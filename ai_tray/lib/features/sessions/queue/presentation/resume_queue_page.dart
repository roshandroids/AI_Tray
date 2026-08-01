import 'dart:async';

import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resume Queue page (Feature 2.2.2) — renders pending/running/succeeded/
/// failed items. Enqueuing never triggers execution on its own; "Run
/// next" is the only way an item moves forward in this pass (see
/// `ResumeQueueController`'s own doc comment for why there's no
/// auto-execute toggle yet).
final class ResumeQueuePage extends ConsumerWidget {
  const ResumeQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(resumeQueueControllerProvider);
    final notifier = ref.read(resumeQueueControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Queue'),
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
            itemBuilder: (context, index) => _QueueItemTile(item: items[index]),
          );
        },
      ),
    );
  }
}

final class _QueueItemTile extends StatelessWidget {
  const _QueueItemTile({required this.item});

  final ResumeQueueItem item;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
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
                    item.sessionId,
                    style: type.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                _QueueStatusChip(status: item.status),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(item.prompt, style: type.caption, maxLines: 2),
            const SizedBox(height: Spacing.xs),
            Text(
              _capAndCostLabel(item),
              style: type.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _capAndCostLabel(ResumeQueueItem item) {
    final cap = 'Cap \$${item.maxBudgetUsd.toStringAsFixed(2)}';
    final outcome = item.result;
    if (outcome == null) return cap;
    return '$cap · cost \$${outcome.costUsd.toStringAsFixed(4)}';
  }
}

final class _QueueStatusChip extends StatelessWidget {
  const _QueueStatusChip({required this.status});

  final ResumeQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, color) = switch (status) {
      ResumeQueueStatus.pending => ('Pending', colors.textMuted),
      ResumeQueueStatus.running => ('Running', colors.info),
      ResumeQueueStatus.succeeded => ('Succeeded', colors.success),
      ResumeQueueStatus.failed => ('Failed', colors.error),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Text(
          label,
          key: ValueKey('queue-status-${status.name}'),
          style: context.typography.status.copyWith(color: color),
        ),
      ),
    );
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
            Text('No queued resumes', style: type.emptyTitle),
            const SizedBox(height: Spacing.sm),
            Text(
              'Add a session to the queue from its detail page.',
              style: type.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
