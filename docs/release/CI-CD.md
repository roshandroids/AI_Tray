# CI/CD & Release (binding)

**Canonical model** (same as [platform-ci RELEASE.md](https://github.com/roshandroids/platform-ci/blob/main/docs/RELEASE.md)):

```text
Cheap proves mergeability.
Release PR proves shipability.
Tag publishes (rebuild — no cross-run artifact reuse).
```

## Flow

```text
feature/* ──PR──► main     quality only (ubuntu) via platform-ci
release/x.y.z ──PR──► main quality + macOS/Windows builds
     │ merge
     ▼
tag vX.Y.Z
     │
     ▼
rebuild desktop → GitHub Release
```

## Config

| File | Role |
|------|------|
| [`ci.yaml`](../../ci.yaml) | Opt-in lanes (`release_targets: [macos, windows]`) |
| [`.github/workflows/quality.yml`](../../.github/workflows/quality.yml) | Feature PR / push → `quality` |
| [`.github/workflows/release-pr.yml`](../../.github/workflows/release-pr.yml) | `release/**` PRs → quality + builds |
| [`.github/workflows/release.yml`](../../.github/workflows/release.yml) | Tag → rebuild + GitHub Release |

## Hard rules (agents + humans)

1. **No permanent `dev` branch.**
2. Feature PRs: **never** macOS/Windows runners.
3. Version + CHANGELOG on **`release/x.y.z`** before merge.
4. Tag **only after** Release PR merges.
5. Tag workflow **rebuilds** (simple). Do not invent artifact promotion.
6. Use `./scripts/*.sh` for local parity; Actions call the same scripts via `ci.yaml` build scripts.
7. Required merge check on feature PRs: `quality / Quality`.
8. CHANGELOG entries follow the convention below — do not just carry over
   whatever bullets happen to already be sitting under `## [Unreleased]`.

## CHANGELOG convention

Feature PRs *should* add their own bullet under `## [Unreleased]` as they
land — but on `release/x.y.z`, before running `./scripts/publish.sh`, treat
that as a **draft, not a source of truth**:

1. **Audit, don't trust.** Diff every commit since the last tag —
   `git log --oneline <last-tag>..HEAD` — against what's already listed
   under `[Unreleased]`. Add whatever's missing (v1.4.0 shipped a redesign,
   onboarding, notifications, and a product tour that had never been
   logged — the gap is easy to miss when several feature branches merge
   between releases).
2. **Group by user-facing area, not by commit or PR.** A bold `**Area**`
   sub-heading per theme (e.g. `**Navigation & shell**`, `**Sessions, queue
   & notifications**`), not one flat list in merge order.
3. **Bold lead-in per bullet:** `- **Short name:** what changed, why it
   matters.` Keep every headline bullet in a section at the same level of
   boldness — don't bold three and leave the rest plain.
4. **One bullet per user-visible change.** Fold tightly-related sub-details
   into the same bullet with semicolons rather than splitting into many
   near-duplicate bullets.
5. **Say why for anything non-obvious**, especially under `### Fixed` — the
   failure mode a user or future maintainer would otherwise have to
   reconstruct from the diff (see the macOS App Sandbox entry in
   [`CHANGELOG.md`](../../CHANGELOG.md) for the shape: what broke, why, what
   changed).
6. **Write for the reader of the GitHub Release, not the commit log.**
   Rephrase commit-message shorthand into a sentence someone outside the
   project could follow.

See the `[1.4.0]` section of [`CHANGELOG.md`](../../CHANGELOG.md) as the
reference example.

## Out of scope

Codesign, notarization, Sparkle, Linux desktop, macOS Intel.

Local DX: [docs/devops/LOCAL_DEVELOPMENT.md](../devops/LOCAL_DEVELOPMENT.md).  
Required checks: [docs/CI_REQUIRED_CHECKS.md](../CI_REQUIRED_CHECKS.md).
