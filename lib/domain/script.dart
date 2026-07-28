/// Script-aware text assembly (§13 wave 2) — pure Dart, no I/O, no Flutter.
///
/// CJK scripts (Han, kana) write without spaces between words, and the
/// transcript pipeline produces per-token words for them (§6.3): every place
/// that flattens words back into text — [Transcript.plainText], clipboard
/// copy, `transcript.md` export, the transcript span tree — must join
/// CJK-adjacent words with nothing and everything else with a space, or
/// Chinese/Japanese text comes out r i d d l e d with spaces. Korean is
/// spaced like Latin and deliberately not in the no-space class.
library;

bool _inAny(int rune, List<(int, int)> ranges) {
  for (final (lo, hi) in ranges) {
    if (rune >= lo && rune <= hi) return true;
  }
  return false;
}

/// Word-forming CJK: Han (incl. compat + astral extensions), hiragana,
/// katakana (incl. phonetic extensions and the U+30FC prolonged-sound mark),
/// and the iteration marks 々〆〇 from the punctuation block.
bool isCjkWordRune(int rune) => _inAny(rune, const [
      (0x3005, 0x3007), // 々〆〇 — word-forming despite the block
      (0x3040, 0x30FF), // hiragana + katakana
      (0x31F0, 0x31FF), // katakana phonetic extensions
      (0x3400, 0x9FFF), // Han (ext A + unified)
      (0xF900, 0xFAFF), // Han compatibility
      (0x20000, 0x2FA1F), // Han ext B+ (astral)
    ]);

/// CJK punctuation and fullwidth forms — 。、！？「」（）… They attach to
/// neighbouring CJK text without spaces on either side.
bool isCjkPunctRune(int rune) => _inAny(rune, const [
      (0x3000, 0x3004), // ideographic space, 。 、 〃 〄
      (0x3008, 0x303F), // brackets, marks (々〆〇 carved out above)
      (0xFF00, 0xFF0F), // fullwidth ！＂＃…／ (，．)
      (0xFF1A, 0xFF20), // fullwidth ：；＜…＠ (？)
      (0xFF3B, 0xFF40), // fullwidth ［＼］…｀
      (0xFF5B, 0xFF65), // fullwidth ｛｜｝～ + halfwidth 。「」、・
    ]);

bool _noSpaceRune(int rune) => isCjkWordRune(rune) || isCjkPunctRune(rune);

/// True when [prev] and [next] sit flush against each other in running text:
/// the boundary runes on both sides belong to the CJK no-space class.
/// Latin↔CJK boundaries (code-switching) keep a space — "我用 Flutter 写的".
bool joinsWithoutSpace(String prev, String next) {
  if (prev.isEmpty || next.isEmpty) return true;
  return _noSpaceRune(prev.runes.last) && _noSpaceRune(next.runes.first);
}

/// The separator rendered/copied between two adjacent transcript words.
String wordSeparator(String prev, String next) =>
    joinsWithoutSpace(prev, next) ? '' : ' ';

/// Joins words with script-aware separators — the CJK-safe `join(' ')`.
String joinWords(Iterable<String> words) {
  final buffer = StringBuffer();
  String? prev;
  for (final word in words) {
    if (prev != null) buffer.write(wordSeparator(prev, word));
    buffer.write(word);
    prev = word;
  }
  return buffer.toString();
}

/// The language subtag alone — 'zh-Hans' → 'zh'. Whisper and the plural
/// logic want bare codes; script-qualified ones are an app-level convention
/// (D8: the Chinese content-script preference).
String baseLanguageCode(String code) {
  final dash = code.indexOf('-');
  return dash < 0 ? code : code.substring(0, dash);
}
