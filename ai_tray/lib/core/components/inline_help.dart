import 'package:ai_tray/core/theme/component_theme.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Token-styled contextual help (V4 §10.2) — thin wrapper around Flutter's
/// [Tooltip] so concept-introducing UI (budget cap, queue behavior,
/// provider capability differences) gets deliberate inline help instead of
/// relying on incidental `IconButton(tooltip:)` coverage.
final class InlineHelp extends StatelessWidget {
  const InlineHelp({required this.message, required this.child, super.key});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: message,
      textStyle: context.typography.caption.copyWith(color: colors.textPrimary),
      decoration: ComponentTheme.panelAlt(colors),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: child,
    );
  }
}
