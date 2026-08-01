import 'dart:async';

import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_controller.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_controller.dart';
import 'package:ai_tray/features/sessions/resume/presentation/resume_controller.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session Detail view. Loads its data read-only from
/// `SessionRepository.readSession()` (Feature 1.2.2), and hosts two
/// acting sections added since: attended "Resume now" (Feature 2.2.1) and
/// "Add to queue" (Feature 2.2.2) — both opt-in, both disabled with no
/// decoded project path, never silent about what they do.
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
    final projectLabel = session.projectPath ?? session.sanitizedProjectDirName;
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
              const SizedBox(height: Spacing.md),
              _ResumeSection(
                sessionId: session.sessionId,
                workingDirectory: session.projectPath,
              ),
              const SizedBox(height: Spacing.md),
              _EnqueueSection(
                sessionId: session.sessionId,
                workingDirectory: session.projectPath,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attended "Resume now" action (Feature 2.2.1) — continues the session
/// in place (never forks; only unattended/queued execution does). Never
/// enabled without a real, decoded [workingDirectory]: design principle 3
/// forbids guessing a `cwd`, so resume is simply unavailable when
/// [ClaudeSession.projectPath] is `null`.
final class _ResumeSection extends ConsumerStatefulWidget {
  const _ResumeSection({
    required this.sessionId,
    required this.workingDirectory,
  });

  final String sessionId;
  final String? workingDirectory;

  @override
  ConsumerState<_ResumeSection> createState() => _ResumeSectionState();
}

final class _ResumeSectionState extends ConsumerState<_ResumeSection> {
  final _prompt = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

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

    return SectionCard(
      title: 'Resume now',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (workingDirectory == null)
            Text(
              'Resume is unavailable — the project path for this session '
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
                    : const Text('Resume now'),
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

/// "Enqueue from Session Detail" (Feature 2.2.2). A budget cap is
/// mandatory (design principle 2) — the submit button stays disabled
/// until both a prompt and a positive cap are entered; there is no
/// "submit without a cap" path in this form. Enqueuing never triggers
/// execution by itself (see `ResumeQueueController`'s own doc comment).
final class _EnqueueSection extends ConsumerStatefulWidget {
  const _EnqueueSection({
    required this.sessionId,
    required this.workingDirectory,
  });

  final String sessionId;
  final String? workingDirectory;

  @override
  ConsumerState<_EnqueueSection> createState() => _EnqueueSectionState();
}

final class _EnqueueSectionState extends ConsumerState<_EnqueueSection> {
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

    return SectionCard(
      title: 'Add to queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (workingDirectory == null)
            Text(
              'Queueing is unavailable — the project path for this '
              "session couldn't be determined.",
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
              decoration: const InputDecoration(
                labelText: 'Budget cap (USD) — required',
                hintText: 'e.g. 2.00',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('enqueue-submit-button'),
                onPressed: _canSubmit ? () => unawaited(_submit()) : null,
                child: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add to queue'),
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
              'Added to the resume queue.',
              key: const ValueKey('enqueue-success'),
              style: type.caption.copyWith(color: context.colors.success),
            ),
          ],
        ],
      ),
    );
  }
}
