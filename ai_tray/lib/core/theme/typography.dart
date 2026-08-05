import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:flutter/material.dart';

/// Font families — JetBrains Mono primary for mono roles (PD-021).
abstract final class TrayFonts {
  static const String monoFamily = TrayMonoFonts.family;
  static const List<String> monoFallbacks = TrayMonoFonts.fallbacks;
}

/// Typography presets derived from semantic colors and a [FontPreset].
@immutable
final class TrayTypography extends ThemeExtension<TrayTypography> {
  const TrayTypography({
    required this.display,
    required this.title,
    required this.section,
    required this.label,
    required this.body,
    required this.caption,
    required this.monoData,
    required this.status,
    required this.terminalOutput,
    required this.button,
    required this.error,
  });

  factory TrayTypography.fromColors(
    TrayColorTokens colors, {
    FontPreset fontPreset = FontPresetX.defaultPreset,
  }) {
    TextStyle ui({
      required double size,
      required Color color,
      FontWeight weight = FontWeight.w400,
      double height = 1.5,
      double? letterSpacing,
    }) {
      return TextStyle(
        fontFamily: fontPreset.fontFamily,
        fontFamilyFallback: fontPreset.fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    TextStyle mono({
      required double size,
      required Color color,
      FontWeight weight = FontWeight.w400,
      double height = 1.5,
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
      display: ui(
        size: 18,
        weight: FontWeight.w700,
        color: colors.textPrimary,
        height: 28 / 18,
      ),
      title: ui(
        size: 18,
        weight: FontWeight.w700,
        color: colors.textPrimary,
        height: 28 / 18,
      ),
      section: ui(
        size: 14,
        weight: FontWeight.w600,
        color: colors.textPrimary,
        height: 20 / 14,
        letterSpacing: 0.4,
      ),
      label: ui(
        size: 12,
        weight: FontWeight.w500,
        color: colors.textSecondary,
        height: 18 / 12,
      ),
      body: ui(
        size: 12,
        color: colors.textPrimary,
        height: 18 / 12,
      ),
      caption: ui(
        size: 11,
        color: colors.textMuted,
        height: 16 / 11,
      ),
      monoData: mono(
        size: 12,
        weight: FontWeight.w500,
        color: colors.textPrimary,
        height: 18 / 12,
      ),
      status: ui(
        size: 12,
        weight: FontWeight.w600,
        color: colors.textPrimary,
        height: 18 / 12,
      ),
      terminalOutput: mono(
        size: 12,
        color: colors.textSecondary,
        height: 18 / 12,
      ),
      button: ui(
        size: 12,
        weight: FontWeight.w600,
        color: colors.onAccent,
        height: 18 / 12,
      ),
      error: ui(
        size: 12,
        color: colors.error,
        height: 18 / 12,
      ),
    );
  }

  final TextStyle display;
  final TextStyle title;
  final TextStyle section;
  final TextStyle label;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle monoData;
  final TextStyle status;
  final TextStyle terminalOutput;
  final TextStyle button;
  final TextStyle error;

  @override
  TrayTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? section,
    TextStyle? label,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? monoData,
    TextStyle? status,
    TextStyle? terminalOutput,
    TextStyle? button,
    TextStyle? error,
  }) {
    return TrayTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      section: section ?? this.section,
      label: label ?? this.label,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      monoData: monoData ?? this.monoData,
      status: status ?? this.status,
      terminalOutput: terminalOutput ?? this.terminalOutput,
      button: button ?? this.button,
      error: error ?? this.error,
    );
  }

  @override
  TrayTypography lerp(ThemeExtension<TrayTypography>? other, double t) {
    if (other is! TrayTypography) return this;
    return TrayTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      section: TextStyle.lerp(section, other.section, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      monoData: TextStyle.lerp(monoData, other.monoData, t)!,
      status: TextStyle.lerp(status, other.status, t)!,
      terminalOutput: TextStyle.lerp(terminalOutput, other.terminalOutput, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      error: TextStyle.lerp(error, other.error, t)!,
    );
  }
}
