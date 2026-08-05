import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:meta/meta.dart';
import 'package:tray_manager/tray_manager.dart';

/// View model for the native tray context menu.
///
/// Kept concise to match macOS menu-bar extra conventions: short status lines,
/// then standard actions — no emoji chrome or ASCII meters.
@immutable
final class TrayMenuSnapshot {
  const TrayMenuSnapshot({
    required this.headerLine,
    required this.sessionLine,
    required this.weekLine,
    required this.updatedLine,
    required this.toolTip,
    required this.iconTitle,
  });

  final String headerLine;
  final String sessionLine;
  final String weekLine;
  final String updatedLine;
  final String toolTip;

  /// Resolved macOS menu-bar title (may be empty for icon-only / adaptive quiet).
  final String iconTitle;

  Menu buildMenu() {
    return Menu(
      items: [
        _info('hdr', headerLine),
        _info('session', sessionLine),
        _info('week', weekLine),
        _info('updated', updatedLine),
        MenuItem.separator(),
        MenuItem(key: 'open', label: 'Open Dashboard'),
        MenuItem(key: 'refresh', label: 'Refresh Now'),
        MenuItem(key: 'settings', label: 'Settings…'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit AI Tray'),
      ],
    );
  }

  static MenuItem _info(String key, String label) {
    return MenuItem(key: key, label: label, disabled: true);
  }
}

/// Builds tray menu labels from live refresh status (presentation only).
abstract final class TrayMenuBuilder {
  static TrayMenuSnapshot fromStatus(
    RefreshStatus status, {
    String providerDisplayName = 'Claude',
    String providerSourceLabel = 'Claude CLI',
    String iconTitle = '',
  }) {
    final usage = status.lastResult?.usage;
    final error = status.lastResult?.error;
    final refreshing = status.phase == RefreshPhase.refreshing;

    final sessionPct = usage?.sessionUsedPercent;
    final week = _primaryWeek(usage);
    // Delegates to the same kind/label resolution the dashboard's
    // StatusBadge uses (UsageStatusMapper, V4 §1.2) so the native tray
    // menu text can't drift from the in-app badge wording.
    final badge = UsageStatusMapper.label(UsageStatusMapper.kind(status));
    final updatedAt = status.lastSuccessAt ?? usage?.fetchedAt;

    final header = _headerLine(
      providerDisplayName: providerDisplayName,
      badge: badge,
      error: error,
      providerSourceLabel: providerSourceLabel,
      refreshing: refreshing,
    );

    final sessionLine = sessionPct != null
        ? _sessionLine(usage!, sessionPct)
        : 'Session —';
    final weekLine = week != null
        ? 'Week ${week.usedPercent.round()}%'
        : 'Week —';
    final updatedLine = 'Updated ${_relativeUpdated(updatedAt)}';

    final toolTip = _toolTip(
      providerDisplayName: providerDisplayName,
      sessionPct: sessionPct,
      weekPct: week?.usedPercent,
      badge: badge,
      sessionReset: usage?.sessionResetsAtRaw,
    );

    return TrayMenuSnapshot(
      headerLine: header,
      sessionLine: sessionLine,
      weekLine: weekLine,
      updatedLine: updatedLine,
      toolTip: toolTip,
      iconTitle: iconTitle,
    );
  }

  static String _sessionLine(UsageInfo usage, double sessionPct) {
    final reset = usage.sessionResetsAtRaw?.trim();
    final pct = '${sessionPct.round()}%';
    if (reset != null && reset.isNotEmpty) {
      return 'Session $pct · Resets $reset';
    }
    return 'Session $pct';
  }

  static WeeklyUsage? _primaryWeek(UsageInfo? usage) {
    if (usage == null || usage.weekly.isEmpty) return null;
    for (final bucket in usage.weekly) {
      if (bucket.label.toLowerCase().contains('all models')) {
        return bucket;
      }
    }
    return usage.weekly.first;
  }

  static String _headerLine({
    required String providerDisplayName,
    required String badge,
    required AppFailure? error,
    required String providerSourceLabel,
    required bool refreshing,
  }) {
    if (refreshing) return '$providerDisplayName · Refreshing';
    if (error != null) {
      return switch (error.code) {
        FailureCode.cliNotInstalled => '$providerSourceLabel not found',
        FailureCode.notAuthenticated => 'Not authenticated',
        FailureCode.timeout => 'Refresh timed out',
        FailureCode.processLaunchFailed || FailureCode.processNonZeroExit =>
          'Could not reach $providerDisplayName',
        _ => '$providerDisplayName · Error',
      };
    }
    return '$providerDisplayName · $badge';
  }

  static String _relativeUpdated(DateTime? at) {
    if (at == null) return 'never';
    final now = DateTime.now().toUtc();
    final utc = at.isUtc ? at : at.toUtc();
    final delta = now.difference(utc);
    if (delta.inSeconds < 5) return 'just now';
    if (delta.inSeconds < 60) return '${delta.inSeconds} sec ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hr ago';
    return '${delta.inDays} day${delta.inDays == 1 ? '' : 's'} ago';
  }

  static String _toolTip({
    required String providerDisplayName,
    required double? sessionPct,
    required double? weekPct,
    required String badge,
    required String? sessionReset,
  }) {
    final parts = <String>['AI Tray', providerDisplayName];
    if (sessionPct != null) {
      parts.add('Session ${sessionPct.round()}%');
    }
    if (weekPct != null) {
      parts.add('Week ${weekPct.round()}%');
    }
    final reset = sessionReset?.trim();
    if (reset != null && reset.isNotEmpty) {
      parts.add('Resets $reset');
    }
    parts.add(badge);
    return parts.join(' · ');
  }
}
