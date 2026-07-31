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
}
