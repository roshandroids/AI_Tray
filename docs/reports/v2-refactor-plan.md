# AI Tray v2 — Engineering & Documentation Parity Plan

**Created:** 2026-07-31  
**Status:** Implementation complete (Master Prompt Phases 1–8)  
**Phase tracker:** see [Master Prompt phase status](#11-master-prompt-phase-status)  
**Sources:**

| Repository | Path inspected |
| --- | --- |
| **AI Tray** | `/Users/roshanshrestha/Desktop/Projects/personal/AI_Tray_Project` |
| **Document Platform** | `/Users/roshanshrestha/Desktop/Projects/personal/research_projects/Document_Platform` |
| **Document Platform Wiki (sibling)** | `/Users/roshanshrestha/Desktop/Projects/personal/research_projects/Document_Platform.wiki` |

**Goal:** Reach Document Platform’s engineering and documentation *standard* without copying product shape. AI Tray is a single Flutter desktop app; Document Platform is a Melos pub-workspace library monorepo. Parity means governance, decision hygiene, docs navigation, CI discipline, and developer experience — not a forced monorepo rewrite.

---

## 1. Executive comparison

| Dimension | Document Platform | AI Tray | Gap severity |
| --- | --- | --- | --- |
| Product shape | 22 `document_*` packages + playground | Single package `ai_tray/` + Node sidecar | Different by design |
| Root governance | LICENSE, SECURITY, CODE_OF_CONDUCT, OWNERSHIP, CONTRIBUTING, AGENTS | README + CHANGELOG only | **High** |
| Docs map | `docs/INDEX.md` + layered folders | `docs/README.md` (weaker switchboard) | Medium |
| Wiki | In-repo `wiki/` (45 pages) + publish scripts | None | Medium |
| ADRs | 10 under `docs/architecture/adr/` + DECISION_LOG | 4 under `docs/adr/` + project DECISION_LOG | Medium |
| Process / DoD | Full `docs/process/` tree | Implicit via handoff + dogfood | **High** |
| Agent rules | 22 `.cursor/rules/*.mdc` + AGENTS.md | 1 rule (`project-handoff.mdc`) | **High** |
| GitHub templates | PR + 5 issue types + CODEOWNERS + labels | Workflows only | **High** |
| Engineering ops | FEATURE_STATUS, NEXT_TASK, CURRENT_SPRINT, IMPLEMENTATION_RULES | 8-file `docs/project/` handoff (stronger for agents) | Low–Medium (AT leads in handoff) |
| Roadmap | `docs/release/ROADMAP.md` + sprint archive | `docs/project/ROADMAP.md` + root historical PO docs | Low |
| Reports | Under `docs/release/` (+ audits) | `docs/reports/` empty; reports scattered | Medium |
| CI | Monorepo ci + coverage + goldens + demos | Quality CI + Release CD + docs + maintenance | Different; AT already Local-First |
| Release | Structured changelog pipeline + `release.sh` | Keep-a-Changelog + bump/publish scripts | Medium |
| Testing docs | UI_TESTING, REGRESSION_MATRIX, QUALITY_GATE, coverage ≥90% | Tests exist; strategy docs thin | Medium |
| Coding standards doc | `CODING_STANDARDS.md` + analysis_options | `very_good_analysis` only (no narrative doc) | Medium |
| Scripts | ~38 sh/py release & check scripts | 5 scripts (ci + release) | Medium |
| Lefthook | Absent (CI-only) | Present (Local First) | AT ahead — keep |
| Showcase | Web demos + Firebase hosting | Product-as-demo (PD-025) | Different by decision |

**AI Tray already matches or exceeds Document Platform in:**

- Machine-readable + human handoff (`docs/project/` 8-file package + `PROJECT_CONTEXT.json`)
- Local-first hooks (`lefthook.yml`)
- Quality CI vs Release CD separation (EP-004A / D-017)
- Dogfood hub with platform checklists
- Conventional commit enforcement locally

**Do not blindly adopt from Document Platform:**

- Melos / pub workspace split of the tray app (conflicts with ADR-004 targeted cleanup)
- Flutter Web playground as the primary demo (conflicts with PD-025)
- Coverage ≥90% gate on all Dart (wrong bar for desktop UI + sidecar hybrid)
- Full 22-rule Cursor pack without trimming for product size
- Store-distribution stub scripts
- Firebase Hosting / playground deploy pipeline

---

## 2. Side-by-side inventories (actual repos)

### 2.1 Folder structure

**Document Platform (top-level):**  
`packages/`, `docs/`, `wiki/`, `scripts/`, `examples/`, `benchmarks/`, `release/`, `showcase/`, `Assets/`, `prompts/` (empty), `.github/`, `.cursor/`, root Melos/`pubspec.yaml`, governance markdown.

**AI Tray (top-level):**  
`ai_tray/`, `docs/`, `scripts/`, `research/`, `showcase/`, `.github/`, `.cursor/`, `lefthook.yml`, root historical PO markdown (`AI_Tray_*.md`), `README.md`, `CHANGELOG.md`.

### 2.2 Feature / package organization

| | Document Platform | AI Tray |
| --- | --- | --- |
| Model | Melos + pub `workspace:` | Single Flutter package |
| Units | 22 `document_<concern>` packages | Features under `ai_tray/lib/features/` |
| Boundaries | Dependency arrows → `document_core` (DEPENDENCY_GRAPH) | Clean Architecture layers per feature |
| Extra | `document_testing` harness package | Node sidecar `tool/copilot_sdk_bridge/` |
| Known debt | N/A for this compare | Dual provider layout: `core/`+`copilot/` vs legacy `domain/`+`data/` (ADR-004) |

### 2.3 docs/ structure

**Document Platform layers:** `ai/`, `architecture/` (adr, specifications, spikes), `engineering/` (planning, status, quality), `project/`, `process/`, `guides/`, `reference/`, `release/`, `changelog/`, `product/`, `design/`, `testing/`, `migration/`, `firebase/`, `archive/`, plus `INDEX.md`, `DOCUMENTATION_RULES.md`.

**AI Tray layers:** `project/` (handoff SoT), `adr/`, `architecture/`, `design/`, `devops/`, `dogfood/`, `guides/`, `planning/`, `providers/`, `release/`, `research/`, `stabilization/`, `execution/`, `assets/`, empty `reports/`, plus root loose reports.

### 2.4 Wiki

| | Document Platform | AI Tray |
| --- | --- | --- |
| In-repo | `wiki/` ~45 flat GitHub Wiki pages | Missing |
| Publish | `scripts/publish_wiki.sh`, `sync_wiki_from_published.py` | Missing |
| Rule | Wiki = handbook; backlog stays in `docs/` | N/A |

### 2.5 ADRs & decision records

| | Document Platform | AI Tray |
| --- | --- | --- |
| ADRs | 10 files (`ADR-001`…`009`, `011`) in `docs/architecture/adr/` | 4 files in `docs/adr/` |
| Indexes | `architecture/DECISION_LOG.md`, `project/DECISIONS.md`, wiki ADR index | `docs/adr/README.md`, `docs/project/DECISION_LOG.md` (PD-*, D-*) |
| Lifecycle | RP → AS/ADR → freeze | ADR + PD/D in handoff |
| Template file | None (convention) | None |

### 2.6 Reports, roadmap, milestones

| | Document Platform | AI Tray |
| --- | --- | --- |
| Reports home | Mostly `docs/release/*_REPORT.md`, audits under engineering | `docs/reports/` empty; EP/stabilization/QA reports elsewhere |
| Roadmap | `docs/release/ROADMAP.md` + archived sprints | `docs/project/ROADMAP.md` + root PO roadmap |
| Execution | `CURRENT_SPRINT.md`, `NEXT_TASK.md`, `FEATURE_STATUS.md` | `NEXT_SESSION.md`, epic/stabilization folders |

### 2.7 Development workflow & CI/CD

| | Document Platform | AI Tray |
| --- | --- | --- |
| Entry | CONTRIBUTING + AGENTS | Handoff package (no CONTRIBUTING/AGENTS) |
| Governance | Issue → branch → PR → Owner approval | Practiced but not fully documented |
| CI | `ci.yml` (format/analyze/tests/goldens/coverage/demos), deploy-demos, release | `quality.yml`, `documentation.yml`, `release.yml`, `maintenance.yml`, unused reusable web-demo |
| Hooks | None | Lefthook pre-commit / commit-msg / pre-push |
| Release | `release.sh` + unreleased changelog entries | `publish.sh` + root `CHANGELOG.md` |

### 2.8 Testing, standards, deps, naming, scripts, templates

| Area | Document Platform | AI Tray |
| --- | --- | --- |
| Testing | Per-package `test/`, goldens, integration_test, benchmarks, QUALITY_GATE, coverage script | `unit/` `widget/` `golden/` `screenshot/` tags; goldens excluded from Quality CI |
| Lint | Root `lints/recommended` + CODING_STANDARDS.md | `very_good_analysis` in `ai_tray/` |
| Deps | Workspace + Melos coordinated SemVer | Single pubspec + npm sidecar |
| Naming | `document_*`, ADR/RP/AS/BUG/SPRINT IDs | Features snake_case; ADR/PD/D/EP/S/RH IDs |
| Scripts | ~38 | 5 |
| Templates | PR + issue YAML + changelog tmpl + migration tmpl | Dogfood markdown templates only |

---

## 3. Everything Document Platform has that AI Tray is missing

Items are **missing relative to Document Platform**, grouped by adoption priority. Effort is wall-clock for a familiar owner (docs/process skew; no large code rewrites unless noted).

---

### High Priority

#### H1. Root governance set: `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `OWNERSHIP.md`

| | |
| --- | --- |
| **Why DP has it** | Open/shareable repo hygiene; clear ownership; vulnerability reporting; community norms. |
| **Adopt?** | **Yes.** Required for the same public-engineering standard even for a personal product. |
| **Benefit** | Trust, clarity for contributors/agents, GitHub community health signals. |
| **Effort** | S (0.5–1 day) — copy/adapt DP MIT + SECURITY + CoC + OWNERSHIP. |

#### H2. `CONTRIBUTING.md` with Day-1 path

| | |
| --- | --- |
| **Why DP has it** | Mandatory Issue → PR → Owner path; points to INDEX, process, NEXT_TASK. |
| **Adopt?** | **Yes**, adapted to AI Tray (handoff package + Quality CI + dogfood; not Melos). |
| **Benefit** | Onboarding and agent consistency; reduces “where do I start?” drift. |
| **Effort** | S–M (1–2 days). |

#### H3. `AGENTS.md` agent entry stub

| | |
| --- | --- |
| **Why DP has it** | Single AI entry that routes to AI_CONTEXT, rules, DoD, ADRs. |
| **Adopt?** | **Yes** — map to existing `docs/project/AI_HANDOFF.md` + `NEXT_SESSION.md`. |
| **Benefit** | Agents stop inventing process; aligns Cursor/Claude with SoT. |
| **Effort** | S (half day). |

#### H4. GitHub PR template + issue templates + `CODEOWNERS`

| | |
| --- | --- |
| **Why DP has it** | Issue-driven work; structured PRs (tests, architecture impact, a11y); owner gate. |
| **Adopt?** | **Yes** (slim set: bug, feature, docs, CI; PR checklist for tray + sidecar). |
| **Benefit** | Review quality; links issues ↔ PRs; matches DP governance culture. |
| **Effort** | S–M (1 day). |

#### H5. `docs/process/` governance pack (subset)

Missing pieces to port (adapted):  
`REPOSITORY_GOVERNANCE.md`, `BRANCH_PROTECTION.md`, `DEFINITION_OF_DONE.md`, `ENGINEERING_PRINCIPLES.md`, `CI_REQUIRED_CHECKS.md`, `BUG_HANDLING.md` (+ optional `BUG_DOCUMENTATION.md`).

| | |
| --- | --- |
| **Why DP has it** | No exceptions on Issue→PR; merge DoD; explicit required checks. |
| **Adopt?** | **Yes** — write tray-specific DoD (format/analyze/test/handoff/validate; no macOS on PR). |
| **Benefit** | Makes EP-004A branch-protection rules durable; closes process gap. |
| **Effort** | M (2–3 days). |

#### H6. Expanded Cursor / agent rule set (pruned)

DP has 22 always-on rules (`00`–`20`, `99-self-audit`). AT has only `project-handoff.mdc`.

| | |
| --- | --- |
| **Why DP has it** | Self-governance: docs-first, bug/feature/refactor workflows, testing, git, security, release, decisions. |
| **Adopt?** | **Yes, selectively** (~8–12 rules). Keep handoff rule; add DoD, ADR, git, testing, security, docs standards. Do not paste all 22 verbatim. |
| **Benefit** | Agents behave like DP sessions without drowning a smaller repo. |
| **Effort** | M (2–4 days including validation). |

#### H7. Documentation index upgrade (`docs/INDEX.md` or strengthen `docs/README.md`)

| | |
| --- | --- |
| **Why DP has it** | Audience switchboard (visitor / contributor / agent / debugger / releaser). |
| **Adopt?** | **Yes.** |
| **Benefit** | Discovers handoff, ADRs, process, CI, dogfood in one map. |
| **Effort** | S (0.5–1 day). |

#### H8. Centralize reports under `docs/reports/` (+ index)

| | |
| --- | --- |
| **Why DP has it** | Production readiness / excellence / audits are findable (under `docs/release/` there; AT already reserved `docs/reports/`). |
| **Adopt?** | **Yes** — move or symlink-index scattered reports; keep historical paths listed. |
| **Benefit** | Clears empty `docs/reports/`; matches this plan’s home; easier audits. |
| **Effort** | S (half day) for index; M if relocating many files carefully. |

---

### Medium Priority

#### M1. In-repo GitHub Wiki handbook (`wiki/` + publish script)

| | |
| --- | --- |
| **Why DP has it** | Human-friendly handbook; normative truth stays in `docs/`. |
| **Adopt?** | **Yes, but thin** (Home, Getting Started, Architecture overview, Development, Roadmap pointers). Avoid duplicating handoff backlog. |
| **Benefit** | Public GitHub Wiki parity; better first impression. |
| **Effort** | M (2–4 days) + ongoing sync cost. |

#### M2. Narrative `CODING_STANDARDS.md`

| | |
| --- | --- |
| **Why DP has it** | Documents package boundaries, style, beyond analyzer YAML. |
| **Adopt?** | **Yes** — describe Clean Architecture + Riverpod + sidecar rules already in handoff. |
| **Benefit** | Reviewers/agents cite one file; complements `very_good_analysis`. |
| **Effort** | S–M (1 day). |

#### M3. Explicit testing strategy docs

Missing vs DP: `UI_TESTING` / testing strategy, `REGRESSION_MATRIX`, `QUALITY_GATE`, `MANUAL_QA_CHECKLIST`, coverage policy.

| | |
| --- | --- |
| **Why DP has it** | Editor quality bar; golden/integration/coverage expectations. |
| **Adopt?** | **Partially.** Document AT tags (`golden`, `screenshot`), what Quality CI runs, dogfood as manual QA SoT. Skip 90% coverage gate. |
| **Benefit** | Clear test pyramid for tray + sidecar. |
| **Effort** | M (1–2 days). |

#### M4. ADR home under architecture + decision guide

DP: `docs/architecture/adr/` + `DECISIONS.md` (when/how). AT: `docs/adr/` (fine) but no “how to write ADR” guide; architecture specs less formal.

| | |
| --- | --- |
| **Why DP has it** | RP→ADR lifecycle; spikes (AS-*). |
| **Adopt?** | **Yes for guide + optional move/alias** to `docs/architecture/adr/`. Keep PD/D in handoff DECISION_LOG. Spikes only when needed. |
| **Benefit** | Aligns ADR placement with architecture docs; clearer decision process. |
| **Effort** | S–M (1 day + link fixes). |

#### M5. Architecture specification pack (subset)

DP: `ARCHITECTURE.md`, `DEPENDENCY_GRAPH.md`, `PUBLIC_API.md`, `CODING_STANDARDS.md`, fidelity/BiDi specs (product-specific).

| | |
| --- | --- |
| **Why DP has it** | Library platform needs public API + dependency arrows. |
| **Adopt?** | **Partially.** Strengthen `system-architecture` / folder-structure into one normative ARCHITECTURE; optional DEPENDENCY_GRAPH for `lib/` + sidecar. Skip PUBLIC_API/pub.dev until packaging as library. Skip BiDi/fidelity. |
| **Benefit** | Single normative architecture SoT; supports EP-004 cleanup. |
| **Effort** | M (2–3 days). |

#### M6. Engineering ops trio: `FEATURE_STATUS`, `NEXT_TASK`, `IMPLEMENTATION_RULES`

| | |
| --- | --- |
| **Why DP has it** | Living maturity map + next coding unit + no temporary fixes. |
| **Adopt?** | **Partially.** AT’s `NEXT_SESSION` + ROADMAP + PRODUCT_STATE already cover much. Add a thin FEATURE_STATUS (providers/platforms maturity) and IMPLEMENTATION_RULES if CONTRIBUTING needs them. Avoid duplicating NEXT_SESSION. |
| **Benefit** | Maturity visibility without abandoning handoff. |
| **Effort** | S–M (1–2 days). |

#### M7. Structured changelog / unreleased entries pipeline

DP: `docs/changelog/unreleased/` + `new_change.sh` + aggregate into release CHANGELOG.

| | |
| --- | --- |
| **Why DP has it** | Multi-package releases must not invent notes from git history. |
| **Adopt?** | **Optional.** Keep-a-Changelog at root works for single app; adopt unreleased fragments if multi-contributor velocity rises. |
| **Benefit** | Cleaner release notes under concurrent PRs. |
| **Effort** | M (2 days) if adopted. |

#### M8. Release automation depth (`release.sh`, verify, quality gate script)

| | |
| --- | --- |
| **Why DP has it** | Coordinated SemVer across packages + hosting assets. |
| **Adopt?** | **Partially.** Harden existing `publish.sh` / bump / extract; add verify checklist script. Skip Melos bump band, Firebase, store stubs. |
| **Benefit** | Safer tagged releases; fewer manual mistakes. |
| **Effort** | M (1–3 days). |

#### M9. `docs/DOCUMENTATION_RULES.md` + archive policy

| | |
| --- | --- |
| **Why DP has it** | No placeholders; archive don’t delete; wiki vs docs roles. |
| **Adopt?** | **Yes** (short). |
| **Benefit** | Stops doc sprawl and contradictory SoTs. |
| **Effort** | S (half day). |

#### M10. Product vision / PRD formalization

DP: `docs/product/VISION.md`, `PRD.md`.

| | |
| --- | --- |
| **Why DP has it** | Long-horizon library product. |
| **Adopt?** | **Lightly** — extract from PRODUCT_STATE + PO roadmap into `docs/product/` if public positioning matters. |
| **Benefit** | Clearer product narrative for wiki/README. |
| **Effort** | S–M (1 day). |

#### M11. Labels + branch-protection ruleset artifact

DP: `.github/labels.yml`, `github-ruleset-protect-main-branch.json`.

| | |
| --- | --- |
| **Why DP has it** | Reproducible GitHub config. |
| **Adopt?** | **Yes** for ruleset JSON matching EP-004A required checks. Labels nice-to-have. |
| **Benefit** | Documented, restorable branch protection. |
| **Effort** | S (half day). |

#### M12. Research → ADR numbering hygiene (RP/AS archives)

| | |
| --- | --- |
| **Why DP has it** | Pre-implementation research is archived and linked. |
| **Adopt?** | **Lightly** — AT already has `docs/research/` and `research/`; add index + archive convention. |
| **Benefit** | EP-003-style work stays discoverable. |
| **Effort** | S (half day). |

---

### Low Priority

#### L1. Melos / pub workspace monorepo

| | |
| --- | --- |
| **Why DP has it** | Many publishable packages with shared tooling. |
| **Adopt?** | **No (now).** Conflicts with ADR-004 targeted cleanup; tray is one app + one sidecar. Revisit only if extracting reusable packages. |
| **Benefit if forced** | Multi-package scripts — unnecessary cost today. |
| **Effort** | XL (weeks) — **defer**. |

#### L2. `examples/playground` + Firebase Hosting demos

| | |
| --- | --- |
| **Why DP has it** | Embeddable editor needs a dogfood host. |
| **Adopt?** | **No.** PD-025: product is the demo. Keep unused reusable web-demo workflow for other projects only. |
| **Benefit** | N/A for AI Tray product. |
| **Effort** | N/A — **do not adopt**. |

#### L3. Benchmarks package + soft perf CI

| | |
| --- | --- |
| **Why DP has it** | Layout/rendering performance is core. |
| **Adopt?** | **No** unless tray UI jank becomes a measured problem. |
| **Benefit** | Marginal for menu-bar refresh loops. |
| **Effort** | L — **defer**. |

#### L4. Coverage ≥90% pure-Dart gate

| | |
| --- | --- |
| **Why DP has it** | Core model must stay highly tested. |
| **Adopt?** | **No as a hard gate.** Optional coverage report later for parsers/domain only. |
| **Benefit** | Misleading if applied to Flutter UI. |
| **Effort** | M — **defer / optional**. |

#### L5. `document_testing`-style harness package

| | |
| --- | --- |
| **Why DP has it** | Headless editor harness shared across packages. |
| **Adopt?** | **No** until multiple packages need shared harnesses. |
| **Effort** | L — **defer**. |

#### L6. Full `docs/reference/` subsystem handbook

| | |
| --- | --- |
| **Why DP has it** | Deep editor subsystems (caret, selection, IME, …). |
| **Adopt?** | **No** at DP depth. Keep provider guides + architecture overview. |
| **Effort** | XL — **defer**. |

#### L7. Accessibility / BiDi / API evolution / migration / deprecations suites

| | |
| --- | --- |
| **Why DP has it** | Host-embed library obligations. |
| **Adopt?** | **Selective later** (a11y notes for tray UI if needed). Not a parity blocker. |
| **Effort** | M–L each — **low priority**. |

#### L8. Distribution stub scripts (App Store, Play, Homebrew, …)

| | |
| --- | --- |
| **Why DP has it** | Future host packaging placeholders. |
| **Adopt?** | **No stubs.** Prefer real notarization/signing docs when ready (already on AT roadmap). |
| **Effort** | S but low value — **skip**. |

#### L9. Empty top-level `prompts/` / Assets release JSON pattern

| | |
| --- | --- |
| **Why DP has it** | Hosting/About metadata + research prompts. |
| **Adopt?** | **No** empty folders. Showcase + CHANGELOG suffice. |
| **Effort** | — **skip**. |

#### L10. Full sprint archive culture (`SPRINT_NNN`)

| | |
| --- | --- |
| **Why DP has it** | Long research/implementation history. |
| **Adopt?** | **Optional.** AT already has stabilization S-00x and release PD folders. |
| **Effort** | S — only if useful. |

---

## 4. What AI Tray should keep (do not regress)

1. **`docs/project/` 8-file handoff + `PROJECT_CONTEXT.json`** — stronger session SoT than DP’s engineering trio alone.  
2. **Lefthook Local First** — DP lacks this; keep and document in CONTRIBUTING.  
3. **Quality CI + Release CD** — do not reintroduce PR desktop builds.  
4. **PD-025 product-as-demo** — do not replace with a web playground.  
5. **ADR-004 targeted cleanup** — no Melos rewrite for parity optics.  
6. **`very_good_analysis`** — stricter than DP’s recommended lints; keep unless migrating deliberately.  
7. **Dogfood checklists** — map them as the manual QA SoT in testing docs.

---

## 5. Phased migration plan

No code/product behavior changes are required to start Phases 1–2. Later phases may touch scripts/CI/docs only unless a phase explicitly schedules engineering cleanup.

### Phase 1 — Foundation

**Objective:** Root governance and contribution entry match Document Platform’s professionalism.

| Deliverable | Maps to |
| --- | --- |
| Add `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `OWNERSHIP.md` | H1 |
| Add `CONTRIBUTING.md` (Day-1 → handoff, Quality CI, Lefthook, dogfood) | H2 |
| Add `AGENTS.md` → `docs/project/AI_HANDOFF.md` | H3 |
| Add `.github/PULL_REQUEST_TEMPLATE.md`, issue templates, `CODEOWNERS` | H4 |
| Add `docs/process/` subset + `CI_REQUIRED_CHECKS.md` + branch-protection notes/ruleset JSON | H5, M11 |
| Point README at CONTRIBUTING / AGENTS / LICENSE | H1–H3 |

**Exit criteria:**

- Root governance files present and linked from README  
- CONTRIBUTING describes Issue → PR → Owner and EP-004A required checks  
- AGENTS.md is the agent stub; handoff remains SoT  
- PR/issue templates usable on GitHub  

**Estimated effort:** 3–5 days  
**Risk:** Low (docs-only)

---

### Phase 2 — Documentation

**Objective:** Navigable, non-duplicative docs tree with report home and documentation rules.

| Deliverable | Maps to |
| --- | --- |
| Upgrade `docs/README.md` or add `docs/INDEX.md` audience switchboard | H7 |
| Add `docs/DOCUMENTATION_RULES.md` (SoT layers, archive policy) | M9 |
| Populate `docs/reports/` with index + this plan; link EP/stabilization/QA reports | H8 |
| Optional thin `docs/product/VISION.md` from PRODUCT_STATE | M10 |
| Research/archive index for `docs/research/` + `research/` | M12 |
| Relocate or clearly mark root `AI_Tray_*.md` as historical (archive links) | M9 |

**Exit criteria:**

- One docs map answers “where do I go?” for visitor / contributor / agent  
- `docs/reports/` is the report index (not empty)  
- Documentation rules prevent competing SoTs (wiki vs handoff vs root PO docs)  

**Estimated effort:** 2–4 days  
**Risk:** Low; watch broken relative links (documentation.yml already validates)

---

### Phase 3 — Architecture

**Objective:** Decision and architecture documentation at DP clarity without monorepo theater.

| Deliverable | Maps to |
| --- | --- |
| ADR writing guide; optional relocate/alias ADRs under `docs/architecture/adr/` | M4 |
| Normative `ARCHITECTURE.md` consolidating system/folder/provider docs | M5 |
| Optional `DEPENDENCY_GRAPH.md` (`lib/` features + sidecar + CLI boundaries) | M5 |
| `CODING_STANDARDS.md` (CA, Riverpod, no UI→API, sidecar rules) | M2 |
| Thin `FEATURE_STATUS.md` (Claude / Copilot / Cursor / platforms) | M6 |
| Ensure DECISION_LOG ↔ ADR index cross-links stay valid | M4 |

**Exit criteria:**

- Architecture changes require ADR process documented like DP  
- One normative architecture doc; older planning docs marked historical  
- Provider/platform maturity visible without reading entire handoff  

**Estimated effort:** 3–5 days  
**Risk:** Medium if relocating ADRs without redirect links

---

### Phase 4 — Engineering

**Objective:** Process rigor and quality documentation equal to DP; preserve Local First CI.

| Deliverable | Maps to |
| --- | --- |
| Expand `.cursor/rules/` (pruned set + self-audit) | H6 |
| Testing strategy + regression matrix + manual QA pointing at dogfood | M3 |
| Harden release verify script; document QUALITY_GATE for tray (not 90% coverage) | M8 |
| Optional unreleased changelog fragments if multi-PR release pain appears | M7 |
| IMPLEMENTATION_RULES (no temporary fixes; import canonicalization per ADR-004) | M6 |
| Keep Quality/Release split; document required checks in process + GitHub | H5 |

**Exit criteria:**

- Agents load multiple always-apply rules including self-audit  
- Contributors know which tests run where (Lefthook vs Quality vs Release)  
- Release checklist script or doc gates tag cuts  

**Estimated effort:** 4–7 days  
**Risk:** Medium — rule bloat; mitigate with pruned set

**Explicitly out of Phase 4:** Melos split, coverage hard gate, playground, benchmarks.

---

### Phase 5 — Developer Experience

**Objective:** Handbook + polish at DP’s external DX level.

| Deliverable | Maps to |
| --- | --- |
| Thin in-repo `wiki/` + optional `publish_wiki.sh` | M1 |
| README switchboard parity with DP (badges optional) | H7 |
| Labels.yml; finalize branch-protection ruleset checked into docs | M11 |
| Wiki pages only summarize; handoff/FEATURE_STATUS remain backlog SoT | M1, M9 |
| Optional: notarization/signing runbook when PO schedules it (real, not stubs) | roadmap |

**Exit criteria:**

- GitHub Wiki (or in-repo wiki/) navigable for newcomers  
- No backlog owned by wiki  
- DX docs match CONTRIBUTING Day-1 path  

**Estimated effort:** 3–5 days  
**Risk:** Medium ongoing cost of wiki sync — keep pages few

---

## 6. Suggested sequence diagram

```text
Phase 1 Foundation
    → LICENSE / SECURITY / CoC / OWNERSHIP
    → CONTRIBUTING + AGENTS
    → GitHub templates + process/ + CODEOWNERS
         ↓
Phase 2 Documentation
    → INDEX + DOCUMENTATION_RULES
    → reports/ index + archive hygiene
         ↓
Phase 3 Architecture
    → ADR guide + ARCHITECTURE + CODING_STANDARDS
    → FEATURE_STATUS (thin)
         ↓
Phase 4 Engineering
    → Cursor rules pack (pruned)
    → Testing / release verify / IMPLEMENTATION_RULES
         ↓
Phase 5 Developer Experience
    → Thin wiki + README polish + ruleset artifact
```

---

## 7. Effort summary

| Phase | Focus | Effort | Priority items closed |
| --- | --- | --- | --- |
| 1 | Foundation | 3–5 days | H1–H5, M11 |
| 2 | Documentation | 2–4 days | H7–H8, M9–M10, M12 |
| 3 | Architecture | 3–5 days | M2, M4–M6 |
| 4 | Engineering | 4–7 days | H6, M3, M7–M8 |
| 5 | Developer Experience | 3–5 days | M1, polish |
| **Total (adopt path)** | | **~15–26 days** | High + selected Medium |
| Deferred / skip | Melos, playground, benches, 90% coverage, reference handbook, store stubs | — | L1–L9 |

---

## 8. Acceptance definition for “parity”

AI Tray has reached Document Platform’s **standard** when:

1. Root governance files exist and match ownership reality.  
2. CONTRIBUTING + AGENTS + process DoD describe the real workflow (Issue → PR → Owner; Quality CI checks).  
3. Docs INDEX routes every audience; reports live under `docs/reports/`.  
4. ADRs + DECISION_LOG + coding/architecture standards are normative and linked.  
5. Agent rules cover workflow classes (not only handoff).  
6. Testing and release expectations are written and match CI.  
7. Optional wiki is a handbook only.  
8. Product decisions PD-023/024/025 and ADR-004 remain intact (no demo/monorepo regressions).

Parity does **not** require matching package count, Melos, Firebase demos, or editor reference depth.

---

## 9. Immediate next actions (when implementation is approved)

1. Confirm Phase 1 scope with Product Owner (license text, CoC applicability).  
2. Implement Phase 1 docs/templates only; run documentation workflow.  
3. Update `docs/project/` handoff to point at this plan and track phase status.  
4. Do **not** start Melos or web playground work under the guise of parity.

---

## 10. Evidence notes

Counts and paths were taken from filesystem inspection on 2026-07-31:

- Document Platform: 22 packages, 10 ADR files, 45 wiki markdown pages, 22 Cursor rules, ~38 scripts, full `.github` template set.  
- AI Tray: 1 Flutter package + sidecar, 4 ADRs, 0 wiki, 1 Cursor rule, 5 scripts, workflows without PR/issue templates, empty `docs/reports/` prior to this file.  
- AI Tray strengths retained: handoff package, Lefthook, Quality/Release split, dogfood hub, PD-025 demo strategy.

---

## 11. Master Prompt phase status

Tracked against `docs/AI_Tray_Documentation_Upgrade_Master_Prompt.md`
(phases differ slightly from §5 above; Master Prompt is the execution SoT).

| Master Prompt phase | Status | Commit message |
| --- | --- | --- |
| 1 — Repository governance | **Completed** 2026-07-31 | `docs: add repository governance` |
| 2 — Community & contributor experience | **Completed** 2026-07-31 | `docs: add contributor documentation` |
| 3 — Documentation foundation | **Completed** 2026-07-31 | `docs: organize documentation structure` |
| 4 — Engineering standard | **Completed** 2026-07-31 | `docs: add engineering standards` |
| 5 — Project blueprint | **Completed** 2026-07-31 | `docs: add project blueprint` |
| 6 — Cursor rules | **Completed** 2026-07-31 | `docs: refine cursor rules` |
| 7 — Documentation cleanup | **Completed** 2026-07-31 | `docs: cleanup documentation` |
| 8 — Validation | **Completed** 2026-07-31 | `docs: finalize documentation upgrade` |

### Phase 1 notes

Added: `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `SUPPORT.md`,
`OWNERSHIP.md`; README quick links updated.

### Phase 2 notes

Added: `CONTRIBUTING.md`, `AGENTS.md`, `.github/CODEOWNERS`,
`.github/PULL_REQUEST_TEMPLATE.md`, issue templates (bug, feature, docs, CI).

### Phase 3 notes

Added: `docs/DOCUMENTATION_RULES.md`, `docs/process/` (governance, DoD, CI
checks, branch protection, principles, bug handling, ruleset JSON),
`docs/templates/`, audience switchboard `docs/README.md`, `docs/reports/`
index; moved loose capability/intelligence reports under `docs/reports/`.

### Phase 4 notes

Added: `docs/ENGINEERING_STANDARD.md` (structure, naming, ADR, testing, CI,
release, DoD, review checklist) with links to existing normative docs.

### Phase 5 notes

Added: `docs/PROJECT_BLUEPRINT.md` (vision, goals, architecture, layout, docs
map, workflows, roadmap, getting started).

### Phase 6 notes

Pruned Cursor rules: kept `project-handoff`; added documentation-first,
architecture, decision-records, testing-standards, git-github-workflow,
security, self-audit. Documented non-adopted DP rules in `.cursor/README.md`.

### Phase 7 notes

Fixed broken PD-015/016/021 links; updated architecture overview provider
wording; deprecated root `AI_Tray_*.md` as historical; refreshed handoff for
EP-004A-on-main + D-018; wrote `documentation-cleanup-summary.md`.

### Phase 8 notes

Validation report: `documentation-validation-report.md` — PASS (links,
governance, process, handoff script, CI model non-regressions).