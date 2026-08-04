# Installation Guide — AI Tray (v1.0.0-rc.1)

## Requirements

- **macOS** 10.15+ — **officially validated** platform for v1.0.0
- **Windows** 10+ — **Experimental** ([PD-010](../stabilization/PD-010-defer-windows.md)); build only on a Windows host; not validated in RC1/Phase 2
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Active Claude.ai authentication (`claude auth login`)

## Install Claude Code CLI

1. Install Claude Code per Anthropic docs.
2. Verify:

```bash
claude --version
claude auth status
```

3. If `claude` is missing from PATH for GUI apps (common with Homebrew), note the absolute path (e.g. `/opt/homebrew/bin/claude`) for Settings → CLI path.

## Install AI Tray (macOS)

1. Build Release:

```bash
cd ai_tray
flutter build macos --release
```

2. Clear Gatekeeper quarantine on the local build (unsigned apps are blocked when double-clicked):

```bash
xattr -cr "build/macos/Build/Products/Release/AI Tray.app"
```

3. Open `AI Tray.app` (or move to `/Applications` first).
4. If macOS still blocks it: **right-click → Open**, or **System Settings → Privacy & Security → Open Anyway**.
5. You should see the usage window and a menu bar icon. Closing the window hides to the tray (does not quit).

> Debug (`flutter run -d macos`) bypasses Gatekeeper; Release `.app` double-click does not. That is why Debug can work while the Release `.app` looks broken.

## Install AI Tray (Windows — Experimental)

Windows is **not** an officially validated platform for v1.0.0 (PD-010). Validation is deferred to backlog item **S-001A**.

When a Windows host is available:

1. `flutter build windows --release`.
2. Run the executable from `build/windows/x64/runner/Release/`.
3. Allow notification / startup permissions if prompted.
4. Locate the **system tray** icon (may be under the overflow chevron).
5. Record results under `docs/stabilization/S-001A-windows-validation.md`.

## First-run checklist

1. Confirm tray icon appears.
2. Open the window and tap **Refresh**.
3. If CLI not found, set absolute path in Settings.
4. Optionally enable **Launch at login**.

## Uninstall

- **macOS:** Quit from tray → move `AI Tray.app` to Trash. Login items: disable in Settings or System Settings → Login Items.
- **Windows:** Quit from tray → delete Release folder / uninstall if packaged later. Remove startup entry via Settings toggle or Task Manager → Startup.
