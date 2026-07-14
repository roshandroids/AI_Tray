import 'package:ai_tray/core/components/usage_progress_bar.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Compact labeled usage meter for legacy layouts / goldens (PD-021).
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
            style: type.section.copyWith(
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(child: UsageProgressBar(percent: clamped)),
              const SizedBox(width: Spacing.md),
              SizedBox(
                width: 48,
                child: Text(
                  '$shown%',
                  textAlign: TextAlign.right,
                  style: type.monoData.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (resetsAtRaw != null && resetsAtRaw!.trim().isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text('Resets', style: type.caption),
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
