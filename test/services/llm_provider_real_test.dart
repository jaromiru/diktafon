/// Full-stack engine test: real libdiktafon_llama.so, real GGUF model,
/// worker isolate, chat templating and output cleanup — the whole
/// SummarizationProvider seam end to end.
///
/// Opt-in (needs artefacts that don't live in the repo):
///   DIKTAFON_LIBLLAMA=path/to/libdiktafon_llama.so \
///   DIKTAFON_LLM_MODEL=path/to/Qwen3-0.6B-Q8_0.gguf \
///   flutter test test/services/llm_provider_real_test.dart
library;

import 'dart:io';

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/llm/llm_summarization_provider.dart';
import 'package:diktafon/services/providers/llm/llama_worker.dart';
import 'package:diktafon/services/providers/summarization_provider.dart';
import 'package:diktafon/services/providers/transcription_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lib = Platform.environment['DIKTAFON_LIBLLAMA'];
  final model = Platform.environment['DIKTAFON_LLM_MODEL'];
  final available = lib != null && model != null;
  const skipNote = 'set DIKTAFON_LIBLLAMA / DIKTAFON_LLM_MODEL to run the '
      'real engine test';

  test(
    'the provider summarizes, folds and titles a Czech cassette end to end',
    () async {
      final dir = Directory.systemTemp.createTempSync('dk_llm_real_');
      addTearDown(() => dir.deleteSync(recursive: true));
      // The manager resolves tiers by canonical file name.
      File(model!).copySync('${dir.path}/${LlmModel.qwen3_0_6b.fileName}');

      final worker = LlamaWorker(lib!);
      addTearDown(worker.dispose);
      final provider = LocalLlmSummarizationProvider(
        models: LlmModelManager(dir),
        worker: worker,
        tier: LlmModel.qwen3_0_6b.tier,
      );

      expect(await provider.modelStatus(), ModelStatus.ready);

      final transcript = Transcript(languageCode: 'cs', segments: [
        Segment(startMs: 0, endMs: 6000, words: [
          for (final (i, w) in 'koupit mléko chleba a máslo nezapomenout '
                  'na granule pro psa a zavolat mámě kvůli víkendu'
              .split(' ')
              .indexed)
            Word(text: w, startMs: i * 400, endMs: i * 400 + 350),
        ]),
      ]);

      final gist = await provider.summarizeMemo(transcript,
          languageCode: 'cs');
      expect(gist, isNotEmpty);
      expect(gist, isNot(contains('<think>')),
          reason: 'think blocks must be stripped');

      final overview = await provider.updateCassetteSummary(
        previousSummary: null,
        newMemos: [MemoDigest(memoSummary: gist, createdAt: DateTime.now())],
        languageCode: 'cs',
      );
      expect(overview, isNotEmpty);

      final title =
          await provider.suggestTitle(overview, languageCode: 'cs');
      expect(title, isNotEmpty);
      expect(title.length, lessThanOrEqualTo(60));
      expect(title, isNot(contains('\n')));
    },
    skip: available ? false : skipNote,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
