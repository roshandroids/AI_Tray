# Windows x64 Runtime Checklist — Post-EP-002 Stabilization

**Date:** 2026-07-19  
**Platform:** Windows x64 (Experimental)  
**Status:** Checklist only — keep **Experimental** until a real Windows host verifies every gate

## Why Experimental remains

No Windows host was available in this stabilization sprint to execute runtime
gates. CI proves Windows **build + sidecar assemble/verify** only.

## Gates (run on a real Windows 10/11 x64 machine)

| # | Scenario | Pass? | Notes |
| --- | --- | --- | --- |
| 1 | Cold launch from release zip | ☐ | Tray icon appears |
| 2 | Provider switching Claude ↔ Copilot | ☐ | No stale UI |
| 3 | Auth / CLI missing recovery | ☐ | Recoverable errors |
| 4 | Sleep / wake | ☐ | Timer recovery |
| 5 | Tray actions | ☐ | Refresh / open / quit |
| 6 | Notifications | ☐ | If enabled |
| 7 | Launch at login | ☐ | Registry/startup path |
| 8 | Relaunch persistence | ☐ | Selection retained |
| 9 | Log redaction | ☐ | No secrets |
| 10 | Sidecar crash / restart | ☐ | Bounded restart; usable after |
| 11 | Idle resources | ☐ | No runaway node process |

## Packaging verification (CI already covers)

- [x] `assemble_sidecar.mjs --target windows-x64`
- [x] `verify_payload.mjs` checksum + package smoke
- [x] `smoke_protocol.mjs` handshake/version/health/shutdown (added to Release)

## Outcome rule

Windows stays **Experimental** until every gate above is checked on hardware.
Do not advertise Windows as GA in release notes until then.
