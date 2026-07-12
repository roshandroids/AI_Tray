# Known Issues — v1.0.0-rc.2

**Active release:** `v1.0.0-rc2` · dogfooding (PD-011)

| ID | Issue | Severity | Workaround | Status |
|--|--|--|--|--|
| KI-01 | Windows not validated — **Experimental** for v1.0.0 (PD-010) | Medium (macOS GA) / High if claiming Windows | Use macOS; track **S-001A** | Deferred |
| KI-02 | Shape B (`/usage` analytics-only) intermittent | High (data) | Keep cache; slow poll; retry | Mitigated (ADR-002) |
| KI-03 | Unsigned macOS app may be blocked by Gatekeeper | Medium | System Settings → allow; or sign later | Open |
| KI-04 | Placeholder Flutter app/tray artwork | Low | Ignore for dogfood | **Resolved** — branded Dash mascot tray/app icons |
| KI-05 | GUI may not see Homebrew `claude` on PATH | Medium | Set absolute CLI path in Settings | Mitigated |
| KI-06 | `local_notifier` uses deprecated macOS notification APIs | Medium | Monitor delivery during dogfood | Open |
| KI-07 | Closing window hides to tray (users may think app quit) | Low | Documented; use Quit in tray | By design |
| KI-08 | Accessibility not audited | Medium | Deferred | Open |
| KI-09 | Sleep/wake auto-refresh not proven in automated tests | Medium | Run RH-002 §10 during dogfood | Open |
| KI-10 | Manual QA checklist not fully executed in hardening session | Medium | Dogfood + complete RH-002 | Open |
| KI-11 | macOS Info.plist short version shows `1.0.0.1` for pubspec `1.0.0-rc.1+1` | Low | Rely on git tag `v1.0.0-rc1` / release notes | Open |

## Dogfood log template

```text
Date/time:
Claude version:
What I was doing:
What AI Tray showed:
Shape A/B from Terminal? (yes/no/unknown):
Annoyance severity (1–5):
Repro steps:
```
