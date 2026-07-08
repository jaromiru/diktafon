import 'package:diktafon/domain/models.dart';
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

    test('long transcripts split at the char budget, indices intact', () {
      final line = List.filled(120, 'word').join(' '); // ~600 chars
      final segments = [for (var i = 0; i < 10; i++) seg(line)];
      final batches = cleanupBatches(transcript(segments));

      expect(batches.length, greaterThan(1));
      var next = 0;
      for (final batch in batches) {
        expect(batch.startIndex, next);
        expect(batch.lines.fold(0, (s, l) => s + l.length),
            lessThanOrEqualTo(cleanupCharBudget));
        next += batch.lines.length;
      }
      expect(next, segments.length, reason: 'every segment is covered');
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
  });
}
