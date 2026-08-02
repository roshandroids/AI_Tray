# Troubleshooting Guide — AI Tray (v1.3.3)

## No tray / menu bar icon

1. Confirm the process is running (Activity Monitor / Task Manager → AI Tray).
2. Quit and relaunch.
3. On Windows, check the tray overflow (^) area.
4. Rebuild after RC1 asset fix if using an older build without `assets/tray/`.

## “CLI missing” / cannot find Claude

1. In Terminal: `which claude` / `where claude`.
2. Paste absolute path into Settings → Claude CLI path.
3. Restart AI Tray (GUI apps often have a shorter PATH than Terminal).

## App launches then immediately quits / “Lost connection to device”

**Cause:** Hiding the usage window at startup (tray mode) while macOS was configured to terminate after the last window closed.

**Fix:** `AppDelegate.applicationShouldTerminateAfterLastWindowClosed` returns `false`. Rebuild and relaunch.

If Flutter still prints `Failed to foreground app; open returned 1`, that is tooling noise when the window starts hidden — check the menu bar for the tray icon.

## “macOS blocked launching Claude CLI” / Operation not permitted

**Current model:** App Sandbox is **disabled** (see `Runner/Release.entitlements`
for the full rationale). Sandbox virtualized `$HOME` for the app and every
spawned `claude`/provider CLI process, which made Session Browser — and any
CLI call — blind to your real `~/.claude` tree regardless of entitlement
exceptions. Distribution is via signed/notarized GitHub Releases, not the Mac
App Store, so sandboxing bought nothing here.

If you still see this error on a current build:

1. Pull latest / rebuild (`flutter clean && flutter run -d macos` or Release rebuild).
2. Confirm you're not running a build from before the sandbox was disabled —
   check `Runner/Release.entitlements` doesn't contain
   `com.apple.security.app-sandbox`.
3. Set an absolute Claude path in Settings if `claude` genuinely isn't
   resolvable from the app's inherited PATH.

## macOS “Files and Folders” / access to many folders

**Cause (historical, RC1-era):** Probing the full inherited `PATH` with
`existsSync` could touch Desktop/Documents/Downloads and trigger TCC prompts
under the old sandboxed build. With App Sandbox now disabled and executable
resolution scoped to known CLI prefixes (`/opt/homebrew/bin`,
`/usr/local/bin`, …) rather than every `PATH` entry, this should no longer
occur on a current build.

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

## Launch at login not working / MissingPluginException

**Cause:** On macOS, `launch_at_startup` is not an auto-registered plugin — it needs a method channel in `MainFlutterWindow.swift`.

**Fix (dogfood):** Channel wired via `SMAppService` (macOS 13+). Full rebuild required (`flutter run -d macos` / Release rebuild). Hot reload is not enough.

If toggle still fails: System Settings → General → Login Items — approve AI Tray if prompted (unsigned builds may be restricted).

## Launch at login not working

1. Toggle off/on in Settings after a full rebuild.
2. macOS: System Settings → General → Login Items — confirm AI Tray listed.
3. Windows: Task Manager → Startup apps.
4. Unsigned builds may be blocked by OS policy.

## Release build “does nothing” / blocked when opening `.app`

Two separate issues are common:

### 1. Gatekeeper blocks unsigned Release builds

`flutter run` (Debug) is allowed; double-clicking an unsigned Release `.app` may be **rejected**.

```bash
xattr -cr "path/to/AI Tray.app"
# or: right-click the app → Open → Open
```

Confirm with: `spctl --assess --type execute -v "AI Tray.app"` (local dogfood builds often show `rejected` until opened once via right-click).

### 2. Finder PATH cannot see Homebrew `claude`

GUI apps do not get your Terminal PATH. Rebuilds now prepend `/opt/homebrew/bin` (and resolve `claude` absolutely). If usage still fails, set **Settings → Claude CLI path** to `/opt/homebrew/bin/claude`.

## Window disappeared

Close hides to tray. Use tray → **Open**. Tray → **Quit** to fully exit.

## Release build “does nothing” when opened

**Cause:** Older builds hid the window and skipped the Dock on startup, so double-clicking `AI Tray.app` looked broken while the process ran only in the menu bar.

**Fix (dogfood):** Cold launch now shows and focuses the usage window. Closing still hides to the tray.

## Auto-refresh stopped after CLI / login errors

By design (ADR-002): missing Claude CLI or expired auth **pauses** auto-refresh. Fix the CLI path or run `claude auth login`, then tap **Refresh** (manual refresh clears the pause).

## Resume Queue item stuck as "failed" / working directory missing

The executor checks the queued item's working directory immediately before
running and fails fast rather than creating or substituting a path — if the
project folder was moved, renamed, or deleted since you queued it, the item
will fail every time. Remove the stale item and re-queue from the session's
current location.

## Resume Queue item stuck as "running"

There's no cooperative cancellation of an in-flight resume yet — if the
underlying `claude` process is genuinely hung, you'll need to quit and
relaunch AI Tray. The remove/cancel button is intentionally disabled while
an item is `running`.

## Clicking a "resume completed" notification does nothing

Confirm notification permission is granted for AI Tray in OS settings — if
the OS drops the click event, AI Tray never gets called. If permissions look
fine but nothing happens, check whether the session that resumed still
appears in the Session Browser (a moved/deleted project directory can leave
the click with nothing valid to open).

## Windows issues

Windows is **Experimental** ([PD-010](../stabilization/PD-010-defer-windows.md)). It's CI-verified to build and package, but has no recorded real-hardware validation yet — prefer macOS for daily use; track validation under backlog **S-001A**.

## Still stuck

Collect:

- `claude --version`
- `claude auth status`
- Approximate time of failure
- Whether Terminal `/usage` was Shape A or B
- Platform + AI Tray version (`1.3.3`)

File under Known Issues / dogfood log for the Product Owner.
