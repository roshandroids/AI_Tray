# ADR-003 — Provider Registry and Capability-Driven UI

| Field | Value |
|-------|-------|
| Status | Accepted by PD-021 |
| Date | 2026-07-16 |
| Decision makers | Product Owner · Lead Engineer |
| Relates to | ADR-001 · ADR-002 · PD-021 |
| Supersedes | Deferred multi-provider port activation |

## Decision

AI Tray will use an additive provider platform built around:

1. `AIProvider` for provider metadata, capabilities, raw operations, and parser
   ownership.
2. `ProviderRegistry` as the single provider catalog and enabled-provider
   filter.
3. `ProviderCapabilities` for conditional behavior and rendering.
4. `DashboardData` and `ProviderStatus` as normalized presentation inputs.
5. A single selected provider with Claude as the default.

Presentation must not branch on provider IDs. Provider-specific adapters and
parsers remain in the data layer and map into shared domain models.

## Context

ADR-001 introduced an adapter-level provider port, but parsing, labels, metrics,
and dependency injection remained Claude-specific. Adding another provider
would have required dashboard and settings branches.

PD-021 requires a framework that preserves Claude behavior while allowing a
future Copilot implementation to integrate without changing shared UI.

## Consequences

### Positive

- Claude behavior and compatibility provider names remain stable.
- Disabled providers can be scaffolded without executing external work.
- Dashboard cards are generated from capabilities and normalized metrics.
- Provider metadata owns labels used by dashboard, settings, diagnostics, tray,
  and error presentation.
- Duplicate and disabled registrations fail predictably.

### Trade-offs

- Only one provider refresh loop is active in this phase.
- Active provider selection is not persisted while only Claude is enabled.
- Existing Claude settings and LKG cache keys remain provider-specific legacy
  keys until a second provider is activated.
- `UsageInfo` remains the canonical rate-limit model; a provider must map its
  payload into that model or extend the shared metric contract deliberately.

## Rejected alternatives

### Provider-specific widgets

Rejected because every provider would duplicate cards, settings, statuses, and
error flows.

### Enable Copilot with placeholder data

Rejected because fabricated or incomplete percentages violate ADR-002.

### Rewrite the refresh repository per provider

Rejected in this phase because it would change Claude timers, retries, cache,
and lifecycle behavior without user benefit.

## Follow-up gate

Copilot may be enabled only after its adapter/parser contract, fixtures,
provider-scoped persistence, and regression tests are approved.

