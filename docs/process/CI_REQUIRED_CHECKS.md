# CI required checks

Status checks that must pass before merging to `main` (EP-004A /
Quality CI + Release CD).

**Updated:** 2026-07-31  
**Workflows:** [`.github/workflows/quality.yml`](../../.github/workflows/quality.yml),
[`.github/workflows/documentation.yml`](../../.github/workflows/documentation.yml)

Related: [BRANCH_PROTECTION.md](BRANCH_PROTECTION.md) ·
[`docs/release/CI-CD.md`](../release/CI-CD.md) ·
[`docs/devops/LOCAL_DEVELOPMENT.md`](../devops/LOCAL_DEVELOPMENT.md)

---

## Required on PRs

Require **all** of the following (names must match GitHub check names):

| Check | Enforces |
| --- | --- |
| Format | `dart format --set-exit-if-changed` |
| Analyze | `flutter analyze --fatal-infos` |
| Test | Unit/widget tests (non-golden) + bridge checks as configured |
| Validate workflows | Workflow YAML / handoff validation as configured |

## Must **not** be required on PRs

| Check | Why |
| --- | --- |
| Build macOS | Desktop builds belong in **Release CD** only |
| Build Windows | Same |
| Golden / screenshot suites as merge blockers | Run locally / as needed; not Quality CI blockers |

## Release CD (not PR)

Desktop packaging (macOS arm64, Windows x64) runs only on SemVer tag or
`workflow_dispatch` via [`.github/workflows/release.yml`](../../.github/workflows/release.yml).

## Ruleset artifact

Canonical export: [`github-ruleset-protect-main-branch.json`](github-ruleset-protect-main-branch.json).
Apply via GitHub Rulesets; see [BRANCH_PROTECTION.md](BRANCH_PROTECTION.md).
