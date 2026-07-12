# RH-005 — Technical Debt Review (RC1)

**Date:** 2026-07-12  
**Scope:** Remaining debt after MVP approval; no new features introduced to “pay down” architecture debt during freeze.

---

## Remaining technical debt

| ID | Item | Severity | Notes |
|--|--|--|--|
| TD-01 | Windows never built/smoked on CI or this host | High | Blocks Windows GA |
| TD-02 | Tray/app icons are Flutter placeholders | Medium | Branding before public launch |
| TD-03 | Unsigned / non-notarized macOS distribution | Medium | Gatekeeper friction |
| TD-04 | `local_notifier` deprecated NSUserNotification APIs | Medium | May break on future macOS |
| TD-05 | Accessibility not audited | Medium | Screen reader / contrast / focus |
| TD-06 | Sleep/wake refresh timer not covered by automated tests | Medium | Manual RH-002 only |
| TD-07 | GUI PATH vs Terminal PATH for `claude` | Medium | Mitigated by Settings path; UX still rough |
| TD-08 | `AppSettings.copyWith` awkward for clearing optionals | Low | UI rebuilds full model in places |
| TD-09 | Dependency upgrades pending (`flutter pub outdated`) | Low | 15 packages newer outside constraints |
| TD-10 | No structured dogfood telemetry (by design freeze) | Low | Manual annoyance log instead |
| TD-11 | Widget/integration tests thin beyond smoke + unit parser/refresh | Medium | Expand after dogfood themes emerge |
| TD-12 | Hard-coded process timeouts (5–8s) | Low | May need tuning per machine |

---

## Deferred improvements (explicitly out of RC1)

- Analytics, charts, history graphs
- Multi-provider / multi-account
- UI redesign
- New settings surfaces
- Architecture refactors / new ADRs unless critical bug
- OAuth HTTP usage fallback (contingency only)
- Auto-update (Sparkle / similar)
- Custom branded icon set

---

## Risks for v1.1 (if started too early)

| Risk | Impact |
|--|--|
| Skipping dogfood → shipping unknown tray edge cases | High user trust damage |
| Feature work before Windows smoke | Split attention; regressions |
| Parser churn while adding providers | Dual maintenance burden |
| Expanding settings before validating current ones | Preference sprawl |

**PO recommendation stands:** dogfood `v1.0.0-rc1` for 1–2 weeks before `v1.0.0`, then consider v1.1.

---

## Parser maintenance recommendations

1. **Keep golden fixtures** for Shape A, Shape B, unknown/cost-only, and auth-ish empties under `test/` / research samples.
2. **Pin / record Claude Code version** in QA reports and dogfood logs whenever parse anomalies appear.
3. **Treat wording changes as P0** if Shape A detection breaks — hot-fix parser, do not invent %.
4. **Log `ParserState` / failure codes** (no raw secrets) when classification fails.
5. **Do not poll faster** to “fix” Shape B — increases rate-limit analytics-only responses.
6. **Revisit ADR-001** only if Claude ships a stable structured usage API; do not scrape HTML.
7. **Single-flight + backoff** remain mandatory; add regression tests when changing refresh policy.
8. After dogfood, add 2–3 real captured envelopes (redacted) from production-like runs to fixtures.

---

## Suggested debt order after dogfood (not a commitment)

1. Fix issues found in dogfood / RH-002 fails  
2. Windows smoke + known Windows PATH  
3. Notarization / icon polish for v1.0.0  
4. Notifier API modernization  
5. a11y pass  
6. Only then v1.1 roadmap items
