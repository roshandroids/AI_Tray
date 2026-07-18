import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/providers/presentation/provider_selection_controller.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:ai_tray/features/providers/presentation/provider_selection_controller.dart'
    show
        selectableAIProvidersProvider,
        selectedAIProviderProvider,
        selectedProviderIdProvider;
export 'package:ai_tray/features/providers/provider_providers.dart'
    show processRunnerProvider, providerRegistryProvider;
export 'package:ai_tray/features/settings/settings_providers.dart'
    show settingsRepositoryProvider, sharedPreferencesProvider;

/// Compatibility alias retained for existing provider-port consumers.
final aiProviderPortProvider = Provider<AiProviderPort>((ref) {
  return ref.watch(selectedAIProviderProvider);
});

/// Parser resolved from the active provider registration.
final usageParserProvider = Provider<ProviderUsageParser>((ref) {
  return ref.watch(selectedAIProviderProvider).parser;
});

final usageValidatorProvider = Provider<UsageValidator>(
  (ref) => UsageValidator(),
);

final usageCacheProvider = Provider<UsageCache>((ref) {
  return SharedPreferencesUsageCache(ref.watch(sharedPreferencesProvider));
});

final refreshServiceProvider = Provider<RefreshService>((ref) {
  return RefreshService(
    provider: ref.read(selectedAIProviderProvider),
    providerResolver: () => ref.read(selectedAIProviderProvider),
    validator: ref.watch(usageValidatorProvider),
    cache: ref.watch(usageCacheProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  final repository = UsageRepositoryImpl(
    refreshService: ref.watch(refreshServiceProvider),
    cache: ref.watch(usageCacheProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    logger: ref.watch(appLoggerProvider),
    providerResolver: () => ref.read(selectedAIProviderProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Convenience logger accessor for feature code.
AppLogger readLogger(Ref ref) => ref.watch(appLoggerProvider);
