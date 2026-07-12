import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Flat lavender usage meter with animated fill (PD-013 / PD-014).
final class TrayUsageMeter extends StatelessWidget {
  const TrayUsageMeter({
    required this.percent,
    required this.label,
    super.key,
    this.resetsAtRaw,
  });

  final double percent;
  final String label;
  final String? resetsAtRaw;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final clamped = percent.clamp(0.0, 100.0);
    final shown = clamped.round();

    return Semantics(
      label: _semanticsLabel(shown),
      value: '$shown%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: type.sectionTitle),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Spacing.radiusSm),
                  child: SizedBox(
                    height: Spacing.meterHeight,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: clamped / 100),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: colors.meterTrack),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value.clamp(0.0, 1.0),
                              child: ColoredBox(color: colors.meterFill),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text('$shown% used', style: type.meterValue),
            ],
          ),
          if (resetsAtRaw != null && resetsAtRaw!.trim().isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'Resets ${resetsAtRaw!.trim()}',
              style: type.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _semanticsLabel(int shown) {
    final reset = resetsAtRaw?.trim();
    if (reset == null || reset.isEmpty) {
      return '$label, $shown percent used';
    }
    return '$label, $shown percent used, resets $reset';
  }
}
