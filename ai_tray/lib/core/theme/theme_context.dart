import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// Convenient access to design tokens from [BuildContext].
extension TrayThemeContext on BuildContext {
  TrayColorTokens get colors =>
      Theme.of(this).extension<TrayColorTokens>() ?? TrayColorTokens.dark;

  TrayTypography get typography =>
      Theme.of(this).extension<TrayTypography>() ??
      TrayTypography.fromColors(colors);
}
