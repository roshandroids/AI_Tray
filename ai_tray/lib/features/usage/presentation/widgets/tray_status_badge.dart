import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Compact status badge: color + text (never color alone).
enum TrayStatusKind { live, cached, error, refreshing, idle }

final class TrayStatusBadge extends StatelessWidget {
  const TrayStatusBadge({
    required this.kind,
    super.key,
    this.detail,
  });

  final TrayStatusKind kind;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(kind, context.colors);
    return Semantics(
      label: detail == null ? spec.label : '${spec.label}. $detail',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: spec.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Spacing.radiusSm),
          border: Border.all(color: spec.color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
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
                    color: spec.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(spec.label, style: context.typography.badge),
            ],
          ),
        ),
      ),
    );
  }

  static ({String label, Color color}) _specFor(
    TrayStatusKind kind,
    TrayColorTokens colors,
  ) {
    return switch (kind) {
      TrayStatusKind.live => (label: 'Live', color: colors.success),
      TrayStatusKind.cached => (label: 'Cached', color: colors.warning),
      TrayStatusKind.error => (label: 'Error', color: colors.error),
      TrayStatusKind.refreshing => (
        label: 'Refreshing',
        color: colors.statusRefreshing,
      ),
      TrayStatusKind.idle => (label: 'Waiting', color: colors.statusIdle),
    };
  }
}
