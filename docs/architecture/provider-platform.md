# Provider Platform Architecture

**Decision:** PD-021 Multi-Provider Architecture  
**Status:** Implemented (framework and Copilot scaffold)  
**Date:** 2026-07-16

## Architecture diagram

```mermaid
flowchart LR
  ProviderSelector --> ProviderSelectionNotifier
  ProviderSelectionNotifier --> ProviderRegistry
  ProviderRegistry --> ClaudeCliAdapter
  ProviderRegistry --> CopilotProvider
  ClaudeCliAdapter --> UsageParser
  CopilotProvider --> CopilotAdapter
  CopilotProvider --> CopilotUsageParser
  ProviderRegistry --> RefreshService
  RefreshService --> UsageRepository
  UsageRepository --> DashboardDataMapper
  DashboardDataMapper --> DashboardData
  DashboardData --> SharedMetricCards
  UsageRepository --> TrayAndDiagnostics
```

The registry is the only provider catalog. Shared presentation consumes provider
metadata, capabilities, `DashboardData`, and `ProviderStatus`; it never checks a
concrete provider ID.

## Refactoring summary

### Provider contracts

- `AIProvider` extends the existing raw usage/health port with display metadata,
  capabilities, parser contract, availability, and provider-authored fallback
  copy.
- `ProviderRegistry` owns deterministic registration, enabled filtering,
  duplicate detection, default resolution, and disabled-provider rejection.
- `ProviderUsageParser` normalizes provider-specific payloads into
  `ProviderUsageCandidate`.
- `ProviderStatus` is the shared status model used beside normalized dashboard
  metrics.

### Claude migration

`ClaudeCliAdapter` now conforms to `AIProvider`. The implementation retains:

- `claude -p /usage --output-format json`
- `claude --version`
- `claude auth status --json`
- Existing Shape A / Shape B parsing
- Existing validation, retry, auth-probe, LKG cache, and scheduling behavior
- Existing `aiProviderPortProvider` and `usageRepositoryProvider` compatibility
  names

No Claude parser fixture or command contract changed.

### Capability-driven UI

`DashboardDataMapper` maps canonical usage into `DashboardMetric` values only
when declared by `ProviderCapabilities`. The dashboard loops over those metrics
using the shared `MetricCard`. Status, source labels, health visibility, settings
labels, diagnostics, tray labels, and empty-state copy use provider metadata.

The provider selector receives `ProviderRegistry.enabledProviders`. Copilot is
registered but disabled, so Claude remains the only selectable and active
provider in this phase.

## Updated folder structure

```text
lib/features/providers/
├── data/
│   ├── claude/
│   │   └── claude_cli_adapter.dart
│   ├── copilot/
│   │   ├── copilot_adapter.dart
│   │   ├── copilot_provider.dart
│   │   └── copilot_usage_parser.dart
│   └── process/
├── domain/
│   ├── models/
│   │   ├── provider_capabilities.dart
│   │   ├── provider_id.dart
│   │   ├── provider_status.dart
│   │   └── provider_usage_candidate.dart
│   ├── ports/
│   │   ├── ai_provider.dart
│   │   ├── ai_provider_port.dart
│   │   └── provider_usage_parser.dart
│   └── services/
│       └── provider_registry.dart
└── presentation/
    ├── provider_selection_controller.dart
    └── widgets/
        └── provider_selector.dart

lib/features/usage/domain/
├── models/
│   └── dashboard_data.dart
└── services/
    └── dashboard_data_mapper.dart
```

## Copilot scaffold and limitations

`CopilotProvider` is intentionally disabled. Its adapter:

- Starts no process
- Makes no network request
- Returns an explicit not-implemented failure

Its parser implements the shared contract but returns an invalid candidate
marked `copilot_parser_not_implemented`.

Unknowns that block activation:

1. No stable Copilot subscription usage payload is defined.
2. Authentication and executable discovery are not selected.
3. Session/weekly metric semantics and reset fields are unknown.
4. Cache namespace and provider-specific settings are not activated.

Implementing those data contracts and changing `enabled`/capabilities is
provider work; the selector and dashboard components require no Copilot branch.

## Migration notes

### Current release

- Default and active provider remain `ProviderId.claude`.
- Existing settings key `settings_v1_claudeBinaryPath` remains unchanged.
- Existing Claude LKG key `usage_lkg_v1` remains unchanged.
- No user preference migration is required.
- No cache is cleared or rewritten.

### Activating a second provider

Before enabling Copilot or another provider:

1. Implement its adapter and parser with fixtures.
2. Declare only verified capabilities.
3. Add provider-scoped settings and cache keys.
4. Migrate `usage_lkg_v1` as Claude-only data without deleting it until a
   successful scoped write.
5. Persist active provider selection.
6. Partition refresh timers/status streams if simultaneous provider refresh is
   required.

The current phase deliberately keeps one active refresh loop to avoid changing
Claude scheduling or stale-cache behavior.

## Regression results

Executed from `ai_tray/` on 2026-07-16:

- `dart format lib test` — clean
- `flutter analyze --fatal-infos` — no issues
- `flutter test --exclude-tags golden,screenshot` — 75 passed
- `flutter test --tags golden` — 3 passed

Coverage added:

- Registry enabled filtering, duplicate rejection, and disabled lookup
- Provider selection validation
- Capability-filtered dashboard metrics
- Shared provider status mapping
- Copilot no-op adapter and parser scaffold
- Enabled-only provider selector rendering

Existing Claude adapter, parser, refresh, repository, cache, tray, stability,
smoke, theme, and golden tests remain passing.

