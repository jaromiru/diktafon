import 'dart:ui';

/// Locale tag for *content* text — transcripts, gists, the cassette
/// overview — as opposed to UI chrome, which inherits the app locale.
///
/// Han unification (§13 wave 2): with ja and zh in one app, a kanji
/// paragraph rendered under a zh app locale (or vice versa) picks the wrong
/// glyph variants out of the fallback fonts unless the text carries its own
/// locale. Derived from the memo's detected/forced language; script-
/// qualified Chinese keeps its script, and Cantonese conventionally writes
/// Traditional. Null in → null out (inherit the ambient locale).
Locale? contentLocale(String? languageCode) {
  if (languageCode == null || languageCode.isEmpty) return null;
  return switch (languageCode) {
    'zh-Hans' =>
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    'zh-Hant' || 'yue' =>
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    _ => Locale(languageCode),
  };
}
