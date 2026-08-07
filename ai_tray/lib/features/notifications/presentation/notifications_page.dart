import 'dart:async';

import 'package:ai_tray/core/components/confirmation_dialog.dart';
import 'package:ai_tray/core/components/empty_state.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/sliver_page_scaffold.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/notifications/presentation/notification_history_controller.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only record of every notification the app has shown (V4 §9.4) —
/// pushed from Settings' Notifications section, not a shell destination
/// (Section 2.3 rule: drill-downs stay pushed).
final class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(notificationHistoryControllerProvider);
    final notifier = ref.read(notificationHistoryControllerProvider.notifier);

    return SliverPageScaffold(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: entriesAsync.isLoading
              ? null
              : () => unawaited(notifier.refresh()),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Clear history',
          onPressed: entriesAsync.value?.isEmpty ?? true
              ? null
              : () => unawaited(_clear(context, notifier)),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      slivers: [
        entriesAsync.when(
          loading: () => SliverFillRemaining(
            child: Center(
              child: Semantics(
                label: 'Loading notification history',
                child: const CircularProgressIndicator(
                  key: ValueKey('notifications-loading'),
                ),
              ),
            ),
          ),
          error: (error, stackTrace) => SliverFillRemaining(
            child: Center(
              child: Semantics(
                label: "Couldn't load notification history",
                child: Text(
                  "Couldn't load notification history",
                  key: const ValueKey('notifications-error'),
                  style: context.typography.body,
                ),
              ),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const SliverFillRemaining(
                child: EmptyState(
                  key: ValueKey('notifications-empty'),
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications yet',
                  body:
                      'Notifications the app shows — usage alerts, queued '
                      'task results — appear here.',
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.all(Spacing.md),
              sliver: SliverSemantics(
                container: true,
                label:
                    'Notification history, ${entries.length} '
                    '${entries.length == 1 ? 'entry' : 'entries'}',
                sliver: SliverList.builder(
                  key: const ValueKey('notifications-list'),
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _NotificationTile(entry: entries[index]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _clear(
    BuildContext context,
    NotificationHistoryController notifier,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Clear notification history?',
      body: 'This removes every recorded entry. It cannot be undone.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed) await notifier.clear();
  }
}

final class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.entry});

  final NotificationHistoryEntry entry;

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
                    entry.title,
                    style: type.body.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  UsageStatusMapper.relativeUpdated(entry.sentAt),
                  style: type.caption,
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(entry.body, style: type.caption),
          ],
        ),
      ),
    );
  }
}
