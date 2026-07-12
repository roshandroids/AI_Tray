import 'package:ai_tray/core/result/result.dart';

/// Outcome of a single external process invocation.
final class ProcessRunResult {
  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;
}

/// Testable process execution boundary (no Claude-specific logic).
abstract interface class ProcessRunner {
  Future<Result<ProcessRunResult>> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 8),
    String? workingDirectory,
  });
}
