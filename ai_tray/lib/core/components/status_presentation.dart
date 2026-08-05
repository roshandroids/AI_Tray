import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/logging/log_level.dart';
import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:flutter/material.dart';

/// Shared icon/color/label resolution for the app's independent status
/// enums (V4 §1.2) — the status badge, log chip and queue chip widgets all
/// render from this instead of carrying their own color switch, so a
/// palette or wording change only happens in one place.
@immutable
final class StatusPresentation {
  const StatusPresentation({required this.color, required this.label});

  factory StatusPresentation.fromTrayStatusKind(
    TrayStatusKind kind,
    TrayColorTokens colors,
  ) {
    final color = switch (kind) {
      TrayStatusKind.live => colors.success,
      TrayStatusKind.cached => colors.warning,
      TrayStatusKind.error => colors.error,
      TrayStatusKind.refreshing => colors.info,
      TrayStatusKind.idle => colors.textMuted,
    };
    return StatusPresentation(
      color: color,
      label: UsageStatusMapper.label(kind),
    );
  }

  factory StatusPresentation.fromResumeQueueStatus(
    ResumeQueueStatus status,
    TrayColorTokens colors,
  ) {
    final (label, color) = switch (status) {
      ResumeQueueStatus.pending => ('Pending', colors.textMuted),
      ResumeQueueStatus.running => ('Running', colors.info),
      ResumeQueueStatus.succeeded => ('Succeeded', colors.success),
      ResumeQueueStatus.failed => ('Failed', colors.error),
      ResumeQueueStatus.cancelled => ('Cancelled', colors.textMuted),
    };
    return StatusPresentation(color: color, label: label);
  }

  factory StatusPresentation.fromLogLevel(
    LogLevel level,
    TrayColorTokens colors,
  ) {
    final color = switch (level) {
      LogLevel.debug => colors.textMuted,
      LogLevel.info => colors.success,
      LogLevel.success => colors.cyanAccent,
      LogLevel.warning => colors.warning,
      LogLevel.error => colors.error,
    };
    return StatusPresentation(color: color, label: level.label);
  }

  final Color color;
  final String label;
}
