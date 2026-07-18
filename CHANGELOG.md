# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·  
Versioning: [SemVer](https://semver.org) on `ai_tray/pubspec.yaml` (single source of truth).

## [Unreleased]

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
