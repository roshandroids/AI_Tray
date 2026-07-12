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

1. Build or obtain `AI Tray.app` (see [Packaging](RH-003-packaging.md)).
2. Move to `/Applications` (optional).
3. Open the app (first open may require **System Settings → Privacy & Security** approval for unsigned builds).
4. Look for the **menu bar** icon (window may start hidden).
5. Use tray menu → **Open** or **Settings**.

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
