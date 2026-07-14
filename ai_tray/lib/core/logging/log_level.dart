/// Log severity for the in-app diagnostics viewer (PD-020).
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
}

extension LogLevelLabel on LogLevel {
  String get label => switch (this) {
    LogLevel.debug => 'DEBUG',
    LogLevel.info => 'INFO',
    LogLevel.warning => 'WARNING',
    LogLevel.error => 'ERROR',
    LogLevel.success => 'SUCCESS',
  };
}
