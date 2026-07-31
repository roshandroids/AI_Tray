import 'dart:async';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/domain/repositories/session_repository.dart';

/// In-memory [SessionRepository] for controller/widget tests — mirrors
/// `FakeProcessRunner`/`FakeSessionFileSystem`'s configurable-response
/// shape rather than a mock.
final class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({
    List<SessionSummary> sessions = const [],
  }) : _result = Result.success(sessions);

  Result<List<SessionSummary>> _result;
  Completer<void>? _gate;

  /// Calls made, for assertions (e.g. that `refresh()` re-queries).
  int listSessionsCallCount = 0;

  void setSessions(List<SessionSummary> sessions) {
    _result = Result.success(sessions);
  }

  void setFailure(FailureCode code, {String message = 'failed'}) {
    _result = Result.failure(AppFailure(code: code, message: message));
  }

  /// Makes the next (and only the next in-flight) [listSessions] call hang
  /// until [releaseResponse] — for deterministically asserting a loading
  /// state in widget tests, instead of racing a real async gap.
  void holdNextResponse() => _gate = Completer<void>();

  void releaseResponse() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<Result<List<SessionSummary>>> listSessions() async {
    listSessionsCallCount++;
    final gate = _gate;
    if (gate != null) await gate.future;
    return _result;
  }
}
