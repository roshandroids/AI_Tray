import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// One row in the keyboard shortcuts list — [keys] as already-formatted
/// display text (e.g. `'⌘K'`), not parsed from a `LogicalKeyboardKey`.
final class KeyboardShortcut {
  const KeyboardShortcut({required this.keys, required this.description});

  final String keys;
  final String description;
}

/// Every global shortcut `AppShell._onKey` actually handles — kept in sync
/// by hand since it mirrors a raw key-event switch, not a declarative
/// shortcut map that could be introspected.
const List<KeyboardShortcut> globalKeyboardShortcuts = [
  KeyboardShortcut(keys: '⌘K', description: 'Open the command palette'),
  KeyboardShortcut(keys: '⌘R', description: 'Refresh usage now'),
  KeyboardShortcut(keys: '⌘1', description: 'Go to Dashboard'),
  KeyboardShortcut(keys: '⌘2', description: 'Go to Sessions'),
  KeyboardShortcut(keys: '⌘3', description: 'Go to Queue'),
  KeyboardShortcut(keys: '⌘4 / ⌘L', description: 'Go to Logs'),
  KeyboardShortcut(keys: '⌘5 / ⌘,', description: 'Go to Settings'),
];

/// Shows the global keyboard shortcuts list (V4 §2.5).
Future<void> showKeyboardShortcutsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keyboard shortcuts'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final shortcut in globalKeyboardShortcuts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        shortcut.keys,
                        style: context.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        shortcut.description,
                        style: context.typography.body,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
