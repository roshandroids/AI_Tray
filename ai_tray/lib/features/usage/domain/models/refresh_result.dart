import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
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
    ProviderId? providerId,
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
      providerId: providerId ?? usage?.providerId,
    );
  }

  const RefreshResult._({
    required this.status,
    required this.usage,
    required this.parserState,
    required this.error,
    required this.duration,
    required this.cliExitCode,
    required this.providerId,
  });

  final RefreshOutcome status;
  final UsageInfo? usage;
  final ParserState parserState;
  final AppFailure? error;
  final Duration duration;
  final int? cliExitCode;
  final ProviderId? providerId;

  RefreshResult copyWith({
    RefreshOutcome? status,
    UsageInfo? usage,
    ParserState? parserState,
    AppFailure? error,
    Duration? duration,
    int? cliExitCode,
    ProviderId? providerId,
  }) {
    return RefreshResult(
      status: status ?? this.status,
      usage: usage ?? this.usage,
      parserState: parserState ?? this.parserState,
      error: error ?? this.error,
      duration: duration ?? this.duration,
      cliExitCode: cliExitCode ?? this.cliExitCode,
      providerId: providerId ?? this.providerId,
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
        other.cliExitCode == cliExitCode &&
        other.providerId == providerId;
  }

  @override
  int get hashCode => Object.hash(
    status,
    usage,
    parserState,
    error,
    duration,
    cliExitCode,
    providerId,
  );
}
