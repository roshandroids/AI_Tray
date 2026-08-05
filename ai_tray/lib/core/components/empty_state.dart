import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Shared empty/no-results chrome (V4 §1.3) — icon + title + body + optional
/// action, centered with [Spacing.lg] padding. Callers own the copy (e.g.
/// `TrayEmptyState`'s per-`FailureCode` text); this only owns layout.
final class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.icon,
    this.body,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData? icon;
  final String title;
  final String? body;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final semanticsLabel = [
      title,
      if (body != null) body,
      if (hint != null) hint,
    ].join('. ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Semantics(
          container: true,
          label: semanticsLabel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                ExcludeSemantics(
                  child: Icon(icon, color: context.colors.textMuted, size: 28),
                ),
                const SizedBox(height: Spacing.sm),
              ],
              Text(title, style: type.section),
              if (body != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(body!, style: type.caption),
              ],
              if (hint != null) ...[
                const SizedBox(height: Spacing.md),
                Text(hint!, style: type.caption),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Spacing.md),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
