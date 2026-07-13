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
import '../services/import/cassette_importer.dart';
import '../services/processing/job_queue.dart';
import '../services/providers/llm/llama_bindings.dart';
import '../services/providers/llm/llama_worker.dart';
import '../services/providers/llm/llm_model_manager.dart';
import '../services/providers/llm/llm_summarization_provider.dart';
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

/// LLM model store under `<app-support>/models/llm` (§7.1) — same deal.
final llmModelManagerProvider = Provider<LlmModelManager>(
    (ref) => throw UnimplementedError('overridden in main'));

final pcmDecoderProvider = Provider<PcmDecoder>((ref) => defaultPcmDecoder());

/// One inference isolate per engine app-wide; keeps loaded models warm
/// (§6.5, queue concurrency is 1 so the two never run at once).
final whisperWorkerProvider = Provider<WhisperWorker>((ref) {
  final worker = WhisperWorker(resolveWhisperLibraryPath());
  ref.onDispose(worker.dispose);
  return worker;
});

final llamaWorkerProvider = Provider<LlamaWorker>((ref) {
  final worker = LlamaWorker(resolveLlamaLibraryPath());
  ref.onDispose(worker.dispose);
  return worker;
});

/// Silero VAD model file, materialized from the bundled asset by main()
/// (§6.3a). Null (tests, missing asset) → transcription runs VAD-free.
final vadModelFileProvider = Provider<String?>((ref) => null);

/// The two swappable intelligence seams (§6.3): whisper (D2, M2) and the
/// local LLM (D3, M3).
final transcriptionProvider = Provider<TranscriptionProvider>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const AppSettings();
  return WhisperCppTranscriptionProvider(
    models: ref.watch(whisperModelManagerProvider),
    decoder: ref.watch(pcmDecoderProvider),
    worker: ref.watch(whisperWorkerProvider),
    tier: settings.whisperTier,
    vadModelPath: ref.watch(vadModelFileProvider),
  );
});

final summarizationProvider = Provider<SummarizationProvider>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const AppSettings();
  return LocalLlmSummarizationProvider(
    models: ref.watch(llmModelManagerProvider),
    worker: ref.watch(llamaWorkerProvider),
    tier: settings.llmTier,
  );
});

/// Deliberately *not* watching the two engine providers: the queue survives
/// a tier switch and resolves them per job instead (see JobQueue docs).
final jobQueueProvider = Provider<JobQueue>((ref) => JobQueue(
      ref.watch(appDatabaseProvider),
      ref.watch(memoRepositoryProvider),
      ref.watch(cassetteRepositoryProvider),
      ref.watch(settingsRepositoryProvider),
      () => ref.read(transcriptionProvider),
      () => ref.read(summarizationProvider),
    ));

/// Archive import (§8): restored memos that lack a transcript or gist
/// re-enter the pipeline through the queue's own entry points.
final cassetteImporterProvider = Provider<CassetteImporter>((ref) {
  final jobs = ref.watch(jobQueueProvider);
  return CassetteImporter(
    cassettes: ref.watch(cassetteRepositoryProvider),
    memos: ref.watch(memoRepositoryProvider),
    files: ref.watch(audioFileStoreProvider),
    enqueueTranscription: jobs.enqueueTranscription,
    retryEnrichment: jobs.retryEnrichment,
  );
});

/// Per-tier model install/download state for the Settings pickers (§5.5).
final whisperModelStatesProvider =
    StreamProvider<List<WhisperModelState>>((ref) async* {
  final manager = ref.watch(whisperModelManagerProvider);
  yield manager.snapshot();
  await for (final _ in manager.changes) {
    yield manager.snapshot();
  }
});

final llmModelStatesProvider =
    StreamProvider<List<LlmModelState>>((ref) async* {
  final manager = ref.watch(llmModelManagerProvider);
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

/// Boundary-chime file, materialized from the bundled asset by main().
/// Null (tests, missing asset) → playback stays chime-free.
final chimeFileProvider = Provider<String?>((ref) => null);

/// One tape player app-wide — only one cassette is open at a time.
final tapePlayerProvider = Provider<TapePlayerService>((ref) {
  final player =
      TapePlayerService(chimeFilePath: ref.watch(chimeFileProvider));
  ref.onDispose(player.dispose);
  // D5: the chime toggle follows settings live, without rebuilding the
  // player (a rebuild would drop the loaded tape mid-session).
  ref.listen(settingsProvider, (_, s) {
    final enabled = s.value?.chimeEnabled;
    if (enabled != null) player.chimeEnabled = enabled;
  }, fireImmediately: true);
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
