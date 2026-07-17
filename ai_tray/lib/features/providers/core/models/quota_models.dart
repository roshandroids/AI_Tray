import 'package:meta/meta.dart';

/// Reset instant associated with a bounded quota.
@immutable
final class QuotaReset {
  const QuotaReset({required this.at});

  final DateTime at;
}

/// Shared immutable fields for one Copilot quota category.
@immutable
sealed class CopilotQuota {
  const CopilotQuota({
    required this.available,
    required this.entitlementRequests,
    required this.usedRequests,
    required this.remainingPercentage,
    required this.overage,
    required this.overageAllowedWithExhaustedQuota,
    required this.reset,
  });

  final bool available;
  final int? entitlementRequests;
  final int? usedRequests;
  final double? remainingPercentage;
  final int? overage;
  final bool? overageAllowedWithExhaustedQuota;
  final QuotaReset? reset;

  bool get isUnlimited {
    return available &&
        entitlementRequests == 0 &&
        (overageAllowedWithExhaustedQuota ?? false);
  }
}

/// Premium-interaction quota.
final class PremiumQuota extends CopilotQuota {
  const PremiumQuota({
    required super.available,
    required super.entitlementRequests,
    required super.usedRequests,
    required super.remainingPercentage,
    required super.overage,
    required super.overageAllowedWithExhaustedQuota,
    required super.reset,
  });
}

/// Chat quota.
final class ChatQuota extends CopilotQuota {
  const ChatQuota({
    required super.available,
    required super.entitlementRequests,
    required super.usedRequests,
    required super.remainingPercentage,
    required super.overage,
    required super.overageAllowedWithExhaustedQuota,
    required super.reset,
  });
}

/// Completion quota.
final class CompletionQuota extends CopilotQuota {
  const CompletionQuota({
    required super.available,
    required super.entitlementRequests,
    required super.usedRequests,
    required super.remainingPercentage,
    required super.overage,
    required super.overageAllowedWithExhaustedQuota,
    required super.reset,
  });
}

/// Validated snapshot of all Copilot quota categories.
@immutable
final class QuotaSnapshot {
  const QuotaSnapshot({
    required this.premium,
    required this.chat,
    required this.completion,
  });

  final PremiumQuota premium;
  final ChatQuota chat;
  final CompletionQuota completion;
}

/// Usage metrics for one Copilot SDK session.
@immutable
final class SessionUsage {
  const SessionUsage({
    required this.sessionId,
    required this.totalPremiumRequestCost,
    required this.totalUserRequests,
    required this.totalApiDuration,
    required this.sessionStartedAt,
    required this.lastCallInputTokens,
    required this.lastCallOutputTokens,
    this.currentModel,
  });

  final String sessionId;
  final double totalPremiumRequestCost;
  final int totalUserRequests;
  final Duration totalApiDuration;
  final DateTime sessionStartedAt;
  final String? currentModel;
  final int lastCallInputTokens;
  final int lastCallOutputTokens;
}

/// Bridge, protocol, SDK, and CLI compatibility versions.
@immutable
final class VersionInfo {
  const VersionInfo({
    required this.protocolVersion,
    required this.bridgeVersion,
    required this.sdkVersion,
    this.cliVersion,
  });

  final int protocolVersion;
  final String bridgeVersion;
  final String sdkVersion;
  final String? cliVersion;
}
