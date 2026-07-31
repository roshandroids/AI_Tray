import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/theme/theme_palette.dart';
import 'package:flutter/material.dart';

/// Maps branded [ThemePalette] / [ColorScheme] into tray [TrayColorTokens].
abstract final class AppColors {
  /// Preferred path: tokens come directly from the active theme palette.
  static TrayColorTokens tokensFromPalette(ThemePalette palette) {
    return TrayColorTokens(
      background: palette.background,
      surface: palette.surface,
      surfaceAlt: palette.surfaceAlt,
      border: palette.border,
      textPrimary: palette.textPrimary,
      textSecondary: palette.textSecondary,
      textMuted: palette.textMuted,
      success: palette.success,
      warning: palette.warning,
      highUsage: palette.highUsage,
      error: palette.error,
      info: palette.info,
      purpleAccent: palette.primary,
      cyanAccent: palette.cyanAccent,
      focus: palette.focus,
      onAccent: palette.onAccent,
      buttonDisabled: palette.buttonDisabled,
      meterTrack: palette.meterTrack,
    );
  }

  /// Fallback when only a [ColorScheme] is available (e.g. tests / missing
  /// extension). Prefer [tokensFromPalette] in production themes.
  static TrayColorTokens tokensFromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return TrayColorTokens(
      background: scheme.surface,
      surface: isDark
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerLowest,
      surfaceAlt: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      textMuted: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      success: isDark ? const Color(0xFF22C55E) : const Color(0xFF1A7F37),
      warning: isDark ? const Color(0xFFEAB308) : const Color(0xFF9A6700),
      highUsage: isDark ? const Color(0xFFF97316) : const Color(0xFFBC4C00),
      error: scheme.error,
      info: scheme.secondary,
      purpleAccent: scheme.primary,
      cyanAccent: scheme.tertiary,
      focus: scheme.primary,
      onAccent: scheme.onPrimary,
      buttonDisabled: scheme.surfaceContainerHighest,
      meterTrack: scheme.surfaceContainerHighest,
    );
  }

  /// Builds an M3 [ColorScheme] whose surfaces match [palette] exactly.
  static ColorScheme colorSchemeFromPalette(
    ThemePalette palette,
    Brightness brightness,
  ) {
    return ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onAccent,
      primaryContainer: palette.surfaceAlt,
      onPrimaryContainer: palette.textPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.surfaceAlt,
      onSecondaryContainer: palette.textPrimary,
      tertiary: palette.tertiary,
      onTertiary: palette.onAccent,
      tertiaryContainer: palette.surfaceAlt,
      onTertiaryContainer: palette.textPrimary,
      error: palette.error,
      onError: palette.onAccent,
      errorContainer: palette.surfaceAlt,
      onErrorContainer: palette.error,
      surface: palette.background,
      onSurface: palette.textPrimary,
      surfaceContainerLowest: palette.background,
      surfaceContainerLow: palette.surface,
      surfaceContainer: palette.surface,
      surfaceContainerHigh: palette.surfaceAlt,
      surfaceContainerHighest: palette.surfaceAlt,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.border,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: palette.textPrimary,
      onInverseSurface: palette.background,
      inversePrimary: palette.secondary,
    );
  }
}
