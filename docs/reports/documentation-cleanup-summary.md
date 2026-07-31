# Documentation cleanup summary

**Date:** 2026-07-31  
**Phase:** Master Prompt Phase 7  
**Related:** [v2-refactor-plan.md](v2-refactor-plan.md) ·
[DOCUMENTATION_RULES.md](../DOCUMENTATION_RULES.md)

---

## Actions taken

### Broken links fixed

| Location | Fix |
| --- | --- |
| `docs/release/pd-015/…` → `tray_menu_builder.dart` | Corrected to `../../../ai_tray/...` |
| `docs/release/pd-021/…` → design system | Corrected to `../../design/DESIGN_SYSTEM.md` |
| `docs/release/pd-016/…` → CI-CD | Corrected to `../CI-CD.md` |

### Outdated content

| Doc | Change |
| --- | --- |
| `docs/guides/architecture-overview.md` | Claude-only wording → Claude stable + Copilot experimental |
| `docs/project/*` handoff | EP-004A marked merged on `main`; docs upgrade noted |
| Root `AI_Tray_*.md` | Marked **DEPRECATED (historical)**; point to handoff / blueprint |

### Consolidation

| Item | Action |
| --- | --- |
| Loose capability / intelligence reports | Already moved to `docs/reports/` (Phase 3) |
| Competing “SoT” claims in root PO roadmap | Deprecated banner; living SoT = `docs/project/` |

### Not deleted

Historical stabilization, release PD folders, postmortem, and root PO docs
are retained with deprecation or historical labels per
[DOCUMENTATION_RULES.md](../DOCUMENTATION_RULES.md).

---

## Remaining known gaps (non-blocking)

- Optional wiki handbook (v2 plan M1) — deferred
- Some architecture planning docs still describe early folder proposals;
  normative current overview is `guides/architecture-overview.md` +
  `ENGINEERING_STANDARD.md`
- Branch protection on GitHub may still list stale `Build macOS` until
  admin applies `docs/process/github-ruleset-protect-main-branch.json`

---

## Link audit

Relative markdown link scan after fixes: **0 broken** among checked
in-repo relative links (root + `docs/` + `.cursor` markdown).
