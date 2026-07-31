# Cursor rules (AI Tray)

Pruned agent rules for this repository. **Do not** paste the full Document
Platform 22-rule pack — AI Tray is a single Flutter desktop app + sidecar.

## Active rules (`alwaysApply: true`)

| File | Purpose |
| --- | --- |
| `project-handoff.mdc` | Maintain `docs/project/` SoT (pre-existing) |
| `documentation-first.mdc` | Read handoff/area docs before inventing |
| `architecture.mdc` | Clean Architecture, Riverpod, provider constraints |
| `decision-records.mdc` | ADR + DECISION_LOG for significant decisions |
| `testing-standards.mdc` | Unit/widget/golden/sidecar expectations |
| `git-github-workflow.mdc` | Issue → PR → Quality CI (no PR desktop builds) |
| `security.mdc` | Secrets, CLI/sidecar trust, private vulns |
| `self-audit.mdc` | Pre-completion DoD / handoff gate |

## Compared to Document Platform — not adopted

| DP rule (approx.) | Why skipped for AI Tray |
| --- | --- |
| `00-global-engineering` | Covered by `ENGINEERING_STANDARD` + `architecture` |
| `02-task-classification` | Overkill for solo app; handoff + NEXT_SESSION suffice |
| `03`–`06` bug/feature/refactor/research workflows | Process docs + CONTRIBUTING cover this without 4 always-on rules |
| `08-documentation-standards` | Merged into `documentation-first` + `DOCUMENTATION_RULES.md` |
| `10-code-quality` | `very_good_analysis` + engineering standard |
| `11-performance` | No soft perf CI / benchmarks for tray |
| `12-accessibility` | Editor a11y pack not applicable as always-on |
| `15-dependency-management` | Melos/workspace-oriented |
| `16-release-process` | Covered by CI-CD docs + engineering standard |
| `18`–`20` project memory / repo-first / tokens | DP agent meta; AT handoff package already stronger |
| BiDi / PUBLIC_API / playground rules | Product-specific to Document Platform |

## Reasoning

- Keep **handoff** as the primary session SoT (AT strength).
- Add only rules that prevent recurring agent mistakes: inventing architecture,
  skipping tests, leaking secrets, reintroducing PR desktop builds, ignoring
  PD-023/025.
- Prefer references to `docs/process/` and `docs/ENGINEERING_STANDARD.md` over
  long duplicated rule bodies.

Selection recorded 2026-07-31 as Master Prompt Phase 6.
