import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/copilot/copilot_provider.dart';
import 'package:ai_tray/features/providers/domain/models/auth_health.dart';
import 'package:ai_tray/features/providers/domain/models/provider_capabilities.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/models/provider_status.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderRegistry', () {
    test('exposes enabled providers and keeps Copilot disabled', () {
      const claude = _FakeProvider(
        id: ProviderId.claude,
        enabled: true,
        capabilities: ProviderCapabilities.claude,
      );
      final registry = ProviderRegistry(
        providers: [claude, const CopilotProvider()],
        defaultProviderId: ProviderId.claude,
      );

      expect(registry.defaultProvider, same(claude));
      expect(
        registry.enabledProviders.map((provider) => provider.providerId),
        [ProviderId.claude],
      );
      expect(registry.find(ProviderId.copilot), isA<CopilotProvider>());
      expect(
        () => registry.requireEnabled(ProviderId.copilot),
        throwsStateError,
      );
    });

    test('rejects duplicate identifiers', () {
      const first = _FakeProvider(
        id: ProviderId.claude,
        enabled: true,
        capabilities: ProviderCapabilities.claude,
      );
      const duplicate = _FakeProvider(
        id: ProviderId.claude,
        enabled: true,
        capabilities: ProviderCapabilities.claude,
      );

      expect(
        () => ProviderRegistry(
          providers: [first, duplicate],
          defaultProviderId: ProviderId.claude,
        ),
        throwsArgumentError,
      );
    });
  });

  test('selection notifier rejects disabled providers', () {
    final registry = ProviderRegistry(
      providers: [
        const _FakeProvider(
          id: ProviderId.claude,
          enabled: true,
          capabilities: ProviderCapabilities.claude,
        ),
        const CopilotProvider(),
      ],
      defaultProviderId: ProviderId.claude,
    );
    final container = ProviderContainer(
      overrides: [providerRegistryProvider.overrideWithValue(registry)],
    );
    addTearDown(container.dispose);

    expect(container.read(selectedProviderIdProvider), ProviderId.claude);
    expect(
      () => container
          .read(selectedProviderIdProvider.notifier)
          .select(ProviderId.copilot),
      throwsStateError,
    );
    expect(container.read(selectedProviderIdProvider), ProviderId.claude);
  });

  test('dashboard metrics are derived only from capabilities', () {
    final provider = _FakeProvider(
      id: ProviderId('custom'),
      enabled: true,
      capabilities: const ProviderCapabilities(
        sessionUsage: false,
        weeklyUsage: true,
        healthCheck: false,
        customExecutable: false,
      ),
    );
    final usage = UsageInfo(
      sessionUsedPercent: 42,
      weekly: [
        WeeklyUsage(label: 'All models', usedPercent: 12),
      ],
      fetchedAt: DateTime.utc(2026, 7, 16),
      source: UsageSource.cli,
      isFromCache: false,
      providerId: provider.providerId,
    );
    final status = RefreshStatus(
      phase: RefreshPhase.idle,
      lastResult: RefreshResult(
        status: RefreshOutcome.success,
        usage: usage,
        parserState: ParserState.empty(),
        duration: Duration.zero,
      ),
      lastSuccessAt: usage.fetchedAt,
    );

    final dashboard = DashboardDataMapper.map(
      provider: provider,
      usage: usage,
      refreshStatus: status,
    );

    expect(dashboard.metrics, hasLength(1));
    expect(dashboard.metrics.single.kind, DashboardMetricKind.weeklyUsage);
    expect(dashboard.metrics.single.label, 'All models');
    expect(dashboard.status.kind, ProviderStatusKind.live);
    expect(dashboard.status.sourceLabel, 'Custom CLI');
  });

  test('refresh resolves the selected provider for each request', () async {
    var selected = const _UsageProvider(
      id: ProviderId.claude,
      percent: 18,
    );
    final service = RefreshService(
      provider: selected,
      providerResolver: () => selected,
      validator: UsageValidator(),
      cache: InMemoryUsageCache(),
      logger: ConsoleAppLogger(defaultName: 'test'),
      softRetryDelay: Duration.zero,
      hardRetryDelay: Duration.zero,
    );

    final claudeResult = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );
    expect(claudeResult.usage?.providerId, ProviderId.claude);
    expect(claudeResult.usage?.sessionUsedPercent, 18);

    selected = const _UsageProvider(
      id: ProviderId.copilot,
      percent: 33,
    );
    final copilotResult = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );
    expect(copilotResult.usage?.providerId, ProviderId.copilot);
    expect(copilotResult.usage?.sessionUsedPercent, 33);
  });

  test('Copilot scaffold performs no usage or health work', () async {
    const provider = CopilotProvider();

    expect(provider.enabled, isFalse);
    expect(provider.capabilities.sessionUsage, isFalse);
    expect(
      (await provider.fetchUsageRaw()).failureOrNull?.code,
      FailureCode.unknown,
    );
    expect(
      (await provider.healthCheck()).failureOrNull?.code,
      FailureCode.unknown,
    );
    expect(
      provider.parser.parse(rawText: 'not implemented').parserState.messages,
      contains('copilot_parser_not_implemented'),
    );
  });
}

final class _FakeProvider implements AIProvider {
  const _FakeProvider({
    required ProviderId id,
    required this.enabled,
    required this.capabilities,
  }) : _id = id;

  final ProviderId _id;

  @override
  final bool enabled;

  @override
  final ProviderCapabilities capabilities;

  @override
  ProviderId get providerId => _id;

  @override
  String get displayName => 'Custom';

  @override
  String get sourceLabel => 'Custom CLI';

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Limits unavailable.';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({String? binaryPath}) async {
    return const Result.failure(
      AppFailure(
        code: FailureCode.unknown,
        message: 'Not used by this test',
      ),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({String? binaryPath}) async {
    return const Result.failure(
      AppFailure(
        code: FailureCode.unknown,
        message: 'Not used by this test',
      ),
    );
  }
}

final class _UsageProvider implements AIProvider {
  const _UsageProvider({required ProviderId id, required this.percent})
    : _id = id;

  final ProviderId _id;
  final double percent;

  @override
  ProviderId get providerId => _id;

  @override
  String get displayName => _id.value;

  @override
  String get sourceLabel => '${_id.value} CLI';

  @override
  bool get enabled => true;

  @override
  ProviderCapabilities get capabilities => ProviderCapabilities.claude;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Limits unavailable.';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({String? binaryPath}) async {
    return Result.success(
      UsageRawFetch(
        stdout: 'Current session: $percent% used · resets tomorrow',
        stderr: '',
        exitCode: 0,
        duration: Duration.zero,
      ),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({String? binaryPath}) async {
    return Result.success(
      AuthHealth(loggedIn: true, checkedAt: DateTime.utc(2026, 7, 16)),
    );
  }
}
