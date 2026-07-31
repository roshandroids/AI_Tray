import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Branded color theme presets for AI Tray.
///
/// Only brand seed colors are defined; FlexColorScheme generates the remaining
/// Material 3 [ColorScheme] roles. Built-in [FlexScheme] values are never used.
enum ThemePreset {
  cursor,
  tokyoNight,
  catppuccinMocha,
  nord,
  oneDark,
  dracula,
  github,
  gruvbox,
}

/// Metadata and FlexColorScheme seed colors for a [ThemePreset].
extension ThemePresetX on ThemePreset {
  /// Stable storage key.
  String get storageValue => name;

  /// Default preset when none is stored.
  static const ThemePreset defaultPreset = ThemePreset.cursor;

  static ThemePreset fromStorage(String? value) {
    if (value == null || value.isEmpty) return defaultPreset;
    return ThemePreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => defaultPreset,
    );
  }

  String get displayName => switch (this) {
    ThemePreset.cursor => 'Cursor',
    ThemePreset.tokyoNight => 'Tokyo Night',
    ThemePreset.catppuccinMocha => 'Catppuccin Mocha',
    ThemePreset.nord => 'Nord',
    ThemePreset.oneDark => 'One Dark',
    ThemePreset.dracula => 'Dracula',
    ThemePreset.github => 'GitHub',
    ThemePreset.gruvbox => 'Gruvbox',
  };

  String get description => switch (this) {
    ThemePreset.cursor =>
      'Muted developer-tool palette inspired by modern IDEs.',
    ThemePreset.tokyoNight => 'Cool blue night palette with soft accents.',
    ThemePreset.catppuccinMocha => 'Warm pastel mocha tones with low contrast.',
    ThemePreset.nord => 'Arctic, bluish Nord palette with calm accents.',
    ThemePreset.oneDark => 'Atom One Dark inspired violet and cyan accents.',
    ThemePreset.dracula => 'Classic Dracula purple with soft pink accents.',
    ThemePreset.github => 'GitHub light/dark surfaces with blue primary.',
    ThemePreset.gruvbox => 'Earthy Gruvbox warm oranges and greens.',
  };

  /// Swatch color used in theme pickers.
  Color get previewColor => dark.primary;

  /// Light-mode brand seeds.
  FlexSchemeColor get light => switch (this) {
    ThemePreset.cursor => const FlexSchemeColor(
      primary: Color(0xFF5B5FC7),
      secondary: Color(0xFF0969DA),
      tertiary: Color(0xFF8250DF),
      error: Color(0xFFCF222E),
    ),
    ThemePreset.tokyoNight => const FlexSchemeColor(
      primary: Color(0xFF2E7DE9),
      secondary: Color(0xFF9854F1),
      tertiary: Color(0xFF07879D),
      error: Color(0xFFF52A65),
    ),
    ThemePreset.catppuccinMocha => const FlexSchemeColor(
      primary: Color(0xFF8839EF),
      secondary: Color(0xFF1E66F5),
      tertiary: Color(0xFFEA76CB),
      error: Color(0xFFD20F39),
    ),
    ThemePreset.nord => const FlexSchemeColor(
      primary: Color(0xFF5E81AC),
      secondary: Color(0xFF81A1C1),
      tertiary: Color(0xFF88C0D0),
      error: Color(0xFFBF616A),
    ),
    ThemePreset.oneDark => const FlexSchemeColor(
      primary: Color(0xFF526FFF),
      secondary: Color(0xFF01A0E4),
      tertiary: Color(0xFFA626A4),
      error: Color(0xFFE45649),
    ),
    ThemePreset.dracula => const FlexSchemeColor(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFFDB61A2),
      tertiary: Color(0xFF50FA7B),
      error: Color(0xFFFF5555),
    ),
    ThemePreset.github => const FlexSchemeColor(
      primary: Color(0xFF0969DA),
      secondary: Color(0xFF1A7F37),
      tertiary: Color(0xFF8250DF),
      error: Color(0xFFCF222E),
    ),
    ThemePreset.gruvbox => const FlexSchemeColor(
      primary: Color(0xFFAF3A03),
      secondary: Color(0xFF79740E),
      tertiary: Color(0xFF076678),
      error: Color(0xFF9D0006),
    ),
  };

  /// Dark-mode brand seeds.
  FlexSchemeColor get dark => switch (this) {
    ThemePreset.cursor => const FlexSchemeColor(
      primary: Color(0xFF8B8CF0),
      secondary: Color(0xFF58A6FF),
      tertiary: Color(0xFFA371F7),
      error: Color(0xFFF85149),
    ),
    ThemePreset.tokyoNight => const FlexSchemeColor(
      primary: Color(0xFF7AA2F7),
      secondary: Color(0xFFBB9AF7),
      tertiary: Color(0xFF7DCFFF),
      error: Color(0xFFF7768E),
    ),
    ThemePreset.catppuccinMocha => const FlexSchemeColor(
      primary: Color(0xFFCBA6F7),
      secondary: Color(0xFF89B4FA),
      tertiary: Color(0xFFF5C2E7),
      error: Color(0xFFF38BA8),
    ),
    ThemePreset.nord => const FlexSchemeColor(
      primary: Color(0xFF88C0D0),
      secondary: Color(0xFF81A1C1),
      tertiary: Color(0xFFB48EAD),
      error: Color(0xFFBF616A),
    ),
    ThemePreset.oneDark => const FlexSchemeColor(
      primary: Color(0xFF61AFEF),
      secondary: Color(0xFF56B6C2),
      tertiary: Color(0xFFC678DD),
      error: Color(0xFFE06C75),
    ),
    ThemePreset.dracula => const FlexSchemeColor(
      primary: Color(0xFFBD93F9),
      secondary: Color(0xFFFF79C6),
      tertiary: Color(0xFF50FA7B),
      error: Color(0xFFFF5555),
    ),
    ThemePreset.github => const FlexSchemeColor(
      primary: Color(0xFF58A6FF),
      secondary: Color(0xFF3FB950),
      tertiary: Color(0xFFA371F7),
      error: Color(0xFFF85149),
    ),
    ThemePreset.gruvbox => const FlexSchemeColor(
      primary: Color(0xFFFE8019),
      secondary: Color(0xFFB8BB26),
      tertiary: Color(0xFF83A598),
      error: Color(0xFFFB4934),
    ),
  };
}
