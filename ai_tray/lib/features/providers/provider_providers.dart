import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/copilot/copilot_provider.dart';
import 'package:ai_tray/features/providers/data/process/io_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Process execution dependency shared by CLI-backed providers.
final processRunnerProvider = Provider<ProcessRunner>((ref) {
  return IoProcessRunner(logger: ref.watch(appLoggerProvider));
});

/// Feature-scoped provider catalog.
///
/// Claude remains the enabled default; Copilot is registered disabled so it
/// cannot be selected or refreshed accidentally.
final providerRegistryProvider = Provider<ProviderRegistry>((ref) {
  return ProviderRegistry(
    providers: [
      ClaudeCliAdapter(
        processRunner: ref.watch(processRunnerProvider),
        logger: ref.watch(appLoggerProvider),
      ),
      const CopilotProvider(),
    ],
    defaultProviderId: ProviderId.claude,
  );
});
