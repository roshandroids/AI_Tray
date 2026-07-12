# Repository Cleanup Summary — Decision 008

**Date:** 2026-07-12  
**Scope:** Documentation and non-functional cleanup only (no product/feature code).

## Actions taken

1. **Added** [POSTMORTEM.md](POSTMORTEM.md) — lessons learned (product, engineering, AI development, future process).
2. **Added** [docs/README.md](README.md) — complete documentation index with status (RC1 / dogfooding).
3. **Updated** root [README.md](../README.md) — RC1 status, dogfood note, working links into `docs/`.
4. **Updated** [ai_tray/README.md](../ai_tray/README.md) — removed obsolete T-001-only scope; points to install/user guides and RC1 status.
5. **Updated** [planning/lightweight-planning-index.md](planning/lightweight-planning-index.md) — marked historical; cleared stale “awaiting ADR-002 / do not implement” gate language.
6. **Updated** [execution/autonomous-progress.md](execution/autonomous-progress.md) — MVP closed; dogfooding phase; no post-MVP work.
7. **Updated** [release/README.md](release/README.md) — Decision 008 closure; link to postmortem.
8. **Verified** documentation links from root README and docs index resolve to existing files.

## Not removed (kept intentionally)

| Path | Reason |
|--|--|
| `AI_Tray_Product_Owner_Master_Roadmap.md` | Historical product SoT; referenced by postmortem / playbook extraction |
| `AI_Tray_Autonomous_Execution_Guide.md` | Process artifact worth preserving |
| `docs/planning/*`, `docs/architecture/*` | Planning-era records; still accurate as history |
| `research/*` | PoC evidence for ADR-001 |
| `docs/release/*` | RC1 deliverables still active during dogfood |

## Obsolete content handled

| Item | Handling |
|--|--|
| `ai_tray/README.md` claiming “T-001 foundation only / CLI not included” | Rewritten for RC1 |
| Planning index “Stop — do not implement” | Relabeled historical complete |
| Autonomous progress “awaiting PO on hardening” | Closed → dogfooding |

## Out of scope (unchanged)

- Application Dart code behavior  
- Version bump / git tag (human may tag `v1.0.0-rc1` when ready)  
- Feature work, refactors, new settings  

## Result

Repository documentation is indexed, status-consistent, and ready for dogfooding with MVP officially closed at **v1.0.0-rc1**.
