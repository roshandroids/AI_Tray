import 'dart:async';

import 'package:ai_tray/core/components/metric_card.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/presentation/widgets/provider_selector.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:ai_tray/features/usage/domain/services/dashboard_data_mapper.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_empty_state.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-system dashboard (PD-021).
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
    if (event.logicalKey == LogicalKeyboardKey.keyL) {
      unawaited(_openLogs());
      return true;
    }
    return false;
  }

  Future<void> _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
  );

  Future<void> _openDiagnostics() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const DiagnosticsPage()),
  );

  Future<void> _openLogs() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const LogsPage()),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsOpenRequestProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_openSettings());
    });

    final repository = ref.watch(usageRepositoryProvider);
    final registry = ref.watch(providerRegistryProvider);
    final selectedProvider = ref.watch(selectedAIProviderProvider);

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
              ProviderSelector(
                providers: registry.enabledProviders.toList(),
                selectedId: selectedProvider.providerId,
                onSelected: ref
                    .read(selectedProviderIdProvider.notifier)
                    .select,
              ),
              const SizedBox(width: Spacing.sm),
              Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: Center(child: StatusBadge(kind: kind, compact: true)),
              ),
              IconButton(
                tooltip: 'Logs (⌘L)',
                onPressed: () => unawaited(_openLogs()),
                icon: const Icon(Icons.article_outlined),
              ),
              IconButton(
                tooltip: 'Diagnostics',
                onPressed: () => unawaited(_openDiagnostics()),
                icon: const Icon(Icons.monitor_heart_outlined),
              ),
              IconButton(
                tooltip: 'Settings (⌘,)',
                onPressed: () => unawaited(_openSettings()),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Spacing.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  Spacing.sm,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: usage == null
                          ? SingleChildScrollView(
                              child: TrayEmptyState(
                                failure: error,
                                provider: selectedProvider,
                              ),
                            )
                          : _DashboardBody(
                              usage: usage,
                              status: status,
                              kind: kind,
                              provider: selectedProvider,
                            ),
                    ),
                    const SectionDivider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '⌘R Refresh · ⌘L Logs · ⌘, Settings',
                            style: context.typography.caption,
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
                            style: context.typography.label.copyWith(
                              color: refreshing
                                  ? context.colors.textMuted
                                  : context.colors.success,
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
    required this.provider,
  });

  final UsageInfo usage;
  final RefreshStatus status;
  final TrayStatusKind kind;
  final AIProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = status.lastResult?.status;
    final error = status.lastResult?.error;
    final parser = status.lastResult?.parserState;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 560;
    final dashboardData = DashboardDataMapper.map(
      provider: provider,
      usage: usage,
      refreshStatus: status,
    );

    return FutureBuilder<AppSettings>(
      future: ref.watch(usageRepositoryProvider).getSettings(),
      builder: (context, snap) {
        final settings = snap.data;
        final showStale = settings?.showStaleIndicator ?? true;
        final displayKind = !showStale && kind == TrayStatusKind.cached
            ? TrayStatusKind.live
            : kind;
        final mode = settings == null
            ? '—'
            : settings.autoRefreshEnabled
            ? 'Auto ${settings.refreshInterval.inSeconds}s'
            : 'Manual';
        final parserOk = parser?.validation == ValidationStatus.valid;
        final authOk = kind != TrayStatusKind.error;

        final metricCards = [
          for (final metric in dashboardData.metrics)
            MetricCard(
              key: ValueKey(metric.key),
              label: metric.label,
              percent: metric.usedPercent,
              resetsAtRaw: metric.resetsAtRaw,
              sparklineValues: _sparkFromPercent(metric.usedPercent),
            ),
        ];
        final primaryMetricCards = metricCards.take(2).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < primaryMetricCards.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: Spacing.sm),
                            Expanded(child: primaryMetricCards[index]),
                          ],
                        ],
                      ),
                    )
                  else ...[
                    for (
                      var index = 0;
                      index < primaryMetricCards.length;
                      index++
                    ) ...[
                      primaryMetricCards[index],
                      if (index < primaryMetricCards.length - 1)
                        const SizedBox(height: Spacing.sm),
                    ],
                  ],
                  if (metricCards.length > 2) ...[
                    const SizedBox(height: Spacing.sm),
                    ...[
                      for (var i = 2; i < metricCards.length; i++) ...[
                        metricCards[i],
                        if (i < metricCards.length - 1)
                          const SizedBox(height: Spacing.sm),
                      ],
                    ],
                  ],
                  const SizedBox(height: Spacing.md),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TerminalPanel(
                            title: 'Status',
                            child: Column(
                              children: [
                                InfoRow(
                                  label: 'Status',
                                  value:
                                      '● ${UsageStatusMapper.label(
                                        displayKind,
                                      )}',
                                  valueColor: context.colors.success,
                                ),
                                InfoRow(
                                  label: 'Source',
                                  value: dashboardData.status.sourceLabel,
                                ),
                                InfoRow(
                                  label: 'Updated',
                                  value: UsageStatusMapper.relativeUpdated(
                                    status.lastSuccessAt ?? usage.fetchedAt,
                                  ),
                                ),
                                InfoRow(label: 'Mode', value: mode),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: TerminalPanel(
                            title: 'Provider Health',
                            child: Column(
                              children: [
                                if (dashboardData.capabilities.healthCheck)
                                  HealthIndicator(label: 'Auth', ok: authOk),
                                HealthIndicator(
                                  label: 'Parser',
                                  ok: parserOk,
                                  detail: parser == null
                                      ? '—'
                                      : parserOk
                                      ? '✓ OK'
                                      : '✗ ${parser.validation.name}',
                                ),
                                HealthIndicator(
                                  label: 'Cache',
                                  ok: !usage.isFromCache,
                                  detail: usage.isFromCache
                                      ? 'Using LKG'
                                      : '✓ Fresh',
                                ),
                                InfoRow(
                                  label: 'Last error',
                                  value: error?.message ?? 'None',
                                  valueColor: error == null
                                      ? context.colors.textMuted
                                      : context.colors.error,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    TerminalPanel(
                      title: 'Status',
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Status',
                            value: '● ${UsageStatusMapper.label(displayKind)}',
                          ),
                          InfoRow(
                            label: 'Source',
                            value: dashboardData.status.sourceLabel,
                          ),
                          InfoRow(
                            label: 'Updated',
                            value: UsageStatusMapper.relativeUpdated(
                              status.lastSuccessAt ?? usage.fetchedAt,
                            ),
                          ),
                          InfoRow(label: 'Mode', value: mode),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TerminalPanel(
                      title: 'Provider Health',
                      child: Column(
                        children: [
                          if (dashboardData.capabilities.healthCheck)
                            HealthIndicator(label: 'Auth', ok: authOk),
                          HealthIndicator(label: 'Parser', ok: parserOk),
                          HealthIndicator(
                            label: 'Cache',
                            ok: !usage.isFromCache,
                            detail: usage.isFromCache ? 'LKG' : '✓ Fresh',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (outcome == RefreshOutcome.softFailure) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      dashboardData.limitsUnavailableMessage,
                      style: context.typography.caption,
                    ),
                  ],
                  if (outcome == RefreshOutcome.failure && error != null) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(error.message, style: context.typography.error),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static List<double> _sparkFromPercent(double percent) {
    final base = percent.clamp(5.0, 100.0);
    return <double>[
      base * 0.45,
      base * 0.55,
      base * 0.4,
      base * 0.7,
      base * 0.65,
      base * 0.85,
      base,
    ];
  }
}
