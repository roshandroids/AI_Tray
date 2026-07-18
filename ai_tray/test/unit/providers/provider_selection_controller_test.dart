import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/providers/presentation/provider_selection_controller.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('selection persists across provider container restart', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSettingsRepository(preferences);
    final first = _container(repository);

    await first.read(selectedProviderIdProvider.future);
    final changed = await first
        .read(selectedProviderIdProvider.notifier)
        .select(ProviderId.copilot);

    expect(changed, isTrue);
    expect((await repository.read()).selectedProviderId, ProviderId.copilot);
    first.dispose();

    final restarted = _container(
      SharedPreferencesSettingsRepository(preferences),
    );
    addTearDown(restarted.dispose);

    expect(
      await restarted.read(selectedProviderIdProvider.future),
      ProviderId.copilot,
    );
    expect(
      restarted.read(selectedAIProviderProvider).providerId,
      ProviderId.copilot,
    );
  });

  test('disabled or unavailable saved providers fall back to Claude', () async {
    for (final settings in [
      AppSettings.defaults().copyWith(
        selectedProviderId: ProviderId.copilot,
        copilotEnabled: false,
      ),
      AppSettings.defaults().copyWith(
        selectedProviderId: ProviderId('unavailable'),
      ),
    ]) {
      final repository = InMemorySettingsRepository(settings);
      final container = _container(repository);

      expect(
        await container.read(selectedProviderIdProvider.future),
        ProviderId.claude,
      );
      expect(
        (await repository.read()).selectedProviderId,
        ProviderId.claude,
      );
      expect(
        container
            .read(selectableAIProvidersProvider)
            .map((provider) => provider.providerId),
        settings.copilotEnabled
            ? [ProviderId.claude, ProviderId.copilot]
            : [ProviderId.claude],
      );
      container.dispose();
    }
  });

  test('failed selection persistence is exposed and recoverable', () async {
    final repository = _RecoverableSettingsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(selectedProviderIdProvider.future);

    repository.failWrites = true;
    final changed = await container
        .read(selectedProviderIdProvider.notifier)
        .select(ProviderId.copilot);
    final notifier = container.read(selectedProviderIdProvider.notifier);

    expect(changed, isTrue);
    expect(notifier.effectiveProviderId, ProviderId.copilot);
    expect(notifier.lastPersistenceFailure, isNotNull);
    expect(container.read(selectedProviderIdProvider).hasError, isTrue);

    repository.failWrites = false;
    expect(await notifier.retryPersistence(), isTrue);
    expect(
      container.read(selectedProviderIdProvider),
      isA<AsyncData<ProviderId>>(),
    );
    expect(
      container.read(selectedProviderIdProvider).value,
      ProviderId.copilot,
    );
    expect((await repository.read()).selectedProviderId, ProviderId.copilot);
  });

  test('Claude remains the enabled default with existing settings', () async {
    final repository = InMemorySettingsRepository(AppSettings.defaults());
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(selectedProviderIdProvider.future),
      ProviderId.claude,
    );
    expect(
      container.read(selectedAIProviderProvider).providerId,
      ProviderId.claude,
    );
    expect(
      (await repository.read()).copilotEnabled,
      isTrue,
    );
  });
}

ProviderContainer _container(SettingsRepository repository) {
  return ProviderContainer(
    overrides: [
      providerRegistryProvider.overrideWithValue(_registry()),
      settingsRepositoryProvider.overrideWithValue(repository),
    ],
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

final class _RecoverableSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings.defaults();
  bool failWrites = false;

  @override
  Future<AppSettings> read() async => _settings;

  @override
  Future<Result<Unit>> write(AppSettings settings) async {
    if (failWrites) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: 'Settings unavailable',
        ),
      );
    }
    _settings = settings;
    return const Result.success(Unit.unit);
  }
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
      AppFailure(
        code: FailureCode.unknown,
        message: 'Not used',
      ),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(
        code: FailureCode.unknown,
        message: 'Not used',
      ),
    );
  }
}
