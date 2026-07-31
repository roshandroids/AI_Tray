import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns loading, refresh, and error state for the Session Browser list
/// (Feature 1.2.1) — same `AsyncNotifier` shape as `SettingsNotifier`/
/// `ProviderSelectionNotifier`. Holds no filtering state of its own: the
/// loaded list is the single source of truth: search/filter
/// (`session_list_filter.dart`) is a pure, page-local derivation over it,
/// never a mutation of controller state.
final class SessionBrowserController
    extends AsyncNotifier<List<SessionSummary>> {
  @override
  Future<List<SessionSummary>> build() => _load();

  /// Re-queries the repository. `SessionRepository` owns no cache (§9), so
  /// this is simply another `listSessions()` call — there is no separate
  /// "refresh the index" operation to invoke.
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<SessionSummary>> _load() async {
    final result = await ref.read(sessionRepositoryProvider).listSessions();
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'session list load failed',
            name: 'session_browser',
            error: failure,
          );
      throw StateError(failure.message);
    }
    return result.valueOrNull ?? const [];
  }
}

/// Feature-scoped asynchronous Session Browser list state.
final sessionBrowserControllerProvider =
    AsyncNotifierProvider<SessionBrowserController, List<SessionSummary>>(
      SessionBrowserController.new,
    );
