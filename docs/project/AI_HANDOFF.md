# AI Tray — AI Handoff

**Updated:** 2026-07-31  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion that shows AI-provider subscription
usage and health in one shared macOS menu-bar / Windows tray experience.
Claude is stable; GitHub Copilot is experimental through the official SDK.
EP-002 Phase 3 is merged (`2885980`). Post-EP-002 stabilization completed;
EP-004 posture is **targeted cleanup** (ADR-004 / PD-024). **CI/CD model is
Quality CI + Release CD (EP-004A)** and is on `main` (`ci.yml` removed;
Lefthook optional). **Demo strategy (PD-025):** product-as-demo
(`showcase/demos.json` → `id: main`). Cursor personal quota remains blocked
(PD-023). Documentation upgrade Master Prompt Phases 1–7 landed on `main`
(governance, contributor templates, process pack, engineering standard,
blueprint, pruned Cursor rules, cleanup). Latest published release remains
v1.3.3 (Phase 3 not yet tagged).

## Current phase

- Completed: **EP-002**, **post-EP-002 stabilization**, **EP-004A on main**,
  **docs upgrade Phases 1–7**
- Architecture posture: **EP-004 targeted cleanup** (not full rewrite)
- Showcase: **product-as-demo** (`demos.json` → `main` desktop)
- Research: **EP-003 / EP-003A** complete; no Cursor production code
- Current objective: confirm GitHub branch protection (no `Build macOS`),
  macOS arm64 dogfood, then Product Owner release timing; finish docs
  Phase 8 validation

## Repository state

- Current release: **v1.3.3** (`1.3.3+9`)
- Active branch: **`main`** (EP-004A merged via PR #11)
- Showcase contract: `showcase/metadata.json` + `showcase/demos.json`
- Agent entry: root `AGENTS.md` · Blueprint: `docs/PROJECT_BLUEPRINT.md`

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

- Documentation upgrade Master Prompt Phases 1–7 (governance through cleanup)
- Prior: Quality CI + Release CD on `main`, DEMO_STRATEGY / PD-025

## Immediate next actions

1. Confirm GitHub branch protection: drop required `Build macOS`; keep
   Format / Analyze / Test / Validate workflows
   (`docs/process/BRANCH_PROTECTION.md`).
2. Finish Master Prompt Phase 8 validation report if not yet committed.
3. Execute macOS arm64 dogfood checklist.
4. Optional: targeted-cleanup import canonicalization (ADR-004).

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
Engineering: `docs/ENGINEERING_STANDARD.md`.

Last recorded: analyzer clean, **144** non-golden, **7** golden, bridge 16 pass / 1 skip.
