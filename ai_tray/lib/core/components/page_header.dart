import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Shared page-top chrome (V4 §1.4) — one header primitive instead of each
/// shell-hosted page nesting its own `Scaffold`/`AppBar` inside `AppShell`'s
/// single outer `Scaffold`.
final class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    super.key,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: Spacing.sm),
            ],
            Expanded(
              child: Text(title, style: context.typography.title),
            ),
            for (final action in actions) ...[
              const SizedBox(width: Spacing.sm),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
