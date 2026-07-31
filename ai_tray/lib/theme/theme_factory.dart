import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/theme/app_colors.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_palette.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Central factory that builds complete Material 3 [ThemeData] from a branded
/// [ThemePreset] + [Brightness] (+ optional [FontPreset]).
///
/// Widgets must not invent colors; consume [ThemeData] / `context.colors`.
abstract final class ThemeFactory {
  /// Produces light or dark [ThemeData] for [preset].
  static ThemeData build({
    required ThemePreset preset,
    required Brightness brightness,
    FontPreset font = FontPresetX.defaultPreset,
  }) {
    final palette = preset.paletteFor(brightness);
    return _build(palette: palette, brightness: brightness, font: font);
  }

  static ThemeData _build({
    required ThemePalette palette,
    required Brightness brightness,
    required FontPreset font,
  }) {
    // FlexColorScheme generates component defaults from brand seeds.
    final flexBase = brightness == Brightness.light
        ? FlexThemeData.light(
            colors: palette.toFlexSchemeColor(),
            useMaterial3: true,
            fontFamily: font.fontFamily,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 0,
          )
        : FlexThemeData.dark(
            colors: palette.toFlexSchemeColor(),
            useMaterial3: true,
            fontFamily: font.fontFamily,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 0,
          );

    // Override generated surfaces so each preset's light/dark palette wins.
    final scheme = AppColors.colorSchemeFromPalette(palette, brightness);
    final tokens = AppColors.tokensFromPalette(palette);
    final typography = TrayTypography.fromColors(tokens, fontPreset: font);

    final themed = flexBase.copyWith(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      cardColor: palette.surface,
      dividerColor: palette.border,
      focusColor: palette.focus.withValues(alpha: 0.18),
      hoverColor: palette.surfaceAlt.withValues(alpha: 0.65),
      highlightColor: palette.primary.withValues(alpha: 0.14),
      splashColor: palette.primary.withValues(alpha: 0.16),
      secondaryHeaderColor: palette.surfaceAlt,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.focus,
        selectionColor: palette.primary.withValues(alpha: 0.28),
        selectionHandleColor: palette.primary,
      ),
      textTheme: _applyFont(
        _mapTextTheme(flexBase.textTheme, typography),
        font,
      ),
      primaryTextTheme: _applyFont(
        _mapTextTheme(flexBase.primaryTextTheme, typography),
        font,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens, typography],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title,
        iconTheme: IconThemeData(color: palette.textSecondary, size: 18),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.success,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.buttonDisabled,
          disabledForegroundColor: palette.textMuted,
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
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.border),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: typography.label,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.success;
          }
          return palette.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.success.withValues(alpha: 0.35);
          }
          return palette.surfaceAlt;
        }),
        trackOutlineColor: WidgetStatePropertyAll(palette.border),
      ),
      listTileTheme: ListTileThemeData(
        textColor: palette.textPrimary,
        iconColor: palette.textSecondary,
        tileColor: Colors.transparent,
        selectedTileColor: palette.primary.withValues(alpha: 0.12),
        selectedColor: palette.primary,
        contentPadding: EdgeInsets.zero,
        titleTextStyle: typography.body,
        subtitleTextStyle: typography.caption,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt,
        isDense: true,
        labelStyle: typography.label,
        hintStyle: typography.caption,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          borderSide: BorderSide(color: palette.focus),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.section,
        contentTextStyle: typography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: palette.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        textStyle: typography.body,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: palette.primary.withValues(alpha: 0.2),
        disabledColor: palette.buttonDisabled,
        side: BorderSide(color: palette.border),
        labelStyle: typography.caption,
        secondaryLabelStyle: typography.caption,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        circularTrackColor: palette.meterTrack,
        linearTrackColor: palette.meterTrack,
      ),
      iconTheme: IconThemeData(color: palette.textSecondary, size: 18),
      primaryIconTheme: IconThemeData(color: palette.primary, size: 18),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textSecondary,
          hoverColor: palette.surfaceAlt,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.surfaceAlt;
        }),
        checkColor: WidgetStatePropertyAll(palette.onAccent),
        side: BorderSide(color: palette.border),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.textSecondary;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.meterTrack,
        thumbColor: palette.primary,
        overlayColor: palette.primary.withValues(alpha: 0.16),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          border: Border.all(color: palette.border),
        ),
        textStyle: typography.caption.copyWith(color: palette.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceAlt,
        contentTextStyle: typography.body,
        actionTextColor: palette.primary,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: palette.textPrimary,
        iconColor: palette.textSecondary,
        collapsedTextColor: palette.textPrimary,
        collapsedIconColor: palette.textSecondary,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: Spacing.sm),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.primary.withValues(alpha: 0.16);
            }
            return palette.surfaceAlt;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.primary;
            }
            return palette.textSecondary;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: palette.primary, size: 18),
        unselectedIconTheme: IconThemeData(
          color: palette.textSecondary,
          size: 18,
        ),
        selectedLabelTextStyle: typography.caption.copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: typography.caption.copyWith(
          color: palette.textSecondary,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: typography.body,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(palette.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );

    return themed;
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

/// Convenience API used by the app shell; delegates to [ThemeFactory].
abstract final class AppTheme {
  static ThemeData light({
    ThemePreset preset = ThemePresetX.defaultPreset,
    FontPreset font = FontPresetX.defaultPreset,
  }) {
    return ThemeFactory.build(
      preset: preset,
      brightness: Brightness.light,
      font: font,
    );
  }

  static ThemeData dark({
    ThemePreset preset = ThemePresetX.defaultPreset,
    FontPreset font = FontPresetX.defaultPreset,
  }) {
    return ThemeFactory.build(
      preset: preset,
      brightness: Brightness.dark,
      font: font,
    );
  }
}
