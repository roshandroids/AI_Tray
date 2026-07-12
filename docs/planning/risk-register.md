# Risk Register — MVP

**Phase:** Lightweight Planning · Task 0002  
**Updated:** 2026-07-12  
**Sources:** Master Roadmap · Task 0001 PoC · ADR-001

**Scale:** Impact / Likelihood = Low · Medium · High

---

## R-001 · Intermittent rate-limit block (Shape B)

| | |
|--|--|
| **Description** | `claude -p /usage` sometimes returns contribution analytics without session/week % and reset times. |
| **Impact** | High — MVP primary UI cannot refresh meaningfully |
| **Likelihood** | High — observed repeatedly after burst polling in PoC |
| **Mitigation** | Cache last known-good Shape A; treat Shape B as softFailure; poll 30–60s with single-flight; backoff on consecutive soft failures; show stale indicator |
| **Contingency** | Spike OAuth usage endpoint as fallback; reduce poll frequency; surface “usage temporarily unavailable” |

---

## R-002 · Free-text `/usage` format churn

| | |
|--|--|
| **Description** | Anthropic changes wording or layout of `/usage` output without notice. |
| **Impact** | High — parser breaks; false empties/errors |
| **Likelihood** | Medium |
| **Mitigation** | Golden fixtures; defensive parser; ParserState diagnostics; version pin note for Claude Code; CI parser tests |
| **Contingency** | Hotfix parser; temporary manual-only mode; evaluate structured alternate source |

---

## R-003 · Claude CLI missing or not on PATH

| | |
|--|--|
| **Description** | User installs tray app without Claude Code CLI, or binary path differs. |
| **Impact** | High — no data source |
| **Likelihood** | Medium |
| **Mitigation** | Startup health check; settings CLI path override; clear error CTA to install/login |
| **Contingency** | Block auto-refresh; deep-link to Claude Code install docs |

---

## R-004 · Unauthenticated / expired Claude session

| | |
|--|--|
| **Description** | `claude auth status` shows logged out or token expired. |
| **Impact** | High — usage fetch fails or returns useless output |
| **Likelihood** | Medium |
| **Mitigation** | Auth probe on repeated failures; distinct `notAuthenticated` failure; instruct user to run `claude auth login` |
| **Contingency** | Pause polling until auth recovers; keep cache visible as stale |

---

## R-005 · Windows parity unknown

| | |
|--|--|
| **Description** | PoC validated macOS only; Windows path, auth store, and tray behavior unproven. |
| **Impact** | High for cross-platform claim; Medium if macOS-first release allowed |
| **Likelihood** | Medium |
| **Mitigation** | Backlog T-020 Windows smoke validation before Windows GA |
| **Contingency** | Ship macOS MVP first; mark Windows as experimental or deferred |

---

## R-006 · Process spawn cost / resource use

| | |
|--|--|
| **Description** | Frequent `claude -p` processes may increase CPU/RAM or slow machine. |
| **Impact** | Medium — may miss idle RAM &lt; 100MB or feel heavy |
| **Likelihood** | Low–Medium |
| **Mitigation** | Single-flight refresh; min interval enforcement; measure RSS in T-021 |
| **Contingency** | Increase default interval; adaptive polling when tray closed |

---

## R-007 · Soft rate-limit on usage endpoint caused by polling

| | |
|--|--|
| **Description** | Burst or frequent polls may increase Shape B rate (hypothesized from PoC). |
| **Impact** | Medium — stale UI more often |
| **Likelihood** | Medium |
| **Mitigation** | Default 30–60s; exponential backoff after soft failures; avoid debug burst loops in production |
| **Contingency** | Manual refresh only mode; alternate data source spike |

---

## R-008 · `--bare` or wrong flags used accidentally

| | |
|--|--|
| **Description** | Using `--bare` returns cost summary instead of subscription usage. |
| **Impact** | High if shipped — silent wrong data |
| **Likelihood** | Low (if ADR followed) |
| **Mitigation** | ADR-001 constraint; adapter unit tests asserting argv; code review checklist |
| **Contingency** | Patch adapter; invalidate cache if mis-detected payload |

---

## R-009 · Session side effects from `-p` invocations

| | |
|--|--|
| **Description** | Each poll creates a CLI session id; unknown long-term side effects (history noise, disk growth). |
| **Impact** | Low–Medium |
| **Likelihood** | Medium |
| **Mitigation** | Prefer `--no-session-persistence` if compatible with `/usage`; monitor disk; keep interval modest |
| **Contingency** | Confirm flag compatibility; reduce poll rate; investigate lighter API |

---

## R-010 · Desktop package / OS permission friction

| | |
|--|--|
| **Description** | Tray, notifications, or launch-at-login require OS permissions or package quirks. |
| **Impact** | Medium — MVP features incomplete |
| **Likelihood** | Medium |
| **Mitigation** | Spike packages early in Epic E; document permission prompts; feature-flag launch-at-login |
| **Contingency** | Defer notifications or login-item to fast-follow; keep core usage popup |

---

## R-011 · Local contribution metrics misread as global usage

| | |
|--|--|
| **Description** | Shape B text includes local-machine contribution stats that exclude other devices. |
| **Impact** | Medium — misleading product if shown as quota |
| **Likelihood** | Medium without UX discipline |
| **Mitigation** | Do not use contribution block as primary UsageInfo; domain model excludes it from MVP fields |
| **Contingency** | If ever shown, label explicitly as “this machine only” |

---

## R-012 · Undocumented OAuth fallback ToS / breakage

| | |
|--|--|
| **Description** | Using community OAuth usage API may violate expectations or break suddenly. |
| **Impact** | High if relied on as sole source |
| **Likelihood** | Low while CLI-primary |
| **Mitigation** | Keep CLI primary per ADR-001; OAuth only as explicit contingency with separate ADR |
| **Contingency** | Disable fallback quickly; revert to cache + softFailure UX |

---

## R-013 · Team vs Pro/Max behavior differences

| | |
|--|--|
| **Description** | Rate-limit surfaces may differ by plan; Team nuances reported in community for some APIs. |
| **Impact** | Medium — some users see empty rate limits more often |
| **Likelihood** | Medium |
| **Mitigation** | Test with Team (already) and ideally Pro/Max; handle missing fields gracefully |
| **Contingency** | Plan-specific messaging; fallback source for affected plans |

---

## R-014 · Scope creep into analytics / multi-provider

| | |
|--|--|
| **Description** | Post-MVP ideas enter MVP timeline. |
| **Impact** | Medium — delays validation |
| **Likelihood** | Medium |
| **Mitigation** | Frozen MVP scope in roadmap; backlog explicitly excludes analytics/multi-provider UI |
| **Contingency** | PO re-prioritization with new decision record |

---

## Risk summary (watch list)

| ID | Title | Priority |
|----|-------|----------|
| R-001 | Shape B intermittent rate limits | **P0** |
| R-002 | Text format churn | **P0** |
| R-003 | CLI missing | **P0** |
| R-004 | Auth expired | **P0** |
| R-005 | Windows unknown | **P1** |
| R-007 | Polling worsens Shape B | **P1** |
| R-010 | Desktop permissions | **P1** |
| Others | See above | P2 |

---

## Review cadence

Revisit this register at:

1. End of Epic C (data path)
2. Before T-021 MVP acceptance
3. After Windows smoke (T-020)
