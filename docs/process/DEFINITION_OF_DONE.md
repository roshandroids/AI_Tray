# Definition of Done

A task is **complete** only when the applicable checklist below is satisfied.

**Updated:** 2026-07-31  
Related: [REPOSITORY_GOVERNANCE.md](REPOSITORY_GOVERNANCE.md) ·
[CI_REQUIRED_CHECKS.md](CI_REQUIRED_CHECKS.md) ·
[`.cursor/rules/project-handoff.mdc`](../../.cursor/rules/project-handoff.mdc)

---

## General checklist

- [ ] Code implemented on a feature branch (correct architecture; no temporary hacks)
- [ ] Issue linked for non-trivial work
- [ ] Tests pass locally for the touched surface
- [ ] Regression coverage for bugs
- [ ] Documentation updated (guides / ADR / provider docs as applicable)
- [ ] Handoff package reviewed when state changed (`docs/project/`)
- [ ] Quality CI required checks green on the PR
- [ ] Maintainer approval obtained
- [ ] Merged to `main` via PR

## By change type

### Bug

- [ ] Reproduced and root-caused ([BUG_HANDLING.md](BUG_HANDLING.md))
- [ ] Regression test added
- [ ] Manually verified on reported platform/provider when practical

### Feature

- [ ] Acceptance criteria met
- [ ] Does not violate PD-023 / PD-024 / PD-025 / ADR-004 constraints
- [ ] `CHANGELOG.md` updated for user-facing changes

### Docs / process

- [ ] Links validated; no competing SoT introduced
- [ ] Follows [DOCUMENTATION_RULES.md](../DOCUMENTATION_RULES.md)

### CI / DevOps

- [ ] Does not reintroduce PR desktop builds
- [ ] [CI_REQUIRED_CHECKS.md](CI_REQUIRED_CHECKS.md) updated if check names change

### Provider / sidecar

- [ ] No invented usage values; stale/LKG labeled
- [ ] No undocumented / scraped APIs
- [ ] Bridge `npm run check` if `copilot_sdk_bridge` touched

---

Until applicable boxes are checked, the task remains **incomplete**.
