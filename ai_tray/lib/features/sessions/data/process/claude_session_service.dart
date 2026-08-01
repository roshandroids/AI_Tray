import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';

/// Wraps two related Claude CLI capabilities behind one class — mirrors
/// `ClaudeCliAdapter`'s existing pattern of bundling one vendor's related
/// CLI calls together (§7, §15 of
/// `docs/planning/v2-vision-and-roadmap.md`):
///
/// - [listLiveSessions] — `agents --json --all`, liveness enrichment only
///   (design principle 3). JSONL transcripts remain the sole source of
///   truth for the Session Browser; this call never blocks or fails that
///   rendering path.
/// - [resume] — `--resume ... --output-format json`, the first *acting*
///   capability in this codebase (M2). Every failure mode (non-zero exit,
///   timeout, invalid JSON, unexpected shape) is captured as a [Result],
///   never thrown — but unlike liveness, a `resume` failure is real and
///   must be surfaced to the caller, not silently swallowed.
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

  /// Continues (or, with [forkSession], branches) an existing session
  /// non-interactively, per the confirmed grammar in
  /// `docs/reports/claude_code_cli_capability_report.md` §2/§3D:
  /// `claude --resume <id> -p "<prompt>" --output-format json`.
  ///
  /// [forkSession] defaults to `false` — attended, continue-in-place, the
  /// default for a human-driven "Resume now" action (design principle 2:
  /// "Manual, attended 'Resume now' ... may continue in place, because a
  /// human is present to notice"). Unattended callers (the queue executor,
  /// Feature 2.2.2) must pass `true` explicitly.
  ///
  /// [timeout] defaults to 10 minutes, not `ProcessRunner`'s 8-second
  /// default — a real model turn with tool use can run minutes (§15). A
  /// timeout still results in `SIGKILL` and a handled
  /// `FailureCode.timeout` failure (design principle 4), never a crash.
  Future<Result<ResumeOutcome>> resume({
    required String sessionId,
    required String prompt,
    required String workingDirectory,
    bool forkSession = false,
    double? maxBudgetUsd,
    List<String>? fallbackModels,
    Duration timeout = const Duration(minutes: 10),
    String? executablePath,
  }) async {
    final binary = _resolveBinary(executablePath);
    final args = [
      '--resume',
      sessionId,
      '-p',
      prompt,
      '--output-format',
      'json',
      if (maxBudgetUsd != null) ...['--max-budget-usd', '$maxBudgetUsd'],
      if (forkSession) '--fork-session',
      if (fallbackModels != null && fallbackModels.isNotEmpty) ...[
        '--fallback-model',
        fallbackModels.join(','),
      ],
    ];
    final result = await _processRunner.run(
      binary,
      args,
      timeout: timeout,
      workingDirectory: workingDirectory,
    );

    return result.when(
      success: (process) {
        if (process.exitCode != 0) {
          // Confirmed live (§2): a bogus/non-existent session id fails
          // immediately with plain stderr text, not JSON, even when
          // `--output-format json` was requested — the process errors
          // before a result envelope is ever built.
          _logger.warning(
            'claude resume non-zero exit=${process.exitCode}',
            name: 'claude_session_service',
          );
          return Result.failure(
            AppFailure(
              code: FailureCode.processNonZeroExit,
              message: 'Claude CLI returned an error resuming the session',
              detail: _truncate(process.stderr),
            ),
          );
        }

        final Object? decoded;
        try {
          decoded = jsonDecode(process.stdout);
        } on FormatException catch (error) {
          _logger.warning(
            'claude resume output was not valid JSON',
            name: 'claude_session_service',
          );
          return Result.failure(
            AppFailure(
              code: FailureCode.unknownCliOutput,
              message: 'Claude resume output was not valid JSON',
              detail: error.message,
            ),
          );
        }

        if (decoded is! Map) {
          _logger.warning(
            'claude resume output was not a JSON object',
            name: 'claude_session_service',
          );
          return const Result.failure(
            AppFailure(
              code: FailureCode.unknownCliOutput,
              message: 'Unexpected Claude resume JSON shape',
            ),
          );
        }

        return Result.success(_parseOutcome(sessionId, decoded));
      },
      onFailure: Result.failure,
    );
  }

  ResumeOutcome _parseOutcome(
    String fallbackSessionId,
    Map<Object?, Object?> json,
  ) {
    final usage = json['usage'];
    return ResumeOutcome(
      sessionId: (json['session_id'] as String?) ?? fallbackSessionId,
      isError: json['is_error'] == true,
      costUsd: _asDouble(json['total_cost_usd']),
      tokens: usage is Map
          ? SessionTokenTotals(
              inputTokens: _asInt(usage['input_tokens']),
              outputTokens: _asInt(usage['output_tokens']),
              cacheCreationInputTokens: _asInt(
                usage['cache_creation_input_tokens'],
              ),
              cacheReadInputTokens: _asInt(usage['cache_read_input_tokens']),
            )
          : const SessionTokenTotals(),
      numTurns: _asInt(json['num_turns']),
      stopReason: json['stop_reason'] as String?,
      resultText: (json['result'] as String?) ?? '',
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
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
