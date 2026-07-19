# AI Tray — Project State

**Updated:** 2026-07-19
**Current release:** v1.3.3 (`1.3.3+9`)
**Default branch:** `main` at `2885980`
**Active development branch:** `cursor/post-ep002-stabilization`
**Current milestone:** Stabilization complete; EP-004 = targeted cleanup
**Overall progress:** EP-002 merged; Phase 3 not yet published

## Current status

Post-EP-002 stabilization is complete on the active branch: shared refresh
lifecycle races fixed, sidecar protocol coverage expanded, dogfood checklists
written, and EP-004 assessed as **targeted cleanup** (ADR-004 / PD-024).

## Completed

- EP-002 Phase 3 merge (PR #7)
- EP-003 / EP-003A research + AI handoff package (PR #8)
- Stabilization baseline and P0 lifecycle fixes
- Sidecar/host protocol hardening + assembly smoke in CI/Release
- EP-004 assessment recommending targeted cleanup

## In progress / unmerged

- Stabilization PR for `cursor/post-ep002-stabilization`
- macOS arm64 dogfood execution (checklist ready)
- Windows runtime verification (checklist ready; remains Experimental)

## Health

- Analyzer clean; 144 non-golden tests; 7 goldens; bridge npm check green
- No production `/copilot_internal`

## Next gate

Merge stabilization, dogfood macOS arm64, then Product Owner release call.
Targeted cleanup may follow as a separate narrow PR series.
