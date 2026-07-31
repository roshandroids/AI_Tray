# CI/CD & Release Automation

Foundation for continuous integration and desktop release automation for AI Tray
(PD-016 → **EP-004A Quality CI + Release CD** → **D-019 shared scripts**).

**Model:**

| Lane | When | Runners | What |
|------|------|---------|------|
| **Quality CI** | `pull_request` / `push` → `main` | **Ubuntu only** | Invokes `./scripts/format.sh`, `analyze.sh`, `test.sh`, `check.sh workflows` |
| **Documentation** | Docs / markdown / showcase path changes | **Ubuntu only** | Handoff JSON, relative links (no Flutter) |
| **Release CD** | SemVer tag / `workflow_dispatch` | Ubuntu + **macOS** + **Windows** | `./scripts/build.sh` + `./scripts/package.sh` + GitHub Release |
| **Maintenance** | Weekly cron + dispatch | **Ubuntu only** | Outdated package reports (never builds app) |

**Hard rules:**
- macOS / Windows runners **never** run on `pull_request` or branch `push`.
- Desktop binaries are built **only** in [`release.yml`](../../.github/workflows/release.yml).
- Workflow YAML is thin orchestration; commands live under [`scripts/`](../../scripts/).
- [`.ci/config`](../../.ci/config) `CI_MODE` is **local DX / docs only** — Actions ignores it.
- Quality CI must stay fast (target wall-clock &lt;10 minutes).

**Out of scope:** Code signing, notarization, Sparkle auto-update, security scanning.
**Not published:** macOS Intel / x64 artifacts (D-007). Linux desktop not shipped.

Local DX guide: [docs/devops/LOCAL_DEVELOPMENT.md](../devops/LOCAL_DEVELOPMENT.md).  
Demo / Showcase: [docs/devops/DEMO_STRATEGY.md](../devops/DEMO_STRATEGY.md).

---

## Shared scripts (one command surface)

Local maintainers and GitHub Actions call the same entrypoints:

```text
./scripts/doctor.sh | bootstrap.sh | clean.sh
./scripts/format.sh | analyze.sh | test.sh | check.sh
./scripts/build.sh | package.sh
./scripts/publish.sh          # canonical bump/tag/push
./scripts/release.sh          # orchestrator (--check-only, --local-only, --publish)
```

Implementations live in `scripts/ci/` (except publish → `scripts/release/publish.sh`).

---

## Pipeline overview

```mermaid
flowchart TB
  subgraph PR["Quality CI — PR / push → main"]
    F["./scripts/format.sh"]
    A["./scripts/analyze.sh"]
    T["./scripts/test.sh"]
    W["./scripts/check.sh workflows"]
    D[Documentation — docs paths]
  end

  subgraph REL["Release CD — tag or workflow_dispatch"]
    V[Validate pubspec]
    MA["./scripts/build.sh macos"]
    WIN["./scripts/build.sh windows"]
    GH[GitHub Release + assets]
    V --> MA & WIN --> GH
  end

  subgraph local [Local DX]
    check["./scripts/check.sh"]
    pub["./scripts/publish.sh"]
  end

  check -.->|same commands| PR
  pub -->|tag push| REL
```

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **Quality** | [`.github/workflows/quality.yml`](../../.github/workflows/quality.yml) | PR + push → `main` | Shared scripts — **no desktop** |
| **Documentation** | [`.github/workflows/documentation.yml`](../../.github/workflows/documentation.yml) | Docs / showcase / `*.md` paths | Handoff + JSON + relative links |
| **Release** | [`.github/workflows/release.yml`](../../.github/workflows/release.yml) | Tag `v*.*.*` or dispatch | **Only** desktop builds + GitHub Release |
| **Maintenance** | [`.github/workflows/maintenance.yml`](../../.github/workflows/maintenance.yml) | Weekly + dispatch | Safe outdated reports |
| **Reusable Flutter Web Demo** | [`.github/workflows/reusable-flutter-web-demo.yml`](../../.github/workflows/reusable-flutter-web-demo.yml) | `workflow_call` only | Template for other RSProjects — **not invoked by AI Tray** |

**Flutter / Node pins:** [`.ci/toolchain.env`](../../.ci/toolchain.env) (single source of truth).  
**App directory:** `ai_tray/`

**Removed:** `.github/workflows/ci.yml` (replaced by Quality; PR macOS build deleted).

**Demos:** Product-as-demo ([`showcase/demos.json`](../../showcase/demos.json) `id: main`). See [DEMO_STRATEGY.md](../devops/DEMO_STRATEGY.md).

---

## Comparison with existing repositories

| Aspect | CELPIP | MBO Research | AI Tray (this repo) |
|--------|--------|--------------|---------------------|
| Quality workflow | `CI` | `ci` | `Quality` (`quality.yml`) |
| Job names (branch protection) | Format, Analyze, Test, Build Web | Analyze, Format, Test, Corpus | Format, Analyze, Test, Validate workflows |
| Flutter pin | `3.38.9` env | `3.38.9` inline | `.ci/toolchain.env` → Actions |
| `subosito/flutter-action@v2` + cache | Yes | Yes | Yes (+ `pub-cache-key` from `pubspec.lock`) |
| Concurrency cancel-in-progress | Yes | No | Yes (Quality / Docs / Maintenance) |
| Deploy on merge | Firebase Hosting | N/A | GitHub Release on **tag or dispatch only** |
| Desktop on PR | N/A (web) | N/A | **No** (Quality CI + Release CD / D-017) |

---

## Pull request CI (Quality)

**Required checks (configure in branch protection):**

| Check name | Command / behavior |
|------------|--------------------|
| `Format` | `./scripts/format.sh` |
| `Analyze` | `./scripts/analyze.sh` |
| `Test` | `./scripts/ci/bridge.sh` + `./scripts/test.sh` |
| `Validate workflows` | `./scripts/check.sh workflows` |

**Do not require:** `Build macOS` (removed), Release, Maintenance.

Run locally before opening a PR:

```bash
./scripts/check.sh          # Quality CI parity (format/analyze/bridge/test/workflows)
```

Desktop builds are **release-only**. Do not expect a PR macOS binary.

---

## Main branch

On push to `main`, Quality re-runs the same lightweight jobs (with path-aware
Flutter skips). No desktop artifacts. User-facing packages come only from **Release**.

---

## Documentation workflow

Triggers on `docs/**`, root `*.md`, `CHANGELOG.md`, `AI_Tray_*.md`, and the
documentation workflow file. Validates:

- `scripts/ci/validate_handoff.sh`
- `docs/project/*.json` parse
- Relative markdown links under `docs/project`, `docs/devops`, `docs/adr`

No Flutter SDK install.

---

## Release flow

### Automated path — “Publish AI Tray”

1. Add notes under `## [Unreleased]` in [`CHANGELOG.md`](../../CHANGELOG.md).
2. Ensure Quality is green on `main`.
3. Run from repo root:

```bash
./scripts/publish.sh patch    # 1.0.0 → 1.0.1
./scripts/publish.sh minor    # 1.0.0 → 1.1.0
./scripts/publish.sh major    # 1.0.0 → 2.0.0
./scripts/publish.sh 1.0.0    # pin exact version (e.g. GA from RC)
./scripts/publish.sh patch --pre rc.1   # pre-release
./scripts/publish.sh patch --dry-run    # preview only

# Orchestrator equivalents:
./scripts/release.sh --check-only
./scripts/release.sh --local-only          # dogfood host zip under dist/
./scripts/release.sh --publish patch
```

4. Script actions:
   - Bumps `ai_tray/pubspec.yaml` (version / build)
   - Moves `[Unreleased]` → `[X.Y.Z] — date` in CHANGELOG (**notes SoT**)
   - Regenerates `ai_tray/assets/release_history.json` (derived; never hand-edit)
   - Commits pubspec + CHANGELOG + release history, creates annotated tag `vX.Y.Z`, pushes commit + tag
5. **Release** workflow triggers automatically:
   - Validates tag ↔ pubspec
   - Builds and packages:
     - `AI-Tray-macOS-arm64.zip`
     - `AI-Tray-Windows-x64.zip`
   - Creates GitHub Release with CHANGELOG body (`extract_changelog.sh`)

**Release notes SoT (D-020):** Edit `## [Unreleased]` in [`CHANGELOG.md`](../../CHANGELOG.md) only.
Do **not** hand-edit `ai_tray/assets/release_history.json`. Re-run
`./scripts/release/sync_release_history.sh` (or `./scripts/publish.sh`) to regenerate.
The app Settings → About / Diagnostics read live version via `package_info_plus`
and What’s New / history from the generated asset.

Manual re-run: Actions → **Release** → **Run workflow** (`workflow_dispatch`).

### Versioning rules

| Rule | Detail |
|------|--------|
| SemVer | `MAJOR.MINOR.PATCH` (+ optional `-prerelease`) |
| Single source | `ai_tray/pubspec.yaml` `version:` line only |
| Tag format | `v1.0.0` or `v1.0.0-rc.1` (must match pubspec name) |
| Build number | `+N` suffix auto-incremented by `publish.sh` |

**Note:** Legacy RC tags `v1.0.0-rc1` / `v1.0.0-rc2` predate automation; new pre-releases use `v1.0.0-rc.1` style to match pubspec.

---

## Release assets

| Asset | Runner | Build command |
|-------|--------|---------------|
| `AI-Tray-macOS-arm64.zip` | `macos-latest` | `./scripts/build.sh macos` + `./scripts/package.sh` |
| `AI-Tray-Windows-x64.zip` | `windows-latest` | `./scripts/build.sh windows` + `./scripts/package.sh` |

macOS zip contains `AI Tray.app`. Windows zip contains the `Release/` folder contents.

**Not published:** `AI-Tray-macOS-x64.zip` (Intel). Demand must justify CI/distribution cost before restoring that matrix entry.

---

## Manual fallback

### Re-run release for an existing tag

GitHub → Actions → **Release** → **Run workflow** → enter tag (e.g. `v1.0.0`).

### Manual tag (emergency)

```bash
# 1. Bump pubspec + CHANGELOG manually
# 2. Commit
git tag -a v1.0.0 -m "AI Tray 1.0.0"
git push origin main
git push origin v1.0.0
```

### Local packaging only

See [RH-003-packaging.md](RH-003-packaging.md).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Release fails: pubspec mismatch | Tag pushed without `publish.sh` | Align pubspec `version:` name with tag, re-tag |
| Windows build fails | Desktop not enabled / VS missing | Runner has VS 2022; run `flutter doctor` in workflow |
| Format check fails on CI only | pub get skipped before format | Quality runs `flutter pub get` first |
| Branch protection blocks merge | Stale check names | Require `Format`, `Analyze`, `Test`, `Validate workflows` — **not** `Build macOS` |
| Docs-only PR still “needs” Flutter | Old `ci.yml` still present | Confirm only `quality.yml` exists; path filter no-ops Flutter steps |
| `[Unreleased]` empty | No changelog entry | Add notes before `publish.sh` |
| Duplicate release | Tag pushed twice | Delete release + tag in GitHub, fix, re-publish |
| Expecting macOS x64 asset | Policy D-007 | Only arm64 + Windows x64 are published |

### Verify check names

```bash
gh api repos/roshandroids/AI_Tray/commits/<sha>/check-runs \
  --jq '.check_runs[] | select(.app.slug=="github-actions") | .name' | sort -u
```

---

## Branch protection checklist (Product Owner)

1. Settings → Rules → protect `main`
2. Require PR before merge
3. Require status checks: **Format**, **Analyze**, **Test**, **Validate workflows**
4. **Remove** required check **Build macOS** (if still listed)
5. Do **not** require Release / Maintenance for merge

---

## Cost posture (target, not measured)

Product Owner target: **&lt;300 Actions minutes / month**. Audit sample math
([CI_AUDIT.md](../devops/CI_AUDIT.md)) suggested ~65 billable min/PR with macOS
on every PR vs ~4–8 without. Local First shape (scenario C) projects roughly
**~160–210** billable min/month under moderate assumptions — still a projection,
not billing-dashboard fact.

---

## Related documents

- [LOCAL_DEVELOPMENT.md](../devops/LOCAL_DEVELOPMENT.md)
- [CI_AUDIT.md](../devops/CI_AUDIT.md)
- [CHANGELOG.md](../../CHANGELOG.md)
- [RH-003-packaging.md](RH-003-packaging.md)
- [lefthook.yml](../../lefthook.yml)

---

## PD-017 preview — one-command releases (all personal projects)

Target interface (not yet unified across repos):

```bash
publish patch    # → 1.0.1
publish minor    # → 1.1.0
publish major    # → 2.0.0
```

AI Tray implements this today via `./scripts/publish.sh` (wrapper around
`./scripts/release/publish.sh`).
