import 'dart:async';

import 'package:ai_tray/core/components/empty_state.dart';
import 'package:ai_tray/core/components/page_header.dart';
import 'package:ai_tray/core/components/session_card.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_browser_controller.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_list_filter.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_project_grouping.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session Browser list page (Feature 1.2.1; M1 "Session Visibility"),
/// grouped by project (V3 redesign) — the group containing the current
/// live session (if any) is pinned first and expanded by default.
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
  final Set<String> _expandedKeys = {};
  bool _expansionInitialized = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _ensureDefaultExpansion(List<ProjectGroup> groups) {
    if (_expansionInitialized || groups.isEmpty) return;
    _expansionInitialized = true;
    _expandedKeys.add(groups.first.key);
  }

  void _openSession(String sessionId) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SessionDetailPage(sessionId: sessionId),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionBrowserControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Sessions',
            actions: [
              IconButton(
                tooltip: 'Queue',
                onPressed: () => ref
                    .read(appShellDestinationProvider.notifier)
                    .select(AppDestination.queue),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
            ),
            child: Semantics(
              textField: true,
              label: 'Filter sessions by project path',
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
                final groups = groupSessionsByProject(filtered);
                _ensureDefaultExpansion(groups);
                return ListView.builder(
                  key: const ValueKey('sessions-list'),
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _ProjectGroupTile(
                      group: group,
                      initiallyExpanded: _expandedKeys.contains(group.key),
                      onExpansionChanged: (expanded) => setState(() {
                        if (expanded) {
                          _expandedKeys.add(group.key);
                        } else {
                          _expandedKeys.remove(group.key);
                        }
                      }),
                      onOpenSession: _openSession,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _ProjectGroupTile extends StatelessWidget {
  const _ProjectGroupTile({
    required this.group,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onOpenSession,
  });

  final ProjectGroup group;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<String> onOpenSession;

  @override
  Widget build(BuildContext context) {
    final mostRecent = group.sessions.first;
    final name = projectDisplayName(
      projectPath: mostRecent.projectPath,
      sanitizedProjectDirName: mostRecent.sanitizedProjectDirName,
    );
    final countLabel =
        '${group.sessions.length} '
        '${group.sessions.length == 1 ? 'session' : 'sessions'} · '
        'updated ${UsageStatusMapper.relativeUpdated(group.lastActivityAt)}';
    final subtitle = mostRecent.projectPath == null
        ? countLabel
        : '${mostRecent.projectPath} · $countLabel';

    return ProjectCard(
      title: name,
      subtitle: subtitle,
      hasLiveSession: group.hasLiveSession,
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      storageKey: PageStorageKey('project-group-${group.key}'),
      children: [
        for (final session in group.sessions)
          SessionCard(
            primaryText:
                '${UsageStatusMapper.relativeUpdated(session.lastActivityAt)} '
                '· ${session.messageCount} messages',
            // A live badge appears only when `agents --json --all` matched
            // this session — absence (false or unconfirmed) is never shown
            // as "not live" (design principle 3): there is no visual
            // distinction between false and null.
            live: session.isLive ?? false,
            onTap: () => onOpenSession(session.sessionId),
          ),
      ],
    );
  }
}

final class _SessionListEmptyState extends StatelessWidget {
  const _SessionListEmptyState({super.key, this.noMatch = false});

  final bool noMatch;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: noMatch ? Icons.search_off : Icons.folder_open_outlined,
      title: noMatch ? 'No sessions match this filter' : 'No sessions yet',
      body: noMatch
          ? 'Clear the search to see every session.'
          : 'Sessions appear here once you use Claude Code in a project.',
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
            Text('Could not load sessions', style: type.section),
            const SizedBox(height: Spacing.sm),
            Text('$error', style: type.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
