import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:flutter/material.dart';

/// Polished empty / error guidance for the usage window (PD-013 / PD-014).
final class TrayEmptyState extends StatelessWidget {
  const TrayEmptyState({
    required this.failure,
    required this.provider,
    super.key,
  });

  final AppFailure? failure;
  final AIProvider provider;

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(failure, provider);
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
    AIProvider provider,
  ) {
    if (!provider.enabled) {
      return (
        title: '${provider.displayName} is disabled',
        body: 'This provider is not currently available for usage refreshes.',
        hint: 'Enable ${provider.displayName} in Settings, then Refresh.',
      );
    }
    if (failure == null) {
      return (
        title: 'No usage data yet',
        body:
            'Press Refresh to fetch the latest session and weekly limits '
            'from ${provider.displayName}.',
        hint: 'Tip: keep ${provider.displayName} signed in.',
      );
    }

    final detail = '${failure.message} ${failure.detail ?? ''}'.toLowerCase();
    if (provider.providerId == ProviderId.copilot) {
      if (detail.contains('experimental')) {
        return (
          title: 'Experimental Copilot API unavailable',
          body:
              'The session-scoped quota API is unavailable in this Copilot '
              'version.',
          hint:
              'Update Copilot, review Diagnostics, then retry. Existing data '
              'is never estimated.',
        );
      }
      if (detail.contains('quota') || detail.contains('rpc')) {
        return (
          title: 'Copilot quota unavailable',
          body:
              'Copilot responded, but did not provide a usable quota '
              'snapshot.',
          hint: 'Open Diagnostics to check Quota RPC, then Refresh.',
        );
      }
      if (failure.code == FailureCode.cliNotInstalled) {
        return (
          title: 'Copilot SDK is missing',
          body:
              'AI Tray could not start the bundled Copilot SDK sidecar on '
              'this device.',
          hint:
              'Reinstall or update AI Tray, then verify SDK and CLI versions '
              'in Diagnostics.',
        );
      }
    }

    return switch (failure.code) {
      FailureCode.cliNotInstalled => (
        title: '${provider.sourceLabel} not found',
        body: 'AI Tray could not find ${provider.sourceLabel} on this device.',
        hint: provider.capabilities.customExecutable
            ? 'Install it, or set the binary path in Settings.'
            : 'Install or configure ${provider.displayName}, then Refresh.',
      ),
      FailureCode.notAuthenticated => (
        title: 'Authentication expired',
        body: '${provider.displayName} is available but not signed in.',
        hint: 'Sign in to ${provider.displayName}, then Refresh.',
      ),
      FailureCode.timeout => (
        title: 'Refresh timed out',
        body: '${provider.displayName} took too long to respond.',
        hint: 'Try again. If this persists, increase the refresh interval.',
      ),
      FailureCode.processLaunchFailed => (
        title: 'Could not start ${provider.displayName}',
        body: failure.message,
        hint: provider.capabilities.customExecutable
            ? 'Check the binary path in Settings and system permissions.'
            : 'Check provider configuration and system permissions.',
      ),
      FailureCode.processNonZeroExit => (
        title: '${provider.displayName} exited with an error',
        body: failure.message,
        hint: 'Verify ${provider.sourceLabel} independently, then Refresh.',
      ),
      FailureCode.parserFailure ||
      FailureCode.unknownCliOutput ||
      FailureCode.incompleteOutput => (
        title: 'Unexpected ${provider.displayName} output',
        body:
            'Limits were not present in this response. Cached values are '
            'kept when available — percentages are never invented.',
        hint: 'This is often temporary under load. Try Refresh again.',
      ),
      FailureCode.cacheUnavailable => (
        title: 'No cached usage',
        body: 'A refresh failed and there is no previous snapshot to show.',
        hint: 'Fix the provider issue above, then Refresh.',
      ),
      FailureCode.cancelled => (
        title: 'Refresh cancelled',
        body: 'The previous refresh was interrupted.',
        hint: 'Press Refresh to try again.',
      ),
      // sessionNotFound is a Session Browser (v2) code — the usage-refresh
      // pipeline that feeds this widget never produces it; bucketed with
      // unknown rather than given its own unreachable-here copy.
      FailureCode.unknown ||
      FailureCode.sessionNotFound => (
        title: 'Refresh failed',
        body: failure.message,
        hint: 'See Troubleshooting in the docs if this keeps happening.',
      ),
    };
  }
}
