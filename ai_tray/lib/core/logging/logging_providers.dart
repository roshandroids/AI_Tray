import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Buffered logger used by UI diagnostics (also mirrors to console).
final Provider<BufferedAppLogger> bufferedAppLoggerProvider =
    Provider<BufferedAppLogger>((ref) {
      final logger = BufferedAppLogger(delegate: ConsoleAppLogger());
      ref.onDispose(logger.dispose);
      return logger;
    });

/// Global application logger. Override [bufferedAppLoggerProvider] in tests.
final Provider<AppLogger> appLoggerProvider = Provider<AppLogger>((ref) {
  return ref.watch(bufferedAppLoggerProvider);
});
