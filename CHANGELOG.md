# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·  
Versioning: [SemVer](https://semver.org) on `ai_tray/pubspec.yaml` (single source of truth).

## [Unreleased]

## [1.5.0] — 2026-08-07

### Added

**Session Detail**
- **Resizable panels:** Continue Conversation, Queue Task, and Advanced can
  now be resized by drag handle (160px–50% of window height); height and
  expanded/collapsed state persist across launches.

### Fixed

**Session Detail**
- **Back navigation:** the V3 redesign dropped Session Detail's way back to
  the Sessions list — restored via the page header's back button, which now
  also carries the session name, live-status badge, and project path
  (previously duplicated in the page body).
- **Accordion spacing:** Queue Task and Advanced used Flutter's stock
  `ExpansionTile`, whose header padding and title styling didn't match every
  other card's. Both — and all other expandable panels app-wide (Settings
  presets, session cards, About's release history, Logs' grouped list) —
  now share one `TrayAccordion` component with consistent spacing and a
  smooth expand/collapse animation.

**Settings**
- **Personalization search:** the Color Theme, Font, and App Icon pickers
  no longer discard in-progress search text when expanded or collapsed. The
  pickers were faking controlled expand/collapse with a key trick that
  destroyed and rebuilt the whole picker — including the search field — on
  every toggle.

## [1.4.0] — 2026-08-05

### Added

**Navigation & shell (V3)**
- **App shell:** persistent `AppShell` (NavigationRail + IndexedStack)
  replaces ad hoc `Navigator.push`.
- **Command palette:** global Cmd+K palette sharing one action registry with
  shell navigation (switch provider, continue last session, queue task,
  refresh, open logs/diagnostics/about, toggle theme), plus arrow-key
  highlight navigation and a keyboard shortcuts dialog.
- **Screen redesign:** all seven screens rebuilt work-first — Dashboard leads
  with Continue Last Session / Queue a Task / Recent Sessions / Recent Queue;
  Sessions groups by project with the current session pinned; Session Detail
  puts Continue Conversation first with technical fields under Advanced;
  Queue gained a live active/history split with a cancel action; Logs became
  an explorer (provider filters, expandable metadata, JSON export); Settings
  gained global keyword search; About became its own product page.
- **Tray icon:** dynamic color-coded ring by usage band
  (healthy/high-usage/near-limit/exhausted), dashed when offline, replacing
  the static monochrome glyph and manual opacity-pulse timer.

**Responsive foundations & dashboard (V4)**
- **Shared primitives:** breakpoint-aware shell and components
  (`ResponsiveGrid`, `PageHeader`, `EmptyState`, `StatusPresentation`,
  `SessionCard`/`ProjectCard`, `ConfirmationDialog`, `InlineHelp`) unify
  status colors/labels and page headers across all 8 pages.
- **Productivity Coach:** Dashboard banner surfacing provider errors, usage
  exhaustion, queue failures, and notifications-off; tappable Provider Health
  cards deep-link into Diagnostics.

**Onboarding, tour & help**
- **First-launch onboarding:** welcome, provider choice, CLI check, feature
  tour, and ready screens.
- **Product Tour:** coach-mark overlay spotlighting the nav rail, gated on
  reduced motion, restartable from the command palette and Settings.
- **Help Center:** searchable page (Queue, Budget cap, Providers,
  Diagnostics, Notifications, Sessions topics), reachable from Settings and
  the command palette.

**Sessions, queue & notifications**
- **Session management (V2 Milestone 1 + 2):** Session Browser and Session
  Detail views, reading directly from `~/.claude/projects/**/*.jsonl` (no new
  database); manual "Resume now" action; a bounded, persisted Resume Queue —
  every queued item requires a budget cap, defaults to forking the session
  rather than continuing in place, and notifies on completion; clicking the
  notification opens that session's detail page directly; a cancel/remove
  action for queue items (pending items can be cancelled; finished items
  cleared; a running item can't be removed until it finishes).
- **Notifications page:** persisted history (`NotificationHistoryRepository`),
  recording every threshold/queue-completion/test notification through one
  gateway choke point (`NotificationGateway`, backed by `local_notifier`),
  replacing `TrayController`'s direct threshold alert.

**Personalization**
- **Themes:** FlexColorScheme branded presets, bundled fonts, and app-icon
  architecture (PD-026 / ADR-005).
- **Menu-bar density:** adaptive title — quiet by default, reveals a
  percentage only past a configurable threshold — plus a monochrome
  template glyph (PD-027).

**Provider quality (EP-002)**
- Phase 3 UI quality coverage: accessibility/state widget tests and provider
  UI golden baselines for Claude and GitHub Copilot; Copilot screenshots plus
  provider docs and the EP-002 implementation report.

### Changed
- **Diagnostics & Settings:** `InfoRow` gains an optional repair-action slot
  (Force Refresh, Parser/Cache invalid-state repair); theme/font pickers
  render bordered preview cards instead of thin rows.
- **Logs:** grouped view now virtualizes rows once a group exceeds 30
  entries, instead of eagerly mounting every row via `ExpansionTile.children`.
- **Sessions:** list sorted most-recently-active first, instead of filesystem
  enumeration order.
- **Providers:** selector disables while selection persistence is busy and
  surfaces a retryable save-failure banner on the shared dashboard.
- **CI:** migrated from repo-owned Actions workflows calling `./scripts/*.sh`
  directly to reusable workflows from `roshandroids/platform-ci@v1`,
  configured by root `ci.yaml`; a new `release-pr.yml` builds macOS/Windows
  for any PR whose head branch starts with `release/`; workflow calls are
  now pinned to a resolved commit SHA instead of the mutable `@v1` tag, so an
  upstream change can't silently alter this repo's release behavior.

### Removed
- 12 unreferenced files: 10 provider-platform compatibility re-export shims
  under `core/`/`data/copilot/` that nothing imported (not even the
  actively-used `domain/` compatibility layer, which is separate, real,
  still-open technical debt tracked under PD-024 — left untouched), and 2
  widget files (`terminal_chrome.dart`, `tray_status_pill.dart`) whose
  classes were never instantiated anywhere.

### Fixed
- **Accessibility:** Semantics coverage added to Help Center's result list,
  the onboarding flow's current step, and the coach-mark callout (announced
  as a live region).
- **Rendering:** `SectionCard`'s `ListTile` children now sit above a
  `Material` ancestor, so ink splashes render on Settings Advanced rows,
  Dashboard, Diagnostics, and About instead of being silently swallowed.
- **macOS:** App Sandbox is now disabled. It virtualized `$HOME` for the app
  and every spawned `claude`/provider CLI process, making Session Browser
  (and any provider CLI call) blind to the real `~/.claude` tree regardless
  of entitlement exceptions. Distribution remains signed/notarized GitHub
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
