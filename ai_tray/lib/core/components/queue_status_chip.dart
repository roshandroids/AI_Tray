import 'package:ai_tray/core/components/status_presentation.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:flutter/material.dart';

/// Compact status chip for a queued resume — shared by the Resume Queue
/// page and the Dashboard's queue glance so the two never drift apart.
final class QueueStatusChip extends StatelessWidget {
  const QueueStatusChip({required this.status, super.key});

  final ResumeQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = StatusPresentation.fromResumeQueueStatus(
      status,
      context.colors,
    );
    final label = presentation.label;
    final color = presentation.color;
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
