# Installation Guide — AI Tray (v1.3.3)

## Requirements

- **macOS** 11+ (arm64) — primary supported platform
- **Windows** 10+ (x64) — **Experimental** ([PD-010](../stabilization/PD-010-defer-windows.md)); CI-verified to build and package, but not yet validated on real Windows hardware
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
  (for the GitHub Copilot provider, the `gh` CLI with Copilot access instead)
- Active Claude.ai authentication (`claude auth login`)

## Download a release (recommended)

Grab `AI-Tray-macOS-arm64.zip` or `AI-Tray-Windows-x64.zip` from
[GitHub Releases](https://github.com/roshandroids/AI_Tray/releases). Then
follow the Gatekeeper step below (macOS) or run the extracted executable
(Windows).

## Install Claude Code CLI

1. Install Claude Code per Anthropic docs.
2. Verify:

```bash
claude --version
claude auth status
```

3. If `claude` is missing from PATH for GUI apps (common with Homebrew), note the absolute path (e.g. `/opt/homebrew/bin/claude`) for Settings → CLI path.

## Build from source (macOS)

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

## Build from source (Windows — Experimental)

Windows is CI-verified to build and package but has no recorded real-hardware
validation yet (PD-010). Validation is tracked under backlog item **S-001A**.

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
