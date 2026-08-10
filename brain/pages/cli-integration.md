---
id: cli-integration
title: Claude CLI integration constraints
category: concept
status: active
tags: [claude, cli, adapter]
created: "2026-08-09T23:31:29"
updated: "2026-08-09T23:37:41"
---

<!-- compiled_truth -->
## The exact invocation (verified: `claude_cli_adapter.dart`)

```
claude -p /usage --output-format json
```

**Never `--bare`** for usage polls — called out explicitly in the adapter's
class doc comment as a load-bearing constraint, not a style choice. Health
checks run a separate, cheap call: `claude --version`.

## What's parsed, and why it's risky

- stdout is JSON-decoded into an "envelope" (`Map<String, dynamic>`); a
  non-zero exit code or non-JSON/non-map stdout both fail fast with a typed
  `AppFailure` (`processNonZeroExit` / `unknownCliOutput`) before the parser
  ever runs.
- The envelope's inner usage text is **not a stable public schema** —
  [ADR-001](../../docs/adr/ADR-001-claude-cli-data-source.md) and
  `ARCHITECTURE_STATE.md` both call this out. `UsageParser` /
  `UsageValidator` classify the parsed shape (`UsageShape` /
  `ValidationStatus`) rather than assuming a fixed structure — see
  [[usage-data-model]].
- Practical consequence for future agents: **keep fixtures for every
  observed CLI output format** you encounter; do not "fix" a parser
  regression by narrowing what it accepts.

## Failure handling (owned by `RefreshService`, not the adapter)

The adapter only classifies *its own* fetch — it does not retry, cache, or
decide soft vs hard failure. See [[caching-strategy]] for the retry/fallback
policy layered on top by `RefreshService`, and [[usage-data-model]] for how
a CLI-level failure differs from a validation-level failure in what the UI
shows.

`healthCheck()` (`claude --version`) is only invoked opportunistically by
`RefreshService` — when the fetch failure looks like `cliNotInstalled` /
`notAuthenticated`, or after repeated hard failures — to get a more specific
error to surface, not on every refresh.

## Configuration

- Default binary name is `"claude"` (resolved via `ProviderExecutionConfig`);
  a custom executable path is only honored when
  `provider.capabilities.customExecutable` is true, sourced from
  `settings.claudeBinaryPath`.
- **Timeout is enforced one layer down, in `ProcessRunner`** (`ai_tray/lib/
  features/providers/data/process/process_runner.dart`), not in the
  adapter: `run()` defaults to an **8-second** timeout
  (`Duration timeout = const Duration(seconds: 8)`). `FailureCode.timeout`
  originates there and is treated as retryable by `RefreshService` (see
  [[caching-strategy]]).

## Constraint provenance

[ADR-001](../../docs/adr/ADR-001-claude-cli-data-source.md) ("Claude CLI as
External Data Source") and
[ADR-002](../../docs/adr/ADR-002-error-handling-resilience.md) ("Error
Handling & Resilience") are the formal decisions behind this. Note:
ADR-002's header still reads "Proposed (awaiting Product Owner acceptance)"
as of the last check, but its resilience model (single-flight, bounded
retry, LKG fallback, soft/hard failure split) is fully implemented and
load-bearing in `refresh_service.dart` — treat it as de facto normative
regardless of the header status, and flag the stale header if you touch
that ADR.


## Timeline

- time: 2026-08-09T23:31:29
  kind: decision
  summary: "Created this page: Claude CLI integration constraints"
  source: "ai_tray/lib/features/providers/data/claude/claude_cli_adapter.dart, docs/adr/ADR-001, docs/adr/ADR-002"
  affects: [cli-integration]

- time: 2026-08-09T23:32:15
  kind: decision
  summary: "Seed compiled_truth: verified claude CLI invocation, schema instability, failure classification, ADR-002 status mismatch"
  source: "claude_cli_adapter.dart, ADR-001, ADR-002"
  affects: [cli-integration]

- time: 2026-08-09T23:37:41
  kind: decision
  summary: "Fix: add real relative ADR links, confirm ProcessRunner enforces an 8s default timeout (was previously flagged as unverified)"
  source: process_runner.dart
  affects: [cli-integration]
