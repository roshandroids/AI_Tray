# AI Tray — Decision Log

**Updated:** 2026-07-31

This is the concise cross-epic decision index. Detailed rationale remains in
ADRs, provider research, and implementation reports.

## Approved Product Decisions

| ID | Date | Status | Decision | Rationale | Impact |
| --- | --- | --- | --- | --- | --- |
| PD-021 | 2026-07-16 | Approved / implemented | Adopt the terminal-inspired design system and capability-driven multi-provider platform | A shared UI prevents provider-specific duplication and preserves Claude behavior | Established `ProviderRegistry`, shared dashboard components, tokens, themes, and provider selector |
| PD-023 | 2026-07-18 | Approved | Do not implement Cursor Agent as a personal quota provider until Cursor publishes an official consumer usage-summary API; any automation provider requires a separate epic | Supported interfaces expose automation, auth, models, and per-run tokens, but not Hobby/Pro remaining %, reset date, or pool balances; EP-003A confirmed `/usage` print prompts return prose, not quota; dashboard scraping is unsupported and conflicts with ToS | EP-003/EP-003A stop after research; no Cursor production code; roadmap may consider a separate automation-only epic |
| PD-024 | 2026-07-19 | Approved | Treat post-EP-002 EP-004 posture as **targeted cleanup**, not a full provider-platform rewrite and not a pure no-go | Stabilization fixed shared orchestration defects without a rewrite; ~35 compatibility aliases and thin capability metadata remain; no third quota provider is planned (PD-023); full-epic triggers are unmet | Canonicalize `core/` + `copilot/` imports; deprecate aliases; enrich metadata; choose one retry owner; keep refresh/cache/sidecar architecture |
| PD-025 | 2026-07-27 | Approved | AI Tray is a product repo: the desktop app is the demo; Showcase lists it in `showcase/demos.json` (`id: main`, `type: desktop`) via GitHub Releases; no duplicate playground or Flutter Web embed | Demo Standard: application = demo; tray/CLI/sidecar cannot embed on web | `demos.json` product entry; reusable web-demo workflow for other RSProjects only; `docs/devops/DEMO_STRATEGY.md` |

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
| D-017 | 2026-07-31 | Name and enforce **Quality CI + Release CD**: Ubuntu-only Quality on PR/push; macOS/Windows exclusively in Release CD (tag/`workflow_dispatch`); Quality validates companions stay ubuntu-only | Active; hardens D-015; delete legacy `ci.yml` on merge to `main` |

## Decision maintenance

- Add a row only for durable product or architecture decisions.
- Record reversals as new rows; do not silently rewrite history.
- Keep detailed evidence in an ADR/research report and link it from state docs.
