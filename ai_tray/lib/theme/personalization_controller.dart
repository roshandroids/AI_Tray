import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/personalization_state.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads and persists theme mode, color preset, font, and app icon.
final personalizationControllerProvider =
    AsyncNotifierProvider<PersonalizationController, PersonalizationState>(
      PersonalizationController.new,
    );

final class PersonalizationController
    extends AsyncNotifier<PersonalizationState> {
  @override
  Future<PersonalizationState> build() async {
    final settings = await ref.read(settingsRepositoryProvider).read();
    return PersonalizationState(
      themeMode: settings.themeMode,
      themePreset: settings.themePreset,
      fontPreset: settings.fontPreset,
      appIconPreset: settings.appIconPreset,
    );
  }

  Future<void> setThemeMode(AppThemePreference mode) async {
    final current = state.value ?? PersonalizationState.defaults();
    final next = current.copyWith(themeMode: mode);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> setThemePreset(ThemePreset preset) async {
    final current = state.value ?? PersonalizationState.defaults();
    final next = current.copyWith(themePreset: preset);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> setFontPreset(FontPreset preset) async {
    final current = state.value ?? PersonalizationState.defaults();
    final next = current.copyWith(fontPreset: preset);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> setAppIconPreset(AppIconPreset preset) async {
    final current = state.value ?? PersonalizationState.defaults();
    final next = current.copyWith(appIconPreset: preset);
    state = AsyncData(next);
    await _persist(next);

    final switcher = ref.read(appIconSwitcherProvider);
    if (switcher.isSupported) {
      await switcher.setIcon(preset);
    }
  }

  Future<void> _persist(PersonalizationState next) async {
    final repo = ref.read(settingsRepositoryProvider);
    final current = await repo.read();
    if (current.themeMode == next.themeMode &&
        current.themePreset == next.themePreset &&
        current.fontPreset == next.fontPreset &&
        current.appIconPreset == next.appIconPreset) {
      return;
    }
    await repo.write(
      current.copyWith(
        themeMode: next.themeMode,
        themePreset: next.themePreset,
        fontPreset: next.fontPreset,
        appIconPreset: next.appIconPreset,
      ),
    );
  }
}
