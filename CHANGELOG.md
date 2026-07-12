# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·  
Versioning: [SemVer](https://semver.org) on `ai_tray/pubspec.yaml` (single source of truth).

## [Unreleased]

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
