# AI Tray — Project State

**Updated:** 2026-08-02
**Current release:** v1.3.3 (`1.3.3+9`) — pending a new tag; substantial work has landed on `main` since this tag
**Default branch:** `main`
**Active development branch:** `main` (no feature branch in flight)
**Current milestone:** Release freeze — open-source readiness (see `ROADMAP.md`)
**Overall progress:** EP-002 merged and published; PD-026/027 personalization merged; V2 Milestone 1 (Session Browser) and Milestone 2 (Manual Resume + Resume Queue + Notifications, all 3 epics) merged; V2 Milestone 3 (Resume Scheduler) intentionally not started (gated on real usage evidence)

## Current status

Post-EP-002 stabilization is complete. **Quality CI + Release CD (EP-004A)**
is on `main`, and CI has since migrated to reusable workflows from
**`roshandroids/platform-ci@v1`** (D-023, PR #14) — `.github/workflows/*.yml`
are now thin callers into that external repo rather than invoking
`./scripts/*.sh` directly from Actions; the `scripts/` tree (and its
`scripts/ci/` implementation) remains the local-dev entrypoint and is what
`ci.yaml` tells `platform-ci` to run. **PD-026 / ADR-005** branded
personalization (themes, fonts, app icons) and **PD-027** adaptive menu-bar
density are merged and shipped, not pending.

**V2 (session management) is substantially shipped**, not merely planned:
Session Browser, Session Detail, manual "Resume now", the bounded/persisted
Resume Queue with its executor, `NotificationGateway`, and the queue's
click-to-resume completion notification (Feature 2.3.1) are all implemented,
tested, and on `main`. See `docs/planning/v2-implementation-log.md` for the
story-by-story record and `docs/planning/v2-vision-and-roadmap.md` for the
locked scope. Milestone 3 (Resume Scheduler) and Session Analytics remain
explicitly out of scope until real usage data justifies them.

**CI/CD strategy (Quality CI + Release CD via platform-ci / D-023):**
- Quality: PR/push → `main`, Ubuntu only — `platform-ci`'s quality job, configured by `ci.yaml`
- Documentation: docs/showcase/markdown paths, no Flutter
- Release PR: quality + macOS/Windows build fires only when the PR head branch starts with `release/`
- Release CD: tag / `workflow_dispatch` only — `platform-ci`'s build+package+publish job
- Local DX: `scripts/*.sh` thin wrappers over `scripts/ci/*.sh` (same scripts `platform-ci` calls)
- Maintenance: weekly + dispatch outdated reports (informational only)
See `docs/devops/LOCAL_DEVELOPMENT.md` and `docs/release/CI-CD.md`.

**Demo strategy (PD-025):** Product-as-demo via `showcase/demos.json` → `id: main`.
See `docs/devops/DEMO_STRATEGY.md`.

## Completed

- EP-002 Phase 3 merge (PR #7)
- EP-003 / EP-003A research + AI handoff package (PR #8)
- Stabilization baseline and P0 lifecycle fixes
- Sidecar/host protocol hardening + assembly smoke in Release
- EP-004 assessment recommending targeted cleanup
- EP-004A Quality CI + Release CD on `main` (PR #11)
- PD-025 product-as-demo + DEMO_STRATEGY
- Document Platform parity plan + Master Prompt Phases 1–8
- D-019 shared `scripts/` Local DX + Remote CI (thin Actions orchestration)
- D-020 CHANGELOG SoT + generated `release_history.json` + in-app About/history
- PD-026 FlexColorScheme personalization (PR #13, merged)
- PD-027 adaptive menu-bar density (PR #13, merged)
- D-023 CI migration to `platform-ci@v1` reusable workflows (PR #14)
- V2 Milestone 1: Session Browser + Session Detail (PR #14)
- V2 Milestone 2: NotificationGateway migration, manual resume, Resume Queue
  incl. click-to-resume completion notification (PR #14 + follow-on commits)
- Resume Queue cancel/remove UI wired to the already-tested repository method
- Session list ordering fix (most-recently-active first)
- App Sandbox disabled on macOS (see `Runner/Release.entitlements` for the
  documented rationale) with `package_info_plus` pod resolution synced

## In progress — release freeze

- Documentation sync across `docs/project/*`, user guides, `CHANGELOG.md`
- Release-engineering audit (CI, dependency versions, dead code, TODOs)
- OSS scaffold verification (LICENSE/CONTRIBUTING/SECURITY/SUPPORT/templates)
- macOS arm64 + Windows x64 dogfood execution (no real-hardware pass recorded yet)
- Signed/notarized macOS build (still unsigned)
- Repo-visibility decision (private → public) — pending Product Owner call

## Health

- Analyzer clean; `flutter test --exclude-tags golden,screenshot` green (365 tests)
- macOS debug build verified to compile with current entitlements/pod state
- No production `/copilot_internal`
- Showcase JSON validates
- Relative docs link audit clean after Phase 7 fixes; this session's doc sync
  addresses drift introduced by the personalization + V2 merges since

## Next gate

Complete the release-freeze checklist in `ROADMAP.md`, then Product Owner
decides on repo visibility and release tag timing. Targeted cleanup (PD-024)
may follow as a separate narrow PR series after going public.
