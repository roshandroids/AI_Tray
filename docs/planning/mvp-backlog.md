# MVP Backlog — Implementation-Ready Tasks

**Phase:** Lightweight Planning · Task 0002  
**Scope:** MVP only (tray, Claude usage, reset timer, auto/manual refresh, settings, notifications, launch at login)  
**Estimate guide:** ~2–6 hours per task  
**Dependency basis:** ADR-001 · system architecture · domain model

---

## Epic A — Foundation

### T-001 · Scaffold Flutter desktop project

| | |
|--|--|
| **Objective** | Create Flutter desktop app targeting macOS (and Windows stub), with Riverpod, logging, and analysis options. |
| **Dependencies** | Product Owner implementation approval |
| **Acceptance Criteria** | App launches on macOS; `flutter analyze` clean; Riverpod wired in `bootstrap`; no feature UI required beyond a blank shell |
| **Definition of Done** | Project matches proposed folder skeleton (empty feature dirs ok); README run instructions; committed |

### T-002 · Core errors, logging, and Result helpers

| | |
|--|--|
| **Objective** | Add shared `AppFailure`, logging facade, and a small Result type used by repositories. |
| **Dependencies** | T-001 |
| **Acceptance Criteria** | Failures have stable codes; logs include request/refresh correlation ids; unit smoke test for Result |
| **Definition of Done** | `core/` helpers documented; used by at least one placeholder repository test |

### T-003 · ProcessRunner abstraction

| | |
|--|--|
| **Objective** | Implement a testable process runner (start, timeout, stdout/stderr, exit code). |
| **Dependencies** | T-001, T-002 |
| **Acceptance Criteria** | Can run a benign command with timeout; fake runner available for unit tests |
| **Definition of Done** | Unit tests with fake; no Claude-specific logic inside runner |

---

## Epic B — Claude Provider Adapter

### T-004 · AiProviderPort + ProviderId

| | |
|--|--|
| **Objective** | Define provider port and Claude provider id without UI. |
| **Dependencies** | T-001 |
| **Acceptance Criteria** | Port methods cover usage fetch + health check contracts; Claude id constant exists |
| **Definition of Done** | Domain port reviewed against architecture doc; no CLI calls yet |

### T-005 · ClaudeCliAdapter usage fetch

| | |
|--|--|
| **Objective** | Call `claude -p '/usage' --output-format json` via ProcessRunner and return raw DTO. |
| **Dependencies** | T-003, T-004 |
| **Acceptance Criteria** | Captures stdout/stderr/exit/duration; does not use `--bare`; respects optional binary path override |
| **Definition of Done** | Integration test or manual scripted check on macOS; fixtures for offline unit tests |

### T-006 · Claude auth health probe

| | |
|--|--|
| **Objective** | Probe `claude auth status --json` and map to AuthHealth / AppFailure codes. |
| **Dependencies** | T-005 |
| **Acceptance Criteria** | Detects logged-out and CLI-missing cases with distinct failure codes |
| **Definition of Done** | Unit tests with fixture JSON; wired for repository error paths |

---

## Epic C — Parse, Validate, Cache

### T-007 · UsageParser (Shape A / Shape B)

| | |
|--|--|
| **Objective** | Parse free-text usage into candidate fields and `ParserState.shape`. |
| **Dependencies** | Domain model agreement; golden fixtures from research |
| **Acceptance Criteria** | Shape A fixture yields session % + weeks; Shape B yields `contributionOnly` without crashing |
| **Definition of Done** | Golden tests committed under `test/fixtures/claude_usage/` |

### T-008 · UsageValidator

| | |
|--|--|
| **Objective** | Validate parsed candidates into valid / incomplete / invalid. |
| **Dependencies** | T-007 |
| **Acceptance Criteria** | Percentages clamped/rejected per rules; Shape B → incomplete; malformed Shape A → invalid |
| **Definition of Done** | Unit tests cover all three validation statuses |

### T-009 · UsageCache (last known good)

| | |
|--|--|
| **Objective** | Persist and load `UsageInfo` + fetchedAt for cold start and soft failures. |
| **Dependencies** | T-002; storage choice recorded in short note or ADR-002 stub |
| **Acceptance Criteria** | Round-trip serialize; missing cache returns empty; corrupt cache fails soft |
| **Definition of Done** | Unit tests with temp storage; no UI dependency |

### T-010 · RefreshService single-flight + timeout

| | |
|--|--|
| **Objective** | Orchestrate adapter → parse → validate → cache write; expose RefreshStatus. |
| **Dependencies** | T-005, T-007, T-008, T-009 |
| **Acceptance Criteria** | Overlapping refresh coalesces; timeout maps to failure; Shape A updates cache; Shape B keeps cache and softFailure |
| **Definition of Done** | Unit tests with fake adapter; status transitions documented |

### T-011 · UsageRepositoryImpl

| | |
|--|--|
| **Objective** | Implement domain repository port combining cache + refresh + settings interval reads. |
| **Dependencies** | T-010, T-012 (can stub settings) |
| **Acceptance Criteria** | `watch`/`get` returns Async-friendly stream or polling API for Riverpod; maps AppFailure correctly |
| **Definition of Done** | Repository tests for success, softFailure, failure |

---

## Epic D — Settings & Notifications (domain/data first)

### T-012 · AppSettings + SettingsRepository

| | |
|--|--|
| **Objective** | Persist auto-refresh, interval, notification flags, launch-at-login, CLI path override. |
| **Dependencies** | T-001, T-002 |
| **Acceptance Criteria** | Defaults applied; invalid intervals rejected; round-trip persistence |
| **Definition of Done** | Unit tests; settings readable by RefreshService |

### T-013 · Notification policy service

| | |
|--|--|
| **Objective** | Given UsageInfo + settings, decide whether to notify (threshold crossing). |
| **Dependencies** | T-012, domain UsageInfo |
| **Acceptance Criteria** | No duplicate notify for same threshold window; disabled settings suppress |
| **Definition of Done** | Pure unit tests; platform notifier behind interface |

---

## Epic E — Desktop Shell (after data path green)

### T-014 · Tray shell + menu actions

| | |
|--|--|
| **Objective** | Menu bar / tray icon with Open, Refresh, Settings, Quit. |
| **Dependencies** | T-011 (can show placeholder strings initially) |
| **Acceptance Criteria** | Actions fire; app usable without dock focus on macOS |
| **Definition of Done** | Manual test checklist on macOS passed |

### T-015 · Usage popup binding

| | |
|--|--|
| **Objective** | Show session %, weekly %, reset time, stale indicator, last updated, error/retry. |
| **Dependencies** | T-011, T-014 |
| **Acceptance Criteria** | Success / softFailure / failure / empty cache states all distinct; manual refresh works |
| **Definition of Done** | Manual QA script; no DTO leakage into widgets |

### T-016 · Settings UI

| | |
|--|--|
| **Objective** | Edit MVP settings and persist via SettingsRepository. |
| **Dependencies** | T-012, T-014 |
| **Acceptance Criteria** | Changing interval reschedules auto-refresh; CLI path override used on next refresh |
| **Definition of Done** | Manual QA; validation errors surfaced |

### T-017 · Local notifications wiring

| | |
|--|--|
| **Objective** | Platform notifications when policy service says notify. |
| **Dependencies** | T-013, T-015 |
| **Acceptance Criteria** | Permission/request handled; notification appears on threshold in test |
| **Definition of Done** | macOS manual test; failure to notify does not crash refresh loop |

### T-018 · Launch at login

| | |
|--|--|
| **Objective** | Honor `launchAtLogin` setting on macOS (Windows best-effort or follow-up). |
| **Dependencies** | T-012, T-016 |
| **Acceptance Criteria** | Toggle survives restart; disabling removes login item |
| **Definition of Done** | Manual verify on macOS; limitation noted if Windows deferred |

---

## Epic F — Quality & Cross-platform gate

### T-019 · Parser regression suite + CI analyze/test

| | |
|--|--|
| **Objective** | CI runs analyzer + unit tests including usage fixtures. |
| **Dependencies** | T-007, T-008, T-010 |
| **Acceptance Criteria** | PR CI green on analyze/test; fixtures cover Shape A/B |
| **Definition of Done** | Workflow documented in README |

### T-020 · Windows CLI smoke validation

| | |
|--|--|
| **Objective** | Validate Claude CLI `/usage` + auth status on Windows; record findings. |
| **Dependencies** | ADR-001; can run before or parallel with late Epic E |
| **Acceptance Criteria** | Research note updated with Windows pass/fail; blockers listed |
| **Definition of Done** | Gate decision for Windows MVP inclusion documented |

### T-021 · MVP acceptance pass

| | |
|--|--|
| **Objective** | End-to-end verify roadmap MVP checklist and success metrics. |
| **Dependencies** | T-014–T-018, T-019 |
| **Acceptance Criteria** | Startup &lt; 2s typical; refresh &lt; 5s; idle RAM sanity check; no browser dependency; softFailure UX acceptable |
| **Definition of Done** | Signed MVP acceptance notes; ready for PO release review |

---

## Suggested implementation order

```text
T-001 → T-002 → T-003 → T-004 → T-005 → T-006
                 ↘ T-012
T-007 → T-008 → T-009 → T-010 → T-011 → T-013
T-014 → T-015 → T-016 → T-017 → T-018
T-019 throughout after T-007
T-020 before claiming Windows
T-021 last
```

---

## Explicitly out of backlog (post-MVP)

- Analytics / charts / history
- Multi-account
- Multi-provider UI
- OAuth usage endpoint (optional spike only if Shape B rate is high)
