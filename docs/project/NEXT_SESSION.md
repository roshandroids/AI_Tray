# AI Tray — Next Session

**Updated:** 2026-07-19

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Confirm stabilization PR state and whether PR #8 docs already merged.

## Current objective

Land the post-EP-002 stabilization branch, complete macOS arm64 dogfood, and
only then consider a Phase 3 release or targeted-cleanup import PRs.

## Prerequisites

- Stabilization branch green locally (format/analyze/144 tests/goldens/bridge)
- ADR-004 / PD-024 understood: targeted cleanup, not full rewrite
- PD-023: no Cursor quota provider

## Blockers

- Windows Experimental until hardware checklist is completed
- Phase 3 still unpublished; release needs Product Owner timing

## Recommended next task

1. Merge/stabilize PR checks.
2. Run [`docs/dogfood/POST_EP002_MACOS_ARM64.md`](../dogfood/POST_EP002_MACOS_ARM64.md).
3. If cleanup is approved: canonicalize imports to `core/` + `copilot/` only.
4. Do not start a full EP-004 rewrite.

## Do not do next

- Cursor personal quota provider
- Provider-folder rewrite / refresh-cache-sidecar redesign
- Docs-only or governance-only release

## Acceptance criteria

- Stabilization changes merged or clearly blocked
- macOS dogfood results recorded
- Handoff JSON/Markdown consistent
- No Cursor quota code
