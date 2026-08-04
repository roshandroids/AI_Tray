import 'dart:io';

import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/sessions/queue/data/repositories/shared_preferences_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/data/services/resume_queue_executor.dart';
import 'package:ai_tray/features/sessions/queue/domain/repositories/resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bounded, persisted Resume Queue (Feature 2.2.2).
final resumeQueueRepositoryProvider = Provider<ResumeQueueRepository>((ref) {
  return SharedPreferencesResumeQueueRepository(
    ref.watch(sharedPreferencesProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

/// Sequential, single-flight queue executor — reuses
/// `claudeSessionServiceProvider` (the same singleton Feature 2.2.1's
/// manual resume already uses), no second CLI execution path.
final resumeQueueExecutorProvider = Provider<ResumeQueueExecutor>((ref) {
  return ResumeQueueExecutor(
    repository: ref.watch(resumeQueueRepositoryProvider),
    sessionService: ref.watch(claudeSessionServiceProvider),
    logger: ref.watch(appLoggerProvider),
    directoryExists: (path) => Directory(path).existsSync(),
  );
});
