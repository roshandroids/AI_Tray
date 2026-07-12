import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// Builds Material 3 themes from semantic tokens (PD-014).
abstract final class AppTheme {
  static ThemeData light() => _build(TrayColorTokens.light);

  static ThemeData dark() => _build(TrayColorTokens.dark);

  static ThemeData _build(TrayColorTokens colors) {
    final typography = TrayTypography.fromColors(colors);
    final isDark = colors == TrayColorTokens.dark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.meterFill,
        onSecondary: colors.textPrimary,
        error: colors.error,
        onError: colors.textPrimary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.divider,
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
        titleTextStyle: typography.appBarTitle,
        iconTheme: IconThemeData(color: colors.textSecondary, size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.buttonDisabled,
          disabledForegroundColor: colors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
          ),
          textStyle: typography.button,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.meterFill.withValues(alpha: 0.45);
          }
          return colors.surfaceRaised;
        }),
      ),
      listTileTheme: ListTileThemeData(
        textColor: colors.textPrimary,
        iconColor: colors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        titleTextStyle: typography.body,
        subtitleTextStyle: typography.bodySmall,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.textSecondary;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.heading,
        contentTextStyle: typography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
          side: BorderSide(color: colors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
          borderSide: BorderSide(color: colors.focus),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: typography.body,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.meterFill,
        circularTrackColor: colors.meterTrack,
        linearTrackColor: colors.meterTrack,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          hoverColor: colors.surfaceRaised,
        ),
      ),
    );
  }

  static TextTheme _mapTextTheme(TextTheme base, TrayTypography type) {
    return base.copyWith(
      displaySmall: type.display,
      headlineSmall: type.heading,
      titleLarge: type.appBarTitle,
      titleMedium: type.sectionTitle,
      titleSmall: type.sectionTitle.copyWith(fontSize: 12),
      bodyLarge: type.body.copyWith(fontSize: 14),
      bodyMedium: type.body,
      bodySmall: type.bodySmall,
      labelLarge: type.badge,
      labelMedium: type.caption,
      labelSmall: type.muted.copyWith(fontSize: 10),
    );
  }
}
