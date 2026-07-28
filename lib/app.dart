import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_resolution.dart';
import 'presentation/screens/first_run_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/theme.dart';

class DiktafonApp extends ConsumerWidget {
  const DiktafonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // System theme with manual override (§5.5).
    final theme = ref.watch(
        settingsProvider.select((s) => s.value?.theme ?? 'system'));
    // First run (§5.6) until walked through/skipped; null → settings still
    // streaming in — hold on blank paper rather than flashing the wrong home.
    final firstRunDone = ref.watch(
        settingsProvider.select((s) => s.value?.firstRunDone));
    return MaterialApp(
      title: 'Diktafon',
      debugShowCheckedModeBanner: false,
      // UI language follows the system locale (§13), independent of the
      // transcription language (D8). English is the fallback; script-less
      // zh locales resolve their script from the region (wave 2).
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: switch (firstRunDone) {
        null => const Scaffold(body: SizedBox.shrink()),
        false => const FirstRunScreen(),
        true => const HomeScreen(),
      },
    );
  }
}
