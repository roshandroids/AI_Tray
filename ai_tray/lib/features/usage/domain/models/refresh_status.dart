import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:meta/meta.dart';

/// Live refresh-loop state for UI binding.
@immutable
final class RefreshStatus {
  factory RefreshStatus({
    required RefreshPhase phase,
    RefreshResult? lastResult,
    DateTime? lastSuccessAt,
    DateTime? nextScheduledAt,
    int consecutiveSoftFailures = 0,
    int consecutiveHardFailures = 0,
  }) {
    if (consecutiveSoftFailures < 0) {
      throw ArgumentError.value(
        consecutiveSoftFailures,
        'consecutiveSoftFailures',
        'must be >= 0',
      );
    }
    if (consecutiveHardFailures < 0) {
      throw ArgumentError.value(
        consecutiveHardFailures,
        'consecutiveHardFailures',
        'must be >= 0',
      );
    }
    return RefreshStatus._(
      phase: phase,
      lastResult: lastResult,
      lastSuccessAt: lastSuccessAt,
      nextScheduledAt: nextScheduledAt,
      consecutiveSoftFailures: consecutiveSoftFailures,
      consecutiveHardFailures: consecutiveHardFailures,
    );
  }

  const RefreshStatus._({
    required this.phase,
    required this.lastResult,
    required this.lastSuccessAt,
    required this.nextScheduledAt,
    required this.consecutiveSoftFailures,
    required this.consecutiveHardFailures,
  });

  factory RefreshStatus.initial() {
    return RefreshStatus(phase: RefreshPhase.idle);
  }

  final RefreshPhase phase;
  final RefreshResult? lastResult;
  final DateTime? lastSuccessAt;
  final DateTime? nextScheduledAt;
  final int consecutiveSoftFailures;
  final int consecutiveHardFailures;

  RefreshStatus copyWith({
    RefreshPhase? phase,
    RefreshResult? lastResult,
    DateTime? lastSuccessAt,
    DateTime? nextScheduledAt,
    int? consecutiveSoftFailures,
    int? consecutiveHardFailures,
  }) {
    return RefreshStatus(
      phase: phase ?? this.phase,
      lastResult: lastResult ?? this.lastResult,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      nextScheduledAt: nextScheduledAt ?? this.nextScheduledAt,
      consecutiveSoftFailures:
          consecutiveSoftFailures ?? this.consecutiveSoftFailures,
      consecutiveHardFailures:
          consecutiveHardFailures ?? this.consecutiveHardFailures,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RefreshStatus &&
        other.phase == phase &&
        other.lastResult == lastResult &&
        other.lastSuccessAt == lastSuccessAt &&
        other.nextScheduledAt == nextScheduledAt &&
        other.consecutiveSoftFailures == consecutiveSoftFailures &&
        other.consecutiveHardFailures == consecutiveHardFailures;
  }

  @override
  int get hashCode => Object.hash(
    phase,
    lastResult,
    lastSuccessAt,
    nextScheduledAt,
    consecutiveSoftFailures,
    consecutiveHardFailures,
  );
}
