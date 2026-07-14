/// Layout spacing — 8-point scale (PD-021).
library;

export 'radius.dart';
export 'shadows.dart';

/// Spacing tokens.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Legacy alias used by older widgets.
  static const double twoXl = xxl;

  static const double contentMaxWidth = 720;
  static const double settingsRailWidth = 168;
  static const double meterHeight = 4;
  static const double progressRingSize = 72;
  static const double trayIconSize = 22;

  // Radius aliases (prefer [RadiusTokens]).
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
}
