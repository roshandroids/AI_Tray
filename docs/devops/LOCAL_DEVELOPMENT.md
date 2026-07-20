# Local development & Local First CI

**Policy (EP-004A):** Validate locally first. GitHub Actions on pull requests
runs **quality only** (format, analyze, unit tests, workflow YAML). Desktop
binaries are built **only** on version tags / `workflow_dispatch` via the
Release workflow. Docs-only changes skip Flutter-heavy steps.

App package root: **`ai_tray/`** (not the repository root).

---

## Quick validation (before every PR)

```bash
cd ai_tray
flutter pub get
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot
```

Copilot bridge (required for Test job parity):

```bash
cd ai_tray/tool/copilot_sdk_bridge
npm ci
npm run check
```

Optional before release / golden work (macOS):

```bash
cd ai_tray
flutter test --tags golden
flutter build macos --release
```

AI handoff consistency:

```bash
bash scripts/ci/validate_handoff.sh
```

---

## Lefthook (optional local hooks)

Hooks are **not** installed by cloning the repo. Enable them per clone:

```bash
# Install Lefthook once on the machine (pick one):
brew install lefthook
# or: npm install -g @evilmartians/lefthook
# or: go install github.com/evilmartians/lefthook@latest

# From the repository root:
lefthook install
```

Configured in [`lefthook.yml`](../../lefthook.yml):

| Hook | What runs |
|------|-----------|
| **pre-commit** | `dart format`, `flutter analyze`, quick unit tests (under `ai_tray/`) |
| **commit-msg** | Conventional Commits via `scripts/ci/check_conventional_commit.sh` |
| **pre-push** | Full unit tests (non-golden), bridge `npm run check`, handoff validation |

Skip once (emergency only): `LEFTHOOK=0 git commit ...` or `git commit --no-verify`.

Uninstall hooks: `lefthook uninstall`.

---

## CI workflow map

| Workflow | File | When | What |
|----------|------|------|------|
| **Quality** | `.github/workflows/quality.yml` | PR + push → `main` | Format, Analyze, Test, Validate workflows — **no desktop builds** |
| **Documentation** | `.github/workflows/documentation.yml` | Docs / markdown paths | Handoff + JSON + relative links |
| **Release** | `.github/workflows/release.yml` | Tag `v*` or dispatch | macOS arm64 + Windows x64 package + GitHub Release |
| **Maintenance** | `.github/workflows/maintenance.yml` | Weekly + dispatch | Informational `pub` / `npm` outdated reports |
| **Security** | — | Future | Placeholder only; no fake scanners |

Path filters: Flutter jobs no-op when the PR does not touch `ai_tray/**`,
`scripts/**`, or `lefthook.yml` (checks still report success for branch
protection). See [CI-CD.md](../release/CI-CD.md) and [CI_AUDIT.md](CI_AUDIT.md).

---

## Branch protection (required checks)

Require on `main` (after EP-004A):

- `Format`
- `Analyze`
- `Test`
- `Validate workflows`

**Remove** any required check named `Build macOS` (desktop moved to Release).

Do **not** require Release, Documentation, or Maintenance for merge.

---

## Related

- [CI-CD.md](../release/CI-CD.md) — operator release guide
- [CI_AUDIT.md](CI_AUDIT.md) — EP-004A audit + post-change notes
- [docs/project/AI_HANDOFF.md](../project/AI_HANDOFF.md)
