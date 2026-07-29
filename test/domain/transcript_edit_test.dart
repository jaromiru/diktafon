import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/transcript_edit.dart';
import 'package:flutter_test/flutter_test.dart';

/// One segment on a contiguous [step]-ms word grid — window math stays
/// predictable in assertions.
Transcript timed(List<String> words, {String lang = 'en', int step = 100}) =>
    Transcript(languageCode: lang, segments: [
      Segment(startMs: 0, endMs: words.length * step, words: [
        for (final (i, w) in words.indexed)
          Word(text: w, startMs: i * step, endMs: (i + 1) * step),
      ]),
    ]);

List<Word> flat(Transcript t) =>
    [for (final s in t.segments) ...s.words];

void main() {
  group('retimeEditedTranscript — anchoring (§6.9)', () {
    test('an unchanged text keeps every timing exactly', () {
      final original = timed(['the', 'quick', 'brown', 'fox']);
      final result =
          retimeEditedTranscript(original, original.plainText,
              memoDurationMs: 400)!;
      expect(result.plainText, original.plainText);
      expect(result.languageCode, 'en');
      final words = flat(result);
      for (final (i, w) in flat(original).indexed) {
        expect(words[i].startMs, w.startMs);
        expect(words[i].endMs, w.endMs);
      }
    });

    test('a one-word fix keeps every other timing; the fix lands inside its '
        'neighbours\' window', () {
      final original = timed(['the', 'quick', 'brown', 'fox']);
      final result = retimeEditedTranscript(original, 'the quick braun fox',
          memoDurationMs: 400)!;
      final words = flat(result);
      expect(words.map((w) => w.text), ['the', 'quick', 'braun', 'fox']);
      expect(words[0].startMs, 0);
      expect(words[1].startMs, 100);
      expect(words[1].endMs, 200);
      expect(words[3].startMs, 300);
      expect(words[3].endMs, 400);
      // The replaced word inherits the gap its predecessor and successor
      // leave open — here exactly the old word's slot.
      expect(words[2].startMs, 200);
      expect(words[2].endMs, 300);
    });

    test('case and punctuation fixes anchor — the timing survives, the new '
        'spelling is stored', () {
      final original = timed(['hello', 'world', 'again']);
      final result = retimeEditedTranscript(original, 'Hello, world. Again!',
          memoDurationMs: 300)!;
      final words = flat(result);
      expect(words.map((w) => w.text), ['Hello,', 'world.', 'Again!']);
      for (final (i, w) in words.indexed) {
        expect(w.startMs, i * 100);
        expect(w.endMs, (i + 1) * 100);
      }
    });

    test('inserted words share the window between their anchors', () {
      final original = timed(['alpha', 'delta']);
      final result = retimeEditedTranscript(original, 'alpha beta gamma delta',
          memoDurationMs: 200)!;
      final words = flat(result);
      expect(words[0].startMs, 0);
      expect(words[0].endMs, 100);
      expect(words[3].startMs, 100);
      expect(words[3].endMs, 200);
      // The inserted pair fills [100, 100] — the anchors sit flush, so the
      // estimates collapse onto the boundary but never run backwards.
      expect(words[1].startMs, greaterThanOrEqualTo(100));
      expect(words[2].endMs, lessThanOrEqualTo(100));
    });

    test('inserted words spread proportionally across an open gap', () {
      final original = Transcript(languageCode: 'en', segments: [
        Segment(startMs: 0, endMs: 1000, words: const [
          Word(text: 'start', startMs: 0, endMs: 100),
          Word(text: 'end', startMs: 900, endMs: 1000),
        ]),
      ]);
      final result = retimeEditedTranscript(original, 'start middle end',
          memoDurationMs: 1000)!;
      final words = flat(result);
      expect(words[1].startMs, 100);
      expect(words[1].endMs, 900);
    });

    test('deleting a word keeps the rest anchored exactly', () {
      final original = timed(['one', 'two', 'three', 'four']);
      final result = retimeEditedTranscript(original, 'one three four',
          memoDurationMs: 400)!;
      final words = flat(result);
      expect(words.map((w) => w.text), ['one', 'three', 'four']);
      expect(words[0].startMs, 0);
      expect(words[1].startMs, 200);
      expect(words[1].endMs, 300);
      expect(words[2].startMs, 300);
      expect(words[2].endMs, 400);
    });

    test('a wholesale rewrite re-times proportionally, monotonic, inside the '
        'memo span', () {
      final original = timed(['aaa', 'bbb', 'ccc', 'ddd', 'eee']);
      final result = retimeEditedTranscript(
          original, 'completely different words here now honestly',
          memoDurationMs: 500)!;
      final words = flat(result);
      expect(words.first.startMs, 0);
      expect(words.last.endMs, 500);
      var cursor = 0;
      for (final w in words) {
        expect(w.startMs, greaterThanOrEqualTo(cursor));
        expect(w.endMs, greaterThanOrEqualTo(w.startMs));
        cursor = w.endMs;
      }
    });
  });

  group('retimeEditedTranscript — lines and segments', () {
    test('each non-empty line becomes a segment spanning its words', () {
      final original = timed(['one', 'two', 'three', 'four']);
      final result = retimeEditedTranscript(original, 'one two\nthree four',
          memoDurationMs: 400)!;
      expect(result.segments.length, 2);
      expect(result.segments[0].startMs, 0);
      expect(result.segments[0].endMs, 200);
      expect(result.segments[1].startMs, 200);
      expect(result.segments[1].endMs, 400);
      expect(result.plainText, 'one two\nthree four');
    });

    test('merging lines merges segments; blank lines drop out', () {
      final original = Transcript(languageCode: 'en', segments: [
        Segment(startMs: 0, endMs: 200, words: const [
          Word(text: 'one', startMs: 0, endMs: 100),
          Word(text: 'two', startMs: 100, endMs: 200),
        ]),
        Segment(startMs: 200, endMs: 400, words: const [
          Word(text: 'three', startMs: 200, endMs: 300),
          Word(text: 'four', startMs: 300, endMs: 400),
        ]),
      ]);
      final result = retimeEditedTranscript(
          original, 'one two three four\n\n   \n',
          memoDurationMs: 400)!;
      expect(result.segments.length, 1);
      expect(flat(result).length, 4);
      expect(flat(result)[2].startMs, 200);
    });

    test('an empty or whitespace-only edit yields null', () {
      final original = timed(['one', 'two']);
      expect(retimeEditedTranscript(original, '', memoDurationMs: 200), null);
      expect(retimeEditedTranscript(original, '  \n \n ', memoDurationMs: 200),
          null);
    });

    test('typing into a "no speech" memo spreads over the recording', () {
      const original = Transcript(languageCode: 'en', segments: []);
      final result = retimeEditedTranscript(original, 'hello there',
          memoDurationMs: 4000)!;
      final words = flat(result);
      expect(words[0].startMs, 0);
      expect(words[0].endMs, 2000);
      expect(words[1].startMs, 2000);
      expect(words[1].endMs, 4000);
      expect(result.segments.single.endMs, 4000);
    });

    test('non-monotonic engine timings are clamped, never reordered', () {
      final original = Transcript(languageCode: 'en', segments: [
        Segment(startMs: 0, endMs: 300, words: const [
          Word(text: 'one', startMs: 0, endMs: 150),
          Word(text: 'two', startMs: 100, endMs: 120), // overlaps backwards
          Word(text: 'three', startMs: 200, endMs: 300),
        ]),
      ]);
      final result = retimeEditedTranscript(original, 'one two three',
          memoDurationMs: 300)!;
      var cursor = 0;
      for (final w in flat(result)) {
        expect(w.startMs, greaterThanOrEqualTo(cursor));
        expect(w.endMs, greaterThanOrEqualTo(w.startMs));
        cursor = w.endMs;
      }
    });
  });

  group('retimeEditedTranscript — CJK (§13 wave 2)', () {
    test('a flush-joined CJK edit re-tokenizes per character and anchors the '
        'untouched ones', () {
      final original = Transcript(languageCode: 'ja', segments: [
        Segment(startMs: 0, endMs: 900, words: const [
          Word(text: '今日は', startMs: 0, endMs: 300),
          Word(text: '晴れ', startMs: 300, endMs: 600),
          Word(text: 'です。', startMs: 600, endMs: 900),
        ]),
      ]);
      expect(original.plainText, '今日は晴れです。');
      final result = retimeEditedTranscript(original, '今日は曇りです。',
          memoDurationMs: 900)!;
      expect(result.plainText, '今日は曇りです。');
      final words = flat(result);
      // Untouched characters keep their (interpolated) engine timings…
      expect(words[0].text, '今');
      expect(words[0].startMs, 0);
      expect(words[0].endMs, 100);
      final de = words.firstWhere((w) => w.text == 'で');
      expect(de.startMs, 600);
      // …and the replaced run stays inside the window they leave open.
      final kumo = words.firstWhere((w) => w.text == '曇');
      expect(kumo.startMs, greaterThanOrEqualTo(300));
      final ri = words.firstWhere((w) => w.text == 'り');
      expect(ri.endMs, lessThanOrEqualTo(600));
    });

    test('code-switched Latin stays whole between CJK characters', () {
      final original = Transcript(languageCode: 'zh-Hans', segments: [
        Segment(startMs: 0, endMs: 400, words: const [
          Word(text: '我用', startMs: 0, endMs: 200),
          Word(text: 'Flutter', startMs: 200, endMs: 400),
        ]),
      ]);
      final result = retimeEditedTranscript(original, '我用 Flutter 写的',
          memoDurationMs: 600)!;
      final words = flat(result);
      expect(words.map((w) => w.text), ['我', '用', 'Flutter', '写', '的']);
      expect(words[2].startMs, 200);
      expect(words[2].endMs, 400);
      expect(result.plainText, '我用 Flutter 写的');
    });
  });
}
