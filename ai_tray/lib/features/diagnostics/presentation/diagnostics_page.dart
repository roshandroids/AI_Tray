import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/diagnostics/presentation/copilot_diagnostics_controller.dart';
import 'package:ai_tray/features/providers/copilot/diagnostics/copilot_diagnostics.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/release_history_providers.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';

/// Live diagnostics dashboard aligned to the design system (PD-021).
final class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(usageRepositoryProvider);
    final logger = ref.watch(bufferedAppLoggerProvider);
    final themePref = ref
        .watch(personalizationControllerProvider)
        .value
        ?.themeMode;
    final selectedProvider = ref.watch(selectedAIProviderProvider);
    final copilotDiagnostics = ref.watch(copilotDiagnosticsProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final appVersionLabel = packageInfo.when(
      data: (info) => '${info.version}+${info.buildNumber}',
      loading: () => '…',
      error: (_, _) => 'unavailable',
    );

    return StreamBuilder<RefreshStatus>(
      stream: repository.watchStatus(),
      initialData: repository.status,
      builder: (context, snap) {
        final status = snap.data ?? RefreshStatus.initial();
        final kind = UsageStatusMapper.kind(status);
        final result = status.lastResult;
        final usage = result?.usage;
        final parser = result?.parserState;
        final error = result?.error;

        return FutureBuilder<AppSettings>(
          future: repository.getSettings(),
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data;
            final themeLabel = (themePref ?? settings?.themeMode)?.label ?? '—';

            return Scaffold(
              appBar: AppBar(
                title: const Text('Diagnostics'),
                actions: [
                  StatusBadge(kind: kind, compact: true),
                  const SizedBox(width: Spacing.sm),
                  IconButton(
                    tooltip: 'Open logs',
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(appShellDestinationProvider.notifier)
                          .select(AppDestination.logs);
                    },
                    icon: const Icon(Icons.article_outlined),
                  ),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final panels = [
                    SectionCard(
                      title: 'Application',
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'App version',
                            value: appVersionLabel,
                          ),
                          InfoRow(
                            label: '${selectedProvider.displayName} CLI',
                            value: '—',
                          ),
                          InfoRow(label: 'Theme', value: themeLabel),
                          InfoRow(
                            label: 'Platform',
                            value: _platformLabel(),
                          ),
                          InfoRow(
                            label: 'Architecture',
                            value: _archLabel(),
                          ),
                          const InfoRow(
                            label: 'Build',
                            value: kReleaseMode ? 'Release' : 'Debug',
                          ),
                          InfoRow(
                            label: 'Provider',
                            value: selectedProvider.sourceLabel,
                          ),
                        ],
                      ),
                    ),
                    SectionCard(
                      title: 'Refresh',
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Mode',
                            value: settings == null
                                ? '—'
                                : settings.autoRefreshEnabled
                                ? 'Auto'
                                : 'Manual',
                          ),
                          InfoRow(
                            label: 'Interval',
                            value: settings == null
                                ? '—'
                                : '${settings.refreshInterval.inSeconds}s',
                          ),
                          InfoRow(
                            label: 'Phase',
                            value: status.phase.name,
                          ),
                          InfoRow(
                            label: 'Status',
                            value: UsageStatusMapper.label(kind),
                            valueColor: _statusColor(context, kind),
                          ),
                          InfoRow(
                            label: 'Last success',
                            value: UsageStatusMapper.relativeUpdated(
                              status.lastSuccessAt,
                            ),
                          ),
                          InfoRow(
                            label: 'Last failure',
                            value: result?.status == RefreshOutcome.failure
                                ? (error?.message ?? 'failure')
                                : '—',
                            valueColor: result?.status == RefreshOutcome.failure
                                ? context.colors.error
                                : null,
                          ),
                          InfoRow(
                            label: 'Duration',
                            value: result == null
                                ? '—'
                                : '${result.duration.inMilliseconds}ms',
                          ),
                          InfoRow(
                            label: 'Soft fails',
                            value: '${status.consecutiveSoftFailures}',
                          ),
                          InfoRow(
                            label: 'Hard fails',
                            value: '${status.consecutiveHardFailures}',
                          ),
                        ],
                      ),
                    ),
                    if (selectedProvider.providerId == ProviderId.copilot)
                      _CopilotDiagnosticsPanel(
                        state: copilotDiagnostics,
                        onRetry: () => unawaited(
                          ref.read(copilotDiagnosticsProvider.notifier).retry(),
                        ),
                      )
                    else
                      SectionCard(
                        title: 'Parser / Cache',
                        child: Column(
                          children: [
                            InfoRow(
                              label: 'Parser',
                              value: parser?.shape.name ?? '—',
                            ),
                            InfoRow(
                              label: 'Validation',
                              value: parser?.validation.name ?? '—',
                            ),
                            InfoRow(
                              label: 'Session line',
                              value: parser == null
                                  ? '—'
                                  : parser.matchedSessionLine
                                  ? 'matched'
                                  : 'miss',
                            ),
                            InfoRow(
                              label: 'Week lines',
                              value: parser == null
                                  ? '—'
                                  : '${parser.matchedWeekLineCount}',
                            ),
                            InfoRow(
                              label: 'Cache',
                              value: usage == null
                                  ? 'empty'
                                  : usage.isFromCache
                                  ? 'LKG'
                                  : 'live',
                              valueColor: usage == null
                                  ? context.colors.textMuted
                                  : usage.isFromCache
                                  ? context.colors.warning
                                  : context.colors.success,
                            ),
                            InfoRow(
                              label: 'Exit code',
                              value: result?.cliExitCode?.toString() ?? '—',
                            ),
                            InfoRow(
                              label: 'CLI binary',
                              value:
                                  (settings?.claudeBinaryPath?.isNotEmpty ??
                                      false)
                                  ? settings!.claudeBinaryPath!
                                  : 'claude (PATH)',
                            ),
                          ],
                        ),
                      ),
                    SectionCard(
                      title: 'Tools',
                      child: Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          _ToolButton(
                            label: 'Force refresh',
                            onPressed: status.phase == RefreshPhase.refreshing
                                ? null
                                : () => unawaited(
                                    repository.refresh(manual: true),
                                  ),
                          ),
                          _ToolButton(
                            label: 'Open logs',
                            onPressed: () {
                              Navigator.of(context).pop();
                              ref
                                  .read(appShellDestinationProvider.notifier)
                                  .select(AppDestination.logs);
                            },
                          ),
                          _ToolButton(
                            label: 'Copy diagnostics',
                            onPressed: () => unawaited(
                              _copyDiagnostics(
                                context,
                                appVersion: appVersionLabel,
                                status: status,
                                settings: settings,
                                theme: themePref,
                                logger: logger,
                              ),
                            ),
                          ),
                          _ToolButton(
                            label: 'Export logs',
                            onPressed: () =>
                                unawaited(_exportLogs(context, logger)),
                          ),
                          _ToolButton(
                            label: 'Test notification',
                            onPressed: () =>
                                unawaited(_testNotification(context)),
                          ),
                          _ToolButton(
                            label: 'Show cache',
                            onPressed: () =>
                                unawaited(_showCache(context, ref)),
                          ),
                        ],
                      ),
                    ),
                  ];

                  return ListView(
                    padding: const EdgeInsets.all(Spacing.md),
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: panels[0]),
                            const SizedBox(width: Spacing.md),
                            Expanded(child: panels[1]),
                          ],
                        )
                      else ...[
                        panels[0],
                        const SizedBox(height: Spacing.md),
                        panels[1],
                      ],
                      const SizedBox(height: Spacing.md),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: panels[2]),
                            const SizedBox(width: Spacing.md),
                            Expanded(child: panels[3]),
                          ],
                        )
                      else ...[
                        panels[2],
                        const SizedBox(height: Spacing.md),
                        panels[3],
                      ],
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  static Color? _statusColor(BuildContext context, TrayStatusKind kind) {
    final colors = context.colors;
    return switch (kind) {
      TrayStatusKind.live => colors.success,
      TrayStatusKind.cached => colors.warning,
      TrayStatusKind.error => colors.error,
      TrayStatusKind.refreshing => colors.info,
      TrayStatusKind.idle => colors.textMuted,
    };
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }

  static String _archLabel() {
    return Platform.localHostname.isEmpty
        ? Platform.operatingSystemVersion
        : '${Platform.operatingSystem} · ${Platform.operatingSystemVersion}';
  }

  static Future<void> _copyDiagnostics(
    BuildContext context, {
    required String appVersion,
    required RefreshStatus status,
    required AppSettings? settings,
    required AppThemePreference? theme,
    required BufferedAppLogger logger,
  }) async {
    final kind = UsageStatusMapper.kind(status);
    final result = status.lastResult;
    final buffer = StringBuffer()
      ..writeln('AI Tray Diagnostics')
      ..writeln('version=$appVersion')
      ..writeln('platform=${_platformLabel()}')
      ..writeln('build=${kReleaseMode ? 'release' : 'debug'}')
      ..writeln('theme=${theme?.label ?? settings?.themeMode.label}')
      ..writeln('status=${UsageStatusMapper.label(kind)}')
      ..writeln('phase=${status.phase.name}')
      ..writeln('lastSuccess=${status.lastSuccessAt}')
      ..writeln('outcome=${result?.status.name}')
      ..writeln('parser=${result?.parserState.shape.name}')
      ..writeln('validation=${result?.parserState.validation.name}')
      ..writeln('error=${result?.error?.message}')
      ..writeln('softFailures=${status.consecutiveSoftFailures}')
      ..writeln('hardFailures=${status.consecutiveHardFailures}')
      ..writeln('--- recent logs ---')
      ..writeln(logger.exportPlainText());

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostics copied to clipboard')),
      );
    }
  }

  static Future<void> _exportLogs(
    BuildContext context,
    BufferedAppLogger logger,
  ) async {
    try {
      final dir = Directory.systemTemp;
      final file = File(
        '${dir.path}/ai-tray-logs-${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(logger.exportPlainText());
      await Clipboard.setData(ClipboardData(text: file.path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported → ${file.path}')),
        );
      }
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $error')),
        );
      }
    }
  }

  static Future<void> _testNotification(BuildContext context) async {
    try {
      final notification = LocalNotification(
        title: 'AI Tray',
        body: 'Test notification from Diagnostics',
      );
      await notification.show();
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification failed: $error')),
        );
      }
    }
  }

  static Future<void> _showCache(BuildContext context, WidgetRef ref) async {
    final cached = await ref.read(usageRepositoryProvider).getCachedUsage();
    if (!context.mounted) return;
    final usage = cached.valueOrNull;
    final text = usage == null
        ? 'Cache empty'
        : 'Session ${usage.sessionUsedPercent.round()}% · '
              'cached=${usage.isFromCache} · '
              'fetched=${usage.fetchedAt.toIso8601String()}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cache'),
        content: Text(text, style: ctx.typography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

final class _CopilotDiagnosticsPanel extends StatelessWidget {
  const _CopilotDiagnosticsPanel({
    required this.state,
    required this.onRetry,
  });

  final AsyncValue<CopilotDiagnostics> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final diagnostics = state.value;
    if (state.isLoading && diagnostics == null) {
      return const SectionCard(
        title: 'Copilot SDK',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (state.hasError && diagnostics == null) {
      final timedOut = state.error is TimeoutException;
      return SectionCard(
        title: 'Copilot SDK',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timedOut
                  ? 'Diagnostics timed out. Verify the bundled SDK and retry.'
                  : 'Diagnostics failed safely. No credentials or tokens were '
                        'included in this report.',
              style: context.typography.body,
            ),
            const SizedBox(height: Spacing.sm),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (diagnostics == null) {
      return SectionCard(
        title: 'Copilot SDK',
        child: OutlinedButton(
          onPressed: onRetry,
          child: const Text('Run diagnostics'),
        ),
      );
    }

    final warnings = <String>[
      if (!diagnostics.providerEnabled) 'Provider is disabled in Settings.',
      if (diagnostics.authStatus != 'Authenticated')
        'Authentication: ${diagnostics.authStatus}',
      if (diagnostics.quotaRpcStatus != 'Available')
        'Quota RPC: ${diagnostics.quotaRpcStatus}',
      if (!diagnostics.available)
        'Usage remains unavailable until all required checks pass.',
    ];
    return SectionCard(
      title: 'Copilot SDK',
      child: Column(
        children: [
          InfoRow(label: 'SDK version', value: diagnostics.sdkVersion),
          InfoRow(label: 'CLI version', value: diagnostics.cliVersion),
          InfoRow(label: 'Authentication', value: diagnostics.authStatus),
          InfoRow(label: 'Health', value: diagnostics.healthStatus),
          InfoRow(label: 'Quota RPC', value: diagnostics.quotaRpcStatus),
          InfoRow(
            label: 'Experimental API',
            value: diagnostics.experimentalStatus,
          ),
          InfoRow(label: 'Model', value: diagnostics.currentModel),
          InfoRow(
            label: 'Duration',
            value: '${diagnostics.duration.inMilliseconds}ms',
          ),
          InfoRow(
            label: 'Checked',
            value: diagnostics.checkedAt.toLocal().toIso8601String(),
          ),
          if (warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Text(
                warnings.join('\n'),
                style: context.typography.caption.copyWith(
                  color: context.colors.warning,
                ),
              ),
            ),
          const SizedBox(height: Spacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: state.isLoading ? null : onRetry,
              child: Text(state.isLoading ? 'Checking…' : 'Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.textPrimary,
        side: BorderSide(color: context.colors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        textStyle: context.typography.caption,
      ),
      child: Text(label),
    );
  }
}

extension on AppThemePreference {
  String get label => switch (this) {
    AppThemePreference.system => 'System',
    AppThemePreference.dark => 'Dark',
    AppThemePreference.light => 'Light',
  };
}
