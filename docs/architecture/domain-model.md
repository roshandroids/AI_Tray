# Domain Model — MVP

**Phase:** Lightweight Planning · Task 0002  
**Scope:** Fields and responsibilities only (no Dart code)

---

## UsageInfo

**Responsibility:** Canonical snapshot of subscription rate-limit usage shown by the tray.

| Field | Type (conceptual) | Notes |
|-------|-------------------|-------|
| `sessionUsedPercent` | `double` | 0–100; from “Current session” |
| `sessionResetsAt` | `DateTime?` or display `String` + parsed instant | Prefer parsed instant when possible; keep display string if parse ambiguous |
| `sessionResetsAtRaw` | `String?` | Original CLI text fragment |
| `weekly` | `List<WeeklyUsage>` | e.g. all models, Fable |
| `fetchedAt` | `DateTime` | When this snapshot was obtained |
| `source` | `UsageSource` | `cli` (MVP); future `oauth`, etc. |
| `isFromCache` | `bool` | True when served from last-known-good |
| `providerId` | `ProviderId` | `claude` for MVP |

### WeeklyUsage

| Field | Type | Notes |
|-------|------|-------|
| `label` | `String` | e.g. `all models`, `Fable` |
| `usedPercent` | `double` | 0–100 |
| `resetsAt` | `DateTime?` | May be null (observed for some buckets) |
| `resetsAtRaw` | `String?` | Original text |

---

## RefreshResult

**Responsibility:** Outcome of a single refresh attempt for the repository / UI.

| Field | Type | Notes |
|-------|------|-------|
| `status` | `RefreshOutcome` | `success` · `softFailure` · `failure` |
| `usage` | `UsageInfo?` | Fresh on success; often cached on soft/hard failure |
| `parserState` | `ParserState` | What the parser/validator observed |
| `error` | `AppFailure?` | Populated on failure (and optionally soft failure detail) |
| `duration` | `Duration` | Wall time of the refresh cycle |
| `cliExitCode` | `int?` | Diagnostics; not for UI copy |

### RefreshOutcome

| Value | Meaning |
|-------|---------|
| `success` | Shape A validated; cache updated |
| `softFailure` | CLI responded; rate limits missing/incomplete; cache retained |
| `failure` | Process/auth/timeout/invalid; cache retained if available |

---

## ParserState

**Responsibility:** Observability and branching for parse/validate pipeline.

| Field | Type | Notes |
|-------|------|-------|
| `shape` | `UsageShape` | `rateLimitsPresent` · `contributionOnly` · `unknown` |
| `rateLimitsPresent` | `bool` | Convenience flag |
| `matchedSessionLine` | `bool` | Regex/session line hit |
| `matchedWeekLineCount` | `int` | How many week buckets parsed |
| `validation` | `ValidationStatus` | `valid` · `incomplete` · `invalid` |
| `messages` | `List<String>` | Non-user-facing diagnostics |
| `rawTextLength` | `int` | Support/debug |

### UsageShape

| Value | Maps to research |
|-------|------------------|
| `rateLimitsPresent` | Shape A |
| `contributionOnly` | Shape B |
| `unknown` | Unrecognized / empty |

---

## AppSettings

**Responsibility:** User-configurable behavior for refresh, notifications, and startup.

| Field | Type | Notes |
|-------|------|-------|
| `autoRefreshEnabled` | `bool` | Default true |
| `refreshInterval` | `Duration` | MVP target 30–60s; enforce min/max |
| `notificationsEnabled` | `bool` | |
| `notifyAtSessionPercent` | `double?` | Optional threshold |
| `launchAtLogin` | `bool` | |
| `claudeBinaryPath` | `String?` | Null = resolve from PATH |
| `showStaleIndicator` | `bool` | Default true when serving cache after soft failure |

---

## RefreshStatus

**Responsibility:** Live refresh-loop state for UI binding (distinct from a single `RefreshResult`).

| Field | Type | Notes |
|-------|------|-------|
| `phase` | `RefreshPhase` | `idle` · `refreshing` · `cooldown` |
| `lastResult` | `RefreshResult?` | Most recent completed cycle |
| `lastSuccessAt` | `DateTime?` | Last Shape A success |
| `nextScheduledAt` | `DateTime?` | For auto-refresh countdown if desired |
| `consecutiveSoftFailures` | `int` | Backoff / warning signal |
| `consecutiveHardFailures` | `int` | Trigger health checks |

### RefreshPhase

| Value | Meaning |
|-------|---------|
| `idle` | Not currently fetching |
| `refreshing` | CLI invocation in flight (single-flight) |
| `cooldown` | Optional short pause after burst/errors |

---

## Supporting domain types (MVP)

### ProviderId

| Field | Notes |
|-------|-------|
| `value` | `claude` for MVP; reserved for future providers |

### AppFailure

| Field | Notes |
|-------|-------|
| `code` | e.g. `cliNotFound`, `notAuthenticated`, `timeout`, `parseInvalid`, `unknown` |
| `message` | User-safe summary |
| `detail` | Optional diagnostic (stderr snippet, sanitized) |

### AuthHealth (optional MVP)

| Field | Notes |
|-------|-------|
| `loggedIn` | From `claude auth status` |
| `subscriptionType` | e.g. team / pro — informational |
| `checkedAt` | Timestamp |

---

## Mapping notes (non-code)

- DTOs from CLI JSON envelope are **data-layer only**; map into `UsageInfo` + `ParserState` before UI.
- Contribution analytics from Shape B are **not** core MVP domain fields (may be ignored or deferred).
- Prefer immutable models with `copyWith` at implementation time.
