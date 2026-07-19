# AI Tray — AI Handoff

**Updated:** 2026-07-19  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion that shows AI-provider subscription
usage and health in one shared macOS menu-bar / Windows tray experience.
Claude is stable; GitHub Copilot is experimental through the official SDK.
EP-002 Phase 3 is **merged to main** via PR #7 (`2885980`). Phase 3 is not yet
in a published release (latest tag remains v1.3.3).
EP-003 / EP-003A Cursor research is complete: do not implement personal quota
monitoring without an official consumer usage API (PD-023).
Current work: documentation PR for research/handoff, then post-EP-002
stabilization and an EP-004 go/no-go assessment.

## Current phase

- Completed epic: **EP-002 — GitHub Copilot Provider Integration** (all phases)
- Current milestone: **Post-EP-002 stabilization + EP-004 decision**
- Research track: **EP-003 / EP-003A complete; no production Cursor code**
- Current objective: land docs/handoff on main, then harden lifecycle/sidecar
  and decide whether EP-004 is no-go, targeted cleanup, or a full epic

## Repository state

- Current release: **v1.3.3** (`ai_tray/pubspec.yaml`: `1.3.3+9`)
- Main: `2885980` (merge of PR #7)
- Active branch: `cursor/ep003-handoff-docs` (from `origin/main`)
- Merged PR: [#7 — EP-002 Phase 3 UI integration](https://github.com/roshandroids/AI_Tray/pull/7)
- Docs in flight: EP-003, EP-003A, `docs/project/`, governance rule, CI-CD fix

Always re-run `git status`, inspect the active branch, and verify PR state
before changing anything; this snapshot may be older than the working tree.

## Product state

- **Claude Code:** stable provider using
  `claude -p /usage --output-format json`; free-text result is parsed
  defensively and backed by LKG cache.
- **GitHub Copilot:** integrated provider using a bundled Node sidecar and
  official `@github/copilot-sdk`; `account.getQuota({})` is experimental.
- **Cursor Agent:** research only. Supported for automation, but not eligible as
  a personal quota provider because no official remaining/reset API exists.
- Shared UI: provider selector, dashboard, rings, settings, diagnostics, logs,
  tray status, loading/error/empty states, light/dark themes.
- Release artifacts: macOS arm64 and Windows x64. No macOS Intel artifact.

## Architecture invariants

1. Feature-first Clean Architecture: UI → State → Domain → Data.
2. Riverpod `Notifier` / `AsyncNotifier` / `AsyncValue`; no business logic in UI.
3. UI never calls external APIs/CLIs/SDKs directly.
4. Provider SDK/CLI DTOs are mapped to app-owned domain models before UI.
5. `ProviderRegistry` is the catalog; shared UI is capability-driven.
6. Refreshes are provider-scoped, single-flight, bounded, race-safe, and cache
   last-known-good data.
7. Never invent usage values. Stale values must be labeled.
8. Do not use `/copilot_internal`, undocumented APIs, or dashboard scraping.

## Completed work

- PD-021 design system and shared provider architecture
- EP-002 Copilot POC, SDK/adapter/domain/provider layers, distribution, shared UI
- EP-002 Phase 3 accessibility, state, golden, screenshot, and docs work
- PR #7 merged to main (`2885980`)
- v1.3.3 Claude parser fix for session lines without reset suffix
- CI: PRs run format/analyze/test/macOS build; pushes to main skip build
- Releases: explicit version tag or manual dispatch only
- EP-003 Cursor Agent supported-interface research; no production code
- EP-003A seven-command print-mode `/usage` verification; no quota payload found
- PD-023 approved: Cursor is not a personal quota provider; automation requires
  a separate future epic

## Current risks / debt

- Copilot quota RPC can change without notice.
- Claude `/usage` is not a stable public schema.
- Copilot sidecar packaging is a release dependency.
- macOS is unsigned/not notarized; sandbox disabled for required subprocesses.
- Windows remains experimental; sleep/wake behavior still needs dogfooding.
- Provider folders contain transitional compatibility paths; avoid broad moves.
- Dependency/docs migration status for `local_notifier` must be re-verified
  before claiming notification migration complete.
- Cursor unknown prompts such as `/usage` can consume quota despite exit code 0;
  never use agent-generated prose as a machine contract.
- Phase 3 UX is on main but not yet published in a GitHub Release.

## Immediate next actions

1. Finish this documentation branch/PR (EP-003, EP-003A, handoff, CI-CD sync).
2. Create a stabilization branch from merged main.
3. Run Flutter/bridge baselines and harden lifecycle, refresh races, and sidecar
   protocol coverage.
4. Produce EP-004 architecture assessment with no-go / targeted cleanup /
   full-epic recommendation. Do not implement EP-004 until that decision lands.

## Verification baseline

From `ai_tray/`:

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot
flutter test --tags golden
git diff --check
```

For EP-002 Phase 3, the last recorded results were analyzer clean, 132
non-golden tests, 7 golden tests, screenshot generation passing, and no
production `/copilot_internal`.

## Maintenance protocol

When an epic, phase, major feature, release, or architecture decision completes:

1. Update the relevant files under `docs/project/`.
2. Summarize outcomes; never paste commit logs.
3. Keep versions, branches, risks, decisions, roadmap, and JSON consistent.
4. Set the same `updated_at` date in this package where practical.
5. Validate `PROJECT_CONTEXT.json` and check all internal links.
