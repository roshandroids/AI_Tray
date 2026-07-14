import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';

/// Compact ● Live / Cached / … status badge (PD-021).
final class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.kind,
    super.key,
    this.compact = false,
  });

  final TrayStatusKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _color(kind, colors);
    final label = UsageStatusMapper.label(kind);

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Spacing.sm : Spacing.md - 4,
            vertical: Spacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                label,
                style: context.typography.status.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _color(TrayStatusKind kind, TrayColorTokens colors) {
    return switch (kind) {
      TrayStatusKind.live => colors.success,
      TrayStatusKind.cached => colors.warning,
      TrayStatusKind.error => colors.error,
      TrayStatusKind.refreshing => colors.info,
      TrayStatusKind.idle => colors.textMuted,
    };
  }
}

/// Auth / Parser / Cache health line.
final class HealthIndicator extends StatelessWidget {
  const HealthIndicator({
    required this.label,
    required this.ok,
    super.key,
    this.detail,
  });

  final String label;
  final bool ok;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = detail ?? (ok ? '✓ OK' : '✗ Check');
    return InfoRowCompat(
      label: label,
      value: value,
      valueColor: ok ? colors.success : colors.error,
    );
  }
}

/// Local info row helper to avoid circular imports with section_chrome.
final class InfoRowCompat extends StatelessWidget {
  const InfoRowCompat({
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
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: type.label),
          ),
          Expanded(
            child: Text(
              value,
              style: type.monoData.copyWith(
                color: valueColor ?? type.monoData.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
