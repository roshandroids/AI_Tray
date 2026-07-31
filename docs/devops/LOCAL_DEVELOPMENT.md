# Local development & dual CI (Local DX + Remote Actions)

AI Tray supports **two equally valid workflows** that share one command surface
under [`scripts/`](../../scripts/):

| Mode | Who | What |
|------|-----|------|
| **Local DX** | Maintainers (recommended) | Run `./scripts/check.sh` (and optional Lefthook) before push |
| **Remote CI** | Contributors + merge gate | GitHub Actions Quality always re-verifies on PR/push |

**GitHub Actions is the merge source of truth.** Local scripts catch issues
earlier; they never replace repository CI. Branch protection still requires
`Format` | `Analyze` | `Test` | `Validate workflows`.

App package root: **`ai_tray/`**.

---

## CI_MODE (local preference only)

[`.ci/config`](../../.ci/config):

```bash
CI_MODE=local   # or: remote
```

| Value | Meaning |
|-------|---------|
| `local` | Prefer running `./scripts/check.sh` / Lefthook before push |
| `remote` | You may lean on GHA for verification; scripts remain available |

**GitHub Actions ignores `CI_MODE` completely.** There is no workflow
conditional on this setting. Override for a single shell: `CI_MODE=remote ./scripts/doctor.sh`.

## Toolchain pins (single source of truth)

[`.ci/toolchain.env`](../../.ci/toolchain.env) pins Flutter / Node / npm for both
local scripts (`scripts/ci/_lib.sh`) and GitHub Actions
(`scripts/ci/export_toolchain.sh`). Bump versions **only** in that file.

---

## Script surface

Thin wrappers in `scripts/` → implementations in `scripts/ci/` (except publish):

| Command | Purpose |
|---------|---------|
| `./scripts/doctor.sh` | Validate Flutter/Dart/Node/git/gh/Xcode/etc. |
| `./scripts/bootstrap.sh` | `flutter pub get` + bridge `npm ci` |
| `./scripts/clean.sh` | `flutter clean` + remove `dist/` |
| `./scripts/format.sh` | `dart format --set-exit-if-changed` |
| `./scripts/analyze.sh` | `flutter analyze --fatal-infos` |
| `./scripts/test.sh` | Unit/widget tests (excludes golden/screenshot) |
| `./scripts/check.sh` | Aggregate gate — default `all` = Quality CI parity |
| `./scripts/build.sh [macos\|windows]` | Host-gated desktop release build (default: host OS) |
| `./scripts/package.sh [macos\|windows]` | Zip + SHA-256 into `dist/` (default: host OS) |
| `./scripts/publish.sh` | Canonical bump/tag/push → Release CD |
| `./scripts/release.sh` | Orchestrator (`--check-only`, `--local-only`, `--publish`, …) |

Examples:

```bash
./scripts/doctor.sh
./scripts/bootstrap.sh
./scripts/check.sh              # same validations as Quality CI
./scripts/check.sh full         # Quality + handoff
./scripts/check.sh format
./scripts/release.sh --check-only
./scripts/release.sh --local-only          # dogfood: check → build → package (no tags)
./scripts/release.sh --publish patch       # check → tag/push → GHA builds both OSes
```

**Parity:** `./scripts/check.sh` ≡ Quality jobs Format + Analyze + bridge + Test +
Validate workflows. Handoff validation is Documentation workflow / `check.sh full`
/ Lefthook pre-push — not part of Quality.
---

## Local vs remote — when to use which

**Prefer local (maintainers):**
- Fast iteration without burning Actions minutes
- Same commands GHA will run
- Enable Lefthook for pre-commit/pre-push hooks

**Prefer remote (contributors / CI-only machines):**
- No need to mirror every tool version locally for day-to-day PRs
- Still encouraged to run `./scripts/check.sh` when possible
- Merge remains blocked until GHA Quality is green

**Relationship:** Local DX ⊆ Remote CI command surface. Shipping macOS **and**
Windows artifacts is always **Release CD** after a SemVer tag (one machine
cannot build both platforms).

---

## Lefthook (optional)

```bash
brew install lefthook   # or npm/go install
lefthook install
```

Hooks call `./scripts/format.sh`, `./scripts/analyze.sh`, `./scripts/test.sh`,
and bridge/handoff helpers — the same scripts as Actions.

Skip once: `LEFTHOOK=0 git commit …` or `--no-verify` (emergency only).

---

## Typical flows

### Before a PR

```bash
./scripts/check.sh          # Quality CI parity
# optional: ./scripts/check.sh full   # also handoff
```
### Dogfood a host build (no tag)

```bash
./scripts/release.sh --local-only
# → dist/AI-Tray-macOS-arm64.zip (on macOS) or Windows zip on Windows
```

### Ship a release

```bash
# Ensure ## [Unreleased] notes exist in CHANGELOG.md (SoT for release notes)
./scripts/release.sh --publish patch
# or: ./scripts/publish.sh patch
```

`publish.sh` bumps pubspec, finalizes CHANGELOG, regenerates
`ai_tray/assets/release_history.json` (do not hand-edit), then tags and pushes.
GitHub Actions Release CD builds macOS arm64 + Windows x64 and publishes
assets. Settings → About shows version/build (via `package_info_plus`) plus
What’s New / previous releases from the generated asset. See
[CI-CD.md](../release/CI-CD.md).
