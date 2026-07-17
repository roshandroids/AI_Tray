import 'dart:collection';

import 'package:ai_tray/features/providers/domain/models/provider_capabilities.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/models/provider_status.dart';
import 'package:meta/meta.dart';

/// Semantic dashboard metric types supported by shared cards.
enum DashboardMetricKind { sessionUsage, weeklyUsage }

/// Provider-neutral data required by one dashboard metric card.
@immutable
final class DashboardMetric {
  const DashboardMetric({
    required this.key,
    required this.kind,
    required this.label,
    required this.usedPercent,
    this.resetsAtRaw,
  });

  final String key;
  final DashboardMetricKind kind;
  final String label;
  final double usedPercent;
  final String? resetsAtRaw;
}

/// Complete provider-neutral snapshot consumed by the dashboard.
///
/// Data Source:
/// - Provider metadata and capabilities from the provider registry.
/// - Canonical usage and refresh state from the existing repository.
@immutable
final class DashboardData {
  DashboardData({
    required this.providerId,
    required this.providerName,
    required this.capabilities,
    required Iterable<DashboardMetric> metrics,
    required this.status,
    required this.limitsUnavailableMessage,
  }) : metrics = UnmodifiableListView(metrics);

  final ProviderId providerId;
  final String providerName;
  final ProviderCapabilities capabilities;
  final UnmodifiableListView<DashboardMetric> metrics;
  final ProviderStatus status;
  final String limitsUnavailableMessage;
}
