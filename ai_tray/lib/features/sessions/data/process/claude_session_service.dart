import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';

/// Wraps the Claude CLI's `agents --json --all` surface — liveness
/// enrichment only (design principle 3, §10 of
/// `docs/planning/v2-vision-and-roadmap.md`). JSONL transcripts remain the
/// sole source of truth for the Session Browser; this service never blocks
/// or fails that rendering path. Every failure mode (non-zero exit,
/// timeout, invalid JSON, unexpected shape, an entry missing a recognizable
/// id) is captured as a [Result] for the caller to degrade silently, never
/// thrown.
final class ClaudeSessionService {
  ClaudeSessionService({
    required ProcessRunner processRunner,
    required AppLogger logger,
    String defaultBinary = 'claude',
  }) : _processRunner = processRunner,
       _logger = logger,
       _defaultBinary = defaultBinary;

  final ProcessRunner _processRunner;
  final AppLogger _logger;
  final String _defaultBinary;

  /// Session ids the CLI currently reports as live.
  ///
  /// Field names on a populated result are unconfirmed (only `[]` was
  /// observed against `2.1.220`), so entries are read defensively: any
  /// entry that isn't a map, or has none of the recognized id keys, is
  /// skipped rather than failing the whole call.
  Future<Result<Set<String>>> listLiveSessions({
    String? executablePath,
  }) async {
    final binary = _resolveBinary(executablePath);
    final result = await _processRunner.run(
      binary,
      const ['agents', '--json', '--all'],
    );

    return result.when(
      success: (process) {
        if (process.exitCode != 0) {
          _logger.warning(
            'claude agents non-zero exit=${process.exitCode}',
            name: 'claude_session_service',
          );
          return Result.failure(
            AppFailure(
              code: FailureCode.processNonZeroExit,
              message: 'Claude CLI returned an error listing live sessions',
              detail: _truncate(process.stderr),
            ),
          );
        }

        final Object? decoded;
        try {
          decoded = jsonDecode(process.stdout);
        } on FormatException catch (error) {
          _logger.warning(
            'claude agents output was not valid JSON',
            name: 'claude_session_service',
          );
          return Result.failure(
            AppFailure(
              code: FailureCode.unknownCliOutput,
              message: 'Claude agents output was not valid JSON',
              detail: error.message,
            ),
          );
        }

        if (decoded is! List) {
          _logger.warning(
            'claude agents output was not a JSON array',
            name: 'claude_session_service',
          );
          return const Result.failure(
            AppFailure(
              code: FailureCode.unknownCliOutput,
              message: 'Unexpected Claude agents JSON shape',
            ),
          );
        }

        final liveIds = <String>{};
        for (final entry in decoded) {
          final id = _extractSessionId(entry);
          if (id != null) liveIds.add(id);
        }
        return Result.success(liveIds);
      },
      onFailure: Result.failure,
    );
  }

  /// Recognized id keys, tried in order. Unconfirmed field names (per
  /// preamble) — anything else is silently skipped, not guessed.
  static const _idKeys = ['sessionId', 'session_id', 'id'];

  String? _extractSessionId(Object? entry) {
    if (entry is! Map) return null;
    for (final key in _idKeys) {
      final value = entry[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  String _resolveBinary(String? binaryPath) {
    final trimmed = binaryPath?.trim();
    if (trimmed == null || trimmed.isEmpty) return _defaultBinary;
    return trimmed;
  }

  String? _truncate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= 200) return trimmed;
    return '${trimmed.substring(0, 200)}…';
  }
}
