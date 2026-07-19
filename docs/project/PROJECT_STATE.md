# AI Tray — Project State

**Updated:** 2026-07-19  
**Current release:** v1.3.3 (`1.3.3+9`)  
**Default branch:** `main` at `2885980`  
**Active development branch:** `cursor/ep003-handoff-docs`  
**Current milestone:** Post-EP-002 stabilization + EP-004 decision  
**Overall progress:** EP-002 Phase 3 merged; Phase 3 not yet released

## Current status

AI Tray is a Flutter desktop usage companion with a shared multi-provider
platform. Claude Code is the stable provider. GitHub Copilot is integrated via
the official SDK sidecar, with its quota RPC explicitly marked experimental.

EP-002 Phase 3 is **merged** via
[PR #7](https://github.com/roshandroids/AI_Tray/pull/7) (merge commit
`2885980`). It includes Copilot UI quality coverage, screenshots, documentation,
and provider-selection recovery UX.

EP-003 research is complete in
[`docs/research/EP-003-cursor-agent-provider.md`](../research/EP-003-cursor-agent-provider.md).
PD-023 records the decision not to implement Cursor as a personal quota
provider. No Cursor provider was implemented.

EP-003A verified all requested print-mode `/usage` variants. Every command
returned exit 0, but `/usage` was interpreted as an agent prompt. No plan usage
percentages or reset date were returned.

## Completed

- Claude CLI usage pipeline with defensive parsing and LKG cache
- Provider registry, capabilities, provider-scoped refresh/cache, and selection
- GitHub Copilot SDK abstraction, sidecar, adapter, quota mapping, diagnostics
- Shared dashboard, settings, diagnostics, logs, tray states, and empty states
- EP-002 accessibility, state, screenshot, and golden regression coverage
- EP-002 Phase 3 merge to main (PR #7)
- macOS arm64 and Windows x64 release packaging
- Explicit release flow (version tag or manual dispatch); no build on main push
- EP-003 supported-interface research for Cursor Agent
- EP-003A non-interactive `/usage` verification with exact command evidence

## In progress / unmerged

- Documentation branch `cursor/ep003-handoff-docs` (EP-003, EP-003A, handoff,
  governance rule, CI-CD doc sync)
- Post-EP-002 stabilization sprint (lifecycle, races, sidecar, dogfood)
- EP-004 architecture assessment (decision pending; no implementation yet)

## Health

- Last verified Phase 3 checks: analyzer clean, 132 non-golden tests, 7 goldens
- Release v1.3.3 built macOS arm64 + Windows x64 successfully
- Post-merge main CI for PR #7 completed successfully
- No production `/copilot_internal` dependency

## Primary risks

- Copilot `account.getQuota` is experimental
- Claude `/usage` remains a free-text contract
- macOS release is unsigned/not notarized; sandbox is disabled for subprocesses
- Windows remains experimental; no macOS Intel release artifact
- Provider code has transitional `core/`, `domain/`, `data/copilot/`, and
  `copilot/` paths that should not be reorganized without a regression plan

## Next gate

Land the documentation PR, then complete the stabilization sprint and produce
an evidence-backed EP-004 decision (no-go, targeted cleanup, or full epic).
Do not implement Cursor quota support without an official personal
usage-summary API. Defer a product release decision until dogfooding and
version planning are complete.

## Release status

- Latest published release: v1.3.3
- EP-002 Phase 3 is on main but not yet in a published release
- No new release is required for EP-003 research or governance docs alone
