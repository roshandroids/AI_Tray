# ADR Index

Architecture Decision Records for AI Tray.

| ID | Title | Status | Date |
|--|--|--|--|
| [ADR-001](ADR-001-claude-cli-data-source.md) | Claude CLI as primary usage data source | Accepted | 2026-07-12 |
| [ADR-002](ADR-002-error-handling-resilience.md) | Error handling, cache, retry, logging | Approved | 2026-07-12 |
| [ADR-003](ADR-003-provider-platform.md) | Provider registry and capability-driven UI | Accepted | 2026-07-16 |
| [ADR-004](ADR-004-provider-platform-post-EP002-assessment.md) | Post-EP-002 targeted cleanup (not full rewrite) | Accepted | 2026-07-19 |
| [ADR-005](ADR-005-flex-color-scheme-personalization.md) | FlexColorScheme branded personalization | Accepted | 2026-07-31 |

## Rules

1. Do not change accepted architecture without a new ADR.
2. Feature freeze (PO Decision 007) prohibits architecture refactors during Release Hardening.
3. Parser / CLI command changes that alter the data-source contract should update ADR-001 or supersede it.

## Proposed (not opened — deferred past RC1)

| Topic | Why deferred |
|--|--|
| Alternate HTTP usage API | Contingency only if CLI Shape B / churn worsens |
| Notarized distribution pipeline | Release ops after dogfood |
