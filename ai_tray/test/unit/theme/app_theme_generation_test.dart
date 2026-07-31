import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/theme/app_colors.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('builds Material 3 light and dark themes for each preset', () {
      for (final preset in ThemePreset.values) {
        final light = AppTheme.light(preset: preset, font: FontPreset.inter);
        final dark = AppTheme.dark(preset: preset, font: FontPreset.inter);

        expect(light.useMaterial3, isTrue);
        expect(dark.useMaterial3, isTrue);
        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
        expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
        expect(light.extension<TrayColorTokens>(), isNotNull);
        expect(dark.extension<TrayTypography>(), isNotNull);
      }
    });

    test('applies font family from FontPreset', () {
      final theme = AppTheme.dark(
        preset: ThemePreset.cursor,
        font: FontPreset.geist,
      );
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Geist');
      expect(
        theme.extension<TrayTypography>()!.body.fontFamily,
        'Geist',
      );
      expect(
        theme.extension<TrayTypography>()!.monoData.fontFamily,
        'JetBrainsMono',
      );
    });

    test('Cursor dark primary seeds into ColorScheme', () {
      final theme = AppTheme.dark(preset: ThemePreset.cursor);
      expect(theme.colorScheme.primary.toARGB32(), 0xFF8B8CF0);
    });
  });

  group('AppColors.tokensFromScheme', () {
    test('maps scheme surfaces and accents', () {
      final theme = AppTheme.dark(preset: ThemePreset.github);
      final tokens = AppColors.tokensFromScheme(theme.colorScheme);
      expect(tokens.background, theme.colorScheme.surface);
      expect(tokens.purpleAccent, theme.colorScheme.primary);
      expect(tokens.error, theme.colorScheme.error);
      expect(tokens.success, TraySemanticColors.dark.success);
    });
  });
}
