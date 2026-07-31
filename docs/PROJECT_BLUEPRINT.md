# Project Blueprint

One-page map of **AI Tray**: what it is, how it is built, and where truth lives.

**Updated:** 2026-07-31  
**Status snapshot:** [project/AI_HANDOFF.md](project/AI_HANDOFF.md) ·
[project/PROJECT_CONTEXT.json](project/PROJECT_CONTEXT.json)

---

## Product vision

AI Tray is a native desktop companion that shows **AI-provider subscription
usage and health** in one shared macOS menu-bar / Windows tray experience.

- **Claude Code** — stable CLI usage + LKG cache
- **GitHub Copilot** — experimental official SDK sidecar + quota RPC
- **Cursor Agent** — research only until an official consumer usage API exists
  (PD-023)

The **product is the demo** (PD-025): GitHub Release desktop binaries via
`showcase/demos.json` (`id: main`). There is no Flutter Web playground.

Living product state: [project/PRODUCT_STATE.md](project/PRODUCT_STATE.md).

---

## Goals

1. Honest, capability-driven usage UI (never invent percentages).
2. Resilient refresh (single-flight, retry, LKG, stale rejection).
3. Multi-provider platform without per-provider UI forks.
4. Local First engineering: Quality CI on Ubuntu; desktop builds in Release CD.
5. Solo-maintainer-friendly governance and agent handoff.

---

## Architecture overview

```
Tray / Dashboard UI (Flutter)
  → Riverpod notifiers
    → Domain models + repository ports
      → Data adapters (Claude CLI, Copilot sidecar)
        → External tools / SDKs
```

Invariants: [project/ARCHITECTURE_STATE.md](project/ARCHITECTURE_STATE.md) ·
[guides/architecture-overview.md](guides/architecture-overview.md) ·
[architecture/provider-platform.md](architecture/provider-platform.md) ·
[adr/](adr/).

Engineering rules: [ENGINEERING_STANDARD.md](ENGINEERING_STANDARD.md) ·
[process/ENGINEERING_PRINCIPLES.md](process/ENGINEERING_PRINCIPLES.md).

---

## Repository layout

```text
AI_Tray_Project/
├── ai_tray/                 # Flutter app + tool/copilot_sdk_bridge
├── docs/                    # Documentation (this tree)
├── showcase/                # RSProjects demo contract
├── scripts/                 # CI / release helpers
├── research/                # PoC / historical research
├── .github/                 # Workflows, templates, CODEOWNERS
├── .cursor/rules/           # Agent rules
├── CONTRIBUTING.md · AGENTS.md · LICENSE · SECURITY.md · …
└── README.md · CHANGELOG.md · lefthook.yml
```

---

## Documentation map

| Need | Start here |
| --- | --- |
| Docs switchboard | [README.md](README.md) |
| Doc rules | [DOCUMENTATION_RULES.md](DOCUMENTATION_RULES.md) |
| Agent session | [../AGENTS.md](../AGENTS.md) → [project/](project/) |
| Contribute | [../CONTRIBUTING.md](../CONTRIBUTING.md) → [process/](process/) |
| Engineering bar | [ENGINEERING_STANDARD.md](ENGINEERING_STANDARD.md) |
| Cursor / agent rules | [../.cursor/README.md](../.cursor/README.md) |
| Reports / audits | [reports/](reports/) |

---

## Development workflow

1. Read handoff (`AI_HANDOFF` → `PROJECT_CONTEXT` → `NEXT_SESSION`).
2. Open/claim an Issue for non-trivial work.
3. Branch from `main`; implement in `ai_tray/` (+ sidecar if needed).
4. Validate locally ([devops/LOCAL_DEVELOPMENT.md](devops/LOCAL_DEVELOPMENT.md)).
5. Open PR; Quality CI must pass ([process/CI_REQUIRED_CHECKS.md](process/CI_REQUIRED_CHECKS.md)).
6. Maintainer approval → merge.
7. Update handoff when state changes.

Governance: [process/REPOSITORY_GOVERNANCE.md](process/REPOSITORY_GOVERNANCE.md) ·
DoD: [process/DEFINITION_OF_DONE.md](process/DEFINITION_OF_DONE.md).

---

## Release workflow

Quality CI never builds desktop apps. Release CD (tag / `workflow_dispatch`)
produces macOS arm64 and Windows x64 artifacts.

Details: [release/CI-CD.md](release/CI-CD.md) · Demo:
[devops/DEMO_STRATEGY.md](devops/DEMO_STRATEGY.md).

---

## Roadmap overview

See [project/ROADMAP.md](project/ROADMAP.md). Current themes:

- Land / protect Quality CI + Release CD on `main`
- macOS dogfood; Phase 3 release timing
- ADR-004 targeted cleanup (imports, metadata, single retry owner)
- Docs/engineering parity (this upgrade) without Melos or web demo

---

## Getting started

```bash
# App
cd ai_tray
flutter pub get
flutter run -d macos

# Quality (before PR)
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot

# Copilot bridge
cd tool/copilot_sdk_bridge && npm ci && npm run check
```

Install builds: [guides/installation.md](guides/installation.md).  
User guide: [guides/user-guide.md](guides/user-guide.md).
