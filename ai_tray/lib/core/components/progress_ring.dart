import 'dart:math' as math;

import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Circular usage progress ring with refresh and unavailable states.
final class ProgressRing extends StatefulWidget {
  const ProgressRing({
    required this.percent,
    super.key,
    this.size = Spacing.progressRingSize,
    this.strokeWidth = 5,
    this.color,
    this.dashed = false,
    this.centerOverride,
    this.showWarning = false,
    this.refreshing = false,
    this.available = true,
  });

  final double percent;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool dashed;
  final String? centerOverride;
  final bool showWarning;
  final bool refreshing;
  final bool available;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

final class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _refreshController;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncRefreshAnimation();
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRefreshAnimation();
  }

  void _syncRefreshAnimation() {
    if (widget.refreshing && !_disableAnimations && widget.available) {
      if (!_refreshController.isAnimating) {
        _refreshController.repeat();
      }
      return;
    }
    _refreshController
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = widget.percent.clamp(0.0, 100.0).round();
    final ringColor = !widget.available
        ? colors.textMuted
        : widget.refreshing
        ? colors.info
        : widget.color ?? colors.usageBand(widget.percent);
    final label = !widget.available ? '--' : widget.centerOverride ?? '$shown';
    final semanticLabel = !widget.available
        ? 'Usage unavailable'
        : widget.refreshing
        ? 'Usage refreshing, $shown percent used'
        : 'Usage $shown percent';

    return Semantics(
      label: semanticLabel,
      value: widget.available ? '$shown%' : 'Unavailable',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 0,
            end: widget.available ? widget.percent.clamp(0.0, 100.0) / 100 : 0,
          ),
          duration: _disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return AnimatedBuilder(
              animation: _refreshController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RingPainter(
                    progress: widget.refreshing ? 0.72 : value,
                    rotation: widget.refreshing ? _refreshController.value : 0,
                    trackColor: colors.meterTrack,
                    ringColor: ringColor,
                    strokeWidth: widget.strokeWidth,
                    dashed: widget.dashed || !widget.available,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: widget.showWarning
                          ? Icon(
                              Icons.priority_high_rounded,
                              size: widget.size * 0.32,
                              color: ringColor,
                            )
                          : Text(
                              label,
                              style: context.typography.monoData.copyWith(
                                fontSize: widget.size * 0.28,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                );
              },
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
    required this.rotation,
    required this.trackColor,
    required this.ringColor,
    required this.strokeWidth,
    required this.dashed,
  });

  final double progress;
  final double rotation;
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
    final start = -math.pi / 2 + (2 * math.pi * rotation);

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
        oldDelegate.rotation != rotation ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.dashed != dashed ||
        oldDelegate.trackColor != trackColor;
  }
}
