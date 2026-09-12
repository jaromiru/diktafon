/// The shipped default `SummarizationProvider` (D3): a small local
/// instruct LLM via llama.cpp behind the dk_llama shim. Every call is one
/// [system, user] exchange in the worker isolate; the model context stays
/// warm between jobs.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../../../domain/models.dart';
import '../summarization_provider.dart';
import '../transcription_provider.dart' show ModelStatus, ProgressSink;
import 'llama_worker.dart' show LlamaWorker, logLlm;
import 'llm_model_manager.dart';
import 'summary_prompts.dart';

class LocalLlmSummarizationProvider implements SummarizationProvider {
  LocalLlmSummarizationProvider({
    required this._models,
    required this._worker,
    required String tier,
  }) : _model = LlmModel.byTier(tier);

  final LlmModelManager _models;
  final LlamaWorker _worker;
  final LlmModel _model;

  /// Low but non-zero: greedy decoding loops on repetitive dictation;
  /// the seeded sampler keeps output deterministic per transcript.
  static const _temperature = 0.3;

  /// Hard ceiling for one exchange. A phone-size model answers in well
  /// under a minute; anything past this is a wedged native call, not a
  /// slow one — without it a stuck job parks the whole queue forever.
  static const _generateTimeout = Duration(minutes: 5);

  /// Leave headroom for the UI/OS; same policy as the whisper provider.
  static final int _threads = max(1, min(Platform.numberOfProcessors - 2, 8));

  @override
  String get id => 'llama.cpp/${_model.tier}';

  @override
  Future<ModelStatus> modelStatus() async => _models.statusOf(_model);

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) =>
      _models.download(_model, onProgress: onProgress);

  @override
  Future<String> summarizeMemo(Transcript t,
      {required String languageCode}) async {
    final out = await _run(memoSummaryPrompt(t, languageCode: languageCode));
    return cleanLlmOutput(out);
  }

  @override
  Future<String> updateCassetteSummary({
    required String? previousSummary,
    required List<MemoDigest> newMemos,
    required String languageCode,
  }) async {
    final out = await _run(cassetteSummaryPrompt(
      previousSummary: previousSummary,
      newMemos: newMemos,
      languageCode: languageCode,
    ));
    return cleanLlmOutput(out);
  }

  @override
  Future<String> suggestTitle(String cassetteSummary,
      {required String languageCode}) async {
    final out =
        await _run(titlePrompt(cassetteSummary, languageCode: languageCode));
    return cleanTitle(out);
  }

  Future<String> _run(LlmPrompt prompt) async {
    if (_models.statusOf(_model) != ModelStatus.ready) {
      throw StateError('summarization model ${_model.tier} is not installed');
    }
    final sw = Stopwatch()..start();
    try {
      return await _worker
          .generate(
            modelPath: _models.fileOf(_model).path,
            contextTokens: _model.contextTokens,
            system: prompt.system,
            user: prompt.user,
            maxTokens: prompt.maxTokens,
            temperature: _temperature,
            cancelFlagAddress: 0, // summarization jobs are short; not cancellable
            threads: _threads,
          )
          .timeout(_generateTimeout);
    } on TimeoutException {
      // The queue retries with backoff — but a wedged native generate
      // would block every later attempt inside one shared isolate, so the
      // worker is torn down and the retry spawns a fresh one.
      logLlm('generate timed out after '
          '${_generateTimeout.inMinutes} min — restarting worker');
      await _worker.dispose();
      rethrow;
    } catch (e) {
      logLlm('generate failed after ${sw.elapsedMilliseconds} ms: $e');
      rethrow;
    }
  }
}
