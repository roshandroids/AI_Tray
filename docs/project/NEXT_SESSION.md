# AI Tray — Next Session

**Updated:** 2026-07-19

## Start here

1. Read `AI_HANDOFF.md`.
2. Parse `PROJECT_CONTEXT.json`.
3. Run:

```bash
git status --short
git branch --show-current
git log -5 --oneline
```

4. Confirm `main` includes PR #7 (`2885980`) before starting stabilization code.

## Current objective

Land EP-003 / EP-003A / AI handoff documentation, then run the post-EP-002
stabilization sprint and produce an EP-004 go/no-go assessment. No Cursor
provider implementation. No provider-folder rewrite until the assessment lands.

## Prerequisites

- Merged `origin/main` at or after `2885980`
- Docs branch `cursor/ep003-handoff-docs` or equivalent for research/handoff
- EP-002 verification baseline available (analyzer, 132 tests, 7 goldens)
- Product decision PD-023 understood: no Cursor personal quota implementation

## Blockers

- Phase 3 is merged but not published; release timing is a Product Owner call.
- Windows runtime validation requires a Windows host; keep Experimental until
  verified.
- Full EP-004 rewrite is blocked pending stabilization evidence.

## Recommended next task

1. Finish/merge the documentation PR if still open.
2. Create `cursor/post-ep002-stabilization` from merged `main`.
3. Re-run Flutter and bridge baselines; record a stabilization report.
4. Add lifecycle/refresh/sidecar race and failure tests; fix proven defects only.
5. Write EP-004 assessment + ADR with no-go / targeted cleanup / full-epic
   recommendation.

## Do not do next

- Do not implement a Cursor quota provider.
- Do not rerun agent-prompt `/usage` probes unless new official evidence
  justifies additional quota consumption.
- Do not use undocumented provider endpoints or scrape dashboards.
- Do not rewrite provider folders before the EP-004 assessment decision.
- Do not publish a release solely for documentation/CI metadata changes.

## Acceptance criteria

- Docs/handoff/CI-CD state matches merged main and current branch.
- Stabilization baselines are recorded with P0/P1 classification.
- Lifecycle/race/sidecar tests cover cold start, switch-during-refresh,
  cache failure, and protocol failure paths.
- EP-004 decision is written with evidence and recorded in `DECISION_LOG.md`.
- `PROJECT_CONTEXT.json` parses and matches the Markdown state.
- No Cursor quota provider code is introduced.

## Handoff completion rule

Before ending any future epic/phase/major feature/release session, update all
affected `docs/project/` files and keep `PROJECT_CONTEXT.json` valid.
