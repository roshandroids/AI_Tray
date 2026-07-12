# PD-011 — Prepare RC2 and Enter Dogfooding

**Decision:** Product Owner Decision PD-011  
**Date:** 2026-07-12  
**Tag:** `v1.0.0-rc2` · version `1.0.0-rc.2+2`

## Authorized

1. Tag and publish **v1.0.0-rc2**
2. Release notes include Phase 2 stabilization improvements
3. **Feature freeze** — no new features
4. Begin dogfooding period

## Allowed during dogfooding

- Critical bug fixes
- Stability improvements
- Documentation corrections

## Required for every bug fix

- Root cause
- Resolution
- Regression test (when practical)
- Release note update (if user-visible)

## Daily process

Maintain [daily-observation-log.md](../dogfood/daily-observation-log.md) covering:

- Stability observations
- UX friction
- Performance observations
- Claude CLI issues
- Platform-specific issues

Do not redesign from a single observation. Prefer recurring patterns across days.

## Exit criteria for GA (v1.0.0)

Recommend GA only when:

1. No critical defects remain
2. Dogfooding period completes successfully
3. No recurring UX issues identified
4. Documentation is current
5. Product Owner approval is granted

## Stop condition (end of dogfood)

Produce, then stop for PO approval:

1. Dogfooding Summary
2. Bug Summary
3. Final GA Recommendation

## Product stance

AI Tray is a **maintained desktop product**. Future features must be justified by evidence from actual use, not speculation.
