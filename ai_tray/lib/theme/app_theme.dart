import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/theme/app_colors.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Builds Material 3 [ThemeData] from branded presets via FlexColorScheme.
abstract final class AppTheme {
  /// Light theme for [preset] using [font] typography.
  static ThemeData light({
    ThemePreset preset = ThemePresetX.defaultPreset,
    FontPreset font = FontPresetX.defaultPreset,
  }) {
    return _build(
      colors: preset.light,
      brightness: Brightness.light,
      font: font,
    );
  }

  /// Dark theme for [preset] using [font] typography.
  static ThemeData dark({
    ThemePreset preset = ThemePresetX.defaultPreset,
    FontPreset font = FontPresetX.defaultPreset,
  }) {
    return _build(
      colors: preset.dark,
      brightness: Brightness.dark,
      font: font,
    );
  }

  static ThemeData _build({
    required FlexSchemeColor colors,
    required Brightness brightness,
    required FontPreset font,
  }) {
    final base = brightness == Brightness.light
        ? FlexThemeData.light(
            colors: colors,
            useMaterial3: true,
            fontFamily: font.fontFamily,
          )
        : FlexThemeData.dark(
            colors: colors,
            useMaterial3: true,
            fontFamily: font.fontFamily,
          );

    final scheme = base.colorScheme;
    final tokens = AppColors.tokensFromScheme(scheme);
    final typography = TrayTypography.fromColors(tokens, fontPreset: font);

    return base.copyWith(
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      dividerColor: tokens.border,
      textTheme: _applyFont(
        _mapTextTheme(base.textTheme, typography),
        font,
      ),
      primaryTextTheme: _applyFont(
        _mapTextTheme(base.primaryTextTheme, typography),
        font,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens, typography],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title,
        iconTheme: IconThemeData(color: tokens.textSecondary, size: 18),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.success,
          foregroundColor: tokens.onAccent,
          disabledBackgroundColor: tokens.buttonDisabled,
          disabledForegroundColor: tokens.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          textStyle: typography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          textStyle: typography.label,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.success;
          }
          return tokens.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.success.withValues(alpha: 0.35);
          }
          return tokens.surfaceAlt;
        }),
        trackOutlineColor: WidgetStatePropertyAll(tokens.border),
      ),
      listTileTheme: ListTileThemeData(
        textColor: tokens.textPrimary,
        iconColor: tokens.textSecondary,
        contentPadding: EdgeInsets.zero,
        titleTextStyle: typography.body,
        subtitleTextStyle: typography.caption,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceAlt,
        isDense: true,
        labelStyle: typography.label,
        hintStyle: typography.caption,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          borderSide: BorderSide(color: tokens.focus),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: tokens.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.section,
        contentTextStyle: typography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: tokens.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceAlt,
        selectedColor: tokens.success.withValues(alpha: 0.2),
        side: BorderSide(color: tokens.border),
        labelStyle: typography.caption,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.purpleAccent,
        circularTrackColor: tokens.meterTrack,
        linearTrackColor: tokens.meterTrack,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textSecondary,
          hoverColor: tokens.surfaceAlt,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          border: Border.all(color: tokens.border),
        ),
        textStyle: typography.caption.copyWith(color: tokens.textPrimary),
      ),
    );
  }

  static TextTheme _mapTextTheme(TextTheme base, TrayTypography type) {
    return base.copyWith(
      displaySmall: type.display,
      headlineSmall: type.title,
      titleLarge: type.title,
      titleMedium: type.section,
      titleSmall: type.label,
      bodyLarge: type.body,
      bodyMedium: type.body,
      bodySmall: type.caption,
      labelLarge: type.status,
      labelMedium: type.label,
      labelSmall: type.caption,
    );
  }

  static TextTheme _applyFont(TextTheme theme, FontPreset font) {
    TextStyle? withFont(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: font.fontFamily,
        fontFamilyFallback: font.fontFamilyFallback,
      );
    }

    return theme.copyWith(
      displayLarge: withFont(theme.displayLarge),
      displayMedium: withFont(theme.displayMedium),
      displaySmall: withFont(theme.displaySmall),
      headlineLarge: withFont(theme.headlineLarge),
      headlineMedium: withFont(theme.headlineMedium),
      headlineSmall: withFont(theme.headlineSmall),
      titleLarge: withFont(theme.titleLarge),
      titleMedium: withFont(theme.titleMedium),
      titleSmall: withFont(theme.titleSmall),
      bodyLarge: withFont(theme.bodyLarge),
      bodyMedium: withFont(theme.bodyMedium),
      bodySmall: withFont(theme.bodySmall),
      labelLarge: withFont(theme.labelLarge),
      labelMedium: withFont(theme.labelMedium),
      labelSmall: withFont(theme.labelSmall),
    );
  }
}
