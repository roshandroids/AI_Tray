# RH-002 — Manual QA Checklist (RC1)

**Release:** v1.0.0-rc.1  
**Platform under test:** ☐ macOS · ☐ Windows  
**Build:** _________________ (`AI Tray.app` / `.exe`)  
**Tester:** _________________  
**Date:** _________________  
**Claude Code version:** _________________ (`claude --version`)

**Pass criteria:** Every row marked Pass or N/A with notes. Any Fail → Known Issues entry.

---

## Preconditions

- [ ] Claude Code CLI installed and on PATH (or path noted for Settings override)
- [ ] Logged in: `claude auth status` shows authenticated
- [ ] Fresh or known cache state documented (wipe SharedPreferences if testing first launch)

---

## 1. First launch

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 1.1 | Install/open Release build cold | App starts; window may hide to tray; no crash | ☐ Pass ☐ Fail |
| 1.2 | Locate tray / menu bar icon | Icon visible; tooltip “AI Tray” | ☐ Pass ☐ Fail |
| 1.3 | Open main window (tray → Open) | Usage shell shows loading then live/stale/error | ☐ Pass ☐ Fail |
| 1.4 | First successful Shape A | Session % + weekly lines + reset text; not invented % | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 2. Refresh

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 2.1 | Tap **Refresh** in UI | Status updates; no duplicate stacked errors | ☐ Pass ☐ Fail |
| 2.2 | Tray → **Refresh** | Same as UI refresh; single-flight (rapid clicks don’t spawn storms) | ☐ Pass ☐ Fail |
| 2.3 | Wait one auto-refresh interval | Refresh occurs without user action (if auto-refresh on) | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 3. Shape A (usable usage)

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 3.1 | Confirm CLI returns Shape A: `claude -p '/usage' --output-format json` | Contains `Current session:` / weekly used lines | ☐ Pass ☐ Fail |
| 3.2 | App displays percentages | Matches CLI text (no fabricated values) | ☐ Pass ☐ Fail |
| 3.3 | Cache written | Quit + relaunch still shows last good until refresh | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 4. Shape B (rate-limit / analytics-only)

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 4.1 | Induce Shape B if possible (burst CLI `/usage` or wait for intermittent) | Soft failure; **not** treated as hard crash | ☐ Pass ☐ Fail ☐ N/A |
| 4.2 | With prior Shape A cache | Stale/cached usage still shown; softFailure message | ☐ Pass ☐ Fail ☐ N/A |
| 4.3 | Without cache | Clear “unavailable” / soft failure; **no** invented % | ☐ Pass ☐ Fail ☐ N/A |

**Notes:** _______________________________________________

---

## 5. Cache recovery

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 5.1 | Successful Shape A, then offline CLI (rename binary / bad path) | Shows stale cache + error; soft/hard age rules respected | ☐ Pass ☐ Fail |
| 5.2 | Restore CLI + Refresh | Returns to live success | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 6. Authentication expired

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 6.1 | Log out Claude (`claude auth logout` or equivalent) | Distinct auth failure; auto-refresh pauses | ☐ Pass ☐ Fail |
| 6.2 | Re-login + Refresh | Recovery to success | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 7. Claude missing

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 7.1 | Point Settings CLI path to nonexistent binary (or clear PATH in controlled env) | Clear “CLI missing” style failure | ☐ Pass ☐ Fail |
| 7.2 | Restore path | Refresh succeeds | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 8. CLI timeout

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 8.1 | Simulate hang if possible (wrapper script that sleeps > timeout) **or** note N/A if not feasible | Timeout failure; retries per ADR-002; UI recovers | ☐ Pass ☐ Fail ☐ N/A |
| 8.2 | Restore normal CLI | Next refresh succeeds | ☐ Pass ☐ Fail ☐ N/A |

**Notes:** _______________________________________________

---

## 9. Quit / relaunch

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 9.1 | Close window via traffic light / X | App stays in tray (does not fully quit) | ☐ Pass ☐ Fail |
| 9.2 | Tray → Quit | Process exits | ☐ Pass ☐ Fail |
| 9.3 | Relaunch | Settings persist; cache recovers if still valid | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 10. Sleep / wake

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 10.1 | Sleep machine ≥ 5 minutes with app running | No crash on wake | ☐ Pass ☐ Fail |
| 10.2 | After wake, Refresh or wait for timer | Refresh works; no stuck loading forever | ☐ Pass ☐ Fail |
| 10.3 | Observe timer drift | Auto-refresh resumes reasonably (document if paused oddly) | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## 11. Settings smoke (existing only — no new settings)

| # | Steps | Expected | ☐ |
|--|--|--|--|
| 11.1 | Change refresh interval | Persists across relaunch | ☐ Pass ☐ Fail |
| 11.2 | Toggle auto-refresh | Behavior matches toggle | ☐ Pass ☐ Fail |
| 11.3 | Notification threshold | Crossing threshold notifies (grant OS permission) | ☐ Pass ☐ Fail |
| 11.4 | Launch at login | Toggle enable/disable; verify OS login item | ☐ Pass ☐ Fail |

**Notes:** _______________________________________________

---

## Sign-off

| | |
|--|--|
| Overall | ☐ Ready for dogfood RC1 · ☐ Blocked |
| Critical fails | |
| Tester signature | |
