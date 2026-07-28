/// Chinese content-script handling (§13 wave 2, D8 amendment) — pure Dart.
///
/// Whisper has one `zh` and emits an uncontrolled script mix (mostly
/// Simplified); the app stores a script-qualified language and converts the
/// text to the user's script. Conversion is char-level over the OpenCC
/// character dictionaries — 1:1 codepoint-aligned, so word boundaries and
/// timings survive exactly. Known v1 limitation (documented, accepted):
/// phrase-level distinctions (发→發/髮) resolve by OpenCC's most frequent
/// variant, and regional vocabulary is not localized.
library;

import '../../domain/models.dart';
import '../../domain/script.dart';
import 'hans_hant_table.dart';

String toTraditional(String text) => _mapRunes(text, simplifiedToTraditional);
String toSimplified(String text) => _mapRunes(text, traditionalToSimplified);

String _mapRunes(String text, Map<String, String> table) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(table[ch] ?? ch);
  }
  return buffer.toString();
}

/// Converts LLM output (gists, overviews, titles) to the script its
/// language pins — belt-and-braces: the prompt already asks for
/// Simplified/Traditional Chinese, but small models drift.
String matchChineseScript(String text, String languageCode) =>
    switch (languageCode) {
      'zh-Hant' => toTraditional(text),
      'zh-Hans' => toSimplified(text),
      _ => text,
    };

/// Applies the D8 script preference to a fresh transcript: a Chinese one
/// (forced `zh-Hans`/`zh-Hant`, or auto-detected `zh` — the script then
/// comes from the system locale via [systemZhScript]) is converted
/// char-by-char and stored under the script-qualified code, which the
/// prompt layer and Han-unification rendering read back. Everything else —
/// including `yue`, whose conventional Traditional output whisper already
/// produces — passes through untouched.
Transcript resolveChineseScript(
  Transcript transcript, {
  String? appLanguage,
  required String Function() systemZhScript,
}) {
  final String script;
  if (appLanguage == 'zh-Hans' || appLanguage == 'zh-Hant') {
    script = appLanguage!.substring(3);
  } else if (appLanguage == null &&
      baseLanguageCode(transcript.languageCode) == 'zh' &&
      transcript.languageCode != 'zh-Hans' &&
      transcript.languageCode != 'zh-Hant') {
    script = systemZhScript();
  } else {
    return transcript;
  }

  final convert = script == 'Hant' ? toTraditional : toSimplified;
  return Transcript(
    languageCode: 'zh-$script',
    segments: [
      for (final segment in transcript.segments)
        Segment(
          startMs: segment.startMs,
          endMs: segment.endMs,
          words: [
            for (final word in segment.words)
              Word(
                text: convert(word.text),
                startMs: word.startMs,
                endMs: word.endMs,
              ),
          ],
        ),
    ],
  );
}
