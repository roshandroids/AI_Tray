import 'dart:async';
import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/features/providers/data/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/data/copilot/sdk/sidecar_process.dart';
import 'package:ai_tray/features/providers/data/copilot/sdk/sidecar_process_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('correlates requests and performs graceful cleanup', () async {
    final process = _FakeProcess();
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
    );

    await transport.initialize();
    final result = await transport.request('health.get');
    await transport.shutdown();

    expect(result, {'healthy': true});
    expect(process.methods, ['handshake', 'health.get', 'shutdown']);
    expect(process.inputClosed, isTrue);
    expect(process.killed, isFalse);
  });

  test('supports cancellation and sends a correlated cancel request', () async {
    final process = _FakeProcess(hangingMethods: {'quota.get'});
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
    );
    final token = CopilotSdkCancellationToken();

    final request = transport.request(
      'quota.get',
      cancellationToken: token,
    );
    await Future<void>.delayed(Duration.zero);
    token.cancel();

    await expectLater(
      request,
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.cancelled,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(process.methods, contains('cancel'));
    await transport.shutdown();
  });

  test('times out a request and keeps the process available', () async {
    final process = _FakeProcess(hangingMethods: {'quota.get'});
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
      requestTimeout: const Duration(milliseconds: 5),
    );

    await expectLater(
      transport.request('quota.get'),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.timeout,
        ),
      ),
    );
    expect(await transport.request('health.get'), {'healthy': true});
    await transport.shutdown();
  });

  test('detects a crash and performs only one bounded restart', () async {
    final first = _FakeProcess();
    final second = _FakeProcess();
    final launcher = _FakeLauncher([first, second]);
    final transport = SidecarProcessTransport(
      launcher: launcher,
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
    );

    await transport.initialize();
    first.crash(17);
    await second.handshakeSeen;

    final result = await transport.request('health.get');

    expect(result, {'healthy': true});
    expect(launcher.starts, 2);
    second.crash(18);
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      transport.request('health.get'),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.processCrashed,
        ),
      ),
    );
    expect(launcher.starts, 2);
  });

  test('redacts credentials before logging sidecar stderr', () async {
    final process = _FakeProcess();
    final logger = _RecordingLogger();
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: logger,
      executable: 'node',
      arguments: const ['bridge.js'],
    );

    await transport.initialize();
    process.emitStderr(
      'failed token=ghu_NEVER_LOG_THIS credential=top-secret',
    );
    await Future<void>.delayed(Duration.zero);
    await transport.shutdown();

    final logs = logger.messages.join('\n');
    expect(logs, isNot(contains('ghu_NEVER_LOG_THIS')));
    expect(logs, isNot(contains('top-secret')));
    expect(logs, contains('[REDACTED]'));
  });

  test(
    'malformed NDJSON fails pending requests and kills the process',
    () async {
      final process = _FakeProcess(hangingMethods: {'quota.get'});
      final transport = SidecarProcessTransport(
        launcher: _FakeLauncher([process]),
        logger: _RecordingLogger(),
        executable: 'node',
        arguments: const ['bridge.js'],
        maxRestarts: 0,
      );

      await transport.initialize();
      final pending = transport.request('quota.get');
      await Future<void>.delayed(Duration.zero);
      process.emitStdout('not-json{{{');

      await expectLater(
        pending,
        throwsA(
          isA<CopilotSdkException>().having(
            (error) => error.code,
            'code',
            CopilotSdkErrorCode.malformedResponse,
          ),
        ),
      );
      expect(process.killed, isTrue);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('handshake timeout surfaces as a transport failure', () async {
    final process = _FakeProcess(hangingMethods: {'handshake'});
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
      requestTimeout: const Duration(milliseconds: 20),
      maxRestarts: 0,
    );

    await expectLater(
      transport.initialize(),
      throwsA(isA<CopilotSdkException>()),
    );
    await Future<void>.delayed(Duration.zero);
  });

  test('write failure fails the active request', () async {
    final process = _FakeProcess(writeError: StateError('broken pipe'));
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
      maxRestarts: 0,
    );

    await expectLater(
      transport.initialize(),
      throwsA(isA<CopilotSdkException>()),
    );
    await Future<void>.delayed(Duration.zero);
  });

  test('concurrent requests complete out of order by id', () async {
    final process = _FakeProcess(holdMethods: {'quota.get', 'health.get'});
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
    );

    await transport.initialize();
    final quota = transport.request('quota.get');
    final health = transport.request('health.get');
    await Future<void>.delayed(Duration.zero);

    process
      ..release('health.get', {'healthy': true})
      ..release('quota.get', {'premium': true});

    expect(await health, {'healthy': true});
    expect(await quota, {'premium': true});
    await transport.shutdown();
  });

  test('late response after timeout is ignored safely', () async {
    final process = _FakeProcess(holdMethods: {'quota.get'});
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
      requestTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      transport.request('quota.get'),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.timeout,
        ),
      ),
    );
    final timedOutId = process.lastIdFor('quota.get');
    process.emitStdout(
      jsonEncode({
        'protocolVersion': 1,
        'id': timedOutId,
        'result': {'premium': true},
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(await transport.request('health.get'), {'healthy': true});
    await transport.shutdown();
  });

  test('shutdown kills the process when exit times out', () async {
    final process = _FakeProcess(hangExit: true);
    final transport = SidecarProcessTransport(
      launcher: _FakeLauncher([process]),
      logger: _RecordingLogger(),
      executable: 'node',
      arguments: const ['bridge.js'],
      shutdownTimeout: const Duration(milliseconds: 20),
    );

    await transport.initialize();
    await transport.shutdown();
    expect(process.killed, isTrue);
  });
}

final class _FakeLauncher implements SidecarProcessLauncher {
  _FakeLauncher(this.processes);

  final List<_FakeProcess> processes;
  int starts = 0;

  @override
  Future<SidecarProcessConnection> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (starts >= processes.length) {
      throw StateError('No more fake sidecar processes available');
    }
    final process = processes[starts];
    starts += 1;
    return process;
  }
}

final class _FakeProcess implements SidecarProcessConnection {
  _FakeProcess({
    this.hangingMethods = const {},
    this.holdMethods = const {},
    this.writeError,
    this.hangExit = false,
  });

  final Set<String> hangingMethods;
  final Set<String> holdMethods;
  final Object? writeError;
  final bool hangExit;
  final StreamController<String> _stdout = StreamController.broadcast();
  final StreamController<String> _stderr = StreamController.broadcast();
  final Completer<int> _exit = Completer<int>();
  final Completer<void> _handshake = Completer<void>();
  final Map<String, String> _heldIds = {};
  final Map<String, String> _lastIds = {};
  final List<String> methods = [];
  bool inputClosed = false;
  bool killed = false;

  Future<void> get handshakeSeen => _handshake.future;

  String lastIdFor(String method) => _lastIds[method]!;

  void emitStdout(String line) => _stdout.add(line);

  void release(String method, Map<String, Object?> result) {
    final id = _heldIds.remove(method);
    if (id == null) {
      throw StateError('No held request for $method');
    }
    _stdout.add(
      jsonEncode({
        'protocolVersion': 1,
        'id': id,
        'result': result,
      }),
    );
  }

  @override
  Stream<String> get stdoutLines => _stdout.stream;

  @override
  Stream<String> get stderrLines => _stderr.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  Future<void> writeLine(String line) async {
    final error = writeError;
    if (error != null) {
      if (error is Error) {
        throw error;
      }
      if (error is Exception) {
        throw error;
      }
      throw StateError('$error');
    }
    final request = jsonDecode(line) as Map<String, Object?>;
    final method = request['method']! as String;
    final id = request['id']! as String;
    methods.add(method);
    _lastIds[method] = id;
    if (method == 'handshake' && !_handshake.isCompleted) {
      _handshake.complete();
    }
    if (hangingMethods.contains(method) || method == 'cancel') {
      return;
    }
    if (holdMethods.contains(method)) {
      _heldIds[method] = id;
      return;
    }
    final result = switch (method) {
      'handshake' => {
        'negotiatedVersion': 1,
        'version': {
          'protocolVersion': 1,
          'bridgeVersion': '1.0.0',
          'sdkVersion': '1.0.7',
          'cliVersion': '1.0.71',
        },
      },
      'health.get' => {'healthy': true},
      'shutdown' => {'stopped': true},
      _ => <String, Object?>{},
    };
    _stdout.add(
      jsonEncode({
        'protocolVersion': 1,
        'id': id,
        'result': result,
      }),
    );
    if (method == 'shutdown' && !_exit.isCompleted && !hangExit) {
      scheduleMicrotask(() => _exit.complete(0));
    }
  }

  void crash(int exitCode) {
    if (!_exit.isCompleted) {
      _exit.complete(exitCode);
    }
  }

  void emitStderr(String line) => _stderr.add(line);

  @override
  Future<void> closeInput() async {
    inputClosed = true;
  }

  @override
  bool kill() {
    killed = true;
    crash(-9);
    return true;
  }
}

final class _RecordingLogger implements AppLogger {
  final List<String> messages = [];

  @override
  void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }

  @override
  void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    AppFailure? failure,
  }) {
    messages.add(message);
  }

  @override
  void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }

  @override
  void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }
}
