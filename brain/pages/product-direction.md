---
id: product-direction
title: Current product direction
category: project
status: active
tags: [product, positioning]
created: "2026-08-09T23:31:29"
updated: "2026-08-09T23:31:54"
---

<!-- compiled_truth -->
## What AI Tray is (verified 2026-08-09)

Desktop usage/health companion for AI-provider subscriptions, positioned as:
"not a chat client, not an IDE, not a general automation engine" (README).
Two product surfaces coexist:

1. **Provider usage/quota dashboard** — Claude Code (stable) and GitHub
   Copilot (experimental) — the original product.
2. **Claude Code session "orchestration companion"** (v2, shipped) —
   Session Browser/Detail, manual resume, and a budget-capped Resume Queue.
   This is the first *mutating* capability the app has ever shipped (prior
   surface was strictly read-only usage/quota) — see [[rejected-approaches]]
   for the safety constraints that shipped alongside it (PD-028).

**Current version / status:** read `ai_tray/pubspec.yaml` for the exact
version and `CHANGELOG.md` for what's actually shipped — do not trust a
hardcoded number here or in README.md's badge (README has been observed
lagging the real shipped version by two minor releases; verify before
quoting it to a user).

## The V3/V4 redesign (v1.4.0, 2026-08-05) — a major, code-confirmed shift

Not reflected in `docs/project/*` as of this writing. Confirmed in
`ai_tray/lib`:

- Persistent app shell (`AppShell` — NavigationRail + IndexedStack) replaced
  ad hoc page-to-page `Navigator.push`.
- Global command palette (Cmd+K) sharing one action registry with shell
  navigation.
- All primary screens rebuilt "work-first" (Dashboard leads with Continue
  Last Session / Queue a Task / Recent Sessions, not raw usage numbers).
- First-launch onboarding, a coach-mark Product Tour, and a searchable Help
  Center were added — this is a materially more guided product than the
  original bare usage-dashboard framing in most of `docs/project/*`.
- Tray icon became a dynamic color-coded usage-band ring (replacing a static
  monochrome glyph) — see [[platform-integration]].

v1.5.0 (2026-08-07) was a smaller follow-up: resizable Session Detail
panels, and fixes to back-navigation and accordion consistency introduced by
the V3 redesign.

## Provider status (verify against `docs/project/PRODUCT_STATE.md` and
`CHANGELOG.md` before relying on this — provider posture can change)

- **Claude Code** — Stable. Session/weekly usage from the installed CLI.
  Known risk: CLI output is not a stable public schema (see
  [[cli-integration]]).
- **GitHub Copilot** — Experimental. Official SDK sidecar; `account.getQuota`
  itself is an experimental RPC upstream, not just an integration choice.
- **Cursor Agent** — Research only, no production code. See
  [[rejected-approaches]] (PD-023).

## Positioning boundaries (non-goals, stable across the redesign)

No history charts, no multi-account support, no cloud settings sync, no
Flutter Web build of the product, no unattended Resume Scheduler yet. See
`background` and [[rejected-approaches]].


## Timeline

- time: 2026-08-09T23:31:29
  kind: decision
  summary: "Created this page: Current product direction"
  source: "README.md, docs/project/PRODUCT_STATE.md, CHANGELOG.md v1.4.0/v1.5.0"
  affects: [product-direction]

- time: 2026-08-09T23:31:54
  kind: decision
  summary: "Seed compiled_truth: current product direction, V3/V4 redesign, provider status, verified against source + CHANGELOG"
  source: "README.md, CHANGELOG.md, ai_tray/lib/core/navigation, docs/project/PRODUCT_STATE.md"
  affects: [product-direction]
