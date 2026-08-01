import 'dart:async';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/diagnostics/presentation/copilot_diagnostics_controller.dart';
import 'package:ai_tray/features/providers/presentation/provider_selection_controller.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Applies the OS login-item preference after settings are persisted.
final applyLaunchAtLoginProvider = Provider<Future<void> Function(AppSettings)>(
  (ref) {
    return (settings) =>
        ref.read(trayControllerProvider).applyLaunchAtLogin(settings);
  },
);

/// Re-applies tray menu / title after settings are persisted.
///
/// Overridable in tests so Linux CI does not construct a real tray controller.
final applyPresentationSettingsProvider = Provider<Future<void> Function()>(
  (ref) {
    return () => ref.read(trayControllerProvider).applyPresentationSettings();
  },
);

/// Owns loading, saving, failure recovery, and retries for Settings UI.
final class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @visibleForTesting
  static Duration operationTimeout = const Duration(seconds: 10);

  AppSettings? _lastSettings;

  /// Most recent usable settings retained while a save or retry fails.
  AppSettings? get lastSettings => _lastSettings;

  @override
  Future<AppSettings> build() => _load();

  /// Persists a complete immutable settings value.
  Future<bool> save(AppSettings settings) async {
    if (state.isLoading) return false;
    final previous = _lastSettings;
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(settingsRepositoryProvider)
          .write(settings)
          .timeout(operationTimeout);
      final failure = result.failureOrNull;
      if (failure != null) {
        state = AsyncError(failure, StackTrace.current);
        ref
            .read(appLoggerProvider)
            .error(
              'operation=save status=failure',
              name: 'settings',
              error: failure,
            );
        return false;
      }

      await ref
          .read(applyLaunchAtLoginProvider)(settings)
          .timeout(operationTimeout);
      await ref
          .read(applyPresentationSettingsProvider)()
          .timeout(operationTimeout);
      _lastSettings = settings;
      state = AsyncData(settings);

      if (previous?.copilotEnabled != settings.copilotEnabled) {
        ref
          ..invalidate(selectedProviderIdProvider)
          ..invalidate(copilotDiagnosticsProvider);
      }
      ref
          .read(appLoggerProvider)
          .info('operation=save status=success', name: 'settings');
      return true;
    } on Object catch (error, stackTrace) {
      final safeError = error is TimeoutException
          ? const AppFailure(
              code: FailureCode.timeout,
              message: 'Saving settings timed out. Please retry.',
            )
          : error;
      ref
          .read(appLoggerProvider)
          .error(
            'operation=save status=failure',
            name: 'settings',
            error: safeError,
            stackTrace: stackTrace,
          );
      state = AsyncError(safeError, stackTrace);
      return false;
    }
  }

  /// Reloads settings after a recoverable loading or saving failure.
  Future<void> retry() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<AppSettings> _load() async {
    try {
      final settings = await ref
          .read(settingsRepositoryProvider)
          .read()
          .timeout(operationTimeout);
      _lastSettings = settings;
      return settings;
    } on TimeoutException {
      throw StateError('Loading settings timed out. Please retry.');
    }
  }
}

/// Feature-scoped asynchronous settings state.
final settingsControllerProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
      SettingsNotifier.new,
    );
