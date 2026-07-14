import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';

/// Shared status derivation for dashboard, settings, tray (PD-020).
abstract final class UsageStatusMapper {
  static TrayStatusKind kind(RefreshStatus status) {
    final usage = status.lastResult?.usage;
    final outcome = status.lastResult?.status;
    if (status.phase == RefreshPhase.refreshing) {
      return TrayStatusKind.refreshing;
    }
    if (outcome == RefreshOutcome.failure && usage == null) {
      return TrayStatusKind.error;
    }
    if (outcome == RefreshOutcome.failure && usage != null) {
      return TrayStatusKind.cached;
    }
    if (usage == null) {
      return TrayStatusKind.idle;
    }
    if (usage.isFromCache || outcome == RefreshOutcome.softFailure) {
      return TrayStatusKind.cached;
    }
    return TrayStatusKind.live;
  }

  static String emoji(TrayStatusKind kind) => switch (kind) {
    TrayStatusKind.live => '🟢',
    TrayStatusKind.cached => '🟡',
    TrayStatusKind.refreshing => '🔵',
    TrayStatusKind.error => '🔴',
    TrayStatusKind.idle => '⚪',
  };

  static String label(TrayStatusKind kind) => switch (kind) {
    TrayStatusKind.live => 'Live',
    TrayStatusKind.cached => 'Cached',
    TrayStatusKind.refreshing => 'Refreshing',
    TrayStatusKind.error => 'Error',
    TrayStatusKind.idle => 'Waiting',
  };

  static String relativeUpdated(DateTime? at) {
    if (at == null) return 'never';
    final now = DateTime.now().toUtc();
    final utc = at.isUtc ? at : at.toUtc();
    final delta = now.difference(utc);
    if (delta.inSeconds < 5) return 'just now';
    if (delta.inSeconds < 60) return '${delta.inSeconds}s ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }

  static String sourceLabel(UsageInfo? usage) {
    if (usage == null) return '—';
    return usage.isFromCache ? 'Cache (LKG)' : 'Claude CLI';
  }
}
