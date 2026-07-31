# Branch protection

**Normative checklist** for GitHub settings that cannot live solely in the
repository tree. A repository admin must apply these in GitHub.

**Updated:** 2026-07-31  
Related: [CI_REQUIRED_CHECKS.md](CI_REQUIRED_CHECKS.md) ·
[REPOSITORY_GOVERNANCE.md](REPOSITORY_GOVERNANCE.md)

---

## Where to configure

**Preferred:** Repository → **Settings** → **Rules** → **Rulesets** → ruleset
targeting `main`.

Also: **Settings** → **General** → **Pull Requests** → **Automatically delete
head branches**.

## Required settings for `main`

| Setting | Value |
| --- | --- |
| Require a pull request before merging | **On** |
| Required approvals | ≥ 1 (maintainer / CODEOWNERS) |
| Dismiss stale approvals | **On** (recommended) |
| Require review from Code Owners | **On** when CODEOWNERS is used |
| Require status checks to pass | **On** — see [CI_REQUIRED_CHECKS.md](CI_REQUIRED_CHECKS.md) |
| Require branches to be up to date | **On** (recommended) |
| Allow force pushes | **Off** |
| Allow deletions of `main` | **Off** |
| Block direct pushes | Via “require PR” |

### Required status checks (exact)

- Format
- Analyze
- Test
- Validate workflows

### Do **not** require

- Build macOS
- Build Windows

## Ruleset JSON

Import or reconcile with
[`github-ruleset-protect-main-branch.json`](github-ruleset-protect-main-branch.json).
Job names in GitHub must match this document after any workflow rename.
