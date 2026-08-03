import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/about/presentation/about_page.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_list_filter.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One runnable entry in the command palette — the single registry backing
/// both quick actions and shell navigation, so the two can't drift.
final class CommandPaletteAction {
  const CommandPaletteAction({
    required this.label,
    required this.icon,
    required this.onInvoke,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final FutureOr<void> Function(BuildContext context, WidgetRef ref) onInvoke;
}

/// Sessions available to the palette's search-as-you-type results.
final FutureProvider<List<SessionSummary>> _commandPaletteSessionsProvider =
    FutureProvider.autoDispose<List<SessionSummary>>((ref) async {
      final result = await ref.watch(sessionRepositoryProvider).listSessions();
      return result.valueOrNull ?? const [];
    });

/// Opens the ⌘K command palette.
Future<void> showCommandPalette(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const _CommandPaletteDialog(),
  );
}

List<CommandPaletteAction> _buildActions(BuildContext context, WidgetRef ref) {
  final destinationActions = [
    for (final destination in AppDestination.values)
      CommandPaletteAction(
        label: 'Go to ${destination.label}',
        icon: destination.icon,
        onInvoke: (context, ref) {
          ref.read(appShellDestinationProvider.notifier).select(destination);
        },
      ),
  ];

  final providerActions = [
    for (final provider in ref.read(selectableAIProvidersProvider))
      CommandPaletteAction(
        label: 'Switch to ${provider.displayName}',
        icon: Icons.swap_horiz_rounded,
        onInvoke: (context, ref) async {
          final changed = await ref
              .read(selectedProviderIdProvider.notifier)
              .select(provider.providerId);
          if (changed) {
            await ref.read(usageRepositoryProvider).refresh(manual: true);
          }
        },
      ),
  ];

  return [
    ...destinationActions,
    CommandPaletteAction(
      label: 'Open Diagnostics',
      icon: Icons.monitor_heart_outlined,
      onInvoke: (context, ref) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DiagnosticsPage()),
      ),
    ),
    CommandPaletteAction(
      label: 'About AI Tray',
      icon: Icons.info_outline,
      onInvoke: (context, ref) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AboutPage()),
      ),
    ),
    CommandPaletteAction(
      label: 'Continue last session',
      icon: Icons.play_circle_outline_rounded,
      onInvoke: (context, ref) async {
        final navigator = Navigator.of(context);
        final result = await ref.read(sessionRepositoryProvider).listSessions();
        final sessions = result.valueOrNull ?? const [];
        if (sessions.isEmpty) return;
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SessionDetailPage(sessionId: sessions.first.sessionId),
            ),
          ),
        );
      },
    ),
    CommandPaletteAction(
      label: 'Queue a task…',
      subtitle: 'Pick a session to add to the queue',
      icon: Icons.pending_actions_outlined,
      onInvoke: (context, ref) {
        ref
            .read(appShellDestinationProvider.notifier)
            .select(AppDestination.sessions);
      },
    ),
    CommandPaletteAction(
      label: 'Refresh now',
      icon: Icons.refresh_rounded,
      onInvoke: (context, ref) =>
          ref.read(usageRepositoryProvider).refresh(manual: true),
    ),
    CommandPaletteAction(
      label: 'Toggle theme',
      icon: Icons.brightness_6_outlined,
      onInvoke: (context, ref) {
        final current =
            ref.read(personalizationControllerProvider).value?.themeMode ??
            AppThemePreference.system;
        const cycle = [
          AppThemePreference.system,
          AppThemePreference.light,
          AppThemePreference.dark,
        ];
        final next = cycle[(cycle.indexOf(current) + 1) % cycle.length];
        return ref
            .read(personalizationControllerProvider.notifier)
            .setThemeMode(next);
      },
    ),
    ...providerActions,
  ];
}

void _openSession(BuildContext context, String sessionId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SessionDetailPage(sessionId: sessionId),
    ),
  );
}

final class _CommandPaletteDialog extends ConsumerStatefulWidget {
  const _CommandPaletteDialog();

  @override
  ConsumerState<_CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

final class _CommandPaletteDialogState
    extends ConsumerState<_CommandPaletteDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _invoke(CommandPaletteAction action) {
    Navigator.of(context).pop();
    unawaited(Future.sync(() => action.onInvoke(context, ref)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final needle = _query.trim().toLowerCase();
    final actions = _buildActions(context, ref);
    final matchedActions = needle.isEmpty
        ? actions
        : [
            for (final action in actions)
              if (action.label.toLowerCase().contains(needle)) action,
          ];
    final sessionsAsync = ref.watch(_commandPaletteSessionsProvider);
    final matchedSessions = needle.isEmpty
        ? const <SessionSummary>[]
        : filterSessionsByProjectPath(
            sessionsAsync.value ?? const [],
            needle,
          ).take(6).toList();

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 96),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: context.typography.body,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type a command or search sessions…',
                    hintStyle: context.typography.body.copyWith(
                      color: colors.textMuted,
                    ),
                    prefixIcon: Icon(Icons.search, color: colors.textMuted),
                  ),
                  onSubmitted: (_) {
                    if (matchedActions.isNotEmpty) {
                      _invoke(matchedActions.first);
                    } else if (matchedSessions.isNotEmpty) {
                      Navigator.of(context).pop();
                      _openSession(context, matchedSessions.first.sessionId);
                    }
                  },
                ),
              ),
              Divider(height: 1, color: colors.border),
              Flexible(
                child: matchedActions.isEmpty && matchedSessions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: Text(
                          'No matching commands or sessions.',
                          style: context.typography.caption,
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.xs,
                        ),
                        children: [
                          for (final action in matchedActions)
                            _PaletteRow(
                              icon: action.icon,
                              label: action.label,
                              subtitle: action.subtitle,
                              onTap: () => _invoke(action),
                            ),
                          if (matchedSessions.isNotEmpty) ...[
                            if (matchedActions.isNotEmpty)
                              Divider(height: 1, color: colors.border),
                            for (final session in matchedSessions)
                              _PaletteRow(
                                icon: Icons.history_rounded,
                                label:
                                    session.projectPath ??
                                    session.sanitizedProjectDirName,
                                subtitle: 'Open session',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _openSession(context, session.sessionId);
                                },
                              ),
                          ],
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

final class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.textSecondary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.typography.body),
                  if (subtitle != null)
                    Text(subtitle!, style: context.typography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
