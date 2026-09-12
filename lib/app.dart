import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_resolution.dart';
import 'presentation/screens/first_run_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/theme.dart';

class DiktafonApp extends ConsumerStatefulWidget {
  const DiktafonApp({super.key});

  @override
  ConsumerState<DiktafonApp> createState() => _DiktafonAppState();
}

class _DiktafonAppState extends ConsumerState<DiktafonApp> {
  StreamSubscription<String>? _summaryIssuesSub;

  @override
  void initState() {
    super.initState();
    // §14: a cassette overview that failed for good has no per-memo retry
    // link to live behind — announce it once, tap anywhere to re-queue.
    _summaryIssuesSub = ref
        .read(jobQueueProvider)
        .summaryIssues
        .listen((cassetteId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.cassetteSummaryFailed),
        duration: const Duration(seconds: 6),
      ));
      // Re-queue right away: the drain runs while the snackbar is up, and
      // a success typically lands before the user could tap anything.
      unawaited(
          ref.read(jobQueueProvider).retryCassetteSummary(cassetteId));
    });
  }

  @override
  void dispose() {
    _summaryIssuesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
