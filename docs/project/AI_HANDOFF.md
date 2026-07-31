# AI Tray — AI Handoff

**Updated:** 2026-07-31  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion for AI-provider subscription usage
(Claude stable; Copilot experimental). EP-004A Quality CI + Release CD is on
`main`. **D-019** shared `scripts/` Local DX + Remote CI. **D-020** CHANGELOG
SoT + in-app release history. **PD-026 / D-021 / ADR-005** FlexColorScheme
branded personalization (theme/font/icon presets) is on
`feat/personalization-flex-theme`. Latest release v1.3.3.

## Current phase

- Product: FlexColorScheme personalization (PD-026) implementation branch
- DevOps: branch protection confirm, macOS dogfood, PO release timing

## Repository state

- Branch: **`feat/personalization-flex-theme`** (personalization work)
- Showcase: `showcase/demos.json` → `id: main`
- Scripts: `./scripts/check.sh`, `./scripts/release.sh`, `./scripts/publish.sh`
- Theme module: `ai_tray/lib/theme/`

## Completed this session

- FlexColorScheme custom theme presets (Cursor default + 7 others)
- Bundled fonts (Inter, JetBrains Mono, Fira Code, IBM Plex Sans/Mono, Geist)
- App icon catalog + unsupported platform switcher
- PersonalizationController + Settings Appearance pickers
- Unit/widget/golden coverage updated

## Immediate next actions

1. Review/commit personalization branch; open PR to `main`
2. Confirm branch protection (no `Build macOS`)
3. macOS arm64 dogfood of Appearance settings

## Verification

```bash
cd ai_tray && flutter analyze --fatal-infos
flutter test test/unit/theme/ test/widget/personalization_pickers_test.dart
flutter test --tags golden
```
