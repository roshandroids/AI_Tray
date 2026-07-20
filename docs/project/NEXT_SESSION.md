# AI Tray — Next Session

**Updated:** 2026-07-19

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Confirm EP-004A Local First CI draft PR status and required check names.

## Current objective

Land EP-004A Local First CI, complete macOS arm64 dogfood, and only then
consider a Phase 3 release or targeted-cleanup import PRs.

## Prerequisites

- Stabilization merged to `main` (PR #9)
- ADR-004 / PD-024 understood: targeted cleanup, not full rewrite
- PD-023: no Cursor quota provider
- EP-004A: if branch protection/rulesets are added later, require
  `Format` | `Analyze` | `Test` | `Validate workflows`, never `Build macOS`

## Blockers

- Windows Experimental until hardware checklist is completed
- Phase 3 still unpublished; release needs Product Owner timing

## Recommended next task

1. Review and merge the EP-004A draft PR; confirm Quality checks on the PR.
2. Run [`docs/dogfood/POST_EP002_MACOS_ARM64.md`](../dogfood/POST_EP002_MACOS_ARM64.md).
3. If cleanup is approved: canonicalize imports to `core/` + `copilot/` only.
4. Do not start a full EP-004 rewrite.

## Do not do next

- Cursor personal quota provider
- Provider-folder rewrite / refresh-cache-sidecar redesign
- Docs-only or governance-only release

## Acceptance criteria

- EP-004A CI changes merged
- macOS dogfood results recorded
- Handoff JSON/Markdown consistent
- No Cursor quota code
