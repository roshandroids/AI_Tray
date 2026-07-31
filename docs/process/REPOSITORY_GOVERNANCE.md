# Repository governance

**Normative.** AI Tray work that reaches `main` should be traceable, reviewed,
and tested.

**Updated:** 2026-07-31  
**Owner:** see [`OWNERSHIP.md`](../../OWNERSHIP.md)

Related: [BRANCH_PROTECTION.md](BRANCH_PROTECTION.md) ·
[DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md) ·
[CI_REQUIRED_CHECKS.md](CI_REQUIRED_CHECKS.md) ·
[`CONTRIBUTING.md`](../../CONTRIBUTING.md)

---

## Lifecycle

```
GitHub Issue (preferred for non-trivial work)
    ↓
Feature branch
    ↓
Implementation + tests
    ↓
Pull Request
    ↓
Maintainer approval
    ↓
Merge into main
```

## Rules

1. Do **not** push directly to `main` when branch protection is enabled; use a PR.
2. Link Issues from PRs when work is non-trivial (`Closes` / `Refs`).
3. Architectural changes require an ADR under [`docs/adr/`](../adr/) and a
   DECISION_LOG entry.
4. Behavior changes require tests appropriate to risk.
5. Significant product/architecture/process changes update the
   [`docs/project/`](../project/) handoff package.
6. Security vulnerabilities follow [`SECURITY.md`](../../SECURITY.md) — not
   public Issues.

## Solo-maintainer note

This repository is solo-maintained. “Owner approval” means the Product Owner /
maintainer reviews before merge. Trivial typo-only docs may skip a new Issue
when the maintainer explicitly allows a fast path; still prefer a PR.
