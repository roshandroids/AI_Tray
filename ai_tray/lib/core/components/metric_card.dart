import 'package:ai_tray/core/components/progress_ring.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Dense metric card: label + ring + reset copy (PD-021).
final class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.percent,
    super.key,
    this.resetsAtRaw,
    this.subtitle,
    this.sparklineValues,
  });

  final String label;
  final double percent;
  final String? resetsAtRaw;
  final String? subtitle;
  final List<double>? sparklineValues;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final shown = percent.clamp(0.0, 100.0).round();
    final band = colors.usageBand(percent);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            ProgressRing(percent: percent, color: band),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: type.section.copyWith(
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '$shown% used',
                    style: type.monoData.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (resetsAtRaw != null &&
                      resetsAtRaw!.trim().isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Resets ${resetsAtRaw!.trim()}',
                      style: type.caption,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(subtitle!, style: type.caption),
                  ],
                  if (sparklineValues != null &&
                      sparklineValues!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    SizedBox(
                      height: 18,
                      child: _MiniBars(
                        values: sparklineValues!,
                        color: band,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: (v.clamp(0, 100) / 100).clamp(0.12, 1.0),
                alignment: Alignment.bottomCenter,
                child: ColoredBox(color: color.withValues(alpha: 0.85)),
              ),
            ),
          ),
      ],
    );
  }
}
