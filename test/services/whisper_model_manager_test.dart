import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:diktafon/services/providers/transcription_provider.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny fake "model" hosted by a local HTTP server; the catalog entry is
/// rebuilt around its real bytes so size/sha checks run for real.
void main() {
  late HttpServer server;
  late Directory dir;
  final payload = utf8.encode('not a real ggml model, but 42 bytes long..');
  var corruptNextResponse = false;
  var stallResponses = false;
  var dropMidResponse = false;
  var serveRanges = false;
  final seenRanges = <String?>[];
  late Completer<void> stallGate;

  WhisperModel spec(HttpServer server, {String? sha}) => WhisperModel(
        tier: 'tiny',
        label: 'Test model',
        description: '',
        fileName: 'model.bin',
        sizeBytes: payload.length,
        sha256Hex: sha ?? sha256.convert(payload).toString(),
        urlOverride: Uri.parse(
            'http://127.0.0.1:${server.port}/model.bin'),
      );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('dk_models_');
    corruptNextResponse = false;
    stallResponses = false;
    dropMidResponse = false;
    serveRanges = false;
    seenRanges.clear();
    stallGate = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final bytes = corruptNextResponse
          ? payload.sublist(0, payload.length - 5)
          : payload;
      request.response.headers.contentType = ContentType.binary;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      seenRanges.add(range);
      try {
        if (dropMidResponse) {
          // A network drop: announce the full length, deliver only the
          // first bytes — close() then aborts the connection over the
          // short body and the client sees a broken transfer.
          request.response.contentLength = bytes.length;
          request.response.bufferOutput = false;
          request.response.add(bytes.sublist(0, 10));
          await request.response.flush();
          await request.response.close();
          return;
        }
        if (serveRanges && range != null) {
          final from =
              int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
          request.response.statusCode = HttpStatus.partialContent;
          request.response.add(bytes.sublist(from));
          await request.response.close();
          return;
        }
        if (stallResponses) {
          // Unbuffered, or the 10-byte chunk never leaves the server.
          request.response.bufferOutput = false;
          request.response.add(bytes.sublist(0, 10));
          await request.response.flush();
          await stallGate.future;
          request.response.add(bytes.sublist(10));
        } else {
          request.response.add(bytes);
        }
        await request.response.close();
      } catch (_) {
        // The cancel test aborts the connection mid-response.
      }
    });
  });

  tearDown(() async {
    if (!stallGate.isCompleted) stallGate.complete();
    await server.close(force: true);
    dir.deleteSync(recursive: true);
  });

  // The catalog hardcodes huggingface URLs; point the request at the local
  // server through a proxying HttpClient instead of patching the spec.
  HttpClient localClient() => HttpClient()
    ..findProxy = (_) => 'PROXY 127.0.0.1:${server.port}';

  test('download → verify → ready; progress reaches 1.0', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);
    expect(manager.statusOf(model), ModelStatus.notInstalled);

    final fractions = <double>[];
    await manager.download(model, onProgress: fractions.add);

    expect(manager.statusOf(model), ModelStatus.ready);
    expect(fractions.last, 1.0);
    expect(manager.fileOf(model).readAsBytesSync(), payload);
    expect(manager.installedBytes(), payload.length);
    expect(dir.listSync().whereType<File>().any((f) => f.path.endsWith('.part')),
        isFalse, reason: 'no stale .part file after success');
  });

  test('sha mismatch → error, nothing installed', () async {
    final model = spec(server, sha: 'deadbeef');
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    await expectLater(manager.download(model),
        throwsA(isA<ModelVerificationException>()));
    expect(manager.statusOf(model), ModelStatus.notInstalled);
    expect(dir.listSync().whereType<File>(), isEmpty,
        reason: 'failed download leaves no partial file behind');
  });

  test('truncated download → error, retry succeeds', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    corruptNextResponse = true;
    await expectLater(manager.download(model),
        throwsA(isA<ModelVerificationException>()));

    corruptNextResponse = false;
    await manager.download(model);
    expect(manager.statusOf(model), ModelStatus.ready);
  });

  test('concurrent downloads of one tier join; ready short-circuits',
      () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    await Future.wait([manager.download(model), manager.download(model)]);
    expect(manager.statusOf(model), ModelStatus.ready);
    // Already installed → returns without touching the network.
    await manager.download(spec(server, sha: 'would-fail-if-fetched'));
  });

  test('cancel aborts mid-flight, leaves nothing, retry succeeds', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    stallResponses = true;
    final fractions = <double>[];
    final download = manager.download(model, onProgress: fractions.add);
    // The server stalls after the first bytes — wait until they arrived so
    // the cancel hits a genuinely in-flight transfer.
    while (fractions.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(manager.statusOf(model), ModelStatus.downloading);

    manager.cancel(model);
    await expectLater(download, throwsA(isA<ModelDownloadCancelled>()));
    expect(manager.statusOf(model), ModelStatus.notInstalled);
    expect(dir.listSync().whereType<File>(), isEmpty,
        reason: 'cancel leaves no partial file behind');

    stallResponses = false;
    await manager.download(model);
    expect(manager.statusOf(model), ModelStatus.ready);
  });

  test('pause stashes the partial as .paused; the next download resumes it',
      () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    stallResponses = true;
    final fractions = <double>[];
    final download = manager.download(model, onProgress: fractions.add);
    while (fractions.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    manager.pause(model);
    await expectLater(download, throwsA(isA<ModelDownloadPaused>()));

    final paused = File('${manager.fileOf(model).path}.paused');
    expect(paused.existsSync(), isTrue,
        reason: 'pause keeps the bytes, stashed out of .part');
    expect(paused.lengthSync(), 10);
    expect(File('${manager.fileOf(model).path}.part').existsSync(), isFalse);
    expect(manager.statusOf(model), ModelStatus.paused);
    expect(manager.stateOf(model).progress,
        closeTo(10 / payload.length, 1e-9),
        reason: 'a paused tier reports the fraction already on disk');

    // Resuming asks the server for just the missing tail.
    stallResponses = false;
    serveRanges = true;
    final resumed = manager.download(model);
    expect(manager.stateOf(model).progress,
        closeTo(10 / payload.length, 1e-9),
        reason: 'a resume starts the bar at the stashed fraction, not 0 %');
    await resumed;
    expect(seenRanges.last, 'bytes=10-');
    expect(manager.statusOf(model), ModelStatus.ready);
    expect(manager.fileOf(model).readAsBytesSync(), payload);
  });

  test('resumeInterrupted puts a killed download back on the wire', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);
    // A force-closed app leaves .part behind; no manager state survives.
    File('${manager.fileOf(model).path}.part')
        .writeAsBytesSync(payload.sublist(0, 10));
    expect(manager.statusOf(model), ModelStatus.paused);

    serveRanges = true;
    expect(await manager.resumeInterrupted(), isTrue,
        reason: 'a model landed — callers drain parked jobs');
    expect(seenRanges.last, 'bytes=10-');
    expect(manager.statusOf(model), ModelStatus.ready);
    expect(manager.fileOf(model).readAsBytesSync(), payload);
  });

  test('resumeInterrupted leaves a user-paused stash alone', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);
    File('${manager.fileOf(model).path}.paused')
        .writeAsBytesSync(payload.sublist(0, 10));

    expect(await manager.resumeInterrupted(), isFalse);
    expect(seenRanges, isEmpty,
        reason: 'an explicit pause never auto-resumes (metered connection)');
    expect(manager.statusOf(model), ModelStatus.paused);
  });

  test('resumeInterrupted stays quiet when the resume fails', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);
    final part = File('${manager.fileOf(model).path}.part')
      ..writeAsBytesSync(payload.sublist(0, 10));

    dropMidResponse = true;
    expect(await manager.resumeInterrupted(), isFalse);
    expect(manager.statusOf(model), ModelStatus.paused,
        reason: 'the partial waits on disk; a tap in Settings retries');
    expect(part.existsSync(), isTrue);
  });

  test('delete discards a paused partial', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);
    File('${manager.fileOf(model).path}.paused')
        .writeAsBytesSync(payload.sublist(0, 10));
    expect(manager.statusOf(model), ModelStatus.paused);

    manager.delete(model);
    expect(manager.statusOf(model), ModelStatus.notInstalled);
    expect(dir.listSync().whereType<File>(), isEmpty);
  });

  test('interrupted download keeps the partial file and resumes with Range',
      () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    dropMidResponse = true;
    await expectLater(manager.download(model), throwsException);
    final part = File('${manager.fileOf(model).path}.part');
    expect(part.existsSync(), isTrue,
        reason: 'a transient failure keeps the partial file for resume');
    expect(part.lengthSync(), 10);
    expect(seenRanges, [null]);

    dropMidResponse = false;
    serveRanges = true;
    final fractions = <double>[];
    await manager.download(model, onProgress: fractions.add);

    expect(seenRanges.last, 'bytes=10-',
        reason: 'the retry asks only for the missing tail');
    expect(manager.statusOf(model), ModelStatus.ready);
    expect(manager.fileOf(model).readAsBytesSync(), payload);
    expect(fractions.first, greaterThanOrEqualTo(10 / payload.length),
        reason: 'progress restarts from the resumed bytes, not 0');
    expect(fractions.last, 1.0);
  });

  test('a stalled body stream times out transiently: the partial is kept '
      'and a later attempt resumes', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient,
        catalog: [model],
        stallTimeout: const Duration(milliseconds: 200));
    stallResponses = true;

    await expectLater(
        manager.download(model), throwsA(isA<TimeoutException>()));
    expect(manager.statusOf(model), ModelStatus.paused,
        reason: 'the partial survives for a resume');

    stallResponses = false;
    serveRanges = true;
    await manager.download(model);
    expect(manager.statusOf(model), ModelStatus.ready);
    expect(manager.fileOf(model).readAsBytesSync(), payload);
  });

  test('a server without Range support restarts the download cleanly',
      () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);

    dropMidResponse = true;
    await expectLater(manager.download(model), throwsException);

    // The retry sends Range, the server answers 200 with the whole file —
    // the partial is overwritten, verification still passes.
    dropMidResponse = false;
    serveRanges = false;
    await manager.download(model);
    expect(seenRanges.last, 'bytes=10-');
    expect(manager.statusOf(model), ModelStatus.ready);
    expect(manager.fileOf(model).readAsBytesSync(), payload);
  });

  test('delete returns the tier to notInstalled', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir,
        httpClientFactory: localClient, catalog: [model]);
    await manager.download(model);
    manager.delete(model);
    expect(manager.statusOf(model), ModelStatus.notInstalled);
    expect(manager.installedBytes(), 0);
  });
}
