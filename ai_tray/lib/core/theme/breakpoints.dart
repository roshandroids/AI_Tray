import 'package:flutter/widgets.dart';

/// Named window-width bands (V4 §2.1) — replaces the ad-hoc `560`/`720`
/// `LayoutBuilder` checks scattered per-page with one shared scale.
abstract final class Breakpoints {
  static const double compact = 0;
  static const double wide = 840;
  static const double ultrawide = 1280;
}

enum WindowSize {
  compact,
  wide,
  ultrawide;

  bool get isCompact => this == WindowSize.compact;
}

/// Resolves the current [WindowSize] from the nearest [MediaQuery].
WindowSize windowSizeOf(BuildContext context) {
  return windowSizeForWidth(MediaQuery.sizeOf(context).width);
}

/// Resolves a [WindowSize] from a raw width — used where the relevant
/// width is a local layout constraint rather than the full window (e.g. a
/// responsive grid deciding column count from its own available space).
WindowSize windowSizeForWidth(double width) {
  if (width >= Breakpoints.ultrawide) return WindowSize.ultrawide;
  if (width >= Breakpoints.wide) return WindowSize.wide;
  return WindowSize.compact;
}
