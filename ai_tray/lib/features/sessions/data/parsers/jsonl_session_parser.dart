import 'dart:convert';

import 'package:ai_tray/features/sessions/data/fs/claude_project_path_decoder.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';

/// Two-pass Claude session parser (§10 of
/// `docs/planning/v2-vision-and-roadmap.md`):
///
/// - [summarize] is the cheap index pass — file metadata only, no
///   transcript content is read.
/// - [parseSession] is the lazy detail pass — reads the full transcript,
///   tolerating malformed or truncated content the same way `UsageParser`
///   tolerates Shape A/B: a bad line is skipped and logged, never thrown
///   (design principle 4). Takes already-opened inputs (a [SessionFileRef]
///   and a line [Stream]) rather than a `SessionFileSystem` directly, so it
///   stays testable with plain fixture data — no fake filesystem needed.
final class JsonlSessionParser {
  const JsonlSessionParser();

  /// Estimate divisor for [summarize]'s message-count estimate — calibrated
  /// loosely against typical transcript line sizes, not measured precisely.
  static const _estimatedBytesPerLine = 400;

  SessionSummary summarize({
    required SessionFileRef file,
    required SessionFileStat stat,
    required bool Function(String path) directoryExists,
  }) {
    final projectPath = ClaudeProjectPathDecoder.decode(
      file.sanitizedProjectDirName,
      directoryExists: directoryExists,
    );
    return SessionSummary(
      sessionId: file.sessionId,
      sanitizedProjectDirName: file.sanitizedProjectDirName,
      projectPath: projectPath,
      lastActivityAt: stat.modifiedAt,
      messageCount: _estimateMessageCount(stat.sizeBytes),
    );
  }

  static int _estimateMessageCount(int sizeBytes) {
    if (sizeBytes <= 0) return 0;
    final estimate = sizeBytes ~/ _estimatedBytesPerLine;
    return estimate < 1 ? 1 : estimate;
  }

  Future<ClaudeSession> parseSession({
    required SessionFileRef file,
    required Stream<String> lines,
  }) async {
    var messageCount = 0;
    var sawAnyLine = false;
    var lastLineComplete = true;
    String? projectPath;
    String? gitBranch;
    String? model;
    DateTime? lastActivityAt;
    var inputTokens = 0;
    var outputTokens = 0;
    var cacheCreationInputTokens = 0;
    var cacheReadInputTokens = 0;

    try {
      await for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        sawAnyLine = true;

        final Object? decoded;
        try {
          decoded = jsonDecode(line);
        } on FormatException {
          lastLineComplete = false;
          continue;
        }
        lastLineComplete = true;
        if (decoded is! Map<String, Object?>) continue;

        final cwd = decoded['cwd'];
        if (cwd is String && cwd.isNotEmpty) projectPath = cwd;

        final branch = decoded['gitBranch'];
        if (branch is String && branch.isNotEmpty) gitBranch = branch;

        final timestampRaw = decoded['timestamp'];
        if (timestampRaw is String) {
          final parsed = DateTime.tryParse(timestampRaw);
          if (parsed != null) lastActivityAt = parsed.toUtc();
        }

        final type = decoded['type'];
        if (type == 'user' || type == 'assistant') {
          messageCount += 1;
        }
        if (type == 'assistant') {
          final message = decoded['message'];
          if (message is Map<String, Object?>) {
            final messageModel = message['model'];
            if (messageModel is String && messageModel.isNotEmpty) {
              model = messageModel;
            }
            final usage = message['usage'];
            if (usage is Map<String, Object?>) {
              inputTokens += _asInt(usage['input_tokens']);
              outputTokens += _asInt(usage['output_tokens']);
              cacheCreationInputTokens += _asInt(
                usage['cache_creation_input_tokens'],
              );
              cacheReadInputTokens += _asInt(usage['cache_read_input_tokens']);
            }
          }
        }
      }
    } on Exception {
      lastLineComplete = false;
    }

    return ClaudeSession(
      sessionId: file.sessionId,
      sanitizedProjectDirName: file.sanitizedProjectDirName,
      projectPath: projectPath,
      lastActivityAt: lastActivityAt,
      messageCount: messageCount,
      model: model,
      gitBranch: gitBranch,
      tokenTotals: SessionTokenTotals(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        cacheCreationInputTokens: cacheCreationInputTokens,
        cacheReadInputTokens: cacheReadInputTokens,
      ),
      isComplete: !sawAnyLine || lastLineComplete,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
