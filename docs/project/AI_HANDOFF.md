# AI Tray — AI Handoff

**Updated:** 2026-07-19  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion that shows AI-provider subscription
usage and health in one shared macOS menu-bar / Windows tray experience.
Claude is stable; GitHub Copilot is experimental through the official SDK.
EP-002 Phase 3 is merged (`2885980`). Post-EP-002 stabilization completed on
`cursor/post-ep002-stabilization`: lifecycle/race fixes, sidecar protocol
hardening, dogfood checklists, and an EP-004 assessment recommending
**targeted cleanup** (ADR-004 / PD-024). Cursor personal quota remains blocked
(PD-023). Latest published release remains v1.3.3 (Phase 3 not yet tagged).

## Current phase

- Completed: **EP-002** (all phases) and **post-EP-002 stabilization**
- Architecture posture: **EP-004 targeted cleanup** (not full rewrite)
- Research: **EP-003 / EP-003A** complete; no Cursor production code
- Current objective: land stabilization PR, run macOS dogfood, then optional
  targeted-cleanup chores; Product Owner decides release timing for Phase 3

## Repository state

- Current release: **v1.3.3** (`1.3.3+9`)
- Main: `2885980` (merge of PR #7); docs PR #8 may already be merged or open
- Active branch: `cursor/post-ep002-stabilization`
- Related: [#8 docs handoff](https://github.com/roshandroids/AI_Tray/pull/8)

Always re-run `git status` before changing anything.

## Product state

- **Claude Code:** stable CLI usage + LKG cache
- **GitHub Copilot:** experimental SDK sidecar + quota RPC
- **Cursor Agent:** research only (PD-023)
- Artifacts: macOS arm64 + Windows x64 only

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

- EP-002 docs closeout + EP-003/EP-003A/handoff on docs branch (PR #8)
- Stabilization baseline: format/analyze/144 non-golden/7 golden/bridge check
- Lifecycle fixes: dispose safety, ABA stale rejection, provider-scoped backoff,
  cache-write logging, resume overdue hook
- Sidecar protocol tests + CI/Release `smoke_protocol.mjs`
- macOS/Windows dogfood checklists; Windows remains Experimental
- EP-004 assessment + ADR-004: targeted cleanup

## Immediate next actions

1. Merge stabilization PR after checks.
2. Execute macOS arm64 dogfood checklist.
3. Product Owner: release decision for Phase 3 (explicit tag/dispatch only).
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

Last recorded: analyzer clean, **144** non-golden, **7** golden, bridge 16 pass / 1 skip.
