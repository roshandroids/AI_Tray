import 'package:flutter/material.dart';

/// Semantic color tokens exposed via [ThemeExtension] (PD-014 / PD-020).
@immutable
final class TrayColorTokens extends ThemeExtension<TrayColorTokens> {
  const TrayColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.divider,
    required this.title,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.meterFill,
    required this.meterTrack,
    required this.success,
    required this.warning,
    required this.error,
    required this.focus,
    required this.buttonDisabled,
    required this.statusRefreshing,
    required this.statusIdle,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color divider;
  final Color title;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color meterFill;
  final Color meterTrack;
  final Color success;
  final Color warning;
  final Color error;
  final Color focus;
  final Color buttonDisabled;
  final Color statusRefreshing;
  final Color statusIdle;

  /// Terminal dark palette — neon status colors (PD-020).
  static const dark = TrayColorTokens(
    background: Color(0xFF111113),
    surface: Color(0xFF161618),
    surfaceRaised: Color(0xFF1C1C1F),
    divider: Color(0xFF2A2A2E),
    title: Color(0xFFE8E6E1),
    textPrimary: Color(0xFFD4D2CC),
    textSecondary: Color(0xFF8B8A86),
    textMuted: Color(0xFF6B6A66),
    primary: Color(0xFFA78BFA),
    onPrimary: Color(0xFF111113),
    meterFill: Color(0xFFA78BFA),
    meterTrack: Color(0xFF2A2A30),
    success: Color(0xFF22C55E),
    warning: Color(0xFFEAB308),
    error: Color(0xFFEF4444),
    focus: Color(0xFFA78BFA),
    buttonDisabled: Color(0xFF2A2A2E),
    statusRefreshing: Color(0xFF7C3AED),
    statusIdle: Color(0xFF6B6A66),
  );

  /// Light terminal companion — same semantic accents on paper.
  static const light = TrayColorTokens(
    background: Color(0xFFF4F3F0),
    surface: Color(0xFFFAFAF8),
    surfaceRaised: Color(0xFFFFFFFF),
    divider: Color(0xFFD8D6D0),
    title: Color(0xFF1A1A1C),
    textPrimary: Color(0xFF2C2A26),
    textSecondary: Color(0xFF6B665E),
    textMuted: Color(0xFF8A857C),
    primary: Color(0xFF7C3AED),
    onPrimary: Color(0xFFFFFFFF),
    meterFill: Color(0xFF7C3AED),
    meterTrack: Color(0xFFE4E2EA),
    success: Color(0xFF16A34A),
    warning: Color(0xFFCA8A04),
    error: Color(0xFFDC2626),
    focus: Color(0xFF7C3AED),
    buttonDisabled: Color(0xFFE8E4DC),
    statusRefreshing: Color(0xFF7C3AED),
    statusIdle: Color(0xFF8A857C),
  );

  @override
  TrayColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? divider,
    Color? title,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? meterFill,
    Color? meterTrack,
    Color? success,
    Color? warning,
    Color? error,
    Color? focus,
    Color? buttonDisabled,
    Color? statusRefreshing,
    Color? statusIdle,
  }) {
    return TrayColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      divider: divider ?? this.divider,
      title: title ?? this.title,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      meterFill: meterFill ?? this.meterFill,
      meterTrack: meterTrack ?? this.meterTrack,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      focus: focus ?? this.focus,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      statusRefreshing: statusRefreshing ?? this.statusRefreshing,
      statusIdle: statusIdle ?? this.statusIdle,
    );
  }

  @override
  TrayColorTokens lerp(ThemeExtension<TrayColorTokens>? other, double t) {
    if (other is! TrayColorTokens) return this;
    return TrayColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      title: Color.lerp(title, other.title, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      meterFill: Color.lerp(meterFill, other.meterFill, t)!,
      meterTrack: Color.lerp(meterTrack, other.meterTrack, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      buttonDisabled: Color.lerp(buttonDisabled, other.buttonDisabled, t)!,
      statusRefreshing: Color.lerp(
        statusRefreshing,
        other.statusRefreshing,
        t,
      )!,
      statusIdle: Color.lerp(statusIdle, other.statusIdle, t)!,
    );
  }
}
