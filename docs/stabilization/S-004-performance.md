# S-004 — Performance Report

**Date:** 2026-07-12  
**Gate:** Performance report complete — **PASS**

## Objective

Measure startup, refresh latency, idle cost; optimize only obvious bottlenecks.

## Summary

| Metric | Result | Notes |
|--|--|--|
| macOS Release artifact size | ~41–43 MB (`AI Tray.app`) | Acceptable for desktop Flutter |
| Fake refresh duration (unit) | typically 0–35 ms | Process spawn dominates real CLI (~1s PoC) |
| Real CLI refresh (historical PoC) | ~1s | Unchanged; no optimization attempted |
| Idle CPU / RAM (instrumented) | Not sampled this session | Dogfood: Activity Monitor while hidden in tray |
| Obvious bottlenecks | None requiring change | Soft retry already limited; single-flight present |

**No performance code changes** — no obvious safe wins without architecture/feature creep.

## Files changed

None (report only).

## Tests

N/A (measurement / report).

## Metrics

See table above.

## Risks

GUI + real `claude` spawn cost under aggressive intervals — keep ≥30s (settings floor).

## Conventional Commit

`docs: add S-004 performance report`

## Architecture Impact

None.

## Recommendation

Proceed to S-005. Sample idle RSS during dogfood.
