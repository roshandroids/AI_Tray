import 'dart:math' as math;

import 'package:ai_tray/core/components/page_header.dart';
import 'package:ai_tray/core/theme/breakpoints.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:flutter/material.dart';

/// Sliver-based replacement for
/// `Scaffold(body: Column([PageHeader, Expanded(scrollable)]))` — every
/// top-level page's previous shape.
/// Pins [PageHeader] via [PinnedHeaderSliver] (sized to its own intrinsic
/// height, so a runtime font-preset change can't clip it the way a fixed
/// `SliverPersistentHeaderDelegate` extent would) and applies the app's
/// existing reading-width cap uniformly to every caller-supplied sliver.
final class SliverPageScaffold extends StatelessWidget {
  const SliverPageScaffold({
    required this.title,
    required this.slivers,
    super.key,
    this.subtitle,
    this.titleTrailing,
    this.leading,
    this.actions = const [],
    this.maxContentWidth,
  });

  final String title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? leading;
  final List<Widget> actions;

  /// Caller-supplied slivers (e.g. `SliverToBoxAdapter`, `SliverList`) —
  /// NOT boxes. Each gets the same horizontal centering inset applied via
  /// its own `SliverPadding`, so a lazy `SliverList` stays lazy instead of
  /// being forced eager by an outer `Align`/`ConstrainedBox`.
  final List<Widget> slivers;

  /// Overrides the default `windowSizeOf()`-based reading-width cap.
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cap =
        maxContentWidth ??
        switch (windowSizeOf(context)) {
          WindowSize.compact => Spacing.contentMaxWidth,
          WindowSize.wide => 960,
          WindowSize.ultrawide => 1200,
        };
    final horizontalPadding = math.max(Spacing.md, (width - cap) / 2);

    return Scaffold(
      body: CustomScrollView(
        // AppShell's IndexedStack keeps all main destinations mounted at
        // once — an unspecified `primary` defaults to true, which would
        // have every mounted page fighting over one inherited
        // PrimaryScrollController.
        primary: false,
        slivers: [
          PinnedHeaderSliver(
            child: PageHeader(
              title: title,
              subtitle: subtitle,
              titleTrailing: titleTrailing,
              leading: leading,
              actions: actions,
            ),
          ),
          for (final sliver in slivers)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: sliver,
            ),
        ],
      ),
    );
  }
}
