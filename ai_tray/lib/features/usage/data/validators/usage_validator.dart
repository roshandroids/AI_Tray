import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/models/provider_usage_candidate.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';

/// Validates parsed usage candidates into domain [UsageInfo] or failures.
final class UsageValidator {
  Result<UsageInfo> validate(
    ProviderUsageCandidate candidate, {
    required DateTime fetchedAt,
    bool isFromCache = false,
    ProviderId providerId = ProviderId.claude,
  }) {
    final state = candidate.parserState;

    if (state.shape == UsageShape.contributionOnly ||
        state.validation == ValidationStatus.incomplete) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.incompleteOutput,
          message: 'Usage limits temporarily unavailable',
        ),
      );
    }

    if (state.shape == UsageShape.unknown ||
        state.validation == ValidationStatus.invalid) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unknownCliOutput,
          message: "Couldn't read provider usage format",
        ),
      );
    }

    final primaryMetric = candidate.metrics.isEmpty
        ? null
        : candidate.metrics.firstWhere(
            (metric) => metric.primary,
            orElse: () => candidate.metrics.first,
          );
    final percent = candidate.sessionUsedPercent ?? primaryMetric?.usedPercent;
    if (percent == null || percent.isNaN || percent < 0 || percent > 100) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.parserFailure,
          message: 'Session usage percentage was missing',
        ),
      );
    }

    return Result.success(
      UsageInfo(
        sessionUsedPercent: percent,
        sessionResetsAt: primaryMetric?.resetsAt,
        sessionResetsAtRaw:
            candidate.sessionResetsAtRaw ?? primaryMetric?.resetsAtRaw,
        weekly: candidate.weekly,
        metrics: candidate.metrics,
        fetchedAt: fetchedAt,
        source: UsageSource.cli,
        isFromCache: isFromCache,
        providerId: providerId,
      ),
    );
  }
}
