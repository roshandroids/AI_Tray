import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:meta/meta.dart';

/// Observability for the parse / validate pipeline.
@immutable
final class ParserState {
  factory ParserState({
    required UsageShape shape,
    required bool rateLimitsPresent,
    required bool matchedSessionLine,
    required int matchedWeekLineCount,
    required ValidationStatus validation,
    required int rawTextLength,
    List<String> messages = const [],
  }) {
    if (matchedWeekLineCount < 0) {
      throw ArgumentError.value(
        matchedWeekLineCount,
        'matchedWeekLineCount',
        'must be >= 0',
      );
    }
    if (rawTextLength < 0) {
      throw ArgumentError.value(
        rawTextLength,
        'rawTextLength',
        'must be >= 0',
      );
    }
    return ParserState._(
      shape: shape,
      rateLimitsPresent: rateLimitsPresent,
      matchedSessionLine: matchedSessionLine,
      matchedWeekLineCount: matchedWeekLineCount,
      validation: validation,
      messages: List<String>.unmodifiable(messages),
      rawTextLength: rawTextLength,
    );
  }

  const ParserState._({
    required this.shape,
    required this.rateLimitsPresent,
    required this.matchedSessionLine,
    required this.matchedWeekLineCount,
    required this.validation,
    required this.messages,
    required this.rawTextLength,
  });

  /// Empty / not-yet-parsed placeholder.
  factory ParserState.empty() {
    return ParserState(
      shape: UsageShape.unknown,
      rateLimitsPresent: false,
      matchedSessionLine: false,
      matchedWeekLineCount: 0,
      validation: ValidationStatus.invalid,
      rawTextLength: 0,
    );
  }

  final UsageShape shape;
  final bool rateLimitsPresent;
  final bool matchedSessionLine;
  final int matchedWeekLineCount;
  final ValidationStatus validation;
  final List<String> messages;
  final int rawTextLength;

  ParserState copyWith({
    UsageShape? shape,
    bool? rateLimitsPresent,
    bool? matchedSessionLine,
    int? matchedWeekLineCount,
    ValidationStatus? validation,
    int? rawTextLength,
    List<String>? messages,
  }) {
    return ParserState(
      shape: shape ?? this.shape,
      rateLimitsPresent: rateLimitsPresent ?? this.rateLimitsPresent,
      matchedSessionLine: matchedSessionLine ?? this.matchedSessionLine,
      matchedWeekLineCount: matchedWeekLineCount ?? this.matchedWeekLineCount,
      validation: validation ?? this.validation,
      rawTextLength: rawTextLength ?? this.rawTextLength,
      messages: messages ?? this.messages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! ParserState) return false;
    if (other.shape != shape ||
        other.rateLimitsPresent != rateLimitsPresent ||
        other.matchedSessionLine != matchedSessionLine ||
        other.matchedWeekLineCount != matchedWeekLineCount ||
        other.validation != validation ||
        other.rawTextLength != rawTextLength ||
        other.messages.length != messages.length) {
      return false;
    }
    for (var i = 0; i < messages.length; i++) {
      if (other.messages[i] != messages[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    shape,
    rateLimitsPresent,
    matchedSessionLine,
    matchedWeekLineCount,
    validation,
    Object.hashAll(messages),
    rawTextLength,
  );
}
