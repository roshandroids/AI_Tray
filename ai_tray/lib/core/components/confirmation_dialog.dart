import 'package:flutter/material.dart';

/// Shows a confirm/cancel dialog and resolves to whether the user
/// confirmed (V4 §1's `ConfirmationDialog` primitive) — used ahead of any
/// destructive or hard-to-reverse action (queue cancel, future settings
/// danger-zone actions).
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: colors.error)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
