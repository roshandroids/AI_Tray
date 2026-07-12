import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:meta/meta.dart';

/// Explicit success/failure container for normal control flow.
///
/// Prefer [Result] over throwing for expected operational failures.
/// [AppFailure] is the only failure payload (ADR-002).
@immutable
sealed class Result<T> {
  const Result();

  /// Successful value.
  const factory Result.success(T value) = Success<T>;

  /// Failed operation with a typed [AppFailure].
  const factory Result.failure(AppFailure failure) = Failure<T>;

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  /// Success value, or `null` when failed.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  /// Failure, or `null` when successful.
  AppFailure? get failureOrNull => switch (this) {
    Success() => null,
    Failure(:final failure) => failure,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(:final failure) => onFailure(failure),
    };
  }

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Result.success(transform(value)),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  Result<T> mapError(AppFailure Function(AppFailure failure) transform) {
    return switch (this) {
      Success() => this,
      Failure(:final failure) => Result.failure(transform(failure)),
    };
  }

  /// Returns the success value, otherwise the result of [fallback].
  T getOrElse(T Function(AppFailure failure) fallback) {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final failure) => fallback(failure),
    };
  }
}

/// Successful [Result].
@immutable
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success($value)';
}

/// Failed [Result] carrying an [AppFailure].
@immutable
final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Failure, failure);

  @override
  String toString() => 'Failure($failure)';
}
