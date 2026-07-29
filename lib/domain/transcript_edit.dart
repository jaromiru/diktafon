/// Manual transcript editing (§6.9) — pure Dart, no I/O.
///
/// A hand-corrected text has to be mapped back onto the timed word structure
/// that drives playback highlight, tap-to-seek and follow-the-playhead:
/// words the edit left in place are *anchored* to their engine timings
/// (matched case-insensitively, ignoring edge punctuation — a comma fix must
/// not cost a word its real timing), and only the edited runs between
/// anchors are re-estimated proportionally to word length. The retired §6.8
/// LLM-cleanup re-timer pioneered the approach per segment; editing is
/// memo-wide because people edit across segment boundaries.
library;

import 'dart:math';

import 'models.dart';
import 'script.dart';

/// Maps [editedText] (the format of [Transcript.plainText]: one line per
/// segment) back onto [original]'s timings. Each non-empty line becomes a
/// segment whose span is its words'. Returns null when the edit holds no
/// words at all — there is nothing to store, the caller keeps the original.
///
/// A "no speech" memo (no timed words to anchor to) spreads the typed text
/// over the whole recording — [memoDurationMs] bounds the estimates then.
Transcript? retimeEditedTranscript(
  Transcript original,
  String editedText, {
  required int memoDurationMs,
}) {
  final lines = <List<String>>[];
  for (final line in editedText.split('\n')) {
    final tokens = _tokenizeLine(line);
    if (tokens.isNotEmpty) lines.add(tokens);
  }
  if (lines.isEmpty) return null;

  final newTokens = <String>[];
  final lineOf = <int>[];
  for (var l = 0; l < lines.length; l++) {
    for (final token in lines[l]) {
      newTokens.add(token);
      lineOf.add(l);
    }
  }

  final originalTokens = <_TimedToken>[
    for (final segment in original.segments)
      for (final word in segment.words) ..._explode(word),
  ];

  // The window the estimates spread over: the engine's segment bounds, or
  // the whole memo when there was nothing transcribed at all.
  final int spanStart;
  final int spanEnd;
  if (originalTokens.isEmpty) {
    spanStart = 0;
    spanEnd = max(0, memoDurationMs);
  } else {
    spanStart = original.segments.first.startMs;
    spanEnd = max(original.segments.last.endMs, spanStart);
  }

  final anchors = _anchor(
    [for (final t in originalTokens) _timingKey(t.text)],
    [for (final t in newTokens) _timingKey(t)],
  );

  final timed = List<_TimedToken?>.filled(newTokens.length, null);
  anchors.forEach((newIndex, originalIndex) {
    final engine = originalTokens[originalIndex];
    timed[newIndex] =
        _TimedToken(newTokens[newIndex], engine.startMs, engine.endMs);
  });

  // Each run of unanchored words shares the window between its neighbouring
  // anchors (memo edges at the ends), split by word length.
  var i = 0;
  while (i < timed.length) {
    if (timed[i] != null) {
      i++;
      continue;
    }
    var j = i;
    while (j < timed.length && timed[j] == null) {
      j++;
    }
    final left = i == 0 ? spanStart : timed[i - 1]!.endMs;
    final right = j == timed.length ? spanEnd : timed[j]!.startMs;
    final span = max(0, right - left);
    final weights = [
      for (var k = i; k < j; k++) newTokens[k].runes.length + 1,
    ];
    final total = weights.fold(0, (sum, w) => sum + w);
    var startMs = left;
    var used = 0;
    for (var k = i; k < j; k++) {
      used += weights[k - i];
      final endMs =
          max(startMs, k == j - 1 ? right : left + (span * used) ~/ total);
      timed[k] = _TimedToken(newTokens[k], startMs, endMs);
      startMs = endMs;
    }
    i = j;
  }

  // Engine timings are not guaranteed monotonic across odd tokenizations —
  // clamp so tap-to-seek never runs backwards inside the memo.
  var cursor = spanStart;
  for (final token in timed) {
    token!.startMs = max(token.startMs, cursor);
    token.endMs = max(token.endMs, token.startMs);
    cursor = token.endMs;
  }

  final segments = <Segment>[];
  var index = 0;
  for (var l = 0; l < lines.length; l++) {
    final words = <Word>[];
    for (; index < timed.length && lineOf[index] == l; index++) {
      final t = timed[index]!;
      words.add(Word(text: t.text, startMs: t.startMs, endMs: t.endMs));
    }
    segments.add(Segment(
        startMs: words.first.startMs, endMs: words.last.endMs, words: words));
  }
  return Transcript(languageCode: original.languageCode, segments: segments);
}

class _TimedToken {
  _TimedToken(this.text, this.startMs, this.endMs);

  final String text;
  int startMs;
  int endMs;
}

/// Splits an edited line into the granularity the pipeline stores: runs of
/// spaced text split on whitespace (punctuation stays attached, like the
/// engine's words), every CJK rune — word-forming or punctuation — its own
/// token. The flush CJK join in [Transcript.plainText] erases the engine's
/// token boundaries, so they cannot round-trip; single characters can, and
/// they render identically (the span build joins CJK neighbours flush).
List<String> _tokenizeLine(String line) {
  final tokens = <String>[];
  final pending = StringBuffer();
  void flush() {
    if (pending.isNotEmpty) {
      tokens.add(pending.toString());
      pending.clear();
    }
  }

  for (final rune in line.runes) {
    if (String.fromCharCode(rune).trim().isEmpty) {
      flush(); // whitespace first: U+3000 is also in the CJK-punct block
    } else if (isCjkWordRune(rune) || isCjkPunctRune(rune)) {
      flush();
      tokens.add(String.fromCharCode(rune));
    } else {
      pending.writeCharCode(rune);
    }
  }
  flush();
  return tokens;
}

/// Re-tokenizes an engine word for anchoring, splitting its span across the
/// parts by rune count. Spaced-script words come back whole (timings kept
/// exactly); CJK token-words explode into per-character sub-timings so they
/// can anchor against the re-tokenized edit.
List<_TimedToken> _explode(Word word) {
  final parts = _tokenizeLine(word.text);
  if (parts.length <= 1) {
    return [
      _TimedToken(
          parts.isEmpty ? word.text : parts.single, word.startMs, word.endMs),
    ];
  }
  final total = parts.fold(0, (sum, p) => sum + p.runes.length);
  final span = max(0, word.endMs - word.startMs);
  final out = <_TimedToken>[];
  var startMs = word.startMs;
  var used = 0;
  for (var i = 0; i < parts.length; i++) {
    used += parts[i].runes.length;
    final endMs = max(startMs,
        i == parts.length - 1 ? word.endMs : word.startMs + (span * used) ~/ total);
    out.add(_TimedToken(parts[i], startMs, endMs));
    startMs = endMs;
  }
  return out;
}

final _edgePunctuation =
    RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true);

/// How words are compared for anchoring: case-insensitive, edge punctuation
/// ignored — edits mostly fix casing and punctuation, and those fixes must
/// not cost a word its real timing.
String _timingKey(String word) =>
    word.toLowerCase().replaceAll(_edgePunctuation, '');

/// Beyond this many LCS cells the middle is left anchor-less (pure
/// proportional re-timing): hand-edits are local, so after peeling the
/// untouched prefix and suffix the table is tiny — only a wholesale rewrite
/// blows the cap, and there is nothing worth anchoring in one anyway.
const _lcsCellCap = 1000000;

/// `new index → original index` for every anchored pair: the shared prefix
/// and suffix positionally, the middle by longest common subsequence.
Map<int, int> _anchor(List<String> original, List<String> edited) {
  var prefix = 0;
  while (prefix < original.length &&
      prefix < edited.length &&
      original[prefix] == edited[prefix]) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < original.length - prefix &&
      suffix < edited.length - prefix &&
      original[original.length - 1 - suffix] ==
          edited[edited.length - 1 - suffix]) {
    suffix++;
  }

  final anchors = <int, int>{};
  for (var i = 0; i < prefix; i++) {
    anchors[i] = i;
  }
  for (var i = 0; i < suffix; i++) {
    anchors[edited.length - 1 - i] = original.length - 1 - i;
  }
  final midOriginal = original.length - prefix - suffix;
  final midEdited = edited.length - prefix - suffix;
  if (midOriginal > 0 &&
      midEdited > 0 &&
      midOriginal * midEdited <= _lcsCellCap) {
    _lcsAnchors(
      original.sublist(prefix, prefix + midOriginal),
      edited.sublist(prefix, prefix + midEdited),
    ).forEach((n, o) => anchors[n + prefix] = o + prefix);
  }
  return anchors;
}

/// Longest common subsequence over the two key lists; returns
/// `edited index → original index` for every matched pair. Empty keys (pure
/// punctuation) never match — there is no timing worth anchoring to.
Map<int, int> _lcsAnchors(List<String> original, List<String> edited) {
  final n = original.length, m = edited.length;
  final dp = [
    for (var i = 0; i <= n; i++) List<int>.filled(m + 1, 0),
  ];
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = original[i] == edited[j] && original[i].isNotEmpty
          ? dp[i + 1][j + 1] + 1
          : max(dp[i + 1][j], dp[i][j + 1]);
    }
  }
  final anchors = <int, int>{};
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (original[i] == edited[j] && original[i].isNotEmpty) {
      anchors[j] = i;
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return anchors;
}
