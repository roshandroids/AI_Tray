import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';

/// Resolves bundled tray icon asset for a status kind (PD-020).
///
/// macOS: PNG variants with status badge.
/// Windows: falls back to static `.ico` (multi-state ICO not shipped).
abstract final class TrayIconResolver {
  static String macOsAsset(TrayStatusKind kind) => switch (kind) {
    TrayStatusKind.live => 'assets/tray/tray_icon_live.png',
    TrayStatusKind.cached => 'assets/tray/tray_icon_cached.png',
    TrayStatusKind.error => 'assets/tray/tray_icon_error.png',
    TrayStatusKind.refreshing => 'assets/tray/tray_icon_refreshing.png',
    TrayStatusKind.idle => 'assets/tray/tray_icon_waiting.png',
  };

  static const windowsAsset = 'assets/tray/tray_icon.ico';

  static String macOsTitlePrefix(TrayStatusKind kind) =>
      UsageStatusMapper.emoji(kind);
}
