import 'package:ai_tray/core/navigation/app_shell.dart';
import 'package:ai_tray/features/onboarding/presentation/onboarding_flow.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
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
    final settings = ref.watch(settingsControllerProvider);

    return personalization.when(
      loading: () => _materialApp(PersonalizationState.defaults(), home: null),
      error: (_, stackTrace) =>
          _materialApp(PersonalizationState.defaults(), home: null),
      data: (state) => _materialApp(
        state,
        // While settings is still loading, render a neutral placeholder
        // rather than guessing AppShell-vs-onboarding — flashing AppShell
        // for a frame would kick off refreshes/tray side effects on what
        // might turn out to be a fresh install (V4 §9.1).
        home: settings.when(
          loading: () => null,
          error: (_, stackTrace) => const AppShell(),
          data: (settings) => settings.hasCompletedOnboarding
              ? const AppShell()
              : const OnboardingFlow(),
        ),
      ),
    );
  }

  Widget _materialApp(PersonalizationState state, {required Widget? home}) {
    final preset = state.themePreset;
    final font = state.fontPreset;
    return MaterialApp(
      title: 'AI Tray',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(preset: preset, font: font),
      darkTheme: AppTheme.dark(preset: preset, font: font),
      themeMode: state.themeMode.materialThemeMode,
      home: home ?? const Scaffold(),
    );
  }
}
