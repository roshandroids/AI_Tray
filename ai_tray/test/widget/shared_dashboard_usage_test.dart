import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart'
    show UsageRawFetch;
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:ai_tray/features/usage/presentation/usage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows provider header, rich cards, and preserves stale failure content',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final usage = _DashboardUsageRepository.copilotFailureWithCache();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerRegistryProvider.overrideWithValue(_registry()),
            settingsRepositoryProvider.overrideWithValue(
              InMemorySettingsRepository(
                AppSettings.defaults().copyWith(
                  selectedProviderId: ProviderId.copilot,
                ),
              ),
            ),
            usageRepositoryProvider.overrideWithValue(usage),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const UsagePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GitHub Copilot'), findsWidgets);
      expect(find.text('EXPERIMENTAL'), findsOneWidget);
      expect(find.textContaining('Last refreshed'), findsOneWidget);
      expect(find.text('PREMIUM REQUESTS'), findsOneWidget);
      expect(find.text('34 / 300 requests used'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);
      expect(
        find.textContaining(
          'Refresh failed. Showing the last available usage.',
        ),
        findsOneWidget,
      );
      // Surfaced both in the failure banner and the "Last error" health row.
      expect(find.textContaining('quota RPC timed out'), findsWidgets);
    },
  );

  testWidgets('shows skeleton while refreshing without cached usage', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final usage = _DashboardUsageRepository.refreshingEmpty();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerRegistryProvider.overrideWithValue(_registry()),
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(AppSettings.defaults()),
          ),
          usageRepositoryProvider.overrideWithValue(usage),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const UsagePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-skeleton-claude')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Loading usage metrics'),
      findsOneWidget,
    );
    expect(find.text('Updating metrics…'), findsOneWidget);
  });
}

ProviderRegistry _registry() {
  return ProviderRegistry(
    providers: const [
      _FakeProvider(ProviderId.claude),
      _FakeProvider(ProviderId.copilot),
    ],
    defaultProviderId: ProviderId.claude,
  );
}

final class _DashboardUsageRepository implements UsageRepository {
  _DashboardUsageRepository(this._status);

  factory _DashboardUsageRepository.copilotFailureWithCache() {
    final usage = UsageInfo(
      sessionUsedPercent: 11.3,
      metrics: [
        ProviderUsageMetric(
          key: 'premium',
          label: 'Premium requests',
          usedPercent: 11.3,
          primary: true,
          value: 34,
          total: 300,
          unit: 'requests',
          remainingPercent: 88.7,
        ),
        ProviderUsageMetric(
          key: 'chat',
          label: 'Chat quota',
          usedPercent: 0,
          primary: false,
          unlimited: true,
          unit: 'requests',
        ),
      ],
      fetchedAt: DateTime.utc(2026, 7, 16),
      source: UsageSource.oauth,
      isFromCache: true,
      providerId: ProviderId.copilot,
    );
    return _DashboardUsageRepository(
      RefreshStatus(
        phase: RefreshPhase.idle,
        lastResult: RefreshResult(
          status: RefreshOutcome.failure,
          usage: usage,
          parserState: ParserState.empty(),
          duration: const Duration(milliseconds: 40),
          error: const AppFailure(
            code: FailureCode.timeout,
            message: 'quota RPC timed out',
          ),
          providerId: ProviderId.copilot,
        ),
        lastSuccessAt: usage.fetchedAt,
      ),
    );
  }

  factory _DashboardUsageRepository.refreshingEmpty() {
    return _DashboardUsageRepository(
      RefreshStatus(phase: RefreshPhase.refreshing),
    );
  }

  final RefreshStatus _status;

  @override
  RefreshStatus get status => _status;

  @override
  Future<Result<UsageInfo?>> getCachedUsage() async {
    return Result.success(_status.lastResult?.usage);
  }

  @override
  Future<AppSettings> getSettings() async => AppSettings.defaults().copyWith(
    selectedProviderId: _status.lastResult?.providerId ?? ProviderId.claude,
  );

  @override
  Future<RefreshResult> refresh({bool manual = false}) async {
    return _status.lastResult ??
        RefreshResult(
          status: RefreshOutcome.failure,
          parserState: ParserState.empty(),
          duration: Duration.zero,
          error: const AppFailure(
            code: FailureCode.unknown,
            message: 'No result',
          ),
          providerId: ProviderId.claude,
        );
  }

  @override
  Future<Result<Unit>> updateSettings(AppSettings settings) async {
    return const Result.success(Unit.unit);
  }

  @override
  Stream<RefreshStatus> watchStatus() => Stream.value(_status);
}

final class _FakeProvider implements AIProvider {
  const _FakeProvider(this.providerId);

  @override
  final ProviderId providerId;

  @override
  String get displayName =>
      providerId == ProviderId.claude ? 'Claude' : 'GitHub Copilot';

  @override
  String get sourceLabel => '${providerId.value} test';

  @override
  bool get enabled => true;

  @override
  ProviderCapabilities get capabilities => providerId == ProviderId.claude
      ? ProviderCapabilities.claude
      : ProviderCapabilities.copilot;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Unavailable';

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
