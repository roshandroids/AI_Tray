# AI Tray — Next Session

**Updated:** 2026-07-31

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Run `./scripts/doctor.sh` and skim `docs/devops/LOCAL_DEVELOPMENT.md` (D-019).
4. Confirm branch protection: ruleset **Protect main (require PR)** active;
   required checks `Format` | `Analyze` | `Test` | `Validate workflows`
   (never `Build macOS`). Never push directly to `main` — always PR → merge.

## Current objective

Verify D-020 in-app release history on a dogfood build, confirm branch
protection, land any remaining D-019 shared-scripts commit, then Phase 3
release timing or targeted cleanup.

## Prerequisites

- EP-004A on `main` (PR #11)
- D-019 shared scripts (Local DX + Remote CI; CI_MODE ignored by Actions)
- D-020 CHANGELOG SoT + `release_history.json` + Settings About
- PD-025 product-as-demo

## Recommended next task

1. Commit D-020 release-notes work (and D-019 CI scripts if still uncommitted).
2. Apply/verify branch protection ruleset.
3. `./scripts/release.sh --local-only` for dogfood; open Settings → About.
4. Do not re-add desktop builds to Quality CI.
5. Never hand-edit `ai_tray/assets/release_history.json`.

## Acceptance criteria

- Settings About shows live version/build and What’s New from history asset
- Diagnostics App version matches PackageInfo (not hardcoded)
- `./scripts/check.sh workflows` passes
- No CI_MODE conditionals in workflow YAML
- Handoff consistent (D-020 recorded)
