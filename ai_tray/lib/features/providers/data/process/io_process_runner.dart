import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/desktop_process_environment.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';

/// Production [ProcessRunner] backed by `dart:io` [Process].
final class IoProcessRunner implements ProcessRunner {
  IoProcessRunner({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  @override
  Future<Result<ProcessRunResult>> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 8),
    String? workingDirectory,
  }) async {
    final started = DateTime.now().toUtc();
    final resolved = DesktopProcessEnvironment.resolveExecutable(executable);
    final environment = DesktopProcessEnvironment.enriched();
    _logger.debug(
      'process start executable=$resolved args=${arguments.join(' ')}',
      name: 'process_runner',
    );

    try {
      final process = await Process.start(
        resolved,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: true,
      );
      // Close stdin for non-interactive Claude -p usage.
      // ignore: unawaited_futures -- fire-and-forget stdin close
      process.stdin.close();

      const encoding = SystemEncoding();
      final stdoutFuture = process.stdout.transform(encoding.decoder).join();
      final stderrFuture = process.stderr.transform(encoding.decoder).join();

      late final int exitCode;
      try {
        exitCode = await process.exitCode.timeout(timeout);
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        _logger.warning(
          'process timeout after ${timeout.inMilliseconds}ms',
          name: 'process_runner',
        );
        return Result.failure(
          AppFailure(
            code: FailureCode.timeout,
            message: 'Timed out waiting for $executable',
            detail: 'timeoutMs=${timeout.inMilliseconds}',
          ),
        );
      }

      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;
      final duration = DateTime.now().toUtc().difference(started);

      _logger.debug(
        'process done exit=$exitCode durationMs=${duration.inMilliseconds}',
        name: 'process_runner',
      );

      return Result.success(
        ProcessRunResult(
          exitCode: exitCode,
          stdout: stdout,
          stderr: stderr,
          duration: duration,
        ),
      );
    } on ProcessException catch (error, stackTrace) {
      _logger.error(
        'process launch failed',
        name: 'process_runner',
        error: error,
        stackTrace: stackTrace,
        failure: AppFailure(
          code: FailureCode.processLaunchFailed,
          message: 'Could not start $resolved',
          detail: error.message,
        ),
      );
      final lower = error.message.toLowerCase();
      final notFound = lower.contains('no such file') || error.errorCode == 2;
      final denied =
          lower.contains('operation not permitted') || error.errorCode == 1;
      return Result.failure(
        AppFailure(
          code: notFound
              ? FailureCode.cliNotInstalled
              : FailureCode.processLaunchFailed,
          message: notFound
              ? 'Claude CLI was not found'
              : denied
              ? 'macOS blocked launching Claude CLI'
              : 'Could not start $resolved',
          detail: error.message,
        ),
      );
    } on Exception catch (error, stackTrace) {
      _logger.error(
        'unexpected process error',
        name: 'process_runner',
        error: error,
        stackTrace: stackTrace,
      );
      return const Result.failure(
        AppFailure(
          code: FailureCode.unknown,
          message: 'Unexpected process error',
        ),
      );
    }
  }
}
