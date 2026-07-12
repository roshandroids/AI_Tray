/// Observed `/usage` text shape (research Shape A / B).
enum UsageShape {
  /// Rate-limit percentages and reset lines present (Shape A).
  rateLimitsPresent,

  /// Contribution analytics only; rate limits missing (Shape B).
  contributionOnly,

  /// Unrecognized or empty payload.
  unknown,
}
