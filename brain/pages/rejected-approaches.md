---
id: rejected-approaches
title: Rejected and deliberately deferred approaches
category: decision
status: active
tags: [decisions, non-goals]
created: "2026-08-09T23:31:29"
updated: "2026-08-09T23:38:22"
---

<!-- compiled_truth -->
## Cursor Agent as a personal quota provider — rejected (PD-023, 2026-07-18)

**Do not implement.** No official Hobby/Pro personal remaining-%/reset-date
API exists. EP-003A research confirmed `agent -p "/usage"` returns generated
prose, not structured quota, and dashboard scraping is unsupported and
conflicts with Cursor's ToS. Revisit only if Cursor publishes an official
consumer usage-summary API; any Cursor automation feature (non-quota)
requires a *separate* Product Owner-approved epic, not a quiet extension of
the existing provider platform.

## Flutter Web build / public embeddable demo — rejected (PD-025, 2026-07-27)

AI Tray is tray/CLI/sidecar-native; there is no web-safe surface to embed.
The product **is** its own demo, listed in `showcase/demos.json` (`id: main`,
`type: desktop`) via GitHub Releases downloads. A `reusable-flutter-web-demo.yml`
workflow exists in the shared CI tooling but is explicitly unused by this
repo. Revisit only if a genuine non-toy web-safe surface appears — don't
build a web playground just to have a live link.

## Full EP-004 provider-platform rewrite — rejected in favor of targeted cleanup ([ADR-004](../../docs/adr/ADR-004-provider-platform-post-EP002-assessment.md) / PD-024, 2026-07-19)

Post-EP-002 stabilization fixed the shared orchestration defects that would
have motivated a rewrite, without one. ~35 compatibility alias files existed
under provider `domain/`/`copilot/` at the time; per
`docs/project/ARCHITECTURE_STATE.md` (as of 2026-08-03, itself stale — see
`roadmap`) that count was down to ~23 — real, load-bearing files, not dead
code. The accepted
posture is **targeted cleanup**: canonicalize imports, deprecate aliases,
enrich capability/recovery/diagnostics metadata, pick one retry owner — kept
as its own narrow PR series. A full rewrite remains a contingency only,
gated on triggers defined in
[ADR-004](../../docs/adr/ADR-004-provider-platform-post-EP002-assessment.md)
(read that ADR before proposing a rewrite; don't re-litigate this from
first principles).

## Third quota provider generally — not planned (PD-024 rationale)

PD-024 explicitly notes "no third quota provider is planned" as part of why
a rewrite isn't justified. Don't assume the provider platform needs to
generalize further than Claude + Copilot without a new decision record.

## Resume Scheduler timer / unattended-by-default — deferred, not rejected (PD-028, v2 M3)

Distinct from the items above: this isn't rejected on principle, it's
explicitly gated on **real Milestone 2 usage evidence** existing first (once
public/dogfood users exist) rather than being built speculatively or on a
timer. Don't build M3 just because M1/M2 shipped cleanly — check whether the
gating evidence exists first.

## "Run without a budget cap" for queued/unattended resume — hard-rejected (D-025)

Not a feature gap — a deliberate safety invariant. `ResumeQueueController`'s
constructor throws `ArgumentError` if the budget cap is missing or
non-positive. Do not add an "unlimited" option or a way to bypass this for
convenience; it's the safety property that makes unattended execution
acceptable at all (paired with `forkSession: true` by default for queued
items — see `flow`).


## Timeline

- time: 2026-08-09T23:31:29
  kind: decision
  summary: "Created this page: Rejected and deliberately deferred approaches"
  source: "docs/project/DECISION_LOG.md, ADR-004"
  affects: [rejected-approaches]

- time: 2026-08-09T23:34:31
  kind: decision
  summary: "Seed compiled_truth: Cursor quota provider, Flutter Web embed, full EP-004 rewrite, third quota provider, Resume Scheduler timing, budget-cap bypass"
  source: "docs/project/DECISION_LOG.md PD-023/024/025/028, D-025, ADR-004"
  affects: [rejected-approaches]

- time: 2026-08-09T23:38:22
  kind: decision
  summary: "Fix: add real ADR-004 relative link, attribute the ~23/~35 alias count to its stale source doc instead of stating it as current fact"
  source: "docs/adr/ADR-004, docs/project/ARCHITECTURE_STATE.md"
  affects: [rejected-approaches]
