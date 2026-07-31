# Engineering principles

**Updated:** 2026-07-31

Non-negotiable rules for AI Tray. Details live in architecture docs and ADRs —
this page is the short list.

1. **Feature-first Clean Architecture** — UI → State → Domain → Data.
2. **Riverpod modern patterns** — Notifier / AsyncNotifier / AsyncValue.
3. **UI never calls CLI/SDK/API directly** — repositories own external I/O;
   DTOs map to domain before UI.
4. **Capability-driven shared UI** — `ProviderRegistry` + provider capabilities.
5. **Resilience** — provider-scoped single-flight refresh, bounded retry, LKG
   cache, generation-based stale rejection, dispose-safe completion.
6. **Honesty** — never invent usage values; label stale data.
7. **Official surfaces only** — no `/copilot_internal`, undocumented APIs, or
   scraping.
8. **Targeted cleanup over rewrites** — ADR-004 / PD-024.
9. **Local First** — validate on the developer machine; Quality CI is Ubuntu
   format/analyze/test; desktop builds only in Release CD.
10. **Product is the demo** — PD-025; no Flutter Web tray playground.
11. **No Cursor personal quota** until an official consumer usage API exists
    (PD-023).
12. **Handoff discipline** — significant work updates `docs/project/`.

See also: [`ENGINEERING_STANDARD.md`](../ENGINEERING_STANDARD.md),
[`architecture/`](../architecture/), [`adr/`](../adr/).
