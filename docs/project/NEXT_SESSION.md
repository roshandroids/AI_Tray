# AI Tray — Next Session

**Updated:** 2026-08-02

## Start here

1. Read `AI_HANDOFF.md` and `PROJECT_CONTEXT.json`.
2. `git status`, `git branch --show-current`, `git log -5 --oneline`.
3. Work lives on `main` — no feature branch in flight. The repository is in
   **release freeze for open-source readiness** (see `ROADMAP.md`).

## Current objective

Finish the release-freeze punch list, then hand the repo-visibility decision
to the Product Owner. This is not a feature sprint — do not start V2
Milestone 3 (Resume Scheduler) or Session Analytics.

## Prerequisites

- PD-026 / PD-027 personalization merged (PR #13)
- CI migrated to `platform-ci@v1` (D-023, PR #14)
- V2 Milestone 1 + 2 merged (PR #14 + follow-on commits): Session Browser,
  Session Detail, manual resume, Resume Queue incl. click-to-resume
  notification and cancel/remove UI

## Recommended next task

1. Confirm `docs/project/*`, `docs/guides/*`, and `CHANGELOG.md` all agree
   with the current code (this is an ongoing pass — check for new drift
   before trusting these files at face value).
2. Real-hardware dogfood: run the macOS arm64 and Windows x64 checklists in
   `docs/dogfood/` and actually record pass/fail — both are currently
   unfilled templates.
3. Decide on code signing/notarization for macOS before or immediately after
   going public (currently unsigned).
4. Product Owner call: flip the GitHub repo from private to public, or stop
   writing docs that assume it already is.

## Acceptance criteria

- Analyzer clean; `flutter test --exclude-tags golden,screenshot` green
- No doc contradicts the actual `Release.entitlements` / current CI files /
  current provider set
- `CHANGELOG.md [Unreleased]` accounts for everything merged since v1.3.3
- Dogfood checklists have at least one recorded real pass, not just ☐ rows
