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
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final bytes = corruptNextResponse
          ? payload.sublist(0, payload.length - 5)
          : payload;
      request.response.headers.contentType = ContentType.binary;
      request.response.add(bytes);
      await request.response.close();
    });
  });

  tearDown(() async {
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
