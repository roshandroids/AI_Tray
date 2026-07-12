import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_empty_state.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_usage_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop usage window — visual shell only (PD-013 / PD-014).
final class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(settingsOpenRequestProvider, (previous, next) {
      if (previous == next) return;
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        ),
      );
    });

    final repository = ref.watch(usageRepositoryProvider);

    return StreamBuilder<RefreshStatus>(
      stream: repository.watchStatus(),
      initialData: repository.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? RefreshStatus.initial();
        final usage = status.lastResult?.usage;
        final outcome = status.lastResult?.status;
        final error = status.lastResult?.error;
        final refreshing = status.phase == RefreshPhase.refreshing;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Tray'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Spacing.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.lg,
                  Spacing.xl,
                  Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: usage != null
                            ? _UsageBody(
                                key: ValueKey<String>(
                                  usage.fetchedAt.toIso8601String(),
                                ),
                                usage: usage,
                                status: status,
                                outcome: outcome,
                                errorMessage: error?.message,
                              )
                            : SingleChildScrollView(
                                key: const ValueKey<String>('empty'),
                                child: TrayEmptyState(failure: error),
                              ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: refreshing
                            ? null
                            : () => unawaited(
                                  repository.refresh(manual: true),
                                ),
                        child: Text(refreshing ? 'Refreshing…' : 'Refresh'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _UsageBody extends StatelessWidget {
  const _UsageBody({
    required this.usage,
    required this.status,
    required this.outcome,
    required this.errorMessage,
    super.key,
  });

  final UsageInfo usage;
  final RefreshStatus status;
  final RefreshOutcome? outcome;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrayUsageMeter(
            label: 'Current session',
            percent: usage.sessionUsedPercent,
            resetsAtRaw: usage.sessionResetsAtRaw,
          ),
          const SizedBox(height: Spacing.xl),
          const _Hairline(),
          const SizedBox(height: Spacing.xl),
          for (var i = 0; i < usage.weekly.length; i++) ...[
            TrayUsageMeter(
              label: _weekLabel(usage.weekly[i].label),
              percent: usage.weekly[i].usedPercent,
              resetsAtRaw: usage.weekly[i].resetsAtRaw,
            ),
            if (i < usage.weekly.length - 1) ...[
              const SizedBox(height: Spacing.xl),
              const _Hairline(),
              const SizedBox(height: Spacing.xl),
            ],
          ],
          const SizedBox(height: Spacing.xl),
          const _Hairline(),
          const SizedBox(height: Spacing.xl),
          Text('Status', style: type.sectionTitle),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TrayStatusBadge(kind: _badgeKind(status, usage, outcome)),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text('Updated', style: type.muted),
          const SizedBox(height: Spacing.xs),
          Text(
            _relativeUpdated(
              status.lastSuccessAt ?? usage.fetchedAt,
            ),
            style: type.body,
          ),
          if (outcome == RefreshOutcome.softFailure) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Claude did not return limits; showing last known usage.',
              style: type.bodySmall,
            ),
          ],
          if (outcome == RefreshOutcome.failure) ...[
            const SizedBox(height: Spacing.md),
            Text(
              errorMessage ?? 'Refresh failed',
              style: type.error,
            ),
          ],
        ],
      ),
    );
  }

  static String _weekLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Current week';
    return 'Current week ($trimmed)';
  }

  static TrayStatusKind _badgeKind(
    RefreshStatus status,
    UsageInfo usage,
    RefreshOutcome? outcome,
  ) {
    if (status.phase == RefreshPhase.refreshing) {
      return TrayStatusKind.refreshing;
    }
    if (outcome == RefreshOutcome.failure) {
      return TrayStatusKind.error;
    }
    if (usage.isFromCache || outcome == RefreshOutcome.softFailure) {
      return TrayStatusKind.cached;
    }
    return TrayStatusKind.live;
  }

  static String _relativeUpdated(DateTime at) {
    final now = DateTime.now().toUtc();
    final utc = at.isUtc ? at : at.toUtc();
    final delta = now.difference(utc);
    if (delta.inSeconds < 5) return 'just now';
    if (delta.inSeconds < 60) return '${delta.inSeconds} sec ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hr ago';
    return '${delta.inDays} day${delta.inDays == 1 ? '' : 's'} ago';
  }
}

final class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.divider,
      child: const SizedBox(height: 1, width: double.infinity),
    );
  }
}
