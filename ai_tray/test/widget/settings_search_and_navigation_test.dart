import 'package:ai_tray/core/components/settings_chrome.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/copilot/diagnostics/copilot_diagnostics.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(),
        ),
        applyLaunchAtLoginProvider.overrideWithValue((_) async {}),
        providerRegistryProvider.overrideWithValue(
          ProviderRegistry(
            providers: const [_FakeProvider(ProviderId.claude)],
            defaultProviderId: ProviderId.claude,
          ),
        ),
        usageRepositoryProvider.overrideWithValue(_FakeUsageRepository()),
        bufferedAppLoggerProvider.overrideWithValue(BufferedAppLogger()),
        copilotDiagnosticsServiceProvider.overrideWithValue(
          CopilotDiagnosticsService(
            sdk: _NoOpCopilotSdk(),
            logger: BufferedAppLogger(),
            clock: () => DateTime.utc(2026),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const SettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every rail section renders in place, no navigation surprise', (
    tester,
  ) async {
    await _pumpSettings(tester);

    Finder railItem(String label) => find.descendant(
      of: find.byType(SettingsNavRail),
      matching: find.text(label),
    );

    for (final label in [
      'Appearance',
      'Refresh',
      'Notifications',
      'App Behavior',
      'CLI',
      'Advanced',
    ]) {
      await tester.tap(railItem(label));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    }
  });

  testWidgets('global settings search narrows the rail by keyword', (
    tester,
  ) async {
    await _pumpSettings(tester);

    Finder railItem(String label) => find.descendant(
      of: find.byType(SettingsNavRail),
      matching: find.text(label),
    );

    expect(railItem('Refresh'), findsOneWidget);
    expect(railItem('CLI'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('settings-search-field')),
      'launch at login',
    );
    await tester.pumpAndSettle();

    expect(railItem('App Behavior'), findsOneWidget);
    expect(railItem('CLI'), findsNothing);
    expect(railItem('Appearance'), findsNothing);
  });

  testWidgets('a search with no matches shows an empty state, not a crash', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await tester.enterText(
      find.byKey(const ValueKey('settings-search-field')),
      'nonexistent setting',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching settings.'), findsOneWidget);
  });

  testWidgets('About AI Tray in Advanced opens the About page', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(SettingsNavRail),
        matching: find.text('Advanced'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('About AI Tray'));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsWidgets);
    expect(find.text('AI Tray'), findsOneWidget);
  });
}

final class _NoOpCopilotSdk implements CopilotSdk {
  @override
  Future<void> initialize() async {}

  @override
  Future<QuotaSnapshot> getQuota({
    CopilotSdkCancellationToken? cancellationToken,
  }) async => _quota;

  @override
  Future<ProviderHealth> getHealth({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    return ProviderHealth(
      healthy: true,
      authenticated: true,
      message: 'ready',
      checkedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<VersionInfo> getVersion({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    return const VersionInfo(
      protocolVersion: 1,
      bridgeVersion: '1.0.0',
      sdkVersion: '1.0.7',
    );
  }

  @override
  Future<SessionUsage> getSessionUsage(
    String sessionId, {
    CopilotSdkCancellationToken? cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> shutdown() async {}
}

const _quota = QuotaSnapshot(
  premium: PremiumQuota(
    available: true,
    entitlementRequests: 300,
    usedRequests: 30,
    remainingPercentage: 90,
    overage: 0,
    overageAllowedWithExhaustedQuota: false,
    reset: null,
  ),
  chat: ChatQuota(
    available: false,
    entitlementRequests: null,
    usedRequests: null,
    remainingPercentage: null,
    overage: null,
    overageAllowedWithExhaustedQuota: null,
    reset: null,
  ),
  completion: CompletionQuota(
    available: false,
    entitlementRequests: null,
    usedRequests: null,
    remainingPercentage: null,
    overage: null,
    overageAllowedWithExhaustedQuota: null,
    reset: null,
  ),
);

final class _FakeUsageRepository implements UsageRepository {
  @override
  RefreshStatus get status => RefreshStatus.initial();

  @override
  Future<Result<UsageInfo?>> getCachedUsage() async =>
      const Result.success(null);

  @override
  Future<AppSettings> getSettings() async => AppSettings.defaults();

  @override
  Future<RefreshResult> refresh({bool manual = false}) async {
    return RefreshResult(
      status: RefreshOutcome.success,
      usage: null,
      parserState: ParserState.empty(),
      duration: Duration.zero,
      providerId: ProviderId.claude,
    );
  }

  @override
  Future<Result<Unit>> updateSettings(AppSettings settings) async =>
      const Result.success(Unit.unit);

  @override
  Stream<RefreshStatus> watchStatus() =>
      Stream.value(RefreshStatus(phase: RefreshPhase.idle));
}

final class _FakeProvider implements AIProvider {
  const _FakeProvider(this.providerId);

  @override
  final ProviderId providerId;

  @override
  String get displayName => 'Claude';

  @override
  String get sourceLabel => 'claude test';

  @override
  bool get enabled => true;

  @override
  ProviderCapabilities get capabilities => ProviderCapabilities.claude;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Unavailable';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'unused'),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'unused'),
    );
  }
}
