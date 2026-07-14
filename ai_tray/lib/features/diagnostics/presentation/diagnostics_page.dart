import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/core/theme/theme_controller.dart';
import 'package:ai_tray/core/widgets/terminal_chrome.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_pill.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';

/// Developer diagnostics dashboard (PD-020).
final class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(usageRepositoryProvider);
    final logger = ref.watch(bufferedAppLoggerProvider);
    final themePref = ref.watch(themeControllerProvider).value;

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

            return Scaffold(
              appBar: AppBar(
                title: const Text('Diagnostics'),
                actions: [
                  TrayStatusPill(kind: kind, compact: true),
                  const SizedBox(width: Spacing.sm),
                  IconButton(
                    tooltip: 'Open logs',
                    onPressed: () {
                      unawaited(
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LogsPage(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.article_outlined),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: [
                  const TerminalSectionLabel('Application'),
                  const SizedBox(height: Spacing.sm),
                  const TerminalKvRow(label: 'Version', value: '1.0.0+3'),
                  TerminalKvRow(
                    label: 'Platform',
                    value: _platformLabel(),
                  ),
                  TerminalKvRow(
                    label: 'Architecture',
                    value: _archLabel(),
                  ),
                  const TerminalKvRow(
                    label: 'Build',
                    value: kReleaseMode ? 'Release' : 'Debug',
                  ),
                  TerminalKvRow(
                    label: 'Theme',
                    value: (themePref ?? settings?.themeMode)?.label ?? '—',
                  ),
                  const AsciiSeparator(),
                  const TerminalSectionLabel('Refresh'),
                  const SizedBox(height: Spacing.sm),
                  TerminalKvRow(
                    label: 'Auto refresh',
                    value: settings == null
                        ? '—'
                        : settings.autoRefreshEnabled
                        ? 'On'
                        : 'Off',
                  ),
                  TerminalKvRow(
                    label: 'Interval',
                    value: settings == null
                        ? '—'
                        : '${settings.refreshInterval.inSeconds}s',
                  ),
                  TerminalKvRow(
                    label: 'Phase',
                    value: status.phase.name,
                  ),
                  TerminalKvRow(
                    label: 'Status',
                    value:
                        '${UsageStatusMapper.emoji(kind)} '
                        '${UsageStatusMapper.label(kind)}',
                  ),
                  TerminalKvRow(
                    label: 'Last success',
                    value: UsageStatusMapper.relativeUpdated(
                      status.lastSuccessAt,
                    ),
                  ),
                  TerminalKvRow(
                    label: 'Last failure',
                    value: result?.status == RefreshOutcome.failure
                        ? (error?.message ?? 'failure')
                        : '—',
                    valueColor: result?.status == RefreshOutcome.failure
                        ? context.colors.error
                        : null,
                  ),
                  TerminalKvRow(
                    label: 'Duration',
                    value: result == null
                        ? '—'
                        : '${result.duration.inMilliseconds}ms',
                  ),
                  TerminalKvRow(
                    label: 'Soft failures',
                    value: '${status.consecutiveSoftFailures}',
                  ),
                  TerminalKvRow(
                    label: 'Hard failures',
                    value: '${status.consecutiveHardFailures}',
                  ),
                  const AsciiSeparator(),
                  const TerminalSectionLabel('Parser / cache'),
                  const SizedBox(height: Spacing.sm),
                  TerminalKvRow(
                    label: 'Shape',
                    value: parser?.shape.name ?? '—',
                  ),
                  TerminalKvRow(
                    label: 'Validation',
                    value: parser?.validation.name ?? '—',
                  ),
                  TerminalKvRow(
                    label: 'Session line',
                    value: parser == null
                        ? '—'
                        : parser.matchedSessionLine
                        ? 'matched'
                        : 'miss',
                  ),
                  TerminalKvRow(
                    label: 'Week lines',
                    value: parser == null
                        ? '—'
                        : '${parser.matchedWeekLineCount}',
                  ),
                  TerminalKvRow(
                    label: 'Raw length',
                    value: parser == null ? '—' : '${parser.rawTextLength}',
                  ),
                  TerminalKvRow(
                    label: 'Cache',
                    value: usage == null
                        ? 'empty'
                        : usage.isFromCache
                        ? 'LKG'
                        : 'live',
                  ),
                  TerminalKvRow(
                    label: 'Exit code',
                    value: result?.cliExitCode?.toString() ?? '—',
                  ),
                  TerminalKvRow(
                    label: 'CLI binary',
                    value: (settings?.claudeBinaryPath?.isNotEmpty ?? false)
                        ? settings!.claudeBinaryPath!
                        : 'claude (PATH)',
                  ),
                  const TerminalKvRow(
                    label: 'CLI version',
                    value: '— (not captured; see PD-020 notes)',
                  ),
                  const AsciiSeparator(),
                  const TerminalSectionLabel('Advanced'),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
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
                          unawaited(
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LogsPage(),
                              ),
                            ),
                          );
                        },
                      ),
                      _ToolButton(
                        label: 'Copy diagnostics',
                        onPressed: () => unawaited(
                          _copyDiagnostics(
                            context,
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
                        onPressed: () => unawaited(_testNotification(context)),
                      ),
                      _ToolButton(
                        label: 'Show cache',
                        onPressed: () => unawaited(_showCache(context, ref)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }

  static String _archLabel() {
    return Platform.operatingSystemVersion;
  }

  static Future<void> _copyDiagnostics(
    BuildContext context, {
    required RefreshStatus status,
    required AppSettings? settings,
    required AppThemePreference? theme,
    required BufferedAppLogger logger,
  }) async {
    final kind = UsageStatusMapper.kind(status);
    final result = status.lastResult;
    final buffer = StringBuffer()
      ..writeln('AI Tray Diagnostics')
      ..writeln('version=1.0.0+3')
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
        side: BorderSide(color: context.colors.divider),
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
