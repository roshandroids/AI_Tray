import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:meta/meta.dart';

/// Canonical subscription rate-limit snapshot for the tray.
@immutable
final class UsageInfo {
  factory UsageInfo({
    required double sessionUsedPercent,
    required DateTime fetchedAt,
    required UsageSource source,
    required bool isFromCache,
    required ProviderId providerId,
    DateTime? sessionResetsAt,
    String? sessionResetsAtRaw,
    List<WeeklyUsage> weekly = const [],
  }) {
    return UsageInfo._(
      sessionUsedPercent: _requirePercent(
        sessionUsedPercent,
        'sessionUsedPercent',
      ),
      sessionResetsAt: sessionResetsAt,
      sessionResetsAtRaw: sessionResetsAtRaw,
      weekly: List<WeeklyUsage>.unmodifiable(weekly),
      fetchedAt: fetchedAt,
      source: source,
      isFromCache: isFromCache,
      providerId: providerId,
    );
  }

  const UsageInfo._({
    required this.sessionUsedPercent,
    required this.sessionResetsAt,
    required this.sessionResetsAtRaw,
    required this.weekly,
    required this.fetchedAt,
    required this.source,
    required this.isFromCache,
    required this.providerId,
  });

  final double sessionUsedPercent;
  final DateTime? sessionResetsAt;
  final String? sessionResetsAtRaw;
  final List<WeeklyUsage> weekly;
  final DateTime fetchedAt;
  final UsageSource source;
  final bool isFromCache;
  final ProviderId providerId;

  UsageInfo copyWith({
    double? sessionUsedPercent,
    DateTime? sessionResetsAt,
    String? sessionResetsAtRaw,
    List<WeeklyUsage>? weekly,
    DateTime? fetchedAt,
    UsageSource? source,
    bool? isFromCache,
    ProviderId? providerId,
  }) {
    return UsageInfo(
      sessionUsedPercent: sessionUsedPercent ?? this.sessionUsedPercent,
      sessionResetsAt: sessionResetsAt ?? this.sessionResetsAt,
      sessionResetsAtRaw: sessionResetsAtRaw ?? this.sessionResetsAtRaw,
      weekly: weekly ?? this.weekly,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      source: source ?? this.source,
      isFromCache: isFromCache ?? this.isFromCache,
      providerId: providerId ?? this.providerId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! UsageInfo) return false;
    if (other.sessionUsedPercent != sessionUsedPercent ||
        other.sessionResetsAt != sessionResetsAt ||
        other.sessionResetsAtRaw != sessionResetsAtRaw ||
        other.fetchedAt != fetchedAt ||
        other.source != source ||
        other.isFromCache != isFromCache ||
        other.providerId != providerId ||
        other.weekly.length != weekly.length) {
      return false;
    }
    for (var i = 0; i < weekly.length; i++) {
      if (other.weekly[i] != weekly[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    sessionUsedPercent,
    sessionResetsAt,
    sessionResetsAtRaw,
    Object.hashAll(weekly),
    fetchedAt,
    source,
    isFromCache,
    providerId,
  );
}

double _requirePercent(double value, String name) {
  if (value.isNaN || value < 0 || value > 100) {
    throw ArgumentError.value(value, name, 'must be between 0 and 100');
  }
  return value;
}
