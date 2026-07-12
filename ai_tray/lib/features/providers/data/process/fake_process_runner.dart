import 'dart:async';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';

/// In-memory [ProcessRunner] for unit tests.
final class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner({
    this.handler,
  });

  FutureOr<Result<ProcessRunResult>> Function(
    String executable,
    List<String> arguments,
  )?
  handler;

  final List<(String, List<String>)> calls = [];

  @override
  Future<Result<ProcessRunResult>> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 8),
    String? workingDirectory,
  }) async {
    calls.add((executable, List<String>.from(arguments)));
    final custom = handler;
    if (custom != null) {
      return custom(executable, arguments);
    }
    return const Result.failure(
      AppFailure(
        code: FailureCode.unknown,
        message: 'FakeProcessRunner has no handler configured',
      ),
    );
  }
}
