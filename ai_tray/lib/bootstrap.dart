import 'dart:async';

import 'package:ai_tray/app.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes bindings, DI, logging, tray, and starts usage refresh.
Future<void> bootstrap({
  AppLogger? logger,
  SharedPreferences? sharedPreferences,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLogger = logger ?? ConsoleAppLogger()
    ..info('AI Tray starting', name: 'bootstrap');

  await initializeDesktopShell(appLogger);

  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      appLoggerProvider.overrideWithValue(appLogger),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  final usageRepository = container.read(usageRepositoryProvider);
  if (usageRepository is UsageRepositoryImpl) {
    unawaited(usageRepository.start());
  }

  final tray = container.read(trayControllerProvider);
  unawaited(tray.start());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AiTrayApp(),
    ),
  );

  // Release + Finder launches need the window shown after the first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(ensureDesktopWindowVisible(appLogger));
  });
}
