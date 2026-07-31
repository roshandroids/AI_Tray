import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Convenient access to design tokens from [BuildContext].
extension TrayThemeContext on BuildContext {
  TrayColorTokens get colors {
    final theme = Theme.of(this);
    return theme.extension<TrayColorTokens>() ??
        AppColors.tokensFromScheme(theme.colorScheme);
  }

  TrayTypography get typography =>
      Theme.of(this).extension<TrayTypography>() ??
      TrayTypography.fromColors(colors);
}
