# AI Tray — Project State

**Updated:** 2026-07-31
**Current release:** v1.3.3 (`1.3.3+9`)
**Default branch:** `main`
**Active development branch:** `main`
**Current milestone:** EP-004A on main; docs upgrade Phases 1–8 complete; dogfood + release timing pending
**Overall progress:** EP-002 merged; Phase 3 not yet published

## Current status

Post-EP-002 stabilization is complete. **Quality CI + Release CD (EP-004A)**
is on `main` (PR #11; legacy `ci.yml` removed). Documentation upgrade Master
Prompt Phases 1–8 are on `main` (governance, contributor templates, process,
engineering standard, blueprint, Cursor rules, cleanup, validation).

**CI/CD strategy (Quality CI + Release CD):**
- Quality: PR/push → `main`, Ubuntu only (Format / Analyze / Test / Validate workflows)
- Documentation: docs/showcase/markdown paths, no Flutter
- Release CD: tag / `workflow_dispatch` only — sole owner of macOS/Windows builds
- Maintenance: weekly + dispatch outdated reports
See `docs/devops/LOCAL_DEVELOPMENT.md` and `docs/release/CI-CD.md`.

**Demo strategy (PD-025):** Product-as-demo via `showcase/demos.json` → `id: main`.
See `docs/devops/DEMO_STRATEGY.md`.

## Completed

- EP-002 Phase 3 merge (PR #7)
- EP-003 / EP-003A research + AI handoff package (PR #8)
- Stabilization baseline and P0 lifecycle fixes
- Sidecar/host protocol hardening + assembly smoke in Release
- EP-004 assessment recommending targeted cleanup
- EP-004A Quality CI + Release CD on `main` (PR #11)
- PD-025 product-as-demo + DEMO_STRATEGY
- Document Platform parity plan + Master Prompt Phases 1–8

## In progress

- GitHub branch protection alignment (drop `Build macOS` if still required)
- macOS arm64 dogfood execution
- Windows runtime verification (Experimental)

## Health

- Analyzer clean; 144 non-golden tests; 7 goldens; bridge npm check green
- No production `/copilot_internal`
- Showcase JSON validates
- Relative docs link audit clean after Phase 7 fixes

## Next gate

Confirm branch protection, dogfood macOS arm64, then Product Owner release call.
Targeted cleanup may follow as a separate narrow PR series.
