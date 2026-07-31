# Agents

AI / coding-agent entry for **AI Tray**.

**Do not invent architecture, APIs, or usage values.** Prefer the handoff
package, ADRs, and existing provider implementations.

## Session start (mandatory)

1. Read [`docs/project/AI_HANDOFF.md`](docs/project/AI_HANDOFF.md)
2. Read [`docs/project/PROJECT_CONTEXT.json`](docs/project/PROJECT_CONTEXT.json)
3. Read [`docs/project/NEXT_SESSION.md`](docs/project/NEXT_SESSION.md)
4. Verify `git status`, branch, and recent commits before changing anything
5. Follow [`.cursor/rules/project-handoff.mdc`](.cursor/rules/project-handoff.mdc)
   after significant work

## Need → open

| Need | Open |
| --- | --- |
| Current objective | [`NEXT_SESSION.md`](docs/project/NEXT_SESSION.md) |
| Executive / product / architecture state | [`docs/project/`](docs/project/) |
| Decisions (PD / D / ADR) | [`DECISION_LOG.md`](docs/project/DECISION_LOG.md) · [`docs/adr/`](docs/adr/) |
| Docs map | [`docs/README.md`](docs/README.md) |
| Local First CI | [`docs/devops/LOCAL_DEVELOPMENT.md`](docs/devops/LOCAL_DEVELOPMENT.md) |
| CI/CD | [`docs/release/CI-CD.md`](docs/release/CI-CD.md) |
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
- Quality CI is Ubuntu-only; desktop builds only in Release CD
- Conventional Commits; do not push unless asked
- After significant work: review/update the eight-file `docs/project/` package

## App roots

| Path | Role |
| --- | --- |
| `ai_tray/` | Flutter desktop app |
| `ai_tray/tool/copilot_sdk_bridge/` | Node Copilot SDK sidecar |
| `docs/project/` | Session source of truth |
| `showcase/` | Product-as-demo contract (PD-025) |
