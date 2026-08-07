import 'dart:async';

import 'package:ai_tray/core/components/confirmation_dialog.dart';
import 'package:ai_tray/core/components/empty_state.dart';
import 'package:ai_tray/core/components/inline_help.dart';
import 'package:ai_tray/core/components/queue_status_chip.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/sliver_page_scaffold.dart';
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

    return SliverPageScaffold(
      title: 'Queue',
      actions: [
        InlineHelp(
          message:
              'Tasks run one at a time, in the background. Nothing '
              'executes until you press Run next — queuing a task '
              'never starts it on its own.',
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: context.colors.textMuted,
          ),
        ),
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
      slivers: [
        itemsAsync.when(
          loading: () => SliverFillRemaining(
            child: Center(
              child: Semantics(
                label: 'Loading resume queue',
                child: const CircularProgressIndicator(
                  key: ValueKey('queue-loading'),
                ),
              ),
            ),
          ),
          error: (error, stackTrace) => SliverFillRemaining(
            child: Center(
              child: Semantics(
                label: 'Could not load the resume queue',
                child: Text(
                  'Could not load the resume queue',
                  key: const ValueKey('queue-error'),
                  style: context.typography.body,
                ),
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SliverFillRemaining(
                child: _QueueEmptyState(key: ValueKey('queue-empty')),
              );
            }
            final active = items
                .where(
                  (i) =>
                      i.status == ResumeQueueStatus.pending ||
                      i.status == ResumeQueueStatus.running,
                )
                .toList();
            final history = items
                .where(
                  (i) =>
                      i.status != ResumeQueueStatus.pending &&
                      i.status != ResumeQueueStatus.running,
                )
                .toList();
            return SliverPadding(
              padding: const EdgeInsets.all(Spacing.md),
              sliver: SliverSemantics(
                container: true,
                label:
                    'Resume queue, ${items.length} '
                    '${items.length == 1 ? 'item' : 'items'}',
                sliver: SliverList.list(
                  key: const ValueKey('queue-list'),
                  children: [
                    for (final item in active)
                      _QueueItemTile(
                        key: ValueKey('queue-item-${item.id}'),
                        item: item,
                        onCancel: item.status == ResumeQueueStatus.pending
                            ? () => unawaited(_cancel(context, notifier, item))
                            : null,
                        onRemove: item.status == ResumeQueueStatus.running
                            ? null
                            : () => unawaited(notifier.remove(item.id)),
                        onRetry: item.status == ResumeQueueStatus.failed
                            ? () => unawaited(notifier.retry(item.id))
                            : null,
                      ),
                    if (history.isNotEmpty) ...[
                      if (active.isNotEmpty) const SizedBox(height: Spacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.xs,
                        ),
                        child: Text(
                          'History',
                          style: context.typography.section,
                        ),
                      ),
                      for (final item in history)
                        _QueueItemTile(
                          key: ValueKey('queue-item-${item.id}'),
                          item: item,
                          onRemove: () => unawaited(notifier.remove(item.id)),
                          onRetry: item.status == ResumeQueueStatus.failed
                              ? () => unawaited(notifier.retry(item.id))
                              : null,
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Confirms before cancelling a pending item (V4 §6.1) — cancelling keeps
/// it in the list (as `cancelled`, for history) rather than deleting it,
/// so a confirmation is worth the click unlike a plain list refresh.
Future<void> _cancel(
  BuildContext context,
  ResumeQueueController notifier,
  ResumeQueueItem item,
) async {
  final confirmed = await showConfirmationDialog(
    context,
    title: 'Cancel this task?',
    body: "It'll move to History as cancelled instead of running.",
    confirmLabel: 'Cancel task',
  );
  if (confirmed) await notifier.cancel(item.id);
}

final class _QueueItemTile extends StatelessWidget {
  const _QueueItemTile({
    required this.item,
    required this.onRemove,
    required this.onRetry,
    super.key,
    this.onCancel,
  });

  final ResumeQueueItem item;

  /// Non-null only for a `pending` item — marks it `cancelled` instead of
  /// deleting it (V4 §6.1). Takes precedence over [onRemove] in the UI
  /// when both would otherwise apply to the same pending item.
  final VoidCallback? onCancel;

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
                if (onCancel != null)
                  IconButton(
                    key: ValueKey('queue-cancel-${item.id}'),
                    tooltip: 'Cancel',
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                  )
                else
                  IconButton(
                    key: ValueKey('queue-remove-${item.id}'),
                    tooltip: 'Remove',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              truncatePath(item.cwd),
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
    return const EmptyState(
      icon: Icons.pending_actions_outlined,
      title: 'No queued tasks',
      body: "Queue a task from a session's detail page.",
    );
  }
}
