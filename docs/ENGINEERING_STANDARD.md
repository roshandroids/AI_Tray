# Engineering Standard

**Normative summary** for AI Tray engineering practice. Prefer linking to
detailed docs rather than duplicating them.

**Updated:** 2026-07-31  
**Related:** [process/ENGINEERING_PRINCIPLES.md](process/ENGINEERING_PRINCIPLES.md) ·
[CONTRIBUTING.md](../CONTRIBUTING.md) · [AGENTS.md](../AGENTS.md)

---

## 1. Repository & folder structure

| Path | Role |
| --- | --- |
| `ai_tray/` | Flutter desktop application (app package root) |
| `ai_tray/lib/features/` | Feature modules (Clean Architecture layers) |
| `ai_tray/lib/core/` | Shared errors, logging, DI, utilities |
| `ai_tray/tool/copilot_sdk_bridge/` | Node Copilot SDK sidecar |
| `docs/` | Documentation tree ([DOCUMENTATION_RULES.md](DOCUMENTATION_RULES.md)) |
| `docs/project/` | Agent handoff source of truth |
| `showcase/` | Product-as-demo contract (PD-025) |
| `scripts/` | CI / release helper scripts |
| `.github/workflows/` | Quality CI, docs, Release CD, maintenance |

Canonical layout detail: [architecture/folder-structure.md](architecture/folder-structure.md).

---

## 2. Feature structure

Each feature under `ai_tray/lib/features/<name>/` follows:

```text
presentation/   # widgets, notifiers (UI + state)
domain/         # models, repository ports, failures
data/           # DTOs, parsers, repositories, sources/adapters
```

Provider platform canonical namespaces (ADR-004):

- `features/providers/core/`
- `features/providers/copilot/`

Legacy `domain/` + `data/` aliases are debt to deprecate — do not expand them.

Overview: [guides/architecture-overview.md](guides/architecture-overview.md) ·
[architecture/provider-platform.md](architecture/provider-platform.md).

---

## 3. Naming

| Kind | Convention |
| --- | --- |
| Dart files / folders | `snake_case` |
| Types | `PascalCase` |
| Providers | `camelCase` + `Provider` / `Notifier` suffix as existing code |
| ADRs | `ADR-NNN-kebab-title.md` under `docs/adr/` |
| Product decisions | `PD-NNN` in `docs/project/DECISION_LOG.md` |
| Engineering decisions | `D-NNN` in DECISION_LOG |
| Epics / research | `EP-NNN`, `RH-NNN`, `S-NNN` as established |
| Commits | Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, …) |

---

## 4. Documentation rules

Follow [DOCUMENTATION_RULES.md](DOCUMENTATION_RULES.md).

After significant work, review the eight-file handoff package
([`.cursor/rules/project-handoff.mdc`](../.cursor/rules/project-handoff.mdc)).

---

## 5. ADR workflow

1. Copy [templates/ADR_TEMPLATE.md](templates/ADR_TEMPLATE.md).
2. Place under `docs/adr/ADR-NNN-….md`.
3. Index in [adr/README.md](adr/README.md).
4. Cross-link product-visible outcomes in
   [project/DECISION_LOG.md](project/DECISION_LOG.md).
5. Do not change accepted architecture without a new ADR.

---

## 6. Testing standards

| Suite | Command / notes |
| --- | --- |
| Format | `dart format --set-exit-if-changed lib test` (in `ai_tray/`) |
| Analyze | `flutter analyze --fatal-infos` |
| Unit / widget | `flutter test --exclude-tags golden,screenshot` |
| Golden | `flutter test --tags golden` (local / release-adjacent; not PR Quality blocker) |
| Sidecar | `cd tool/copilot_sdk_bridge && npm run check` |

Manual QA SoT: [dogfood/](dogfood/).  
There is **no** Document Platform–style ≥90% coverage hard gate.

---

## 7. CI standards

- **Quality CI** (PR/push): Ubuntu — Format / Analyze / Test / Validate workflows.
- **Release CD** (tag / dispatch): **only** place for macOS/Windows desktop builds.
- Do **not** reintroduce PR desktop builds.
- Lefthook is optional per clone ([devops/LOCAL_DEVELOPMENT.md](devops/LOCAL_DEVELOPMENT.md)).

Normative check names: [process/CI_REQUIRED_CHECKS.md](process/CI_REQUIRED_CHECKS.md).  
Narrative: [release/CI-CD.md](release/CI-CD.md).

---

## 8. Release workflow

1. Validate locally (format, analyze, tests, bridge).
2. Update [CHANGELOG.md](../CHANGELOG.md) for user-facing changes.
3. Bump `ai_tray/pubspec.yaml` version when cutting a release.
4. Tag / dispatch Release CD; publish GitHub Release artifacts.
5. Confirm showcase contract still matches PD-025
   ([devops/DEMO_STRATEGY.md](devops/DEMO_STRATEGY.md)).

---

## 9. Definition of Done

Canonical checklist: [process/DEFINITION_OF_DONE.md](process/DEFINITION_OF_DONE.md).

Handoff completion gate: code complete, tests passing, docs updated, handoff
updated, validation complete.

---

## 10. Code review checklist

Author and reviewer should confirm:

- [ ] Clean Architecture boundaries respected (UI → State → Domain → Data)
- [ ] No UI → CLI/SDK/API shortcuts; DTOs mapped before UI
- [ ] No invented usage values; stale/LKG labeled
- [ ] No undocumented / scraped APIs; no Cursor quota (PD-023)
- [ ] No Flutter Web tray playground (PD-025)
- [ ] ADR-004: prefer `core/` + `copilot/`; do not grow legacy aliases
- [ ] Tests match risk; bridge checked if sidecar touched
- [ ] Docs / handoff updated when state changes
- [ ] Quality CI checks expected green; no new PR desktop jobs
- [ ] Conventional Commit title; PR template complete

Process: [process/REPOSITORY_GOVERNANCE.md](process/REPOSITORY_GOVERNANCE.md).
