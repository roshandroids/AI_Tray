import 'dart:async';

import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/providers/copilot/diagnostics/copilot_diagnostics.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation state for the pure Copilot diagnostics service.
final class CopilotDiagnosticsNotifier
    extends AsyncNotifier<CopilotDiagnostics> {
  static const _uiTimeout = Duration(seconds: 12);

  @override
  Future<CopilotDiagnostics> build() => _inspect();

  /// Re-runs all probes without using cached health or version metadata.
  Future<void> retry() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _inspect(forceRefresh: true));
  }

  Future<CopilotDiagnostics> _inspect({bool forceRefresh = false}) async {
    final logger = ref.read(bufferedAppLoggerProvider)
      ..info(
        'operation=ui_diagnostics status=started',
        name: 'copilot_diagnostics_ui',
        provider: 'copilot',
        category: 'diagnostics',
      );
    try {
      final settings = await ref
          .read(settingsRepositoryProvider)
          .read()
          .timeout(_uiTimeout);
      final result = await ref
          .read(copilotDiagnosticsServiceProvider)
          .inspect(
            enabled: settings.copilotEnabled,
            forceRefresh: forceRefresh,
          )
          .timeout(_uiTimeout);
      logger.info(
        'operation=ui_diagnostics status=success '
        'available=${result.available}',
        name: 'copilot_diagnostics_ui',
        provider: 'copilot',
        category: 'diagnostics',
      );
      return result;
    } on Object catch (error, stackTrace) {
      logger.error(
        'operation=ui_diagnostics status=failure',
        name: 'copilot_diagnostics_ui',
        error: error,
        stackTrace: stackTrace,
        provider: 'copilot',
        category: 'diagnostics',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

/// Feature-scoped asynchronous Copilot diagnostics snapshot.
final copilotDiagnosticsProvider =
    AsyncNotifierProvider<CopilotDiagnosticsNotifier, CopilotDiagnostics>(
      CopilotDiagnosticsNotifier.new,
    );
