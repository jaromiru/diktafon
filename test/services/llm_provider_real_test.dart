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

  // Per-language probes (tr/ru/ko wave + §13 wave 2): the summary must come
  // back non-empty and — where the script is distinctive — *in that script*
  // (prompts pin the output language per D8). Reuses the same lib/model.
  // CJK texts are pre-spaced per word here only to build the Word list; the
  // app joins them flush (script-aware joins). zh-Hant asserts Han script,
  // not Hant specifically — the Hans→Hant belt-and-braces conversion is the
  // job queue's, unit-tested in chinese_script/job_queue tests.
  const memoTexts = {
    'tr': 'yarın markete gidip süt ekmek ve peynir almam lazım ayrıca '
        'annemi arayıp hafta sonu planını sormalıyım',
    'ru': 'надо купить молоко хлеб и корм для собаки а ещё позвонить '
        'маме насчёт планов на выходные',
    'ko': '내일 마트에 가서 우유랑 빵을 사야 하고 주말 계획에 대해 엄마에게 '
        '전화해야 한다',
    'it': 'domani devo comprare latte pane e formaggio e poi chiamare la '
        'mamma per i piani del fine settimana',
    'id': 'besok saya harus beli susu roti dan keju lalu menelepon ibu '
        'soal rencana akhir pekan',
    'uk': 'треба купити молоко хліб і корм для собаки а ще подзвонити '
        'мамі щодо планів на вихідні',
    'vi': 'ngày mai phải mua sữa bánh mì và phô mai rồi gọi cho mẹ về kế '
        'hoạch cuối tuần',
    'ja': '明日 スーパー で 牛乳 と パン を 買って 母 に 週末 の 予定 を '
        '電話 する',
    'zh-Hans': '明天 要 去 超市 买 牛奶 和 面包 还要 给 妈妈 打 电话 说 '
        '周末 的 计划',
    'zh-Hant': '明天 要 去 超市 買 牛奶 和 麵包 還要 給 媽媽 打 電話 說 '
        '週末 的 計劃',
    'ar': 'غدا يجب أن أشتري الحليب والخبز والجبن وأتصل بأمي بخصوص خطة '
        'نهاية الأسبوع',
    'fa': 'فردا باید شیر و نان و پنیر بخرم و به مادرم درباره برنامه آخر '
        'هفته زنگ بزنم',
    'hi': 'कल मुझे दूध रोटी और पनीर खरीदना है और सप्ताहांत की योजना के बारे '
        'में माँ को फोन करना है',
  };
  final scriptOf = {
    'ru': RegExp(r'[Ѐ-ӿ]'),
    'ko': RegExp(r'[가-힯]'),
    'uk': RegExp(r'[Ѐ-ӿ]'),
    'ja': RegExp(r'[ぁ-ヿ一-鿿]'),
    'zh-Hans': RegExp(r'[一-鿿]'),
    'zh-Hant': RegExp(r'[一-鿿]'),
    'ar': RegExp(r'[؀-ۿ]'),
    'fa': RegExp(r'[؀-ۿ]'),
    'hi': RegExp(r'[ऀ-ॿ]'),
  };

  for (final MapEntry(key: code, value: text) in memoTexts.entries) {
    test(
      'the provider summarizes a $code memo in its own script',
      () async {
        final dir = Directory.systemTemp.createTempSync('dk_llm_$code');
        addTearDown(() => dir.deleteSync(recursive: true));
        File(model!).copySync('${dir.path}/${LlmModel.qwen3_0_6b.fileName}');

        final worker = LlamaWorker(lib!);
        addTearDown(worker.dispose);
        final provider = LocalLlmSummarizationProvider(
          models: LlmModelManager(dir),
          worker: worker,
          tier: LlmModel.qwen3_0_6b.tier,
        );

        final transcript = Transcript(languageCode: code, segments: [
          Segment(startMs: 0, endMs: 8000, words: [
            for (final (i, w) in text.split(' ').indexed)
              Word(text: w, startMs: i * 400, endMs: i * 400 + 350),
          ]),
        ]);

        final gist =
            await provider.summarizeMemo(transcript, languageCode: code);
        expect(gist, isNotEmpty);
        expect(gist, isNot(contains('<think>')));
        final script = scriptOf[code];
        if (script != null) {
          expect(gist, matches(script),
              reason: 'the summary must stay in the $code script');
        }
      },
      skip: available ? false : skipNote,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
