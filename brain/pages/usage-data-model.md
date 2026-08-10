---
id: usage-data-model
title: Usage data model and status/freshness semantics
category: concept
status: active
tags: [usage, data-model, status]
created: "2026-08-09T23:31:29"
updated: "2026-08-09T23:32:39"
---

<!-- compiled_truth -->
## `UsageInfo` (the canonical validated model)

Fields (`ai_tray/lib/features/usage/domain/models/usage_info.dart`):
`sessionUsedPercent`, `sessionResetsAt`/`sessionResetsAtRaw`, `weekly`
(`List<WeeklyUsage>`), `metrics` (`List<ProviderUsageMetric>`, provider-neutral),
`fetchedAt`, `source` (`UsageSource.cli` | `.oauth` — oauth is reserved,
unused today), `isFromCache` (bool), `providerId`.

`isFromCache` is the single flag distinguishing a freshly-fetched value from
one read back out of the Last-Known-Good cache — see [[caching-strategy]].
There is no separate "staleness age" field; freshness is derived from
`fetchedAt` at render time (`UsageStatusMapper.relativeUpdated`), not stored.

## The four semantic distinctions this brain must protect

**Live vs Cached vs Refreshing vs Error vs Waiting** — this is a UI *status*
derived by `UsageStatusMapper.kind()`
(`features/usage/presentation/usage_status.dart`), not a field on the model:

| Condition | `TrayStatusKind` | Label |
| --- | --- | --- |
| `phase == refreshing` | `refreshing` | Refreshing |
| last outcome `failure` and no usage at all | `error` | Error |
| last outcome `failure` but usage exists (from cache) | `cached` | Cached |
| no usage yet | `idle` | Waiting |
| `usage.isFromCache` or last outcome `softFailure` | `cached` | Cached |
| otherwise | `live` | Live |

**CLI failure vs Validation failure** — both are `AppFailure`s but occur at
different pipeline stages and have different `RefreshOutcome`s:

- *CLI failure* — the adapter itself failed (process non-zero exit, timeout,
  not installed, not authenticated, unreadable stdout). Always maps to
  `RefreshOutcome.failure` ("hard failure").
- *Validation failure* — the CLI succeeded and returned parseable JSON, but
  `UsageValidator` rejected the parsed shape: `UsageShape.contributionOnly`
  or `ValidationStatus.incomplete` → `RefreshOutcome.softFailure` ("soft
  failure", FailureCode `incompleteOutput`); `UsageShape.unknown` or
  `ValidationStatus.invalid`, or a missing/out-of-range percentage → also
  `RefreshOutcome.failure` (hard), FailureCode `unknownCliOutput` /
  `parserFailure`.

Do not conflate these when debugging a "no usage shown" report — check which
stage actually failed before changing retry or cache logic.

**Unavailable vs Stale** — "Unavailable" is a **per-metric** UI state
(`ProgressRing`'s `available: false` renders the literal string
`"Unavailable"`), used when a specific metric/limit has no value at all —
distinct from the page-level Cached/stale-data status above, which means a
metric *does* have a value, just not a freshly-fetched one. A provider can be
`Cached` overall while a specific metric is `Unavailable` if the cached
snapshot never had that field populated.

## What NOT to do with this model

- Don't add a numeric "staleness threshold" / TTL — there isn't one by
  design (see [[caching-strategy]]); staleness is communicated qualitatively
  (Cached label + relative timestamp), never as an expiry.
- Don't invent a percentage or metric value when a fetch/validation fails —
  this is a named hard constraint (`AGENTS.md`: "Never invent usage
  values; label stale data").


## Timeline

- time: 2026-08-09T23:31:29
  kind: decision
  summary: "Created this page: Usage data model and status/freshness semantics"
  source: "ai_tray/lib/features/usage/domain, ai_tray/lib/features/usage/presentation/usage_status.dart"
  affects: [usage-data-model]

- time: 2026-08-09T23:32:39
  kind: decision
  summary: "Seed compiled_truth: UsageInfo model fields, Live/Cached/Refreshing/Error/Waiting derivation, CLI-vs-validation failure distinction, per-metric Unavailable vs page-level stale"
  source: "usage_info.dart, usage_status.dart, usage_validator.dart, refresh_outcome.dart"
  affects: [usage-data-model]
