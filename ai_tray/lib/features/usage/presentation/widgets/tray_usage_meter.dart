import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Terminal-style usage meter with animated lavender fill (PD-020).
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
          Text(
            label.toUpperCase(),
            style: type.sectionTitle.copyWith(
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
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
              const SizedBox(width: Spacing.md),
              SizedBox(
                width: 48,
                child: Text(
                  '$shown%',
                  textAlign: TextAlign.right,
                  style: type.meterValue.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (resetsAtRaw != null && resetsAtRaw!.trim().isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text('Resets', style: type.muted),
            const SizedBox(height: 2),
            Text(resetsAtRaw!.trim(), style: type.body),
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
