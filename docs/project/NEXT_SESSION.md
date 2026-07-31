# AI Tray — Next Session

**Updated:** 2026-07-31

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Personalization lives on `feat/personalization-flex-theme` (PD-026 / ADR-005).
4. Confirm branch protection: required checks `Format` | `Analyze` | `Test` |
   `Validate workflows` (never `Build macOS`).

## Current objective

Land FlexColorScheme personalization via PR, dogfood Appearance settings on
macOS, then resume branch-protection / Phase 3 release timing.

## Prerequisites

- EP-004A on `main`
- D-019 / D-020 on `main`
- PD-026 implementation on `feat/personalization-flex-theme`

## Recommended next task

1. Commit personalization (Dart + bundled fonts/icons + docs/ADR).
2. Open PR; wait for Quality CI; merge.
3. Dogfood: Settings → Appearance (theme mode, preset, font, disabled icon).
4. Leave unrelated sessions WIP separate if still present.

## Acceptance criteria

- Appearance changes apply without restart
- Prefs restore after relaunch (`settings_v1_themePreset|fontPreset|appIconPreset`)
- App icon picker disabled with platform explanation on desktop
- Analyzer clean; theme unit/widget tests + goldens green
- Handoff records PD-026 / D-021 / ADR-005
