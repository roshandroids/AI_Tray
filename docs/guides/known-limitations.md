# Known Limitations — AI Tray

1. **GitHub Copilot quota API is experimental.** AI Tray uses the official SDK
   RPC `account.getQuota`. Schema/availability can change; the app degrades
   gracefully and never invents percentages.
2. **Claude is CLI-dependent.** No direct Anthropic HTTP usage API (ADR-001).
3. **Shape B intermittency.** `/usage` sometimes returns analytics-only text;
   the app soft-fails and keeps cache.
4. **Free-text Claude parser.** Format churn from Claude Code can break parsing
   until fixtures/parser update (session reset suffix is optional as of v1.3.3).
5. **Windows is Experimental (PD-010).** macOS arm64 is the primary validated
   desktop target; Windows validation remains lighter-weight.
6. **Unsigned macOS builds.** Gatekeeper friction; no notarization in current
   release automation.
7. **App Sandbox is disabled** on macOS so the app can spawn Claude CLI and the
   Copilot sidecar. Do not re-enable without an alternate data path.
8. **PATH differences** between Terminal and GUI may require CLI path override
   for Claude.
9. **No charts / history / multi-account.** Still out of scope.
10. **Published release artifacts** are macOS arm64 + Windows x64 only (no macOS
    Intel/x64 zip).
11. **Sleep/wake timer behavior** is not fully automated-tested — manual QA /
    dogfood required.
12. **Cache ages** (soft/hard) may show stale % for hours by design (ADR-002).
13. **Single-user local prefs only** — no sync, no cloud settings.
