import 'dart:async';

import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_browser_controller.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_list_filter.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_page.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session Browser list page (Feature 1.2.1; M1 "Session Visibility").
///
/// Renders entirely from `SessionBrowserController`'s JSONL-derived list —
/// no mutation, no CLI action beyond the read-only liveness enrichment the
/// repository already merged in (design principle 3 — the CLI's live
/// registry is enrichment only, never load-bearing for this list).
final class SessionBrowserPage extends ConsumerStatefulWidget {
  const SessionBrowserPage({super.key});

  @override
  ConsumerState<SessionBrowserPage> createState() => _SessionBrowserPageState();
}

final class _SessionBrowserPageState extends ConsumerState<SessionBrowserPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionBrowserControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(
            tooltip: 'Resume Queue',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ResumeQueuePage()),
            ),
            icon: const Icon(Icons.pending_actions_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: sessionsAsync.isLoading
                ? null
                : () => unawaited(
                    ref
                        .read(sessionBrowserControllerProvider.notifier)
                        .refresh(),
                  ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
            ),
            child: TextField(
              key: const ValueKey('sessions-search-field'),
              controller: _search,
              style: context.typography.body,
              decoration: const InputDecoration(
                hintText: 'Filter by project path…',
                prefixIcon: Icon(Icons.search, size: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('sessions-loading'),
                ),
              ),
              error: (error, stackTrace) => _SessionListError(error: error),
              data: (sessions) {
                final filtered = filterSessionsByProjectPath(
                  sessions,
                  _search.text,
                );
                if (sessions.isEmpty) {
                  return const _SessionListEmptyState(
                    key: ValueKey('sessions-empty'),
                  );
                }
                if (filtered.isEmpty) {
                  return const _SessionListEmptyState(
                    key: ValueKey('sessions-no-match'),
                    noMatch: true,
                  );
                }
                return ListView.builder(
                  key: const ValueKey('sessions-list'),
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _SessionListTile(summary: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _SessionListTile extends StatelessWidget {
  const _SessionListTile({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final projectLabel = summary.projectPath ?? summary.sanitizedProjectDirName;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionDetailPage(sessionId: summary.sessionId),
          ),
        ),
        child: SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectLabel,
                      style: type.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${UsageStatusMapper.relativeUpdated(
                        summary.lastActivityAt,
                      )} · ${summary.messageCount} messages',
                      style: type.caption,
                    ),
                  ],
                ),
              ),
              // A live badge appears only when `agents --json --all`
              // matched this session — absence (false or unconfirmed) is
              // never shown as "not live" (design principle 3): there is
              // no visual distinction between false and null.
              if (summary.isLive ?? false) ...[
                const SizedBox(width: Spacing.sm),
                const StatusBadge(kind: TrayStatusKind.live, compact: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _SessionListEmptyState extends StatelessWidget {
  const _SessionListEmptyState({super.key, this.noMatch = false});

  final bool noMatch;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final title = noMatch ? 'No sessions match this filter' : 'No sessions yet';
    final body = noMatch
        ? 'Clear the search to see every session.'
        : 'Sessions appear here once you use Claude Code in a project.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Semantics(
          container: true,
          label: '$title. $body',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: type.emptyTitle),
              const SizedBox(height: Spacing.sm),
              Text(body, style: type.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SessionListError extends StatelessWidget {
  const _SessionListError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load sessions', style: type.emptyTitle),
            const SizedBox(height: Spacing.sm),
            Text('$error', style: type.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
