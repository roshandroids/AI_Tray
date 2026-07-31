# AI Tray — Roadmap

**Updated:** 2026-07-31

## Completed milestones

- PD-021 design system and provider platform
- EP-002 Copilot integration through Phase 3 (PR #7)
- EP-003 / EP-003A Cursor research (PD-023)
- Official `docs/project/` AI handoff package
- Post-EP-002 stabilization (lifecycle, races, sidecar, dogfood checklists)
- EP-004 assessment → **targeted cleanup** (ADR-004 / PD-024)
- EP-004A Quality CI + Release CD (no PR desktop; ubuntu guardrail; D-017)
- PD-025 / D-016 demo strategy: product-as-demo (`demos.json` id `main`, desktop)

## Current milestone

1. Merge EP-004A to `main`; update branch protection (drop `Build macOS`).
2. Execute macOS arm64 dogfood checklist.
3. Product Owner decides whether/when to publish a release including Phase 3.
4. Optional: begin targeted-cleanup import canonicalization.

## Upcoming

- Targeted cleanup: deprecate `domain/` and `data/copilot/` aliases; enrich
  capability/recovery/diagnostics metadata; single retry owner
- Signed/notarized macOS
- Windows hardware validation → exit Experimental only when checklist passes
- Full EP-004 rewrite remains a contingency only (see ADR-004 triggers)
- Future embeddable demo only if a real non-toy web-safe surface appears
  (append to `showcase/demos.json`; call reusable web-demo workflow)

## Product decision queue

- Cursor automation epic (non-quota) — optional, separate
- Phase 3 release timing
- Whether to schedule the targeted-cleanup PR series immediately after dogfood

## Exit criteria for the next release

- Stabilization / EP-004A merged
- macOS dogfood recorded
- Analyzer/tests/sidecar checks green
- Changelog matches shipped behavior
- Explicit tag or manual dispatch only
- Showcase demo contract remains consistent with PD-025
