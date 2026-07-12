# S-008 — Technical Debt Review (Phase 2)

**Date:** 2026-07-12  
**Do not implement deferred items** (per checklist).

## Must fix before GA

| Item | Notes |
|--|--|
| Complete interactive RH-002 / dogfood critical paths | Auth, CLI missing, sleep/wake on macOS |
| Accept or clear KI-03 Gatekeeper for personal GA | Sign/notarize optional for public share |
| Confirm no new critical defects from dogfood log | Block GA if P0 found |

## Can wait for v1.0.1

| Item | Notes |
|--|--|
| Placeholder icons | Brand polish |
| `local_notifier` deprecated APIs | Monitor in dogfood |
| Idle RSS / CPU formal sampling | S-004 leftover |
| Widget/tray integration tests | Expand after dogfood themes |
| KI-11 plist pre-release version display | Cosmetic |

## Candidate for v1.1

| Item | Notes |
|--|--|
| S-001A Windows Validation | PD-010 deferred |
| Accessibility audit | KI-08 |
| Alternate usage API if CLI churn worsens | New ADR required |
| Charts / multi-provider / redesign | Explicitly out of scope |

## Intentionally accepted

- Free-text parser maintenance  
- Shape B intermittency (mitigated)  
- Windows Experimental  

## Recommendation

Proceed to S-009. Do not implement deferred items now.
