import 'package:flutter/material.dart';

/// Top-level destinations in the persistent app shell (V3 nav rail).
enum AppDestination { dashboard, sessions, queue, logs, settings }

extension AppDestinationChrome on AppDestination {
  String get label => switch (this) {
    AppDestination.dashboard => 'Dashboard',
    AppDestination.sessions => 'Sessions',
    AppDestination.queue => 'Queue',
    AppDestination.logs => 'Logs',
    AppDestination.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    AppDestination.dashboard => Icons.space_dashboard_outlined,
    AppDestination.sessions => Icons.history_outlined,
    AppDestination.queue => Icons.pending_actions_outlined,
    AppDestination.logs => Icons.article_outlined,
    AppDestination.settings => Icons.settings_outlined,
  };

  IconData get selectedIcon => switch (this) {
    AppDestination.dashboard => Icons.space_dashboard_rounded,
    AppDestination.sessions => Icons.history_rounded,
    AppDestination.queue => Icons.pending_actions_rounded,
    AppDestination.logs => Icons.article_rounded,
    AppDestination.settings => Icons.settings_rounded,
  };

  /// ⌘1..⌘5 quick-switch shortcut for this destination.
  int get shortcutDigit => index + 1;
}
