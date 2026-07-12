import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failure = AppFailure(
    code: FailureCode.timeout,
    message: 'Timed out',
    detail: 'exceeded 8s',
  );

  group('Result.success', () {
    test('exposes value and success flags', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result, isA<Success<int>>());
    });

    test('when maps to success branch', () {
      const result = Result<String>.success('ok');

      final mapped = result.when(
        success: (value) => 'S:$value',
        onFailure: (_) => 'F',
      );

      expect(mapped, 'S:ok');
    });

    test('map transforms value', () {
      const result = Result<int>.success(2);
      final mapped = result.map((value) => value * 3);

      expect(mapped.valueOrNull, 6);
      expect(mapped.isSuccess, isTrue);
    });

    test('mapError is a no-op on success', () {
      const result = Result<int>.success(1);
      final mapped = result.mapError(
        (_) => const AppFailure(
          code: FailureCode.unknown,
          message: 'nope',
        ),
      );

      expect(mapped.valueOrNull, 1);
    });

    test('getOrElse returns value', () {
      const result = Result<int>.success(7);
      expect(result.getOrElse((_) => -1), 7);
    });
  });

  group('Result.failure', () {
    test('exposes failure and failure flags', () {
      const result = Result<int>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(result, isA<Failure<int>>());
    });

    test('when maps to failure branch', () {
      const result = Result<String>.failure(failure);

      final mapped = result.when(
        success: (_) => 'S',
        onFailure: (error) => 'F:${error.code.name}',
      );

      expect(mapped, 'F:timeout');
    });

    test('map preserves failure without transforming', () {
      const result = Result<int>.failure(failure);
      final mapped = result.map((value) => value + 1);

      expect(mapped.isFailure, isTrue);
      expect(mapped.failureOrNull, failure);
    });

    test('mapError transforms AppFailure', () {
      const result = Result<int>.failure(failure);
      final mapped = result.mapError(
        (error) => AppFailure(
          code: error.code,
          message: 'wrapped',
          detail: error.detail,
        ),
      );

      expect(mapped.failureOrNull?.message, 'wrapped');
      expect(mapped.failureOrNull?.code, FailureCode.timeout);
    });

    test('getOrElse uses fallback', () {
      const result = Result<int>.failure(failure);
      expect(result.getOrElse((error) => error.code.index), failure.code.index);
    });
  });

  group('equality', () {
    test('success values compare by value', () {
      expect(
        const Result<int>.success(1),
        const Result<int>.success(1),
      );
      expect(
        const Result<int>.success(1),
        isNot(const Result<int>.success(2)),
      );
    });

    test('failures compare by AppFailure', () {
      expect(
        const Result<int>.failure(failure),
        const Result<int>.failure(failure),
      );
      expect(
        const Result<int>.failure(failure),
        isNot(
          const Result<int>.failure(
            AppFailure(
              code: FailureCode.unknown,
              message: 'other',
            ),
          ),
        ),
      );
    });
  });
}
