import 'package:flutter/material.dart';

/// Semantic color tokens exposed via [ThemeExtension] (PD-014).
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

  static const dark = TrayColorTokens(
    background: Color(0xFF161513),
    surface: Color(0xFF1C1B19),
    surfaceRaised: Color(0xFF242320),
    divider: Color(0xFF2E2C28),
    title: Color(0xFFD2C093),
    textPrimary: Color(0xFFD8D4CC),
    textSecondary: Color(0xFF8A857C),
    textMuted: Color(0xFF6B665E),
    primary: Color(0xFFD2C093),
    onPrimary: Color(0xFF161513),
    meterFill: Color(0xFF828CB7),
    meterTrack: Color(0xFF2A2F3D),
    success: Color(0xFF6B9B7A),
    warning: Color(0xFFC4A35A),
    error: Color(0xFFC4756B),
    focus: Color(0xFF9AA3C7),
    buttonDisabled: Color(0xFF3A3834),
    statusRefreshing: Color(0xFF8A857C),
    statusIdle: Color(0xFF6B665E),
  );

  static const light = TrayColorTokens(
    background: Color(0xFFF5F3EF),
    surface: Color(0xFFFAFAF8),
    surfaceRaised: Color(0xFFFFFFFF),
    divider: Color(0xFFE3DFD6),
    title: Color(0xFF7A6340),
    textPrimary: Color(0xFF2C2A26),
    textSecondary: Color(0xFF6B665E),
    textMuted: Color(0xFF8A857C),
    primary: Color(0xFFC4A86A),
    onPrimary: Color(0xFF1C1B19),
    meterFill: Color(0xFF6B75A8),
    meterTrack: Color(0xFFD8DCE8),
    success: Color(0xFF4A8B62),
    warning: Color(0xFFB8860B),
    error: Color(0xFFB85C52),
    focus: Color(0xFF6B75A8),
    buttonDisabled: Color(0xFFE8E4DC),
    statusRefreshing: Color(0xFF8A857C),
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
