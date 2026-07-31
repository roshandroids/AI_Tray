/// How the macOS menu-bar title shows session usage beside the tray icon.
enum TrayDisplayMode {
  /// Show `%` only when usage ≥ threshold, or while refreshing / error.
  adaptive,

  /// Always show session `%` when available.
  alwaysPercent,

  /// Never show a title; icon (+ tooltip) only.
  iconOnly,
}

/// Storage / display helpers for [TrayDisplayMode].
extension TrayDisplayModeX on TrayDisplayMode {
  String get storageValue => name;

  String get displayName => switch (this) {
    TrayDisplayMode.adaptive => 'Adaptive',
    TrayDisplayMode.alwaysPercent => 'Always show %',
    TrayDisplayMode.iconOnly => 'Icon only',
  };

  String get description => switch (this) {
    TrayDisplayMode.adaptive =>
      'Show the percentage only when usage is high or status needs attention.',
    TrayDisplayMode.alwaysPercent =>
      'Always show session usage beside the icon.',
    TrayDisplayMode.iconOnly =>
      'Keep the menu bar quiet; usage stays in the menu and tooltip.',
  };

  static const TrayDisplayMode defaultMode = TrayDisplayMode.adaptive;

  static TrayDisplayMode fromStorage(String? value) {
    if (value == null || value.isEmpty) return defaultMode;
    return TrayDisplayMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => defaultMode,
    );
  }
}
