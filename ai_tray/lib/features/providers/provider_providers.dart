import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/providers/copilot/adapter/copilot_adapter.dart';
import 'package:ai_tray/features/providers/copilot/diagnostics/copilot_diagnostics.dart';
import 'package:ai_tray/features/providers/copilot/provider/copilot_provider.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk_v1.dart';
import 'package:ai_tray/features/providers/copilot/sdk/sidecar_process.dart';
import 'package:ai_tray/features/providers/copilot/sdk/sidecar_process_transport.dart';
import 'package:ai_tray/features/providers/core/cache/provider_cache.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:ai_tray/features/providers/core/registry/provider_registry.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/io_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Process execution dependency shared by CLI-backed providers.
final processRunnerProvider = Provider<ProcessRunner>((ref) {
  return IoProcessRunner(logger: ref.watch(appLoggerProvider));
});

/// Executable and arguments for the bundled Copilot sidecar.
final class CopilotSidecarCommand {
  const CopilotSidecarCommand({
    required this.executable,
    required this.arguments,
    this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
}

/// Resolves development and packaged sidecar locations without `npx` or `gh`.
final copilotSidecarCommandProvider = Provider<CopilotSidecarCommand>((ref) {
  const isRelease = bool.fromEnvironment('dart.vm.product');
  if (!isRelease) {
    final bridgeRoot = '${Directory.current.path}/tool/copilot_sdk_bridge';
    return CopilotSidecarCommand(
      executable: 'node',
      arguments: const ['dist/src/bridge_cli.js'],
      workingDirectory: bridgeRoot,
    );
  }

  final executableDirectory = File(Platform.resolvedExecutable).parent.path;
  final runtimeRoot = Platform.isMacOS
      ? '$executableDirectory/../Resources/copilot_sdk'
      : '$executableDirectory/copilot_sdk';
  return CopilotSidecarCommand(
    executable: Platform.isMacOS
        ? '$runtimeRoot/node/bin/node'
        : '$runtimeRoot/node/node.exe',
    arguments: ['$runtimeRoot/bridge/dist/src/bridge_cli.js'],
    workingDirectory: '$runtimeRoot/bridge',
  );
});

/// Process launcher isolated for transport tests.
final copilotSidecarLauncherProvider = Provider<SidecarProcessLauncher>((ref) {
  return const IoSidecarProcessLauncher();
});

/// Lazily initialized feature-owned SDK boundary.
final copilotSdkProvider = Provider<CopilotSdk>((ref) {
  final command = ref.watch(copilotSidecarCommandProvider);
  return CopilotSdkV1(
    transport: SidecarProcessTransport(
      launcher: ref.watch(copilotSidecarLauncherProvider),
      logger: ref.watch(appLoggerProvider),
      executable: command.executable,
      arguments: command.arguments,
      workingDirectory: command.workingDirectory,
    ),
  );
});

/// Lifecycle-owning SDK adapter.
final copilotSdkAdapterProvider = Provider<CopilotSdkAdapter>((ref) {
  final adapter = CopilotSdkAdapter(
    sdk: ref.watch(copilotSdkProvider),
    logger: ref.watch(appLoggerProvider),
  );
  ref.onDispose(() => unawaited(adapter.shutdown()));
  return adapter;
});

/// Feature-owned metadata caches used by pure diagnostics.
final copilotHealthCacheProvider =
    Provider<ProviderMetadataCache<ProviderHealth>>((ref) {
      return ProviderMetadataCache();
    });

final copilotVersionCacheProvider =
    Provider<ProviderMetadataCache<VersionInfo>>((ref) {
      return ProviderMetadataCache();
    });

/// Pure diagnostics service exposed through dependency injection.
final copilotDiagnosticsServiceProvider = Provider<CopilotDiagnosticsService>((
  ref,
) {
  return CopilotDiagnosticsService(
    sdk: ref.watch(copilotSdkProvider),
    logger: ref.watch(appLoggerProvider),
    healthCache: ref.watch(copilotHealthCacheProvider),
    versionCache: ref.watch(copilotVersionCacheProvider),
  );
});

/// Feature-scoped provider catalog with Claude retained as default.
final providerRegistryProvider = Provider<ProviderRegistry>((ref) {
  return ProviderRegistry(
    providers: [
      ClaudeCliAdapter(
        processRunner: ref.watch(processRunnerProvider),
        logger: ref.watch(appLoggerProvider),
      ),
      CopilotProvider.active(adapter: ref.watch(copilotSdkAdapterProvider)),
    ],
    defaultProviderId: ProviderId.claude,
  );
});
