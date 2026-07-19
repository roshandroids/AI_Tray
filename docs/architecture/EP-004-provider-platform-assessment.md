# EP-004 Provider Platform Assessment (Post-EP-002)

**Date:** 2026-07-19  
**Status:** Assessment complete — recommendation for Product Owner  
**Inputs:** Stabilization baseline, lifecycle/race fixes, sidecar hardening, folder inventory

## Decision gate (from plan)

| Option | Trigger |
| --- | --- |
| **No-go** | No third provider planned **and** stabilization finds no shared-orchestration defect |
| **Targeted cleanup** | Canonicalize imports, deprecate aliases, enrich capability/recovery/diagnostics metadata, choose one retry owner — **without** rewriting refresh/cache/sidecar |
| **Full EP-004** | Shared lifecycle defects remain after stabilization, **or** a third provider needs >3 shared UI/state changes, >2 new provider-ID branches, diagnostics cannot fit a shared snapshot, or simultaneous refresh becomes required |

## Inventory

Assessed trees under `ai_tray/lib/features/providers/`:

| Tree | Files | Role |
| --- | --- | --- |
| `copilot/` | 10 | **Canonical** Copilot SDK/sidecar implementation |
| `core/` | 20 | Canonical registry/models/ports + ~13 thin `export … show` aliases |
| `domain/` | 15 | **All** compatibility re-exports → `core/` |
| `data/copilot/` | 7 | **All** compatibility re-exports → `copilot/` |

**Forwarding / compatibility surface:** ~35 files (15 `domain/` + 7 `data/copilot/` + ~13 thin `core/` show-exports).  
**Canonical namespaces to keep:** `features/providers/core/**` and `features/providers/copilot/**`.

Import migration impact is moderate: update call sites to canonical paths, then deprecate alias barrels before deletion. No behavioral rewrite required for the alias layer itself.

## Stabilization findings (orchestration)

Proven and **fixed** in this sprint (not deferred to a full epic):

1. Dispose during refresh no longer mutates status/timers.
2. ABA Claude→Copilot→Claude rejects stale completions; provider switch invalidates in-flight coalescing.
3. Soft/hard backoff counters are provider-scoped.
4. Cache write failures are logged; refresh remains successful/recoverable.
5. Resume overdue schedule hook (`recoverScheduleIfOverdue`) is testable.
6. Sidecar protocol edges: malformed NDJSON, handshake timeout, write failure, concurrent IDs, late responses, shutdown kill; host duplicate/cancel coverage; CI/Release `smoke_protocol.mjs` after assemble/verify.

Remaining shared gaps are **cleanup-sized**, not rewrite-sized:

| Gap | Severity | Fits targeted cleanup? |
| --- | --- | --- |
| Dual retry ownership (adapter soft/hard paths + `RefreshService` retry) | Medium | Yes — pick one owner |
| Copilot vs Claude diagnostics shape divergence | Medium | Yes — shared snapshot metadata |
| Thin `ProviderCapabilities` (booleans only) | Low–Medium | Yes — maturity/icon/recovery fields |
| String matching in empty states | Low | Yes — structured recovery reasons |
| TrayController stream/listener disposal | Medium | Yes — local disposal, not platform rewrite |
| WidgetsBindingObserver wiring for sleep/wake | Low | Optional follow-up; hook exists |

No residual defect requires rewriting `RefreshService`, LKG cache, or the NDJSON sidecar architecture.

## Third-provider outlook

- Cursor personal quota remains blocked (PD-023).
- A future Cursor **automation** surface would be a separate epic and is not scheduled.
- Therefore full EP-004 is **not** justified by an imminent third quota provider.

## Recommendation

**Targeted cleanup** (not no-go, not full EP-004).

Rationale:

- Stabilization found real shared-orchestration defects, so pure **no-go** is too weak.
- Those defects were fixed without a platform rewrite, and remaining work is import canonicalization + metadata/retry ownership — the plan’s **targeted cleanup** definition.
- Full EP-004 triggers (simultaneous multi-provider refresh, diagnostics that cannot share a snapshot, third quota provider needing many provider-ID branches) are **not** met.

## Proposed targeted-cleanup scope (future PR; not this sprint)

1. Canonicalize imports to `core/` and `copilot/`; deprecate `domain/` and `data/copilot/` aliases.
2. Extend capability metadata (maturity, icon key, recovery hints, diagnostics profile).
3. Choose a single retry owner (prefer `RefreshService`; adapters stay transport-only).
4. Replace avoidable provider-ID UI branches with capability/recovery metadata.
5. Dispose tray subscriptions explicitly.
6. Optionally wire `recoverScheduleIfOverdue` from app lifecycle.

**Out of scope for targeted cleanup:** refresh/cache rewrite, sidecar protocol redesign, Cursor provider implementation.

## Product Owner ask

Approve **targeted cleanup** as the EP-004 posture (tracked as PD-024 / ADR-004). Defer a named “full EP-004” epic unless a future third quota provider or simultaneous-refresh requirement appears.
