import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/layout/data/repositories/shared_preferences_panel_layout_repository.dart';
import 'package:ai_tray/features/layout/domain/repositories/panel_layout_repository.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted size/collapse state for `ResizablePanel`s (V4 §1.4).
final panelLayoutRepositoryProvider = Provider<PanelLayoutRepository>((ref) {
  return SharedPreferencesPanelLayoutRepository(
    ref.watch(sharedPreferencesProvider),
    logger: ref.watch(appLoggerProvider),
  );
});
