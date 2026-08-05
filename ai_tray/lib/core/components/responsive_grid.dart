import 'package:ai_tray/core/theme/breakpoints.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:flutter/material.dart';

/// Reflows [children] into 1/2/3 columns at compact/wide/ultrawide (V4
/// §2.1) — replaces the hard-720px-cap-vs-no-cap split with one grid every
/// multi-card page section can share. Order-preserving row-major flow.
final class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    super.key,
    this.spacing = Spacing.md,
    this.runSpacing = Spacing.md,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (windowSizeForWidth(constraints.maxWidth)) {
          WindowSize.compact => 1,
          WindowSize.wide => 2,
          WindowSize.ultrawide => 3,
        };
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
