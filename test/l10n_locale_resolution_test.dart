/// UI-locale resolution for Chinese scripts (§13 wave 2): script-less
/// system locales must land on the right ARB by region.
library;

import 'dart:ui';

import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/l10n/locale_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final supported = AppLocalizations.supportedLocales;

  Locale resolve(List<Locale> preferred) =>
      resolveAppLocale(preferred, supported);

  test('supported set carries both Chinese scripts', () {
    expect(supported.where((l) => l.languageCode == 'zh'), hasLength(2));
  });

  test('script-less zh resolves by region', () {
    expect(resolve([const Locale('zh', 'TW')]).toString(), 'zh_Hant');
    expect(resolve([const Locale('zh', 'HK')]).toString(), 'zh_Hant');
    expect(resolve([const Locale('zh', 'MO')]).toString(), 'zh_Hant');
    expect(resolve([const Locale('zh', 'CN')]).languageCode, 'zh');
    expect(resolve([const Locale('zh', 'CN')]).scriptCode, isNull);
    expect(resolve([const Locale('zh', 'SG')]).scriptCode, isNull);
  });

  test('explicit scripts resolve directly', () {
    expect(
        resolve([
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW')
        ]).toString(),
        'zh_Hant');
    expect(
        resolve([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
        ]).scriptCode,
        isNull,
        reason: 'Hans is the base zh ARB');
  });

  test('non-Chinese locales are untouched; unsupported falls back', () {
    expect(resolve([const Locale('it')]).languageCode, 'it');
    expect(resolve([const Locale('xx'), const Locale('uk')]).languageCode,
        'uk');
  });

  test('the notification lookup pad qualifies script-less zh too', () {
    expect(padZhLocale(const Locale('zh', 'TW')).scriptCode, 'Hant');
    expect(padZhLocale(const Locale('zh', 'CN')).scriptCode, 'Hans');
    expect(padZhLocale(const Locale('cs')).scriptCode, isNull);
    expect(
        lookupAppLocalizations(padZhLocale(const Locale('zh', 'TW')))
            .settingsTitle,
        lookupAppLocalizations(
                const Locale.fromSubtags(
                    languageCode: 'zh', scriptCode: 'Hant'))
            .settingsTitle);
  });
}
