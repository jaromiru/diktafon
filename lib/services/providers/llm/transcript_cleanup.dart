/// Prompt building, reply parsing and guardrails for LLM transcript cleanup
/// (§6.8). Pure Dart (unit-testable), shared by the provider.
///
/// The contract: segments go to the model as numbered lines and must come
/// back as the same numbered lines, corrected. A small local model *will*
/// sometimes mangle its answer, so every guardrail falls back to the
/// original text — cleanup may only ever be a no-op, never a loss.
library;

import 'dart:math';

import '../../../domain/models.dart';
import 'summary_prompts.dart' show LlmPrompt, languageName;

const _system =
    'You clean up automatic speech-recognition transcripts. Reply with only '
    'the requested numbered lines — no preamble, no explanations.';

/// Per-request char budget: keeps prompt + echoed output well inside the
/// 4096-token context (~3 chars/token) with the instruction overhead.
const cleanupCharBudget = 3500;

/// A run of consecutive segments that fits one LLM exchange.
class CleanupBatch {
  const CleanupBatch(this.startIndex, this.lines);

  /// Index of the first segment (into the transcript's segment list).
  final int startIndex;

  /// The segments' original texts, in order.
  final List<String> lines;

  LlmPrompt prompt(String languageCode) {
    final numbered = [
      for (var i = 0; i < lines.length; i++) '${i + 1}: ${lines[i]}',
    ].join('\n');
    final budget = lines.fold(0, (sum, l) => sum + l.length);
    return LlmPrompt(
      _system,
      'Lines from an automatic speech transcript in '
      '${languageName(languageCode)}:\n$numbered\n\n'
      'Correct obvious recognition errors: misheard words, spelling, '
      'punctuation, casing. Keep the original language, the speaker\'s '
      'wording and the meaning. Do not translate, do not add or drop '
      'content, do not merge, split or reorder lines. Reply with exactly '
      'the same numbered lines, corrected; repeat lines that are already '
      'fine unchanged.\n/no_think',
      // Room to echo every line back, plus numbering slack.
      maxTokens: min(2048, 64 + budget),
    );
  }
}

/// Splits a transcript into consecutive-segment batches within the char
/// budget. Segments without words are skipped (nothing to clean — and the
/// numbered-line contract needs non-empty lines).
List<CleanupBatch> cleanupBatches(Transcript t) {
  final batches = <CleanupBatch>[];
  var start = 0;
  var lines = <String>[];
  var chars = 0;
  void flush() {
    if (lines.isNotEmpty) batches.add(CleanupBatch(start, lines));
    lines = <String>[];
    chars = 0;
  }

  for (var i = 0; i < t.segments.length; i++) {
    final text = t.segments[i].words.map((w) => w.text).join(' ');
    if (text.isEmpty) {
      flush();
      start = i + 1;
      continue;
    }
    if (lines.isEmpty) start = i;
    if (chars + text.length > cleanupCharBudget && lines.isNotEmpty) {
      flush();
      start = i;
    }
    lines.add(text);
    chars += text.length;
  }
  flush();
  return batches;
}

final _thinkBlock = RegExp(r'<think>[\s\S]*?</think>', multiLine: true);
final _numberedLine = RegExp(r'^\s*(\d+)\s*[:.)\-]\s*(.*)$');

/// Parses the model's reply back into one cleaned text per batch line,
/// falling back to the original wherever the reply is unusable: a missing
/// or empty line, or a length so far off the original (outside 0.5–2×,
/// with slack for very short lines) that the model likely rewrote rather
/// than corrected.
List<String> applyCleanupReply(CleanupBatch batch, String reply) {
  var text = reply.replaceAll(_thinkBlock, '');
  final unclosed = text.indexOf('<think>');
  if (unclosed >= 0) text = text.substring(0, unclosed);

  final replies = <int, String>{};
  for (final line in text.split('\n')) {
    final match = _numberedLine.firstMatch(line);
    if (match == null) continue;
    final n = int.parse(match.group(1)!);
    if (n < 1 || n > batch.lines.length) continue;
    // A duplicated number means the model lost the plot — first one wins.
    replies.putIfAbsent(n, () => match.group(2)!.trim());
  }

  return [
    for (var i = 0; i < batch.lines.length; i++)
      _guarded(batch.lines[i], replies[i + 1]),
  ];
}

String _guarded(String original, String? cleaned) {
  if (cleaned == null || cleaned.isEmpty) return original;
  final slack = 12; // short lines legitimately grow ("ok" → "OK, done.")
  final lower = original.length / 2 - slack;
  final upper = original.length * 2 + slack;
  if (cleaned.length < lower || cleaned.length > upper) return original;
  return cleaned;
}

/// Rebuilds a segment around [newText]: the segment's span is kept, words
/// the cleanup left in place (matched case-insensitively, ignoring edge
/// punctuation) are *anchored* to their engine timings, and only the gaps
/// between anchors are re-estimated proportionally to word length. A comma
/// fix must not smear the timing of every other word in the line — playback
/// highlight and tap-to-seek stay word-accurate wherever the text survived.
Segment retimedSegment(Segment original, String newText) {
  final originalText = original.words.map((w) => w.text).join(' ');
  if (newText == originalText) return original;
  final words =
      newText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return original;

  final anchors = _lcsAnchors(
    [for (final w in original.words) _timingKey(w.text)],
    [for (final w in words) _timingKey(w)],
  );

  final timed = List<Word?>.filled(words.length, null);
  anchors.forEach((newIndex, originalIndex) {
    final engine = original.words[originalIndex];
    timed[newIndex] =
        Word(text: words[newIndex], startMs: engine.startMs, endMs: engine.endMs);
  });

  // Each run of unanchored words shares the window between its neighbouring
  // anchors (segment edges at the ends), split by word length.
  var i = 0;
  while (i < words.length) {
    if (timed[i] != null) {
      i++;
      continue;
    }
    var j = i;
    while (j < words.length && timed[j] == null) {
      j++;
    }
    final left = i == 0 ? original.startMs : timed[i - 1]!.endMs;
    final right = j == words.length ? original.endMs : timed[j]!.startMs;
    final span = max(0, right - left);
    final weights = [for (var k = i; k < j; k++) words[k].length + 1];
    final total = weights.fold(0, (sum, w) => sum + w);
    var startMs = left;
    var used = 0;
    for (var k = i; k < j; k++) {
      used += weights[k - i];
      final endMs =
          max(startMs, k == j - 1 ? right : left + (span * used) ~/ total);
      timed[k] = Word(text: words[k], startMs: startMs, endMs: endMs);
      startMs = endMs;
    }
    i = j;
  }

  // Engine timings are not guaranteed monotonic across odd tokenizations —
  // clamp so tap-to-seek never runs backwards inside the segment.
  final ordered = <Word>[];
  var cursor = original.startMs;
  for (final word in timed) {
    final startMs = max(word!.startMs, cursor);
    final endMs = max(word.endMs, startMs);
    ordered.add(Word(text: word.text, startMs: startMs, endMs: endMs));
    cursor = endMs;
  }
  return Segment(
      startMs: original.startMs, endMs: original.endMs, words: ordered);
}

final _edgePunctuation =
    RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true);

/// How words are compared for anchoring: case-insensitive, edge punctuation
/// ignored — cleanup mostly fixes casing and punctuation, and those fixes
/// must not cost a word its real timing.
String _timingKey(String word) =>
    word.toLowerCase().replaceAll(_edgePunctuation, '');

/// Longest common subsequence over the two key lists; returns
/// `new index → original index` for every matched pair. Empty keys (pure
/// punctuation) never match — there is no timing worth anchoring to.
Map<int, int> _lcsAnchors(List<String> original, List<String> cleaned) {
  final n = original.length, m = cleaned.length;
  final dp = [
    for (var i = 0; i <= n; i++) List<int>.filled(m + 1, 0),
  ];
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = original[i] == cleaned[j] && original[i].isNotEmpty
          ? dp[i + 1][j + 1] + 1
          : max(dp[i + 1][j], dp[i][j + 1]);
    }
  }
  final anchors = <int, int>{};
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (original[i] == cleaned[j] && original[i].isNotEmpty) {
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
