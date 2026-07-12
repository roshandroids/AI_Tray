# PD-015 — Rich Tray Dashboard

**Status:** Ready for Product Owner review  
**Scope:** Tray presentation only  
**Date:** 2026-07-12

---

## 1. Before / after

### Before

Minimal native menu (5 actionable rows + 1 status line):

```text
Session 24% (cached)
────────────────
Open
Refresh
Settings
────────────────
Quit
```

### After

Compact developer dashboard in the native tray menu:

```text
AI Tray
────────────────
🟢 Claude connected
────────────────
Current Session
██░░░░░░░░
24% used
Resets 10pm (America/Toronto)
────────────────
Current Week (all models)
█░░░░░░░░░
11% used
Resets Sat 7am (America/Toronto)
────────────────
🟢 Live
Updated 12 sec ago
────────────────
Open Dashboard
Refresh Now
Settings
────────────────
Quit
```

**Tooltip (hover):** `AI Tray · Session 24% · Week 11% · Live`  
**macOS menu-bar title:** `24%` beside the tray icon when live data is available.

---

## 2. Tray UX rationale

| Question | Where answered |
|----------|----------------|
| Is Claude connected? | Connection row (🟢 / 🔴 / 🔄 / ⚪) |
| Session usage remaining? | Session bar + `% used` |
| Weekly usage remaining? | Week bar + `% used` (prefers “all models” bucket) |
| When does it reset? | Per-section reset lines |
| Live or cached? | Footer status badge |
| Last updated? | Footer “Updated … ago” |

Users can answer routine checks from the tray without opening the dashboard window.

Implementation: [`tray_menu_builder.dart`](../../ai_tray/lib/features/tray/presentation/tray_menu_builder.dart) maps existing `RefreshStatus` → disabled info rows + actions. No repository or parser changes.

---

## 3. Platform limitations

| Capability | macOS | Windows | Notes |
|------------|-------|---------|-------|
| Rich text rows | Yes | Yes | Native `NSMenu` / Win32 menu via `tray_manager` |
| Unicode progress bars (`█░`) | Yes | Yes | Monospace alignment not guaranteed (system menu font) |
| Claude colors / beige / lavender | **No** | **No** | Native menus use OS styling; aesthetic is structural only |
| Custom Flutter widgets in menu | **No** | **No** | Would require a popover window (out of scope) |
| Dynamic tray **icons** by state | **Limited** | **Limited** | `setIcon` accepts static asset paths only; no runtime badge overlay |
| Session % beside icon | Yes (`setTitle`) | No | macOS menu-bar title only |
| Rich tooltip | Yes | Yes | `setToolTip` summary |

**Dynamic icons:** Not implemented. Would need pre-rendered icon variants per state and platform-specific testing. Documented rather than workaround.

---

## 4. Confirmation

- **No** parser changes  
- **No** repository / refresh logic changes  
- **No** Claude integration changes  
- Presentation only: `tray_menu_builder.dart` + `TrayController._rebuildMenu`

---

## Tests

- `test/unit/tray/tray_menu_builder_test.dart` — live, cached, refreshing, error states

**Stop here — awaiting Product Owner review.**
