import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/dashboard_data.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:ai_tray/features/usage/domain/services/dashboard_data_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps provider metrics without a provider-specific layout', () {
    final fetchedAt = DateTime.utc(2026, 7, 17);
    final usage = UsageInfo(
      sessionUsedPercent: 25,
      metrics: [
        ProviderUsageMetric(
          key: 'premium',
          label: 'Premium requests',
          usedPercent: 25,
          primary: true,
          value: 25,
          total: 100,
          unit: 'requests',
          remainingPercent: 75,
        ),
        ProviderUsageMetric(
          key: 'chat',
          label: 'Chat quota',
          usedPercent: 0,
          primary: false,
          unlimited: true,
        ),
      ],
      fetchedAt: fetchedAt,
      source: UsageSource.oauth,
      isFromCache: false,
      providerId: ProviderId.copilot,
    );
    final status = RefreshStatus(
      phase: RefreshPhase.refreshing,
      lastResult: RefreshResult(
        status: RefreshOutcome.success,
        usage: usage,
        parserState: ParserState.empty(),
        duration: Duration.zero,
        providerId: ProviderId.copilot,
      ),
      lastSuccessAt: fetchedAt,
    );

    final dashboard = DashboardDataMapper.map(
      provider: const _FakeProvider(ProviderId.copilot),
      usage: usage,
      refreshStatus: status,
    );

    expect(dashboard.metrics, hasLength(2));
    expect(dashboard.metrics.first.kind, DashboardMetricKind.absoluteUsage);
    expect(dashboard.metrics.first.remaining, 75);
    expect(dashboard.metrics.last.unlimited, isTrue);
    expect(dashboard.status.isRefreshing, isTrue);
    expect(dashboard.status.updatedAt, fetchedAt);
  });

  test('projects Claude session and weekly metrics for shared cards', () {
    final usage = UsageInfo(
      sessionUsedPercent: 12,
      sessionResetsAtRaw: 'tonight',
      weekly: [
        WeeklyUsage(label: 'all models', usedPercent: 4, resetsAtRaw: 'Sunday'),
      ],
      fetchedAt: DateTime.utc(2026, 7, 17),
      source: UsageSource.cli,
      isFromCache: false,
      providerId: ProviderId.claude,
    );

    final dashboard = DashboardDataMapper.map(
      provider: const _FakeProvider(ProviderId.claude),
      usage: usage,
      refreshStatus: RefreshStatus.initial(),
    );

    expect(dashboard.metrics, hasLength(2));
    expect(dashboard.metrics.first.key, 'session');
    expect(dashboard.metrics.first.kind, DashboardMetricKind.sessionUsage);
    expect(dashboard.metrics.first.label, 'Session');
    expect(dashboard.metrics.last.kind, DashboardMetricKind.weeklyUsage);
    expect(dashboard.metrics.last.label, 'all models');
    expect(dashboard.metrics.last.resetsAtRaw, 'Sunday');
  });

  test('maps soft-failure with cached usage to cached status', () {
    final usage = UsageInfo(
      sessionUsedPercent: 30,
      fetchedAt: DateTime.utc(2026, 7, 17),
      source: UsageSource.cli,
      isFromCache: true,
      providerId: ProviderId.claude,
    );
    final status = RefreshStatus(
      phase: RefreshPhase.idle,
      lastResult: RefreshResult(
        status: RefreshOutcome.softFailure,
        usage: usage,
        parserState: ParserState.empty(),
        duration: Duration.zero,
        error: const AppFailure(
          code: FailureCode.incompleteOutput,
          message: 'Limits unavailable',
        ),
        providerId: ProviderId.claude,
      ),
      lastSuccessAt: usage.fetchedAt,
    );

    final dashboard = DashboardDataMapper.map(
      provider: const _FakeProvider(ProviderId.claude),
      usage: usage,
      refreshStatus: status,
    );

    expect(dashboard.status.kind, ProviderStatusKind.cached);
    expect(dashboard.status.sourceLabel, 'Cache (LKG)');
    expect(dashboard.status.failureMessage, 'Limits unavailable');
  });
}

final class _FakeProvider implements AIProvider {
  const _FakeProvider(this.providerId);

  @override
  final ProviderId providerId;

  @override
  ProviderCapabilities get capabilities => providerId == ProviderId.claude
      ? ProviderCapabilities.claude
      : ProviderCapabilities.copilot;

  @override
  String get displayName =>
      providerId == ProviderId.claude ? 'Claude' : 'GitHub Copilot';

  @override
  bool get enabled => true;

  @override
  String get limitsUnavailableMessage => 'Quota is temporarily unavailable.';

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get sourceLabel => '${providerId.value} source';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'Not used'),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'Not used'),
    );
  }
}
