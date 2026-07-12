# S-001 — Windows Validation Report

**Phase:** Phase 2 Stabilization  
**Date:** 2026-07-12  
**Host:** macOS (Darwin) — **not** a Windows build host  
**App version:** `1.0.0-rc.1+1`

---

## Objective

Build and verify AI Tray on Windows: startup, tray, notifications, launch-at-login; produce this validation report. **Gate:** Windows build passes.

---

## Summary

| Check | Result |
|--|--|
| Windows project present (`ai_tray/windows/`) | **PASS** (static) |
| `flutter build windows --release` on this host | **BLOCKED** |
| Startup / tray / notifications / login-at-startup | **NOT RUN** |
| Gate: Windows build passes | **FAIL (blocked)** |

```text
"build windows" only supported on Windows hosts.
```

No Windows compile errors were observed because the toolchain never started. This is an **environment blocker**, not an application defect proven on Windows.

---

## Static inventory (macOS review only)

| Item | Status |
|--|--|
| `windows/CMakeLists.txt` | Present · `BINARY_NAME = ai_tray` |
| `windows/runner/*` | Standard Flutter runner sources present |
| `windows/runner/resources/app_icon.ico` | Present |
| `Runner.rc` version macros | Present (Flutter-driven) |
| Tray icon asset | `assets/tray/tray_icon.ico` declared + used when `Platform.isWindows` |
| Desktop shell | `initializeDesktopShell` / `TrayController` include Windows branches |
| Plugins used on Windows | `tray_manager`, `window_manager`, `launch_at_startup`, `local_notifier`, `shared_preferences` |

### Code-path notes (unverified at runtime)

1. **CLI resolution** — Windows may need `claude.cmd` / absolute path in Settings more often than macOS.
2. **Tray overflow** — icon may sit in the notification-area chevron; document in troubleshooting after smoke.
3. **`local_notifier`** — `ShortcutPolicy.requireCreate` may require a Start Menu shortcut on first run.
4. **Executable name** — on-disk name is `ai_tray.exe` (CMake `BINARY_NAME`), while product display name is “AI Tray”.

---

## Required to clear the gate (Windows host)

Run on a machine with Flutter Windows desktop + Visual Studio workload:

```bat
cd ai_tray
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

Then manually verify:

1. Cold start → process alive; window may hide  
2. System tray icon visible (check overflow)  
3. Tray: Open / Refresh / Settings / Quit  
4. Notification permission + threshold notify  
5. Launch at login toggle + reboot/login check  
6. Claude CLI path (PATH vs Settings override)

Attach logs and update this report to **PASS** or list build/runtime fixes.

---

## Deliverable fields (S-001)

| Field | Content |
|--|--|
| **Objective** | Windows build + runtime verification |
| **Summary** | Blocked: cannot build Windows on macOS host |
| **Files changed** | This report only (no app code) |
| **Tests** | N/A on Windows; macOS suite unchanged |
| **Metrics** | N/A |
| **Risks** | Claiming Windows GA without this gate is a product risk (KI-01) |
| **Conventional Commit** | `docs: add S-001 Windows validation report (blocked on macOS host)` |
| **Architecture Impact** | None |
| **Recommendation** | **PO decision required** — see below |

---

## Product Owner decision needed

S-001 gate is unmet. Choose one:

1. **Defer Windows** — continue Phase 2 (S-002+) for **macOS-first GA**; mark Windows experimental until a Windows host clears S-001.  
2. **Pause Phase 2** — wait until a Windows host is available; resume at S-001.  
3. **Provide Windows host / CI** — agent or human runs the checklist above; then continue sequentially.

Stabilization rules forbid feature work; they do not authorize skipping a sequential gate without PO input.

**Stopped at S-001.** Awaiting Product Owner direction before S-002.
