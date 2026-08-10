---
id: caching-strategy
title: "Refresh and caching strategy (LKG)"
category: concept
status: active
tags: [cache, refresh, resilience]
created: "2026-08-09T23:31:29"
updated: "2026-08-09T23:33:04"
---

<!-- compiled_truth -->
## What triggers a refresh, and single-flight

`RefreshService.refresh()` keys an in-flight `Future<RefreshResult>` map by
`ProviderId`. A second `refresh()` call for the *same* provider while one is
already running joins the existing future (coalesced) rather than starting a
duplicate CLI process. `invalidateInFlight(providerId)` drops the coalescing
map entry (without cancelling the underlying future) — used when the
selected provider changes, so switching back later starts a fresh run
instead of joining a stale one.

## Retry policy (bounded, at most one extra attempt)

After the first `fetchUsageRaw`:

- **Success but rate limits missing/incomplete** (`parserState.rateLimitsPresent`
  is false) → wait `softRetryDelay` (default 3s), fetch once more.
- **Failure with code `timeout`, `processNonZeroExit`, or `unknown`** → wait
  `hardRetryDelay` (default 2s), fetch once more.
- Any other outcome (already-good success, or a non-retryable failure like
  `cliNotInstalled`/`notAuthenticated`) → no retry.

This is a single retry pass, not a loop — `_maybeRetryRaw` only ever adds one
extra attempt, it does not recurse.

## Cache semantics — Last-Known-Good, no TTL

`UsageCache` (`SharedPreferencesUsageCache`) persists exactly one snapshot
per provider (`usage_lkg_v2_<providerId>` key; a legacy unscoped
`usage_lkg_v1` key is read once and migrated for Claude). There is
**no expiry / TTL** — a cached value is valid indefinitely until overwritten
by a newer successful fetch. Reads set `isFromCache: true` on the returned
`UsageInfo`. **Only a successful, validated fetch writes the cache** — soft
and hard failures both *read* the cache for fallback but never write it, so
a bad/incomplete response can never clobber a good last-known value.

## What each `RefreshOutcome` does with the cache

| Outcome | Cache write? | Cache read (fallback)? | Typical cause |
| --- | --- | --- | --- |
| `success` | Yes | — | CLI succeeded, validator accepted (Shape A) |
| `softFailure` | No | Yes | CLI succeeded but rate limits/shape incomplete |
| `failure` | No | Yes | CLI/process/auth/timeout error, or unparseable/invalid shape |

An auth-probe (`healthCheck`) may run before the hard-failure cache read, to
attach a more specific error — see [[cli-integration]]. Health-check results
never touch the cache themselves.

## Why no TTL (and don't add one)

The product constraint is "never invent usage values; label stale data," not
"expire data after N minutes" — an unreachable CLI (e.g. offline, or the
binary momentarily missing during an unrelated system event) should keep
showing the last real number, clearly labeled Cached, indefinitely, rather
than blanking to Unavailable. See [[usage-data-model]] for how that label is
derived, and `background` for the underlying goal.

## Provider scoping

Every cache read/write, and the `RefreshService` in-flight map, is keyed by
`ProviderId` — Claude and Copilot caches are fully independent; switching
providers never reads or invalidates the other provider's LKG snapshot.


## Timeline

- time: 2026-08-09T23:31:29
  kind: decision
  summary: "Created this page: Refresh and caching strategy (LKG)"
  source: "ai_tray/lib/features/usage/data/services/refresh_service.dart, ai_tray/lib/features/usage/data/cache/usage_cache.dart, ADR-002"
  affects: [caching-strategy]

- time: 2026-08-09T23:33:04
  kind: decision
  summary: "Seed compiled_truth: single-flight coalescing, bounded one-shot retry policy, LKG cache has no TTL and only success writes it"
  source: "refresh_service.dart, usage_cache.dart"
  affects: [caching-strategy]
