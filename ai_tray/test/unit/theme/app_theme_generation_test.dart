import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/theme/app_colors.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_factory.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeFactory', () {
    test('builds Material 3 light and dark themes for each preset', () {
      for (final preset in ThemePreset.values) {
        final light = ThemeFactory.build(
          preset: preset,
          brightness: Brightness.light,
          font: FontPreset.inter,
        );
        final dark = ThemeFactory.build(
          preset: preset,
          brightness: Brightness.dark,
          font: FontPreset.inter,
        );

        expect(light.useMaterial3, isTrue);
        expect(dark.useMaterial3, isTrue);
        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
        expect(
          light.extension<TrayColorTokens>()!.background,
          preset.light.background,
        );
        expect(
          dark.extension<TrayColorTokens>()!.background,
          preset.dark.background,
        );
        expect(
          light.scaffoldBackgroundColor,
          isNot(dark.scaffoldBackgroundColor),
        );
        expect(light.extension<TrayTypography>(), isNotNull);
      }
    });

    test('light mode does not keep dark surfaces', () {
      for (final preset in ThemePreset.values) {
        final light = AppTheme.light(preset: preset);
        final tokens = light.extension<TrayColorTokens>()!;
        // Light backgrounds are bright (high luminance).
        expect(
          tokens.background.computeLuminance(),
          greaterThan(0.5),
          reason: '${preset.displayName} light background should be bright',
        );
        expect(tokens.background, preset.light.background);
        expect(tokens.surface, preset.light.surface);
        expect(light.colorScheme.surface, preset.light.background);
      }
    });

    test('dark mode uses preset dark surfaces', () {
      for (final preset in ThemePreset.values) {
        final dark = AppTheme.dark(preset: preset);
        final tokens = dark.extension<TrayColorTokens>()!;
        expect(
          tokens.background.computeLuminance(),
          lessThan(0.5),
          reason: '${preset.displayName} dark background should be dark',
        );
        expect(tokens.background, preset.dark.background);
        expect(tokens.purpleAccent, preset.dark.primary);
      }
    });

    test('applies font family from FontPreset', () {
      final theme = AppTheme.dark(
        preset: ThemePreset.cursor,
        font: FontPreset.geist,
      );
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Geist');
      expect(theme.extension<TrayTypography>()!.body.fontFamily, 'Geist');
      expect(
        theme.extension<TrayTypography>()!.monoData.fontFamily,
        'JetBrainsMono',
      );
    });

    test('Cursor dark primary seeds into ColorScheme', () {
      final theme = AppTheme.dark(preset: ThemePreset.cursor);
      expect(theme.colorScheme.primary.toARGB32(), 0xFF8B8CF0);
    });

    test('Gruvbox light uses warm paper surfaces', () {
      final theme = AppTheme.light(preset: ThemePreset.gruvbox);
      expect(theme.scaffoldBackgroundColor.toARGB32(), 0xFFFBF1C7);
      expect(
        theme.extension<TrayColorTokens>()!.surface.toARGB32(),
        0xFFF2E5BC,
      );
    });

    test('Tokyo Night dark uses night navy surfaces', () {
      final theme = AppTheme.dark(preset: ThemePreset.tokyoNight);
      expect(theme.scaffoldBackgroundColor.toARGB32(), 0xFF1A1B26);
      expect(theme.colorScheme.primary.toARGB32(), 0xFF7AA2F7);
    });
  });

  group('AppColors.tokensFromPalette', () {
    test('maps palette surfaces and accents', () {
      final palette = ThemePreset.github.dark;
      final tokens = AppColors.tokensFromPalette(palette);
      expect(tokens.background, palette.background);
      expect(tokens.purpleAccent, palette.primary);
      expect(tokens.error, palette.error);
      expect(tokens.success, palette.success);
    });
  });
}
