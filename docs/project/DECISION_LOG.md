# AI Tray — Decision Log

**Updated:** 2026-08-02

This is the concise cross-epic decision index. Detailed rationale remains in
ADRs, provider research, and implementation reports.

## Approved Product Decisions

| ID | Date | Status | Decision | Rationale | Impact |
| --- | --- | --- | --- | --- | --- |
| PD-021 | 2026-07-16 | Approved / implemented | Adopt the terminal-inspired design system and capability-driven multi-provider platform | A shared UI prevents provider-specific duplication and preserves Claude behavior | Established `ProviderRegistry`, shared dashboard components, tokens, themes, and provider selector |
| PD-023 | 2026-07-18 | Approved | Do not implement Cursor Agent as a personal quota provider until Cursor publishes an official consumer usage-summary API; any automation provider requires a separate epic | Supported interfaces expose automation, auth, models, and per-run tokens, but not Hobby/Pro remaining %, reset date, or pool balances; EP-003A confirmed `/usage` print prompts return prose, not quota; dashboard scraping is unsupported and conflicts with ToS | EP-003/EP-003A stop after research; no Cursor production code; roadmap may consider a separate automation-only epic |
| PD-024 | 2026-07-19 | Approved | Treat post-EP-002 EP-004 posture as **targeted cleanup**, not a full provider-platform rewrite and not a pure no-go | Stabilization fixed shared orchestration defects without a rewrite; ~35 compatibility aliases and thin capability metadata remain; no third quota provider is planned (PD-023); full-epic triggers are unmet | Canonicalize `core/` + `copilot/` imports; deprecate aliases; enrich metadata; choose one retry owner; keep refresh/cache/sidecar architecture |
| PD-025 | 2026-07-27 | Approved | AI Tray is a product repo: the desktop app is the demo; Showcase lists it in `showcase/demos.json` (`id: main`, `type: desktop`) via GitHub Releases; no duplicate playground or Flutter Web embed | Demo Standard: application = demo; tray/CLI/sidecar cannot embed on web | `demos.json` product entry; reusable web-demo workflow for other RSProjects only; `docs/devops/DEMO_STRATEGY.md` |
| PD-026 | 2026-07-31 | Approved / implemented | Ship branded FlexColorScheme personalization: custom theme presets, bundled fonts, app-icon architecture with graceful unsupported platforms | Users need selectable appearance without rewriting tray surfaces; offline desktop forbids runtime font downloads | `lib/theme/` + Settings Appearance pickers; persist via `settings_v1_*`; ADR-005 |
| PD-027 | 2026-07-31 | Approved / implemented | Menu bar: adaptive title density (default), always-%, or icon-only; configurable reveal threshold (default 90%); monochrome template glyph with opacity pulse on refresh; tooltip always has full usage; no usage encoding in the icon | Persistent `%` is noisy; premium macOS extras stay quiet until attention is useful | `TrayDisplayMode` + settings; G1 solid template assets; concise native tray menu |
| PD-028 | 2026-08-01 | Approved / implemented | Ship V2 Milestone 1 (Session Browser + Detail, read-only) and Milestone 2 (manual resume, Resume Queue, NotificationGateway migration, click-to-resume completion notification) as scoped in `docs/planning/v2-vision-and-roadmap.md`; Milestone 3 (Resume Scheduler) and Session Analytics remain explicitly deferred, gated on real M2 usage evidence rather than a timer | First mutating capability the app has ever shipped (prior surface was read-only usage/quota); safety model mandates a budget cap on every queued item and no unattended cancellation | `features/sessions/{browser,detail,resume,queue}/`; `core/notifications/`; see `docs/planning/v2-implementation-log.md` for the story-by-story record |
| PD-029 | 2026-08-02 | Approved | Repository enters release freeze: no new features until documentation, release engineering, and OSS scaffold are confirmed consistent with shipped code; repo-visibility (private → public) remains a separate, explicit Product Owner decision, not an automatic outcome of the freeze | `docs/project/*` had drifted a full PR + a merged feature milestone behind actual `main`; OSS-facing docs (README, SECURITY.md, CONTRIBUTING.md) already read as if the repo is public when it is still private | This freeze pass (docs sync, CI/dependency/dead-code audit, OSS scaffold check); see `ROADMAP.md` exit criteria |

## Architecture and operational decisions

| ID | Date | Decision | Status / consequence |
| --- | --- | --- | --- |
| D-001 | 2026-07-12 | Use installed Claude CLI as the MVP usage source | Accepted; parse defensively and keep fixtures |
| D-002 | 2026-07-12 | Standardize failures, bounded retry, single-flight, and LKG cache | Normative resilience model; never invent usage |
| D-003 | 2026-07-16 | Adopt `AIProvider`, `ProviderRegistry`, capabilities, and shared UI | Accepted; no provider-specific pages |
| D-004 | 2026-07-17 | Integrate Copilot only through official SDK `account.getQuota` | Accepted as experimental with graceful degradation |
| D-005 | 2026-07-17 | Reject `/copilot_internal`, undocumented APIs, and TUI scraping | Permanent integration constraint |
| D-006 | 2026-07-17 | Bundle a versioned Node sidecar for Copilot SDK/runtime | Accepted; packaging is part of release verification |
| D-007 | 2026-07-17 | Publish macOS arm64 + Windows x64; drop macOS Intel artifact | Active release policy |
| D-008 | 2026-07-17 | Do not build artifacts on main push; publish only by tag/manual dispatch | Active CI/release policy |
| D-009 | 2026-07-18 | Apply PD-023 to provider planning | Cursor personal quota provider remains blocked |
| D-010 | 2026-07-18 | Allow future Cursor automation only as a separate product epic | Requires Product Owner approval and explicit non-goals |
| D-011 | 2026-07-18 | Make `docs/project/` the official AI handoff package | Active; update after every epic/phase/major feature/release |
| D-012 | 2026-07-19 | Close EP-002 Phase 3 as merged on main (`2885980`); keep Phase 3 out of a docs-only release | Active; next product release remains an explicit Product Owner decision |
| D-013 | 2026-07-19 | Complete post-EP-002 stabilization before any EP-004 folder rewrite | Done; see ADR-004 / PD-024 |
| D-014 | 2026-07-19 | Accept ADR-004 targeted cleanup as the EP-004 posture | Active; full rewrite is contingency-only |
| D-015 | 2026-07-19 | Local First CI (EP-004A): no desktop builds on PR/main; Quality + Documentation + Release (tag/dispatch) + Maintenance; Lefthook optional locally | Active; supersedes PR `Build macOS` required check; PO target &lt;300 Actions min/month |
| D-016 | 2026-07-27 | Demo/Showcase: product-as-demo — `showcase/demos.json` lists `main` (desktop/Releases); no Flutter Web playground; ship `reusable-flutter-web-demo.yml` as callable template unused by AI Tray | Active; PD-025; see `docs/devops/DEMO_STRATEGY.md` |
| D-017 | 2026-07-31 | Name and enforce **Quality CI + Release CD**: Ubuntu-only Quality on PR/push; macOS/Windows exclusively in Release CD (tag/`workflow_dispatch`); Quality validates companions stay ubuntu-only | Active; hardens D-015; `ci.yml` removed on `main` (PR #11) |
| D-018 | 2026-07-31 | Adopt Document Platform *standard* for governance/docs without Melos or web demo: root governance, CONTRIBUTING/AGENTS, process pack, ENGINEERING_STANDARD, PROJECT_BLUEPRINT, pruned Cursor rules | Active; Master Prompt Phases 1–7; see `docs/reports/v2-refactor-plan.md` |
| D-019 | 2026-07-31 | Shared `scripts/` surface for Local DX + Remote CI; `.ci/config` `CI_MODE` is local preference only (Actions ignores it); GHA remains merge source of truth; thin workflows call `./scripts/*.sh`; hybrid release via `./scripts/publish.sh` → Release CD | Active; see `docs/devops/LOCAL_DEVELOPMENT.md` |
| D-020 | 2026-07-31 | `CHANGELOG.md` is the single source of truth for release notes; `ai_tray/assets/release_history.json` is generated by `scripts/release/sync_release_history.sh` during publish (never hand-edit); runtime version/build via `package_info_plus`; Settings About / Diagnostics surface What’s New + history | Active; see `docs/release/CI-CD.md` |
| D-021 | 2026-07-31 | Personalization via FlexColorScheme custom seeds only (no built-in Flex schemes); `PersonalizationController` owns theme mode/preset, font, app icon; derive `TrayColorTokens` from M3 `ColorScheme`; bundle Inter/JetBrains/Fira/Plex/Geist offline; `AppIconSwitcher` unsupported on desktop by default | Active; ADR-005 / PD-026 |
| D-022 | 2026-07-31 | Menu-bar title density: Adaptive (default, reveal ≥ threshold)/Always %/Icon only; threshold default 90%; template solid mark + dim pulse; tooltip always full; redesign tray dropdown to concise native labels | Active; PD-027; `docs/design/MENU_BAR_DENSITY_AND_BENCHMARK.md` |
| D-023 | 2026-08-01 | Migrate CI from repo-owned `./scripts/*.sh`-calling Actions workflows to `roshandroids/platform-ci@v1` reusable workflows, configured by root `ci.yaml`; `scripts/` remains the local-dev entrypoint and is what `platform-ci` shells out to via `scripts/ci/*.sh` | Active; PR #14. `platform-ci` is pinned to a mutable `@v1` tag, not a commit SHA — tighten before/after going public (tracked as technical debt in `ARCHITECTURE_STATE.md`) |
| D-024 | 2026-08-01 | Session management (v2) reads `~/.claude/projects/**/*.jsonl` directly — no new database, no new persisted cache beyond the Resume Queue's own bounded `SharedPreferences` store | Active; keeps the read path honest with the CLI's own on-disk state; `JsonlSessionParser` tolerates malformed/truncated files rather than failing the whole list |
| D-025 | 2026-08-01 | Resume Queue enforces a mandatory positive budget cap on every item (constructor-level `ArgumentError` if missing/non-positive) and defaults to `forkSession: true` for anything unattended, vs. `false` for the attended "Resume now" action | Active; no "run without a cap" path; unattended execution never silently mutates a transcript the user might be continuing by hand elsewhere |
| D-026 | 2026-08-02 | Disable macOS App Sandbox permanently; distribute via signed/notarized GitHub Releases instead of the Mac App Store | Active; sandbox virtualized `$HOME` for the app and every spawned `claude` child process, making Session Browser and any provider CLI call blind to real user data regardless of temporary-exception entitlements — see `Runner/Release.entitlements` for the full rationale comment |

## Decision maintenance

- Add a row only for durable product or architecture decisions.
- Record reversals as new rows; do not silently rewrite history.
- Keep detailed evidence in an ADR/research report and link it from state docs.
- The v2 vision doc originally proposed ADR-005 through ADR-010 for
  session-management decisions before ADR-005 was claimed by personalization
  (PD-026). Those ADRs were never opened even though the features they'd
  cover (M1/M2) shipped — D-024/D-025/D-026 above stand in for them in this
  log. Renumber from ADR-006 if/when they're formally written.
