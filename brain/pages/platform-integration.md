---
id: platform-integration
title: "Platform integration: tray/menu-bar and Copilot sidecar"
category: concept
status: active
tags: [platform, tray, macos, windows, sidecar]
created: "2026-08-09T23:31:29"
updated: "2026-08-09T23:34:01"
---

<!-- compiled_truth -->
## Tray icon (verified: `tray_controller.dart`, `tray_ring_icon_renderer.dart`)

Primary path (v1.4.0+): **`TrayRingIconRenderer.render()`** paints a
color-coded ring PNG at runtime (healthy/high-usage/near-limit/exhausted
bands keyed off `TrayStatusKind` + `sessionUsedPercent`) to a temp file, then
`trayManager.setIcon(path, isTemplate: false)`. Rendered PNGs are cached on
disk per `(kind, 5%-rounded percent bucket)` for 30 minutes to avoid
repainting an unchanged icon every refresh tick.

If rendering throws for any reason, `_applyFallbackIcon()` falls back to
**`TrayIconResolver`**'s static monochrome **template** glyph on macOS
(`isTemplate: true`, so the OS tints it for light/dark menu bars) or a
`.ico` on Windows. `TrayIconResolver`'s per-status color PNGs and its
`macOsAsset` alias are marked in-code as **legacy, not used for the live
glyph** — don't resurrect them as the primary path; they only exist as the
degraded fallback's sibling assets.

Usage is **never encoded directly in the glyph shape** beyond the color
band — the exact percentage lives in the macOS title (`TrayIconResolver
.macOsTitle`, density-gated by `TrayDisplayMode` — adaptive/always-%/icon-only,
default threshold 90%, PD-027) and always in the tooltip.

## macOS menu bar vs Windows system tray

- macOS: template-tinted glyph + optional adaptive `%` title text, both via
  `tray_manager`.
- Windows: `.ico` icon only, no adaptive title text (`iconTitle` is forced
  empty when `!Platform.isMacOS`) — Windows tray communicates status purely
  through the icon and the native tray menu/tooltip.
- Both platforms rebuild the menu (`TrayMenuBuilder.fromStatus`) on every
  status change, driven by the same `RefreshStatus` stream
  (`repository.watchStatus()`).

## GitHub Copilot sidecar transport

`ai_tray/tool/copilot_sdk_bridge` is a separate Node/TypeScript process
communicating with the Flutter app over **NDJSON on stdio** (see
`src/protocol.ts`, `src/host.ts`) — not HTTP, not a persistent socket. The
Flutter side never talks to `@github/copilot-sdk` directly; every quota RPC
goes through this sidecar and is mapped app-side by `CopilotQuotaMapper`.
The sidecar's Node runtime + built bundle are assembled and versioned per
release target, not assumed present on the host — see `stack`.

## Session file access

Session Browser/Detail read `~/.claude/projects/**/*.jsonl` directly off
disk (`IoSessionFileSystem`) — this is real OS filesystem access, not an API
call, and is a different platform-integration surface than the CLI-subprocess
usage pipeline. `JsonlSessionParser` is deliberately tolerant of malformed or
truncated lines (skips and degrades `isComplete` rather than throwing) since
these files can be actively written by a running `claude` process while
being read.

## macOS App Sandbox

Permanently disabled — see `stack` and D-026. This is why the app can spawn
`claude` as a real child process against the real `$HOME` and read the real
`~/.claude/projects/` tree; re-enabling the sandbox would silently break both
the usage pipeline and Session Browser, not just look different.


## Timeline

- time: 2026-08-09T23:31:29
  kind: decision
  summary: "Created this page: Platform integration: tray/menu-bar and Copilot sidecar"
  source: "ai_tray/lib/features/tray, ai_tray/tool/copilot_sdk_bridge"
  affects: [platform-integration]

- time: 2026-08-09T23:34:01
  kind: decision
  summary: "Seed compiled_truth: dynamic ring tray icon is primary path, static template is fallback-only, macOS vs Windows title differences, sidecar NDJSON transport, sandbox rationale"
  source: "tray_controller.dart, tray_ring_icon_renderer.dart, tray_icon_resolver.dart, copilot_sdk_bridge"
  affects: [platform-integration]
