# Architecture Overview — AI Tray

**Audience:** contributors and reviewers  
**Status:** Reflects implemented provider framework through PD-021

## Purpose

Desktop companion that displays AI provider subscription usage in the system
tray / menu bar. A provider registry resolves enabled implementations; raw
provider output is parsed/validated into shared domain models, cached, and shown
through capability-driven Riverpod-backed UI. Claude Code is stable; GitHub
Copilot is experimental via the official SDK sidecar.

## Layering

```
UI (Flutter widgets, tray shell)
  → State (Riverpod providers / notifiers)
    → Domain (models, repository ports, failure types)
      → Data (adapters, process runner, parser, cache, refresh)
        → External (enabled provider adapter)
```

Rules in force:

- UI never sees CLI DTOs / raw JSON envelopes.
- Provider access only via `AIProvider`; CLI providers use `ProcessRunner`.
- UI renders `DashboardData` and provider capabilities, never provider IDs.
- No fabricated usage percentages.
- Architecture changes require a new ADR.

## Primary data flow

1. `ProviderRegistry` resolves the enabled default provider (Claude).
2. `RefreshService` single-flights a refresh (manual or timer).
3. `ClaudeCliAdapter` runs `claude -p '/usage' --output-format json` (never `--bare`).
4. Provider parser + `UsageValidator` classify usable vs degraded output.
5. Shape A → write LKG cache; emit success.
6. Soft/hard failures → keep cache when allowed; surface `AppFailure` codes.
7. `DashboardDataMapper` applies capabilities; tray and diagnostics use provider metadata.

## Key modules (`ai_tray/lib`)

| Area | Location |
|--|--|
| DI / bootstrap | `core/di`, `main.dart`, `app.dart` |
| Errors / Result / logging | `core/errors`, `core/result`, `core/logging` |
| Provider registry / contracts / selection | `features/providers/domain`, `features/providers/presentation` |
| Claude + Copilot scaffold + process | `features/providers/data/` |
| Usage repo / refresh / cache | `features/usage/` |
| Settings | `features/settings/` |
| Tray / window / notify / login | `features/tray/` |

## Resilience (ADR-002)

- Retries + backoff for timeout / transient failures
- Soft failure for Shape B
- Cache soft age ~6h / hard age ~24h
- Pause auto-refresh on auth / CLI missing
- Structured logging without secrets

## Platforms

| Platform | Status |
|--|--|
| macOS | Primary; Release build verified |
| Windows | Scaffolded; host build pending |

## Deeper docs

- [System architecture (planning)](../architecture/system-architecture.md)
- [Provider platform](../architecture/provider-platform.md)
- [Domain model](../architecture/domain-model.md)
- [Folder structure](../architecture/folder-structure.md)
- [ADR index](../adr/README.md)
