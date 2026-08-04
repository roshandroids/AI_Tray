import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/data/fs/fake_session_file_system.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/data/repositories/file_system_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSessionFileSystem fileSystem;
  late FakeProcessRunner processRunner;
  late FileSystemSessionRepository repository;

  void liveSessions(List<String> ids) {
    processRunner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode([
            for (final id in ids) {'sessionId': id},
          ]),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };
  }

  setUp(() {
    fileSystem = FakeSessionFileSystem();
    processRunner = FakeProcessRunner();
    repository = FileSystemSessionRepository(
      fileSystem: fileSystem,
      sessionService: ClaudeSessionService(
        processRunner: processRunner,
        logger: ConsoleAppLogger(defaultName: 'repo_test'),
      ),
      logger: ConsoleAppLogger(defaultName: 'repo_test'),
      directoryExists: (_) => false,
      rootPath: '/root',
    );
    liveSessions(const []);
  });

  test('builds summaries from every seeded session file', () async {
    fileSystem
      ..addFile(
        '/root/-home-claude-one/abc.jsonl',
        lines: const ['line'],
        modifiedAt: DateTime.utc(2026, 7, 30),
      )
      ..addFile(
        '/root/-home-claude-two/def.jsonl',
        lines: const ['line'],
        modifiedAt: DateTime.utc(2026, 7, 31),
      );

    final result = await repository.listSessions();

    expect(result.isSuccess, isTrue);
    final ids = result.valueOrNull!.map((s) => s.sessionId).toSet();
    expect(ids, {'abc', 'def'});
  });

  test('orders sessions most-recently-active first, not by enumeration '
      'order', () async {
    fileSystem
      ..addFile(
        '/root/-home-claude-one/oldest.jsonl',
        lines: const ['line'],
        modifiedAt: DateTime.utc(2026, 7, 1),
      )
      ..addFile(
        '/root/-home-claude-two/newest.jsonl',
        lines: const ['line'],
        modifiedAt: DateTime.utc(2026, 7, 31),
      )
      ..addFile(
        '/root/-home-claude-three/middle.jsonl',
        lines: const ['line'],
        modifiedAt: DateTime.utc(2026, 7, 15),
      );

    final result = await repository.listSessions();

    final ids = result.valueOrNull!.map((s) => s.sessionId).toList();
    expect(ids, ['newest', 'middle', 'oldest']);
  });

  test('merges liveness onto matching sessions', () async {
    fileSystem
      ..addFile('/root/-home-claude-one/live.jsonl', lines: const [])
      ..addFile('/root/-home-claude-one/not-live.jsonl', lines: const []);
    liveSessions(['live']);

    final result = await repository.listSessions();

    final byId = {for (final s in result.valueOrNull!) s.sessionId: s};
    expect(byId['live']!.isLive, isTrue);
    expect(byId['not-live']!.isLive, isFalse);
  });

  test('a failed liveness enrichment leaves isLive null, never fails the '
      'whole list', () async {
    fileSystem.addFile('/root/-home-claude-one/abc.jsonl', lines: const []);
    processRunner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(code: FailureCode.timeout, message: 'timed out'),
      );
    };

    final result = await repository.listSessions();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.single.isLive, isNull);
  });

  test('a file that disappears between listing and stat is skipped, not '
      'fatal', () async {
    fileSystem
      ..addFile('/root/-home-claude-one/gone.jsonl', lines: const [])
      ..addFile('/root/-home-claude-one/here.jsonl', lines: const [])
      ..removeFile('/root/-home-claude-one/gone.jsonl');

    final result = await repository.listSessions();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.map((s) => s.sessionId), ['here']);
  });

  test('empty session directory returns an empty, successful list', () async {
    final result = await repository.listSessions();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test(
    'a genuine enumeration failure propagates, unlike liveness failures',
    () async {
      fileSystem.listFailure = const AppFailure(
        code: FailureCode.unknown,
        message: 'boom',
      );

      final result = await repository.listSessions();

      expect(result.failureOrNull?.code, FailureCode.unknown);
    },
  );

  group('readSession', () {
    test('parses the full transcript for a matching session id', () async {
      fileSystem.addFile(
        '/root/-home-claude-proj/abc.jsonl',
        lines: [
          jsonEncode({
            'type': 'user',
            'timestamp': '2026-07-30T00:00:00Z',
            'gitBranch': 'main',
          }),
          jsonEncode({
            'type': 'assistant',
            'timestamp': '2026-07-30T00:01:00Z',
            'message': {
              'model': 'claude-x',
              'usage': {'input_tokens': 10, 'output_tokens': 5},
            },
          }),
        ],
      );

      final result = await repository.readSession('abc');

      expect(result.isSuccess, isTrue);
      final session = result.valueOrNull!;
      expect(session.sessionId, 'abc');
      expect(session.model, 'claude-x');
      expect(session.gitBranch, 'main');
      expect(session.messageCount, 2);
      expect(session.isComplete, isTrue);
    });

    test('merges liveness onto the read session', () async {
      fileSystem.addFile('/root/-home-claude-proj/live.jsonl', lines: const []);
      liveSessions(['live']);

      final result = await repository.readSession('live');

      expect(result.valueOrNull?.isLive, isTrue);
    });

    test(
      'returns sessionNotFound when no file matches the id — a real race '
      'between listing and opening a session, not hypothetical',
      () async {
        fileSystem.addFile(
          '/root/-home-claude-proj/other.jsonl',
          lines: const [],
        );

        final result = await repository.readSession('missing');

        expect(result.failureOrNull?.code, FailureCode.sessionNotFound);
      },
    );

    test(
      'a genuine enumeration failure propagates for readSession too',
      () async {
        fileSystem.listFailure = const AppFailure(
          code: FailureCode.unknown,
          message: 'boom',
        );

        final result = await repository.readSession('abc');

        expect(result.failureOrNull?.code, FailureCode.unknown);
      },
    );
  });
}
