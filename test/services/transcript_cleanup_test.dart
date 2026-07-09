import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/providers/llm/summary_prompts.dart'
    show estimateTokens;
import 'package:diktafon/services/providers/llm/transcript_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

Segment seg(String text, {int startMs = 0, int endMs = 1000}) {
  final words = text.split(' ');
  final step = (endMs - startMs) ~/ words.length;
  return Segment(startMs: startMs, endMs: endMs, words: [
    for (final (i, w) in words.indexed)
      Word(
          text: w,
          startMs: startMs + i * step,
          endMs: startMs + (i + 1) * step),
  ]);
}

Transcript transcript(List<Segment> segments) =>
    Transcript(languageCode: 'en', segments: segments);

void main() {
  group('cleanupBatches', () {
    test('a short transcript is one batch of segment texts', () {
      final batches = cleanupBatches(transcript([
        seg('hello world'),
        seg('second line here'),
      ]));
      expect(batches, hasLength(1));
      expect(batches.single.startIndex, 0);
      expect(batches.single.lines, ['hello world', 'second line here']);
    });

    test('long transcripts split at the token budget, indices intact', () {
      final line = List.filled(120, 'word').join(' '); // ~600 chars ≈ 200 tok
      final segments = [for (var i = 0; i < 10; i++) seg(line)];
      final batches = cleanupBatches(transcript(segments));

      expect(batches.length, greaterThan(1));
      var next = 0;
      for (final batch in batches) {
        expect(batch.startIndex, next);
        expect(batch.lines.fold(0, (s, l) => s + estimateTokens(l)),
            lessThanOrEqualTo(cleanupTokenBudget));
        next += batch.lines.length;
      }
      expect(next, segments.length, reason: 'every segment is covered');
    });

    test('Hangul spends the budget sooner than latin of equal char length',
        () {
      // 120 four-char words ≈ 600 chars per line in both scripts.
      List<Segment> segsOf(String ch) => [
            for (var i = 0; i < 10; i++)
              seg(List.filled(120, ch * 4).join(' ')),
          ];
      final latin = cleanupBatches(transcript(segsOf('a')));
      final hangul = cleanupBatches(transcript(segsOf('가')));
      expect(hangul.length, greaterThan(latin.length),
          reason: 'per-script budgets keep Hangul prompts inside the '
              'context window');
    });

    test('word-less segments are skipped without breaking indexing', () {
      final batches = cleanupBatches(transcript([
        seg('first'),
        const Segment(startMs: 1000, endMs: 2000, words: []),
        seg('third'),
      ]));
      expect(batches, hasLength(2));
      expect(batches[0].startIndex, 0);
      expect(batches[0].lines, ['first']);
      expect(batches[1].startIndex, 2);
      expect(batches[1].lines, ['third']);
    });

    test('the prompt carries numbered lines, the language and /no_think', () {
      final prompt =
          cleanupBatches(transcript([seg('hello world')])).single.prompt('cs');
      expect(prompt.user, contains('1: hello world'));
      expect(prompt.user, contains('Czech'));
      expect(prompt.user, endsWith('/no_think'));
      expect(prompt.maxTokens, lessThanOrEqualTo(2048));
    });

    test('maxTokens leaves a 2× echo headroom over the line estimate', () {
      final batch =
          cleanupBatches(transcript([seg('내일 마트에 가서 우유를 사야 한다')]))
              .single;
      final tokens = batch.lines.fold(0, (s, l) => s + estimateTokens(l));
      expect(batch.prompt('ko').maxTokens,
          greaterThanOrEqualTo(2 * tokens));
    });
  });

  group('applyCleanupReply — guardrails', () {
    final batch = CleanupBatch(0, const [
      'their was a problem',
      'all good here',
    ]);

    test('a well-formed reply replaces the lines', () {
      final lines = applyCleanupReply(
          batch, '1: There was a problem.\n2: All good here.');
      expect(lines, ['There was a problem.', 'All good here.']);
    });

    test('think blocks are stripped without collapsing the line structure',
        () {
      final lines = applyCleanupReply(batch,
          '<think>\nlet me see\n</think>\n1: There was a problem.\n2: all good here');
      expect(lines.first, 'There was a problem.');
    });

    test('missing or empty reply lines keep the original', () {
      expect(applyCleanupReply(batch, '2: All good here.'),
          ['their was a problem', 'All good here.']);
      expect(applyCleanupReply(batch, '1:\n2: All good here.').first,
          'their was a problem');
    });

    test('a rewrite far off the original length is rejected', () {
      final essay = List.filled(20, 'padding').join(' ');
      expect(applyCleanupReply(batch, '1: $essay\n2: All good here.').first,
          'their was a problem');
    });

    test('alternative numbering styles parse; junk numbers are ignored', () {
      expect(
          applyCleanupReply(
              batch, '1. There was a problem.\n2) All good here.\n7: noise'),
          ['There was a problem.', 'All good here.']);
    });

    test('no usable reply at all → verbatim originals', () {
      expect(applyCleanupReply(batch, 'Sure! Here are the corrected lines.'),
          batch.lines);
    });
  });

  group('retimedSegment', () {
    final original = seg('their was a problem', startMs: 500, endMs: 4500);

    test('unchanged text keeps the engine timings object', () {
      expect(identical(retimedSegment(original, 'their was a problem'), original),
          isTrue);
    });

    test('changed text keeps the span; timings are monotonic and gap-free',
        () {
      final retimed = retimedSegment(original, 'There was a big problem.');
      expect(retimed.startMs, original.startMs);
      expect(retimed.endMs, original.endMs);
      expect(retimed.words.map((w) => w.text).join(' '),
          'There was a big problem.');
      expect(retimed.words.first.startMs, original.startMs);
      expect(retimed.words.last.endMs, original.endMs);
      for (var i = 1; i < retimed.words.length; i++) {
        expect(retimed.words[i].startMs, retimed.words[i - 1].endMs);
        expect(retimed.words[i].endMs,
            greaterThanOrEqualTo(retimed.words[i].startMs));
      }
    });

    test('a blank rewrite cannot produce an empty segment', () {
      expect(identical(retimedSegment(original, '   '), original), isTrue);
    });

    // original: their[500,1500] was[1500,2500] a[2500,3500] problem[3500,4500]

    test('unchanged words are anchored to their engine timings', () {
      final retimed = retimedSegment(original, 'There was a problem.');
      expect(retimed.words.map((w) => w.text).join(' '), 'There was a problem.');
      // 'was', 'a', 'problem.' survived (case/punctuation ignored) — their
      // engine timings must not move because a neighbour changed.
      expect(retimed.words[1].startMs, 1500);
      expect(retimed.words[1].endMs, 2500);
      expect(retimed.words[2].startMs, 2500);
      expect(retimed.words[2].endMs, 3500);
      expect(retimed.words[3].startMs, 3500);
      expect(retimed.words[3].endMs, 4500);
      // The replaced first word fills the gap up to the first anchor.
      expect(retimed.words[0].startMs, 500);
      expect(retimed.words[0].endMs, 1500);
    });

    test('casing and punctuation fixes never move any word', () {
      final retimed = retimedSegment(original, 'Their was a problem.');
      for (var i = 0; i < 4; i++) {
        expect(retimed.words[i].startMs, original.words[i].startMs);
        expect(retimed.words[i].endMs, original.words[i].endMs);
      }
    });

    test('an inserted word squeezes between its neighbours', () {
      final retimed = retimedSegment(original, 'their was a big problem');
      expect(retimed.words[3].text, 'big');
      expect(retimed.words[3].startMs, 3500);
      expect(retimed.words[3].endMs, 3500);
      expect(retimed.words[2].endMs, 3500, reason: "'a' keeps its timing");
      expect(retimed.words[4].startMs, 3500,
          reason: "'problem' keeps its timing");
      expect(retimed.words[4].endMs, 4500);
    });

    test('a full rewrite falls back to proportional timings', () {
      final retimed = retimedSegment(original, 'completely different words');
      expect(retimed.words.first.startMs, 500);
      expect(retimed.words.last.endMs, 4500);
      for (var i = 1; i < retimed.words.length; i++) {
        expect(retimed.words[i].startMs, retimed.words[i - 1].endMs);
      }
    });
  });
}
