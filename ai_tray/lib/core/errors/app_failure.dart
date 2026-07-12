import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:meta/meta.dart';

/// User-safe application failure (domain / shared).
///
/// Infrastructure must not put secrets in [detail].
@immutable
final class AppFailure {
  const AppFailure({
    required this.code,
    required this.message,
    this.detail,
  });

  final FailureCode code;

  /// User-safe summary suitable for UI copy.
  final String message;

  /// Optional sanitized diagnostic (never tokens / full PII).
  final String? detail;

  AppFailure copyWith({
    FailureCode? code,
    String? message,
    String? detail,
  }) {
    return AppFailure(
      code: code ?? this.code,
      message: message ?? this.message,
      detail: detail ?? this.detail,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppFailure &&
        other.code == code &&
        other.message == message &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(code, message, detail);

  @override
  String toString() => 'AppFailure(code: $code, message: $message)';
}
