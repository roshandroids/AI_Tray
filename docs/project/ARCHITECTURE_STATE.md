# AI Tray — Architecture State

**Updated:** 2026-08-02
**Primary references:** ADR-001, ADR-002, ADR-003, ADR-004, ADR-005, provider-platform docs,
EP-004 assessment, DEMO_STRATEGY (PD-025 / D-016), Quality CI + Release CD (D-017, superseded
in CI shape by D-023), shared scripts (D-019), personalization (PD-026 / D-021),
`docs/planning/v2-vision-and-roadmap.md` (session management), `docs/ENGINEERING_STANDARD.md`,
`docs/PROJECT_BLUEPRINT.md`

## System shape

```text
Desktop UI / Tray
  → Riverpod presentation state
  → provider-neutral domain models and repository contracts
  → ProviderRegistry / RefreshService
      ├─ ClaudeCliAdapter → Claude CLI → UsageParser
      └─ CopilotProvider → CopilotSdkAdapter → CopilotSdkV1
           → NDJSON sidecar → official @github/copilot-sdk

Session management (v2, separate bounded context — no shared state with the
usage/quota pipeline above beyond re-using ClaudeSessionService and
NotificationGateway):
  Session Browser / Detail UI
  → SessionRepository → IoSessionFileSystem + JsonlSessionParser
       (reads ~/.claude/projects/**/*.jsonl directly — no new database)
  → ResumeController (attended "Resume now") /
    ResumeQueueController → ResumeQueueExecutor
       → SharedPreferencesResumeQueueRepository (bounded, persisted)
       → NotificationGateway (completion notification, click-to-resume
          opens SessionDetailOpenRequestNotifier → SessionDetailPage)
```

## Layer responsibilities

| Layer | Responsibility |
| --- | --- |
| UI | Render shared provider state; no external I/O or business rules |
| State | Async orchestration, persisted selection, retries, user actions |
| Domain | Provider contracts, capabilities, usage/quota/status models |
| Data | CLI/SDK process execution, DTO mapping, cache, repositories |
| Sidecar | Isolate Node SDK/runtime from Flutter and expose versioned NDJSON |

## Provider contracts

- `AIProvider`: metadata, capabilities, parser, raw usage, health
- `ProviderRegistry`: registration, enabled filtering, default resolution
- `ProviderCapabilities`: drives shared UI without provider-specific pages
- `UsageInfo.metrics`: canonical provider-neutral metric list
- `RefreshService`: provider-scoped single-flight, bounded retries, stale-result
  rejection, validation, and cache fallback

## Data flows

### Claude

```text
claude -p /usage --output-format json
→ JSON envelope.result free text
→ UsageParser → UsageValidator → UsageInfo → cache/UI/tray
```

The free-text schema is unstable. Keep fixtures for every observed format.

### GitHub Copilot

```text
CopilotSdkV1 → sidecar → client.rpc.account.getQuota({})
→ SDK DTO → CopilotQuotaMapper → app-owned quota/usage models
→ shared refresh/cache/dashboard
```

The quota RPC is experimental. No SDK DTO may escape the adapter/mapping
boundary. Graceful degradation is required.

## Persistence and resilience

- SharedPreferences stores settings, selected provider, LKG usage, and
  personalization (`themeMode`, `themePreset`, `fontPreset`, `appIconPreset`)
  and tray density (`trayDisplayMode`, `trayPercentThreshold`).
- Cache is provider-scoped; legacy Claude cache migration is preserved.
- Refresh state distinguishes loading, live, cached, soft failure, hard failure.
- Async UI actions check lifecycle safety before navigation/feedback.
- Logs are structured and secret-safe with provider/category metadata.

## Session management (v2 M1/M2)

- Modules: `features/sessions/{browser,detail,resume,queue}/`,
  `features/sessions/data/{fs,parsers,process}/`, `core/notifications/`
- Read path is JSONL-only: `IoSessionFileSystem` enumerates
  `~/.claude/projects/**/*.jsonl`; `JsonlSessionParser` tolerates malformed
  and truncated lines (skips and degrades `isComplete`, never throws)
- `SessionSummary.messageCount` is a cheap byte-size estimate until the
  detail page does a full parse — documented on the model, not a bug
- Attended resume (`ResumeController`) always runs `forkSession: false`
  (continue in place); the Resume Queue defaults to `forkSession: true`
  (unattended execution never silently mutates a transcript the user might
  be continuing by hand elsewhere) — this asymmetry is deliberate
- `ResumeQueueExecutor` is single-flight, checks `cwd` existence
  immediately before running (never creates/substitutes a missing
  directory), and notifies via `NotificationGateway` on every terminal
  outcome with a click-through to `SessionDetailPage`
- Mandatory budget cap on every queued item — no "run without a cap" path
- No cooperative cancellation of an in-flight resume yet (users can cancel
  a `pending` item or clear a finished one; a `running` item must finish)
- Non-goals for the current scope (see `docs/planning/v2-vision-and-roadmap.md`):
  Resume Scheduler, Session Analytics, multi-provider session support,
  streaming/live progressive resume view

## Personalization (PD-026 / ADR-005)

- Module: `ai_tray/lib/theme/`
- `AppTheme` builds M3 themes via FlexColorScheme custom `FlexSchemeColor` only
- `TrayColorTokens` / `TrayTypography` derived for existing UI call sites
- `PersonalizationController` applies theme mode, color preset, font, and icon
  immediately; icon switcher is unsupported on desktop by default

## Distribution

- Flutter 3.38.9 / Dart 3.10.x
- Node sidecar toolchain is pinned and assembled per release target.
- Release artifacts: macOS arm64 and Windows x64.
- **No Flutter Web platform** for the product app (tray/CLI/sidecar native).
- **CI (Quality CI + Release CD / EP-004A / D-017, CI shape superseded by
  D-023):** `.github/workflows/{quality,documentation,release-pr,release,
  maintenance}.yml` are thin callers into `roshandroids/platform-ci@v1`
  reusable workflows, configured by root `ci.yaml`. `quality.yml` runs on
  every PR/push to `main` (Ubuntu only, no desktop build); `release-pr.yml`
  additionally builds macOS+Windows when the PR head branch starts with
  `release/`; `release.yml` builds+packages+publishes on a version tag or
  manual dispatch. `platform-ci` in turn shells out to this repo's own
  `scripts/ci/*.sh` (via the thin `scripts/*.sh` local-dev wrappers) —
  `platform-ci` is pinned to a mutable `@v1` tag, not a commit SHA, so its
  behavior can drift independently of a change in this repo. Optional
  Lefthook — see `docs/devops/LOCAL_DEVELOPMENT.md`.
- **Showcase demos:** `showcase/demos.json` lists product `main` (`type: desktop`).
  Callable `reusable-flutter-web-demo.yml` is unused by AI Tray.
  See `docs/devops/DEMO_STRATEGY.md`.
- **Release notes (D-020):** `CHANGELOG.md` is SoT; `publish.sh` regenerates
  `ai_tray/assets/release_history.json` for Settings About / Diagnostics;
  runtime version/build via `package_info_plus`. Never hand-edit the JSON.

## Invariants

1. No direct external I/O from UI.
2. No undocumented provider endpoints or interactive-output scraping.
3. No invented percentages or conflicting state emissions.
4. Preserve Claude behavior when adding providers.
5. Shared pages and cards must remain capability-driven.

## Technical debt

- Transitional compatibility directories (~35 alias files) under provider
  `core/`, `domain/`, `data/copilot/`, and `copilot/` — addressed by ADR-004
  targeted cleanup (import canonicalize + deprecate), not a full rewrite.
  Still open; not blocking correctness.
- Signing, notarization, and Windows hardware validation remain open
  (Windows stays Experimental). Sandbox strategy is resolved — App Sandbox
  is deliberately disabled; see `Runner/Release.entitlements` for the
  documented rationale.
- The v2 vision doc (§16) proposed ADR-005 through ADR-010 for session/resume
  decisions, written before ADR-005 was claimed by the personalization
  decision (2026-07-31). Those session-management ADRs were never actually
  opened despite M1/M2 shipping — renumber from ADR-006 onward whenever they
  are written, and treat this architecture doc plus
  `docs/planning/v2-vision-and-roadmap.md` as the source of truth for
  session-management rationale until then.
- `platform-ci@v1` is a mutable tag dependency, not pinned to a commit SHA —
  low risk today, worth tightening before or shortly after going public so a
  third-party change to that tag can't silently alter release behavior.
