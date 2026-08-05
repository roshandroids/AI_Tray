import 'dart:async';

import 'package:ai_tray/core/components/keyboard_shortcuts_dialog.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/motion.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/about/presentation/about_page.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/help/presentation/help_center_page.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_list_filter.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        MaterialPageRoute<void>(builder: (_) => DiagnosticsPage()),
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
      label: 'Open Help Center',
      icon: Icons.help_outline,
      onInvoke: (context, ref) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HelpCenterPage()),
      ),
    ),
    CommandPaletteAction(
      label: 'Keyboard shortcuts',
      icon: Icons.keyboard_outlined,
      onInvoke: (context, ref) => showKeyboardShortcutsDialog(context),
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

/// One flattened, keyboard-navigable row — either an action or a session.
final class _PaletteEntry {
  const _PaletteEntry({
    required this.icon,
    required this.label,
    required this.onInvoke,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onInvoke;
}

final class _CommandPaletteDialogState
    extends ConsumerState<_CommandPaletteDialog> {
  final _controller = TextEditingController();
  final _listScrollController = ScrollController();
  String _query = '';
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text;
        _highlightedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _invoke(CommandPaletteAction action) {
    Navigator.of(context).pop();
    unawaited(Future.sync(() => action.onInvoke(context, ref)));
  }

  void _openSessionEntry(SessionSummary session) {
    Navigator.of(context).pop();
    _openSession(context, session.sessionId);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event, int entryCount) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (entryCount == 0) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(
          () => _highlightedIndex = (_highlightedIndex + 1) % entryCount,
        );
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(
          () => _highlightedIndex =
              (_highlightedIndex - 1 + entryCount) % entryCount,
        );
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
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

    final entries = [
      for (final action in matchedActions)
        _PaletteEntry(
          icon: action.icon,
          label: action.label,
          subtitle: action.subtitle,
          onInvoke: () => _invoke(action),
        ),
      for (final session in matchedSessions)
        _PaletteEntry(
          icon: Icons.history_rounded,
          label: session.projectPath ?? session.sanitizedProjectDirName,
          subtitle: 'Open session',
          onInvoke: () => _openSessionEntry(session),
        ),
    ];
    final highlighted = entries.isEmpty
        ? -1
        : _highlightedIndex.clamp(0, entries.length - 1);

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
          child: Focus(
            onKeyEvent: (node, event) =>
                _handleKey(node, event, entries.length),
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
                      if (highlighted >= 0) {
                        entries[highlighted].onInvoke();
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: colors.border),
                Flexible(
                  child: entries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Text(
                            'No matching commands or sessions.',
                            style: context.typography.caption,
                          ),
                        )
                      : ListView.builder(
                          controller: _listScrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: Spacing.xs,
                          ),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _PaletteRow(
                              icon: entry.icon,
                              label: entry.label,
                              subtitle: entry.subtitle,
                              highlighted: index == highlighted,
                              onTap: entry.onInvoke,
                              onHover: () =>
                                  setState(() => _highlightedIndex = index),
                            );
                          },
                        ),
                ),
              ],
            ),
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
    required this.highlighted,
    this.subtitle,
    this.onHover,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback? onHover;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: onHover == null ? null : (_) => onHover!(),
      child: Semantics(
        button: true,
        selected: highlighted,
        label: subtitle == null ? label : '$label, $subtitle',
        child: AnimatedContainer(
          duration: MotionTokens.fast,
          curve: MotionTokens.standardCurve,
          color: highlighted ? colors.surfaceAlt : Colors.transparent,
          child: InkWell(
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
          ),
        ),
      ),
    );
  }
}
