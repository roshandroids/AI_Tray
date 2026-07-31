import 'package:ai_tray/theme/font_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FontPreset', () {
    test('defaults to Inter', () {
      expect(FontPresetX.defaultPreset, FontPreset.inter);
      expect(FontPresetX.fromStorage(null), FontPreset.inter);
      expect(FontPresetX.fromStorage('nope'), FontPreset.inter);
    });

    test('round-trips storage values', () {
      for (final preset in FontPreset.values) {
        expect(FontPresetX.fromStorage(preset.storageValue), preset);
      }
    });

    test('bundled presets declare families', () {
      expect(FontPreset.inter.fontFamily, 'Inter');
      expect(FontPreset.inter.isBundled, isTrue);
      expect(FontPreset.jetBrainsMono.fontFamily, 'JetBrainsMono');
      expect(FontPreset.firaCode.fontFamily, 'FiraCode');
      expect(FontPreset.ibmPlexSans.fontFamily, 'IBMPlexSans');
      expect(FontPreset.geist.fontFamily, 'Geist');
    });

    test('system presets use fallbacks', () {
      expect(FontPreset.systemDefault.fontFamily, isNull);
      expect(FontPreset.systemDefault.fontFamilyFallback, isNotEmpty);
      expect(FontPreset.sfPro.isBundled, isFalse);
      expect(FontPreset.roboto.isBundled, isFalse);
      expect(FontPreset.sourceSans3.isBundled, isFalse);
    });

    test('recommendedFor labels', () {
      expect(FontPreset.inter.recommendedFor, FontRecommendedFor.ui);
      expect(
        FontPreset.jetBrainsMono.recommendedFor,
        FontRecommendedFor.coding,
      );
      expect(
        FontPreset.sourceSans3.recommendedFor,
        FontRecommendedFor.reading,
      );
    });
  });
}
