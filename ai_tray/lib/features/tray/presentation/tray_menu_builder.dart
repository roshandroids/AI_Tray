import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:meta/meta.dart';
import 'package:tray_manager/tray_manager.dart';

/// View model for the native tray context menu (PD-015).
@immutable
final class TrayMenuSnapshot {
  const TrayMenuSnapshot({
    required this.title,
    required this.connectionLabel,
    required this.sessionBarLine,
    required this.sessionPercentLine,
    required this.sessionResetLine,
    required this.weekTitleLine,
    required this.weekBarLine,
    required this.weekPercentLine,
    required this.weekResetLine,
    required this.footerStatusLine,
    required this.footerUpdatedLine,
    required this.toolTip,
    required this.iconTitle,
  });

  final String title;
  final String connectionLabel;
  final String sessionBarLine;
  final String sessionPercentLine;
  final String sessionResetLine;
  final String weekTitleLine;
  final String weekBarLine;
  final String weekPercentLine;
  final String weekResetLine;
  final String footerStatusLine;
  final String footerUpdatedLine;
  final String toolTip;
  /// macOS menu-bar title beside the tray icon (empty when unavailable).
  final String iconTitle;

  Menu buildMenu() {
    return Menu(
      items: [
        _info('hdr_title', title),
        MenuItem.separator(),
        _info('hdr_connection', connectionLabel),
        MenuItem.separator(),
        _info('hdr_session', 'Current Session'),
        _info('session_bar', sessionBarLine),
        _info('session_pct', sessionPercentLine),
        _info('session_reset', sessionResetLine),
        MenuItem.separator(),
        _info('hdr_week', weekTitleLine),
        _info('week_bar', weekBarLine),
        _info('week_pct', weekPercentLine),
        _info('week_reset', weekResetLine),
        MenuItem.separator(),
        _info('footer_status', footerStatusLine),
        _info('footer_updated', footerUpdatedLine),
        MenuItem.separator(),
        MenuItem(key: 'open', label: 'Open Dashboard'),
        MenuItem(key: 'refresh', label: 'Refresh Now'),
        MenuItem(key: 'settings', label: 'Settings'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    );
  }

  static MenuItem _info(String key, String label) {
    return MenuItem(key: key, label: label, disabled: true);
  }
}

/// Builds tray menu labels from live refresh status (presentation only).
abstract final class TrayMenuBuilder {
  static const _barWidth = 10;

  static TrayMenuSnapshot fromStatus(RefreshStatus status) {
    final usage = status.lastResult?.usage;
    final outcome = status.lastResult?.status;
    final error = status.lastResult?.error;
    final refreshing = status.phase == RefreshPhase.refreshing;

    final sessionPct = usage?.sessionUsedPercent;
    final week = _primaryWeek(usage);

    final connection = _connectionLabel(
      refreshing: refreshing,
      usage: usage,
      error: error,
    );
    final badge = _statusBadge(
      refreshing: refreshing,
      usage: usage,
      outcome: outcome,
      error: error,
    );
    final updatedAt = status.lastSuccessAt ?? usage?.fetchedAt;
    final updated = _relativeUpdated(updatedAt);

    final sessionBar = sessionPct != null
        ? _progressBar(sessionPct)
        : _progressBar(0);
    final sessionPctLine = sessionPct != null
        ? '${sessionPct.round()}% used'
        : '—';
    final sessionReset = (usage?.sessionResetsAtRaw?.trim().isNotEmpty ?? false)
        ? 'Resets ${usage!.sessionResetsAtRaw!.trim()}'
        : 'Resets —';

    final weekTitle = week != null
        ? _weekTitle(week.label)
        : 'Current Week';
    final weekBar =
        week != null ? _progressBar(week.usedPercent) : _progressBar(0);
    final weekPctLine =
        week != null ? '${week.usedPercent.round()}% used' : '—';
    final weekReset = (week?.resetsAtRaw?.trim().isNotEmpty ?? false)
        ? 'Resets ${week!.resetsAtRaw!.trim()}'
        : 'Resets —';

    final toolTip = _toolTip(
      sessionPct: sessionPct,
      weekPct: week?.usedPercent,
      badge: badge,
    );

    final iconTitle = sessionPct != null && !refreshing
        ? '${sessionPct.round()}%'
        : '';

    return TrayMenuSnapshot(
      title: 'AI Tray',
      connectionLabel: connection,
      sessionBarLine: sessionBar,
      sessionPercentLine: sessionPctLine,
      sessionResetLine: sessionReset,
      weekTitleLine: weekTitle,
      weekBarLine: weekBar,
      weekPercentLine: weekPctLine,
      weekResetLine: weekReset,
      footerStatusLine: badge,
      footerUpdatedLine: 'Updated $updated',
      toolTip: toolTip,
      iconTitle: iconTitle,
    );
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

  static String _weekTitle(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return 'Current Week';
    return 'Current Week ($trimmed)';
  }

  static String _progressBar(double percent) {
    final clamped = percent.clamp(0.0, 100.0);
    final filled = (clamped / 100 * _barWidth).round().clamp(0, _barWidth);
    final empty = _barWidth - filled;
    return '${'█' * filled}${'░' * empty}';
  }

  static String _connectionLabel({
    required bool refreshing,
    required UsageInfo? usage,
    required AppFailure? error,
  }) {
    if (refreshing) return '🔄 Refreshing…';
    if (error != null) {
      return switch (error.code) {
        FailureCode.cliNotInstalled => '🔴 Claude CLI not found',
        FailureCode.notAuthenticated => '🔴 Not authenticated',
        FailureCode.timeout => '🔴 Refresh timed out',
        FailureCode.processLaunchFailed ||
        FailureCode.processNonZeroExit =>
          '🔴 Could not reach Claude',
        _ => '🔴 Connection error',
      };
    }
    if (usage != null) return '🟢 Claude connected';
    return '⚪ Waiting for usage data';
  }

  static String _statusBadge({
    required bool refreshing,
    required UsageInfo? usage,
    required RefreshOutcome? outcome,
    required AppFailure? error,
  }) {
    if (refreshing) return '🔄 Refreshing';
    if (outcome == RefreshOutcome.failure && error != null) {
      return '🔴 Error';
    }
    if (usage == null) return '⚪ Waiting';
    if (usage.isFromCache || outcome == RefreshOutcome.softFailure) {
      return '🟡 Cached';
    }
    return '🟢 Live';
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
    required double? sessionPct,
    required double? weekPct,
    required String badge,
  }) {
    final parts = <String>['AI Tray'];
    if (sessionPct != null) {
      parts.add('Session ${sessionPct.round()}%');
    }
    if (weekPct != null) {
      parts.add('Week ${weekPct.round()}%');
    }
    final status = badge.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (status.isNotEmpty) parts.add(status);
    return parts.join(' · ');
  }
}
