import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/features/providers/data/process/desktop_process_environment.dart';

/// Writable, line-oriented persistent child-process connection.
abstract interface class SidecarProcessConnection {
  Stream<String> get stdoutLines;
  Stream<String> get stderrLines;
  Future<int> get exitCode;

  /// Writes and flushes one NDJSON request.
  Future<void> writeLine(String line);

  /// Closes stdin so the bridge can complete graceful shutdown.
  Future<void> closeInput();

  /// Terminates the process when graceful cleanup cannot complete.
  bool kill();
}

/// Testable factory for persistent sidecar process connections.
abstract interface class SidecarProcessLauncher {
  Future<SidecarProcessConnection> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });
}

/// Production launcher backed by `dart:io` process streams.
final class IoSidecarProcessLauncher implements SidecarProcessLauncher {
  const IoSidecarProcessLauncher();

  @override
  Future<SidecarProcessConnection> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final process = await Process.start(
      DesktopProcessEnvironment.resolveExecutable(executable),
      arguments,
      workingDirectory: workingDirectory,
      environment: DesktopProcessEnvironment.enriched(),
      includeParentEnvironment: true,
    );
    return _IoSidecarProcessConnection(process);
  }
}

final class _IoSidecarProcessConnection implements SidecarProcessConnection {
  _IoSidecarProcessConnection(this._process)
    : stdoutLines = _process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
      stderrLines = _process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter());

  final Process _process;

  @override
  final Stream<String> stdoutLines;

  @override
  final Stream<String> stderrLines;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> writeLine(String line) async {
    _process.stdin.writeln(line);
    await _process.stdin.flush();
  }

  @override
  Future<void> closeInput() => _process.stdin.close();

  @override
  bool kill() => _process.kill();
}
