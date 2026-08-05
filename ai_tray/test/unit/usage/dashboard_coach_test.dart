import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/services/dashboard_coach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UsageInfo usage({double sessionUsedPercent = 10}) {
    return UsageInfo(
      sessionUsedPercent: sessionUsedPercent,
      fetchedAt: DateTime.utc(2026, 7, 12),
      source: UsageSource.cli,
      isFromCache: false,
      providerId: ProviderId.claude,
    );
  }

  ResumeQueueItem queueItem(String id, ResumeQueueStatus status) {
    return ResumeQueueItem(
      id: id,
      sessionId: 's-$id',
      cwd: '/x',
      prompt: 'p',
      maxBudgetUsd: 1,
      createdAt: DateTime.utc(2026, 7, 31),
      status: status,
    );
  }

  test('returns null when nothing is worth surfacing', () {
    final message = selectCoachMessage(
      isProviderError: false,
      usage: usage(),
      queueItems: const [],
      notificationsEnabled: true,
    );

    expect(message, isNull);
  });

  test('a provider error outranks every other situation', () {
    final message = selectCoachMessage(
      isProviderError: true,
      usage: usage(sessionUsedPercent: 99),
      queueItems: [queueItem('1', ResumeQueueStatus.failed)],
      notificationsEnabled: false,
    );

    expect(message?.kind, CoachKind.error);
  });

  test('near-exhausted usage outranks failed queue items', () {
    final message = selectCoachMessage(
      isProviderError: false,
      usage: usage(sessionUsedPercent: 95),
      queueItems: [queueItem('1', ResumeQueueStatus.failed)],
      notificationsEnabled: true,
    );

    expect(message?.kind, CoachKind.warning);
  });

  test('failed queue items outrank notifications-off', () {
    final message = selectCoachMessage(
      isProviderError: false,
      usage: usage(sessionUsedPercent: 85),
      queueItems: [queueItem('1', ResumeQueueStatus.failed)],
      notificationsEnabled: false,
    );

    expect(message?.kind, CoachKind.queue);
    expect(message?.text, contains('failed'));
  });

  test('notifications-off while usage is high outranks idle pending work', () {
    final message = selectCoachMessage(
      isProviderError: false,
      usage: usage(sessionUsedPercent: 80),
      queueItems: [queueItem('1', ResumeQueueStatus.pending)],
      notificationsEnabled: false,
    );

    expect(message?.kind, CoachKind.notificationsOff);
  });

  test('pending work with nothing running surfaces a queue nudge', () {
    final message = selectCoachMessage(
      isProviderError: false,
      usage: usage(),
      queueItems: [queueItem('1', ResumeQueueStatus.pending)],
      notificationsEnabled: true,
    );

    expect(message?.kind, CoachKind.queue);
    expect(message?.text, contains('waiting'));
  });

  test('pending work is not flagged while an item is already running', () {
    final message = selectCoachMessage(
      isProviderError: false,
      usage: usage(),
      queueItems: [
        queueItem('1', ResumeQueueStatus.pending),
        queueItem('2', ResumeQueueStatus.running),
      ],
      notificationsEnabled: true,
    );

    expect(message, isNull);
  });
}
