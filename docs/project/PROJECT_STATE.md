# AI Tray — Project State

**Updated:** 2026-07-31
**Current release:** v1.3.3 (`1.3.3+9`)
**Default branch:** `main` (verify tip with `git log origin/main -1`)
**Active development branch:** `cursor/ep004a-local-first-ci`
**Current milestone:** Stabilization complete; EP-004 = targeted cleanup; Quality CI + Release CD (EP-004A) + demo strategy (PD-025)
**Overall progress:** EP-002 merged; Phase 3 not yet published

## Current status

Post-EP-002 stabilization is complete: shared refresh lifecycle races fixed,
sidecar protocol coverage expanded, dogfood checklists written, and EP-004
assessed as **targeted cleanup** (ADR-004 / PD-024).

**CI/CD strategy (Quality CI + Release CD):**
- Quality: PR/push → `main`, Ubuntu only (Format / Analyze / Test / Validate workflows)
- Documentation: docs/showcase/markdown paths, no Flutter
- Release CD: tag / `workflow_dispatch` only — sole owner of macOS/Windows builds
- Maintenance: weekly + dispatch outdated reports
- Guardrail in Quality asserts companions stay ubuntu-only
See `docs/devops/LOCAL_DEVELOPMENT.md` and `docs/release/CI-CD.md`.

**Demo strategy (PD-025 / D-016):** Product-as-demo. Showcase lists
`showcase/demos.json` → `id: main` (`type: desktop`, Releases download).
No duplicate playground. Callable `reusable-flutter-web-demo.yml` is for other
RSProjects only. See `docs/devops/DEMO_STRATEGY.md`.

## Completed

- EP-002 Phase 3 merge (PR #7)
- EP-003 / EP-003A research + AI handoff package (PR #8)
- Stabilization baseline and P0 lifecycle fixes
- Sidecar/host protocol hardening + assembly smoke in Release
- EP-004 assessment recommending targeted cleanup
- EP-004A Quality CI + Release CD redesign (`ci.yml` removed on branch)
- Demo/Showcase standardization (product-as-demo in `demos.json` + reusable web workflow)
- Quality CI ubuntu-only guardrail + CI-CD docs sync (2026-07-31)
- Document Platform parity gap analysis → `docs/reports/v2-refactor-plan.md`
  (analysis only; phased adoption not started)

## In progress / unmerged

- EP-004A + demo-strategy docs on `cursor/ep004a-local-first-ci` (land when PO asks)
- macOS arm64 dogfood execution (checklist ready)
- Windows runtime verification (checklist ready; remains Experimental)

## Health

- Analyzer clean; 144 non-golden tests; 7 goldens; bridge npm check green
- No production `/copilot_internal`
- Showcase JSON validates (`metadata.json`, `demos.json`)
- Workflow YAML parses; Quality/Documentation/Maintenance are ubuntu-only

## Next gate

Update branch protection (remove `Build macOS`), land CI + demo contract on
`main`, dogfood macOS arm64, then Product Owner release call.
Targeted cleanup may follow as a separate narrow PR series.
