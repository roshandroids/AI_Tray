import 'package:ai_tray/core/logging/log_level.dart';
import 'package:meta/meta.dart';

/// One buffered log line for the diagnostics viewer.
@immutable
final class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.component,
    this.error,
    this.stackTrace,
    this.recoveryHint,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? component;
  final Object? error;
  final StackTrace? stackTrace;
  final String? recoveryHint;

  String get formattedTime {
    final local = timestamp.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  String toPlainLine() {
    final name = component == null ? '' : ' [$component]';
    final err = error == null ? '' : ' error=$error';
    final hint = recoveryHint == null ? '' : ' · $recoveryHint';
    return '$formattedTime ${level.label}$name $message$err$hint';
  }
}
