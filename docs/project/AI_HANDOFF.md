# AI Tray — AI Handoff

**Updated:** 2026-07-31  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion for AI-provider subscription usage
(Claude stable; Copilot experimental). EP-004A Quality CI + Release CD is on
`main`. **D-019** shared `scripts/` Local DX + Remote CI (CI_MODE local-only).
**D-020** keeps `CHANGELOG.md` as release-notes SoT; publish syncs
`release_history.json` for Settings About / Diagnostics. Docs upgrade Phases
1–8 (D-018) landed. Demo strategy PD-025: product-as-demo. Latest release
v1.3.3 (Phase 3 not yet tagged).

## Current phase

- Product: in-app release history (D-020)
- DevOps: shared scripts Local DX + Remote CI (D-019)
- Next: branch protection confirm, macOS dogfood, PO release timing

## Repository state

- Branch: **`main`**
- Showcase: `showcase/demos.json` → `id: main`
- Scripts: `./scripts/check.sh`, `./scripts/release.sh`, `./scripts/publish.sh`
- Toolchain pins: `.ci/toolchain.env` (Local DX + Actions)
- Release notes SoT: `CHANGELOG.md` → `ai_tray/assets/release_history.json`

## Completed this session

- D-020 release notes SoT + in-app What’s New / history
- `sync_release_history.sh` wired into `publish.sh`
- Settings About + Diagnostics use `package_info_plus`

## Immediate next actions

1. Confirm branch protection (no `Build macOS`)
2. macOS arm64 dogfood
3. Commit D-019 shared-scripts work if still uncommitted (separate from D-020)

## Verification

```bash
./scripts/release/sync_release_history.sh
cd ai_tray && flutter test test/unit/release_history_test.dart \
  test/widget/about_settings_test.dart
./scripts/doctor.sh
./scripts/check.sh workflows
```
