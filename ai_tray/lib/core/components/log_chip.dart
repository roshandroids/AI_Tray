import 'package:ai_tray/core/components/status_presentation.dart';
import 'package:ai_tray/core/logging/log_level.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Colored log-level chip (PD-021).
final class LogChip extends StatelessWidget {
  const LogChip({required this.level, super.key});

  final LogLevel level;

  @override
  Widget build(BuildContext context) {
    final presentation = StatusPresentation.fromLogLevel(
      level,
      context.colors,
    );
    final color = presentation.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: 2,
        ),
        child: Text(
          presentation.label,
          style: context.typography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
