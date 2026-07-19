# AI Tray — Roadmap

**Updated:** 2026-07-19

## Completed milestones

- PD-021 design system and provider platform
- EP-002 Copilot SDK/provider foundation and distribution
- EP-002 Phase 3 shared UI, accessibility, screenshots, and documentation
- PR #7 merged to main (`2885980`)
- v1.3.3 Claude parser resilience fix and release pipeline corrections
- EP-003 Cursor Agent research and PD-023 decision
- EP-003A Cursor Agent non-interactive `/usage` verification

## Current milestone — docs closeout + post-EP-002 stabilization

1. Land EP-003 / EP-003A / AI handoff / CI-CD documentation on main.
2. Create a stabilization branch from merged main (no new product features).
3. Re-run Flutter and Node sidecar baselines; classify P0/P1 defects.
4. Harden lifecycle, refresh races, cache failure, provider switching, and
   sidecar protocol coverage; fix only proven defects.
5. Document macOS arm64 dogfood and Windows x64 runtime checklist.
6. Produce EP-004 assessment + ADR with no-go / targeted cleanup / full-epic
   decision. Do not implement EP-004 until that decision is approved.

## Upcoming milestones — reliability and release quality

- Product Owner decides whether/when to publish a release that includes Phase 3.
- Add signed/notarized macOS release path and document certificate ownership.
- Expand Windows runtime validation beyond build success.
- Reconcile notification dependency and platform behavior.
- Execute only the EP-004 path selected by the assessment (likely targeted
  cleanup unless stabilization proves shared lifecycle defects).
- Keep Claude parser fixtures current as CLI output changes.

## Product decision queue

### Cursor Agent

- Do not implement personal quota monitoring now.
- Product Owner may approve a separate automation epic using documented
  headless JSON / SDK surfaces.
- Enterprise analytics must remain a separate, gated feature.

### EP-004 provider platform

- Decision pending after stabilization evidence.
- Current architectural leaning: targeted cleanup over a full rewrite unless
  triggers fire (third provider needing many shared changes, shared lifecycle
  defects, simultaneous refresh requirement, etc.).

### Deferred product capabilities

- Historical usage charts
- Multi-account support
- Synced/cloud settings
- Automatic updates
- macOS Intel release (only if demand justifies CI/distribution cost)

## Exit criteria for the next release

- Main contains approved EP-002 Phase 3 work (done).
- Handoff package reflects the final merged and stabilization state.
- Analyzer, non-golden tests, golden tests, and release-sidecar checks pass.
- Stabilization report and EP-004 decision are recorded.
- Changelog and release notes match included behavior.
- Release is triggered explicitly by version tag or manual dispatch.
