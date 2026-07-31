import 'package:ai_tray/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppIconPreset', () {
    test('catalog includes required presets', () {
      expect(AppIconPresets.all.map((p) => p.id), [
        'default',
        'terminal',
        'ai',
        'minimal',
        'dark',
        'light',
      ]);
    });

    test('round-trips storage', () {
      expect(AppIconPresets.fromStorage(null), AppIconPresets.defaultIcon);
      expect(AppIconPresets.fromStorage('unknown'), AppIconPresets.defaultIcon);
      for (final preset in AppIconPresets.all) {
        expect(AppIconPresets.fromStorage(preset.storageValue), preset);
        expect(preset.assetPath, isNotEmpty);
        expect(preset.previewAssetPath, isNotEmpty);
        expect(preset.displayName, isNotEmpty);
        expect(preset.description, isNotEmpty);
      }
    });
  });

  group('AppIconSwitcher', () {
    test('unsupported switcher reports false and no-ops', () async {
      const switcher = UnsupportedAppIconSwitcher();
      expect(switcher.isSupported, isFalse);
      await switcher.setIcon(AppIconPresets.terminal);
    });

    test('recording switcher captures calls when supported', () async {
      final switcher = _RecordingSwitcher();
      expect(switcher.isSupported, isTrue);
      await switcher.setIcon(AppIconPresets.ai);
      expect(switcher.calls, [AppIconPresets.ai]);
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
