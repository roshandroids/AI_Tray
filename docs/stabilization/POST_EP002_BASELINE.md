# Post-EP-002 Stabilization Baseline Report

**Date:** 2026-07-19  
**Branch:** `cursor/post-ep002-stabilization`  
**Base:** `main` @ `2885980` (PR #7 merged)  
**Scope:** Reliability only — no new provider or product capability

## Baseline results

| Gate | Result | Notes |
| --- | --- | --- |
| `dart format --set-exit-if-changed lib test` | Pass | 165 files, 0 changes |
| `flutter analyze --fatal-infos` | Pass | No issues |
| `flutter test --exclude-tags golden,screenshot` | Pass | **132** tests |
| `flutter test --tags golden` | Pass | **7** goldens |
| `flutter test --tags screenshot` | Pass | **10** screenshot captures |
| `npm run check` (Copilot bridge) | Pass | **15** Node tests, 0 fail (1 live auth SKIP) |

## Classification

### P0 — must fix in this sprint

| ID | Defect | Evidence |
| --- | --- | --- |
| S-P0-1 | Disposal during in-flight refresh can still mutate status and reschedule a timer | `UsageRepositoryImpl.dispose` cancels timer/closes stream but does not set a disposed flag; completion path calls `_emit` / `_reschedule` |
| S-P0-2 | ABA provider switch accepts a stale completion | Repository compares provider IDs only; Claude→Copilot→Claude allows the original Claude future to update UI |
| S-P0-3 | Soft/hard backoff counters are global across providers | Three Claude failures can impose Claude backoff on Copilot after a switch |

### P1 — harden with tests / small fixes

| ID | Item | Notes |
| --- | --- | --- |
| S-P1-1 | Cache write failures are ignored | Refresh still reports success; add logging and regression coverage |
| S-P1-2 | Sidecar protocol edge cases | Malformed NDJSON, late responses, concurrent requests, shutdown timeout partially untested |
| S-P1-3 | Sleep/wake overdue schedule recovery | No lifecycle observer; add explicit resume recovery hook + test |
| S-P1-4 | TrayController lacks disposal of stream/listeners | Document + cover; full desktop plugin disposal remains platform dogfood |

### Optional / deferred (not blockers)

- Full sleep/wake WidgetsBindingObserver wiring beyond a testable resume hook
- Provider-folder rewrite (EP-004 decision pending)
- Signed/notarized macOS
- Windows host dogfood (keep Experimental until verified)
- `screenshot`/`golden` tags not listed in `dart_test.yaml` (warning only)

## Acceptance for this sprint

- One active refresh per provider (already covered; keep regression)
- No status/timer mutation after dispose
- Stale ABA completions rejected
- Provider-scoped backoff after switches
- Cache write failure logged; refresh remains recoverable
- Sidecar protocol failure paths covered
- macOS dogfood checklist documented; Windows checklist remains Experimental if unverified
- EP-004 assessment produced with evidence-backed recommendation

## Boundaries honored

- No Cursor provider implementation
- No new product features
- No release for docs/governance alone
- No provider-folder rewrite before assessment decision
