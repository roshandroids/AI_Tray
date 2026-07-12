import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/core/theme/theme_controller.dart';
import 'package:ai_tray/features/usage/presentation/usage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
class AiTrayApp extends ConsumerWidget {
  const AiTrayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeControllerProvider);

    return themePref.when(
      loading: () => MaterialApp(
        title: 'AI Tray',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const UsagePage(),
      ),
      error: (_, stackTrace) => MaterialApp(
        title: 'AI Tray',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const UsagePage(),
      ),
      data: (pref) => MaterialApp(
        title: 'AI Tray',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: pref.materialThemeMode,
        home: const UsagePage(),
      ),
    );
  }
}
