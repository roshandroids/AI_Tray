import 'dart:math' as math;

import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Circular usage progress ring with center percentage (PD-021).
final class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.percent,
    super.key,
    this.size = Spacing.progressRingSize,
    this.strokeWidth = 5,
    this.color,
    this.dashed = false,
    this.centerOverride,
    this.showWarning = false,
  });

  final double percent;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool dashed;
  final String? centerOverride;
  final bool showWarning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ringColor = color ?? colors.usageBand(percent);
    final shown = percent.clamp(0.0, 100.0).round();
    final label = centerOverride ?? '$shown';

    return Semantics(
      label: 'Usage $shown percent',
      value: '$shown%',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent.clamp(0.0, 100.0) / 100),
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return CustomPaint(
              painter: _RingPainter(
                progress: value,
                trackColor: colors.meterTrack,
                ringColor: ringColor,
                strokeWidth: strokeWidth,
                dashed: dashed,
              ),
              child: Center(
                child: showWarning
                    ? Icon(
                        Icons.priority_high_rounded,
                        size: size * 0.32,
                        color: ringColor,
                      )
                    : Text(
                        label,
                        style: context.typography.monoData.copyWith(
                          fontSize: size * 0.28,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
    required this.strokeWidth,
    required this.dashed,
  });

  final double progress;
  final Color trackColor;
  final Color ringColor;
  final double strokeWidth;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    if (dashed) {
      const segments = 28;
      const sweep = 2 * math.pi / segments;
      for (var i = 0; i < segments; i += 2) {
        canvas.drawArc(rect, start + i * sweep, sweep * 0.7, false, paint);
      }
      return;
    }

    if (progress <= 0) return;
    canvas.drawArc(rect, start, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.dashed != dashed ||
        oldDelegate.trackColor != trackColor;
  }
}
