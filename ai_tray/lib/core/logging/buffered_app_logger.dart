import 'dart:async';
import 'dart:collection';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/log_entry.dart';
import 'package:ai_tray/core/logging/log_level.dart';

/// In-memory ring buffer + optional delegate (console) for PD-020 log viewer.
final class BufferedAppLogger implements AppLogger {
  BufferedAppLogger({
    this.delegate,
    this.capacity = 500,
    this.defaultName = 'ai_tray',
  });

  final AppLogger? delegate;
  final int capacity;
  final String defaultName;

  final Queue<LogEntry> _entries = Queue<LogEntry>();
  final StreamController<List<LogEntry>> _controller =
      StreamController<List<LogEntry>>.broadcast();

  List<LogEntry> get entries => List.unmodifiable(_entries.toList());

  Stream<List<LogEntry>> get watch => _controller.stream;

  void clear() {
    _entries.clear();
    _emit();
  }

  String exportPlainText() {
    return _entries.map((e) => e.toPlainLine()).join('\n');
  }

  @override
  void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? provider,
    String? category,
  }) {
    _record(
      LogLevel.debug,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      provider: provider,
      category: category,
    );
    delegate?.debug(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? provider,
    String? category,
  }) {
    _record(
      LogLevel.info,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      provider: provider,
      category: category,
    );
    delegate?.info(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? provider,
    String? category,
  }) {
    _record(
      LogLevel.warning,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      provider: provider,
      category: category,
    );
    delegate?.warning(
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
    String? provider,
    String? category,
  }) {
    final buffer = StringBuffer(message);
    String? recovery;
    if (failure != null) {
      buffer.write(' code=${failure.code.name}');
      if (failure.detail != null && failure.detail!.isNotEmpty) {
        buffer.write(' detail=${failure.detail}');
      }
      recovery = _recoveryFor(failure);
    }
    _record(
      LogLevel.error,
      buffer.toString(),
      name: name,
      error: error,
      stackTrace: stackTrace,
      recoveryHint: recovery,
      provider: provider,
      category: category,
    );
    delegate?.error(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      failure: failure,
    );
  }

  /// Success-level event for the diagnostics viewer.
  ///
  /// Also logged as INFO to the console delegate.
  void success(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? provider,
    String? category,
  }) {
    _record(
      LogLevel.success,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      provider: provider,
      category: category,
    );
    delegate?.info(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _record(
    LogLevel level,
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? recoveryHint,
    String? provider,
    String? category,
  }) {
    _entries.addLast(
      LogEntry(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        component: name ?? defaultName,
        error: error,
        stackTrace: stackTrace,
        recoveryHint: recoveryHint,
        provider: provider ?? _providerFor(name, message),
        category: category ?? _categoryFor(name),
      ),
    );
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(entries);
    }
  }

  static String? _recoveryFor(AppFailure failure) {
    return switch (failure.code.name) {
      'cliNotInstalled' => 'Install Claude CLI or set binary path in Settings.',
      'notAuthenticated' => 'Run `claude auth login` then Refresh Now.',
      'timeout' => 'Retry refresh. Check network / Claude CLI health.',
      'processLaunchFailed' => 'Verify Claude binary path and permissions.',
      'processNonZeroExit' => 'Check CLI auth and session; try Refresh Now.',
      'incompleteOutput' ||
      'parseFailed' => 'Wait for next refresh or check CLI output shape.',
      _ => 'Open Logs for detail; try Refresh Now.',
    };
  }

  static String? _providerFor(String? component, String message) {
    final normalized = '${component ?? ''} $message'.toLowerCase();
    if (normalized.contains('provider=copilot') ||
        normalized.contains('copilot')) {
      return 'copilot';
    }
    if (normalized.contains('provider=claude') ||
        normalized.contains('claude')) {
      return 'claude';
    }
    return null;
  }

  static String? _categoryFor(String? component) {
    final normalized = component?.toLowerCase() ?? '';
    if (normalized.contains('diagnostic')) return 'diagnostics';
    if (normalized.contains('sdk') || normalized.contains('sidecar')) {
      return 'sdk';
    }
    if (normalized.contains('refresh') || normalized.contains('usage')) {
      return 'usage';
    }
    if (normalized.contains('provider') || normalized.contains('adapter')) {
      return 'provider';
    }
    if (normalized.isEmpty || normalized == 'ai_tray') return null;
    return normalized;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
