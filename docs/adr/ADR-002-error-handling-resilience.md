# ADR-002 — Error Handling & Resilience

| Field | Value |
|-------|-------|
| Status | Proposed (awaiting Product Owner acceptance) |
| Date | 2026-07-12 |
| Decision makers | Product Owner · Lead Engineer |
| Relates to | ADR-001 · Task 0001 PoC · Task 0002 architecture · Decision 003 |
| Supersedes | — |

---

## Decision

The MVP will treat Claude CLI usage refresh as an **unreliable external dependency** and apply a uniform resilience model:

1. **Classify** every failure into a stable `AppFailure` code (or soft-failure outcome).
2. **Retry** only transient failures, with bounded backoff and single-flight refresh.
3. **Serve Last Known Good (LKG)** cached `UsageInfo` whenever fresh Shape A data is unavailable.
4. **Never crash** the tray process due to refresh/parse/cache errors.
5. **Never present incomplete or guessed percentages as live truth** — stale cache must be labeled; empty state must be explicit.
6. **Log** enough to diagnose Shape A/B and process failures without leaking secrets or full PII.

This ADR is normative for RefreshService, UsageRepository, Parser/Validator, Cache, and presentation error copy.

---

## Context

ADR-001 accepted Claude CLI (`claude -p '/usage'`) with **PASS WITH LIMITATIONS**. PoC showed:

- Hard failures: missing CLI, auth issues, process problems, timeouts
- Soft failures: Shape B (contribution-only, no rate-limit block)
- Format risk: free-text contract may change across Claude Code versions

Product success metrics require refresh &lt; 5s and a stable desktop companion. Users must trust percentages and reset times; silent wrong data is worse than an honest stale/error state.

---

## 1. Error categories

All refresh outcomes map to either `RefreshOutcome.success`, `softFailure`, or `failure` (see domain model). Failures use stable codes below.

| Code | Category | Trigger | Outcome class |
|------|----------|---------|---------------|
| `cliNotInstalled` | Environment | `claude` not found on PATH / configured path | `failure` |
| `notAuthenticated` | Auth | `auth status` logged out / expired / unusable for `/usage` | `failure` |
| `timeout` | Transient | Process exceeds refresh timeout | `failure` |
| `processLaunchFailed` | Environment / OS | Process cannot start (permissions, exec format, IO) | `failure` |
| `processNonZeroExit` | Transient / env | CLI exits non-zero without classifiable auth/missing binary | `failure` |
| `parserFailure` | Data contract | Envelope/text cannot be interpreted; validator `invalid` | `failure` |
| `unknownCliOutput` | Data contract | Output unrecognized (empty, wrong payload e.g. cost summary, novel layout) | `failure` |
| `incompleteOutput` | Soft / degraded | Shape B — CLI OK but rate-limit block missing | `softFailure` |
| `cacheUnavailable` | Local storage | Read/write cache fails or corrupt | Degraded support path (see §3); does not by itself invent usage |
| `cancelled` | Control | Refresh superseded/cancelled by single-flight policy | Internal; usually not user-facing |
| `unknown` | Catch-all | Unexpected exception | `failure` |

### Category notes

- **`incompleteOutput` is not a hard failure.** It is expected under ADR-001. It must not clear LKG cache.
- **`unknownCliOutput` vs `parserFailure`:** use `unknownCliOutput` when the payload is structurally unexpected (e.g. `--bare` cost summary, empty `result`); use `parserFailure` when Shape A-like text exists but fields fail validation (bad percents, contradictory lines).
- **`cacheUnavailable` during a successful Shape A fetch:** still return success to the user if in-memory usage is valid; log error and skip persistence.
- **`cacheUnavailable` on cold start with no memory:** show empty/error state — never fabricate numbers.

---

## 2. Retry strategy

### Principles

- Only **one** CLI usage process at a time (single-flight).
- Retries are **per refresh cycle** (manual or scheduled), not unbounded background storms.
- Auto-refresh schedule continues independently, but consecutive failures escalate backoff (see below).
- Manual refresh always allowed; it resets user-facing error copy but still respects single-flight.

### Per-attempt timeout

| Setting | Value |
|---------|-------|
| CLI usage process timeout | **8 seconds** (above PoC ~1s average; under product 5s “happy path” goal for success UX; timeout itself may surface after 8s) |
| Auth probe timeout | **5 seconds** |

> Product metric “refresh &lt; 5 seconds” applies to **successful** refreshes. Timeout budget is intentionally slightly higher to reduce false timeouts on slow machines; UI should show a refreshing state within 100–200ms.

### Automatic retries (within one refresh cycle)

| Failure code | Auto-retry? | Attempts (including first) | Interval between attempts | Notes |
|--------------|-------------|----------------------------|---------------------------|-------|
| `timeout` | Yes | 2 | 2s | Transient |
| `processNonZeroExit` | Yes | 2 | 2s | If second fails → classify via auth probe when appropriate |
| `processLaunchFailed` | No* | 1 | — | *Retry once only if error suggests transient resource exhaustion; default **no** |
| `incompleteOutput` | Yes (light) | 2 | 3s | Second attempt only; if still Shape B → softFailure + LKG |
| `cliNotInstalled` | **Never** | 1 | — | Needs user action |
| `notAuthenticated` | **Never** | 1 | — | Needs `claude auth login` |
| `parserFailure` | **Never** | 1 | — | Unlikely to self-heal mid-cycle |
| `unknownCliOutput` | **Never** | 1 | — | Same |
| `cacheUnavailable` | N/A | — | — | Not a CLI retry; optional one cache re-read |
| `unknown` | Yes | 2 | 2s | Then surface failure |

### Scheduled auto-refresh backoff

Applies when auto-refresh is enabled (default interval 30–60s from settings):

| Condition | Behavior |
|-----------|----------|
| Success (Shape A) | Reset consecutive counters; next poll at configured interval |
| Soft failure (Shape B) | Keep showing LKG; increment `consecutiveSoftFailures`; after **3** consecutive: stretch next interval to `max(configured, 120s)` until a Shape A success |
| Hard failure (retryable exhausted) | Increment `consecutiveHardFailures`; after **2**: run auth/CLI health probe; after **3**: stretch interval to `max(configured, 180s)` and show persistent error affordance |
| Hard failure (non-retryable: missing CLI / auth) | **Pause auto-refresh** until manual refresh or settings change; show blocking guidance |

### Never retry automatically

- `cliNotInstalled`
- `notAuthenticated`
- `parserFailure`
- `unknownCliOutput`
- User cancelled quit / app shutdown mid-refresh (`cancelled`)

---

## 3. Cache strategy

### Last Known Good (LKG)

| Rule | Definition |
|------|------------|
| What is cached | Only **validator-approved Shape A** `UsageInfo` (rate limits present and valid) |
| What is never cached as LKG | Shape B parses, invalid parses, guessed/default percentages, contribution-only analytics |
| On softFailure | Return LKG if present; set `isFromCache = true` |
| On hard failure | Return LKG if present; set `isFromCache = true` + attach `AppFailure` |
| On success | Replace LKG atomically; `isFromCache = false` |

### Cache lifetime

| Policy | Value |
|--------|-------|
| Soft max age (stale-but-displayable) | **6 hours** from `fetchedAt` |
| Hard max age (do not display percentages) | **24 hours** from `fetchedAt` |
| Within soft max age | Show LKG with explicit stale indicator |
| Between soft and hard max age | Show LKG with stronger “outdated” warning; suppress threshold notifications |
| Beyond hard max age | Do **not** show numeric usage as current; treat as empty + last-updated metadata optional in diagnostics only |

### Stale data policy

- Stale LKG is allowed and preferred over blank UI **within soft max age**.
- UI must distinguish:
  - **Live** — fresh Shape A this cycle
  - **Cached / possibly stale** — LKG after soft/hard failure or cold start before first success
  - **Outdated** — past soft max age
  - **Unavailable** — no LKG or past hard max age
- Reset countdown timers derived from cached `sessionResetsAt` may still be shown while stale, but must not imply a successful live refresh.

### Cache invalidation rules

Invalidate (delete / ignore) LKG when:

1. User explicitly clears cache / resets app data (settings action, if provided)
2. Hard max age exceeded
3. Successful parse proves a **different provider identity** (future multi-provider)
4. Auth user/org identity changes materially (email/orgId from auth probe differs from cache metadata) — avoid showing another account’s quotas
5. Corrupt cache payload fails integrity/schema check (`cacheUnavailable`)

Do **not** invalidate LKG solely because of Shape B or transient timeouts.

---

## 4. User experience

### Global UX laws

1. The app **must not crash** on refresh, parse, or cache errors.
2. The app **must not** show placeholder zeros, random percents, or contribution stats as subscription limits.
3. Every displayed % / reset time must be attributable to either **live Shape A** or **LKG** with labeling.
4. Errors use calm, actionable copy — not raw stderr.

### Per-category UX

| Situation | Primary UI | Secondary | Auto-refresh |
|-----------|------------|-----------|--------------|
| Live success | Session % · week % · reset times · “Updated just now” | — | Normal |
| Soft failure + LKG (fresh enough) | LKG numbers + **“Showing last known usage”** / stale badge | Subtle “Claude didn’t return limits; retrying later” | Continue with soft backoff |
| Soft failure + no LKG | Empty usage + “Usage temporarily unavailable” | Retry button | Soft backoff |
| `cliNotInstalled` | Blocking message: Claude Code CLI not found | How to install / set binary path in Settings | Paused |
| `notAuthenticated` | Blocking message: Sign in to Claude | Instruct `claude auth login` (or documented flow) | Paused |
| `timeout` / retryable process errors (exhausted) | If LKG: stale badge + “Refresh failed”; else empty + retry | Keep Retry enabled | Hard backoff |
| `parserFailure` / `unknownCliOutput` | If LKG: stale + “Couldn’t read Claude usage format”; else empty | Suggest update Claude Code / report version | Hard backoff (do not spin forever) |
| `processLaunchFailed` | Error + retry; settings path override hint | — | Hard backoff |
| `cacheUnavailable` alone | If live success in memory: show live; else empty | “Couldn’t save/load local cache” as non-blocking notice when relevant | Unaffected |
| Outdated LKG (soft–hard age) | Numbers + **“Outdated”** warning | Notifications suppressed | Continue trying refresh |
| Past hard max age | No percentages | “Usage data expired — refresh required” | Continue trying |

### Misleading-information prohibitions

- Do not label Shape B contribution text as “session usage.”
- Do not update the tray badge/percent from incomplete output.
- Do not reset `lastSuccessAt` on softFailure.
- Do not clear visible LKG on softFailure.

---

## 5. Logging policy

### Levels

| Level | When | Examples |
|-------|------|----------|
| **Info** | Normal lifecycle | App start; refresh started/finished; outcome `success`/`softFailure`/`failure` code; duration_ms; cache hit/miss; auto-refresh schedule changes; Claude Code version string if queried |
| **Warning** | Degraded but handled | Shape B (`incompleteOutput`); stale LKG served; soft/hard backoff engaged; cache corrupt ignored; non-zero exit then recovered on retry |
| **Error** | Operation failed after policy | Final failure codes; unexpected exceptions; persistent auth/CLI missing; validator invalid after Shape A-looking text |

### Required fields on refresh logs

- `providerId`
- `failureCode` or `outcome`
- `durationMs`
- `parser.shape` / `validation`
- `rateLimitsPresent` (bool)
- `usedCache` (bool)
- `cliExitCode` (nullable)
- `consecutiveSoftFailures` / `consecutiveHardFailures` when relevant

### Never log (sensitive / prohibited)

- Auth tokens, cookies, API keys, `Authorization` headers
- Full email addresses (log hashed or redact to domain-only if needed)
- Org secrets or raw account identifiers beyond opaque ids already present in local auth status **if avoidable**
- Entire raw `/usage` payload in **release** builds (may include environment-identifying skill/MCP names)
- User file paths unrelated to the configured CLI binary
- Clipboard contents or prompt text from other sessions

### Conditional debug logging

- In debug/profile builds only: truncated raw `result` text (e.g. first 500 chars) behind an explicit debug flag
- Stderr snippets sanitized to ≤200 chars, stripped of token-like patterns

---

## 6. Future compatibility (CLI output format changes)

### Assumptions

Claude Code may change `/usage` wording, field order, JSON envelope keys, or rate-limit semantics at any time. The text format is **not** a versioned public API (ADR-001).

### Required architectural behaviors

1. **Parser/validator isolation** — All format knowledge lives in Parser + Validator + golden fixtures; UI and repository depend only on domain models.
2. **Shape detection first** — Classify `rateLimitsPresent` / `contributionOnly` / `unknown` before field extraction.
3. **Fail closed on unknowns** — Novel layouts → `unknownCliOutput` or `parserFailure`, then LKG + labeled stale UI — never partial invent.
4. **Fixture-driven evolution** — When format changes are discovered, add fixtures first, then update parser; ship parser hotfixes without tray redesign.
5. **Version awareness** — Log Claude Code version on health probe; optional compatibility table in docs (not a hard block unless known broken).
6. **Feature flag / kill switch** — Settings or remote-free local flag to disable auto-refresh if a breaking CLI release ships.
7. **Escape hatch** — Keep provider port so a future structured source (official API or approved fallback ADR) can replace CLI text parsing without rewriting UX.

### Compatibility test obligations

Before declaring a parser change done:

- Shape A historical fixtures still pass
- Shape B still yields softFailure (not success)
- At least one “novel/unknown” fixture yields failure (not success)
- LKG not cleared by unknown/soft paths

---

## Consequences

### Positive

- Predictable degradation aligned with PoC limitations
- Users retain trustworthy numbers via LKG labeling
- Reduced retry storms and clearer auth/CLI guidance
- Safer logs for a desktop companion

### Negative / obligations

- Implementers must wire failure codes, backoff, and cache ages consistently
- Stale UX must be designed carefully (presentation task inherits these rules)
- Hard max age may blank the UI after a long offline period — intentional

### Non-goals

- This ADR does not choose storage technology (Drift/Hive/SharedPreferences)
- This ADR does not authorize OAuth usage API (requires a separate ADR if pursued)
- This ADR does not define visual layout — only information truthfulness and messaging intent

---

## Compliance

Until Product Owner accepts this ADR, it remains **Proposed**. No Flutter scaffold or implementation should begin solely on this draft; Decision 003’s approval gate applies after review.

---

## References

- [ADR-001 — Claude CLI as External Data Source](ADR-001-claude-cli-data-source.md)
- [System Architecture](../architecture/system-architecture.md)
- [Domain Model](../architecture/domain-model.md)
- [Risk Register](../planning/risk-register.md)
- [R1 Claude CLI Research](../../research/claude-cli.md)
