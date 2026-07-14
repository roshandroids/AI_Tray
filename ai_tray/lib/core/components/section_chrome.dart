import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Dense key / value row for terminal panels (PD-021).
final class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    super.key,
    this.valueColor,
    this.labelWidth = 112,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: type.label),
          ),
          Expanded(
            child: Text(
              value,
              style: type.monoData.copyWith(
                color: valueColor ?? type.monoData.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered section container.
final class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    super.key,
    this.title,
    this.padding = const EdgeInsets.all(Spacing.md),
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!.toUpperCase(),
                style: context.typography.section.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Subtle horizontal rule.
final class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: ColoredBox(
        color: context.colors.border,
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }
}

/// Terminal-style bordered panel (alias of [SectionCard] with defaults).
final class TerminalPanel extends StatelessWidget {
  const TerminalPanel({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(title: title, child: child);
  }
}
