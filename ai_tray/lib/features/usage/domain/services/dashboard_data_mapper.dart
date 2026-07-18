import 'package:ai_tray/features/providers/domain/models/provider_capabilities.dart';
import 'package:ai_tray/features/providers/domain/models/provider_status.dart';
import 'package:ai_tray/features/providers/domain/models/provider_usage_metric.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/usage/domain/models/dashboard_data.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';

/// Maps repository output into provider-neutral dashboard content.
///
/// Transformation:
/// - Emits metrics only when the active provider declares the capability.
/// - Projects refresh state into a shared provider status.
/// - Never branches on a concrete provider identifier.
abstract final class DashboardDataMapper {
  static DashboardData map({
    required AIProvider provider,
    required UsageInfo usage,
    required RefreshStatus refreshStatus,
  }) {
    final metrics = [
      for (final metric in _effectiveMetrics(provider.capabilities, usage))
        DashboardMetric(
          key: metric.key,
          kind: _kindFor(metric),
          label: metric.label,
          usedPercent: metric.usedPercent,
          resetsAtRaw: metric.resetsAtRaw,
          value: metric.value,
          total: metric.total,
          unit: metric.unit,
          remainingPercent: metric.remainingPercent,
          unlimited: metric.unlimited,
        ),
    ];

    return DashboardData(
      providerId: provider.providerId,
      providerName: provider.displayName,
      capabilities: provider.capabilities,
      metrics: metrics,
      status: ProviderStatus(
        providerId: provider.providerId,
        kind: _statusKind(refreshStatus),
        sourceLabel: usage.isFromCache ? 'Cache (LKG)' : provider.sourceLabel,
        updatedAt: refreshStatus.lastSuccessAt ?? usage.fetchedAt,
        failureMessage: refreshStatus.lastResult?.error?.message,
      ),
      limitsUnavailableMessage: provider.limitsUnavailableMessage,
    );
  }

  static Iterable<ProviderUsageMetric> _effectiveMetrics(
    ProviderCapabilities capabilities,
    UsageInfo usage,
  ) sync* {
    var emittedSecondary = false;
    for (final metric in usage.metrics) {
      if (!_includeMetric(capabilities, metric)) continue;
      if (!metric.primary) emittedSecondary = true;
      yield metric;
    }

    // Claude may still carry weekly rows only on [UsageInfo.weekly]
    // (for example older cache payloads). Project them when weekly
    // capability is enabled and no secondary metric was already emitted.
    if (!capabilities.weeklyUsage || emittedSecondary) return;
    for (var index = 0; index < usage.weekly.length; index++) {
      final week = usage.weekly[index];
      yield ProviderUsageMetric(
        key: 'week-$index-${week.label}',
        label: week.label.trim().isEmpty ? 'Week' : week.label,
        usedPercent: week.usedPercent,
        primary: false,
        resetsAt: week.resetsAt,
        resetsAtRaw: week.resetsAtRaw,
      );
    }
  }

  static bool _includeMetric(
    ProviderCapabilities capabilities,
    ProviderUsageMetric metric,
  ) {
    final isAbsolute =
        metric.value != null || metric.total != null || metric.unlimited;
    // Absolute / unlimited quotas are session-capability rich cards (Copilot).
    if (isAbsolute) return capabilities.sessionUsage;
    if (metric.primary) return capabilities.sessionUsage;
    return capabilities.weeklyUsage;
  }

  static DashboardMetricKind _kindFor(ProviderUsageMetric metric) {
    if (metric.value != null || metric.total != null || metric.unlimited) {
      return DashboardMetricKind.absoluteUsage;
    }
    return metric.primary
        ? DashboardMetricKind.sessionUsage
        : DashboardMetricKind.weeklyUsage;
  }

  static ProviderStatusKind _statusKind(RefreshStatus status) {
    final usage = status.lastResult?.usage;
    final outcome = status.lastResult?.status;
    if (status.phase == RefreshPhase.refreshing) {
      return ProviderStatusKind.refreshing;
    }
    if (outcome == RefreshOutcome.failure && usage == null) {
      return ProviderStatusKind.error;
    }
    if (outcome == RefreshOutcome.failure && usage != null) {
      return ProviderStatusKind.cached;
    }
    if (usage == null) {
      return ProviderStatusKind.idle;
    }
    if (usage.isFromCache || outcome == RefreshOutcome.softFailure) {
      return ProviderStatusKind.cached;
    }
    return ProviderStatusKind.live;
  }
}
