# S-002 — Long-running Stability

**Date:** 2026-07-12  
**Gate:** No critical reliability issues — **PASS** (automated proxy + bugfix)

## Objective

Verify refresh loop stability: no critical leaks in refresh path, timer/cache correctness, record findings.

## Summary

| Check | Result |
|--|--|
| 500-cycle Shape A→B→A stress (fake CLI) | PASS |
| Single-flight coalescing | PASS |
| Auto-refresh pause clears `nextScheduledAt` | **Fixed** then PASS |
| Wall-clock 6–12h session | Deferred to dogfood procedure (see below) |

### Bug fixed

`UsageRepositoryImpl` set `_autoRefreshPaused` **after** emitting status, so CLI-missing / auth failures still advertised a `nextScheduledAt`. Pause now applies **before** `_statusAfter`.

### Timer / sleep-wake notes

- Auto-refresh uses a one-shot `Timer` rescheduled after each refresh — no overlapping timers when pause/reschedule works.
- Sleep/wake: Dart `Timer` may delay across sleep; expected next fire after wake. Full wall-clock validation remains dogfood (RH-002 §10).

## Files changed

- `lib/features/usage/data/repositories/usage_repository_impl.dart` — pause-before-emit fix
- `test/unit/stability/long_running_refresh_test.dart` — stress + single-flight
- `lib/features/providers/data/process/fake_process_runner.dart` — `FutureOr` handler for async tests

## Tests

`flutter test` — includes stability suite (56 total after Phase 2).

## Metrics

- 500 refresh cycles (1 success + 250 soft + 249 success) completed in ~1s under fake runner
- Single-flight: 3 concurrent calls → 1 process start

## Risks

- Wall-clock 6–12h not executed in this session — use [dogfood daily log](../dogfood/daily-observation-log.md)

## Conventional Commit

`fix: pause auto-refresh before emitting next schedule`

## Architecture Impact

None (behavior aligned with ADR-002 intent).

## Recommendation

Proceed to S-003. Run overnight dogfood during Phase 2 / RC use.
