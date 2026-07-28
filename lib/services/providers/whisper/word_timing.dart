/// Whisper tokens → domain [Transcript] (§6.3). Pure Dart so the merging
/// rules are unit-testable without the native engine.
///
/// Whisper emits sub-word BPE tokens whose text is raw UTF-8 bytes; a token
/// may even end mid-way through a multi-byte character (Czech/Polish
/// diacritics). Bytes are therefore concatenated per *word* first and only
/// then decoded. A token starting with a space opens a new word; punctuation
/// tokens (no leading space) attach to the word before them.
///
/// CJK (§13 wave 2): ja/zh segments carry no spaces at all, which under the
/// space rule collapsed a whole segment into one giant word — tap-to-seek,
/// highlight and follow-seek degraded to segment granularity. Tokens whose
/// accumulated bytes decode to text *ending in* a CJK word rune flush at the
/// token boundary instead: words of ~1–3 CJK chars carrying genuine whisper
/// token timings, which is also whisper's native timing resolution. Tokens
/// split mid-character keep accumulating until the char completes. CJK
/// punctuation then re-attaches to its neighbour (。left, 「right), and a
/// CJK token opening after non-CJK pending text closes the pending word —
/// code-switching keeps clean boundaries. Korean has spaces: untouched.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../domain/models.dart';
import '../../../domain/script.dart';

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
      if (pending == null ||
          token.bytes.first == space ||
          _cjkOpensAfter(pending!, token.bytes) ||
          _cjkPunctBreak(pending!, token.bytes)) {
        flush();
        pending = <int>[];
        startMs = token.t0Ms;
      }
      pending!.addAll(token.bytes);
      endMs = token.t1Ms;
      if (_endsInCjkWord(pending!)) flush();
    }
    flush();
    _mergeCjkPunct(words);

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

/// True when the accumulated word bytes decode cleanly to text whose last
/// rune is a CJK word rune — the token boundary is then a word boundary.
/// A mid-character byte split throws on strict decode → keep accumulating.
bool _endsInCjkWord(List<int> pending) {
  final String text;
  try {
    text = utf8.decode(pending).trim();
  } on FormatException {
    return false;
  }
  return text.isNotEmpty && isCjkWordRune(text.runes.last);
}

/// True when a spaceless token opens CJK text after pending non-CJK bytes
/// ("我用Flutter写的": the 写 token must not glue onto "Flutter"). The
/// pending bytes decode cleanly by construction here (a mid-char split can
/// only continue the same word); a malformed token head decodes to U+FFFD,
/// which is not CJK, so it safely keeps accumulating.
bool _cjkOpensAfter(List<int> pending, Uint8List tokenBytes) {
  final String text;
  try {
    text = utf8.decode(pending).trim();
  } on FormatException {
    return false;
  }
  if (text.isEmpty) return false;
  final head = utf8.decode(tokenBytes, allowMalformed: true).trimLeft();
  return head.isNotEmpty && isCjkWordRune(head.runes.first);
}

/// "です。" then "「" must not glue into one pending run — the closer
/// belongs to the sentence before, the opener to the quote after, and each
/// needs its own token timing for [_mergeCjkPunct] to hand out.
bool _cjkPunctBreak(List<int> pending, Uint8List tokenBytes) {
  final String text;
  try {
    text = utf8.decode(pending).trim();
  } on FormatException {
    return false;
  }
  if (text.isEmpty) return false;
  final last = text.runes.last;
  if (!isCjkPunctRune(last) || _openingCjkPunct.contains(last)) return false;
  final head = utf8.decode(tokenBytes, allowMalformed: true).trimLeft();
  return head.isNotEmpty && _openingCjkPunct.contains(head.runes.first);
}

const _openingCjkPunct = {
  0x3008, 0x300A, 0x300C, 0x300E, 0x3010, 0x3014, 0x3016, 0x3018, 0x301A,
  0x301D, // 〈《「『【〔〖〘〚〝
  0xFF08, 0xFF3B, 0xFF5B, 0xFF5F, 0xFF62, // （［｛｟｢
};

/// Per-token CJK flushing leaves punctuation stranded as its own "word"
/// (…"です", "。"…). Re-attach it in place: closers and separators merge
/// left (です。), openers merge right (「こんにちは). Latin punctuation
/// never strands — it arrives glued to its word's own token run.
void _mergeCjkPunct(List<Word> words) {
  bool punctOnly(Word w, bool Function(int) klass) =>
      w.text.runes.isNotEmpty && w.text.runes.every(klass);

  for (var i = words.length - 1; i >= 0; i--) {
    final word = words[i];
    if (!punctOnly(word, isCjkPunctRune)) continue;
    if (punctOnly(word, _openingCjkPunct.contains) && i + 1 < words.length) {
      final next = words[i + 1];
      words[i + 1] = Word(
        text: word.text + next.text,
        startMs: word.startMs,
        endMs: next.endMs,
      );
      words.removeAt(i);
    } else if (!punctOnly(word, _openingCjkPunct.contains) && i > 0) {
      final prev = words[i - 1];
      words[i - 1] = Word(
        text: prev.text + word.text,
        startMs: prev.startMs,
        endMs: max(prev.endMs, word.endMs),
      );
      words.removeAt(i);
    }
  }
}

/// Whisper renders non-speech as bracketed stage directions — "[BLANK_AUDIO]",
/// "(applause)", "♪…♪". On silent memos these are noise, not words (§14
/// "empty/near-silent memo": the transcript may be empty).
bool _isNonSpeech(List<Word> words) {
  final text = words.map((w) => w.text).join(' ');
  const brackets = [('[', ']'), ('(', ')'), ('（', '）'), ('【', '】')];
  final bracketed = brackets
      .any((b) => text.startsWith(b.$1) && text.endsWith(b.$2));
  if (bracketed) return true;
  const notes = {0x266A, 0x266B}; // ♪ ♫
  return words
      .every((w) => w.text.runes.every((rune) => notes.contains(rune)));
}
