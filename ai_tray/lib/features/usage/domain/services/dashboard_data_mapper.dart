import 'package:ai_tray/features/providers/domain/models/provider_status.dart';
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
    final metrics = <DashboardMetric>[];
    if (provider.capabilities.sessionUsage) {
      metrics.add(
        DashboardMetric(
          key: 'session',
          kind: DashboardMetricKind.sessionUsage,
          label: 'Session',
          usedPercent: usage.sessionUsedPercent,
          resetsAtRaw: usage.sessionResetsAtRaw,
        ),
      );
    }
    if (provider.capabilities.weeklyUsage) {
      for (var index = 0; index < usage.weekly.length; index++) {
        final week = usage.weekly[index];
        metrics.add(
          DashboardMetric(
            key: 'week-$index-${week.label}',
            kind: DashboardMetricKind.weeklyUsage,
            label: week.label.trim().isEmpty ? 'Week' : week.label,
            usedPercent: week.usedPercent,
            resetsAtRaw: week.resetsAtRaw,
          ),
        );
      }
    }

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
