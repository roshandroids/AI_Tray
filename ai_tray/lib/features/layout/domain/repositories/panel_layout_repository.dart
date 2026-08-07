import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/layout/domain/models/panel_layout_state.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;

/// Persisted heights/collapse state for `ResizablePanel`s, keyed by
/// `panelId` — same "read-modify-write one JSON blob" shape as
/// `NotificationHistoryRepository`, but a map instead of a list since a
/// malformed entry here is one bad key, not one bad list index.
abstract interface class PanelLayoutRepository {
  Future<Result<Map<String, PanelLayoutState>>> loadAll();

  Future<Result<Unit>> save(String panelId, PanelLayoutState state);

  Future<Result<Unit>> clear();
}
