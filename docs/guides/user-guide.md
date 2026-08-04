# User Guide — AI Tray (v1.3.3)

AI Tray is a macOS menu bar / Windows system tray companion for AI developer
tool subscriptions and Claude Code sessions. It reads usage directly from the
installed CLI (never invents percentages) and keeps a last-known-good cache
when a refresh is temporarily unavailable.

## Providers

| Provider | Status | Source |
|--|--|--|
| Claude Code | Stable | `claude -p '/usage' --output-format json` |
| GitHub Copilot | Experimental | Official `@github/copilot-sdk` via a bundled sidecar |

Switch the active provider in **Settings → Provider**. Copilot's quota API is
explicitly experimental upstream — expect occasional degraded/soft-failure
states even when your subscription is fine.

## Tray menu

| Item | Action |
|--|--|
| **Open** | Show the usage window |
| **Refresh** | Fetch usage now |
| **Settings** | Open settings |
| **Quit** | Exit the app completely |

Closing the window (traffic light / X) **hides** the app to the tray; it does
not quit. The menu bar title itself stays quiet by default (adaptive
density) — it only shows a `NN%` badge once usage crosses your configured
threshold (default 90%); the tooltip always has the full numbers regardless.

On launch, the usage window opens so you can confirm the app started. Use the
tray after you close the window.

## Usage window

- **Live** — Latest successful parse.
- **Stale / cached** — Showing last known good while a soft failure or
  temporary issue occurs.
- **Error** — Auth, missing CLI, timeout, or hard failure. Follow on-screen
  guidance.

Percentages only appear when the CLI returns a usable usage block.
Contribution-only or degraded responses are treated as temporary
unavailability, not a real value.

## Sessions

Open **Sessions** from the usage window to browse your Claude Code sessions
(read directly from `~/.claude/projects/**/*.jsonl` — no separate database).

- **Browser** — Every session, most-recently-active first. Search narrows by
  project path. A live badge marks a session Claude Code currently has open.
- **Detail** — Open a session to see its model, branch, working directory,
  token totals, and whether the transcript is complete. From here you can:
  - **Resume now** — Continue that session immediately, in place.
  - **Add to queue** — Queue a resume for later (see below).

### Resume Queue

The Resume Queue lets you queue a session resume instead of running it
immediately. Open it from the usage window.

- Every queued item requires a **budget cap** (in USD) — there is no
  "run without a cap" option, by design.
- A queued resume **forks** the session by default rather than continuing
  in place, so it never silently mutates a transcript you might be
  continuing by hand elsewhere.
- Nothing runs automatically — press **Run next** to execute the oldest
  pending item. There's no auto-execute toggle yet.
- You'll get a notification when a queued item finishes (success or
  failure); clicking it opens that session's detail page directly.
- You can remove a `pending` item (cancel it before it runs) or clear a
  finished (`succeeded`/`failed`) item from the list. A `running` item can't
  be removed until it finishes — there's no cancel-mid-flight yet.

## Settings

| Setting | Purpose |
|--|--|
| Provider | Switch between Claude Code and GitHub Copilot |
| Refresh interval | How often auto-refresh runs |
| Auto-refresh | Enable/disable background polling |
| Notification threshold | Notify when usage crosses the threshold |
| Launch at login | Start AI Tray when you log in |
| Claude CLI path | Optional absolute path if `claude` is not on PATH |
| Appearance | Theme mode (light/dark/system), color preset, font, app icon |
| Menu bar density | Adaptive / always show percentage / icon only, and the reveal threshold |

## Tips

- Prefer refresh intervals ≥ 30s to reduce rate-limit flakiness.
- After `claude auth login` (or the equivalent Copilot sign-in), tap Refresh
  once.
- If a queued resume fails repeatedly, check that its working directory
  still exists — the queue fails fast rather than guessing at a substitute
  path.

## What AI Tray does not do

- Charts / historical analytics dashboards
- Multiple accounts for the same provider, or cloud settings sync
- Unattended/scheduled resumes (the Resume Queue is manual-trigger only —
  a scheduler is a deliberately deferred, gated future milestone)
- Editing Claude settings beyond CLI path / refresh behavior
- A general automation or workflow engine — AI Tray orchestrates the
  official CLIs it talks to, it doesn't replace them
