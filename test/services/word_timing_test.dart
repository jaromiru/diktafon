import 'dart:convert';
import 'dart:typed_data';

import 'package:diktafon/services/providers/whisper/word_timing.dart';
import 'package:flutter_test/flutter_test.dart';

RawToken _token(String text, int t0, int t1) =>
    RawToken(Uint8List.fromList(utf8.encode(text)), t0, t1);

void main() {
  group('assembleTranscript (whisper tokens → words)', () {
    test('leading-space tokens open words; punctuation attaches', () {
      final transcript = assembleTranscript('en', [
        RawSegment(0, 2000, [
          _token(' Hello', 0, 400),
          _token(' world', 500, 900),
          _token(',', 900, 950),
          _token(' again', 1000, 1400),
          _token('.', 1400, 1500),
        ]),
      ]);
      final words = transcript.segments.single.words;
      expect(words.map((w) => w.text), ['Hello', 'world,', 'again.']);
      expect(words[1].startMs, 500);
      expect(words[1].endMs, 950, reason: 'punctuation extends the word');
    });

    test('multi-token words merge with the full time span', () {
      final transcript = assembleTranscript('cs', [
        RawSegment(0, 1000, [
          _token(' nakou', 0, 300),
          _token('pit', 300, 600),
        ]),
      ]);
      final word = transcript.segments.single.words.single;
      expect(word.text, 'nakoupit');
      expect(word.startMs, 0);
      expect(word.endMs, 600);
    });

    test('UTF-8 split across tokens survives (Czech diacritics)', () {
      // "žluťoučký" cut mid-character: ž = 0xC5 0xBE split across tokens.
      final bytes = utf8.encode(' žluťoučký');
      final transcript = assembleTranscript('cs', [
        RawSegment(0, 800, [
          RawToken(Uint8List.fromList(bytes.sublist(0, 2)), 0, 100),
          RawToken(Uint8List.fromList(bytes.sublist(2)), 100, 700),
        ]),
      ]);
      expect(transcript.segments.single.words.single.text, 'žluťoučký');
    });

    test('bracketed non-speech segments are dropped (§14 silence)', () {
      final transcript = assembleTranscript('en', [
        RawSegment(0, 900, [_token(' [BLANK', 0, 400), _token('_AUDIO]', 400, 800)]),
        RawSegment(900, 1500, [_token(' (applause)', 900, 1400)]),
        RawSegment(1500, 2000, [_token(' ♪', 1500, 1900)]),
      ]);
      expect(transcript.segments, isEmpty);
      expect(transcript.isEmpty, isTrue);
    });

    test('real speech next to a noise segment is kept', () {
      final transcript = assembleTranscript('en', [
        RawSegment(0, 500, [_token(' [BLANK_AUDIO]', 0, 400)]),
        RawSegment(500, 1200, [_token(' hello', 500, 1000)]),
      ]);
      expect(transcript.segments, hasLength(1));
      expect(transcript.segments.single.words.single.text, 'hello');
    });

    test('whitespace-only tokens vanish; negative times clamp to zero', () {
      final transcript = assembleTranscript('en', [
        RawSegment(-10, 600, [
          _token(' ', 0, 10),
          _token(' ok', -5, 300),
        ]),
      ]);
      final segment = transcript.segments.single;
      expect(segment.startMs, 0);
      expect(segment.words.single.text, 'ok');
      expect(segment.words.single.startMs, 0);
    });

    test('empty input → empty transcript', () {
      expect(assembleTranscript('en', []).isEmpty, isTrue);
      expect(assembleTranscript('en', [const RawSegment(0, 100, [])]).isEmpty,
          isTrue);
    });
  });

  group('CJK token-boundary words (§13 wave 2)', () {
    test('spaceless CJK tokens become per-token words with genuine token '
        'times — not one giant word', () {
      final transcript = assembleTranscript('zh', [
        RawSegment(0, 2000, [
          _token('今天', 0, 300),
          _token('天气', 300, 700),
          _token('很好', 700, 1100),
        ]),
      ]);
      final words = transcript.segments.single.words;
      expect(words.map((w) => w.text), ['今天', '天气', '很好']);
      expect(words[1].startMs, 300);
      expect(words[1].endMs, 700, reason: 'token times survive untouched — '
          'VAD interpolation already happened on the RawToken times');
    });

    test('a token split mid-character keeps accumulating until the char '
        'completes; the word spans both tokens', () {
      final bytes = utf8.encode('語'); // 3 bytes
      final transcript = assembleTranscript('ja', [
        RawSegment(0, 1000, [
          _token('日本', 0, 200),
          RawToken(Uint8List.fromList(bytes.sublist(0, 1)), 200, 300),
          RawToken(Uint8List.fromList(bytes.sublist(1)), 300, 500),
        ]),
      ]);
      final words = transcript.segments.single.words;
      expect(words.map((w) => w.text), ['日本', '語']);
      expect(words[1].startMs, 200);
      expect(words[1].endMs, 500);
    });

    test('kana runs flush per token, including the prolonged-sound mark', () {
      final transcript = assembleTranscript('ja', [
        RawSegment(0, 1000, [
          _token('コー', 0, 200),
          _token('ヒー', 200, 400),
          _token('を', 400, 500),
          _token('飲む', 500, 800),
        ]),
      ]);
      expect(transcript.segments.single.words.map((w) => w.text),
          ['コー', 'ヒー', 'を', '飲む']);
      expect(transcript.plainText, 'コーヒーを飲む');
    });

    test('code-switching: a CJK token after Latin pending closes the Latin '
        'word; Latin after CJK opens via the flush', () {
      final transcript = assembleTranscript('zh', [
        RawSegment(0, 2000, [
          _token('我用', 0, 300),
          _token('Fl', 300, 400),
          _token('utter', 400, 600),
          _token('写的', 600, 900),
        ]),
      ]);
      final words = transcript.segments.single.words;
      expect(words.map((w) => w.text), ['我用', 'Flutter', '写的']);
      expect(words[1].startMs, 300);
      expect(words[1].endMs, 600);
      expect(transcript.plainText, '我用 Flutter 写的');
    });

    test('CJK punctuation re-attaches: closers left, openers right', () {
      final transcript = assembleTranscript('ja', [
        RawSegment(0, 2000, [
          _token('です', 0, 300),
          _token('。', 300, 350),
          _token('「', 350, 400),
          _token('はい', 400, 700),
          _token('」', 700, 750),
        ]),
      ]);
      final words = transcript.segments.single.words;
      expect(words.map((w) => w.text), ['です。', '「はい」']);
      expect(words[0].endMs, 350);
      expect(words[1].startMs, 350);
      expect(transcript.plainText, 'です。「はい」');
    });

    test('Korean stays space-ruled — Hangul is not in the CJK no-space set',
        () {
      final transcript = assembleTranscript('ko', [
        RawSegment(0, 2000, [
          _token(' 안녕', 0, 300),
          _token('하세요', 300, 700),
          _token(' 저는', 800, 1200),
        ]),
      ]);
      expect(transcript.segments.single.words.map((w) => w.text),
          ['안녕하세요', '저는']);
    });

    test('fullwidth-bracketed noise segments drop like ASCII ones (§14)', () {
      final transcript = assembleTranscript('zh', [
        RawSegment(0, 1000, [_token('（', 0, 10), _token('字幕', 10, 500),
            _token('）', 500, 510)]),
        RawSegment(1000, 2000, [_token('真的', 1000, 1500)]),
      ]);
      expect(transcript.segments.single.words.single.text, '真的');
    });
  });
}
