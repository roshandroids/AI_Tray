---
slug: stack
title: Tech stack
role: tech-stack choices
updated: "2026-08-09T23:30:07"
---

# Tech stack

## Application

- Flutter (Dart SDK `^3.10.8`), desktop-only targets: macOS arm64 (primary,
  supported) and Windows x64 (experimental).
- State management: **`flutter_riverpod`** — `Notifier`/`AsyncNotifier`/
  `AsyncValue` only, no legacy `StateNotifier` (hard constraint, see
  `AGENTS.md`).
- `flex_color_scheme` — branded theme presets (custom `FlexSchemeColor` seeds
  only, no built-in Flex schemes) plus bundled offline fonts, per ADR-005.
- `tray_manager` / `window_manager` — menu bar / system tray + window
  lifecycle.
- `local_notifier` — desktop notifications, routed through the single
  `NotificationGateway` choke point (no other call site sends a notification
  directly).
- `shared_preferences` — settings, provider-scoped Last-Known-Good usage
  cache, personalization, tray density, and the Resume Queue's persisted
  store. No SQL database anywhere in the app.
- `package_info_plus` — runtime version/build number surfaced in Settings
  About / Diagnostics.

## Version source of truth

**`ai_tray/pubspec.yaml`** is the single source of truth for the app version
(SemVer). **`CHANGELOG.md`** is the single source of truth for release notes
(Keep a Changelog format). `ai_tray/assets/release_history.json` is
*generated* from the changelog by `scripts/release/sync_release_history.sh`
during publish — never hand-edit it (D-020). Don't hardcode a specific
version or test count anywhere in this brain; read the files above instead.

## GitHub Copilot sidecar

- `ai_tray/tool/copilot_sdk_bridge/` — TypeScript/Node package wrapping the
  official `@github/copilot-sdk`.
- Communicates with the Flutter app over **NDJSON** on stdio (see
  `src/protocol.ts`, `src/host.ts`).
- A versioned Node runtime + the built sidecar are assembled and bundled per
  release target (`scripts/assemble_sidecar.mjs`) — not a dev-machine-only
  dependency.
- No SDK DTO may cross the adapter/mapping boundary into app-owned models
  (`CopilotQuotaMapper` is the only place that translates SDK shapes).

## CI/CD

- Thin GitHub Actions workflows (`.github/workflows/{quality,documentation,
  release-pr,release,maintenance}.yml`) call into external reusable
  workflows from **`roshandroids/platform-ci`**, configured by root
  `ci.yaml`.
- `platform-ci` calls are pinned to a **resolved commit SHA**, not the
  mutable `@v1` tag (D-027 closed the D-023 follow-up — if you find a doc
  still saying "pinned to mutable `@v1`, tracked as tech debt," that's the
  stale D-023 wording; D-027 is the current state). Bump the SHA
  deliberately when `platform-ci` needs to change; check
  `.github/workflows/quality.yml` for the SHA actually in effect rather than
  trusting any doc's copy of it.
- Quality CI (analyze + test) runs Ubuntu-only on every PR/push to `main`.
  Desktop (macOS/Windows) builds run only on a `release/**`-prefixed PR head
  branch or on tag/`workflow_dispatch` — never on a plain feature PR.
- `scripts/*.sh` are the local-dev entrypoints and are exactly what
  `platform-ci` shells out to via `scripts/ci/*.sh` — so a local
  `./scripts/check.sh` run reproduces what CI does.

## Distribution

- Release artifacts: macOS arm64 `.zip` and Windows x64 `.zip` only (no
  macOS Intel).
- macOS App Sandbox is **permanently disabled** — sandbox would virtualize
  `$HOME` for both the app and every spawned `claude` child process, making
  the usage pipeline and Session Browser blind to real user data (D-026; see
  `Runner/Release.entitlements` for the full rationale).
- macOS build is not yet signed/notarized as of the last verified check —
  confirm current status against `docs/release/` before assuming otherwise.
