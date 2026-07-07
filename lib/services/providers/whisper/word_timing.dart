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
  const RawSegment(this.t0Ms, this.t1Ms, this.tokens);

  final int t0Ms;
  final int t1Ms;
  final List<RawToken> tokens;
}

Transcript assembleTranscript(String languageCode, List<RawSegment> raw) {
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
