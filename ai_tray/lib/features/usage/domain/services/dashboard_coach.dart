import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:meta/meta.dart';

/// Broad category of a [CoachMessage] — the presentation layer maps this
/// to a concrete icon/color; this file stays Flutter-free.
enum CoachKind { info, warning, error, queue, notificationsOff }

/// A single situational message the Productivity Coach can surface (V4
/// §3.2). [selectCoachMessage] only ever returns the single
/// highest-priority message for the current state, never a list, so the
/// dashboard shows at most one banner.
@immutable
final class CoachMessage {
  const CoachMessage({required this.kind, required this.text});

  final CoachKind kind;
  final String text;
}

/// Evaluates dashboard state and returns the single highest-priority
/// situational message, or `null` if nothing is worth surfacing right now.
///
/// Priority (most urgent first): provider unreachable, usage exhausted,
/// failed queue items, notifications disabled while usage is high, queue
/// idle with pending work. Each input already exists elsewhere in the app
/// (health checks, `ResumeQueueRepository`, settings) — this is a pure
/// synthesis function, not new data plumbing.
CoachMessage? selectCoachMessage({
  required bool isProviderError,
  required UsageInfo? usage,
  required List<ResumeQueueItem> queueItems,
  required bool notificationsEnabled,
}) {
  if (isProviderError) {
    return const CoachMessage(
      kind: CoachKind.error,
      text: "Can't reach the provider right now. Check Diagnostics.",
    );
  }

  final sessionPercent = usage?.sessionUsedPercent;
  if (sessionPercent != null && sessionPercent >= 95) {
    final reset = usage?.sessionResetsAtRaw?.trim();
    final resetSuffix = (reset == null || reset.isEmpty)
        ? ''
        : ' · resets $reset';
    return CoachMessage(
      kind: CoachKind.warning,
      text: 'Session usage is almost exhausted$resetSuffix.',
    );
  }

  final failedCount = queueItems
      .where((item) => item.status == ResumeQueueStatus.failed)
      .length;
  if (failedCount > 0) {
    return CoachMessage(
      kind: CoachKind.queue,
      text:
          '$failedCount queued task${failedCount == 1 ? '' : 's'} failed — '
          'review and retry.',
    );
  }

  if (!notificationsEnabled &&
      sessionPercent != null &&
      sessionPercent >= 80) {
    return const CoachMessage(
      kind: CoachKind.notificationsOff,
      text: 'Notifications are off — enable them in Settings to catch a reset.',
    );
  }

  final pendingCount = queueItems
      .where((item) => item.status == ResumeQueueStatus.pending)
      .length;
  final hasRunning = queueItems.any(
    (item) => item.status == ResumeQueueStatus.running,
  );
  if (pendingCount > 0 && !hasRunning) {
    return CoachMessage(
      kind: CoachKind.queue,
      text:
          '$pendingCount task${pendingCount == 1 ? '' : 's'} waiting in the '
          'queue — run next when ready.',
    );
  }

  return null;
}
