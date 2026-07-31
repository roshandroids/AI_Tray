/// Recommended use-case tags for a font preset.
enum FontRecommendedFor {
  ui,
  coding,
  reading,
}

/// Application typography presets independent of color theme.
enum FontPreset {
  systemDefault,
  inter,
  jetBrainsMono,
  firaCode,
  ibmPlexSans,
  sfPro,
  roboto,
  geist,
  sourceSans3,
}

/// Metadata and family resolution for a [FontPreset].
extension FontPresetX on FontPreset {
  String get storageValue => name;

  static const FontPreset defaultPreset = FontPreset.inter;

  static FontPreset fromStorage(String? value) {
    if (value == null || value.isEmpty) return defaultPreset;
    return FontPreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => defaultPreset,
    );
  }

  String get displayName => switch (this) {
    FontPreset.systemDefault => 'System Default',
    FontPreset.inter => 'Inter',
    FontPreset.jetBrainsMono => 'JetBrains Mono',
    FontPreset.firaCode => 'Fira Code',
    FontPreset.ibmPlexSans => 'IBM Plex Sans',
    FontPreset.sfPro => 'SF Pro',
    FontPreset.roboto => 'Roboto',
    FontPreset.geist => 'Geist',
    FontPreset.sourceSans3 => 'Source Sans 3',
  };

  /// Primary font family name registered in pubspec or expected on the OS.
  ///
  /// Null means use the platform default (no explicit `TextStyle.fontFamily`).
  String? get fontFamily => switch (this) {
    FontPreset.systemDefault => null,
    FontPreset.inter => 'Inter',
    FontPreset.jetBrainsMono => 'JetBrainsMono',
    FontPreset.firaCode => 'FiraCode',
    FontPreset.ibmPlexSans => 'IBMPlexSans',
    FontPreset.sfPro => '.AppleSystemUIFont',
    FontPreset.roboto => 'Roboto',
    FontPreset.geist => 'Geist',
    FontPreset.sourceSans3 => 'Source Sans 3',
  };

  /// Fallbacks when [fontFamily] is unavailable on the device.
  List<String> get fontFamilyFallback => switch (this) {
    FontPreset.systemDefault => const [
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    FontPreset.inter => const [
      'SF Pro Text',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    FontPreset.jetBrainsMono => const [
      'IBMPlexMono',
      'FiraCode',
      'Menlo',
      'SF Mono',
      'Consolas',
      'monospace',
    ],
    FontPreset.firaCode => const [
      'JetBrainsMono',
      'IBMPlexMono',
      'Menlo',
      'Consolas',
      'monospace',
    ],
    FontPreset.ibmPlexSans => const [
      'Inter',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    FontPreset.sfPro => const [
      'SF Pro Text',
      'Helvetica Neue',
      'Segoe UI',
      'Roboto',
      'Arial',
      'sans-serif',
    ],
    FontPreset.roboto => const [
      'Segoe UI',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    FontPreset.geist => const [
      'Inter',
      'SF Pro Text',
      'Segoe UI',
      'Roboto',
      'sans-serif',
    ],
    FontPreset.sourceSans3 => const [
      'Source Sans Pro',
      'Inter',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
  };

  String get previewText => switch (this) {
    FontPreset.jetBrainsMono || FontPreset.firaCode => 'AiTray { usage: 42% }',
    _ => 'The quick brown fox jumps over the lazy dog',
  };

  FontRecommendedFor get recommendedFor => switch (this) {
    FontPreset.jetBrainsMono ||
    FontPreset.firaCode => FontRecommendedFor.coding,
    FontPreset.sourceSans3 ||
    FontPreset.ibmPlexSans => FontRecommendedFor.reading,
    _ => FontRecommendedFor.ui,
  };

  String get recommendedForLabel => switch (recommendedFor) {
    FontRecommendedFor.ui => 'UI',
    FontRecommendedFor.coding => 'Coding',
    FontRecommendedFor.reading => 'Reading',
  };

  /// Whether this preset ships font files with the app.
  bool get isBundled => switch (this) {
    FontPreset.inter ||
    FontPreset.jetBrainsMono ||
    FontPreset.firaCode ||
    FontPreset.ibmPlexSans ||
    FontPreset.geist => true,
    _ => false,
  };
}

/// Fixed mono stack for meters, logs, and terminal chrome.
abstract final class TrayMonoFonts {
  static const String family = 'JetBrainsMono';
  static const List<String> fallbacks = [
    'IBMPlexMono',
    'FiraCode',
    'Menlo',
    'SF Mono',
    'Monaco',
    'Consolas',
    'Cascadia Mono',
    'Courier New',
    'monospace',
  ];
}
