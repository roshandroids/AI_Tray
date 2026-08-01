import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/settings/release_history_providers.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('About shows live version and What’s New from history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final packageInfo = PackageInfo(
      appName: 'AI Tray',
      packageName: 'ai_tray',
      version: '1.3.3',
      buildNumber: '9',
    );
    const history = ReleaseHistory(
      schemaVersion: 1,
      generatedFrom: 'CHANGELOG.md',
      releases: [
        ReleaseEntry(
          version: '1.3.3',
          date: '2026-07-17',
          notesMarkdown: '### Fixed\n- Optional session reset suffix.',
        ),
        ReleaseEntry(
          version: '1.3.2',
          date: '2026-07-17',
          notesMarkdown: '### Fixed\n- Sidecar payload pin.',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
          applyLaunchAtLoginProvider.overrideWithValue((_) async {}),
          providerRegistryProvider.overrideWithValue(_registry()),
          usageRepositoryProvider.overrideWithValue(_FakeUsageRepository()),
          bufferedAppLoggerProvider.overrideWithValue(BufferedAppLogger()),
          packageInfoProvider.overrideWith((ref) async => packageInfo),
          releaseHistoryProvider.overrideWith((ref) async => history),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('AI Tray 1.3.3'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('2026-07-17'), findsWidgets);
    expect(
      find.textContaining('Optional session reset suffix'),
      findsOneWidget,
    );
    expect(find.text('Previous releases'), findsOneWidget);
  });
}

ProviderRegistry _registry() {
  return ProviderRegistry(
    providers: const [
      _FakeProvider(ProviderId.claude),
    ],
    defaultProviderId: ProviderId.claude,
  );
}

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
  Stream<RefreshStatus> watchStatus() => Stream.value(
    RefreshStatus(phase: RefreshPhase.idle),
  );
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
