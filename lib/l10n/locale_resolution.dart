/// UI-locale resolution helpers (§13 wave 2).
///
/// Flutter's basic resolution never infers a Chinese script from the
/// region, so a device reporting plain `zh-TW` (script-less, still common
/// on Android) would land on the base `zh` (Simplified) ARB. Padding the
/// preference list with the region-inferred script first lets the standard
/// algorithm match `zh-Hant` where it should.
library;

import 'dart:ui';

import 'package:flutter/widgets.dart' show basicLocaleListResolution;

import '../domain/script.dart';

/// A `zh` locale without a script gains the one its region implies;
/// everything else passes through.
Locale padZhLocale(Locale locale) =>
    locale.languageCode == 'zh' && locale.scriptCode == null
        ? Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: zhScriptFor(countryCode: locale.countryCode),
            countryCode: locale.countryCode,
          )
        : locale;

/// Drop-in `localeListResolutionCallback`.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) =>
    basicLocaleListResolution(
        preferred?.map(padZhLocale).toList(), supported);
