import 'package:ai_tray/core/components/metric_card.dart';
import 'package:ai_tray/core/components/progress_ring.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart'
    show UsageRawFetch;
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/providers/presentation/widgets/provider_selector.dart';
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
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:ai_tray/features/usage/presentation/usage_page.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Claude success dashboard renders session and week cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerRegistryProvider.overrideWithValue(_registry()),
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(AppSettings.defaults()),
          ),
          usageRepositoryProvider.overrideWithValue(
            _StaticUsageRepository.claudeSuccess(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const UsagePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Claude'), findsWidgets);
    expect(find.text('EXPERIMENTAL'), findsNothing);
    expect(find.text('SESSION'), findsOneWidget);
    expect(find.text('WEEK'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Claude provider')), findsOneWidget);
  });

  testWidgets('Copilot success dashboard renders rich absolute metrics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          usageRepositoryProvider.overrideWithValue(
            _StaticUsageRepository.copilotSuccess(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const UsagePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GitHub Copilot'), findsWidgets);
    expect(find.text('EXPERIMENTAL'), findsOneWidget);
    expect(find.text('PREMIUM REQUESTS'), findsOneWidget);
    expect(find.text('34 / 300 requests used'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);
  });

  testWidgets('empty hard-failure state shows actionable guidance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          usageRepositoryProvider.overrideWithValue(
            _StaticUsageRepository.copilotHardFailure(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const UsagePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-empty-copilot')),
      findsOneWidget,
    );
    expect(find.text('Authentication expired'), findsOneWidget);
    expect(find.textContaining('not signed in'), findsOneWidget);
  });

  testWidgets('dashboard survives 150% text scale without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          usageRepositoryProvider.overrideWithValue(
            _StaticUsageRepository.copilotSuccess(),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const UsagePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PREMIUM REQUESTS'), findsOneWidget);
  });

  testWidgets('progress ring exposes unavailable semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: ProgressRing(percent: 0, available: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Usage unavailable'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('metric card exposes screen-reader label for percent usage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: MetricCard(
            label: 'Session',
            percent: 42,
            resetsAtRaw: 'tonight',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.byType(MetricCard));
    expect(semantics.label, contains('Session metric'));
    expect(semantics.label, contains('Usage 42 percent'));
  });

  testWidgets('provider selector dropdown items meet min touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: ProviderSelector(
            providers: const [
              _FakeProvider(ProviderId.claude),
              _FakeProvider(ProviderId.copilot),
            ],
            selectedId: ProviderId.claude,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<ProviderId>));
    await tester.pumpAndSettle();

    final item = tester.widget<DropdownMenuItem<ProviderId>>(
      find.widgetWithText(DropdownMenuItem<ProviderId>, 'GitHub Copilot'),
    );
    final size = tester.getSize(find.byWidget(item));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('reduced motion disables dashboard AnimatedSwitcher duration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerRegistryProvider.overrideWithValue(_registry()),
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(AppSettings.defaults()),
          ),
          usageRepositoryProvider.overrideWithValue(
            _StaticUsageRepository.claudeSuccess(),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const UsagePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
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

final class _StaticUsageRepository implements UsageRepository {
  _StaticUsageRepository(this._status);

  factory _StaticUsageRepository.claudeSuccess() {
    final usage = UsageInfo(
      sessionUsedPercent: 24,
      sessionResetsAtRaw: '10pm',
      weekly: const [],
      metrics: [
        ProviderUsageMetric(
          key: 'session',
          label: 'Session',
          usedPercent: 24,
          primary: true,
          resetsAtRaw: '10pm',
        ),
        ProviderUsageMetric(
          key: 'week',
          label: 'Week',
          usedPercent: 11,
          primary: false,
          resetsAtRaw: 'Sat 7am',
        ),
      ],
      fetchedAt: DateTime.utc(2026, 7, 18, 12),
      source: UsageSource.cli,
      isFromCache: false,
      providerId: ProviderId.claude,
    );
    return _StaticUsageRepository(
      RefreshStatus(
        phase: RefreshPhase.idle,
        lastResult: RefreshResult(
          status: RefreshOutcome.success,
          usage: usage,
          parserState: ParserState(
            shape: UsageShape.rateLimitsPresent,
            rateLimitsPresent: true,
            matchedSessionLine: true,
            matchedWeekLineCount: 1,
            validation: ValidationStatus.valid,
            rawTextLength: 120,
          ),
          duration: const Duration(milliseconds: 120),
          providerId: ProviderId.claude,
        ),
        lastSuccessAt: usage.fetchedAt,
      ),
    );
  }

  factory _StaticUsageRepository.copilotSuccess() {
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
          resetsAtRaw: 'Jul 25',
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
      fetchedAt: DateTime.utc(2026, 7, 18, 12),
      source: UsageSource.oauth,
      isFromCache: false,
      providerId: ProviderId.copilot,
    );
    return _StaticUsageRepository(
      RefreshStatus(
        phase: RefreshPhase.idle,
        lastResult: RefreshResult(
          status: RefreshOutcome.success,
          usage: usage,
          parserState: ParserState.empty(),
          duration: const Duration(milliseconds: 80),
          providerId: ProviderId.copilot,
        ),
        lastSuccessAt: usage.fetchedAt,
      ),
    );
  }

  factory _StaticUsageRepository.copilotHardFailure() {
    return _StaticUsageRepository(
      RefreshStatus(
        phase: RefreshPhase.idle,
        lastResult: RefreshResult(
          status: RefreshOutcome.failure,
          parserState: ParserState.empty(),
          duration: const Duration(milliseconds: 20),
          error: const AppFailure(
            code: FailureCode.notAuthenticated,
            message: 'GitHub Copilot is not authenticated',
          ),
          providerId: ProviderId.copilot,
        ),
      ),
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
