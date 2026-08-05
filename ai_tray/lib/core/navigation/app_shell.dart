import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/navigation/command_palette.dart';
import 'package:ai_tray/core/navigation/product_tour_keys.dart';
import 'package:ai_tray/core/theme/breakpoints.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_browser_page.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_open_request.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_page.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/presentation/usage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persistent app shell: a nav rail wrapping the top-level destinations
/// (V3 redesign) so moving between Dashboard/Sessions/Queue/Logs/Settings
/// no longer pushes a new full-screen route for every hop.
final class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

final class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final meta =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (!meta) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyK) {
      unawaited(showCommandPalette(context, ref));
      return true;
    }
    if (key == LogicalKeyboardKey.keyR) {
      unawaited(ref.read(usageRepositoryProvider).refresh(manual: true));
      return true;
    }
    if (key == LogicalKeyboardKey.comma) {
      _select(AppDestination.settings);
      return true;
    }
    if (key == LogicalKeyboardKey.keyL) {
      _select(AppDestination.logs);
      return true;
    }
    for (final destination in AppDestination.values) {
      if (key == _digitKey(destination.shortcutDigit)) {
        _select(destination);
        return true;
      }
    }
    return false;
  }

  LogicalKeyboardKey _digitKey(int digit) => switch (digit) {
    1 => LogicalKeyboardKey.digit1,
    2 => LogicalKeyboardKey.digit2,
    3 => LogicalKeyboardKey.digit3,
    4 => LogicalKeyboardKey.digit4,
    _ => LogicalKeyboardKey.digit5,
  };

  void _select(AppDestination destination) {
    ref.read(appShellDestinationProvider.notifier).select(destination);
  }

  Future<void> _openSessionDetail(String sessionId) {
    _select(AppDestination.sessions);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionDetailPage(sessionId: sessionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<int>(settingsOpenRequestProvider, (previous, next) {
        if (previous == next) return;
        _select(AppDestination.settings);
      })
      ..listen<SessionDetailOpenRequestState>(
        sessionDetailOpenRequestProvider,
        (previous, next) {
          if (next == null || previous == next) return;
          unawaited(_openSessionDetail(next.sessionId));
        },
      );

    final selected = ref.watch(appShellDestinationProvider);
    final colors = context.colors;
    final tourKeys = ref.watch(productTourKeysProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Collapses to icon-only at Compact width (V4 §2.2) instead of
          // always reserving space for labels.
          final extended =
              windowSizeForWidth(constraints.maxWidth) != WindowSize.compact;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selected.index,
                onDestinationSelected: (index) =>
                    _select(AppDestination.values[index]),
                extended: extended,
                labelType: extended ? null : NavigationRailLabelType.none,
                destinations: [
                  for (final destination in AppDestination.values)
                    NavigationRailDestination(
                      icon: _withTourKey(
                        _tourKeyFor(destination, tourKeys),
                        Icon(destination.icon),
                      ),
                      selectedIcon: _withTourKey(
                        _tourKeyFor(destination, tourKeys),
                        Icon(destination.selectedIcon),
                      ),
                      label: Text(destination.label),
                    ),
                ],
              ),
              VerticalDivider(width: 1, color: colors.border),
              Expanded(
                child: IndexedStack(
                  index: selected.index,
                  children: const [
                    UsagePage(),
                    SessionBrowserPage(),
                    ResumeQueuePage(),
                    LogsPage(),
                    SettingsPage(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// `null` for destinations the Product Tour (V4 §9.3) doesn't spotlight.
GlobalKey? _tourKeyFor(AppDestination destination, ProductTourKeys keys) =>
    switch (destination) {
      AppDestination.dashboard => keys.dashboard,
      AppDestination.sessions => keys.sessions,
      AppDestination.queue => keys.queue,
      AppDestination.logs || AppDestination.settings => null,
    };

/// The unselected and selected icon variants for one destination are
/// mutually exclusive in the tree at any moment (`NavigationRail` swaps
/// between them), so both can safely share the same key.
Widget _withTourKey(GlobalKey? key, Widget child) =>
    key == null ? child : KeyedSubtree(key: key, child: child);
