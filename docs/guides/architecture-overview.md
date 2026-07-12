# Architecture Overview — AI Tray (RC1)

**Audience:** contributors and reviewers  
**Status:** Reflects implemented MVP + Release Hardening (no architecture refactor)

## Purpose

Desktop companion that displays Claude Code subscription usage in the system tray / menu bar. Data enters only through a Claude CLI adapter, is parsed/validated into domain models, cached, and shown via Riverpod-backed UI.

## Layering

```
UI (Flutter widgets, tray shell)
  → State (Riverpod providers / notifiers)
    → Domain (models, repository ports, failure types)
      → Data (adapters, process runner, parser, cache, refresh)
        → External (Claude CLI process)
```

Rules in force:

- UI never sees CLI DTOs / raw JSON envelopes.
- Claude access only via adapter + `ProcessRunner`.
- No fabricated usage percentages.
- Architecture changes require a new ADR.

## Primary data flow

1. `RefreshService` single-flights a refresh (manual or timer).
2. `ClaudeCliAdapter` runs `claude -p '/usage' --output-format json` (never `--bare`).
3. `UsageParser` + `UsageValidator` classify **Shape A** (usable) vs **Shape B** (softFailure).
4. Shape A → write LKG cache; emit success.
5. Soft/hard failures → keep cache when allowed; surface `AppFailure` codes (auth, missing CLI, timeout, etc.).
6. Tray + usage shell observe `RefreshStatus`.

## Key modules (`ai_tray/lib`)

| Area | Location |
|--|--|
| DI / bootstrap | `core/di`, `main.dart`, `app.dart` |
| Errors / Result / logging | `core/errors`, `core/result`, `core/logging` |
| Claude adapter + process | `features/providers/data/` |
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
- [Domain model](../architecture/domain-model.md)
- [Folder structure](../architecture/folder-structure.md)
- [ADR index](../adr/README.md)
