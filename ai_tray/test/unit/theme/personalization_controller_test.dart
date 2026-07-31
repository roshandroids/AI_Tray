import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonalizationController', () {
    late InMemorySettingsRepository repo;
    late _RecordingSwitcher switcher;
    late ProviderContainer container;

    setUp(() {
      repo = InMemorySettingsRepository();
      switcher = _RecordingSwitcher();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          appIconSwitcherProvider.overrideWithValue(switcher),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('restores defaults on empty storage', () async {
      final state = await container.read(
        personalizationControllerProvider.future,
      );
      expect(state.themeMode, AppThemePreference.system);
      expect(state.themePreset, ThemePreset.cursor);
      expect(state.fontPreset, FontPreset.inter);
      expect(state.appIconPreset, AppIconPresets.defaultIcon);
    });

    test('theme mode switch persists immediately', () async {
      await container.read(personalizationControllerProvider.future);
      await container
          .read(personalizationControllerProvider.notifier)
          .setThemeMode(AppThemePreference.dark);

      final state = container.read(personalizationControllerProvider).value!;
      expect(state.themeMode, AppThemePreference.dark);
      expect((await repo.read()).themeMode, AppThemePreference.dark);
    });

    test('theme and font presets persist', () async {
      await container.read(personalizationControllerProvider.future);
      final notifier = container.read(
        personalizationControllerProvider.notifier,
      );
      await notifier.setThemePreset(ThemePreset.nord);
      await notifier.setFontPreset(FontPreset.geist);

      final stored = await repo.read();
      expect(stored.themePreset, ThemePreset.nord);
      expect(stored.fontPreset, FontPreset.geist);
    });

    test('icon selection persists and invokes supported switcher', () async {
      await container.read(personalizationControllerProvider.future);
      await container
          .read(personalizationControllerProvider.notifier)
          .setAppIconPreset(AppIconPresets.terminal);

      expect((await repo.read()).appIconPreset, AppIconPresets.terminal);
      expect(switcher.calls, [AppIconPresets.terminal]);
    });

    test('unsupported switcher still persists icon', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          appIconSwitcherProvider.overrideWithValue(
            const UnsupportedAppIconSwitcher(),
          ),
        ],
      );
      await container.read(personalizationControllerProvider.future);
      await container
          .read(personalizationControllerProvider.notifier)
          .setAppIconPreset(AppIconPresets.dark);

      expect((await repo.read()).appIconPreset, AppIconPresets.dark);
    });
  });
}

final class _RecordingSwitcher implements AppIconSwitcher {
  final List<AppIconPreset> calls = [];

  @override
  bool get isSupported => true;

  @override
  Future<void> setIcon(AppIconPreset preset) async {
    calls.add(preset);
  }
}
