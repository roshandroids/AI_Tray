---
slug: roadmap
title: Roadmap
role: milestones
updated: "2026-08-09T23:31:18"
---

# Roadmap

## Unresolved: release-freeze status

**Do not assume the project is in a feature freeze without checking
`CHANGELOG.md [Unreleased]` and recent `git log` first.**

`docs/project/DECISION_LOG.md` (PD-029, 2026-08-02) declares: "Repository
enters release freeze: no new features until documentation, release
engineering, and OSS scaffold are confirmed consistent with shipped code."
`docs/project/*` has not been touched since 2026-08-03 (verified via
`git log -- docs/project/`).

But `CHANGELOG.md` shows a large **v1.4.0 "V3 redesign"** (2026-08-05) —
app shell, command palette, onboarding, product tour, help center,
productivity coach, dynamic tray icon — followed by **v1.5.0** (2026-08-07,
resizable Session Detail panels + fixes) — both clearly new feature work,
both after the freeze was declared. Neither release is reflected in
`docs/project/ROADMAP.md`/`PROJECT_STATE.md`/`PRODUCT_STATE.md`.

Two explanations are equally plausible from available evidence: the freeze
was informally lifted/overridden without a recorded decision, or the
`docs/project/*` package is simply stale. **Treat `docs/project/*`'s
"current phase" framing as unverified until you check `git log` and
`CHANGELOG.md` yourself.** This brain does not resolve the contradiction —
it flags it so it isn't silently baked into future work.

## Durable, still-open items (true regardless of freeze status)

- **V2 Milestone 3 — Resume Scheduler**: intentionally not started, gated on
  real Milestone 2 usage evidence, not a timer (PD-028). Don't build this
  speculatively.
- **Session Analytics**: deferred to v3, not in current scope.
- **Targeted cleanup (ADR-004 / PD-024)**: canonicalize `core/`/`copilot/`
  compatibility-alias imports, deprecate the aliases, enrich
  capability/recovery/diagnostics metadata, pick one retry owner. Scoped as
  its own narrow PR series — see [[rejected-approaches]] for why a full
  rewrite was rejected instead.
- **Signed/notarized macOS build**: open as of the last verified check.
- **Windows hardware validation**: Windows stays Experimental until a real
  checklist pass is recorded (CI-buildable already).
- **Repo visibility (private → public)**: explicit Product Owner decision,
  never an automatic outcome of a docs pass.
- **`platform-ci` SHA maintenance**: bump the pinned commit SHA
  deliberately when upstream `platform-ci` needs a new capability — see
  `stack`.

## Non-goals reaffirmed by roadmap (don't revisit casually)

- Cursor Agent as a personal quota provider — blocked on Cursor publishing an
  official API (PD-023).
- Flutter Web build of the product app (PD-025).
- A "run without a budget cap" path for queued resumes (D-025) — this is a
  safety invariant, not a missing feature.

## How to update this page

Update only when a roadmap item actually completes, is added, or is
explicitly deferred/rejected by a real decision — not for routine PRs. Prefer
recording the decision in [[rejected-approaches]] or a new `decision` page
and linking it here over inlining long rationale in this root page.
