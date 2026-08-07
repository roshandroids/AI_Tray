import 'dart:async';

import 'package:ai_tray/core/components/inline_help.dart';
import 'package:ai_tray/core/components/resizable_panel.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/sliver_page_scaffold.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/layout/layout_providers.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_project_grouping.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_controller.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_controller.dart';
import 'package:ai_tray/features/sessions/resume/presentation/resume_controller.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session Detail view. Loads its data read-only from
/// `SessionRepository.readSession()` (Feature 1.2.2). Redesigned (V3)
/// around continuing work: "Continue conversation" is the primary,
/// immediately-visible action; "Queue task" is secondary and collapsed by
/// default; technical fields (model, tokens, git branch, …) move under an
/// "Advanced" disclosure at the bottom instead of leading the page.
final class SessionDetailPage extends ConsumerWidget {
  const SessionDetailPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailProvider(sessionId));
    final backButton = IconButton(
      tooltip: 'Back to Sessions',
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back),
    );

    return sessionAsync.when(
      loading: () => SliverPageScaffold(
        title: 'Session',
        leading: backButton,
        slivers: const [
          SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                key: ValueKey('session-detail-loading'),
              ),
            ),
          ),
        ],
      ),
      error: (error, stackTrace) {
        final Widget body;
        if (error is SessionLoadException &&
            error.code == FailureCode.sessionNotFound) {
          body = const _SessionNotFoundState(
            key: ValueKey('session-detail-not-found'),
          );
        } else {
          body = _SessionDetailError(error: error);
        }
        return SliverPageScaffold(
          title: 'Session',
          leading: backButton,
          slivers: [SliverFillRemaining(child: body)],
        );
      },
      data: (session) {
        final name = projectDisplayName(
          projectPath: session.projectPath,
          sanitizedProjectDirName: session.sanitizedProjectDirName,
        );
        final fullPath = session.projectPath;
        return SliverPageScaffold(
          title: name,
          subtitle: fullPath != null && fullPath != name ? fullPath : null,
          titleTrailing: (session.isLive ?? false)
              ? const StatusBadge(kind: TrayStatusKind.live, compact: true)
              : null,
          leading: backButton,
          slivers: [
            SliverToBoxAdapter(child: _SessionDetailBody(session: session)),
          ],
        );
      },
    );
  }
}

final class _SessionDetailBody extends StatelessWidget {
  const _SessionDetailBody({required this.session});

  final ClaudeSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Incomplete sessions are shown honestly, not silently (design
          // principle 4) — a killed process is an accepted, ordinary
          // state, not corruption.
          if (!session.isComplete) ...[
            const _IncompleteBanner(key: ValueKey('session-incomplete')),
            const SizedBox(height: Spacing.md),
          ],
          _ContinueConversationSection(
            sessionId: session.sessionId,
            workingDirectory: session.projectPath,
          ),
          const SizedBox(height: Spacing.md),
          _QueueTaskSection(
            sessionId: session.sessionId,
            workingDirectory: session.projectPath,
          ),
          const SizedBox(height: Spacing.md),
          _AdvancedDetailsSection(session: session),
        ],
      ),
    );
  }
}

/// Primary action (V3): continues this conversation in place — never
/// forks (only unattended/queued execution does). Never enabled without a
/// real, decoded [workingDirectory]: design principle 3 forbids guessing
/// a `cwd`, so continuing is simply unavailable when
/// [ClaudeSession.projectPath] is `null`.
final class _ContinueConversationSection extends ConsumerStatefulWidget {
  const _ContinueConversationSection({
    required this.sessionId,
    required this.workingDirectory,
  });

  final String sessionId;
  final String? workingDirectory;

  @override
  ConsumerState<_ContinueConversationSection> createState() =>
      _ContinueConversationSectionState();
}

final class _ContinueConversationSectionState
    extends ConsumerState<_ContinueConversationSection> {
  final _prompt = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  static const _panelId = 'session_detail.continue_conversation';

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final resumeState = ref.watch(resumeControllerProvider);
    final attempt = resumeState.value;
    final showResult = attempt != null && attempt.sessionId == widget.sessionId;
    final isBusy = resumeState.isLoading;
    final workingDirectory = widget.workingDirectory;
    final canResume =
        workingDirectory != null && !isBusy && _prompt.text.trim().isNotEmpty;
    final layout = ref.watch(sessionDetailPanelLayoutProvider).value;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ResizablePanel(
        panelId: _panelId,
        title: 'Continue conversation',
        initialState: layout?[_panelId],
        defaultExpanded: true,
        onStateChanged: (state) => unawaited(
          ref.read(panelLayoutRepositoryProvider).save(_panelId, state),
        ),
        bodyBuilder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Picks up where this session left off, in its original '
              'working directory. Runs right now, in place — never a '
              'separate copy.',
              style: type.caption,
            ),
            const SizedBox(height: Spacing.sm),
            if (workingDirectory == null)
              Text(
                'Unavailable — the project path for this session '
                "couldn't be determined.",
                style: type.caption,
              )
            else ...[
              TextField(
                key: const ValueKey('resume-prompt-field'),
                controller: _prompt,
                maxLines: 3,
                style: type.body,
                enabled: !isBusy,
                decoration: const InputDecoration(hintText: 'Continue with…'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Spacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('resume-now-button'),
                  onPressed: canResume
                      ? () => unawaited(
                          ref
                              .read(resumeControllerProvider.notifier)
                              .resume(
                                sessionId: widget.sessionId,
                                prompt: _prompt.text.trim(),
                                workingDirectory: workingDirectory,
                              ),
                        )
                      : null,
                  child: isBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue conversation'),
                ),
              ),
            ],
            if (resumeState.hasError && !isBusy) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                '${resumeState.error}',
                key: const ValueKey('resume-error'),
                style: type.caption.copyWith(color: context.colors.error),
              ),
            ],
            if (showResult) ...[
              const SizedBox(height: Spacing.md),
              const SectionDivider(),
              _ResumeResult(outcome: attempt.outcome),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ResumeResult extends StatelessWidget {
  const _ResumeResult({required this.outcome});

  final ResumeOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Column(
      key: const ValueKey('resume-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoRow(
          label: 'Cost',
          value: '\$${outcome.costUsd.toStringAsFixed(4)}',
        ),
        InfoRow(
          label: 'Tokens',
          value:
              '${outcome.tokens.inputTokens} in / '
              '${outcome.tokens.outputTokens} out',
        ),
        InfoRow(label: 'Turns', value: '${outcome.numTurns}'),
        InfoRow(label: 'Stop reason', value: outcome.stopReason ?? '—'),
        const SizedBox(height: Spacing.sm),
        Text(outcome.resultText, style: type.body),
      ],
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
              Text('Session no longer available', style: type.section),
              const SizedBox(height: Spacing.sm),
              Text(
                'This transcript was deleted or moved since it was listed.',
                style: type.caption,
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
            Text('Could not load session', style: type.section),
            const SizedBox(height: Spacing.sm),
            Text('$error', style: type.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Secondary action (V3): queues a task to run unattended later, as a
/// forked copy of this session — safe to queue even while actively using
/// this session elsewhere. Collapsed by default (progressive disclosure);
/// a budget cap is mandatory (design principle 2) — the submit button
/// stays disabled until both a prompt and a positive cap are entered.
final class _QueueTaskSection extends ConsumerStatefulWidget {
  const _QueueTaskSection({
    required this.sessionId,
    required this.workingDirectory,
  });

  final String sessionId;
  final String? workingDirectory;

  @override
  ConsumerState<_QueueTaskSection> createState() => _QueueTaskSectionState();
}

final class _QueueTaskSectionState extends ConsumerState<_QueueTaskSection> {
  static const _panelId = 'session_detail.queue_task';

  final _prompt = TextEditingController();
  final _budgetCap = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _justEnqueued = false;

  @override
  void dispose() {
    _prompt.dispose();
    _budgetCap.dispose();
    super.dispose();
  }

  double? get _parsedCap => double.tryParse(_budgetCap.text.trim());

  bool get _canSubmit {
    final workingDirectory = widget.workingDirectory;
    final cap = _parsedCap;
    return workingDirectory != null &&
        !_submitting &&
        _prompt.text.trim().isNotEmpty &&
        cap != null &&
        cap > 0;
  }

  Future<void> _submit() async {
    final workingDirectory = widget.workingDirectory;
    final cap = _parsedCap;
    if (workingDirectory == null || cap == null) return;
    setState(() {
      _submitting = true;
      _error = null;
      _justEnqueued = false;
    });

    final ok = await ref
        .read(resumeQueueControllerProvider.notifier)
        .enqueue(
          sessionId: widget.sessionId,
          cwd: workingDirectory,
          prompt: _prompt.text.trim(),
          maxBudgetUsd: cap,
        );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _justEnqueued = ok;
      _error = ok ? null : 'Could not add to the queue.';
      if (ok) {
        _prompt.clear();
        _budgetCap.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final workingDirectory = widget.workingDirectory;
    final layout = ref.watch(sessionDetailPanelLayoutProvider).value;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ResizablePanel(
        key: const ValueKey('queue-task-expansion'),
        panelId: _panelId,
        title: 'Queue task',
        subtitle: 'Runs later, unattended, as a separate copy of this session',
        initialState: layout?[_panelId],
        onStateChanged: (state) => unawaited(
          ref.read(panelLayoutRepositoryProvider).save(_panelId, state),
        ),
        bodyBuilder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (workingDirectory == null)
              Text(
                'Unavailable — the project path for this session '
                "couldn't be determined.",
                style: type.caption,
              )
            else ...[
              TextField(
                key: const ValueKey('enqueue-prompt-field'),
                controller: _prompt,
                maxLines: 3,
                style: type.body,
                enabled: !_submitting,
                decoration: const InputDecoration(hintText: 'Continue with…'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                key: const ValueKey('enqueue-budget-cap-field'),
                controller: _budgetCap,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: type.body,
                enabled: !_submitting,
                decoration: InputDecoration(
                  labelText: 'Budget cap (USD) — required',
                  hintText: 'e.g. 2.00',
                  suffixIcon: InlineHelp(
                    message:
                        'The task stops itself once its cost reaches this '
                        "cap, even mid-response — it won't run unbounded.",
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Spacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  key: const ValueKey('enqueue-submit-button'),
                  onPressed: _canSubmit ? () => unawaited(_submit()) : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Queue task'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                _error!,
                key: const ValueKey('enqueue-error'),
                style: type.caption.copyWith(color: context.colors.error),
              ),
            ],
            if (_justEnqueued) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'Added to the queue.',
                key: const ValueKey('enqueue-success'),
                style: type.caption.copyWith(color: context.colors.success),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Technical fields (V3: moved under an "Advanced" disclosure at the
/// bottom of the page instead of leading it — a user resuming or queueing
/// work rarely needs the model name or raw token counts up front).
final class _AdvancedDetailsSection extends ConsumerStatefulWidget {
  const _AdvancedDetailsSection({required this.session});

  final ClaudeSession session;

  @override
  ConsumerState<_AdvancedDetailsSection> createState() =>
      _AdvancedDetailsSectionState();
}

final class _AdvancedDetailsSectionState
    extends ConsumerState<_AdvancedDetailsSection> {
  static const _panelId = 'session_detail.advanced';

  @override
  Widget build(BuildContext context) {
    final tokens = widget.session.tokenTotals;
    final layout = ref.watch(sessionDetailPanelLayoutProvider).value;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ResizablePanel(
        key: const ValueKey('advanced-details-expansion'),
        panelId: _panelId,
        title: 'Advanced',
        initialState: layout?[_panelId],
        onStateChanged: (state) => unawaited(
          ref.read(panelLayoutRepositoryProvider).save(_panelId, state),
        ),
        bodyBuilder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoRow(label: 'Model', value: widget.session.model ?? '—'),
            InfoRow(
              label: 'Git branch',
              value: widget.session.gitBranch ?? '—',
            ),
            InfoRow(
              label: 'Last activity',
              value: UsageStatusMapper.relativeUpdated(
                widget.session.lastActivityAt,
              ),
            ),
            InfoRow(
              label: 'Messages',
              value: '${widget.session.messageCount}',
            ),
            InfoRow(label: 'Input tokens', value: '${tokens.inputTokens}'),
            InfoRow(label: 'Output tokens', value: '${tokens.outputTokens}'),
          ],
        ),
      ),
    );
  }
}
