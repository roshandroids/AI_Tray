# Known Limitations — AI Tray (v1.0.0-rc.1)

1. **Claude-only.** No other providers.
2. **CLI-dependent.** No direct Anthropic HTTP usage API in MVP (ADR-001).
3. **Shape B intermittency.** `/usage` sometimes returns analytics-only text; app soft-fails and keeps cache.
4. **Free-text parser.** Format churn from Claude Code can break parsing until fixtures/parser update.
5. **Windows is Experimental (PD-010).** macOS is the officially validated platform for v1.0.0; Windows validation is deferred to **S-001A**.
6. **Unsigned macOS builds.** Gatekeeper friction; no notarization in RC1.
7. **App Sandbox is disabled** on macOS so the app can spawn Claude CLI. Do not re-enable without an alternate usage data path.
8. **PATH differences** between Terminal and GUI may require CLI path override.
9. **No charts / history / multi-account.** Feature-frozen for RC1.
10. **Accessibility** not audited (deferred).
11. **Sleep/wake timer behavior** not fully automated-tested — manual QA / dogfood required.
12. **Notification stack** relies on `local_notifier` deprecated macOS APIs.
13. **Cache ages** (soft/hard) may show stale % for hours by design (ADR-002).
14. **Single-user local prefs only** — no sync, no cloud settings.
