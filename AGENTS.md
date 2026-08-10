# Agents

AI / coding-agent entry for **AI Tray**.

**Do not invent architecture, APIs, or usage values.** Prefer the handoff
package, ADRs, and existing provider implementations.

## Session start (mandatory)

1. Read [`BRAIN.md`](BRAIN.md) and the relevant `brain/` pages (`brain
   list-pages`) — this is durable, code-verified project memory, and it may
   be more current than the handoff package below.
2. Read [`docs/project/AI_HANDOFF.md`](docs/project/AI_HANDOFF.md)
3. Read [`docs/project/PROJECT_CONTEXT.json`](docs/project/PROJECT_CONTEXT.json)
4. Read [`docs/project/NEXT_SESSION.md`](docs/project/NEXT_SESSION.md)
5. Verify `git status`, branch, and recent commits before changing anything —
   `docs/project/*` can lag shipped code; cross-check against `CHANGELOG.md`
   and `git log` rather than trusting its "current phase" at face value (see
   the brain's `roadmap` page for a known instance of this).
6. Follow [`.cursor/rules/project-handoff.mdc`](.cursor/rules/project-handoff.mdc)
   after significant work

## Need → open

| Need | Open |
| --- | --- |
| Current objective | [`NEXT_SESSION.md`](docs/project/NEXT_SESSION.md) |
| Executive / product / architecture state | [`docs/project/`](docs/project/) |
| Decisions (PD / D / ADR) | [`DECISION_LOG.md`](docs/project/DECISION_LOG.md) · [`docs/adr/`](docs/adr/) |
| Docs map | [`docs/README.md`](docs/README.md) |
| Local First CI | [`docs/devops/LOCAL_DEVELOPMENT.md`](docs/devops/LOCAL_DEVELOPMENT.md) |
| **CI / release (binding)** | [`docs/release/CI-CD.md`](docs/release/CI-CD.md) · [`ci.yaml`](ci.yaml) |
| Demo / showcase | [`docs/devops/DEMO_STRATEGY.md`](docs/devops/DEMO_STRATEGY.md) |
| Dogfood / manual QA | [`docs/dogfood/README.md`](docs/dogfood/README.md) |
| Copilot provider | [`docs/providers/github-copilot.md`](docs/providers/github-copilot.md) |
| Architecture | [`docs/architecture/`](docs/architecture/) |
| Parity / docs upgrade plan | [`docs/reports/v2-refactor-plan.md`](docs/reports/v2-refactor-plan.md) |
| Contributing | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Security | [`SECURITY.md`](SECURITY.md) |

## Hard constraints

- Feature-first Clean Architecture: UI → State → Domain → Data
- Riverpod Notifier / AsyncNotifier / AsyncValue only (no legacy StateNotifier)
- UI never calls external CLI/SDK/API directly; DTOs map to domain before UI
- Provider-scoped single-flight refresh, LKG cache, stale rejection
- Never invent usage values; label stale data
- No `/copilot_internal`, undocumented APIs, or scraping
- No Cursor personal quota provider (PD-023)
- No Flutter Web tray playground (PD-025)
- EP-004 = targeted cleanup, not full rewrite (ADR-004)
- Quality CI is Ubuntu-only; desktop builds only on `release/**` PRs and tags ([docs/release/CI-CD.md](docs/release/CI-CD.md))
- Never invent a permanent `dev` branch; never put macOS/Windows on feature PRs
- Version + CHANGELOG on `release/x.y.z` before merge; tag only after merge; tag rebuilds then publishes
- Conventional Commits; do not push unless asked
- After significant work: review/update the eight-file `docs/project/` package

## App roots

| Path | Role |
| --- | --- |
| `ai_tray/` | Flutter desktop app |
| `ai_tray/tool/copilot_sdk_bridge/` | Node Copilot SDK sidecar |
| `docs/project/` | Session source of truth |
| `showcase/` | Product-as-demo contract (PD-025) |

<!-- BEGIN brain.md -->
## Project Brain

This project keeps a **Project Brain**: a persistent memory layer of its durable decisions, requirements, and constraints. Read `./BRAIN.md` for the full read/write contract.

Use it actively:
- Before any task or discussion, load the relevant brain context with the `brain` CLI's read commands.
- Whenever a decision, requirement, constraint, or durable insight surfaces — in discussion or in code — record it with the `brain` CLI before moving on; don't wait to be asked.
- All reads and writes go through the `brain` CLI — never hand-edit brain files.

The brain skills (`brain-setup`, `brain-page`, `brain-ingest`, `brain-bootstrap`) are installed in your global skills directory.
<!-- END brain.md -->

### AI Tray project-brain workflow

Before substantial work:

1. Read `BRAIN.md`.
2. Read the relevant `brain/` pages for the area you're touching
   (`brain list-pages`, `brain read-page <id>`, `brain read-root <slug>`).
3. Consult the matching ADR under `docs/adr/` when a change touches
   architecture — brain pages say *what's true now*, ADRs say *why it was
   decided*.
4. Verify important assumptions against source code before acting on them;
   brain content can lag a fast-moving redesign (see `roadmap`'s
   release-freeze note for a live example).

Update the brain only when durable project knowledge changes (architecture,
product direction, constraints, roadmap, a new rejected approach). Routine
code changes, bug fixes, and doc-drift catch-up do not need a brain update.
