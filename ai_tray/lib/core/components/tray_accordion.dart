import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// How [TrayAccordion] styles its header title.
enum AccordionHeaderStyle {
  /// Regular body-weight title — disclosures embedded in list rows/cards
  /// (settings presets, session cards, FAQ entries).
  plain,

  /// Uppercase caption title matching `SectionCard`'s header, for
  /// disclosures that stand alone as their own panel.
  sectionLabel,
}

/// Shared expand/collapse disclosure, replacing Flutter's [ExpansionTile]
/// app-wide. Always fully controlled by [isExpanded]/[onExpandedChanged] —
/// no internal state, no `initiallyExpanded`, no key tricks to force a
/// rebuild on toggle — so callers never need to fake control the way the
/// settings preset pickers used to (`ValueKey('theme-$expanded')`, which
/// destroyed and rebuilt their whole subtree, including in-progress search
/// text, on every toggle).
///
/// [bodyBuilder] is only invoked while [isExpanded] is `true`, matching
/// [ExpansionTile]'s lazy-mount behavior for collapsed content.
final class TrayAccordion extends StatelessWidget {
  const TrayAccordion({
    required this.title,
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.bodyBuilder,
    super.key,
    this.subtitle,
    this.trailing,
    this.headerStyle = AccordionHeaderStyle.plain,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.expandedHeight,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final WidgetBuilder bodyBuilder;
  final AccordionHeaderStyle headerStyle;
  final EdgeInsetsGeometry padding;

  /// When set, the expanded body is constrained to this height instead of
  /// sizing to its content — used by `ResizablePanel`.
  final double? expandedHeight;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final titleStyle = switch (headerStyle) {
      AccordionHeaderStyle.plain => type.body.copyWith(
        fontWeight: FontWeight.w600,
      ),
      AccordionHeaderStyle.sectionLabel => type.section.copyWith(
        fontSize: 12,
        letterSpacing: 0.8,
        color: colors.textSecondary,
      ),
    };
    final titleText = headerStyle == AccordionHeaderStyle.sectionLabel
        ? title.toUpperCase()
        : title;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onExpandedChanged(!isExpanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titleText, style: titleStyle),
                      if (subtitle != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(subtitle!, style: type.caption),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: Spacing.sm),
                  trailing!,
                ],
                const SizedBox(width: Spacing.sm),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: animationDuration,
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: animationDuration,
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: !isExpanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: AnimatedSwitcher(
                      duration: animationDuration ~/ 2,
                      child: KeyedSubtree(
                        key: const ValueKey('expanded'),
                        child: expandedHeight != null
                            ? SizedBox(
                                height: expandedHeight,
                                child: Builder(builder: bodyBuilder),
                              )
                            : Builder(builder: bodyBuilder),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
