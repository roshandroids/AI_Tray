import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown by [sessionDetailProvider] on a repository failure. Carries the
/// original [FailureCode] (unlike a bare `StateError`) so the page can
/// distinguish `sessionNotFound` — which needs its own "session no longer
/// available" state (Feature 1.2.2 acceptance criteria) — from any other
/// failure.
///
/// Extends [Error], not merely `implements Exception`: riverpod 3.x
/// retries a provider's `create` call automatically on failure — up to 10x
/// with exponential backoff (`ProviderContainer.defaultRetry`) — unless
/// the thrown object `is Error`. Throwing a plain `Exception` implementer
/// here reproduced that exact hang (confirmed by a real test timeout, not
/// a hypothetical): the failure log line appeared immediately, but
/// `.future` didn't settle for the full 10-retry backoff window. This is
/// the same reason `SessionBrowserController._load()` already throws
/// `StateError` rather than `AppFailure` directly — that choice
/// incidentally also avoided this retry behavior, though its own doc
/// comment only cited the `only_throw_errors` lint. Recorded here so a
/// later provider doesn't reintroduce the hang by throwing an `Exception`
/// implementer for an intentionally terminal failure.
final class SessionLoadException extends Error {
  SessionLoadException(this.code, this.message);

  final FailureCode code;
  final String message;

  @override
  String toString() => message;
}

/// Loads one session's full detail for the Session Detail view (Feature
/// 1.2.2).
///
/// A `FutureProvider.family` rather than a custom `AsyncNotifier` class:
/// this codebase's installed `riverpod` (3.3.2) only exposes `.family` as a
/// static builder on `Provider`/`FutureProvider`/`StreamProvider` — the
/// manual (non-codegen) `AsyncNotifierProvider` has no `.family` builder in
/// this version (confirmed against the installed package source; a family
/// notifier is codegen-only via `@riverpod`, which this codebase doesn't
/// use anywhere). `FutureProvider.family` gives the identical `AsyncValue`
/// loading/data/error shape `SessionBrowserController` exposes,
/// parameterized by session id — sufficient here since this feature has no
/// "refresh" story, unlike 1.2.1.
///
/// Not `autoDispose`: a plain `container.read(provider.future)`/
/// `ref.read(...).future` call (used both by the page and by tests) has no
/// active `ref.watch`/`container.listen` keeping it alive, so riverpod
/// schedules an autoDispose provider for disposal while its future is
/// still pending — a real race, not a hypothetical one (confirmed by a
/// `disposed during loading state` failure when this provider was tried
/// with `.autoDispose`). No other provider in this codebase uses
/// `autoDispose` either, so this keeps the same behavior everywhere.
/// (The family provider's return type, `FutureProviderFamily`, isn't part
/// of riverpod's public export surface, so it can't be spelled out
/// explicitly — the ignore below is unavoidable, not a shortcut.)
// ignore: specify_nonobvious_property_types
final sessionDetailProvider = FutureProvider.family<ClaudeSession, String>((
  ref,
  sessionId,
) async {
  final result = await ref
      .read(sessionRepositoryProvider)
      .readSession(
        sessionId,
      );
  final failure = result.failureOrNull;
  if (failure != null) {
    ref
        .read(appLoggerProvider)
        .warning(
          'session detail load failed sessionId=$sessionId',
          name: 'session_detail',
          error: failure,
        );
    throw SessionLoadException(failure.code, failure.message);
  }
  return result.valueOrNull!;
});
