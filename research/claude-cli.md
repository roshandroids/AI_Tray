# R1 — Claude CLI Usage Investigation

**Task:** 0001 — Claude CLI Proof of Concept  
**Status:** Complete — approved PASS WITH LIMITATIONS (Decision 002 → Lightweight Planning)  
**Date:** 2026-07-12  
**Environment:** macOS Darwin arm64 · Claude Code `2.1.193` · path `/opt/homebrew/bin/claude`  
**Auth (observed):** Claude Team (`claude.ai`), organization present, `claude auth status` → `loggedIn: true`

---

## Feasibility conclusion

### ⚠️ PASS WITH LIMITATIONS

The installed Claude CLI **can** be launched programmatically, can return subscription usage text, and that text **can** be parsed into structured fields suitable for an MVP tray app.

However, the MVP-critical **rate-limit block** (`Current session` / `Current week` percentages and reset times) is **not consistently present**. Early runs in this investigation returned the full rate-limit block; subsequent polls returned only local “what’s contributing” analytics. There is also **no first-party structured usage JSON** for rate limits — only a JSON envelope around free-text.

**Recommendation for MVP:** Proceed with Claude CLI (`claude -p /usage`) as the **primary** data source, with mandatory caching, graceful degradation when rate-limit lines are absent, and a follow-up spike on the community-documented OAuth usage endpoint as a structured fallback. Do **not** treat the CLI text format as a stable API contract.

---

## Research questions

| # | Question | Answer | Evidence |
|---|----------|--------|----------|
| 1 | Can `/usage` be executed programmatically? | **Yes** | `claude -p '/usage'` exits 0 and prints usage text |
| 2 | Is there a non-interactive equivalent? | **Yes** | `-p` / `--print` headless mode; stdin redirected to `/dev/null` |
| 3 | Is structured (JSON) output available? | **Partial** | `--output-format json` returns a result envelope; rate-limit fields live inside free-text `result`, not typed JSON |
| 4 | Is the output stable enough to parse? | **Conditionally** | Two observed shapes; regex works when rate-limit lines exist; format may change without notice |
| 5 | Does querying usage consume quota? | **No evidence of consumption** | Envelope `total_cost_usd: 0`, `duration_api_ms: 0`, token usage all zeros across repeated polls |
| 6 | Does it require an authenticated session? | **Yes** | Requires logged-in Claude.ai / Team session (`claude auth status`) |
| 7 | Does it work on both macOS and Windows? | **macOS yes; Windows untested** | Validated only on Darwin arm64 in this PoC |
| 8 | What is the average execution time? | **~1.06 s** | 5-run benchmark: min 0.92s, max 1.32s (see `poc/timing_benchmark.json`) |
| 9 | Can it be safely polled every 30–60s? | **Likely yes for cost; reliability caveats** | Zero cost per call; however heavy polling may correlate with missing rate-limit blocks (observed after burst of queries) |

---

## Findings

### Primary command

```bash
claude -p '/usage' --output-format json </dev/null
```

Equivalent text mode:

```bash
claude -p '/usage' --output-format text </dev/null
```

### Auth prerequisite

```bash
claude auth status --json
```

Observed shape (email redacted in fixtures):

```json
{
  "loggedIn": true,
  "authMethod": "claude.ai",
  "apiProvider": "firstParty",
  "email": "[REDACTED]",
  "orgId": "...",
  "orgName": "...",
  "subscriptionType": "team"
}
```

### No dedicated `claude usage` subcommand

`claude usage` is **not** a real subcommand in `2.1.193`. Invoking it starts a normal prompt/agent turn. Usage is exposed via the **slash command** `/usage` inside an interactive or `-p` session.

### `--bare` breaks subscription usage

```bash
claude -p '/usage' --bare --output-format json
```

Returned session **cost** stats (`Total cost: $0.0000` …), **not** subscription rate limits. Do not use `--bare` for MVP usage polling.

### `/status` unavailable in `-p`

```text
/status isn't available in this environment.
```

### Two observed `/usage` response shapes

**Shape A — complete (MVP-usable)** — captured early in this investigation (`poc/sample_usage_text_with_rate_limits.txt`):

```text
You are currently using your subscription to power your Claude Code usage

Current session: 2% used · resets Jul 12 at 10pm (America/Toronto)
Current week (all models): 0% used · resets Jul 19 at 7am (America/Toronto)
Current week (Fable): 0% used

What's contributing to your limits usage?
...
```

**Shape B — incomplete (soft failure)** — dominant after repeated polls (`poc/sample_usage_text_contribution_only.txt`):

```text
You are currently using your subscription to power your Claude Code usage

What's contributing to your limits usage?
Approximate, based on local sessions on this machine — does not include other devices or claude.ai.
...
```

Shape B still proves the CLI launches and returns data, but **cannot power the MVP reset timer / % used UI** without a prior cached Shape A value (or an alternate source).

### JSON envelope (not rate-limit schema)

When using `--output-format json`, stdout is a single JSON object. Relevant fields observed:

| Field | Typical value for `/usage` | Meaning |
|-------|----------------------------|---------|
| `type` | `result` | Envelope type |
| `subtype` | `success` | Success marker |
| `is_error` | `false` | Error flag |
| `result` | free-text usage report | **Actual usage payload** |
| `total_cost_usd` | `0` | Indicates no billable model spend for this call |
| `duration_api_ms` | `0` | No model API duration attributed |
| `usage.*_tokens` | `0` | No token consumption attributed |
| `session_id` | UUID | A session is still created for the `-p` invocation |

### Quota consumption

Across all successful polls in this investigation:

- `total_cost_usd` was always `0`
- `duration_api_ms` was always `0`
- token counters were always `0`

Conclusion: querying `/usage` via `-p` does **not** appear to consume Claude Code subscription quota / model budget. Contribution analytics request counts may still increment locally (request counters in the contribution section moved slightly during testing), which is separate from rate-limit utilization %.

### Timing

From `poc/timing_benchmark.json` (5 consecutive runs):

- Average: **1.064 s**
- Min: **0.920 s**
- Max: **1.318 s**

Well within the product success metric of refresh &lt; 5 seconds. Suitable for 30–60s polling from a wall-clock perspective.

### Cross-platform

| Platform | Result |
|----------|--------|
| macOS (Darwin arm64) | Validated |
| Windows | **Not tested** in Task 0001 |

Claude Code ships for Windows, so parity is plausible, but Windows path resolution, auth storage, and process spawning must be validated before calling MVP “done” for Windows.

### Related / alternate sources (not validated as primary)

Community sources document:

1. Statusline `rate_limits` JSON (`five_hour` / `seven_day`) — only inside an active Claude Code session statusline hook; not a standalone tray data source.
2. Undocumented OAuth endpoint `GET https://api.anthropic.com/api/oauth/usage` — reportedly returns structured utilization JSON for subscribers.

These are **out of scope** for this PoC’s primary path, but are strong candidates if Shape B flakiness persists in planning.

---

## Commands tested

| Command | Result |
|---------|--------|
| `claude --version` | `2.1.193 (Claude Code)` |
| `claude --help` | Documents `-p`, `--output-format` |
| `claude auth status --json` | Logged in (Team) |
| `claude -p '/usage' --output-format text` | Usage text (Shape A then Shape B) |
| `claude -p '/usage' --output-format json` | JSON envelope + text `result` |
| `claude -p '/usage' --bare ...` | Wrong payload (cost summary) |
| `claude -p '/status'` | Not available in `-p` |
| `claude usage` | Not a subcommand; treated as a prompt |
| `python3 research/poc/fetch_usage.py` | Launches CLI, captures stdout/stderr, parses fields |

---

## Output samples

Fixtures live under [`research/poc/`](poc/):

| File | Description |
|------|-------------|
| `sample_usage_text_with_rate_limits.txt` | Shape A (complete) |
| `sample_usage_text_contribution_only.txt` | Shape B (incomplete) |
| `sample_usage_json.json` | Live JSON envelope sample |
| `sample_auth_status.json` | Auth status (email redacted) |
| `timing_benchmark.json` | Timing + zero-cost evidence |
| `fetch_usage.py` | Minimal PoC prototype |

### Parsed Shape A (from PoC parser self-test)

```json
{
  "rate_limits_present": true,
  "session_used_percent": 2.0,
  "session_resets_at": "Jul 12 at 10pm (America/Toronto)",
  "weeks": [
    {"label": "all models", "used_percent": 0.0, "resets_at": "Jul 19 at 7am (America/Toronto)"},
    {"label": "Fable", "used_percent": 0.0, "resets_at": null}
  ]
}
```

### Live PoC run (Shape B at time of final test)

- Process exit: `0`
- PoC exit code: `3` (soft failure: response OK, rate limits missing)
- `elapsed_ms`: ~998
- `total_cost_usd`: `0`
- `rate_limits_present`: `false`

---

## Proof of Concept

**Location:** [`research/poc/fetch_usage.py`](poc/fetch_usage.py)

**What it does:**

1. Resolves the installed `claude` binary
2. Launches `claude -p /usage --output-format json` with stdin closed
3. Captures stdout/stderr and wall time
4. Parses the JSON envelope and free-text `result`
5. Emits structured JSON for consumers
6. Exit codes:
   - `0` — success with rate-limit fields present
   - `1` — hard failure (process/JSON)
   - `2` — CLI missing
   - `3` — soft failure (CLI OK, rate limits absent)

**Run:**

```bash
cd research/poc
python3 fetch_usage.py
python3 fetch_usage.py --raw
```

**Parser self-test:** executed successfully against Shape A and Shape B fixtures during this investigation.

This prototype is intentionally **not** Flutter and is **not** production application code.

---

## Limitations

1. **Rate-limit block is intermittent** — MVP-critical percentages/reset times may be missing.
2. **Free-text contract** — no official schema for rate limits; brittle against copy/UI wording changes.
3. **Windows untested.**
4. **Auth required** — unauthenticated / API-key-only setups may not expose subscription `/usage` the same way.
5. **`--bare` incompatible** with subscription usage retrieval.
6. **Each poll creates a `-p` session** (`session_id` present) — unknown long-term side effects of high-frequency polling.
7. **Contribution section is local-machine only** — explicitly excludes other devices / claude.ai web usage.
8. **Team plan nuances** — community reports suggest Team may differ from Pro/Max for some rate-limit surfaces (statusline); `/usage` worked for Team here, but flakiness remains.
9. **No official guarantee** that `/usage` in `-p` mode is a supported integration API.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Anthropic changes `/usage` text format | Parser breaks | Version pin + golden fixtures + defensive parsing + telemetry on parse failures |
| Rate-limit block frequently absent | Tray shows stale/empty usage | Cache last good Shape A; UI “last updated”; investigate OAuth usage API |
| Heavy polling triggers incomplete responses | Degraded accuracy | Poll 30–60s; backoff on Shape B; avoid burst fetches |
| CLI missing or logged out | App unusable | Detect `claude` on PATH + `auth status`; clear user messaging |
| Windows path/auth differences | Partial MVP | Dedicated Windows validation before release |
| Relying on undocumented OAuth API later | Breakage / ToS risk | Prefer CLI; treat OAuth as optional fallback with ADR |

---

## Recommendation

1. **Accept Claude CLI as the MVP primary source** under ⚠️ PASS WITH LIMITATIONS.
2. In Lightweight Planning, require:
   - Adapter interface around process execution
   - Text parser with Shape A / Shape B handling
   - Last-known-good cache
   - Auth/CLI health checks
3. Schedule a short follow-up spike (still Discovery/Planning, not Flutter UI): evaluate structured OAuth usage endpoint as fallback **only if** Shape B remains common in day-to-day use.
4. Validate Windows before declaring cross-platform MVP complete.
5. **Do not** start the Flutter application until this gate is explicitly approved.

---

## Decision gate

**⚠️ PASS WITH LIMITATIONS — Usable, but document all caveats.**

Claude CLI is a viable official data source for the MVP **provided** the product accepts:

- text parsing instead of a first-party usage schema,
- intermittent absence of rate-limit lines,
- macOS-first validation (Windows TBD),
- authenticated Claude.ai / Team session requirement.

**Stop here.** Awaiting approval before Lightweight Planning and Implementation.
