/// Prompt building + output cleanup for the local summarization LLM.
/// Pure Dart (unit-testable), engine-agnostic on the way in — the only
/// model-family accommodation is the trailing `/no_think` soft switch,
/// which Qwen3 honours and other instruct models ignore as noise.
library;

import '../../../domain/models.dart';
import '../summarization_provider.dart';

/// One chat exchange for the worker.
class LlmPrompt {
  const LlmPrompt(this.system, this.user, {required this.maxTokens});

  final String system;
  final String user;
  final int maxTokens;
}

/// Instructions are English (small models follow English instructions most
/// reliably); the *output* language is pinned explicitly (D8).
String languageName(String code) =>
    const {
      'en': 'English',
      'fr': 'French',
      'es': 'Spanish',
      'pt': 'Portuguese',
      'de': 'German',
      'pl': 'Polish',
      'cs': 'Czech',
      'tr': 'Turkish',
      'ru': 'Russian',
      'ko': 'Korean',
    }[code] ??
    code;

const _system =
    'You summarize personal voice memos. Reply with only the requested text — '
    'no preamble, no explanations, no quotation marks.';

/// Budgets keep prompts inside the model's 4096-token context window with
/// generous slack. They are counted in *estimated tokens*, not chars: the
/// old ~3 chars/token assumption holds for latin scripts but Hangul runs
/// ~1.6 and Cyrillic ~2.2 chars/token on Qwen-style BPE — a flat char
/// budget would overflow the window for ko and cut it close for ru.
const transcriptTokenBudget = 3000;
const digestsTokenBudget = 2000;

/// Estimated token cost of one UTF-16 code unit, by script block. Values
/// sit at the token-hungry end of each range so budgets err short.
double _unitTokenCost(int unit) {
  if (unit < 0x0370) return 1 / 3; // latin + latin-ext, digits, punctuation
  if (unit >= 0xD800 && unit <= 0xDFFF) return 0.5; // astral pair halves
  if ((unit >= 0xAC00 && unit <= 0xD7AF) || // Hangul syllables
      (unit >= 0x1100 && unit <= 0x11FF) || // Hangul jamo
      (unit >= 0x3130 && unit <= 0x318F)) {
    return 0.625; // ~1.6 chars/token
  }
  if ((unit >= 0x3000 && unit <= 0x30FF) || // CJK punctuation, kana
      (unit >= 0x3400 && unit <= 0x9FFF) || // Han
      (unit >= 0xF900 && unit <= 0xFAFF) ||
      (unit >= 0xFF00 && unit <= 0xFFEF)) {
    return 1; // ~1 char/token
  }
  return 0.45; // Cyrillic, Greek, Arabic, Devanagari, … — ~2.2 chars/token
}

int estimateTokens(String text) {
  var cost = 0.0;
  for (final unit in text.codeUnits) {
    cost += _unitTokenCost(unit);
  }
  return cost.ceil();
}

String truncateTokens(String text, int budget) {
  var cost = 0.0;
  final units = text.codeUnits;
  for (var i = 0; i < units.length; i++) {
    cost += _unitTokenCost(units[i]);
    if (cost > budget) {
      // Never cut between surrogate halves.
      final cut = units[i] >= 0xDC00 && units[i] <= 0xDFFF ? i - 1 : i;
      return '${text.substring(0, cut)} …';
    }
  }
  return text;
}

/// The 1–2 sentence "what the speaker meant to say" gist (§6.7).
LlmPrompt memoSummaryPrompt(Transcript t, {required String languageCode}) {
  final text = truncateTokens(t.plainText, transcriptTokenBudget);
  return LlmPrompt(
    _system,
    'Voice memo transcript:\n$text\n\n'
    'Write a summary in ${languageName(languageCode)} of what the speaker '
    'meant to say: 1–2 short sentences, at most 30 words. '
    'Only output the summary.\n/no_think',
    maxTokens: 160,
  );
}

/// Folds new memo digests into the rolling cassette overview (§6.7).
LlmPrompt cassetteSummaryPrompt({
  required String? previousSummary,
  required List<MemoDigest> newMemos,
  required String languageCode,
}) {
  final digests = truncateTokens(
      newMemos.map((m) => '- ${m.memoSummary}').join('\n'),
      digestsTokenBudget);
  final language = languageName(languageCode);
  final user = previousSummary == null
      ? 'Notes from a collection of voice memos:\n$digests\n\n'
          'Write an overview in $language of the key points: '
          'at most 3 short sentences. Only output the overview.\n/no_think'
      : 'Current overview of a collection of voice memos:\n'
          '$previousSummary\n\n'
          'Newly added memos:\n$digests\n\n'
          'Update the overview in $language to include the new memos, '
          'keeping the still-relevant key points: at most 3 short '
          'sentences. Only output the updated overview.\n/no_think';
  return LlmPrompt(_system, user, maxTokens: 220);
}

/// The auto-suggested cassette title (D10) — derived from the overview.
LlmPrompt titlePrompt(String cassetteSummary, {required String languageCode}) {
  return LlmPrompt(
    _system,
    'Overview of a collection of voice memos:\n'
    '${truncateTokens(cassetteSummary, digestsTokenBudget)}\n\n'
    'Suggest a topic title in ${languageName(languageCode)}: 1–4 words, '
    'like a folder name. Only output the title.\n/no_think',
    maxTokens: 24,
  );
}

final _thinkBlock = RegExp(r'<think>[\s\S]*?</think>', multiLine: true);
final _quotePairs = [
  ('"', '"'), ('“', '”'), ('„', '“'), ('«', '»'), ("'", "'"), ('‚', '‘'),
];

/// Normalizes raw model output into displayable text: drops Qwen3 think
/// blocks (including one left unclosed by the token cap), unwraps quoting
/// the model added despite instructions, and collapses whitespace — stored
/// summaries are flowing text, not markdown.
String cleanLlmOutput(String raw) {
  var text = raw.replaceAll(_thinkBlock, '');
  final unclosed = text.indexOf('<think>');
  if (unclosed >= 0) text = text.substring(0, unclosed);
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final (open, close) in _quotePairs) {
    if (text.length >= 2 && text.startsWith(open) && text.endsWith(close)) {
      text = text.substring(1, text.length - 1).trim();
    }
  }
  return text;
}

/// Titles additionally lose list markers, trailing punctuation and length
/// beyond what a cassette label can carry.
String cleanTitle(String raw) {
  var title = cleanLlmOutput(raw)
      .replaceFirst(RegExp(r'^[-–•*#\s]+'), '')
      .replaceFirst(RegExp(r'[.。!?:;,\s]+$'), '');
  if (title.length > 60) {
    title = title.substring(0, 60).trim();
  }
  return title;
}
