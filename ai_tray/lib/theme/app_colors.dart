import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

/// Semantic status accents that stay readable across branded presets.
@immutable
final class TraySemanticColors {
  const TraySemanticColors({
    required this.success,
    required this.warning,
    required this.highUsage,
    required this.info,
    required this.cyanAccent,
  });

  final Color success;
  final Color warning;
  final Color highUsage;
  final Color info;
  final Color cyanAccent;

  static const TraySemanticColors light = TraySemanticColors(
    success: Color(0xFF1A7F37),
    warning: Color(0xFF9A6700),
    highUsage: Color(0xFFBC4C00),
    info: Color(0xFF0969DA),
    cyanAccent: Color(0xFF0550AE),
  );

  static const TraySemanticColors dark = TraySemanticColors(
    success: Color(0xFF22C55E),
    warning: Color(0xFFEAB308),
    highUsage: Color(0xFFF97316),
    info: Color(0xFF3B82F6),
    cyanAccent: Color(0xFF06B6D4),
  );

  static TraySemanticColors forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Maps a Material 3 [ColorScheme] into tray semantic [TrayColorTokens].
abstract final class AppColors {
  /// Builds tray tokens from FlexColorScheme-generated [scheme].
  static TrayColorTokens tokensFromScheme(
    ColorScheme scheme, {
    TraySemanticColors? semantic,
  }) {
    final status =
        semantic ?? TraySemanticColors.forBrightness(scheme.brightness);
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
      success: status.success,
      warning: status.warning,
      highUsage: status.highUsage,
      error: scheme.error,
      info: status.info,
      purpleAccent: scheme.primary,
      cyanAccent: status.cyanAccent,
      focus: scheme.primary,
      onAccent: scheme.onPrimary,
      buttonDisabled: scheme.surfaceContainerHighest,
      meterTrack: scheme.surfaceContainerHighest,
    );
  }
}
