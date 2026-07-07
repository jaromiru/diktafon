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
}
