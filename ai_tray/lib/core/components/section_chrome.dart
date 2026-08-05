import 'package:ai_tray/core/theme/component_theme.dart';
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
    this.repairLabel,
    this.onRepair,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final double labelWidth;

  /// Optional repair-action slot (V4 §9.5) — every Diagnostics health
  /// check gets somewhere to fix the problem inline, not just see it.
  final String? repairLabel;
  final VoidCallback? onRepair;

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
          if (repairLabel != null && onRepair != null)
            Padding(
              padding: const EdgeInsets.only(left: Spacing.sm),
              child: InkWell(
                onTap: onRepair,
                child: Text(
                  repairLabel!,
                  style: type.label.copyWith(color: context.colors.info),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bordered section container.
///
/// Use the default constructor for a single [child], or [SectionCard.divided]
/// to lay out [children] separated by hairline dividers (e.g. settings rows).
final class SectionCard extends StatelessWidget {
  const SectionCard({
    required Widget this.child,
    super.key,
    this.title,
    this.padding = const EdgeInsets.all(Spacing.lg),
  }) : children = null;

  const SectionCard.divided({
    required this.children,
    super.key,
    this.title,
    this.padding = const EdgeInsets.all(Spacing.lg),
  }) : child = null;

  final Widget? child;
  final List<Widget>? children;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = children;
    final body = items == null
        ? child!
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Divider(height: Spacing.md, color: colors.border),
              ],
            ],
          );
    return DecoratedBox(
      decoration: ComponentTheme.panel(colors),
      // ListTile/InkWell children paint their background and ink splashes
      // on the nearest Material ancestor — without this, this DecoratedBox
      // hides those effects (Flutter's ListTile debug assertion catches it).
      child: Material(
        type: MaterialType.transparency,
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
              body,
            ],
          ),
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
