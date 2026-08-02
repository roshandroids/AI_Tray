# AI Tray — Roadmap

**Updated:** 2026-08-02

## Completed milestones

- PD-021 design system and provider platform
- EP-002 Copilot integration through Phase 3 (PR #7)
- EP-003 / EP-003A Cursor research (PD-023)
- Official `docs/project/` AI handoff package
- Post-EP-002 stabilization (lifecycle, races, sidecar, dogfood checklists)
- EP-004 assessment → **targeted cleanup** (ADR-004 / PD-024)
- EP-004A Quality CI + Release CD on `main` (PR #11; D-017)
- D-019 shared `scripts/` Local DX + Remote CI
- D-020 CHANGELOG SoT + in-app release history (`release_history.json`)
- PD-025 / D-016 demo strategy: product-as-demo (`demos.json` id `main`, desktop)
- Docs/engineering upgrade Master Prompt Phases 1–8 (D-018)
- PD-026 / ADR-005 FlexColorScheme personalization (PR #13, merged)
- PD-027 adaptive menu-bar density (PR #13, merged)
- D-023 CI migrated to `roshandroids/platform-ci@v1` reusable workflows (PR #14)
- **V2 Milestone 1 — Session Browser** (read-only session list + detail view,
  JSONL-sourced, no new database) (PR #14)
- **V2 Milestone 2 — Manual Resume + Resume Queue + Notifications**, all three
  epics complete: `NotificationGateway` migration, manual "Resume now" action,
  bounded/persisted Resume Queue with executor and click-to-resume completion
  notification (Feature 2.3.1) (PR #14 + follow-on commits)
- Resume Queue cancel/remove UI (backend `remove()` now reachable from the page)
- Session list ordering fix (most-recently-active first)

## Current milestone

**Release freeze — open-source readiness.** No new features; only
correctness, docs sync, release engineering, and OSS-scaffold work until the
repository is confidently publishable.

1. Finish documentation sync (this doc set + user guides + CHANGELOG).
2. Release-engineering audit: CI, dependency versions, dead code, TODOs.
3. Verify OSS scaffold (LICENSE/CONTRIBUTING/SECURITY/SUPPORT/templates).
4. Product Owner decides whether/when to flip the GitHub repo from private
   to public (not something to do silently as part of a docs pass).

## Upcoming (post-freeze)

- **V2 Milestone 3 — Resume Scheduler**: explicitly gated on real M2 usage
  evidence once public/dogfood users exist — not a timer, not started.
- Session Analytics — deferred to v3, not in current scope.
- Targeted cleanup: deprecate `domain/` and `data/copilot/` aliases; enrich
  capability/recovery/diagnostics metadata; single retry owner (PD-024, still
  open — see `docs/architecture/EP-004-provider-platform-assessment.md`)
- Signed/notarized macOS
- Windows hardware validation → exit Experimental only when checklist passes
- Full EP-004 rewrite remains a contingency only (see ADR-004 triggers)
- Future embeddable demo only if a real non-toy web-safe surface appears
  (append to `showcase/demos.json`; call reusable web-demo workflow)

## Product decision queue

- GitHub repo visibility (private → public) — Product Owner call, not
  automatic once the freeze checklist is done
- Cursor automation epic (non-quota) — optional, separate
- Whether to schedule the targeted-cleanup PR series (PD-024) before or after
  going public

## Exit criteria for the open-source release

- Docs (this file, `PROJECT_STATE.md`, `PRODUCT_STATE.md`,
  `ARCHITECTURE_STATE.md`, guides) match shipped code — no contradictions
- `CHANGELOG.md` `[Unreleased]` section reflects everything since v1.3.3
- Analyzer/tests/build green (macOS); Windows CI-buildable
- At least one recorded real-hardware dogfood pass per supported platform
- Explicit tag or manual dispatch only for release artifacts
- Showcase demo contract remains consistent with PD-025
