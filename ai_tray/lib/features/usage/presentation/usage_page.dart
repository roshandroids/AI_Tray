import 'dart:async';

import 'package:ai_tray/core/components/metric_card.dart';
import 'package:ai_tray/core/components/page_header.dart';
import 'package:ai_tray/core/components/queue_status_chip.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/session_card.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/theme/breakpoints.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/presentation/widgets/provider_selector.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_controller.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:ai_tray/features/usage/domain/services/dashboard_coach.dart';
import 'package:ai_tray/features/usage/domain/services/dashboard_data_mapper.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-system dashboard (PD-021), hosted as the Dashboard destination in
/// the app shell — navigation to Sessions/Queue/Logs/Settings and the
/// ⌘R/⌘L/⌘, shortcuts live on the shell now, not here.
final class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(usageRepositoryProvider);
    final selectableProviders = ref.watch(selectableAIProvidersProvider);
    final selectedProvider = ref.watch(selectedAIProviderProvider);
    final selectionAsync = ref.watch(selectedProviderIdProvider);
    final selectionNotifier = ref.read(selectedProviderIdProvider.notifier);
    final selectionBusy = selectionAsync.isLoading;
    final selectionFailure = selectionNotifier.lastPersistenceFailure;

    return StreamBuilder<RefreshStatus>(
      stream: repository.watchStatus(),
      initialData: repository.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? RefreshStatus.initial();
        final visibleResult =
            status.lastResult?.providerId == selectedProvider.providerId
            ? status.lastResult
            : null;
        final usage = visibleResult?.usage;
        final error = visibleResult?.error;
        final refreshing = status.phase == RefreshPhase.refreshing;
        final kind = UsageStatusMapper.kind(status);

        return Scaffold(
          body: Column(
            children: [
              PageHeader(
                title: 'AI Tray',
                actions: [
                  ProviderSelector(
                    providers: selectableProviders,
                    selectedId: selectedProvider.providerId,
                    enabled: !selectionBusy,
                    onSelected: (providerId) async {
                      final changed = await ref
                          .read(selectedProviderIdProvider.notifier)
                          .select(providerId);
                      if (changed) {
                        await repository.refresh(manual: true);
                      }
                    },
                  ),
                  Center(child: StatusBadge(kind: kind, compact: true)),
                  IconButton(
                    tooltip: 'Diagnostics',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DiagnosticsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.monitor_heart_outlined),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    // Scales with window width (V4 §3.1) instead of a flat
                    // 720px cap, so wide/ultrawide monitors don't carry a
                    // large dead margin either side of the dashboard.
                    constraints: BoxConstraints(
                      maxWidth: switch (windowSizeOf(context)) {
                        WindowSize.compact => Spacing.contentMaxWidth,
                        WindowSize.wide => 960,
                        WindowSize.ultrawide => 1200,
                      },
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
                          if (selectionFailure != null) ...[
                            _DashboardStatusNotice(
                              icon: Icons.save_outlined,
                              message:
                                  '${selectionFailure.message}. '
                                  'Selection is active in memory — '
                                  'tap Retry to save.',
                              color: context.colors.warning,
                              actionLabel: 'Retry',
                              onAction: () => unawaited(
                                ref
                                    .read(selectedProviderIdProvider.notifier)
                                    .retryPersistence(),
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                          ],
                          _CoachBanner(
                            usage: usage,
                            isProviderError: kind == TrayStatusKind.error,
                          ),
                          const _ContinueYourWorkSection(),
                          const SizedBox(height: Spacing.md),
                          _ProviderHeader(
                            key: ValueKey(
                              'provider-header-${selectedProvider.providerId.value}',
                            ),
                            provider: selectedProvider,
                            status: status,
                          ),
                          const SizedBox(height: Spacing.sm),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration:
                                  MediaQuery.maybeOf(
                                        context,
                                      )?.disableAnimations ??
                                      false
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: usage == null
                                  ? refreshing
                                        ? _DashboardSkeleton(
                                            key: ValueKey(
                                              'dashboard-skeleton-'
                                              '${selectedProvider.providerId.value}',
                                            ),
                                          )
                                        : SingleChildScrollView(
                                            key: ValueKey(
                                              'dashboard-empty-'
                                              '${selectedProvider.providerId.value}',
                                            ),
                                            child: TrayEmptyState(
                                              failure: error,
                                              provider: selectedProvider,
                                            ),
                                          )
                                  : _DashboardBody(
                                      key: ValueKey(
                                        'dashboard-'
                                        '${selectedProvider.providerId.value}',
                                      ),
                                      usage: usage,
                                      status: status,
                                      kind: kind,
                                      provider: selectedProvider,
                                    ),
                            ),
                          ),
                          const SectionDivider(),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '⌘K Commands · ⌘R Refresh · ⌘L Logs · ⌘, Settings',
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
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Work-first block (V3 redesign): quick actions plus at-a-glance recent
/// sessions and queue state, ahead of the usage/health metrics below.
final class _ContinueYourWorkSection extends ConsumerWidget {
  const _ContinueYourWorkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionBrowserControllerProvider);
    final queueAsync = ref.watch(resumeQueueControllerProvider);
    final recentSessions = sessionsAsync.value ?? const <SessionSummary>[];
    final recentQueue = queueAsync.value ?? const <ResumeQueueItem>[];
    final lastSessionId = recentSessions.isEmpty
        ? null
        : recentSessions.first.sessionId;

    void goToSessions() => ref
        .read(appShellDestinationProvider.notifier)
        .select(
          AppDestination.sessions,
        );
    void goToQueue() => ref
        .read(appShellDestinationProvider.notifier)
        .select(
          AppDestination.queue,
        );
    void openSession(String sessionId) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionDetailPage(sessionId: sessionId),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: lastSessionId == null
                    ? null
                    : () => openSession(lastSessionId),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('Continue last session'),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: goToSessions,
                icon: const Icon(Icons.pending_actions_outlined, size: 18),
                label: const Text('Queue a task'),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final sessionsCard = _RecentSessionsCard(
              sessions: recentSessions,
              onOpenSession: openSession,
              onViewAll: goToSessions,
            );
            final queueCard = _RecentQueueCard(
              items: recentQueue,
              onOpenSession: openSession,
              onViewAll: goToQueue,
            );
            if (constraints.maxWidth >= 560) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: sessionsCard),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: queueCard),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sessionsCard,
                const SizedBox(height: Spacing.sm),
                queueCard,
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Productivity Coach v1 (V4 §3.2) — surfaces the single highest-priority
/// situational message for the current dashboard state, or nothing.
final class _CoachBanner extends ConsumerWidget {
  const _CoachBanner({required this.usage, required this.isProviderError});

  final UsageInfo? usage;
  final bool isProviderError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueItems =
        ref.watch(resumeQueueControllerProvider).value ?? const [];
    final settings = ref.watch(settingsControllerProvider).value;
    final message = selectCoachMessage(
      isProviderError: isProviderError,
      usage: usage,
      queueItems: queueItems,
      notificationsEnabled: settings?.notificationsEnabled ?? true,
    );
    if (message == null) return const SizedBox.shrink();

    final colors = context.colors;
    final (icon, color) = switch (message.kind) {
      CoachKind.info => (Icons.info_outline, colors.info),
      CoachKind.warning => (Icons.warning_amber_outlined, colors.warning),
      CoachKind.error => (Icons.error_outline, colors.error),
      CoachKind.queue => (Icons.pending_actions_outlined, colors.info),
      CoachKind.notificationsOff => (
        Icons.notifications_off_outlined,
        colors.textSecondary,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: _DashboardStatusNotice(
        icon: icon,
        message: message.text,
        color: color,
      ),
    );
  }
}

final class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({
    required this.sessions,
    required this.onOpenSession,
    required this.onViewAll,
  });

  final List<SessionSummary> sessions;
  final ValueChanged<String> onOpenSession;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final recent = sessions.take(3).toList();
    return SectionCard(
      title: 'Recent Sessions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Text('No sessions yet', style: type.caption),
            )
          else
            for (final (index, session) in recent.indexed) ...[
              SessionCard(
                primaryText:
                    session.projectPath ?? session.sanitizedProjectDirName,
                secondaryText: UsageStatusMapper.relativeUpdated(
                  session.lastActivityAt,
                ),
                live: session.isLive ?? false,
                onTap: () => onOpenSession(session.sessionId),
              ),
              if (index < recent.length - 1) const Divider(height: Spacing.md),
            ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('View all'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _RecentQueueCard extends StatelessWidget {
  const _RecentQueueCard({
    required this.items,
    required this.onOpenSession,
    required this.onViewAll,
  });

  final List<ResumeQueueItem> items;
  final ValueChanged<String> onOpenSession;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final recent = items.take(3).toList();
    return SectionCard(
      title: 'Queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Text('No queued tasks', style: type.caption),
            )
          else
            for (final (index, item) in recent.indexed) ...[
              InkWell(
                onTap: () => onOpenSession(item.sessionId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.prompt,
                          style: type.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      QueueStatusChip(status: item.status),
                    ],
                  ),
                ),
              ),
              if (index < recent.length - 1) const Divider(height: Spacing.md),
            ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('View all'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _DashboardStatusNotice extends StatelessWidget {
  const _DashboardStatusNotice({
    required this.icon,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.typography.caption.copyWith(color: color),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: Spacing.sm),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: context.typography.label.copyWith(color: color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({
    required this.provider,
    required this.status,
    super.key,
  });

  final AIProvider provider;
  final RefreshStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = UsageStatusMapper.kind(status);
    final healthColor = switch (kind) {
      TrayStatusKind.live => colors.success,
      TrayStatusKind.cached => colors.warning,
      TrayStatusKind.refreshing => colors.info,
      TrayStatusKind.error => colors.error,
      TrayStatusKind.idle => colors.textMuted,
    };
    final lastRefresh = UsageStatusMapper.relativeUpdated(
      status.lastSuccessAt ?? status.lastResult?.usage?.fetchedAt,
    );

    return Semantics(
      container: true,
      label:
          '${provider.displayName} provider, '
          '${UsageStatusMapper.label(kind)}, last refreshed $lastRefresh',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.sm),
                    child: Icon(
                      provider.providerId == ProviderId.copilot
                          ? Icons.code_rounded
                          : Icons.auto_awesome_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: context.typography.section,
                          ),
                        ),
                        if (provider.providerId == ProviderId.copilot) ...[
                          const SizedBox(width: Spacing.sm),
                          _ExperimentalBadge(color: colors.warning),
                        ],
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Last refreshed $lastRefresh',
                      style: context.typography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: healthColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        UsageStatusMapper.label(kind),
                        style: context.typography.status.copyWith(
                          color: healthColor,
                        ),
                      ),
                    ],
                  ),
                  if (kind == TrayStatusKind.refreshing) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Updating metrics…',
                      style: context.typography.caption,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ExperimentalBadge extends StatelessWidget {
  const _ExperimentalBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: 2,
        ),
        child: Text(
          'EXPERIMENTAL',
          style: context.typography.caption.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

final class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading usage metrics',
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SkeletonCard(),
            SizedBox(height: Spacing.sm),
            _SkeletonCard(),
            SizedBox(height: Spacing.md),
            _SkeletonPanel(),
          ],
        ),
      ),
    );
  }
}

final class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: Spacing.progressRingSize,
                height: Spacing.progressRingSize,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Spacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(widthFactor: 0.45),
                    SizedBox(height: Spacing.sm),
                    _SkeletonLine(widthFactor: 0.7),
                    SizedBox(height: Spacing.sm),
                    _SkeletonLine(widthFactor: 0.55),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: context.colors.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonLine(widthFactor: 0.3),
              SizedBox(height: Spacing.md),
              _SkeletonLine(widthFactor: 0.8),
              SizedBox(height: Spacing.sm),
              _SkeletonLine(widthFactor: 0.65),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: context.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
      ),
    );
  }
}

/// Deep-links from a dashboard health row into Diagnostics' health panel
/// (V4 §3.3) instead of requiring the Diagnostics page for all detail.
void _openDiagnosticsHealth(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DiagnosticsPage(scrollToHealth: true),
    ),
  );
}

final class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.usage,
    required this.status,
    required this.kind,
    required this.provider,
    super.key,
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
        final statusValue = '● ${UsageStatusMapper.label(displayKind)}';
        final mode = settings == null
            ? '—'
            : settings.autoRefreshEnabled
            ? 'Auto ${settings.refreshInterval.inSeconds}s'
            : 'Manual';
        final parserOk = parser?.validation == ValidationStatus.valid;
        final authOk = kind != TrayStatusKind.error;

        final metricCards = dashboardData.metrics.isEmpty
            ? const [
                MetricCard(
                  key: ValueKey('usage-unavailable'),
                  label: 'Usage',
                  percent: 0,
                  available: false,
                ),
              ]
            : [
                for (final metric in dashboardData.metrics)
                  MetricCard(
                    key: ValueKey(metric.key),
                    label: metric.label,
                    percent: metric.usedPercent,
                    resetsAtRaw: metric.resetsAtRaw,
                    value: metric.value,
                    total: metric.total,
                    unit: metric.unit,
                    remainingPercent: metric.remainingPercent,
                    unlimited: metric.unlimited,
                    refreshing: dashboardData.status.isRefreshing,
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
                          child: SectionCard(
                            title: 'Status',
                            child: Column(
                              children: [
                                InfoRow(
                                  label: 'Status',
                                  value: statusValue,
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
                          child: InkWell(
                            onTap: () => _openDiagnosticsHealth(context),
                            child: SectionCard(
                              title: 'Provider Health',
                              child: Column(
                                children: [
                                  if (dashboardData.capabilities.healthCheck)
                                    HealthIndicator(
                                      label: 'Auth',
                                      ok: authOk,
                                    ),
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
                        ),
                      ],
                    )
                  else ...[
                    SectionCard(
                      title: 'Status',
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Status',
                            value: statusValue,
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
                    InkWell(
                      onTap: () => _openDiagnosticsHealth(context),
                      child: SectionCard(
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
                    ),
                  ],
                  if (outcome == RefreshOutcome.softFailure) ...[
                    const SizedBox(height: Spacing.sm),
                    _DashboardStatusNotice(
                      icon: Icons.history_rounded,
                      message:
                          'Showing saved usage. '
                          '${dashboardData.limitsUnavailableMessage}',
                      color: context.colors.warning,
                    ),
                  ],
                  if (outcome == RefreshOutcome.failure && error != null) ...[
                    const SizedBox(height: Spacing.sm),
                    _DashboardStatusNotice(
                      icon: Icons.error_outline_rounded,
                      message:
                          'Refresh failed. Showing the last available usage. '
                          '${error.message}',
                      color: context.colors.error,
                    ),
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
