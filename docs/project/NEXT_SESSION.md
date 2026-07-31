# AI Tray — Next Session

**Updated:** 2026-07-31

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Verify required checks are `Format` | `Analyze` | `Test` | `Validate workflows`
   and that `Build macOS` is **not** required
   ([BRANCH_PROTECTION.md](../process/BRANCH_PROTECTION.md)).
4. Skim `docs/devops/DEMO_STRATEGY.md` (PD-025) and `AGENTS.md`.

## Current objective

Confirm branch protection matches EP-004A, complete macOS arm64 dogfood, then
consider Phase 3 release timing or targeted-cleanup import PRs. Finish docs
upgrade Phase 8 validation if still open.

## Prerequisites

- Stabilization merged to `main` (PR #9)
- EP-004A Quality CI + Release CD on `main` (PR #11)
- ADR-004 / PD-024: targeted cleanup, not full rewrite
- PD-023: no Cursor quota provider
- PD-025: product-as-demo (`demos.json` id `main`)
- Docs Master Prompt Phases 1–7 complete on `main`

## Blockers

- Windows Experimental until hardware checklist is completed
- Phase 3 still unpublished; release needs Product Owner timing
- GitHub branch protection may still list stale `Build macOS` until updated

## Recommended next task

1. Apply/verify branch protection ruleset
   ([`docs/process/github-ruleset-protect-main-branch.json`](../process/github-ruleset-protect-main-branch.json)).
2. Run [`docs/dogfood/POST_EP002_MACOS_ARM64.md`](../dogfood/POST_EP002_MACOS_ARM64.md).
3. If cleanup is approved: canonicalize imports to `core/` + `copilot/` only.
4. Do not add a Flutter Web playground; do not Melos-split for parity.

## Do not do next

- Cursor personal quota provider
- Provider-folder rewrite / refresh-cache-sidecar redesign
- Docs-only or governance-only release
- Flutter Web “demo” of the tray app
- Re-adding desktop builds to Quality CI

## Acceptance criteria

- Branch protection matches EP-004A required checks
- Showcase `demos.json` lists product `main` + DEMO_STRATEGY consistent with PD-025
- Handoff JSON/Markdown consistent
- No Cursor quota code
- Docs validation report present after Phase 8
