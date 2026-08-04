# AI Tray — AI Handoff

**Updated:** 2026-08-02  
**Read first:** This file, then `PROJECT_CONTEXT.json` and `NEXT_SESSION.md`.

## Executive summary

AI Tray is a Flutter desktop companion for AI-provider subscription usage
(Claude stable; Copilot experimental) that has grown a second surface in v2:
an "orchestration companion" for Claude Code sessions — browse sessions,
resume one by hand, or queue a resume for later with a mandatory budget cap.
EP-004A Quality CI + Release CD is on `main`, and CI has since migrated to
**`platform-ci@v1`** reusable workflows (**D-023**, PR #14). **PD-026 / D-021
/ ADR-005** FlexColorScheme personalization and **PD-027 / D-022** adaptive
menu-bar density are merged (PR #13). **V2 Milestones 1 and 2** (Session
Browser/Detail, manual resume, Resume Queue with notifications and
click-to-resume) are merged (PR #14 + this session's follow-on commits).
Latest tagged release v1.3.3; `main` is ahead of that tag.

## Current phase

**Release freeze — open-source readiness.** No new features. Only
correctness, documentation sync, release engineering, and OSS-scaffold work
until the repo is confidently publishable, then a Product Owner call on
repo visibility (private → public) and release timing.

## Repository state

- Branch: **`main`** (no feature branch in flight)
- Showcase: `showcase/demos.json` → `id: main`
- Theme: `ai_tray/lib/theme/` · Tray density: `TrayDisplayMode`
- Sessions: `ai_tray/lib/features/sessions/{browser,detail,resume,queue}/`

## Completed this session

- Regenerated macOS Podfile.lock/pbxproj/GeneratedPluginRegistrant.swift
  (were in a broken, partially-resolved state from local tooling) and
  verified the app still builds with App Sandbox disabled
- Committed the finished-but-uncommitted click-to-resume feature (v2
  Feature 2.3.1) — completes V2 Milestone 2's exit criteria
- Committed a session-ordering fix (most-recently-active first)
- Added the missing cancel/remove action to the Resume Queue UI (the
  repository method existed and was tested but had no UI entry point)
- Synced `docs/project/*` off the stale PD-026-pending-PR state (personalization
  and the v2 session work are both actually merged)

## Immediate next actions

1. Continue the release-freeze punch list: user-facing doc drift
   (`docs/guides/*`), `CHANGELOG.md [Unreleased]`, release-engineering audit,
   OSS scaffold check
2. Real-hardware dogfood on macOS arm64 and Windows x64 — record actual
   results, not just unfilled checklists
3. Product Owner decision: code signing/notarization timing, and whether/when
   to flip the GitHub repo to public

## Verification

```bash
cd ai_tray && flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot
```
