import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compatibility facade over [personalizationControllerProvider] (PD-014).
final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, AppThemePreference>(
      ThemeController.new,
    );

final class ThemeController extends AsyncNotifier<AppThemePreference> {
  @override
  Future<AppThemePreference> build() async {
    final personalization = await ref.watch(
      personalizationControllerProvider.future,
    );
    return personalization.themeMode;
  }

  /// Applies immediately and persists via personalization.
  Future<void> setPreference(AppThemePreference mode) async {
    state = AsyncData(mode);
    await ref
        .read(personalizationControllerProvider.notifier)
        .setThemeMode(mode);
  }
}
