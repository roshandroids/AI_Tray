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

## Out of scope

Codesign, notarization, Sparkle, Linux desktop, macOS Intel.

Local DX: [docs/devops/LOCAL_DEVELOPMENT.md](../devops/LOCAL_DEVELOPMENT.md).  
Required checks: [docs/CI_REQUIRED_CHECKS.md](../CI_REQUIRED_CHECKS.md).
