import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/providers/llm/summary_prompts.dart';
import 'package:diktafon/services/providers/summarization_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Transcript transcriptOf(List<String> lines) => Transcript(
      languageCode: 'cs',
      segments: [
        for (final line in lines)
          Segment(startMs: 0, endMs: 1000, words: [
            for (final word in line.split(' '))
              Word(text: word, startMs: 0, endMs: 100),
          ]),
      ],
    );

void main() {
  group('prompt building', () {
    test('memo prompt carries the transcript and pins the output language',
        () {
      final prompt = memoSummaryPrompt(
          transcriptOf(['koupit mléko a chleba']),
          languageCode: 'cs');
      expect(prompt.user, contains('koupit mléko a chleba'));
      expect(prompt.user, contains('Czech'));
      expect(prompt.user, contains('/no_think'),
          reason: 'Qwen3 soft switch — no thinking tokens on-device');
      expect(prompt.maxTokens, greaterThan(0));
    });

    test('unknown language codes fall back to the code itself', () {
      expect(languageName('cs'), 'Czech');
      expect(languageName('xx'), 'xx');
    });

    test('overlong transcripts are truncated to the context budget', () {
      final prompt = memoSummaryPrompt(
          transcriptOf([List.filled(9000, 'slovo').join(' ')]),
          languageCode: 'cs');
      expect(prompt.user.length,
          lessThan(transcriptCharBudget + 500),
          reason: 'transcript text clamped + instruction overhead');
      expect(prompt.user, contains('…'));
    });

    test('first cassette update has no previous summary; later ones fold',
        () {
      final digests = [
        MemoDigest(memoSummary: 'první', createdAt: DateTime(2026)),
      ];
      final first = cassetteSummaryPrompt(
          previousSummary: null, newMemos: digests, languageCode: 'cs');
      expect(first.user, isNot(contains('Current overview')));
      expect(first.user, contains('- první'));

      final folding = cassetteSummaryPrompt(
          previousSummary: 'starý přehled',
          newMemos: digests,
          languageCode: 'cs');
      expect(folding.user, contains('starý přehled'));
      expect(folding.user, contains('Newly added'));
    });

    test('title prompt asks for 1–4 words from the overview', () {
      final prompt = titlePrompt('nákupy na víkend', languageCode: 'cs');
      expect(prompt.user, contains('nákupy na víkend'));
      expect(prompt.user, contains('1–4 words'));
    });
  });

  group('output cleanup', () {
    test('strips closed think blocks and surrounding whitespace', () {
      expect(
          cleanLlmOutput('<think>\nhmm\n</think>\n\n  Koupit mléko.  '),
          'Koupit mléko.');
      expect(cleanLlmOutput('<think></think>Text'), 'Text');
    });

    test('drops an unclosed think block entirely (token cap hit mid-think)',
        () {
      expect(cleanLlmOutput('<think>endless reasoning about milk'), '');
      expect(cleanLlmOutput('Summary. <think>tail'), 'Summary.');
    });

    test('unwraps quotes the model added despite instructions', () {
      expect(cleanLlmOutput('"Nákupní seznam"'), 'Nákupní seznam');
      expect(cleanLlmOutput('„Nákupy“'), 'Nákupy');
    });

    test('collapses newlines — stored summaries are flowing text', () {
      expect(cleanLlmOutput('Bod jedna.\nBod dva.'), 'Bod jedna. Bod dva.');
    });

    test('titles lose list markers, trailing punctuation and excess length',
        () {
      expect(cleanTitle('- Nákupní seznam.'), 'Nákupní seznam');
      expect(cleanTitle('<think></think>\n**Nákupy**'.replaceAll('*', '')),
          'Nákupy');
      expect(cleanTitle(List.filled(30, 'slovo').join(' ')).length,
          lessThanOrEqualTo(60));
    });
  });
}
