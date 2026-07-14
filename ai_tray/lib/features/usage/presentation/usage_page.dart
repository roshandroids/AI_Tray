import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/core/widgets/terminal_chrome.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_empty_state.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_pill.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_usage_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Terminal-inspired usage dashboard (PD-020).
final class UsagePage extends ConsumerStatefulWidget {
  const UsagePage({super.key});

  @override
  ConsumerState<UsagePage> createState() => _UsagePageState();
}

final class _UsagePageState extends ConsumerState<UsagePage> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final meta =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (!meta) return false;

    final repo = ref.read(usageRepositoryProvider);
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      unawaited(repo.refresh(manual: true));
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.comma) {
      unawaited(_openSettings());
      return true;
    }
    return false;
  }

  Future<void> _openSettings() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  Future<void> _openDiagnostics() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DiagnosticsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsOpenRequestProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_openSettings());
    });

    final repository = ref.watch(usageRepositoryProvider);

    return StreamBuilder<RefreshStatus>(
      stream: repository.watchStatus(),
      initialData: repository.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? RefreshStatus.initial();
        final usage = status.lastResult?.usage;
        final error = status.lastResult?.error;
        final refreshing = status.phase == RefreshPhase.refreshing;
        final kind = UsageStatusMapper.kind(status);

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Tray'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: Center(child: TrayStatusPill(kind: kind, compact: true)),
              ),
              IconButton(
                tooltip: 'Diagnostics',
                onPressed: () => unawaited(_openDiagnostics()),
                icon: const Icon(Icons.terminal_outlined),
              ),
              IconButton(
                tooltip: 'Settings (⌘,)',
                onPressed: () => unawaited(_openSettings()),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Spacing.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: usage != null
                            ? _DashboardBody(
                                key: ValueKey(
                                  '${usage.fetchedAt.toIso8601String()}_$kind',
                                ),
                                usage: usage,
                                status: status,
                                kind: kind,
                              )
                            : SingleChildScrollView(
                                key: const ValueKey('empty'),
                                child: TrayEmptyState(failure: error),
                              ),
                      ),
                    ),
                    const AsciiSeparator(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '⌘R refresh  ·  ⌘, settings',
                            style: context.typography.muted.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: refreshing
                              ? null
                              : () => unawaited(
                                  repository.refresh(manual: true),
                                ),
                          child: Text(
                            refreshing ? 'Refreshing…' : 'Refresh',
                            style: context.typography.button.copyWith(
                              color: refreshing
                                  ? context.colors.textMuted
                                  : context.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.usage,
    required this.status,
    required this.kind,
    super.key,
  });

  final UsageInfo usage;
  final RefreshStatus status;
  final TrayStatusKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = status.lastResult?.status;
    final error = status.lastResult?.error;
    final parser = status.lastResult?.parserState;
    final settingsFuture = ref.watch(usageRepositoryProvider).getSettings();

    return FutureBuilder<AppSettings>(
      future: settingsFuture,
      builder: (context, settingsSnap) {
        final settings = settingsSnap.data;
        final mode = settings == null
            ? '—'
            : settings.autoRefreshEnabled
            ? 'Auto ${settings.refreshInterval.inSeconds}s'
            : 'Manual';

        final parserOk = parser?.validation == ValidationStatus.valid;
        final authOk = kind != TrayStatusKind.error;
        final showStale = settings?.showStaleIndicator ?? true;
        final displayKind = !showStale && kind == TrayStatusKind.cached
            ? TrayStatusKind.live
            : kind;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrayUsageMeter(
                label: 'Session',
                percent: usage.sessionUsedPercent,
                resetsAtRaw: usage.sessionResetsAtRaw,
              ),
              const AsciiSeparator(),
              for (var i = 0; i < usage.weekly.length; i++) ...[
                TrayUsageMeter(
                  label: _weekLabel(usage.weekly[i].label),
                  percent: usage.weekly[i].usedPercent,
                  resetsAtRaw: usage.weekly[i].resetsAtRaw,
                ),
                if (i < usage.weekly.length - 1) const AsciiSeparator(),
              ],
              const AsciiSeparator(),
              const TerminalSectionLabel('Usage status'),
              const SizedBox(height: Spacing.sm),
              TerminalKvRow(
                label: 'Status',
                value:
                    '${UsageStatusMapper.emoji(displayKind)} '
                    '${UsageStatusMapper.label(displayKind)}',
              ),
              TerminalKvRow(
                label: 'Source',
                value: UsageStatusMapper.sourceLabel(usage),
              ),
              TerminalKvRow(
                label: 'Updated',
                value: UsageStatusMapper.relativeUpdated(
                  status.lastSuccessAt ?? usage.fetchedAt,
                ),
              ),
              TerminalKvRow(label: 'Mode', value: mode),
              if (outcome == RefreshOutcome.softFailure) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  'Claude did not return limits; showing last known usage.',
                  style: context.typography.bodySmall,
                ),
              ],
              if (outcome == RefreshOutcome.failure && error != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(error.message, style: context.typography.error),
              ],
              const AsciiSeparator(),
              const TerminalSectionLabel('CLI health'),
              const SizedBox(height: Spacing.sm),
              TerminalKvRow(
                label: 'Auth',
                value: authOk ? '✓ OK' : '✗ Check',
                valueColor: authOk
                    ? context.colors.success
                    : context.colors.error,
              ),
              TerminalKvRow(
                label: 'Parser',
                value: parser == null
                    ? '—'
                    : parserOk
                    ? '✓ OK'
                    : '✗ ${parser.validation.name}',
                valueColor: parserOk
                    ? context.colors.success
                    : context.colors.warning,
              ),
              TerminalKvRow(
                label: 'Cache',
                value: usage.isFromCache ? 'Using LKG' : '✓ Fresh',
              ),
              TerminalKvRow(
                label: 'Last error',
                value: error?.message ?? 'None',
                valueColor: error == null
                    ? context.colors.textMuted
                    : context.colors.error,
              ),
            ],
          ),
        );
      },
    );
  }

  static String _weekLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Week';
    return 'Week ($trimmed)';
  }
}
