# EP-002 Implementation Report — GitHub Copilot Provider Integration

**Date:** 2026-07-18  
**Release baseline:** v1.3.3  
**Phase covered by this report:** Phase 3 UI Integration (plus prior foundation)

## Summary

EP-002 adds GitHub Copilot as a second AI provider inside AI Tray’s shared
provider platform. Backend foundation (SDK sidecar, adapter, domain mapping,
refresh/cache isolation) shipped earlier. Phase 3 completes the unified
presentation layer so Copilot feels identical to Claude except for metrics.

## Architecture

```text
UI
└─ Provider Registry
   └─ CopilotProvider
      └─ CopilotSdkAdapter
         └─ CopilotSdk / CopilotSdkV1
            └─ Bundled Node sidecar → @github/copilot-sdk
               └─ client.rpc.account.getQuota({})  (Experimental)
```

Rejected approaches: `/copilot_internal/*`, undocumented GitHub APIs, scraping
CLI TUI output, parsing interactive terminal text.

## Phase completion

| Phase | Status |
| --- | --- |
| 1 Proof of Concept | Complete |
| 2 SDK / adapter / domain / provider foundation | Complete |
| 3 Shared UI integration | Complete |
| Distribution (arm64 macOS + Windows sidecar packaging) | Complete |
| Docs + screenshots + Phase 3 verification | Complete (this report) |

### Phase 3 deliverables

1. Persisted provider selector with race-safe refresh
2. Capability-driven shared dashboard (header, rich cards, skeletons, transitions)
3. Circular usage indicator states (threshold colors, refreshing, unavailable)
4. Shared Settings / Diagnostics / Logs integration
5. Actionable empty / error guidance
6. Accessibility + visual regression coverage
7. Screenshots and provider documentation
8. This implementation report

## Design decisions

- Keep one shared dashboard; never fork provider-specific pages.
- Map SDK DTOs only inside the adapter; UI consumes app-owned metrics.
- Treat quota RPC as experimental and degrade gracefully.
- Persist selection and scope cache/refresh by `ProviderId`.
- Preserve Claude parsing, refresh, and tray behavior when Claude is selected.

## Risks and experimental limitations

1. `account.getQuota` may change shape or availability without notice.
2. Sidecar assembly/signing remains a release-path dependency.
3. Published releases ship **macOS arm64** and **Windows x64** only (no macOS
   Intel artifact).
4. Auth/session environment differences between Terminal and GUI can still
   confuse first-run diagnostics.

## Verification (Phase 3)

Run from `ai_tray/`:

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot
flutter test --tags golden --update-goldens   # when baselines change
flutter test test/screenshot/readme_screenshots_test.dart --tags screenshot
```

Checks enforced for this phase:

- No production `/copilot_internal` usage
- No SDK bridge redesign during Phase 3 UI work
- Claude regression suite remains green
- Provider switching hides stale metrics immediately and refreshes once

## Recommendations for future SDK versions

1. Keep `CopilotSdk` / `CopilotSdkV1` as the only import boundary for SDK code.
2. Version the NDJSON sidecar protocol independently from UI releases.
3. Add contract tests against recorded `getQuota` payloads whenever GitHub
   changes the experimental schema.
4. Revisit publishing macOS Intel only if demand and CI cost justify it.

## Related docs

- [GitHub Copilot provider guide](../providers/github-copilot.md)
- [Provider platform architecture](../architecture/provider-platform.md)
- [CI/CD](./CI-CD.md)
- [CHANGELOG](../../CHANGELOG.md)
