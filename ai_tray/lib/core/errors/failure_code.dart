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
}
