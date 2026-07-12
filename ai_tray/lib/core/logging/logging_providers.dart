import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global application logger. Override in tests with a recording fake.
final appLoggerProvider = Provider<AppLogger>((ref) {
  return ConsoleAppLogger();
});
