# Release Notes — AI Tray v1.0.0-rc.2

**Tag:** `v1.0.0-rc2`  
**Date:** 2026-07-12  
**Status:** Release Candidate — **dogfooding** (PD-011) · not final v1.0.0  
**Prior:** [v1.0.0-rc.1](release-notes-v1.0.0-rc1.md)

## Highlights

- Stabilization Phase (Phase 2) approved; RC2 published for real-world dogfooding
- **Feature freeze** in effect — critical bugs, stability, and docs only (PD-011)
- **macOS** remains the officially validated platform; **Windows Experimental** (PD-010 / S-001A)
- Branded Dash-style tray and app icons

## Stabilization improvements (since RC1)

| Area | Change |
|--|--|
| Reliability | Auto-refresh pause on CLI missing / auth failure now clears `nextScheduledAt` before status emit |
| Tests | Suite expanded to **56** tests (adapter, cache, repository, refresh error paths, 500-cycle stability, single-flight) |
| Parser | Additional Shape A/B / unknown / empty / auth-prompt fixtures and regressions |
| Packaging | Tray icons shipped as Flutter assets; macOS Release packaging re-verified |
| Docs | Guides, Known Issues, Phase 2 reports, dogfood templates, postmortem |
| Platform policy | Windows deferred to S-001A; not claimed as GA-ready |

See also: [Stabilization Report](../stabilization/STABILIZATION_REPORT.md) · [S-010](../stabilization/S-010-ga-recommendation.md)

## Platform support

| Platform | Status |
|--|--|
| macOS | Supported / validated |
| Windows | Experimental |

## Installation

See [Installation Guide](../guides/installation.md) and [Packaging](RH-003-packaging.md).

```bash
cd ai_tray
flutter build macos --release
# → build/macos/Build/Products/Release/AI Tray.app
```

## Breaking / upgrade notes

- Version `1.0.0-rc.1+1` → **`1.0.0-rc.2+2`**
- Color tray icon uses `isTemplate: false` (full-color mascot)

## Known issues

See [Known Issues](known-issues.md).

## Dogfooding (PD-011)

- Log daily observations: [dogfood/daily-observation-log.md](../dogfood/daily-observation-log.md)
- Bug process: [issue-template](../dogfood/issue-template.md) · [triage](../dogfood/bug-triage-template.md)
- Do not redesign from a single observation — look for recurring patterns
- GA only after dogfood exit criteria + Product Owner approval

## Bug-fix bar (during dogfood)

Every user-visible fix must include: root cause · resolution · regression test (when practical) · release note update.

## Dogfood fixes (post-tag)

### macOS: Claude CLI “Operation not permitted”

| | |
|--|--|
| **Root cause** | Default App Sandbox blocked `Process.start` for the external `claude` binary |
| **Resolution** | Keep App Sandbox **on** with temporary absolute-path exceptions for `/opt/homebrew/`, `/usr/local/`, `/usr/bin/`, home-relative `.claude/` access, and network client; resolve `claude` only via known CLI prefixes (no full-PATH FS probes) |
| **Regression** | `test/unit/process/io_process_runner_test.dart`; Release `.app` refresh success with sandboxed entitlements |
| **User impact** | Usage refresh works without unsandboxed “all folders” exposure |

### macOS: App exits immediately after launch (“Lost connection to device”)

| | |
|--|--|
| **Root cause** | Startup hides the window for tray mode, but `applicationShouldTerminateAfterLastWindowClosed` returned `true`, so AppKit quit the process (exit 0) as soon as the window was hidden — often right as Claude CLI spawn began |
| **Resolution** | Return `false` from `applicationShouldTerminateAfterLastWindowClosed` in `AppDelegate.swift` |
| **Regression** | Manual: launch Debug/Release `.app` and confirm process stays alive with tray icon; automated entitlements/AppDelegate source check |
| **User impact** | App remains in the menu bar and can complete usage refresh |

### macOS: Launch at login MissingPluginException

| | |
|--|--|
| **Root cause** | `launch_at_startup` requires a manual macOS method channel; it is not registered by `GeneratedPluginRegistrant` |
| **Resolution** | Implement `launch_at_startup` channel in `MainFlutterWindow.swift` using `SMAppService` (macOS 13+) |
| **Regression** | Manual Settings toggle after full rebuild; MissingPluginException warnings should stop |
| **User impact** | Launch-at-login toggle can talk to Login Items |

### macOS: Release build appears not to open

| | |
|--|--|
| **Root cause** | Startup hid the window and used `skipTaskbar: true`, so Finder launch showed no Dock/window while the process ran in the menu bar |
| **Resolution** | Show + focus window on cold start; keep Dock presence; close still hides to tray |
| **Regression** | Launch Release `.app` and confirm window appears; close → tray; tray Open → window |
| **User impact** | Double-clicking the Release app visibly opens AI Tray |
