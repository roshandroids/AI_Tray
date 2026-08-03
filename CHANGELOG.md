# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·  
Versioning: [SemVer](https://semver.org) on `ai_tray/pubspec.yaml` (single source of truth).

## [Unreleased]

### Added
- **Session management (V2 Milestone 1 + 2):** Session Browser and Session
  Detail views, reading directly from `~/.claude/projects/**/*.jsonl` (no new
  database). Manual "Resume now" action. A bounded, persisted Resume Queue —
  every queued item requires a budget cap, defaults to forking the session
  rather than continuing in place, and notifies on completion; clicking the
  notification opens that session's detail page directly. A cancel/remove
  action for queue items (pending items can be cancelled; finished items
  cleared; a running item can't be removed until it finishes).
- `NotificationGateway` abstraction with a real `local_notifier`-backed
  implementation, migrated `TrayController`'s threshold alert onto it.
- FlexColorScheme branded personalization: selectable theme presets, bundled
  fonts, and app-icon architecture (PD-026 / ADR-005).
- Adaptive menu-bar title density — quiet by default, reveals a percentage
  only past a configurable threshold — plus a monochrome template glyph
  (PD-027).
- EP-002 Phase 3 UI quality coverage: accessibility/state widget tests and
  provider UI golden baselines for Claude and GitHub Copilot.
- Copilot screenshots plus provider docs and the EP-002 implementation report.

### Changed
- Provider selector disables while selection persistence is busy and surfaces a
  retryable save-failure banner on the shared dashboard.
- Session list is now sorted most-recently-active first, instead of
  filesystem enumeration order.
- CI migrated from repo-owned Actions workflows calling `./scripts/*.sh`
  directly to reusable workflows from `roshandroids/platform-ci@v1`,
  configured by root `ci.yaml`; a new `release-pr.yml` builds macOS/Windows
  for any PR whose head branch starts with `release/`.

### Fixed
- macOS App Sandbox is now disabled. It virtualized `$HOME` for the app and
  every spawned `claude`/provider CLI process, making Session Browser (and
  any provider CLI call) blind to the real `~/.claude` tree regardless of
  entitlement exceptions. Distribution remains signed/notarized GitHub
  Releases, not the Mac App Store, so sandboxing had no upside here.

## [1.3.3] — 2026-07-17

### Fixed
- Claude usage parsing no longer fails with `parserFailure` when the CLI omits
  the session reset suffix (e.g. `Current session: 0% used`); the session reset
  clause is now optional, matching the weekly-line behavior.

### Changed
- Release pipeline no longer builds or publishes macOS x64 (Rosetta/Intel);
  GitHub Releases ship macOS arm64 and Windows x64 only.

## [1.3.2] — 2026-07-17

### Fixed
- macOS release jobs now select their Copilot sidecar payload explicitly,
  preventing Rosetta x64 builds from requesting the arm64 payload.

## [1.3.1] — 2026-07-17

### Fixed
- Windows release assembly now stages Copilot sidecar payloads on the output
  volume, preventing cross-drive `EXDEV` rename failures in GitHub Actions.

## [1.3.0] — 2026-07-17

### Added
- GitHub Copilot provider foundation with official SDK sidecar, quota mapping,
  health/diagnostics, and provider-scoped refresh/cache isolation (EP-002).
- Shared multi-provider dashboard surfaces: persisted provider selection,
  capability-driven metric cards, circular usage indicator states, Copilot
  settings/diagnostics/logs filters, and actionable empty states.
- Deterministic macOS and Windows Copilot sidecar packaging in CI/release.

### Changed
- Provider registry and usage pipeline now support normalized provider contracts
  while preserving the existing Claude Code experience.

## [1.2.0] — 2026-07-13

### Added
- Official design system tokens and shared desktop components (PD-021).
- Circular macOS tray usage ring; Settings left rail; redesigned Diagnostics/Logs.

### Changed
- JetBrains Mono typography and GitHub-dark / intentional light palettes throughout.

## [1.1.0] — 2026-07-13

### Added
- Diagnostics page and in-app log viewer with export / copy (PD-020).
- Dynamic macOS tray icons with status badges (live / cached / error / refreshing / waiting).

### Changed
- Terminal-inspired developer UX: ASCII separators, dense dashboard, developer settings (PD-020).
- Status colors aligned to neon Live/Cached/Error/Refreshing palette.

## [1.0.0] — 2026-07-12

### Added
- GitHub Actions CI (Format, Analyze, Test, Build macOS) and tagged Release workflow (PD-016).
- One-command release script: `scripts/release/publish.sh`.
- Rich tray dashboard with session/week usage at a glance (PD-015).

### Changed
- Claude-inspired visual refresh and dynamic light/dark/system theming (PD-013, PD-014).

## [1.0.0-rc.2] — 2026-07-12

### Added
- Dogfooding policy (PD-011) and RC2 release packaging.
- Release `.app` sandbox and PATH fixes for packaged macOS builds.

### Fixed
- Gatekeeper guidance for unsigned Release builds.
- App lifecycle: tray persists when main window is hidden.

## [1.0.0-rc.1] — 2026-07-12

### Added
- Claude Code usage pipeline: CLI adapter, parser, validator, cache, refresh service.
- macOS menu bar / Windows system tray shell with settings and usage dashboard.
- Stabilization suite: parser hardening, long-running refresh tests, packaging docs.

[1.0.0-rc.2]: https://github.com/roshandroids/AI_Tray/compare/v1.0.0-rc1...v1.0.0-rc.2
[1.0.0-rc.1]: https://github.com/roshandroids/AI_Tray/releases/tag/v1.0.0-rc1
