import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/tray/domain/tray_display_mode.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AppThemePreference round-trips through storage', () {
    expect(AppThemePreference.fromStorage('light'), AppThemePreference.light);
    expect(AppThemePreference.fromStorage('dark'), AppThemePreference.dark);
    expect(AppThemePreference.fromStorage(null), AppThemePreference.system);
    expect(AppThemePreference.dark.storageValue, 'dark');
  });

  test('settings repository persists personalization fields', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSettingsRepository(prefs);

    final updated = AppSettings.defaults().copyWith(
      themeMode: AppThemePreference.light,
      themePreset: ThemePreset.dracula,
      fontPreset: FontPreset.firaCode,
      appIconPreset: AppIconPresets.ai,
      trayDisplayMode: TrayDisplayMode.alwaysPercent,
      trayPercentThreshold: 75,
    );
    await repo.write(updated);

    final read = await repo.read();
    expect(read.themeMode, AppThemePreference.light);
    expect(read.themePreset, ThemePreset.dracula);
    expect(read.fontPreset, FontPreset.firaCode);
    expect(read.appIconPreset, AppIconPresets.ai);
    expect(read.trayDisplayMode, TrayDisplayMode.alwaysPercent);
    expect(read.trayPercentThreshold, 75);
  });

  test('missing personalization keys restore defaults', () async {
    SharedPreferences.setMockInitialValues({
      'settings_v1_themeMode': 'dark',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSettingsRepository(prefs);
    final read = await repo.read();
    expect(read.themeMode, AppThemePreference.dark);
    expect(read.themePreset, ThemePreset.cursor);
    expect(read.fontPreset, FontPreset.inter);
    expect(read.appIconPreset, AppIconPresets.defaultIcon);
    expect(read.trayDisplayMode, TrayDisplayMode.adaptive);
    expect(read.trayPercentThreshold, 90);
  });
}
