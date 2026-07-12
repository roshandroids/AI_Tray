import 'package:ai_tray/core/errors/app_failure.dart';

/// Application logging abstraction (ADR-002 levels).
///
/// Call sites must not use `print` directly — go through [AppLogger].
abstract interface class AppLogger {
  void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  });

  void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  });

  void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  });

  void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    AppFailure? failure,
  });
}
