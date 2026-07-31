# Documentation rules

**Normative.** How AI Tray documentation is organized and maintained.

**Updated:** 2026-07-31  
**Related:** [README.md](README.md) · [AGENTS.md](../AGENTS.md) · [process/](process/)

---

## Principles

1. **`docs/project/` is the session source of truth** for agents (handoff package).
2. **`docs/` is the human/agent documentation tree** — process, architecture, guides, release.
3. **Never invent implementation details** that ADRs / DECISION_LOG have not decided.
4. **Never create placeholder documentation.**
5. **Never duplicate.** Prefer one normative page plus links.
6. **Prefer linking over copying.**
7. **Archive instead of deleting** when content is outdated but historically useful.
8. **Mark deprecated docs** clearly rather than silently diverging.
9. **Root `AI_Tray_*.md` PO docs are historical** — living roadmap is
   [`project/ROADMAP.md`](project/ROADMAP.md).
10. **Product-as-demo (PD-025)** — do not invent a second “demo docs” SoT that
    implies a Flutter Web playground.

---

## Folder roles

| Area | Role |
| --- | --- |
| [`project/`](project/) | Eight-file handoff + `PROJECT_CONTEXT.json` (agent SoT) |
| [`process/`](process/) | Governance: issues, PRs, CI checks, DoD |
| [`adr/`](adr/) | Architecture Decision Records (why) |
| [`architecture/`](architecture/) | System / provider / folder architecture |
| [`guides/`](guides/) | User and contributor how-tos |
| [`providers/`](providers/) | Per-provider integration guides |
| [`design/`](design/) | Design system |
| [`devops/`](devops/) | Local First, CI audit, demo strategy |
| [`dogfood/`](dogfood/) | Manual QA / dogfood hub |
| [`release/`](release/) | CI-CD, release notes, PD folders, QA |
| [`research/`](research/) | Provider / epic research (not production code) |
| [`stabilization/`](stabilization/) | Post-RC / post-EP stabilization records |
| [`reports/`](reports/) | Audits, status reports, upgrade plans |
| [`planning/`](planning/) | Historical planning packages |
| [`templates/`](templates/) | Document templates (ADR, etc.) |
| [`assets/`](assets/) | Screenshots and static assets |

---

## Source-of-truth layers

| Concern | Canonical location |
| --- | --- |
| What to do next (agents) | `project/NEXT_SESSION.md` |
| Machine-readable state | `project/PROJECT_CONTEXT.json` |
| Product decisions | `project/DECISION_LOG.md` |
| Architecture decisions | `adr/` (+ link from DECISION_LOG) |
| How to contribute | root `CONTRIBUTING.md` |
| Agent entry | root `AGENTS.md` |
| Required CI checks | `process/CI_REQUIRED_CHECKS.md` |
| Demo strategy | `devops/DEMO_STRATEGY.md` |

---

## When updating docs

- After feature/bug/architecture/process changes: review the full handoff package
  (see `.cursor/rules/project-handoff.mdc`).
- Fix broken relative links; documentation CI validates handoff consistency.
- New process docs belong under `process/`. New one-off reports belong under
  `reports/` with an index entry.
