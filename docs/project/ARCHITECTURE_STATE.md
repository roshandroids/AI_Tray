# AI Tray — Architecture State

**Updated:** 2026-07-31
**Primary references:** ADR-001, ADR-002, ADR-003, ADR-004, ADR-005, provider-platform docs,
EP-004 assessment, DEMO_STRATEGY (PD-025 / D-016), Quality CI + Release CD (D-017),
shared scripts (D-019), personalization (PD-026 / D-021), `docs/ENGINEERING_STANDARD.md`,
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
- **CI (Quality CI + Release CD / EP-004A / D-017 / D-019):** `quality.yml` on
  PR/main invokes `./scripts/format.sh`, `analyze.sh`, `test.sh`,
  `check.sh workflows` (Ubuntu only; no desktop); `release.yml` calls
  `./scripts/build.sh` + `package.sh` on tag/dispatch only; `.ci/config`
  `CI_MODE` is local preference only (Actions ignores it). Optional Lefthook
  — see `docs/devops/LOCAL_DEVELOPMENT.md`.
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
- Notification dependency/migration state must be reconciled with current
  `pubspec.yaml` before further notification work.
- Signing, notarization, sandbox strategy, and Windows hardware validation
  remain open (Windows stays Experimental).
