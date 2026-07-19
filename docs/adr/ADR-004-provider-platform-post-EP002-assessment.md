# ADR-004 — Provider platform posture after EP-002

**Date:** 2026-07-19  
**Status:** Accepted (Product Owner decision recorded)  
**Relates to:** ADR-003, EP-002, post-EP-002 stabilization,  
[`EP-004-provider-platform-assessment.md`](../architecture/EP-004-provider-platform-assessment.md)

## Context

After EP-002 Phase 3 merged, the provider trees contain a large compatibility
layer (`domain/` and `data/copilot/` re-exports, thin `core/` show-exports).
A full “EP-004 provider platform rewrite” was proposed in planning materials.
Stabilization was required first to learn whether shared lifecycle defects
justified that rewrite.

## Decision

Adopt **targeted cleanup**, not a full EP-004 rewrite and not a pure no-go:

1. Keep canonical namespaces `features/providers/core/**` and
   `features/providers/copilot/**`.
2. Deprecate compatibility aliases after import migration.
3. Enrich capability / recovery / diagnostics metadata and remove avoidable
   provider-ID branches.
4. Choose one retry owner (`RefreshService` preferred).
5. Do **not** rewrite refresh, LKG cache, or the Copilot NDJSON sidecar as part
   of this posture.
6. Re-open a full EP-004 epic only if future evidence meets the assessment
   triggers (third quota provider needing broad shared changes, simultaneous
   refresh, or diagnostics that cannot share a snapshot).

## Rationale

Stabilization proved and fixed shared orchestration defects (dispose races,
ABA stale completions, cross-provider backoff bleed, cache-write logging,
sidecar protocol edges) without requiring a platform rewrite. Remaining debt
is organizational and metadata-shaped. Cursor personal quota remains blocked
(PD-023), so a third quota provider is not an imminent driver.

## Consequences

- Roadmap lists targeted cleanup as the next architecture chore, not a rewrite epic.
- Import/deprecation PRs must keep tests green and avoid behavior changes.
- Full EP-004 remains a named contingency, not the default path.
