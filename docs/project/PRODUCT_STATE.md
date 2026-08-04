# AI Tray — Product State

**Updated:** 2026-08-02  
**Current release:** v1.3.3 (tag) — `main` is ahead of this tag; a new release is pending the open-source readiness freeze
**Positioning:** Desktop usage and health companion for AI developer tools, now with an "orchestration companion" surface for Claude Code sessions (see v2 vision doc) — not a chat client, not an IDE, not a general automation engine
**Architecture posture:** EP-004 targeted cleanup approved (PD-024 / ADR-004) — still open, not yet executed
**Demo posture:** Product-as-demo via GitHub Releases (`demos.json` id `main`); no Flutter Web embed (PD-025)
**CI posture:** Quality CI + Release CD via `platform-ci@v1` reusable workflows (D-023) — desktop builds only on tag/dispatch or a `release/*` PR
**Release notes:** CHANGELOG.md SoT; Settings About / Diagnostics show live version + What’s New (D-020)
**Appearance:** FlexColorScheme branded presets + bundled fonts + app-icon architecture (PD-026 / ADR-005, merged); adaptive menu-bar density (PD-027, merged)
**Session management:** Session Browser + Detail (v2 M1), manual Resume + Resume Queue + click-to-resume notifications (v2 M2) — all merged; Resume Scheduler (v2 M3) intentionally not started
**Docs posture:** Governance + process + engineering standard + blueprint (D-018); release-freeze doc sync in progress (this session)

## Supported experience

| Area | Status |
| --- | --- |
| macOS arm64 | Primary supported release target |
| Windows x64 | Experimental release target — CI-buildable, no recorded real-hardware pass yet |
| macOS Intel/x64 | Not published |
| Flutter Web / public embed | Not supported (PD-025) |
| Dark / light / system themes | Implemented |
| Branded theme / font / app-icon presets | Implemented (PD-026; icon switch unsupported on desktop) |
| Tray/menu-bar status | Implemented (adaptive title density + template glyph) |
| Session Browser (list, filter by project path) | Implemented (v2 M1) |
| Session Detail (transcript summary, resume actions) | Implemented (v2 M1/M2) |
| Manual "Resume now" | Implemented (v2 M2) |
| Resume Queue (enqueue, run next, cancel/remove, completion notification) | Implemented (v2 M2) |
| Resume Scheduler (unattended, timer/wake-driven) | Not started — gated on real M2 usage evidence (v2 M3) |
| Session Analytics | Deferred to v3 — not in current scope |
| Settings, diagnostics, logs | Implemented |
| In-app What’s New / release history | Implemented (D-020; from CHANGELOG-derived asset) |
| Accessibility and golden coverage | Implemented; continue manual QA |

## Provider status

### Claude Code — Stable

- Session and weekly usage from installed Claude CLI
- Auth/version/process diagnostics
- Defensive parsing and stale-cache fallback
- Risk: CLI output is not a stable public schema

### GitHub Copilot — Experimental

- Official SDK sidecar with quota mapping
- Premium requests, remaining percentage, resets, chat/completion metrics when
  supplied by the SDK
- Shared settings, diagnostics, logs, dashboard, and empty states
- Risk: `account.getQuota` is experimental

### Cursor Agent — Research only

- Supported automation surfaces exist (CLI/SDK/Cloud Agents)
- No official Hobby/Pro personal remaining-percentage/reset-date API
- PD-023: do not implement as a personal quota provider unless Cursor publishes
  an official consumer usage-summary API
- EP-003A confirmed `agent -p "/usage"` returns generated prose; JSON contains
  only per-agent-turn token accounting, not plan quota
- Optional future: separate automation-provider epic or Enterprise analytics

## Shipped outcomes

- PD-021 design system and capability-driven provider UI
- EP-002 Copilot provider foundation and shared UI integration
- v1.3.3 Claude parser resilience fix
- Release assets limited to macOS arm64 + Windows x64

## Current product constraints

- No history charts, multi-account support, or cloud settings sync
- Usage cache may intentionally display labeled stale values
- macOS release is not signed/notarized
- App Sandbox is disabled for CLI/sidecar subprocess execution
- Sleep/wake and extended dogfooding remain partially manual
- No Flutter Web playground or public web embed (PD-025); Showcase launches
  the product via `showcase/demos.json` (`id: main`) + Releases downloads

## Current product gate

Repository is in **release freeze for open-source readiness** (see
`ROADMAP.md`). Remaining gates: documentation sync, real-hardware dogfood on
both platforms, signed/notarized macOS, and an explicit Product Owner
decision on flipping the GitHub repo from private to public. Cursor
automation without quota parity may only proceed through a separate Product
Owner-approved epic.
