# AI Tray — Architecture State

**Updated:** 2026-07-19  
**Primary references:** ADR-001, ADR-002, ADR-003, provider-platform docs

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

- SharedPreferences stores settings, selected provider, and LKG usage.
- Cache is provider-scoped; legacy Claude cache migration is preserved.
- Refresh state distinguishes loading, live, cached, soft failure, hard failure.
- Async UI actions check lifecycle safety before navigation/feedback.
- Logs are structured and secret-safe with provider/category metadata.

## Distribution

- Flutter 3.38.9 / Dart 3.10.x
- Node sidecar toolchain is pinned and assembled per release target.
- Release artifacts: macOS arm64 and Windows x64.
- Release workflow runs on version tags or manual dispatch.

## Invariants

1. No direct external I/O from UI.
2. No undocumented provider endpoints or interactive-output scraping.
3. No invented percentages or conflicting state emissions.
4. Preserve Claude behavior when adding providers.
5. Shared pages and cards must remain capability-driven.

## Technical debt

- Transitional compatibility directories exist under provider `core/`,
  `domain/`, `data/copilot/`, and `copilot/`; consolidation needs a dedicated
  migration with import inventory and full regression tests.
- `docs/release/CI-CD.md` is stale relative to actual arm64-only macOS release
  and main-push build gating.
- Notification dependency/migration state must be reconciled with current
  `pubspec.yaml` before further notification work.
- Signing, notarization, sandbox strategy, and Windows validation remain open.
