# Architecture Overview — AI Tray

**Audience:** contributors and reviewers
**Status:** Reflects the multi-provider platform (PD-021), personalization
(PD-026/027), and V2 session management (Milestones 1–2)

## Purpose

Desktop companion with two surfaces:

1. **Usage/quota dashboard** — a provider registry resolves enabled
   implementations; raw provider output is parsed/validated into shared
   domain models, cached, and shown through capability-driven Riverpod UI.
   Claude Code is stable; GitHub Copilot is experimental via the official
   SDK sidecar.
2. **Session management (V2)** — browse Claude Code sessions read directly
   from `~/.claude/projects/**/*.jsonl`, resume one by hand, or queue a
   resume (with a mandatory budget cap) for later. This is a separate
   bounded context from the usage pipeline, sharing only
   `ClaudeSessionService` and `NotificationGateway`.

## Layering

```
UI (Flutter widgets, tray shell)
  → State (Riverpod providers / notifiers)
    → Domain (models, repository ports, failure types)
      → Data (adapters, process runner, parser, cache, refresh)
        → External (enabled provider adapter / filesystem)
```

Rules in force:

- UI never sees CLI DTOs / raw JSON envelopes.
- Provider access only via `AIProvider`; CLI providers use `ProcessRunner`.
- UI renders `DashboardData` and provider capabilities, never provider IDs.
- No fabricated usage percentages.
- Every queued resume requires a positive budget cap — no "run without a
  cap" path.
- Architecture changes require a new ADR.

## Primary data flow (usage/quota)

1. `ProviderRegistry` resolves the enabled default provider (Claude, or
   Copilot if enabled in Settings).
2. `RefreshService` single-flights a refresh (manual or timer).
3. The active adapter calls its CLI/SDK (Claude: `claude -p '/usage'
   --output-format json`; Copilot: `account.getQuota` via the sidecar).
4. Provider parser + validator classify usable vs degraded output.
5. Success → write last-known-good cache; soft/hard failures → keep cache
   when allowed, surface an `AppFailure` code.
6. `DashboardDataMapper` applies capabilities; tray and diagnostics use
   provider metadata.

## Session data flow (V2)

1. `IoSessionFileSystem` enumerates `~/.claude/projects/**/*.jsonl` — no new
   database, no separate cache beyond the Resume Queue's own store.
2. `JsonlSessionParser` tolerates malformed/truncated lines (skips and marks
   `isComplete: false` rather than throwing).
3. `FileSystemSessionRepository` merges in live-session enrichment and sorts
   most-recently-active first.
4. Attended "Resume now" (`ResumeController`) runs the CLI in place
   (`forkSession: false`); the Resume Queue (`ResumeQueueExecutor`) defaults
   to forking (`forkSession: true`) so unattended execution never mutates a
   transcript you might be continuing by hand elsewhere.
5. `ResumeQueueExecutor` is single-flight, checks the working directory
   exists immediately before running, and notifies via `NotificationGateway`
   on every terminal outcome — clicking the notification opens that
   session's detail page.

## Key modules (`ai_tray/lib`)

| Area | Location |
|--|--|
| DI / bootstrap | `core/di`, `main.dart`, `app.dart` |
| Errors / Result / logging | `core/errors`, `core/result`, `core/logging` |
| Notifications | `core/notifications` |
| Provider registry / contracts / selection | `features/providers/domain`, `features/providers/presentation` |
| Claude + Copilot adapters | `features/providers/data/` |
| Usage repo / refresh / cache | `features/usage/` |
| Sessions (browser, detail, resume, queue) | `features/sessions/` |
| Settings | `features/settings/` |
| Personalization (themes, fonts, app icons) | `theme/` |
| Tray / window / notify / login | `features/tray/` |

## Resilience (ADR-002)

- Retries + backoff for timeout / transient failures
- Soft failure for degraded provider output
- Cache soft age ~6h / hard age ~24h
- Pause auto-refresh on auth / CLI missing
- Structured logging without secrets (credential-shaped strings are redacted
  before any log write)
- Resume Queue: mandatory budget cap, fail-fast on a missing working
  directory, no unattended cancellation of a running item

## Platforms

| Platform | Status |
|--|--|
| macOS arm64 | Primary; Release build verified; unsigned/not notarized |
| Windows x64 | Experimental; CI-verified to build and package, no recorded real-hardware validation yet |

## Deeper docs

- [V2 vision and roadmap](../planning/v2-vision-and-roadmap.md)
- [System architecture (planning)](../architecture/system-architecture.md)
- [Provider platform](../architecture/provider-platform.md)
- [Domain model](../architecture/domain-model.md)
- [Folder structure](../architecture/folder-structure.md)
- [ADR index](../adr/README.md)
