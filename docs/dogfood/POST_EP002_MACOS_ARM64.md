# macOS arm64 Dogfood Checklist — Post-EP-002 Stabilization

**Date:** 2026-07-19  
**Platform:** macOS arm64 (primary supported)  
**Build basis:** `main` @ `2885980` + stabilization branch  
**Status:** Checklist prepared; mark each item during a local dogfood pass

## Gates

| # | Scenario | Pass? | Notes |
| --- | --- | --- | --- |
| 1 | Cold launch from packaged `.app` | ☐ | No hung tray; dashboard reachable |
| 2 | Provider switch Claude → Copilot → Claude | ☐ | No stale metrics; one refresh after settle |
| 3 | Copilot auth failure and recovery | ☐ | Clear error; resume after login |
| 4 | Claude CLI missing / PATH failure and recovery | ☐ | Auto-refresh pauses; manual retry recovers |
| 5 | Sleep / wake (>2 min sleep) | ☐ | Overdue schedule recovers; no duplicate timers |
| 6 | Tray menu: refresh / show / quit | ☐ | Actions respond; no stuck refreshing |
| 7 | Threshold notifications (if enabled) | ☐ | Fire once; no spam |
| 8 | Launch at login toggle | ☐ | Persists across relaunch |
| 9 | Relaunch persistence | ☐ | Selected provider + theme retained |
| 10 | Log redaction | ☐ | No tokens/`ghu_` in logs view/export |
| 11 | Idle resource observation (~15 min) | ☐ | CPU/memory reasonable; no runaway sidecar |
| 12 | `NotificationGateway` migration (v2 Feature 2.1.1) — threshold notification still fires via `IoNotificationGateway`, and clicking it (`onClick`) behaves correctly on a real macOS notification | ☐ | `TrayController.maybeNotify` now goes through `IoNotificationGateway` instead of calling `local_notifier` directly — confirm no regression from row 7, plus that `LocalNotification.onClick` actually invokes the supplied callback once a consumer wires one (Epic 2.3's queue-completion notification will be the first real `onClick` user; re-run this check when that lands) |

## Evidence to attach

- Build/commit SHA
- Screenshot of Claude and Copilot success states
- Any failure logs (redacted)

## Outcome

- [ ] Ready for Product Owner release consideration
- [ ] Blockers filed with severity
