import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_controller.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session Detail view (Feature 1.2.2; M1 "Session Visibility"). Renders
/// entirely from `SessionRepository.readSession()` — read-only, no mutating
/// CLI action anywhere in this page.
final class SessionDetailPage extends ConsumerWidget {
  const SessionDetailPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: sessionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            key: ValueKey('session-detail-loading'),
          ),
        ),
        error: (error, stackTrace) {
          if (error is SessionLoadException &&
              error.code == FailureCode.sessionNotFound) {
            return const _SessionNotFoundState(
              key: ValueKey('session-detail-not-found'),
            );
          }
          return _SessionDetailError(error: error);
        },
        data: (session) => _SessionDetailBody(session: session),
      ),
    );
  }
}

final class _SessionDetailBody extends StatelessWidget {
  const _SessionDetailBody({required this.session});

  final ClaudeSession session;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final projectLabel =
        session.projectPath ?? session.sanitizedProjectDirName;
    final tokens = session.tokenTotals;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.contentMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      projectLabel,
                      style: type.section,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (session.isLive ?? false) ...[
                    const SizedBox(width: Spacing.sm),
                    const StatusBadge(kind: TrayStatusKind.live, compact: true),
                  ],
                ],
              ),
              const SizedBox(height: Spacing.sm),
              // Incomplete sessions are shown honestly, not silently
              // (design principle 4) — a killed process is an accepted,
              // ordinary state, not corruption.
              if (!session.isComplete) ...[
                const _IncompleteBanner(key: ValueKey('session-incomplete')),
                const SizedBox(height: Spacing.md),
              ],
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InfoRow(
                      label: 'Model',
                      value: session.model ?? '—',
                    ),
                    InfoRow(
                      label: 'Git branch',
                      value: session.gitBranch ?? '—',
                    ),
                    InfoRow(
                      label: 'Last activity',
                      value: UsageStatusMapper.relativeUpdated(
                        session.lastActivityAt,
                      ),
                    ),
                    InfoRow(
                      label: 'Messages',
                      value: '${session.messageCount}',
                    ),
                    InfoRow(
                      label: 'Input tokens',
                      value: '${tokens.inputTokens}',
                    ),
                    InfoRow(
                      label: 'Output tokens',
                      value: '${tokens.outputTokens}',
                    ),
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

final class _IncompleteBanner extends StatelessWidget {
  const _IncompleteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Text(
          'Incomplete — this session may have been interrupted before it '
          'finished.',
          style: type.caption.copyWith(color: colors.warning),
        ),
      ),
    );
  }
}

final class _SessionNotFoundState extends StatelessWidget {
  const _SessionNotFoundState({super.key});

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Semantics(
          container: true,
          label:
              'Session no longer available. This transcript was deleted or '
              'moved.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Session no longer available', style: type.emptyTitle),
              const SizedBox(height: Spacing.sm),
              Text(
                'This transcript was deleted or moved since it was listed.',
                style: type.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SessionDetailError extends StatelessWidget {
  const _SessionDetailError({required this.error});

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
            Text('Could not load session', style: type.emptyTitle),
            const SizedBox(height: Spacing.sm),
            Text('$error', style: type.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
