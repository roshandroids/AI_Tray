# PD-016 — Standardize CI/CD & Release Automation

**Status:** Historical design record (superseded in parts by **EP-004A Local First**)  
**Scope:** Automation only — no application functionality changes  
**Date:** 2026-07-12  
**Live source of truth:** [CI-CD.md](../CI-CD.md), [LOCAL_DEVELOPMENT.md](../../devops/LOCAL_DEVELOPMENT.md), `.github/workflows/`

> **Stale vs live YAML (2026-07-19):** PR desktop builds and `ci.yml` were removed.
> Quality is `quality.yml` (no desktop). Release is tag/dispatch only (macOS arm64 +
> Windows x64 — not macOS Intel). See [CI_AUDIT.md](../../devops/CI_AUDIT.md) §11.

---

## 1. CI/CD architecture summary (original PD-016)

| Layer | Implementation (as designed 2026-07-12) |
|-------|----------------|
| PR gates | `.github/workflows/ci.yml` — Format, Analyze, Test (Ubuntu) → Build macOS |
| Main verification | Same CI on push; ephemeral macOS artifact |
| Release | `.github/workflows/release.yml` — tag `vX.Y.Z` → macOS arm64/x64 + Windows → GitHub Release |
| Version | `ai_tray/pubspec.yaml` only |
| Changelog | Root `CHANGELOG.md` (Keep a Changelog) |
| Publish command | `./scripts/release/publish.sh patch\|minor\|major` |

---

## 2. Comparison with MBO Research & CELPIP

See [CI-CD.md](../CI-CD.md#comparison-with-existing-repositories).

**Key finding:** Neither reference repo has full desktop release automation yet. AI Tray adopts their **CI conventions** and extends with a **tag-driven release pipeline** PO requested for all personal projects (PD-017 foundation).

---

## 3. Implemented GitHub Actions

| File | Jobs |
|------|------|
| `ci.yml` | Format, Analyze, Test, Build macOS |
| `release.yml` | Validate version, Build macOS arm64, Build macOS x64, Build Windows x64, Publish GitHub Release |

**Action versions:** `actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/upload-artifact@v4`, `actions/download-artifact@v4`, `softprops/action-gh-release@v2`

---

## 4. Release workflow

```
Developer → publish.sh → version bump + CHANGELOG + commit + tag + push
    → GitHub Actions Release workflow
    → Build macOS (arm64 + x64) + Windows
    → Upload AI-Tray-*.zip assets
    → Publish GitHub Release with CHANGELOG notes
```

---

## 5. Documentation

- [docs/release/CI-CD.md](../CI-CD.md) — pipeline, troubleshooting, branch protection, manual fallback

---

## 6. Example release execution

```bash
# 1. Populate CHANGELOG [Unreleased]
# 2. Dry run
./scripts/release/publish.sh 1.0.0 --dry-run

# 3. After PO approval
./scripts/release/publish.sh 1.0.0
```

Monitor: https://github.com/roshandroids/AI_Tray/actions

---

## Repository changes

| Path | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | PR + main CI |
| `.github/workflows/release.yml` | Tagged release builds |
| `scripts/release/publish.sh` | One-command publish |
| `scripts/release/bump_version.sh` | Pubspec semver bump |
| `scripts/release/extract_changelog.sh` | Release notes extractor |
| `CHANGELOG.md` | Version history + Unreleased |
| `docs/release/CI-CD.md` | Operator documentation |

**No Dart / business logic changes.**

---

## First release instructions (awaiting PO approval)

1. Enable branch protection with required checks: Format, Analyze, Test, Build macOS.
2. Merge this PD-016 commit to `main`.
3. Confirm CI is green on `main`.
4. Finalize `## [Unreleased]` in CHANGELOG for the target version (e.g. `1.0.0` GA).
5. Run `./scripts/release/publish.sh 1.0.0` (or `patch`/`minor` as appropriate).
6. Verify GitHub Release assets and notes.

**Do not run step 5 until Product Owner approves.**

---

## Platform notes

| Topic | Status |
|-------|--------|
| macOS x64 on arm64 runners | Uses `arch -x86_64`; may fail if Rosetta unavailable — documented in CI-CD troubleshooting |
| Windows | Experimental per PD-010; CI builds for release parity |
| Code signing / notarization | Not in scope; manual install guidance unchanged |
| dSYM upload | Not configured |

**Stop here — awaiting Product Owner approval before first automated release.**
