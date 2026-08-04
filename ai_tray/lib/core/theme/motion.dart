import 'package:flutter/material.dart';

/// Canonical animation durations and curves (V3 design system) — the one
/// place hover/selection/transition motion values come from, so timing
/// stays consistent instead of every widget picking its own numbers.
abstract final class MotionTokens {
  /// Hover highlights, focus rings, small state toggles.
  static const Duration fast = Duration(milliseconds: 120);

  /// Selection changes, expand/collapse, list highlight moves.
  static const Duration standard = Duration(milliseconds: 200);

  /// Counters, progress rings, larger content transitions.
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;

  /// Whether the platform/user has requested reduced motion — check this
  /// before starting a repeating or decorative animation.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
