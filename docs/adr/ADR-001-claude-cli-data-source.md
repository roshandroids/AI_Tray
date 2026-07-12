# ADR-001 — Claude CLI as External Data Source

| Field | Value |
|-------|-------|
| Status | Accepted |
| Date | 2026-07-12 |
| Decision makers | Product Owner · Lead Engineer |
| Relates to | Task 0001 PoC · Decision 002 |
| Supersedes | — |

---

## Decision

The MVP will use the **installed Claude Code CLI** as the **primary external data source** for subscription usage.

Canonical fetch command:

```text
claude -p '/usage' --output-format json
```

(with stdin closed / non-interactive).

The application will:

1. Spawn the CLI as an external process
2. Capture stdout / stderr
3. Parse the JSON envelope and free-text `result`
4. Validate parsed fields
5. Cache the last known-good rate-limit snapshot
6. Degrade gracefully when rate-limit lines are absent (Shape B)

The free-text `/usage` format is **not** treated as a stable public API. Parsing must be defensive, version-aware, and backed by fixtures from research.

---

## Context

Task 0001 (Claude CLI Proof of Concept) concluded:

**PASS WITH LIMITATIONS**

Proven:

- `/usage` runs non-interactively via `-p`
- Typical latency ~1s (well under the 5s refresh goal)
- Queries do not appear to consume model/subscription quota (`total_cost_usd: 0`, `duration_api_ms: 0`)
- Auth via existing Claude.ai / Team login is sufficient on macOS

Limitations:

- Rate-limit block (`Current session` / `Current week` + reset times) is **intermittent**
- No first-party structured schema for rate limits (JSON wraps free text)
- Windows not validated
- `--bare` returns the wrong payload and must not be used

Product principles require research-before-build, a small MVP, Clean Architecture, and provider-agnostic design. MVP scope needs usage %, reset timer, auto/manual refresh — all dependent on this data source decision.

---

## Alternatives considered

### A. Claude CLI `/usage` (chosen)

Spawn local `claude` and parse output.

- Pros: Simple; uses user’s existing login; no browser; maintainable vs scraping; validated in PoC
- Cons: Text fragility; intermittent Shape B; process overhead; Windows TBD

### B. Official Anthropic Usage API (if/when available)

Call a documented HTTP usage API.

- Pros: Structured, versioned contract
- Cons: No suitable official subscriber rate-limit API confirmed for Claude Code limits at PoC time; would still need auth bridging

### C. Undocumented OAuth usage endpoint

Community-documented `GET .../api/oauth/usage` returning structured utilization.

- Pros: Structured JSON; likely what `/usage` itself uses internally
- Cons: Undocumented; ToS/breakage risk; token handling complexity; not PoC-validated as primary

### D. Browser companion / scraping / automation

Read usage from claude.ai UI.

- Pros: Might mirror web dashboard exactly
- Cons: Fragile; browser dependency; violates MVP success metric (“no browser dependency”); higher maintenance

### E. Statusline `rate_limits` hook only

Consume Claude Code statusline JSON inside an active session.

- Pros: Structured `five_hour` / `seven_day` fields (where available)
- Cons: Requires active Claude Code session; not a standalone tray data source; Team plan caveats reported by community

---

## Trade-offs

| Benefit | Cost |
|---------|------|
| Fast path to MVP without browser | Parser must handle format churn |
| Reuses user’s CLI auth | App fails if CLI missing or logged out |
| Zero apparent quota cost per poll | Burst polling may correlate with Shape B |
| Clear process boundary for testing | ~1s per refresh; process spawn cost |
| Provider interface still possible later | Claude-specific adapter details leak unless isolated |

---

## Consequences

### Positive

- Implementation can proceed behind a Claude adapter + parser + cache
- Matches roadmap priority: CLI → API → extension → automation
- Supports offline-ish tray UX via last-known-good cache when Shape B occurs

### Negative / obligations

- Must implement Shape A vs Shape B handling and soft failures
- Must never use `--bare` for usage polling
- Must detect CLI presence + auth health before refresh loops
- Must add golden text fixtures and parser tests
- Must validate Windows before claiming cross-platform MVP
- Must document that contribution analytics are local-machine only (not MVP primary UI)

### Follow-ups (not blocking Lightweight Planning)

- Optional spike: OAuth usage endpoint as **fallback only** if Shape B is common in real use
- Windows CLI parity validation task in MVP backlog

---

## Compliance with Decision 002

This ADR locks the data-source choice for MVP planning and upcoming implementation. It does **not** authorize Flutter scaffolding or production coding until Product Owner approval of the full Lightweight Planning package.
