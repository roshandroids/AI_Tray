import 'package:ai_tray/core/components/progress_ring.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Displays percentage-only or absolute provider quota metrics.
final class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.percent,
    super.key,
    this.resetsAtRaw,
    this.subtitle,
    this.sparklineValues,
    this.value,
    this.total,
    this.unit,
    this.remainingPercent,
    this.unlimited = false,
    this.refreshing = false,
    this.available = true,
  });

  final String label;
  final double percent;
  final String? resetsAtRaw;
  final String? subtitle;
  final List<double>? sparklineValues;
  final num? value;
  final num? total;
  final String? unit;
  final double? remainingPercent;
  final bool unlimited;
  final bool refreshing;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final shown = percent.clamp(0.0, 100.0).round();
    final band = colors.usageBand(percent);
    final primaryText = _primaryText(shown);
    final remainingText = _remainingText();

    return Semantics(
      container: true,
      label: '$label metric',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              ProgressRing(
                percent: percent,
                color: band,
                refreshing: refreshing,
                available: available,
              ),
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
                      primaryText,
                      style: type.monoData.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (remainingText != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(remainingText, style: type.caption),
                    ],
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
      ),
    );
  }

  String _primaryText(int shown) {
    if (!available) return 'Usage unavailable';
    if (unlimited) return 'Unlimited';
    if (value != null && total != null) {
      return '${_format(value!)} / ${_format(total!)} '
          '${_unitLabel(value!)} used';
    }
    if (value != null) {
      return '${_format(value!)} ${_unitLabel(value!)} used';
    }
    return '$shown% used';
  }

  String? _remainingText() {
    if (!available) return null;
    if (unlimited) return 'No usage limit';
    final parts = <String>[];
    if (value != null && total != null) {
      final remaining = (total! - value!).clamp(0, total!);
      parts.add('${_format(remaining)} ${_unitLabel(remaining)} remaining');
    }
    if (remainingPercent != null) {
      parts.add('${_format(remainingPercent!)}% remaining');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String _unitLabel(num amount) {
    final normalized = unit?.trim();
    if (normalized == null || normalized.isEmpty) return 'units';
    if (amount == 1 && normalized.endsWith('s')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _format(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
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
