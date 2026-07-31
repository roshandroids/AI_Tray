# AI Tray — Project State

**Updated:** 2026-07-31
**Current release:** v1.3.3 (`1.3.3+9`)
**Default branch:** `main`
**Active development branch:** `feat/personalization-flex-theme`
**Current milestone:** PD-026 FlexColorScheme personalization on feature branch; dogfood + release timing pending
**Overall progress:** EP-002 merged; Phase 3 not yet published

## Current status

Post-EP-002 stabilization is complete. **Quality CI + Release CD (EP-004A)**
is on `main` (PR #11). Documentation upgrade Master Prompt Phases 1–8 are on
`main`. **PD-026 / ADR-005** branded personalization (themes, fonts, app icons)
is implemented on `feat/personalization-flex-theme`.

**CI/CD strategy (Quality CI + Release CD + shared scripts / D-019):**
- Quality: PR/push → `main`, Ubuntu only — invokes `./scripts/format|analyze|test|check`
- Documentation: docs/showcase/markdown paths, no Flutter
- Release CD: tag / `workflow_dispatch` only — `./scripts/build.sh` + `package.sh`
- Local DX: same `scripts/` surface; `.ci/config` `CI_MODE` is preference only (Actions ignores it)
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
- D-019 shared `scripts/` Local DX + Remote CI (thin Actions orchestration)
- D-020 CHANGELOG SoT + generated `release_history.json` + in-app About/history
- PD-026 FlexColorScheme personalization (feature branch; pending PR)

## In progress

- PR for `feat/personalization-flex-theme`
- GitHub branch protection alignment (drop `Build macOS` if still required)
- macOS arm64 dogfood execution
- Windows runtime verification (Experimental)

## Health

- Analyzer clean; theme personalization unit/widget tests + goldens updated
- No production `/copilot_internal`
- Showcase JSON validates
- Relative docs link audit clean after Phase 7 fixes

## Next gate

Confirm branch protection, dogfood macOS arm64, then Product Owner release call.
Targeted cleanup may follow as a separate narrow PR series.
