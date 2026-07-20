# AI Tray — Project State

**Updated:** 2026-07-19
**Current release:** v1.3.3 (`1.3.3+9`)
**Default branch:** `main` at `2885980`
**Active development branch:** `cursor/post-ep002-stabilization`
**Current milestone:** Stabilization complete; EP-004 = targeted cleanup; EP-004A CI Local First implemented (uncommitted)
**Overall progress:** EP-002 merged; Phase 3 not yet published

## Current status

Post-EP-002 stabilization is complete on the active branch: shared refresh
lifecycle races fixed, sidecar protocol coverage expanded, dogfood checklists
written, and EP-004 assessed as **targeted cleanup** (ADR-004 / PD-024).

**CI strategy (active):** Local First — Quality on PR/main (no desktop builds);
Documentation for docs paths; Release on tag/`workflow_dispatch` only;
Maintenance weekly outdated reports; Lefthook for optional local hooks.
See `docs/devops/LOCAL_DEVELOPMENT.md` and `docs/release/CI-CD.md`.

## Completed

- EP-002 Phase 3 merge (PR #7)
- EP-003 / EP-003A research + AI handoff package (PR #8)
- Stabilization baseline and P0 lifecycle fixes
- Sidecar/host protocol hardening + assembly smoke in Release
- EP-004 assessment recommending targeted cleanup
- EP-004A Local First CI redesign (working tree)

## In progress / unmerged

- Stabilization PR for `cursor/post-ep002-stabilization`
- EP-004A workflow/Lefthook/docs changes (not yet committed)
- macOS arm64 dogfood execution (checklist ready)
- Windows runtime verification (checklist ready; remains Experimental)

## Health

- Analyzer clean; 144 non-golden tests; 7 goldens; bridge npm check green
- No production `/copilot_internal`

## Next gate

Update branch protection (remove `Build macOS`), land CI + stabilization,
dogfood macOS arm64, then Product Owner release call.
Targeted cleanup may follow as a separate narrow PR series.
