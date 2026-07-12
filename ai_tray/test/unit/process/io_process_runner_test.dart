import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/providers/data/process/io_process_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps missing executable to cliNotInstalled when possible', () async {
    final runner = IoProcessRunner(
      logger: ConsoleAppLogger(defaultName: 'process_test'),
    );

    final result = await runner.run(
      '__ai_tray_definitely_missing_binary__',
      const ['--version'],
      timeout: const Duration(seconds: 2),
    );

    expect(result.isFailure, isTrue);
    // Platform may report "No such file" (cliNotInstalled) or launch failed.
    expect(
      result.failureOrNull?.code,
      anyOf(FailureCode.cliNotInstalled, FailureCode.processLaunchFailed),
    );
  });
}
