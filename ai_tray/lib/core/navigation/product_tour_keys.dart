import 'package:ai_tray/core/components/coach_mark_overlay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable `GlobalKey`s for the nav rail icons a Product Tour (V4 §9.3)
/// spotlights — attached once by `AppShell`, read by whatever triggers a
/// (re)run of the tour (command palette, Settings).
final class ProductTourKeys {
  final GlobalKey dashboard = GlobalKey(debugLabel: 'tour-dashboard');
  final GlobalKey sessions = GlobalKey(debugLabel: 'tour-sessions');
  final GlobalKey queue = GlobalKey(debugLabel: 'tour-queue');
}

final productTourKeysProvider = Provider<ProductTourKeys>((ref) {
  return ProductTourKeys();
});

/// The Product Tour's fixed 3-step script — kept short per the V4 plan's
/// "keep it minimal" guidance for a feature whose visual positioning can't
/// be verified without taking screenshots.
List<CoachMarkStep> buildProductTourSteps(ProductTourKeys keys) {
  return [
    CoachMarkStep(
      targetKey: keys.dashboard,
      title: 'Dashboard',
      body: 'Usage, provider health, and quick actions at a glance.',
    ),
    CoachMarkStep(
      targetKey: keys.sessions,
      title: 'Sessions',
      body: 'Browse past sessions, grouped by project.',
    ),
    CoachMarkStep(
      targetKey: keys.queue,
      title: 'Queue',
      body: 'Queue tasks to run unattended, one at a time.',
    ),
  ];
}
