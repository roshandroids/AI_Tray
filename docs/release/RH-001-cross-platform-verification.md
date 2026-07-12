# RH-001 — Cross-platform Verification

**Release:** v1.0.0-rc.1  
**Date:** 2026-07-12  
**Host used for this report:** macOS (Darwin 25.5.0)

---

## Summary

| Check | Result | Notes |
|--|--|--|
| macOS build (release) | **PASS** | `AI Tray.app` built successfully (~42.5MB) |
| Windows build (release) | **BLOCKED** | `"build windows" only supported on Windows hosts` |
| Automated tests | **PASS** | 34/34 |
| `flutter analyze` | **PASS** | No issues |
| Startup (code path) | **PASS** (static) | Desktop shell initializes tray/window/notifier/login hooks |
| Tray behavior | **PASS** (code + packaging fix) | Icon now loads from Flutter assets |
| Notifications | **PASS** (static / deps) | `local_notifier` wired; deprecation warnings from plugin APIs |
| Launch at login | **PASS** (static) | `launch_at_startup` setup + Settings toggle |

Manual interactive smoke (tray click, sleep/wake, login item) still required on a real menu bar session — see RH-002.

---

## macOS

### Build

```bash
cd ai_tray
flutter build macos --release
# → build/macos/Build/Products/Release/AI Tray.app
```

### Bundle metadata (Release app inspected)

| Key | Value |
|--|--|
| Product name | AI Tray |
| Bundle ID | `com.aitray.app` |
| Short version (pre-bump build) | `0.1.0` → bumped to **`1.0.0-rc.1`** in pubspec for RC1 |
| Build number | `1` |
| Copyright | Copyright © 2026 AI Tray. All rights reserved. |

### Observed platform notes

1. **Tray icon packaging (fixed in RC1):** Prior paths pointed at `macos/Runner/...` source tree files, which are **not** reliable inside a packaged `.app`. Icons are now Flutter assets under `assets/tray/`.
2. **`local_notifier`:** Release build emits deprecation warnings for `NSUserNotification*` (macOS 11+). Functional for RC1; consider migrating notifier plugin in v1.1 if notifications misbehave.
3. **Hide-on-close / skip taskbar:** Window closes to tray (prevent-close + hide). Expected for menu-bar apps; document for users who expect Quit via red traffic light.
4. **CLI dependency:** App assumes `claude` on PATH (or Settings override). Menu-bar apps may inherit a reduced PATH vs Terminal — document override path for Homebrew installs.

### Startup / tray / notifications / login (verification status)

| Area | Automated / static | Manual still needed |
|--|--|--|
| Startup bootstrap | DI + SharedPreferences + `initializeDesktopShell` | Cold launch from Finder / Launchpad |
| Tray menu | Open / Refresh / Settings / Quit wired | Icon visibility, template rendering on light/dark menu bar |
| Notifications | Threshold notify on status stream | OS permission prompt, delivery while hidden |
| Launch at login | Settings toggles `launchAtStartup` | Reboot / logout cycle |

---

## Windows

### Build

Cannot be produced on this macOS host.

```text
"build windows" only supported on Windows hosts.
```

Windows **project scaffolding exists** (`ai_tray/windows/`, `app_icon.ico`, `Runner.rc` version macros). Treat Windows as **experimental until a Windows host runs RH-001 + RH-002**.

### Expected Windows-specific risks (unverified)

| Risk | Why |
|--|--|
| PATH / `claude.cmd` | CLI resolution differs from Unix |
| Tray icon | `.ico` asset packaged; DPI / monochrome not audited |
| Launch at login | Registry / Startup folder behavior via plugin |
| Notifications | Shortcut policy (`ShortcutPolicy.requireCreate`) may require first-run setup |
| Process spawn | `Process.start` + stdin close parity with macOS |

---

## Recommendation

- **Ship RC1 for macOS dogfooding** (PO Decision 007).
- **Defer Windows GA** until a Windows machine completes build + RH-002 checklist.
- Tag git: `v1.0.0-rc1` after docs land; do not promote to `v1.0.0` until post-dogfood.
