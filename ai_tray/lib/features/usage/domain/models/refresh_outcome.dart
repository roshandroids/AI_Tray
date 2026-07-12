/// Outcome of a single refresh attempt.
enum RefreshOutcome {
  /// Shape A validated; cache updated.
  success,

  /// CLI responded; rate limits missing/incomplete; cache retained.
  softFailure,

  /// Process/auth/timeout/invalid; cache retained if available.
  failure,
}
