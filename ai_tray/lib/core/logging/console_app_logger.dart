import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/logging/app_logger.dart';

/// Lightweight console [AppLogger] for desktop MVP.
///
/// This is the only place that may write to stdout for application logs.
final class ConsoleAppLogger implements AppLogger {
  ConsoleAppLogger({this.defaultName = 'ai_tray'});

  final String defaultName;

  @override
  void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write('DEBUG', message, name: name, error: error, stackTrace: stackTrace);
  }

  @override
  void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write('INFO', message, name: name, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      'WARNING',
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    AppFailure? failure,
  }) {
    final buffer = StringBuffer(message);
    if (failure != null) {
      buffer.write(' code=${failure.code.name}');
      if (failure.detail != null && failure.detail!.isNotEmpty) {
        buffer.write(' detail=${failure.detail}');
      }
    }
    _write(
      'ERROR',
      buffer.toString(),
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _write(
    String level,
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final loggerName = name ?? defaultName;
    final timestamp = DateTime.now().toUtc().toIso8601String();
    // ignore: avoid_print -- sole AppLogger stdout sink
    print('$level $timestamp [$loggerName] $message');
    if (error != null) {
      // ignore: avoid_print -- sole AppLogger stdout sink
      print('$level $timestamp [$loggerName] error=$error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print -- sole AppLogger stdout sink
      print('$level $timestamp [$loggerName] stackTrace=\n$stackTrace');
    }
  }
}
