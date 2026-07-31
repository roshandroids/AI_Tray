# AI Tray — Product State

**Updated:** 2026-07-31  
**Current release:** v1.3.3  
**Positioning:** Desktop usage and health companion for AI developer tools
**Architecture posture:** EP-004 targeted cleanup approved (PD-024 / ADR-004)
**Demo posture:** Product-as-demo via GitHub Releases (`demos.json` id `main`); no Flutter Web embed (PD-025)
**CI posture:** Quality CI + Release CD (D-017) — desktop builds only on tag/dispatch

## Supported experience

| Area | Status |
| --- | --- |
| macOS arm64 | Primary supported release target |
| Windows x64 | Experimental release target |
| macOS Intel/x64 | Not published |
| Flutter Web / public embed | Not supported (PD-025) |
| Dark / light / system themes | Implemented |
| Tray/menu-bar status | Implemented |
| Settings, diagnostics, logs | Implemented |
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

Land EP-004A + demo contract; complete macOS dogfood; Product Owner decides
Phase 3 release timing. Cursor automation without quota parity may only proceed
through a separate Product Owner-approved epic.
