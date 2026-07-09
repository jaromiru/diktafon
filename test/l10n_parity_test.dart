/// Locale plumbing checks: gen-l10n silently falls back to English for any
/// message a locale forgot to translate, and prompts fall back to the raw
/// language code — both are enforced here instead.
library;

import 'dart:convert';
import 'dart:io';

import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/screens/settings_screen.dart';
import 'package:diktafon/services/providers/llm/summary_prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Set<String> keysOf(File f) =>
      (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)
          .keys
          .where((k) => !k.startsWith('@'))
          .toSet();

  test('every locale ARB carries every template message', () {
    final template = keysOf(File('lib/l10n/app_en.arb'));
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();
    expect(arbs.length, greaterThanOrEqualTo(10),
        reason: 'en fr es pt de pl cs tr ru ko');
    for (final arb in arbs) {
      expect(keysOf(arb), template, reason: arb.path);
    }
  });

  test('every Settings picker language has a prompt language name', () {
    for (final code in SettingsScreen.languages.keys) {
      expect(languageName(code), isNot(code),
          reason: 'prompts would read "Write a summary in $code"');
    }
  });

  test('every locale loads and its plural messages resolve', () async {
    expect(AppLocalizations.supportedLocales, hasLength(10));
    // 1/2/5/21 hit en =1, cs few/other, ru one/few/many (21 → one), ko other.
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final count in [1, 2, 5, 21]) {
        expect(l10n.memoCount(count), contains('$count'),
            reason: '$locale memoCount($count)');
        expect(l10n.deleteCassetteBody('x', count), isNotEmpty);
        expect(l10n.exportedAllTo(count, '/tmp'), isNotEmpty);
        expect(l10n.retranscribeBody(count), isNotEmpty);
      }
    }
  });
}
