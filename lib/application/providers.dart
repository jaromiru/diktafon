/// Riverpod wiring (§6.1): providers are resolved here, so swapping a
/// transcription/summarization engine is a factory change — never a UI change.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/files/audio_file_store.dart';
import '../data/repositories/cassette_repository.dart';
import '../data/repositories/memo_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/models.dart';
import '../domain/tape.dart';
import '../services/audio/pcm_decoder.dart';
import '../services/audio/recorder_service.dart';
import '../services/audio/tape_player_service.dart';
import '../services/processing/job_queue.dart';
import '../services/providers/summarization_provider.dart';
import '../services/providers/transcription_provider.dart';
import '../services/providers/whisper/whisper_bindings.dart';
import '../services/providers/whisper/whisper_model_manager.dart';
import '../services/providers/whisper/whisper_transcription_provider.dart';
import '../services/providers/whisper/whisper_worker.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Overridden in main() with the opened store (needs async I/O).
final audioFileStoreProvider = Provider<AudioFileStore>(
    (ref) => throw UnimplementedError('overridden in main'));

final cassetteRepositoryProvider = Provider<CassetteRepository>(
    (ref) => CassetteRepository(ref.watch(appDatabaseProvider)));

final memoRepositoryProvider = Provider<MemoRepository>(
    (ref) => MemoRepository(ref.watch(appDatabaseProvider)));

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => SettingsRepository(ref.watch(appDatabaseProvider)));

/// Whisper model store under `<app-support>/models/whisper` (§7.1) —
/// overridden in main() / tests with the resolved directory.
final whisperModelManagerProvider = Provider<WhisperModelManager>(
    (ref) => throw UnimplementedError('overridden in main'));

final pcmDecoderProvider = Provider<PcmDecoder>((ref) => defaultPcmDecoder());

/// One inference isolate app-wide; keeps the loaded model warm (§6.5).
final whisperWorkerProvider = Provider<WhisperWorker>((ref) {
  final worker = WhisperWorker(resolveWhisperLibraryPath());
  ref.onDispose(worker.dispose);
  return worker;
});

/// The two swappable intelligence seams (§6.3). Whisper ships in M2 (D2);
/// summarization arrives with M3 (D3).
final transcriptionProvider = Provider<TranscriptionProvider>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const AppSettings();
  return WhisperCppTranscriptionProvider(
    models: ref.watch(whisperModelManagerProvider),
    decoder: ref.watch(pcmDecoderProvider),
    worker: ref.watch(whisperWorkerProvider),
    tier: settings.whisperTier,
  );
});

final summarizationProvider = Provider<SummarizationProvider>(
    (ref) => const NotInstalledSummarizationProvider());

/// Deliberately *not* watching [transcriptionProvider]: the queue survives a
/// tier switch and resolves the provider per job instead (see JobQueue docs).
final jobQueueProvider = Provider<JobQueue>((ref) => JobQueue(
      ref.watch(appDatabaseProvider),
      ref.watch(memoRepositoryProvider),
      ref.watch(settingsRepositoryProvider),
      () => ref.read(transcriptionProvider),
    ));

/// Per-tier model install/download state for the Settings picker (§5.5).
final whisperModelStatesProvider =
    StreamProvider<List<WhisperModelState>>((ref) async* {
  final manager = ref.watch(whisperModelManagerProvider);
  yield manager.snapshot();
  await for (final _ in manager.changes) {
    yield manager.snapshot();
  }
});

final recorderServiceProvider = Provider<RecorderService>((ref) {
  final recorder = RecorderService(ref.watch(audioFileStoreProvider));
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// One tape player app-wide — only one cassette is open at a time.
final tapePlayerProvider = Provider<TapePlayerService>((ref) {
  final player = TapePlayerService();
  ref.onDispose(player.dispose);
  return player;
});

final settingsProvider = StreamProvider<AppSettings>(
    (ref) => ref.watch(settingsRepositoryProvider).watch());

final cassetteOverviewsProvider = StreamProvider<List<CassetteOverview>>(
    (ref) => ref.watch(cassetteRepositoryProvider).watchOverviews());

final cassetteProvider = StreamProvider.family<Cassette?, String>(
    (ref, id) => ref.watch(cassetteRepositoryProvider).watchCassette(id));

final memosProvider = StreamProvider.family<List<Memo>, String>(
    (ref, cassetteId) =>
        ref.watch(memoRepositoryProvider).watchMemosOf(cassetteId));

/// The computed tape view (§4.1) for an open cassette.
final tapeProvider = Provider.family<Tape, String>((ref, cassetteId) {
  final memos = ref.watch(memosProvider(cassetteId)).value ?? const [];
  return Tape(memos);
});

/// Playback state of the currently loaded tape, for the LCD counter,
/// playhead and transcript highlight.
final playbackProvider = StreamProvider<TapePlaybackState>((ref) {
  final player = ref.watch(tapePlayerProvider);
  return player.stateStream;
});
