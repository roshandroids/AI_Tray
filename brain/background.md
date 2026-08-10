---
slug: background
title: Project background
role: project background
updated: "2026-08-09T23:29:04"
---

# Project background

## Why

Developers on metered AI-coding subscriptions (Claude Code, GitHub Copilot) have
no ambient way to see remaining usage/quota without switching context into a
CLI or web dashboard. AI Tray is a native macOS/Windows tray app that surfaces
that usage continuously, plus (new in v2) a light "orchestration companion"
surface for Claude Code sessions specifically — browse sessions, resume one by
hand, or queue a resume for later under a mandatory budget cap.

## Goals

- Always-visible, low-noise usage/health status for each supported provider
  (menu bar / system tray icon + dashboard).
- Never show an invented number — every value is either freshly fetched,
  clearly labeled cached/stale, or explicitly unavailable. See
  [[usage-data-model]].
- Resilient to an unreliable external dependency (the provider CLI): a single
  slow or malformed CLI response must degrade gracefully, not crash the app
  or blank the UI. See [[caching-strategy]].
- Let a user act on a Claude Code session (continue, queue a resume) without
  leaving the tray app, without a second database, and without ever
  auto-running something unbounded.

## Non-goals

- Not a chat client, not an IDE, not a general automation engine.
- No history charts, multi-account support, or cloud settings sync.
- No Cursor Agent personal-quota provider — no official API exists for it
  (PD-023; see [[rejected-approaches]]).
- No Flutter Web build of the product app — it is native tray/CLI/sidecar by
  design (PD-025; see [[rejected-approaches]]).
- No unattended Resume Scheduler yet, no Session Analytics — both are
  explicitly deferred (v2 Milestone 3 / v3), gated on real usage evidence,
  not a timer. See `roadmap`.

## Target user

An individual developer who pays for one or more AI coding-assistant
subscriptions and wants to avoid silently blowing through a quota mid-task,
plus — for Claude Code users specifically — a quick way to see and resume
recent sessions without re-opening a terminal.
