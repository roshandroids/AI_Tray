import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

/// Bundled monospace stack (IBM Plex Mono).
abstract final class TrayFonts {
  static const String monoFamily = 'IBMPlexMono';
  static const List<String> monoFallbacks = [
    'Menlo',
    'SF Mono',
    'Monaco',
    'Consolas',
    'Cascadia Mono',
    'Courier New',
    'monospace',
  ];
}

/// Typography scale derived from semantic colors (PD-014).
@immutable
final class TrayTypography extends ThemeExtension<TrayTypography> {
  const TrayTypography({
    required this.display,
    required this.heading,
    required this.sectionTitle,
    required this.appBarTitle,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.muted,
    required this.meterValue,
    required this.badge,
    required this.button,
    required this.emptyTitle,
    required this.error,
  });

  factory TrayTypography.fromColors(TrayColorTokens colors) {
    TextStyle mono({
      required double size,
      required Color color,
      FontWeight weight = FontWeight.w400,
      double height = 1.35,
      double? letterSpacing,
    }) {
      return TextStyle(
        fontFamily: TrayFonts.monoFamily,
        fontFamilyFallback: TrayFonts.monoFallbacks,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    return TrayTypography(
      display: mono(size: 22, weight: FontWeight.w600, color: colors.title),
      heading: mono(size: 16, weight: FontWeight.w600, color: colors.title),
      sectionTitle: mono(
        size: 13,
        weight: FontWeight.w600,
        color: colors.title,
      ),
      appBarTitle: mono(
        size: 15,
        weight: FontWeight.w600,
        color: colors.title,
        letterSpacing: 0.2,
      ),
      body: mono(size: 13, color: colors.textPrimary),
      bodySmall: mono(size: 12, color: colors.textSecondary, height: 1.45),
      caption: mono(size: 11, color: colors.textSecondary, height: 1.45),
      muted: mono(size: 12, color: colors.textMuted, height: 1.45),
      meterValue: mono(size: 12, color: colors.textPrimary),
      badge: mono(size: 12, weight: FontWeight.w600, color: colors.textPrimary),
      button: mono(
        size: 13,
        weight: FontWeight.w600,
        color: colors.onPrimary,
      ),
      emptyTitle: mono(size: 14, weight: FontWeight.w600, color: colors.title),
      error: mono(size: 12, color: colors.error, height: 1.45),
    );
  }

  final TextStyle display;
  final TextStyle heading;
  final TextStyle sectionTitle;
  final TextStyle appBarTitle;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle caption;
  final TextStyle muted;
  final TextStyle meterValue;
  final TextStyle badge;
  final TextStyle button;
  final TextStyle emptyTitle;
  final TextStyle error;

  @override
  TrayTypography copyWith({
    TextStyle? display,
    TextStyle? heading,
    TextStyle? sectionTitle,
    TextStyle? appBarTitle,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? caption,
    TextStyle? muted,
    TextStyle? meterValue,
    TextStyle? badge,
    TextStyle? button,
    TextStyle? emptyTitle,
    TextStyle? error,
  }) {
    return TrayTypography(
      display: display ?? this.display,
      heading: heading ?? this.heading,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      caption: caption ?? this.caption,
      muted: muted ?? this.muted,
      meterValue: meterValue ?? this.meterValue,
      badge: badge ?? this.badge,
      button: button ?? this.button,
      emptyTitle: emptyTitle ?? this.emptyTitle,
      error: error ?? this.error,
    );
  }

  @override
  TrayTypography lerp(ThemeExtension<TrayTypography>? other, double t) {
    if (other is! TrayTypography) return this;
    return TrayTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      appBarTitle: TextStyle.lerp(appBarTitle, other.appBarTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      muted: TextStyle.lerp(muted, other.muted, t)!,
      meterValue: TextStyle.lerp(meterValue, other.meterValue, t)!,
      badge: TextStyle.lerp(badge, other.badge, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      emptyTitle: TextStyle.lerp(emptyTitle, other.emptyTitle, t)!,
      error: TextStyle.lerp(error, other.error, t)!,
    );
  }
}
