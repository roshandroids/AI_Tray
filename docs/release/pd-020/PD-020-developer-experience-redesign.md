# PD-020 — Developer Experience Redesign

**Status:** Ready for Product Owner review  
**Scope:** Presentation + diagnostics/logging visibility only  
**Date:** 2026-07-13

---

## Summary

AI Tray’s dashboard, settings, tray status, and developer tooling now follow a **terminal-inspired** aesthetic (IBM Plex Mono, ASCII separators, neon status colors). The only functional addition is **Diagnostics + Logs**.

---

## Deliverables

| # | Item | Status |
|---|------|--------|
| 1 | Redesigned dashboard | Done |
| 2 | Redesigned settings | Done |
| 3 | Diagnostics page | Done |
| 4 | Log viewer | Done |
| 5 | Dynamic tray icon | Best-effort (see platform notes) |
| 6 | Before/after | Capture locally (mockup reference in Product Owner design) |
| 7 | Accessibility review | Done (below) |
| 8 | Business logic unchanged | Confirmed |

---

## What changed (presentation)

### Theme
- Dark terminal palette: Live `#22c55e`, Cached `#eab308`, Error `#ef4444`, Refreshing `#7c3aed`, Progress `#a78bfa`
- ASCII separators (`AsciiSeparator`) and dense `TerminalKvRow` layout

### Dashboard
- Session / Week meters with uppercase labels and reset blocks
- Usage status + CLI health sections
- Keyboard hints: `⌘R` refresh, `⌘,` settings
- Status pill in app bar; Diagnostics entry

### Settings
- Sections: Appearance, Refresh, Notifications, App behavior, CLI, Diagnostics
- Links to Diagnostics and Logs

### Diagnostics
- App version, platform, build, theme
- Refresh phase, status, last success/failure, durations, failure counts
- Parser shape/validation/cache/exit code
- Advanced tools: Force refresh, Open logs, Copy diagnostics, Export logs, Test notification, Show cache

### Logs
- Ring buffer (500 entries) via `BufferedAppLogger`
- Filter by level, search, copy, clear, export
- Levels: DEBUG / INFO / WARNING / ERROR / SUCCESS
- Recovery hints on known failure codes

---

## Dynamic tray icon

| Platform | Behavior |
|----------|----------|
| **macOS** | Runtime `setIcon` swaps badge variants: live / cached / error / refreshing / waiting PNGs. Menu-bar title also prefixes status emoji + session `%`. |
| **Windows** | Static `tray_icon.ico` only (no per-state ICO set). Status still shown in tooltip + menu labels. |

`tray_manager` supports runtime `setIcon`; Windows limitation is **asset packaging** (ICO variants), not API absence.

Assets: `assets/tray/tray_icon_{live,cached,error,refreshing,waiting}.png`

---

## CLI version

Diagnostics shows `CLI version: —` because capturing `claude --version` requires extending the adapter/health path. Deferred to avoid business-logic changes in this PD. All other requested diagnostics fields are available from existing `RefreshStatus` / settings.

---

## Accessibility review

| Check | Result |
|-------|--------|
| Status not color-only | Status uses emoji + text label + color |
| Usage meters | `Semantics` label includes percent + reset |
| Keyboard | ⌘R refresh, ⌘, settings |
| Contrast | Neon status on near-black; text ladder for primary/muted |
| Targets | Outlined tool buttons and list tiles retain default tap sizes |
| Screen reader | App bar status pill labeled; log lines selectable |

---

## Business logic confirmation

**Unchanged:**
- Parser
- Repository / refresh algorithm
- Claude CLI adapter fetch/parse path
- Cache write rules

**Added (presentation / DX plumbing only):**
- `BufferedAppLogger` wrapping console logger
- Diagnostics / Logs UI
- Tray icon asset swapping on status

---

## Verification

- `flutter analyze --fatal-infos` — clean
- `flutter test --exclude-tags golden` — pass
- `flutter test --tags golden` — pass (goldens updated for PD-020 colors)

---

## Before / after screenshots

Capture after launch:

1. Dashboard (Live)
2. Settings
3. Diagnostics
4. Logs
5. Tray menu (Live / Cached / Error)

Reference mockup: Product Owner design (`AI Tray v1.0 — Nerdier. Clearer. Smarter.`)

---

**Stop — awaiting Product Owner review before further features.**
