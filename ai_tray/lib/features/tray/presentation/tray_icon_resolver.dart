import 'package:ai_tray/features/tray/domain/tray_display_mode.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';

/// Resolves tray / menu-bar icon assets and macOS title density.
///
/// macOS menu bar uses a dedicated monochrome **template** glyph
/// ([macOsMenuBarTemplate]) separate from the application icon branding.
/// Usage is never encoded in the glyph; the title / tooltip carry numbers.
abstract final class TrayIconResolver {
  /// Primary macOS menu-bar template (solid mark, black on transparent).
  ///
  /// Pass to `trayManager.setIcon(..., isTemplate: true)` so the system
  /// tints the glyph for Light and Dark menu bars.
  static const macOsMenuBarTemplate = 'assets/tray/tray_menubar_template.png';

  /// Dimmed template (~35% alpha) used for the refreshing opacity pulse.
  static const macOsMenuBarTemplateDim =
      'assets/tray/tray_menubar_template_dim.png';

  /// Optional 18pt @2x template when a denser menu-bar size is preferred.
  static const macOsMenuBarTemplate36 =
      'assets/tray/tray_menubar_template_36.png';

  /// Legacy per-status color PNGs (not used for the live menu-bar glyph).
  static String macOsStatusAsset(TrayStatusKind kind) => switch (kind) {
    TrayStatusKind.live => 'assets/tray/tray_icon_live.png',
    TrayStatusKind.cached => 'assets/tray/tray_icon_cached.png',
    TrayStatusKind.error => 'assets/tray/tray_icon_error.png',
    TrayStatusKind.refreshing => 'assets/tray/tray_icon_refreshing.png',
    TrayStatusKind.idle => 'assets/tray/tray_icon_waiting.png',
  };

  /// Legacy alias for [macOsStatusAsset].
  static String macOsAsset(TrayStatusKind kind) => macOsStatusAsset(kind);

  static const windowsAsset = 'assets/tray/tray_icon.ico';

  /// Compact macOS menu-bar title based on [TrayDisplayMode].
  ///
  /// Never includes emoji. Empty string means icon-only.
  static String macOsTitle({
    required TrayDisplayMode mode,
    required double threshold,
    required TrayStatusKind kind,
    required double? sessionPercent,
  }) {
    final pct = sessionPercent == null
        ? null
        : '${sessionPercent.clamp(0, 100).round()}%';

    return switch (mode) {
      TrayDisplayMode.iconOnly => '',
      TrayDisplayMode.alwaysPercent => pct ?? '',
      TrayDisplayMode.adaptive => _adaptiveTitle(
        kind: kind,
        threshold: threshold,
        percentLabel: pct,
        sessionPercent: sessionPercent,
      ),
    };
  }

  static String _adaptiveTitle({
    required TrayStatusKind kind,
    required double threshold,
    required String? percentLabel,
    required double? sessionPercent,
  }) {
    if (kind == TrayStatusKind.error || kind == TrayStatusKind.refreshing) {
      return percentLabel ?? '';
    }
    if (sessionPercent != null && sessionPercent >= threshold) {
      return percentLabel!;
    }
    return '';
  }

  /// Whether the adaptive / always modes should reveal a title for [kind].
  static bool shouldRevealPercent({
    required TrayDisplayMode mode,
    required double threshold,
    required TrayStatusKind kind,
    required double? sessionPercent,
  }) {
    return macOsTitle(
      mode: mode,
      threshold: threshold,
      kind: kind,
      sessionPercent: sessionPercent,
    ).isNotEmpty;
  }
}
