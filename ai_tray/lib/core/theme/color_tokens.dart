import 'package:flutter/material.dart';

/// Semantic color tokens — GitHub/terminal dark & intentional light (PD-021).
@immutable
final class TrayColorTokens extends ThemeExtension<TrayColorTokens> {
  const TrayColorTokens({
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
    required this.error,
    required this.info,
    required this.purpleAccent,
    required this.cyanAccent,
    required this.focus,
    required this.onAccent,
    required this.buttonDisabled,
    required this.meterTrack,
  });

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
  final Color error;
  final Color info;
  final Color purpleAccent;
  final Color cyanAccent;
  final Color focus;
  final Color onAccent;
  final Color buttonDisabled;
  final Color meterTrack;

  // --- Compatibility aliases used by existing call sites ---
  Color get surfaceRaised => surfaceAlt;
  Color get divider => border;
  Color get title => textPrimary;
  Color get primary => purpleAccent;
  Color get onPrimary => onAccent;
  Color get meterFill => purpleAccent;
  Color get statusRefreshing => info;
  Color get statusIdle => textMuted;

  /// Usage-band color for progress rings (0–100).
  Color usageBand(double percent) {
    final p = percent.clamp(0.0, 100.0);
    if (p < 50) return success;
    if (p < 80) return warning;
    if (p < 95) return highUsage;
    return error;
  }

  static const dark = TrayColorTokens(
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceAlt: Color(0xFF21262D),
    border: Color(0xFF30363D),
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B949E),
    textMuted: Color(0xFF6E7681),
    success: Color(0xFF22C55E),
    warning: Color(0xFFEAB308),
    highUsage: Color(0xFFF97316),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    purpleAccent: Color(0xFFA855F7),
    cyanAccent: Color(0xFF06B6D4),
    focus: Color(0xFFA855F7),
    onAccent: Color(0xFF0D1117),
    buttonDisabled: Color(0xFF30363D),
    meterTrack: Color(0xFF21262D),
  );

  /// Intentional light palette (not a simple invert).
  static const light = TrayColorTokens(
    background: Color(0xFFF6F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFF2F5),
    border: Color(0xFFD0D7DE),
    textPrimary: Color(0xFF1F2328),
    textSecondary: Color(0xFF656D76),
    textMuted: Color(0xFF8B949E),
    success: Color(0xFF1A7F37),
    warning: Color(0xFF9A6700),
    highUsage: Color(0xFFBC4C00),
    error: Color(0xFFCF222E),
    info: Color(0xFF0969DA),
    purpleAccent: Color(0xFF8250DF),
    cyanAccent: Color(0xFF0550AE),
    focus: Color(0xFF8250DF),
    onAccent: Color(0xFFFFFFFF),
    buttonDisabled: Color(0xFFD0D7DE),
    meterTrack: Color(0xFFEFF2F5),
  );

  @override
  TrayColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? highUsage,
    Color? error,
    Color? info,
    Color? purpleAccent,
    Color? cyanAccent,
    Color? focus,
    Color? onAccent,
    Color? buttonDisabled,
    Color? meterTrack,
  }) {
    return TrayColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      highUsage: highUsage ?? this.highUsage,
      error: error ?? this.error,
      info: info ?? this.info,
      purpleAccent: purpleAccent ?? this.purpleAccent,
      cyanAccent: cyanAccent ?? this.cyanAccent,
      focus: focus ?? this.focus,
      onAccent: onAccent ?? this.onAccent,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      meterTrack: meterTrack ?? this.meterTrack,
    );
  }

  @override
  TrayColorTokens lerp(ThemeExtension<TrayColorTokens>? other, double t) {
    if (other is! TrayColorTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TrayColorTokens(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      highUsage: l(highUsage, other.highUsage),
      error: l(error, other.error),
      info: l(info, other.info),
      purpleAccent: l(purpleAccent, other.purpleAccent),
      cyanAccent: l(cyanAccent, other.cyanAccent),
      focus: l(focus, other.focus),
      onAccent: l(onAccent, other.onAccent),
      buttonDisabled: l(buttonDisabled, other.buttonDisabled),
      meterTrack: l(meterTrack, other.meterTrack),
    );
  }
}
