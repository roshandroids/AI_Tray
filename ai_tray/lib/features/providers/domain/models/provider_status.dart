import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:meta/meta.dart';

/// Provider-neutral status categories consumed by shared presentation.
enum ProviderStatusKind { idle, refreshing, live, cached, error }

/// Immutable provider status projected from the refresh pipeline.
///
/// Data Flow:
/// - Refresh state is mapped into this model beside dashboard metrics.
/// - Shared UI reads this model without inspecting provider implementations.
@immutable
final class ProviderStatus {
  const ProviderStatus({
    required this.providerId,
    required this.kind,
    required this.sourceLabel,
    this.updatedAt,
    this.failureMessage,
  });

  final ProviderId providerId;
  final ProviderStatusKind kind;
  final String sourceLabel;
  final DateTime? updatedAt;
  final String? failureMessage;

  bool get isCached => kind == ProviderStatusKind.cached;
  bool get isRefreshing => kind == ProviderStatusKind.refreshing;
  bool get hasError => kind == ProviderStatusKind.error;

  @override
  bool operator ==(Object other) {
    return other is ProviderStatus &&
        other.providerId == providerId &&
        other.kind == kind &&
        other.sourceLabel == sourceLabel &&
        other.updatedAt == updatedAt &&
        other.failureMessage == failureMessage;
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    kind,
    sourceLabel,
    updatedAt,
    failureMessage,
  );
}
