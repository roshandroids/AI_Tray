import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:meta/meta.dart';

/// Result of one refresh cycle for repository / UI consumers.
@immutable
final class RefreshResult {
  factory RefreshResult({
    required RefreshOutcome status,
    required ParserState parserState,
    required Duration duration,
    UsageInfo? usage,
    AppFailure? error,
    int? cliExitCode,
  }) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'must not be negative');
    }
    return RefreshResult._(
      status: status,
      usage: usage,
      parserState: parserState,
      error: error,
      duration: duration,
      cliExitCode: cliExitCode,
    );
  }

  const RefreshResult._({
    required this.status,
    required this.usage,
    required this.parserState,
    required this.error,
    required this.duration,
    required this.cliExitCode,
  });

  final RefreshOutcome status;
  final UsageInfo? usage;
  final ParserState parserState;
  final AppFailure? error;
  final Duration duration;
  final int? cliExitCode;

  RefreshResult copyWith({
    RefreshOutcome? status,
    UsageInfo? usage,
    ParserState? parserState,
    AppFailure? error,
    Duration? duration,
    int? cliExitCode,
  }) {
    return RefreshResult(
      status: status ?? this.status,
      usage: usage ?? this.usage,
      parserState: parserState ?? this.parserState,
      error: error ?? this.error,
      duration: duration ?? this.duration,
      cliExitCode: cliExitCode ?? this.cliExitCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RefreshResult &&
        other.status == status &&
        other.usage == usage &&
        other.parserState == parserState &&
        other.error == error &&
        other.duration == duration &&
        other.cliExitCode == cliExitCode;
  }

  @override
  int get hashCode => Object.hash(
        status,
        usage,
        parserState,
        error,
        duration,
        cliExitCode,
      );
}
