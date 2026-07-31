# Branch protection

**Normative checklist** for GitHub settings that cannot live solely in the
repository tree. A repository admin must apply these in GitHub.

**Updated:** 2026-07-31  
**Status:** Active ruleset **Protect main (require PR)** applied on
`roshandroids/AI_Tray` (id `20100786`).

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
| Require a pull request before merging | **On** (no direct pushes) |
| Required approvals | **0** (solo maintainer; PR still mandatory) |
| Dismiss stale approvals | **On** |
| Require review from Code Owners | **Off** (solo; re-enable if co-maintainers) |
| Require status checks to pass | **On** — see [CI_REQUIRED_CHECKS.md](CI_REQUIRED_CHECKS.md) |
| Require branches to be up to date | **On** |
| Allow force pushes | **Off** (`non_fast_forward`) |
| Allow deletions of `main` | **Off** (`deletion` rule) |
| Bypass actors | **None** — even admins merge via PR |

### Required status checks (exact)

- Format
- Analyze
- Test
- Validate workflows

### Do **not** require

- Build macOS
- Build Windows

## Workflow

```text
feature branch → pull request → Quality CI green → merge to main
```

Never push commits directly to `main`. Create a PR, wait for required checks,
then merge (GitHub UI or `gh pr merge`).

## Ruleset JSON

Canonical export:
[`github-ruleset-protect-main-branch.json`](github-ruleset-protect-main-branch.json).

Re-apply / update:

```bash
gh auth switch --user roshandroids
# Create (first time):
gh api --method POST repos/roshandroids/AI_Tray/rulesets \
  --input docs/process/github-ruleset-protect-main-branch.json
# Update existing (replace RULESET_ID):
gh api --method PUT repos/roshandroids/AI_Tray/rulesets/RULESET_ID \
  --input docs/process/github-ruleset-protect-main-branch.json
```

Job names in GitHub must match this document after any workflow rename.
