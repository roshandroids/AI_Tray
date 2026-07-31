import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Complete light or dark surface + accent palette for a branded theme.
@immutable
final class ThemePalette {
  const ThemePalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.error,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.highUsage,
    required this.info,
    required this.cyanAccent,
    required this.onAccent,
    required this.focus,
    required this.buttonDisabled,
    required this.meterTrack,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color error;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color highUsage;
  final Color info;
  final Color cyanAccent;
  final Color onAccent;
  final Color focus;
  final Color buttonDisabled;
  final Color meterTrack;

  /// Compact picker strip: background → surface → accents.
  List<Color> get previewStrip => [
    background,
    surface,
    primary,
    secondary,
    tertiary,
  ];

  FlexSchemeColor toFlexSchemeColor() {
    return FlexSchemeColor(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      error: error,
    );
  }
}
