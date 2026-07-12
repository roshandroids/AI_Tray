import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads and persists the user's theme preference (PD-014).
final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, AppThemePreference>(
      ThemeController.new,
    );

final class ThemeController extends AsyncNotifier<AppThemePreference> {
  @override
  Future<AppThemePreference> build() async {
    final settings = await ref.read(settingsRepositoryProvider).read();
    return settings.themeMode;
  }

  /// Applies immediately and persists to settings storage.
  Future<void> setPreference(AppThemePreference mode) async {
    state = AsyncData(mode);
    final repo = ref.read(settingsRepositoryProvider);
    final current = await repo.read();
    if (current.themeMode == mode) return;
    await repo.write(current.copyWith(themeMode: mode));
  }
}
