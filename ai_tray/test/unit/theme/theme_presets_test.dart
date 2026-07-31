import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemePreset', () {
    test('defaults to cursor', () {
      expect(ThemePresetX.defaultPreset, ThemePreset.cursor);
      expect(ThemePresetX.fromStorage(null), ThemePreset.cursor);
      expect(ThemePresetX.fromStorage('unknown'), ThemePreset.cursor);
    });

    test('round-trips storage values', () {
      for (final preset in ThemePreset.values) {
        expect(ThemePresetX.fromStorage(preset.storageValue), preset);
      }
    });

    test('exposes metadata and light/dark FlexSchemeColor seeds', () {
      for (final preset in ThemePreset.values) {
        expect(preset.displayName, isNotEmpty);
        expect(preset.description, isNotEmpty);
        expect(preset.previewColor, preset.dark.primary);
        expect(preset.light.primary, isNotNull);
        expect(preset.dark.primary, isNotNull);
        expect(preset.light.secondary, isNotNull);
        expect(preset.dark.secondary, isNotNull);
      }
    });

    test('Cursor uses muted developer-tool primaries', () {
      expect(ThemePreset.cursor.dark.primary.toARGB32(), 0xFF8B8CF0);
      expect(ThemePreset.cursor.light.primary.toARGB32(), 0xFF5B5FC7);
    });
  });
}
