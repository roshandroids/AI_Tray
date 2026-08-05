import 'dart:async';

import 'package:ai_tray/core/theme/component_theme.dart';
import 'package:ai_tray/core/theme/motion.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// One stop in a coach-mark tour — [targetKey] must already be attached to
/// a live widget in the tree when the tour reaches this step, or the
/// spotlight silently degrades to a centered callout with no highlight
/// (see [computeHighlightRect]).
final class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.body,
  });

  final GlobalKey targetKey;
  final String title;
  final String body;
}

/// The screen-space rectangle to spotlight for [key]'s current render
/// object, inflated by [padding] — `Rect.zero` if the key isn't attached
/// to anything (unmounted target, wrong screen, etc.). Pulled out as a
/// pure function so the geometry is unit-testable without a live overlay.
Rect computeHighlightRect(GlobalKey key, {double padding = 6}) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.attached) return Rect.zero;
  final origin = renderObject.localToGlobal(Offset.zero);
  return (origin & renderObject.size).inflate(padding);
}

/// Runs [steps] as a sequential coach-mark tour (V4 §9.3) — an
/// `Overlay`-based spotlight with a scrim dimming everything but the
/// current target. The scrim is a deliberate, narrow exception to the
/// design system's "no shadows/overlays" rule (Section 0 of the V4 plan):
/// it's a functional focus mechanism, not decorative elevation.
///
/// Resolves once the tour is finished or skipped. A step whose target
/// isn't currently attached (e.g. the app was resized mid-tour) shows a
/// centered callout with no highlight rather than crashing.
Future<void> showCoachMarks(BuildContext context, List<CoachMarkStep> steps) {
  if (steps.isEmpty) return Future<void>.value();
  final overlayState = Overlay.of(context);
  final completer = Completer<void>();
  late OverlayEntry entry;
  var index = 0;

  void finish() {
    entry.remove();
    if (!completer.isCompleted) completer.complete();
  }

  void next() {
    index++;
    if (index >= steps.length) {
      finish();
    } else {
      entry.markNeedsBuild();
    }
  }

  entry = OverlayEntry(
    builder: (overlayContext) => _CoachMarkFrame(
      step: steps[index],
      stepNumber: index + 1,
      totalSteps: steps.length,
      isLastStep: index == steps.length - 1,
      onNext: next,
      onSkip: finish,
    ),
  );
  overlayState.insert(entry);
  return completer.future;
}

final class _CoachMarkFrame extends StatelessWidget {
  const _CoachMarkFrame({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isLastStep,
    required this.onNext,
    required this.onSkip,
  });

  final CoachMarkStep step;
  final int stepNumber;
  final int totalSteps;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final rect = computeHighlightRect(step.targetKey);
    final screen = MediaQuery.sizeOf(context);
    final hasTarget = rect != Rect.zero;

    const calloutWidth = 300.0;
    final calloutBelow = hasTarget && rect.bottom + 160 < screen.height;
    final calloutTop = hasTarget
        ? (calloutBelow ? rect.bottom + Spacing.sm : rect.top - 160)
        : screen.height / 2 - 80;
    final calloutLeft = hasTarget
        ? (rect.left + rect.width / 2 - calloutWidth / 2).clamp(
            Spacing.md,
            screen.width - calloutWidth - Spacing.md,
          )
        : screen.width / 2 - calloutWidth / 2;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onSkip,
            child: CustomPaint(
              painter: _ScrimPainter(highlightRect: rect),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: MotionTokens.reduced(context)
              ? Duration.zero
              : MotionTokens.standard,
          curve: MotionTokens.standardCurve,
          left: calloutLeft,
          top: calloutTop,
          width: calloutWidth,
          child: _CoachMarkCallout(
            step: step,
            stepNumber: stepNumber,
            totalSteps: totalSteps,
            isLastStep: isLastStep,
            onNext: onNext,
            onSkip: onSkip,
          ),
        ),
      ],
    );
  }
}

final class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.highlightRect});

  final Rect highlightRect;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scrimPath = highlightRect == Rect.zero
        ? full
        : Path.combine(
            PathOperation.difference,
            full,
            Path()..addRRect(
              RRect.fromRectAndRadius(
                highlightRect,
                const Radius.circular(8),
              ),
            ),
          );
    canvas.drawPath(
      scrimPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    if (highlightRect != Rect.zero) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) =>
      oldDelegate.highlightRect != highlightRect;
}

final class _CoachMarkCallout extends StatelessWidget {
  const _CoachMarkCallout({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isLastStep,
    required this.onNext,
    required this.onSkip,
  });

  final CoachMarkStep step;
  final int stepNumber;
  final int totalSteps;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Step $stepNumber of $totalSteps: ${step.title}. ${step.body}',
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: ComponentTheme.panel(colors),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$stepNumber / $totalSteps',
                  style: type.caption.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  step.title,
                  style: type.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Spacing.xs),
                Text(step.body, style: type.caption),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    TextButton(
                      key: const ValueKey('coach-mark-skip'),
                      onPressed: onSkip,
                      child: const Text('Skip'),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const ValueKey('coach-mark-next'),
                      onPressed: onNext,
                      child: Text(isLastStep ? 'Done' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
