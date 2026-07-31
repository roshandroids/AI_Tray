# AI Tray — Next Session

**Updated:** 2026-07-31

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Confirm EP-004A Quality CI + Release CD is merged (or open a PR); verify
   required checks are `Format` | `Analyze` | `Test` | `Validate workflows`
   and that `Build macOS` is **not** required.
4. Skim `docs/devops/DEMO_STRATEGY.md` (PD-025) — product is the demo.

## Current objective

Land Quality CI + Release CD on `main`, complete macOS arm64 dogfood, then
consider Phase 3 release timing or targeted-cleanup import PRs.

## Prerequisites

- Stabilization merged to `main` (PR #9)
- ADR-004 / PD-024: targeted cleanup, not full rewrite
- PD-023: no Cursor quota provider
- PD-025: product-as-demo (`demos.json` id `main`)
- EP-004A: require `Format` | `Analyze` | `Test` | `Validate workflows`;
  never `Build macOS`

## Blockers

- Windows Experimental until hardware checklist is completed
- Phase 3 still unpublished; release needs Product Owner timing
- Until EP-004A merges, `main` still runs legacy PR macOS builds

## Recommended next task

1. Push/open PR for `cursor/ep004a-local-first-ci` if needed; merge after Quality green.
2. Update branch protection (drop `Build macOS`).
3. Run [`docs/dogfood/POST_EP002_MACOS_ARM64.md`](../dogfood/POST_EP002_MACOS_ARM64.md).
4. If cleanup is approved: canonicalize imports to `core/` + `copilot/` only.
5. If PO wants docs parity: start Phase 1 only from
   [`docs/reports/v2-refactor-plan.md`](../reports/v2-refactor-plan.md).
6. Do not add a Flutter Web playground for AI Tray; do not Melos-split for parity.

## Do not do next

- Cursor personal quota provider
- Provider-folder rewrite / refresh-cache-sidecar redesign
- Docs-only or governance-only release
- Flutter Web “demo” of the tray app
- Re-adding desktop builds to Quality CI

## Acceptance criteria

- EP-004A merged; `ci.yml` gone from `main`
- Normal PRs run Ubuntu Quality only (no macOS/Windows jobs)
- Showcase `demos.json` lists product `main` + DEMO_STRATEGY consistent with PD-025
- Handoff JSON/Markdown consistent
- No Cursor quota code
