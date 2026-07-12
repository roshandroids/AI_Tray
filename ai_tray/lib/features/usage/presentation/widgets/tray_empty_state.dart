import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Polished empty / error guidance for the usage window (PD-013 / PD-014).
final class TrayEmptyState extends StatelessWidget {
  const TrayEmptyState({
    required this.failure,
    super.key,
  });

  final AppFailure? failure;

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(failure);
    final type = context.typography;

    return Semantics(
      container: true,
      label: '${copy.title}. ${copy.body}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.title, style: type.emptyTitle),
          const SizedBox(height: Spacing.sm),
          Text(copy.body, style: type.bodySmall),
          if (copy.hint != null) ...[
            const SizedBox(height: Spacing.md),
            Text(copy.hint!, style: type.muted),
          ],
        ],
      ),
    );
  }

  static ({String title, String body, String? hint}) _copyFor(
    AppFailure? failure,
  ) {
    if (failure == null) {
      return (
        title: 'No usage data yet',
        body:
            'Press Refresh to fetch the latest session and weekly limits '
            'from Claude Code.',
        hint: 'Tip: keep Claude signed in (`claude auth status`).',
      );
    }

    return switch (failure.code) {
      FailureCode.cliNotInstalled => (
        title: 'Claude CLI not found',
        body: 'AI Tray needs the Claude Code CLI on this Mac.',
        hint: 'Install Claude Code, or set the binary path in Settings.',
      ),
      FailureCode.notAuthenticated => (
        title: 'Authentication expired',
        body: 'Claude is installed but not signed in.',
        hint: 'Run `claude auth login` in Terminal, then Refresh.',
      ),
      FailureCode.timeout => (
        title: 'Refresh timed out',
        body: 'Claude took too long to respond.',
        hint: 'Try again. If this persists, increase the refresh interval.',
      ),
      FailureCode.processLaunchFailed => (
        title: 'Could not start Claude',
        body: failure.message,
        hint: 'Check the binary path in Settings and macOS permissions.',
      ),
      FailureCode.processNonZeroExit => (
        title: 'Claude exited with an error',
        body: failure.message,
        hint: "Verify `claude -p '/usage' --output-format json` in Terminal.",
      ),
      FailureCode.parserFailure ||
      FailureCode.unknownCliOutput ||
      FailureCode.incompleteOutput => (
        title: 'Unexpected Claude output',
        body:
            'Limits were not present in this response. Cached values are '
            'kept when available — percentages are never invented.',
        hint: 'This is often temporary under load. Try Refresh again.',
      ),
      FailureCode.cacheUnavailable => (
        title: 'No cached usage',
        body: 'A refresh failed and there is no previous snapshot to show.',
        hint: 'Fix the Claude CLI issue above, then Refresh.',
      ),
      FailureCode.cancelled => (
        title: 'Refresh cancelled',
        body: 'The previous refresh was interrupted.',
        hint: 'Press Refresh to try again.',
      ),
      FailureCode.unknown => (
        title: 'Refresh failed',
        body: failure.message,
        hint: 'See Troubleshooting in the docs if this keeps happening.',
      ),
    };
  }
}
