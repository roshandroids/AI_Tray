# Release Notes — AI Tray v1.0.0-rc.1

**Tag:** `v1.0.0-rc1`  
**Date:** 2026-07-12  
**Status:** Release Candidate — for personal dogfooding, **not** final v1.0.0

## Highlights

- Native **macOS menu bar** companion for Claude Code subscription usage
- **macOS is the officially validated platform** for the v1.0.0 line
- **Windows is Experimental** (PD-010) — project scaffolded; validation deferred to **S-001A** until a Windows build host is available
- Claude CLI pipeline: `claude -p '/usage' --output-format json` (ADR-001)
- Shape A success + Shape B soft failure with last-known-good cache (ADR-002)
- Tray menu: Open / Refresh / Settings / Quit
- Settings: refresh interval, auto-refresh, notification threshold, launch at login, CLI path
- Automated tests; `flutter analyze` clean; macOS Release build verified

## Platform support

| Platform | v1.0.0 status |
|--|--|
| macOS | Supported / validated |
| Windows | Experimental — see [PD-010](../stabilization/PD-010-defer-windows.md) |

## Installation

See [Installation Guide](../guides/installation.md) and [Packaging](RH-003-packaging.md).

## Breaking / upgrade notes

- First public RC — no prior stable upgrade path.
- Version bumped from `0.1.0+1` → `1.0.0-rc.1+1`.

## Known issues

See [Known Issues](known-issues.md).

## Next steps (Product Owner)

1. Dogfood RC1 for 1–2 weeks during normal Claude Code work.
2. Record annoyances and failures.
3. Promote to **v1.0.0** only after dogfood — do not jump to v1.1 features yet.
