import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AppThemePreference round-trips through storage', () {
    expect(AppThemePreference.fromStorage('light'), AppThemePreference.light);
    expect(AppThemePreference.fromStorage('dark'), AppThemePreference.dark);
    expect(AppThemePreference.fromStorage(null), AppThemePreference.system);
    expect(AppThemePreference.dark.storageValue, 'dark');
  });

  test('settings repository persists themeMode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSettingsRepository(prefs);

    final updated = AppSettings.defaults().copyWith(
      themeMode: AppThemePreference.light,
    );
    await repo.write(updated);

    final read = await repo.read();
    expect(read.themeMode, AppThemePreference.light);
  });
}
