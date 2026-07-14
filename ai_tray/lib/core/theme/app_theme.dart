import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// Builds Material 3 themes from design-system tokens (PD-021).
abstract final class AppTheme {
  static ThemeData light() => _build(TrayColorTokens.light);

  static ThemeData dark() => _build(TrayColorTokens.dark);

  static ThemeData _build(TrayColorTokens colors) {
    final typography = TrayTypography.fromColors(colors);
    final isDark =
        identical(colors, TrayColorTokens.dark) ||
        colors.background == TrayColorTokens.dark.background;

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.purpleAccent,
        onPrimary: colors.onAccent,
        secondary: colors.info,
        onSecondary: colors.onAccent,
        error: colors.error,
        onError: colors.onAccent,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.border,
      ),
      extensions: [colors, typography],
    );

    return base.copyWith(
      textTheme: _mapTextTheme(base.textTheme, typography),
      primaryTextTheme: _mapTextTheme(base.primaryTextTheme, typography),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title,
        iconTheme: IconThemeData(color: colors.textSecondary, size: 18),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.success,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.buttonDisabled,
          disabledForegroundColor: colors.textMuted,
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
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
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
            return colors.success;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.success.withValues(alpha: 0.35);
          }
          return colors.surfaceAlt;
        }),
        trackOutlineColor: WidgetStatePropertyAll(colors.border),
      ),
      listTileTheme: ListTileThemeData(
        textColor: colors.textPrimary,
        iconColor: colors.textSecondary,
        contentPadding: EdgeInsets.zero,
        titleTextStyle: typography.body,
        subtitleTextStyle: typography.caption,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        isDense: true,
        labelStyle: typography.label,
        hintStyle: typography.caption,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          borderSide: BorderSide(color: colors.focus),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.section,
        contentTextStyle: typography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: colors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.success.withValues(alpha: 0.2),
        side: BorderSide(color: colors.border),
        labelStyle: typography.caption,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.purpleAccent,
        circularTrackColor: colors.meterTrack,
        linearTrackColor: colors.meterTrack,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          hoverColor: colors.surfaceAlt,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          border: Border.all(color: colors.border),
        ),
        textStyle: typography.caption.copyWith(color: colors.textPrimary),
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
}
