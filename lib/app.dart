import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/theme.dart';

class DiktafonApp extends ConsumerWidget {
  const DiktafonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // System theme with manual override (§5.5).
    final theme = ref.watch(
        settingsProvider.select((s) => s.value?.theme ?? 'system'));
    return MaterialApp(
      title: 'Diktafon',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: const HomeScreen(),
    );
  }
}
