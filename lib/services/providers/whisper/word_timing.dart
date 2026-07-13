/// Whisper tokens → domain [Transcript] (§6.3). Pure Dart so the merging
/// rules are unit-testable without the native engine.
///
/// Whisper emits sub-word BPE tokens whose text is raw UTF-8 bytes; a token
/// may even end mid-way through a multi-byte character (Czech/Polish
/// diacritics). Bytes are therefore concatenated per *word* first and only
/// then decoded. A token starting with a space opens a new word; punctuation
/// tokens (no leading space) attach to the word before them.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../domain/models.dart';

/// One whisper token as it crosses the FFI boundary.
class RawToken {
  const RawToken(this.bytes, this.t0Ms, this.t1Ms);

  final Uint8List bytes;
  final int t0Ms;
  final int t1Ms;
}

class RawSegment {
  const RawSegment(this.t0Ms, this.t1Ms, this.tokens,
      {this.noSpeechProb = 0, this.avgTokenP = 1});

  final int t0Ms;
  final int t1Ms;
  final List<RawToken> tokens;

  /// Decoder confidence (noise-robust-transcription.md phase 1.3):
  /// hallucinations on noise show high [noSpeechProb] + low [avgTokenP].
  final double noSpeechProb;
  final double avgTokenP;
}

/// Confidence of one *kept* transcript segment — parallel to
/// `Transcript.segments` when collected via [assembleTranscript]'s
/// `confidenceOut`.
class SegmentConfidence {
  const SegmentConfidence(this.noSpeechProb, this.avgTokenP);

  final double noSpeechProb;
  final double avgTokenP;
}

/// Drops segments the decoder itself doesn't believe in — the literature's
/// practical hallucination filter (§3.3): high no-speech probability *and*
/// low mean token probability. Conservative defaults from the phase-0
/// bench, where genuine speech never hit both conditions at once.
Transcript filterByConfidence(
  Transcript t,
  List<SegmentConfidence> confidence, {
  double noSpeechThreshold = 0.6,
  double avgPThreshold = 0.4,
}) {
  final kept = <Segment>[];
  for (var i = 0; i < t.segments.length; i++) {
    final c = i < confidence.length
        ? confidence[i]
        : const SegmentConfidence(0, 1);
    if (c.noSpeechProb > noSpeechThreshold && c.avgTokenP < avgPThreshold) {
      continue;
    }
    kept.add(t.segments[i]);
  }
  return Transcript(languageCode: t.languageCode, segments: kept);
}

Transcript assembleTranscript(String languageCode, List<RawSegment> raw,
    {List<SegmentConfidence>? confidenceOut}) {
  const space = 0x20;
  final segments = <Segment>[];
  for (final rawSegment in raw) {
    final words = <Word>[];
    List<int>? pending;
    var startMs = 0;
    var endMs = 0;

    void flush() {
      if (pending == null) return;
      final text = utf8.decode(pending!, allowMalformed: true).trim();
      if (text.isNotEmpty) {
        words.add(Word(
          text: text,
          startMs: max(0, startMs),
          endMs: max(max(0, startMs), endMs),
        ));
      }
      pending = null;
    }

    for (final token in rawSegment.tokens) {
      if (token.bytes.isEmpty) continue;
      if (pending == null || token.bytes.first == space) {
        flush();
        pending = <int>[];
        startMs = token.t0Ms;
      }
      pending!.addAll(token.bytes);
      endMs = token.t1Ms;
    }
    flush();

    if (words.isEmpty || _isNonSpeech(words)) continue;
    segments.add(Segment(
      startMs: max(0, rawSegment.t0Ms),
      endMs: max(0, rawSegment.t1Ms),
      words: words,
    ));
    confidenceOut?.add(
        SegmentConfidence(rawSegment.noSpeechProb, rawSegment.avgTokenP));
  }
  return Transcript(languageCode: languageCode, segments: segments);
}

/// Whisper renders non-speech as bracketed stage directions — "[BLANK_AUDIO]",
/// "(applause)", "♪…♪". On silent memos these are noise, not words (§14
/// "empty/near-silent memo": the transcript may be empty).
bool _isNonSpeech(List<Word> words) {
  final text = words.map((w) => w.text).join(' ');
  final bracketed = (text.startsWith('[') && text.endsWith(']')) ||
      (text.startsWith('(') && text.endsWith(')'));
  if (bracketed) return true;
  const notes = {0x266A, 0x266B}; // ♪ ♫
  return words
      .every((w) => w.text.runes.every((rune) => notes.contains(rune)));
}
