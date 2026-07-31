# AI Tray — AI Handoff

**Updated:** 2026-07-31  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion that shows AI-provider subscription
usage and health in one shared macOS menu-bar / Windows tray experience.
Claude is stable; GitHub Copilot is experimental through the official SDK.
EP-002 Phase 3 is merged (`2885980`). Post-EP-002 stabilization completed;
EP-004 posture is **targeted cleanup** (ADR-004 / PD-024). **CI/CD model is
Quality CI + Release CD (EP-004A):** Ubuntu-only Quality on PR/push; desktop
(macOS/Windows) builds **only** in Release on tag/`workflow_dispatch`;
`ci.yml` removed; Lefthook optional locally. **Demo strategy (PD-025):** the
product is the demo (`showcase/demos.json` → `id: main`, `type: desktop`);
no Flutter Web playground. Cursor personal quota remains blocked (PD-023).
Latest published release remains v1.3.3 (Phase 3 not yet tagged).

## Current phase

- Completed: **EP-002** (all phases) and **post-EP-002 stabilization**
- Architecture posture: **EP-004 targeted cleanup** (not full rewrite)
- DevOps: **Quality CI + Release CD** (EP-004A) — hardened; awaiting merge to `main`
- Showcase: **product-as-demo** (`demos.json` → `main` desktop)
- Research: **EP-003 / EP-003A** complete; no Cursor production code
- Current objective: land CI branch on `main`, update branch protection, dogfood,
  then Product Owner release timing

## Repository state

- Current release: **v1.3.3** (`1.3.3+9`)
- Main: still has legacy `ci.yml` with PR macOS builds until EP-004A merges
- Active branch: `cursor/ep004a-local-first-ci` (upstream may be gone —
  verify with `git status` / `git branch -vv`)
- Showcase contract: `showcase/metadata.json` + `showcase/demos.json`

Always re-run `git status` before changing anything.

## Product state

- **Claude Code:** stable CLI usage + LKG cache
- **GitHub Copilot:** experimental SDK sidecar + quota RPC
- **Cursor Agent:** research only (PD-023)
- Artifacts: macOS arm64 + Windows x64 only (Release CD only)
- **Public demo:** Product desktop app via GitHub Releases (`demos.json` id `main`)

## Architecture invariants

1. Feature-first Clean Architecture: UI → State → Domain → Data.
2. Riverpod Notifier / AsyncNotifier / AsyncValue.
3. UI never calls external APIs/CLIs/SDKs directly.
4. DTOs mapped to app-owned domain models before UI.
5. `ProviderRegistry` + capability-driven shared UI.
6. Provider-scoped single-flight refresh, bounded retry, LKG cache, stale rejection.
7. Never invent usage values; label stale data.
8. No `/copilot_internal`, undocumented APIs, or scraping.

## Completed this session

- Hardened Quality CI + Release CD workflow headers and policy comments
- Added Ubuntu-only guardrail in Quality `Validate workflows` job
- Documentation path filter includes `showcase/**`
- Synced `docs/release/CI-CD.md` + `docs/devops/LOCAL_DEVELOPMENT.md`

## Immediate next actions

1. Update GitHub branch protection: drop required `Build macOS`; keep
   Format / Analyze / Test / Validate workflows.
2. Land/merge EP-004A CI branch onto `main` (deletes legacy `ci.yml`).
3. Execute macOS arm64 dogfood checklist.
4. Optional: start targeted-cleanup import canonicalization (no rewrite).

## Verification baseline

```bash
cd ai_tray
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot
flutter test --tags golden
cd tool/copilot_sdk_bridge && npm run check
```

Quality CI + Release CD / Lefthook: `docs/devops/LOCAL_DEVELOPMENT.md`.  
Demo strategy: `docs/devops/DEMO_STRATEGY.md`.

Last recorded: analyzer clean, **144** non-golden, **7** golden, bridge 16 pass / 1 skip.
