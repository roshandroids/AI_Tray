import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
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
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'selection hides stale usage immediately and refreshes exactly once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final settings = _GatedSettingsRepository();
      final usage = _CountingUsageRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerRegistryProvider.overrideWithValue(_registry()),
            settingsRepositoryProvider.overrideWithValue(settings),
            usageRepositoryProvider.overrideWithValue(usage),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const UsagePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('session')), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<ProviderId>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GitHub Copilot').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('session')), findsNothing);
      expect(usage.refreshCount, 0);

      settings.releaseWrite();
      await tester.pumpAndSettle();

      expect(usage.refreshCount, 1);
    },
  );
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

final class _GatedSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings.defaults();
  Completer<void>? _writeGate;

  @override
  Future<AppSettings> read() async => _settings;

  @override
  Future<Result<Unit>> write(AppSettings settings) async {
    final gate = _writeGate ??= Completer<void>();
    await gate.future;
    _settings = settings;
    return const Result.success(Unit.unit);
  }

  void releaseWrite() {
    _writeGate?.complete();
  }
}

final class _CountingUsageRepository implements UsageRepository {
  _CountingUsageRepository()
    : _status = RefreshStatus(
        phase: RefreshPhase.idle,
        lastResult: RefreshResult(
          status: RefreshOutcome.success,
          usage: UsageInfo(
            sessionUsedPercent: 20,
            fetchedAt: DateTime.utc(2026, 7, 17),
            source: UsageSource.cli,
            isFromCache: false,
            providerId: ProviderId.claude,
          ),
          parserState: ParserState.empty(),
          duration: Duration.zero,
          providerId: ProviderId.claude,
        ),
      );

  final RefreshStatus _status;
  int refreshCount = 0;

  @override
  RefreshStatus get status => _status;

  @override
  Future<Result<UsageInfo?>> getCachedUsage() async {
    return Result.success(_status.lastResult?.usage);
  }

  @override
  Future<AppSettings> getSettings() async => AppSettings.defaults();

  @override
  Future<RefreshResult> refresh({bool manual = false}) async {
    refreshCount++;
    return RefreshResult(
      status: RefreshOutcome.success,
      usage: UsageInfo(
        sessionUsedPercent: 40,
        fetchedAt: DateTime.utc(2026, 7, 17),
        source: UsageSource.oauth,
        isFromCache: false,
        providerId: ProviderId.copilot,
      ),
      parserState: ParserState.empty(),
      duration: Duration.zero,
      providerId: ProviderId.copilot,
    );
  }

  @override
  Future<Result<Unit>> updateSettings(AppSettings settings) async {
    return const Result.success(Unit.unit);
  }

  @override
  Stream<RefreshStatus> watchStatus() => const Stream.empty();
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
