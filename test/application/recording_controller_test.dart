import 'dart:async';
import 'dart:io';

import 'package:diktafon/application/providers.dart';
import 'package:diktafon/application/recording_controller.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/audio/capture_recovery.dart';
import 'package:diktafon/services/audio/recorder_service.dart';
import 'package:diktafon/services/audio/tape_player_service.dart';
import 'package:diktafon/services/processing/job_queue.dart';
import 'package:diktafon/services/providers/transcription_provider.dart'
    show ModelStatus;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/job_queue_test.dart'
    show FakeSummarizationProvider, FakeTranscriptionProvider;

/// Captures without a microphone: fabricates the WAV + marker the real
/// recorder would produce and never touches the record plugin.
class FakeRecorder extends RecorderService {
  FakeRecorder(this._store) : super(_store);

  final AudioFileStore _store;
  String? _memoId;
  String? _path;
  final _stops = StreamController<void>.broadcast();

  @override
  Future<bool> hasPermission() async => true;

  @override
  bool get isRecording => _memoId != null;

  @override
  Duration get elapsed => const Duration(seconds: 2);

  @override
  Stream<void> get captureStops => _stops.stream;

  @override
  Future<void> start(String cassetteId) async {
    _memoId = 'fake-memo';
    _path = await _store.pathFor(cassetteId, _memoId!, extension: 'wav');
    await File(_path!).writeAsBytes(List.filled(64, 1));
    await writeCaptureMarker(
      wavPath: _path!,
      memoId: _memoId!,
      cassetteId: cassetteId,
      startedAt: DateTime(2026, 7, 20, 9),
    );
  }

  @override
  Future<RecordingResult> stop() async {
    final result = RecordingResult(
        memoId: _memoId!, filePath: _path!, durationMs: 2000);
    _memoId = null;
    return result;
  }

  @override
  Future<void> discard() async {
    if (_path != null) {
      final file = File(_path!);
      if (file.existsSync()) file.deleteSync();
      await removeCaptureMarker(_path!);
    }
    _memoId = null;
  }

  @override
  Future<void> dispose() => _stops.close();
}

class FakePlayer extends TapePlayerService {
  int pauses = 0;

  @override
  Future<void> pause() async => pauses++;
}

class FakeGlue extends RecordingForegroundGlue {
  bool answer = true;
  int starts = 0, stops = 0;
  String? lastTitle, lastChannelName;

  /// Lets the abort test act while the service start is "in flight".
  Completer<void>? gate;

  @override
  Future<bool> start(
      {required String title, required String channelName}) async {
    starts++;
    lastTitle = title;
    lastChannelName = channelName;
    if (gate != null) await gate!.future;
    return answer;
  }

  @override
  Future<void> stop() async => stops++;
}

void main() {
  // RecorderService's plugin field (and just_audio inside TapePlayerService)
  // touch platform channels at construction — swallow those calls; the fakes
  // override every method the controller actually uses.
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final channel in const [
    MethodChannel('com.llfbandit.record/messages'),
    MethodChannel('com.ryanheise.just_audio.methods'),
  ]) {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  }

  late Directory work;
  late AppDatabase db;
  late FakeRecorder recorder;
  late FakeGlue glue;
  late ProviderContainer container;
  late String cassetteId;

  setUp(() async {
    work = Directory.systemTemp.createTempSync('dk_recctl_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final store = AudioFileStore(Directory('${work.path}/audio'));
    recorder = FakeRecorder(store);
    glue = FakeGlue();
    // Inert queue: no models, no transcoder — enqueued jobs park as rows,
    // so stop() can be asserted without the pipeline racing the test.
    final inertQueue = JobQueue(
      db,
      MemoRepository(db),
      CassetteRepository(db),
      SettingsRepository(db),
      () => FakeTranscriptionProvider(status: ModelStatus.notInstalled),
      () => FakeSummarizationProvider(status: ModelStatus.notInstalled),
      retryDelayUnit: Duration.zero,
    );
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      audioFileStoreProvider.overrideWithValue(store),
      recorderServiceProvider.overrideWithValue(recorder),
      tapePlayerProvider.overrideWithValue(FakePlayer()),
      recordingForegroundGlueProvider.overrideWithValue(glue),
      jobQueueProvider.overrideWithValue(inertQueue),
    ]);
    cassetteId =
        (await container.read(cassetteRepositoryProvider).create()).id;
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    work.deleteSync(recursive: true);
    debugDefaultTargetPlatformOverride = null;
  });

  RecordingController controller() =>
      container.read(recordingControllerProvider.notifier);

  Future<List<JobRow>> jobRows() => db.select(db.jobs).get();

  group('foreground service (D13)', () {
    test('Android start pins the service with localized copy', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final outcome = await controller().start(cassetteId);

      expect(outcome, RecordStartOutcome.started);
      expect(glue.starts, 1);
      expect(glue.lastTitle, isNotEmpty);
      expect(glue.lastChannelName, isNotEmpty);
      expect(container.read(recordingControllerProvider).backgroundCapable,
          isTrue);
    });

    test('rejected service start records anyway, flagged not-capable',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      glue.answer = false;
      final outcome = await controller().start(cassetteId);

      expect(outcome, RecordStartOutcome.started);
      expect(container.read(recordingControllerProvider).backgroundCapable,
          isFalse);
    });

    test('non-Android never touches the service and is capable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await controller().start(cassetteId);

      expect(glue.starts, 0);
      expect(container.read(recordingControllerProvider).backgroundCapable,
          isTrue);
    });

    test('stop tears the service down', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await controller().start(cassetteId);
      await controller().stop();

      expect(glue.stops, greaterThanOrEqualTo(1));
      expect(container.read(recordingControllerProvider).isRecording, isFalse);
    });

    test('abort during the service start discards the capture', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      glue.gate = Completer<void>();
      final pending = controller().start(cassetteId);
      while (glue.starts == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      controller().abortStartIn(cassetteId);
      glue.gate!.complete();

      expect(await pending, RecordStartOutcome.ignored);
      expect(glue.stops, 1);
      expect(await container.read(memoRepositoryProvider).allIds(), isEmpty);
    });
  });

  group('stop finalization (§14)', () {
    test(
        'inserts the memo, enqueues transcribe + transcode, clears the marker',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await controller().start(cassetteId);
      await controller().stop();

      final memos = container.read(memoRepositoryProvider);
      final memo = (await memos.memosOf(cassetteId)).single;
      expect(memo.id, 'fake-memo');
      expect(memo.filePath, endsWith('.wav'));
      expect(memo.status, MemoStatus.stored);
      expect(File(captureMarkerPath(memo.filePath)).existsSync(), isFalse);
      expect(
        (await jobRows()).map((j) => j.type).toSet(),
        {'transcribe', 'transcodeAudio'},
      );
    });
  });
}
