# User Guide — AI Tray (v1.0.0-rc.1)

AI Tray shows your **Claude Code subscription usage** in the macOS menu bar or Windows system tray. It reads usage via the Claude CLI (`claude -p '/usage'`), never invents percentages, and keeps a last-known-good cache when temporary CLI responses are incomplete.

## Tray menu

| Item | Action |
|--|--|
| **Open** | Show the usage window |
| **Refresh** | Fetch usage now |
| **Settings** | Open settings |
| **Quit** | Exit the app completely |

Closing the window (traffic light / X) **hides** the app to the tray; it does not quit.

## Usage window

- **Live** — Latest successful parse (Shape A).
- **Stale / cached** — Showing last known good while a soft failure or temporary issue occurs.
- **Error** — Auth, missing CLI, timeout, or hard failure. Follow on-screen guidance.

Percentages only appear when the CLI returns a usable usage block (session / weekly lines). Contribution-only responses are treated as temporary unavailability.

## Settings

| Setting | Purpose |
|--|--|
| Refresh interval | How often auto-refresh runs (bounded MVP range) |
| Auto-refresh | Enable/disable background polling |
| Notification threshold | Notify when usage crosses the threshold |
| Launch at login | Start AI Tray when you log in |
| Claude CLI path | Optional absolute path if `claude` is not on PATH |

## Tips

- Prefer intervals ≥ 30s to reduce Shape B (rate-limit) flakiness.
- After `claude auth login`, tap Refresh once.
- For dogfooding RC1: note any annoyance in a personal log — that feeds v1.0.0.

## What AI Tray does not do (RC1)

- Charts / analytics dashboards
- Multiple AI providers
- Multiple Claude accounts
- Editing Claude settings beyond CLI path / refresh behavior
