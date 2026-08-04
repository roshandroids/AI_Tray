import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// ASCII dashed separator — terminal vibe (PD-020).
final class AsciiSeparator extends StatelessWidget {
  const AsciiSeparator({super.key, this.char = '─', this.length = 34});

  final String char;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Text(
        List.filled(length, char).join(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: context.typography.muted.copyWith(
          letterSpacing: 0.5,
          height: 1,
          color: context.colors.divider,
        ),
      ),
    );
  }
}

/// Uppercase section label used across terminal panels.
final class TerminalSectionLabel extends StatelessWidget {
  const TerminalSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.typography.sectionTitle.copyWith(
        letterSpacing: 1.1,
        fontSize: 11,
      ),
    );
  }
}

/// Dense key / value terminal row.
final class TerminalKvRow extends StatelessWidget {
  const TerminalKvRow({
    required this.label,
    required this.value,
    super.key,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: type.muted),
          ),
          Expanded(
            child: Text(
              value,
              style: type.body.copyWith(color: valueColor ?? type.body.color),
            ),
          ),
        ],
      ),
    );
  }
}
