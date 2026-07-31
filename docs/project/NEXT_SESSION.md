# AI Tray — Next Session

**Updated:** 2026-07-31

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Work lives on `feat/personalization-flex-theme` (PD-026 + PD-027).

## Current objective

Land personalization + adaptive menu-bar UX via PR, dogfood on macOS, then
resume branch-protection / Phase 3 release timing.

## Prerequisites

- EP-004A, D-019 / D-020 on `main`
- PD-026 / PD-027 implementation on `feat/personalization-flex-theme`

## Recommended next task

1. Commit intentional Dart + tray assets + docs; open PR.
2. Quality CI green; merge.
3. Dogfood: theme switch (light/dark per preset), Menu Bar Adaptive/Always/Icon
   only, template icon + refresh pulse, concise tray menu.

## Acceptance criteria

- Adaptive default: no title under threshold; `93%` at ≥ 90%
- Tooltip always includes session/week/status
- Refresh pulses template opacity (no usage ring in icon)
- Appearance accordion + Menu Bar settings persist (`settings_v1_tray*`)
- Analyzer clean; theme + tray unit tests green
