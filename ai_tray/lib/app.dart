import 'package:ai_tray/core/navigation/app_shell.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:ai_tray/theme/personalization_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
class AiTrayApp extends ConsumerWidget {
  const AiTrayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalization = ref.watch(personalizationControllerProvider);

    return personalization.when(
      loading: () => _materialApp(PersonalizationState.defaults()),
      error: (_, stackTrace) => _materialApp(PersonalizationState.defaults()),
      data: _materialApp,
    );
  }

  Widget _materialApp(PersonalizationState state) {
    final preset = state.themePreset;
    final font = state.fontPreset;
    return MaterialApp(
      title: 'AI Tray',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(preset: preset, font: font),
      darkTheme: AppTheme.dark(preset: preset, font: font),
      themeMode: state.themeMode.materialThemeMode,
      home: const AppShell(),
    );
  }
}
