# AI Tray — Roadmap

**Updated:** 2026-07-19

## Completed milestones

- PD-021 design system and provider platform
- EP-002 Copilot integration through Phase 3 (PR #7)
- EP-003 / EP-003A Cursor research (PD-023)
- Official `docs/project/` AI handoff package
- Post-EP-002 stabilization (lifecycle, races, sidecar, dogfood checklists)
- EP-004 assessment → **targeted cleanup** (ADR-004 / PD-024)
- EP-004A Local First CI (quality/docs/release/maintenance; no PR desktop builds)

## Current milestone

1. Land EP-004A CI changes; update branch protection (drop `Build macOS`).
2. Merge stabilization PR.
3. Execute macOS arm64 dogfood checklist.
4. Product Owner decides whether/when to publish a release including Phase 3.
5. Optional: begin targeted-cleanup import canonicalization.

## Upcoming

- Targeted cleanup: deprecate `domain/` and `data/copilot/` aliases; enrich
  capability/recovery/diagnostics metadata; single retry owner
- Signed/notarized macOS
- Windows hardware validation → exit Experimental only when checklist passes
- Full EP-004 rewrite remains a contingency only (see ADR-004 triggers)

## Product decision queue

- Cursor automation epic (non-quota) — optional, separate
- Phase 3 release timing
- Whether to schedule the targeted-cleanup PR series immediately after dogfood

## Exit criteria for the next release

- Stabilization merged
- macOS dogfood recorded
- Analyzer/tests/sidecar checks green
- Changelog matches shipped behavior
- Explicit tag or manual dispatch only
