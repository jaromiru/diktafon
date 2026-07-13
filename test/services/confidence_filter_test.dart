import 'dart:convert';

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/providers/whisper/word_timing.dart';
import 'package:flutter_test/flutter_test.dart';

Segment _segment(String text) => Segment(startMs: 0, endMs: 1000, words: [
      for (final w in text.split(' '))
        Word(text: w, startMs: 0, endMs: 1000),
    ]);

void main() {
  test('assembleTranscript emits confidence only for kept segments', () {
    final confidence = <SegmentConfidence>[];
    final transcript = assembleTranscript(
      'en',
      [
        RawSegment(0, 1000, [RawToken(utf8.encode(' hello'), 0, 500)],
            noSpeechProb: 0.1, avgTokenP: 0.9),
        // Bracketed stage direction — dropped by assembly.
        RawSegment(1000, 2000, [RawToken(utf8.encode(' [BLANK_AUDIO]'), 0, 0)],
            noSpeechProb: 0.9, avgTokenP: 0.2),
        RawSegment(2000, 3000, [RawToken(utf8.encode(' world'), 0, 500)],
            noSpeechProb: 0.7, avgTokenP: 0.3),
      ],
      confidenceOut: confidence,
    );
    expect(transcript.segments, hasLength(2));
    expect(confidence, hasLength(2));
    expect(confidence[0].noSpeechProb, closeTo(0.1, 1e-9));
    expect(confidence[1].avgTokenP, closeTo(0.3, 1e-9));
  });

  test('filterByConfidence drops only high-nsp AND low-p segments', () {
    final t = Transcript(languageCode: 'en', segments: [
      _segment('confident speech'),
      _segment('thank you for watching'),
      _segment('hesitant but real'),
    ]);
    final filtered = filterByConfidence(t, const [
      SegmentConfidence(0.1, 0.95), // clean speech — kept
      SegmentConfidence(0.9, 0.2), // classic hallucination — dropped
      SegmentConfidence(0.7, 0.8), // no-speech-ish but confident — kept
    ]);
    expect(filtered.segments.map((s) => s.words.first.text),
        ['confident', 'hesitant']);
  });

  test('filterByConfidence tolerates missing confidence entries', () {
    final t = Transcript(languageCode: 'en', segments: [
      _segment('one'),
      _segment('two'),
    ]);
    final filtered =
        filterByConfidence(t, const [SegmentConfidence(0.9, 0.1)]);
    expect(filtered.segments, hasLength(1),
        reason: 'segments without confidence are kept');
  });
}
