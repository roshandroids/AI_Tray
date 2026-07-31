import 'dart:io';

import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:ai_tray/features/sessions/data/fs/io_session_file_system.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/data/repositories/file_system_session_repository.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:ai_tray/features/sessions/domain/repositories/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filesystem boundary for Claude session transcripts (Feature 1.1.1).
final sessionFileSystemProvider = Provider<SessionFileSystem>((ref) {
  return IoSessionFileSystem(logger: ref.watch(appLoggerProvider));
});

/// Claude CLI liveness-enrichment adapter (Feature 1.1.3). Reuses the same
/// `ProcessRunner` singleton as `ClaudeCliAdapter` — no second CLI
/// execution path.
final claudeSessionServiceProvider = Provider<ClaudeSessionService>((ref) {
  return ClaudeSessionService(
    processRunner: ref.watch(processRunnerProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

/// Session Browser's data source — a read projection over JSONL files
/// (Feature 1.2.1; see `docs/planning/v2-implementation-log.md`).
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FileSystemSessionRepository(
    fileSystem: ref.watch(sessionFileSystemProvider),
    sessionService: ref.watch(claudeSessionServiceProvider),
    logger: ref.watch(appLoggerProvider),
    directoryExists: (path) => Directory(path).existsSync(),
  );
});
