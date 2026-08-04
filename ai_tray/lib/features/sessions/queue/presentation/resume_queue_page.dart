import 'dart:async';

import 'package:ai_tray/core/components/queue_status_chip.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_project_grouping.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resume Queue page (Feature 2.2.2; V3 redesign) — renders pending/
/// running/succeeded/failed items with live updates, a project label
/// (from each item's working directory) instead of a raw session id, and
/// a Retry action for failed items. Enqueuing never triggers execution on
/// its own; "Run next" is the only way an item moves forward in this pass
/// (see `ResumeQueueController`'s own doc comment for why there's no
/// auto-execute toggle yet).
final class ResumeQueuePage extends ConsumerStatefulWidget {
  const ResumeQueuePage({super.key});

  @override
  ConsumerState<ResumeQueuePage> createState() => _ResumeQueuePageState();
}

final class _ResumeQueuePageState extends ConsumerState<ResumeQueuePage> {
  Timer? _liveUpdateTimer;

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  // Live updates (V3): the queue has no push/stream signal of its own (a
  // single sequential CLI executor), so a light poll is the smallest
  // change that keeps Running/Duration current without a bigger
  // architecture change. Gated on this actually being the *visible* shell
  // destination — not just mounted — since the shell keeps every
  // destination alive in an `IndexedStack`; polling unconditionally on
  // mount would poll forever in the background, even while looking at the
  // Dashboard.
  void _syncLiveUpdates(bool isVisible) {
    if (isVisible) {
      _liveUpdateTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
        final notifier = ref.read(resumeQueueControllerProvider.notifier);
        if (!ref.read(resumeQueueControllerProvider).isLoading) {
          unawaited(notifier.refresh());
        }
      });
    } else {
      _liveUpdateTimer?.cancel();
      _liveUpdateTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisible =
        ref.watch(appShellDestinationProvider) == AppDestination.queue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLiveUpdates(isVisible);
    });

    final itemsAsync = ref.watch(resumeQueueControllerProvider);
    final notifier = ref.read(resumeQueueControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          IconButton(
            key: const ValueKey('queue-run-next'),
            tooltip: 'Run next',
            onPressed: itemsAsync.isLoading
                ? null
                : () => unawaited(notifier.runNext()),
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: itemsAsync.isLoading
                ? null
                : () => unawaited(notifier.refresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: ValueKey('queue-loading')),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Could not load the resume queue',
            key: const ValueKey('queue-error'),
            style: context.typography.body,
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _QueueEmptyState(key: ValueKey('queue-empty'));
          }
          return ListView.builder(
            key: const ValueKey('queue-list'),
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) => _QueueItemTile(
              item: items[index],
              onRemove: items[index].status == ResumeQueueStatus.running
                  ? null
                  : () => unawaited(notifier.remove(items[index].id)),
              onRetry: items[index].status == ResumeQueueStatus.failed
                  ? () => unawaited(notifier.retry(items[index].id))
                  : null,
            ),
          );
        },
      ),
    );
  }
}

final class _QueueItemTile extends StatelessWidget {
  const _QueueItemTile({
    required this.item,
    required this.onRemove,
    required this.onRetry,
  });

  final ResumeQueueItem item;

  /// `null` when this item can't be removed yet (currently `running` —
  /// there's no cooperative cancellation of an in-flight resume).
  final VoidCallback? onRemove;

  /// `null` unless this item is `failed`.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final projectName = projectDisplayName(
      projectPath: item.cwd,
      sanitizedProjectDirName: item.cwd,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    projectName,
                    style: type.body.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                QueueStatusChip(status: item.status),
                if (onRetry != null)
                  IconButton(
                    key: ValueKey('queue-retry-${item.id}'),
                    tooltip: 'Retry',
                    onPressed: onRetry,
                    icon: const Icon(Icons.replay),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  key: ValueKey('queue-remove-${item.id}'),
                  tooltip: item.status == ResumeQueueStatus.pending
                      ? 'Cancel'
                      : 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              item.cwd,
              style: type.caption,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.xs),
            Text(item.prompt, style: type.caption, maxLines: 2),
            const SizedBox(height: Spacing.xs),
            Text(_summaryLine(item), style: type.caption),
          ],
        ),
      ),
    );
  }

  String _summaryLine(ResumeQueueItem item) {
    final cap = 'Cap \$${item.maxBudgetUsd.toStringAsFixed(2)}';
    final duration = _durationLabel(item);
    final outcome = item.result;
    final parts = [
      cap,
      ?duration,
      if (outcome != null) 'cost \$${outcome.costUsd.toStringAsFixed(4)}',
    ];
    return parts.join(' · ');
  }

  String? _durationLabel(ResumeQueueItem item) {
    final startedAt = item.startedAt;
    if (startedAt == null) return null;
    final end = item.executedAt ?? DateTime.now().toUtc();
    final elapsed = end.difference(startedAt);
    final label = _formatDuration(elapsed);
    return item.status == ResumeQueueStatus.running ? 'running $label' : label;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${duration.inSeconds}s';
  }
}

final class _QueueEmptyState extends StatelessWidget {
  const _QueueEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No queued tasks', style: type.emptyTitle),
            const SizedBox(height: Spacing.sm),
            Text(
              "Queue a task from a session's detail page.",
              style: type.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
