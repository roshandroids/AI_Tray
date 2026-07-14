import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';

/// Back-compat pill that forwards to [StatusBadge] (PD-021).
final class TrayStatusPill extends StatelessWidget {
  const TrayStatusPill({required this.kind, super.key, this.compact = false});

  final TrayStatusKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(kind: kind, compact: compact);
  }
}
