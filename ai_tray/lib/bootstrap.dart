import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Initializes bindings, logging, and Riverpod before running [builder].
Future<void> bootstrap(
  Widget Function() builder, {
  AppLogger? logger,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLogger = logger ?? ConsoleAppLogger()
    ..info('AI Tray starting', name: 'bootstrap');

  runApp(
    ProviderScope(
      overrides: [
        appLoggerProvider.overrideWithValue(appLogger),
      ],
      child: builder(),
    ),
  );
}
