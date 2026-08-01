/// Stable failure codes from ADR-002.
enum FailureCode {
  cliNotInstalled,
  notAuthenticated,
  timeout,
  processLaunchFailed,
  processNonZeroExit,
  parserFailure,
  unknownCliOutput,
  incompleteOutput,
  cacheUnavailable,
  cancelled,
  unknown,

  /// A Claude session transcript file was deleted or moved between listing
  /// and reading it. Introduced for v2 Session Browser (§8 of
  /// `docs/planning/v2-vision-and-roadmap.md`).
  sessionNotFound,

  /// A queue item's stored `cwd` no longer exists at execution time —
  /// fails fast, never creates the directory or substitutes another one
  /// (design principle 2). Introduced for v2 Resume Queue (§8/§21,
  /// Feature 2.2.2).
  workingDirectoryMissing,

  /// A stored `ResumeQueueItem` was read back missing its (required)
  /// budget cap — e.g. written by an older build. Distinct from the
  /// constructor's synchronous `ArgumentError` on the enqueue path; this
  /// is the read-path failure (§8/§9, Feature 2.2.2).
  budgetCapRequired,
}
