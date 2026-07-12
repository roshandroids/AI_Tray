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
