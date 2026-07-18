import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the provider selected by shared presentation.
///
/// Mutations:
/// - [select] updates state only for registered, user-enabled providers.
/// - Invalid selections fail before UI state can become inconsistent.
/// - Persistence failures retain the in-memory selection and can be retried.
final class ProviderSelectionNotifier extends AsyncNotifier<ProviderId> {
  AppSettings? _settings;
  AppSettings? _pendingSettings;
  AppFailure? _lastPersistenceFailure;
  ProviderId _effectiveProviderId = ProviderId.claude;
  Future<void> _writeQueue = Future<void>.value();
  int _revision = 0;

  /// Selection used by presentation even while persistence is in error.
  ProviderId get effectiveProviderId => _effectiveProviderId;

  /// Last recoverable settings persistence failure, if any.
  AppFailure? get lastPersistenceFailure => _lastPersistenceFailure;

  @override
  Future<ProviderId> build() async {
    final registry = ref.watch(providerRegistryProvider);
    final settings = await ref.watch(settingsRepositoryProvider).read();
    _settings = settings;

    final saved = registry.find(settings.selectedProviderId);
    if (saved != null && _isSelectable(saved, settings)) {
      _effectiveProviderId = saved.providerId;
      return saved.providerId;
    }

    final fallback = registry.enabledProviders.firstWhere(
      (provider) => _isSelectable(provider, settings),
      orElse: () => registry.defaultProvider,
    );
    _effectiveProviderId = fallback.providerId;
    if (settings.selectedProviderId != fallback.providerId) {
      final desired = settings.copyWith(
        selectedProviderId: fallback.providerId,
      );
      _settings = desired;
      _pendingSettings = desired;
      final result = await _enqueueWrite(desired);
      _recordPersistenceResult(
        result,
        providerId: fallback.providerId,
        updateState: false,
      );
      ref
          .read(appLoggerProvider)
          .warning(
            'provider fallback reason=disabled_or_unavailable '
            'from=${settings.selectedProviderId.value} '
            'to=${fallback.providerId.value}',
            name: 'provider_selection',
          );
    }
    return fallback.providerId;
  }

  /// Selects and persists a provider, returning whether selection changed.
  Future<bool> select(ProviderId providerId) async {
    final settings = _settings;
    if (settings == null) {
      throw StateError('Provider selection has not initialized');
    }
    final provider = ref
        .read(providerRegistryProvider)
        .requireEnabled(
          providerId,
        );
    if (!_isSelectable(provider, settings)) {
      throw StateError('Provider "${providerId.value}" is disabled');
    }
    if (_effectiveProviderId == provider.providerId) {
      if (_pendingSettings != null) {
        await retryPersistence();
      }
      return false;
    }

    final revision = ++_revision;
    _effectiveProviderId = provider.providerId;
    final desired = settings.copyWith(
      selectedProviderId: provider.providerId,
    );
    _settings = desired;
    _pendingSettings = desired;
    _lastPersistenceFailure = null;
    state = AsyncData(provider.providerId);

    final result = await _enqueueWrite(desired);
    if (revision != _revision) return false;
    _recordPersistenceResult(
      result,
      providerId: provider.providerId,
      updateState: true,
    );
    return true;
  }

  /// Retries the most recent failed selection persistence.
  Future<bool> retryPersistence() async {
    final pending = _pendingSettings;
    if (pending == null) return true;

    final revision = ++_revision;
    final result = await _enqueueWrite(pending);
    if (revision != _revision) return result.isSuccess;
    _recordPersistenceResult(
      result,
      providerId: _effectiveProviderId,
      updateState: true,
    );
    return result.isSuccess;
  }

  /// Whether a registered provider is currently selectable.
  bool isSelectable(AIProvider provider) {
    final settings = _settings;
    if (settings == null) {
      return provider.enabled && provider.providerId != ProviderId.copilot;
    }
    return _isSelectable(provider, settings);
  }

  bool _isSelectable(AIProvider provider, AppSettings settings) {
    if (!provider.enabled) return false;
    return provider.providerId != ProviderId.copilot || settings.copilotEnabled;
  }

  Future<Result<Unit>> _enqueueWrite(AppSettings settings) {
    late final Result<Unit> result;
    final write = _writeQueue.then((_) async {
      try {
        result = await ref.read(settingsRepositoryProvider).write(settings);
      } on Exception catch (error) {
        result = Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't save provider selection",
            detail: error.runtimeType.toString(),
          ),
        );
      }
    });
    _writeQueue = write;
    return write.then((_) => result);
  }

  void _recordPersistenceResult(
    Result<Unit> result, {
    required ProviderId providerId,
    required bool updateState,
  }) {
    final failure = result.failureOrNull;
    if (failure == null) {
      _pendingSettings = null;
      _lastPersistenceFailure = null;
      if (updateState) state = AsyncData(providerId);
      return;
    }

    _lastPersistenceFailure = failure;
    ref
        .read(appLoggerProvider)
        .warning(
          'provider selection persistence failed '
          'provider=${providerId.value}',
          name: 'provider_selection',
          error: failure,
        );
    if (updateState) {
      state = AsyncError<ProviderId>(failure, StackTrace.current);
    }
  }
}

/// Feature-scoped selected provider identifier.
final selectedProviderIdProvider =
    AsyncNotifierProvider<ProviderSelectionNotifier, ProviderId>(
      ProviderSelectionNotifier.new,
    );

/// Providers enabled by both registration and persisted user preference.
final selectableAIProvidersProvider = Provider<List<AIProvider>>((ref) {
  ref.watch(selectedProviderIdProvider);
  final registry = ref.watch(providerRegistryProvider);
  final notifier = ref.read(selectedProviderIdProvider.notifier);
  return List<AIProvider>.unmodifiable(
    registry.enabledProviders.where(notifier.isSelectable),
  );
});

/// Selected enabled provider metadata consumed by shared UI.
final selectedAIProviderProvider = Provider<AIProvider>((ref) {
  ref.watch(selectedProviderIdProvider);
  final registry = ref.watch(providerRegistryProvider);
  final notifier = ref.read(selectedProviderIdProvider.notifier);
  final selected = registry.find(notifier.effectiveProviderId);
  if (selected != null && notifier.isSelectable(selected)) return selected;
  return registry.defaultProvider;
});
