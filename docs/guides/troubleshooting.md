# Troubleshooting Guide — AI Tray (v1.0.0-rc.1)

## No tray / menu bar icon

1. Confirm the process is running (Activity Monitor / Task Manager → AI Tray).
2. Quit and relaunch.
3. On Windows, check the tray overflow (^) area.
4. Rebuild after RC1 asset fix if using an older build without `assets/tray/`.

## “CLI missing” / cannot find Claude

1. In Terminal: `which claude` / `where claude`.
2. Paste absolute path into Settings → Claude CLI path.
3. Restart AI Tray (GUI apps often have a shorter PATH than Terminal).

## Authentication / login errors

1. Run `claude auth status`.
2. If logged out: `claude auth login`.
3. Refresh from AI Tray.
4. Auto-refresh pauses on persistent auth failures (by design).

## Usage stuck or “unavailable”

Often **Shape B**: CLI returned contribution analytics without session % (intermittent under load).

1. Wait and Refresh again.
2. Increase refresh interval.
3. Confirm Terminal still gets Shape A sometimes:  
   `claude -p '/usage' --output-format json`
4. Cached Shape A should remain visible when available — percentages are never invented.

## Timeouts

1. Claude CLI may be slow or hung — wait for retry/backoff.
2. Check CPU / VPN / sleeping disk.
3. Retry Refresh; if persistent, restart Claude-related sessions and AI Tray.

## Notifications not appearing

1. Grant notification permission in OS settings for AI Tray.
2. Lower the threshold temporarily to test.
3. Confirm usage actually crossed the threshold after a successful Shape A parse.
4. Note: `local_notifier` uses older macOS notification APIs (deprecation warnings at build time).

## Launch at login not working

1. Toggle off/on in Settings.
2. macOS: System Settings → General → Login Items — confirm AI Tray listed.
3. Windows: Task Manager → Startup apps.
4. Unsigned builds may be blocked by OS policy.

## Window disappeared

Close hides to tray. Use tray → **Open**. Tray → **Quit** to fully exit.

## Auto-refresh stopped after CLI / login errors

By design (ADR-002): missing Claude CLI or expired auth **pauses** auto-refresh. Fix the CLI path or run `claude auth login`, then tap **Refresh** (manual refresh clears the pause).

## Windows issues

Windows is **Experimental** for v1.0.0 ([PD-010](../stabilization/PD-010-defer-windows.md)). Prefer macOS for supported use; track validation under backlog **S-001A**.

## Still stuck

Collect:

- `claude --version`
- `claude auth status`
- Approximate time of failure
- Whether Terminal `/usage` was Shape A or B
- Platform + AI Tray version (`1.0.0-rc.1`)

File under Known Issues / dogfood log for the Product Owner.
