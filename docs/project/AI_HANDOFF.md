# AI Tray — AI Handoff

**Updated:** 2026-07-31  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion for AI-provider subscription usage
(Claude stable; Copilot experimental). EP-004A Quality CI + Release CD is on
`main`. **D-019** shared `scripts/` Local DX + Remote CI. **D-020** CHANGELOG
SoT + in-app release history. **PD-026 / D-021 / ADR-005** FlexColorScheme
personalization and **PD-027 / D-022** adaptive menu-bar density + template
glyph are on `feat/personalization-flex-theme`. Latest release v1.3.3.

## Current phase

- Product: Personalization + menu-bar UX on feature branch (pending PR)
- DevOps: branch protection confirm, macOS dogfood, PO release timing

## Repository state

- Branch: **`feat/personalization-flex-theme`**
- Showcase: `showcase/demos.json` → `id: main`
- Theme: `ai_tray/lib/theme/` · Tray density: `TrayDisplayMode`

## Completed this session

- ThemeFactory: full light/dark palettes + component themes from presets
- Appearance: expandable Theme / Font / App Icon + Menu Bar density settings
- Concise native tray dropdown (no emoji / ASCII meters)
- Adaptive / Always % / Icon-only title; threshold default 90%
- G1 solid template icon + dim opacity pulse while refreshing
- Tooltip always carries full usage

## Immediate next actions

1. Commit + open PR to `main`; wait for Quality CI
2. macOS dogfood: Appearance themes + Menu Bar density + template icon
3. Confirm branch protection (no `Build macOS`)

## Verification

```bash
cd ai_tray && flutter analyze --fatal-infos
flutter test test/unit/theme/ test/unit/tray/ test/widget/personalization_pickers_test.dart
```
