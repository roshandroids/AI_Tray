import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Compact horizontal usage meter (PD-021).
final class UsageProgressBar extends StatelessWidget {
  const UsageProgressBar({
    required this.percent,
    super.key,
    this.height = Spacing.meterHeight,
  });

  final double percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clamped = percent.clamp(0.0, 100.0);
    final fill = colors.usageBand(clamped);

    return Semantics(
      label: '${clamped.round()} percent used',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.full),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.meterTrack),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped / 100,
                child: ColoredBox(color: fill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
