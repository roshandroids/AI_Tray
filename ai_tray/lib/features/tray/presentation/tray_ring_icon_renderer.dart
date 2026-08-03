import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

/// Renders compact circular tray icons to temp PNG files (PD-021).
///
/// `tray_manager` only accepts image paths — no live Flutter widgets —
/// so we paint a ring and write PNG bytes for macOS `setIcon`.
abstract final class TrayRingIconRenderer {
  static const _size = 44;

  static Future<String> render({
    required TrayStatusKind kind,
    required double? sessionPercent,
  }) async {
    const colors = TrayColorTokens.dark;
    final dir = Directory('${Directory.systemTemp.path}/ai_tray_tray_icons');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final pct = sessionPercent?.clamp(0.0, 100.0);
    final bucket = pct == null ? 'na' : (pct / 5).round() * 5;
    final file = File('${dir.path}/${kind.name}_$bucket.png');

    if (file.existsSync() &&
        DateTime.now().difference(file.lastModifiedSync()) <
            const Duration(minutes: 30)) {
      return file.path;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paint(
      canvas,
      const Size(44, 44),
      kind: kind,
      percent: pct,
      colors: colors,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(_size, _size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file.path;
  }

  static void _paint(
    Canvas canvas,
    Size size, {
    required TrayStatusKind kind,
    required double? percent,
    required TrayColorTokens colors,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 4.0;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    late Color ringColor;
    var dashed = false;
    var progress = (percent ?? 0) / 100;
    late String centerText;

    switch (kind) {
      case TrayStatusKind.refreshing:
        ringColor = colors.info;
        progress = 0.75;
        centerText = percent == null ? '…' : '${percent.round()}';
      case TrayStatusKind.error:
        ringColor = colors.error;
        progress = 1;
        centerText = '!';
      case TrayStatusKind.idle:
        ringColor = colors.textMuted;
        dashed = true;
        progress = 1;
        centerText = '--';
      case TrayStatusKind.cached:
        ringColor = colors.warning;
        dashed = true;
        centerText = percent == null ? '--' : '${percent.round()}';
      case TrayStatusKind.live:
        ringColor = percent == null
            ? colors.success
            : colors.usageBand(percent);
        centerText = percent == null ? '--' : '${percent.round()}';
    }

    final track = Paint()
      ..color = colors.meterTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    if (dashed) {
      const segments = 20;
      const sweep = 2 * math.pi / segments;
      for (var i = 0; i < segments; i += 2) {
        canvas.drawArc(rect, start + i * sweep, sweep * 0.65, false, paint);
      }
    } else if (progress > 0) {
      canvas.drawArc(rect, start, 2 * math.pi * progress, false, paint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(
          color: kind == TrayStatusKind.error ? ringColor : colors.textPrimary,
          fontSize: size.width * (kind == TrayStatusKind.error ? 0.42 : 0.32),
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrainsMono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}
