import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';

/// Compact status pill with emoji + label (PD-020).
final class TrayStatusPill extends StatelessWidget {
  const TrayStatusPill({required this.kind, super.key, this.compact = false});

  final TrayStatusKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      TrayStatusKind.live => context.colors.success,
      TrayStatusKind.cached => context.colors.warning,
      TrayStatusKind.error => context.colors.error,
      TrayStatusKind.refreshing => context.colors.statusRefreshing,
      TrayStatusKind.idle => context.colors.statusIdle,
    };
    final label = UsageStatusMapper.label(kind);
    final emoji = UsageStatusMapper.emoji(kind);

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Spacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Spacing.sm : Spacing.md,
            vertical: Spacing.xs,
          ),
          child: Text(
            compact ? '$emoji $label' : '$emoji $label',
            style: context.typography.badge.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
