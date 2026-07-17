import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:meta/meta.dart';

/// Provider authentication probe result.
@immutable
final class AuthHealth {
  const AuthHealth({
    required this.loggedIn,
    required this.checkedAt,
    this.subscriptionType,
  });

  final bool loggedIn;
  final String? subscriptionType;
  final DateTime checkedAt;

  AuthHealth copyWith({
    bool? loggedIn,
    String? subscriptionType,
    DateTime? checkedAt,
  }) {
    return AuthHealth(
      loggedIn: loggedIn ?? this.loggedIn,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthHealth &&
        other.loggedIn == loggedIn &&
        other.subscriptionType == subscriptionType &&
        other.checkedAt == checkedAt;
  }

  @override
  int get hashCode => Object.hash(loggedIn, subscriptionType, checkedAt);
}

/// Features exposed by a provider to shared application layers.
@immutable
final class ProviderCapabilities {
  const ProviderCapabilities({
    required this.sessionUsage,
    required this.weeklyUsage,
    required this.healthCheck,
    required this.customExecutable,
  });

  static const claude = ProviderCapabilities(
    sessionUsage: true,
    weeklyUsage: true,
    healthCheck: true,
    customExecutable: true,
  );

  static const copilotPlaceholder = ProviderCapabilities(
    sessionUsage: false,
    weeklyUsage: false,
    healthCheck: false,
    customExecutable: false,
  );

  /// GitHub Copilot account quota exposed through the bundled SDK sidecar.
  static const copilot = ProviderCapabilities(
    sessionUsage: true,
    weeklyUsage: false,
    healthCheck: true,
    customExecutable: false,
  );

  final bool sessionUsage;
  final bool weeklyUsage;
  final bool healthCheck;
  final bool customExecutable;

  @override
  bool operator ==(Object other) {
    return other is ProviderCapabilities &&
        other.sessionUsage == sessionUsage &&
        other.weeklyUsage == weeklyUsage &&
        other.healthCheck == healthCheck &&
        other.customExecutable == customExecutable;
  }

  @override
  int get hashCode => Object.hash(
    sessionUsage,
    weeklyUsage,
    healthCheck,
    customExecutable,
  );
}

/// Provider parser output before shared validation and persistence.
@immutable
final class ProviderUsageCandidate {
  const ProviderUsageCandidate({
    required this.parserState,
    required this.rawText,
    this.sessionUsedPercent,
    this.sessionResetsAtRaw,
    this.weekly = const [],
    this.metrics = const [],
  });

  final ParserState parserState;
  final String rawText;
  final double? sessionUsedPercent;
  final String? sessionResetsAtRaw;
  final List<WeeklyUsage> weekly;
  final List<ProviderUsageMetric> metrics;
}

/// Provider-neutral runtime configuration.
@immutable
final class ProviderExecutionConfig {
  const ProviderExecutionConfig({this.executablePath});

  final String? executablePath;
}

/// Provider-neutral health projection.
@immutable
final class ProviderHealth {
  const ProviderHealth({
    required this.healthy,
    required this.authenticated,
    required this.message,
    required this.checkedAt,
  });

  final bool healthy;
  final bool authenticated;
  final String message;
  final DateTime checkedAt;
}

/// Provider-neutral quota or rate-limit metric.
@immutable
final class ProviderUsageMetric {
  factory ProviderUsageMetric({
    required String key,
    required String label,
    required double usedPercent,
    required bool primary,
    DateTime? resetsAt,
    String? resetsAtRaw,
    num? value,
    num? total,
    String? unit,
    double? remainingPercent,
    bool unlimited = false,
  }) {
    if (!usedPercent.isFinite || usedPercent < 0 || usedPercent > 100) {
      throw ArgumentError.value(usedPercent, 'usedPercent');
    }
    if (remainingPercent != null &&
        (!remainingPercent.isFinite ||
            remainingPercent < 0 ||
            remainingPercent > 100)) {
      throw ArgumentError.value(remainingPercent, 'remainingPercent');
    }
    if (value != null && value < 0) {
      throw ArgumentError.value(value, 'value');
    }
    if (total != null && total < 0) {
      throw ArgumentError.value(total, 'total');
    }
    return ProviderUsageMetric._(
      key: key.trim(),
      label: label.trim(),
      usedPercent: usedPercent,
      primary: primary,
      resetsAt: resetsAt,
      resetsAtRaw: resetsAtRaw,
      value: value,
      total: total,
      unit: unit?.trim(),
      remainingPercent: remainingPercent,
      unlimited: unlimited,
    );
  }

  const ProviderUsageMetric._({
    required this.key,
    required this.label,
    required this.usedPercent,
    required this.primary,
    required this.resetsAt,
    required this.resetsAtRaw,
    required this.value,
    required this.total,
    required this.unit,
    required this.remainingPercent,
    required this.unlimited,
  });

  final String key;
  final String label;
  final double usedPercent;
  final bool primary;
  final DateTime? resetsAt;
  final String? resetsAtRaw;
  final num? value;
  final num? total;
  final String? unit;
  final double? remainingPercent;
  final bool unlimited;

  num? get remaining {
    if (unlimited || value == null || total == null) return null;
    return (total! - value!).clamp(0, total!);
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderUsageMetric &&
        other.key == key &&
        other.label == label &&
        other.usedPercent == usedPercent &&
        other.primary == primary &&
        other.resetsAt == resetsAt &&
        other.resetsAtRaw == resetsAtRaw &&
        other.value == value &&
        other.total == total &&
        other.unit == unit &&
        other.remainingPercent == remainingPercent &&
        other.unlimited == unlimited;
  }

  @override
  int get hashCode => Object.hash(
    key,
    label,
    usedPercent,
    primary,
    resetsAt,
    resetsAtRaw,
    value,
    total,
    unit,
    remainingPercent,
    unlimited,
  );
}

/// Shared provider refresh status.
enum ProviderStatusKind { idle, refreshing, live, cached, error }

/// Immutable provider status projected from the refresh pipeline.
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
}
