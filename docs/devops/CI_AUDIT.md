# CI/CD Audit — EP-004A (AI Tray)

**Audit date:** 2026-07-19  
**Repository:** [roshandroids/AI_Tray](https://github.com/roshandroids/AI_Tray)  
**Audited path:** `/Users/roshanshrestha/Desktop/Projects/personal/AI_Tray_Project`  
**Default branch:** `main`  
**Scope:** Read-only inspection of `.github/workflows/`, release scripts, and CI docs.  
**Out of scope for this deliverable:** Creating or rewriting workflow YAML, Lefthook, or handoff docs.

---

## 0. Audit workspace snapshot

| Item | Value |
|------|--------|
| **Current branch** | `cursor/post-ep002-stabilization` |
| **Upstream** | `origin/cursor/post-ep002-stabilization` **[gone]** |
| **Working tree** | **Clean** — no dirty / untracked files at audit start |
| **HEAD (sample)** | `f0b700a` *checkpoint before checking out master* (and related docs/stabilization commits) |

> After this audit file is written, `docs/devops/CI_AUDIT.md` will appear as a new untracked file. That is expected and was not present at inspection start.

---

## 1. Inventory

### 1.1 Workflows (`.github/workflows/`)

| File | Workflow `name` | Present |
|------|-----------------|---------|
| `ci.yml` | `CI` | Yes |
| `release.yml` | `Release` | Yes |
| `quality.yml` | — | **Absent** (Local First target) |
| `documentation.yml` | — | **Absent** |
| `maintenance.yml` | — | **Absent** |
| `security.yml` | — | **Absent** (future) |

No Dependabot, CODEOWNERS, or other `.github/` config files were found.

### 1.2 Release scripts (`scripts/release/`)

| Script | Role |
|--------|------|
| `publish.sh` | One-command bump + CHANGELOG finalize + commit + annotated tag + push (triggers Release) |
| `bump_version.sh` | SemVer bump for `ai_tray/pubspec.yaml` |
| `extract_changelog.sh` | Extracts CHANGELOG section for GitHub Release body (used by `release.yml`) |

### 1.3 CI documentation

| Path | Notes |
|------|--------|
| `docs/release/CI-CD.md` | Operator guide; matches current `ci.yml` / `release.yml` behavior (PR Build macOS; main = quality only; tag/dispatch release) |
| `docs/release/pd-016/PD-016-ci-cd-automation.md` | PD-016 design doc; **partially stale** (still mentions macOS x64 release matrix and “ephemeral macOS artifact on main”) |

### 1.4 Local hooks

| Item | Status |
|------|--------|
| Lefthook / pre-commit config | **Not present** in repo |
| Documented local checks | Manual commands in `docs/release/CI-CD.md` (format / analyze / test / build) |

---

## 2. Workflow deep dive

### 2.1 `ci.yml` — CI

| Dimension | Finding |
|-----------|---------|
| **Filename** | `.github/workflows/ci.yml` |
| **Triggers** | `pull_request` → `main`; `push` → `main` |
| **Feature branch pushes** | **No** — feature work only hits CI via PR to `main` |
| **PRs** | **Yes** — full quality + Build macOS |
| **Main** | **Yes** — Format / Analyze / Test only (`Build macOS` skipped) |
| **Tags** | **No** |
| **Path filters** | **None** — docs-only and code PRs cost the same |
| **Concurrency** | `group: ci-${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: true` |
| **Env pins** | Flutter `3.38.9`, Node `22.17.0`, npm `10.9.2`, `WORKING_DIRECTORY: ai_tray` |
| **Caches** | `subosito/flutter-action@v2` `cache: true` on all Flutter jobs; `actions/setup-node@v4` npm cache on Test + Build macOS (`ai_tray/tool/copilot_sdk_bridge/package-lock.json`) |
| **Artifacts** | **None** uploaded |
| **Duplication** | Flutter setup + `pub get` repeated across Format / Analyze / Test / Build macOS (expected for parallel jobs; no reusable workflow / composite action) |

#### Jobs

| Job `name` (status check) | Runner | Timeout | When | Steps (summary) |
|---------------------------|--------|---------|------|-----------------|
| **Format** | `ubuntu-latest` | 15m | PR + main | checkout → Flutter → `pub get` → `dart format --set-exit-if-changed .` |
| **Analyze** | `ubuntu-latest` | 15m | PR + main | checkout → Flutter → `pub get` → `flutter analyze --fatal-infos` |
| **Test** | `ubuntu-latest` | 20m | PR + main | checkout → Flutter → Node + npm ci + bridge `check` → `pub get` → `flutter test --exclude-tags golden,screenshot` |
| **Build macOS** | `macos-latest` | 45m | **PR only** (`if: github.event_name == 'pull_request'`) | needs Format+Analyze+Test → Flutter → Node arm64 → sidecar assemble/verify/smoke → `pub get` → golden tests → `flutter build macos --release` → verify packaged sidecar |

**Desktop on PR/push:** Desktop **release-style build runs on every PR** to `main`. It does **not** run on push to `main`. Feature **pushes** (no PR) do not trigger CI.

**Stable check contexts** (documented for branch protection): `Format` | `Analyze` | `Test` | `Build macOS`.

---

### 2.2 `release.yml` — Release

| Dimension | Finding |
|-----------|---------|
| **Filename** | `.github/workflows/release.yml` |
| **Triggers** | Tag push `v[0-9]+.[0-9]+.[0-9]+` and `v[0-9]+.[0-9]+.[0-9]+-*`; `workflow_dispatch` with required `tag` input |
| **Feature pushes / PRs / main** | **No** |
| **Tags / dispatch** | **Yes** — aligned with Local First “tag/dispatch-only release” |
| **Path filters** | N/A (tag/dispatch only) |
| **Concurrency** | `group: release-${{ github.ref }}`, `cancel-in-progress: false` (correct for releases) |
| **Permissions** | `contents: write` |
| **Caches** | Flutter cache + npm cache on both desktop build jobs |
| **Artifacts** | `actions/upload-artifact@v4`: `AI-Tray-macOS-arm64`, `AI-Tray-Windows-x64` → downloaded in Publish → attached via `softprops/action-gh-release@v2` |
| **Duplication vs CI** | Copilot sidecar assemble/verify and macOS release build overlap with PR `Build macOS` (intentional for publish packaging; costly if both always run) |

#### Jobs

| Job `name` | Runner | Timeout | Depends on | Steps (summary) |
|------------|--------|---------|------------|-----------------|
| **Validate version** | `ubuntu-latest` | (default) | — | Resolve tag; assert `ai_tray/pubspec.yaml` version name matches tag |
| **Build macOS arm64** | `macos-latest` | 45m | validate | Flutter + Node arm64 + sidecar → `flutter build macos --release` → zip → upload artifact |
| **Build Windows x64** | `windows-latest` | 45m | validate | Flutter + Node x64 + sidecar → `flutter build windows --release` → zip → upload artifact |
| **Publish GitHub Release** | `ubuntu-latest` | (default) | validate + both builds | Download artifacts → `extract_changelog.sh` → create/update GitHub Release with zips |

**Not published:** macOS Intel/x64 (policy D-007 / current `CI-CD.md`). PD-016 doc still mentions x64 — treat as historical.

---

## 3. Trigger matrix (when CI spend happens)

| Event | `ci.yml` | `release.yml` | Desktop build? |
|-------|----------|---------------|----------------|
| Push to feature branch | No | No | No |
| Pull request → `main` | Yes (4 jobs; macOS gated on) | No | **Yes (macOS)** |
| Push / merge → `main` | Yes (3 jobs; Build macOS skipped) | No | No |
| Tag `vX.Y.Z` (+ prerelease suffix) | No | Yes | **Yes (macOS + Windows)** |
| `workflow_dispatch` (Release) | No | Yes | **Yes (macOS + Windows)** |
| Docs-only change on PR | Yes (full PR suite) | No | **Yes (macOS)** — no path filter |

---

## 4. Runtime & Actions minutes (evidence-based)

### 4.1 Evidence sources

1. Workflow job counts and OS runners (YAML).  
2. Recent Actions history via `gh run list` / `gh run view` (sampled 2026-07-12 → 2026-07-19).  
3. Tag / release frequency from `gh run list --workflow=release.yml` and `git tag`.

**Not available / not used as fact:** GitHub billing dashboard export, organization Actions minutes invoice, or a measured “X minutes/month” figure. **Do not treat any monthly total below as measured spend.**

### 4.2 Observed wall-clock (sample successful runs)

| Scenario | Run (example) | Wall-clock | Job notes |
|----------|---------------|------------|-----------|
| PR (quality + Build macOS) | `29674308575` (2026-07-19) | **~8m 17s** | Format ~0.7m, Analyze ~0.9m, Test ~1.9m (parallel); Build macOS ~6.2m after needs |
| Main push (no desktop) | `29669052255` (2026-07-19) | **~1m 38s** | Format/Analyze/Test only; Build macOS **skipped** |
| Release tag | `29628977667` `v1.3.3` | **~11m 0s** | Validate ~4s; macOS arm64 ~3.4m; Windows ~10.2m (parallel); Publish ~0.5m |

Other recent successful PRs in the same window typically land in **~5–8 minutes** wall-clock when Build macOS runs. Main pushes without desktop typically **~1.5–8 minutes** (variance from queue/cache/test load). Releases in history: **~9–13 minutes** wall-clock.

### 4.3 Billing-minute model (assumptions — not measured)

GitHub Actions billable minutes are generally **sum of job runtimes × OS multiplier**, not wall-clock of the workflow. Multipliers used for **estimation only** (verify against current GitHub pricing docs for the account plan):

| Runner label | Assumed multiplier |
|--------------|--------------------|
| `ubuntu-latest` | **1×** |
| `windows-latest` | **2×** |
| `macos-latest` | **10×** |

**Illustrative billable minutes per successful event** (using sample job durations above):

| Event | Approx. raw job-minutes | Approx. billable (× multiplier) |
|-------|-------------------------|----------------------------------|
| PR → `main` | Format 0.7 + Analyze 0.9 + Test 1.9 + macOS 6.2 ≈ **9.7** | 0.7+0.9+1.9 + **62** ≈ **~65** |
| Push → `main` | Format+Analyze+Test ≈ **3–6** | **~3–6** |
| Release tag | Validate ~0.1 + macOS 3.4 + Windows 10.2 + Publish 0.5 ≈ **14.2** | 0.1 + **34** + **20.4** + 0.5 ≈ **~55** |

### 4.4 Recent activity intensity (observed window ≈ 1 week)

From `gh run list` (CI + Release, ~2026-07-12–2026-07-19):

| Signal | Observation |
|--------|-------------|
| CI PR successes | Multiple (~8+ completed success PRs in sample); concurrency cancels visible on rapid pushes |
| CI main pushes | Frequent; several **cancelled** when a newer push superseded; two **failures** on 2026-07-19 completed in **~4s** (jobs failed immediately — likely infra/permissions/checkout, not full Flutter suite) |
| Release successes | **5** tagged Release runs: `v1.0.0`, `v1.1.0`, `v1.2.0`, `v1.3.2`, `v1.3.3` |
| Tags in repo | `v1.0.0-rc2`, `v1.0.0`, `v1.1.0`, `v1.2.0`, `v1.3.0`–`v1.3.3` (burst of releases mid-July) |

This week was an **active development / release burst**. Extrapolating that pace to a full month would overstate steady-state cost.

### 4.5 Monthly estimate — scenarios (explicitly hypothetical)

Product Owner **target: &lt;300 Actions minutes / month** may be cited as a **goal**, not as current measured spend.

| Scenario | Assumptions | Rough billable estimate |
|----------|-------------|-------------------------|
| **A. Burst month** (like observed week ×4) | ~32 PRs×65 + ~40 main×4 + ~20 releases×55 | **Order of ~3k+** — speculative; **not measured** |
| **B. Moderate product month** | 8 PRs×65 + 12 main×4 + 2 releases×55 | **~520 + 48 + 110 ≈ ~680** |
| **C. Local First target shape** | 8 PRs **without** macOS (~4–8 billable each) + path-filtered / no redundant main CI + 2 releases×55 | **~50–100 + ~110 ≈ ~160–210** — under **&lt;300** target **if** desktop leaves PR path |

**Verdict:** Billing minutes **cannot be proven** from this audit. The dominant cost driver in the **current** design is **macOS on every PR** (assumed 10× multiplier). Release is already tag/dispatch-only and appropriately expensive only when shipping.

---

## 5. Gaps vs Local First target architecture

Target split (EP-004A / Local First):  
`quality.yml` · `release.yml` · `documentation.yml` · `maintenance.yml` · future `security.yml`  
with **PR-only quality**, **tag/dispatch-only release**, **no desktop on PR/push**, path filters, concurrency cancel, caching, and **Lefthook** local validation.

| Target | Current state | Gap |
|--------|---------------|-----|
| `quality.yml` (PR-only quality) | Single `ci.yml`; quality runs on **PR and main push** | Split/rename; stop redundant main re-run or make it path-filtered / optional |
| `release.yml` tag/dispatch only | **Already aligned** | Keep; ensure docs match (PD-016 stale bits) |
| No desktop on PR/push | **Desktop on every PR** | **Largest gap** — move macOS (+ Windows) exclusively to Release |
| `documentation.yml` | Absent; docs changes still run full CI + macOS on PR | Add docs path-filtered lightweight workflow (or skip quality when only docs) |
| `maintenance.yml` | Absent; no Dependabot | Scheduled dependency / cache hygiene optional |
| `security.yml` (future) | Absent | Defer until needed |
| Path filters | None | Add for `ai_tray/**`, workflows, lockfiles vs `docs/**` |
| Concurrency cancel | Present on CI; correct off on Release | Keep |
| Caching | Flutter + npm already | Keep; consider pub cache explicitness if split workflows |
| Lefthook local validation | **Missing** | Add format/analyze/test (and optional bridge check) pre-push/pre-commit to offset removing PR desktop |
| Branch protection | Docs require `Build macOS` | Must update required checks if desktop leaves PR CI |

---

## 6. Optimization opportunities (priority)

1. **Remove `Build macOS` from PR CI** — largest Actions-minute lever; ship desktop only via `release.yml`. Compensate with Lefthook + optional manual `workflow_dispatch` “desktop smoke” if needed.  
2. **PR-only quality; reduce main-push CI** — main already skips desktop; still pays 3 Ubuntu jobs per merge/commit. Prefer PR gates + optional main path filters.  
3. **Introduce path filters** — skip or shrink runs for `docs/**`, markdown-only, changelog-only.  
4. **Split workflows toward Local First names** — `quality.yml` / keep `release.yml` / add `documentation.yml` / `maintenance.yml` without changing app code.  
5. **Add Lefthook** — local format + analyze + test (+ npm bridge check) before push.  
6. **Deduplicate Flutter/Node setup** later via composite action (secondary; clarity more than minutes).  
7. **Refresh stale docs** — especially `PD-016-ci-cd-automation.md` (x64 matrix / main artifact claims).  
8. **Investigate 2026-07-19 main CI ~4s failures** — separate from spend; reliability signal after merges #8/#9.

---

## 7. Duplication & consistency notes

| Topic | Note |
|-------|------|
| Flutter / Node pins | Duplicated env blocks in `ci.yml` and `release.yml` (same versions today) |
| Sidecar assemble | Repeated in CI Build macOS and both Release desktop jobs |
| PD-016 vs live YAML | PD-016 still describes macOS x64 release job and main ephemeral artifact; **live YAML does not** |
| `CI-CD.md` vs live YAML | **Aligned** with PR-only Build macOS and tag/dispatch release |

---

## 8. Summary findings

1. **Two workflows only:** `ci.yml` + `release.yml`. No quality/docs/maintenance/security split yet.  
2. **Release path is already Local First–shaped** (tags + `workflow_dispatch`; macOS arm64 + Windows artifacts).  
3. **Primary cost / policy gap:** **macOS desktop build (+ goldens) on every PR**, with **no path filters**, and **quality re-run on every main push**.  
4. **Caching and CI concurrency cancel are already in place**; Lefthook is not.  
5. **Measured monthly spend is unknown**; sample runs suggest ~**65 billable min/PR** and ~**55 billable min/release** under stated multipliers. PO **&lt;300/month** is a **target**; achieving it likely requires **removing PR desktop builds** and moderating release frequency.  
6. **Audit branch:** `cursor/post-ep002-stabilization` (upstream gone); **working tree was clean** before adding this file.

---

## 9. Explicit non-actions (this deliverable)

- Did **not** create or rewrite workflow YAML.  
- Did **not** add Lefthook.  
- Did **not** update handoff / PROJECT_STATE docs.  
- Did **not** commit, push, or open a PR.

---

## 10. Related paths

- `.github/workflows/ci.yml` *(removed in EP-004A implementation)*  
- `.github/workflows/quality.yml`  
- `.github/workflows/documentation.yml`  
- `.github/workflows/maintenance.yml`  
- `.github/workflows/release.yml`  
- `lefthook.yml`  
- `scripts/ci/validate_handoff.sh`  
- `scripts/ci/check_conventional_commit.sh`  
- `scripts/release/publish.sh`  
- `scripts/release/bump_version.sh`  
- `scripts/release/extract_changelog.sh`  
- `docs/release/CI-CD.md`  
- `docs/devops/LOCAL_DEVELOPMENT.md`  
- `docs/release/pd-016/PD-016-ci-cd-automation.md`

---

## 11. Post-change status (EP-004A implementation)

**Implemented:** 2026-07-19 (working tree; not committed by the implementing agent).

### Architecture now

| Workflow | Role |
|----------|------|
| `quality.yml` | PR + push → `main`; Format / Analyze / Test / Validate workflows; **no desktop** |
| `documentation.yml` | Docs / markdown paths; handoff + JSON + relative links; no Flutter |
| `release.yml` | Tag `v*` + `workflow_dispatch`; macOS arm64 + Windows x64 publish (unchanged triggers) |
| `maintenance.yml` | Weekly + dispatch; informational `flutter pub outdated` / `npm outdated` |
| `ci.yml` | **Deleted** (replaced by Quality; PR `Build macOS` removed) |

Also: `lefthook.yml` + `docs/devops/LOCAL_DEVELOPMENT.md`; pub cache keyed by `ai_tray/pubspec.lock`.

### Projected spend (still not measured)

Using §4.3 sample multipliers and scenario **C** from §4.5:

| Lever | Effect vs audit baseline |
|-------|--------------------------|
| Remove PR macOS (~62 billable min/PR in sample model) | Dominant reduction |
| Docs-only Flutter no-op via path filter | Avoids unnecessary Ubuntu Flutter jobs |
| Release unchanged (~55 billable/release in sample) | Still the main ship cost |

**Target remains Product Owner &lt;300 Actions minutes / month.** Scenario C projection (~160–210 under moderate PR/release assumptions) is unchanged as a **projection** — not a billing export.

### Operator follow-ups

1. Update GitHub branch protection: require `Format` \| `Analyze` \| `Test` \| `Validate workflows`; **remove** `Build macOS`.
2. Enable Lefthook per clone (`lefthook install`) — not global.
3. `security.yml` remains deferred (no invented scanners).
4. PD-016 design doc may still mention historical x64 / main artifact claims — treat live YAML + `CI-CD.md` as source of truth.
