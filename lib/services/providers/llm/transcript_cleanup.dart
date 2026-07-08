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

/// Rebuilds a segment around [newText]: the segment's span is kept and
/// word timings are re-estimated proportionally to word length, so
/// tap-to-seek stays segment-accurate (approximate within it). Unchanged
/// text keeps the engine's real timings.
Segment retimedSegment(Segment original, String newText) {
  final originalText = original.words.map((w) => w.text).join(' ');
  if (newText == originalText) return original;
  final words =
      newText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return original;

  final span = original.endMs - original.startMs;
  final weights = [for (final w in words) w.length + 1];
  final total = weights.fold(0, (sum, w) => sum + w);
  final timed = <Word>[];
  var startMs = original.startMs;
  var used = 0;
  for (var i = 0; i < words.length; i++) {
    used += weights[i];
    final endMs = i == words.length - 1
        ? original.endMs
        : original.startMs + (span * used) ~/ total;
    timed.add(Word(text: words[i], startMs: startMs, endMs: endMs));
    startMs = endMs;
  }
  return Segment(startMs: original.startMs, endMs: original.endMs, words: timed);
}
