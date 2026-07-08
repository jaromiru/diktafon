import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:diktafon/services/notifications/download_notifier.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every sink call as one printable line, in order.
class RecordingSink implements DownloadNotificationSink {
  final calls = <String>[];

  @override
  Future<void> showProgress(int id, String title, int percent) async {
    calls.add('progress#$id "$title" $percent');
  }

  @override
  Future<void> showDone(int id, String title) async {
    calls.add('done#$id "$title"');
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel#$id');
  }
}

/// Drives a real [ModelManager] against a local HTTP server (the
/// whisper_model_manager_test pattern) and asserts the notification
/// choreography: progress while on the wire, a "done" notice on landing,
/// silent removal on cancel.
void main() {
  late HttpServer server;
  late Directory dir;
  final payload = utf8.encode('not a real ggml model, but 42 bytes long..');
  var stallResponses = false;
  late Completer<void> stallGate;

  WhisperModel spec(HttpServer server) => WhisperModel(
        tier: 'tiny',
        label: 'Test model',
        description: '',
        fileName: 'model.bin',
        sizeBytes: payload.length,
        sha256Hex: sha256.convert(payload).toString(),
        urlOverride: Uri.parse('http://127.0.0.1:${server.port}/model.bin'),
      );

  const texts = DownloadNotificationTexts(
    downloading: _downloadingText,
    installed: _installedText,
  );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('dk_notif_');
    stallResponses = false;
    stallGate = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.binary;
      try {
        if (stallResponses) {
          request.response.bufferOutput = false;
          request.response.add(payload.sublist(0, 10));
          await request.response.flush();
          await stallGate.future;
          request.response.add(payload.sublist(10));
        } else {
          request.response.add(payload);
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

  test('download → per-percent progress, then the done notice', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir, catalog: [model]);
    final sink = RecordingSink();
    final notifier = ModelDownloadNotifier(sink, texts)
      ..attach(manager, idBase: 100);
    addTearDown(notifier.dispose);

    await manager.download(model);
    // Let the queued sink calls (and the trailing change event) settle.
    await Future<void>.delayed(Duration.zero);

    // Attach first clears any notification a previous run left behind.
    expect(sink.calls.first, 'cancel#100');
    expect(sink.calls[1], startsWith('progress#100 "Downloading Test model"'));
    expect(sink.calls.last, 'done#100 "Test model installed"');
    final percents = sink.calls
        .where((c) => c.startsWith('progress#'))
        .map((c) => int.parse(c.split(' ').last))
        .toList();
    expect(percents, equals(percents.toSet().toList()),
        reason: 'chunk-level events are gated to one update per percent');
  });

  test('cancel mid-flight removes the notification, no done notice',
      () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir, catalog: [model]);
    final sink = RecordingSink();
    final notifier = ModelDownloadNotifier(sink, texts)
      ..attach(manager, idBase: 100);
    addTearDown(notifier.dispose);

    stallResponses = true;
    final download = manager.download(model);
    // Attach itself enqueues a stale-notification cancel — wait for real
    // progress so our cancel hits a genuinely in-flight transfer.
    while (!sink.calls.any((c) => c.startsWith('progress#'))) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    manager.cancel(model);
    await expectLater(download, throwsA(isA<ModelDownloadCancelled>()));
    await Future<void>.delayed(Duration.zero);

    expect(sink.calls.last, 'cancel#100');
    expect(sink.calls.where((c) => c.startsWith('done#')), isEmpty);
  });

  test('attach clears notifications a dead process left behind', () async {
    // A process killed mid-download can't cancel its progress notification;
    // the next run's attach must sweep it out of the shade.
    final model = spec(server);
    final manager = WhisperModelManager(dir, catalog: [model]);
    final sink = RecordingSink();
    final notifier = ModelDownloadNotifier(sink, texts)
      ..attach(manager, idBase: 100);
    addTearDown(notifier.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(sink.calls, ['cancel#100']);
  });

  test('a second attached manager gets its own id space', () async {
    final model = spec(server);
    final manager = WhisperModelManager(dir, catalog: [model]);
    final other = WhisperModelManager(
        Directory('${dir.path}/other')..createSync(),
        catalog: [model]);
    final sink = RecordingSink();
    final notifier = ModelDownloadNotifier(sink, texts)
      ..attach(manager, idBase: 100)
      ..attach(other, idBase: 200);
    addTearDown(notifier.dispose);

    await manager.download(model);
    await other.download(model);
    await Future<void>.delayed(Duration.zero);

    expect(sink.calls.where((c) => c.contains('#100')), isNotEmpty);
    expect(sink.calls.where((c) => c.contains('#200')), isNotEmpty);
  });
}

String _downloadingText(String label) => 'Downloading $label';
String _installedText(String label) => '$label installed';
