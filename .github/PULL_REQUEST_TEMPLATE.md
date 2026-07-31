## Related Issue

<!-- Prefer linking an Issue for non-trivial changes. -->

- Closes #
- Refs #

## Summary

<!-- What changed and why (1–5 sentences). -->



## Root Cause

<!-- Required for bugs. Otherwise write "N/A — not a bug". -->



## Solution

<!-- How the change fixes the problem or delivers the feature. -->



## Architecture impact

- [ ] No architecture / boundary change
- [ ] ADR updated or new ADR added (`docs/adr/` + `docs/project/DECISION_LOG.md`)
- [ ] Provider / sidecar / refresh-cache impact reviewed
- [ ] Import canonicalization follows ADR-004 (`core/` + `copilot/`)

## Platforms / providers

- [ ] N/A
- [ ] macOS arm64 considered
- [ ] Windows x64 considered (Experimental)
- [ ] Claude Code path touched
- [ ] GitHub Copilot / sidecar path touched

## Screenshots / GIFs

<!-- Required for UI-visible changes. Else "N/A". -->



## Tests

- [ ] Unit / widget tests added or updated
- [ ] Golden tests updated (if UI chrome changed) / N/A
- [ ] Sidecar `npm run check` (if bridge touched) / N/A
- [ ] Regression coverage for bugs

## Documentation / handoff

- [ ] N/A — no doc impact
- [ ] Guides / architecture / provider docs updated
- [ ] `docs/project/` handoff reviewed (AI_HANDOFF, CONTEXT, NEXT_SESSION, …)
- [ ] `CHANGELOG.md` updated for user-facing changes / N/A

## Checklist (author)

- [ ] Follows [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ ] No invented usage values; stale/LKG labeled
- [ ] No undocumented / scraped APIs
- [ ] Quality CI expected green (Format / Analyze / Test / Validate workflows)
- [ ] Conventional Commit title (`fix:`, `feat:`, `docs:`, `ci:`, …)
- [ ] Does **not** reintroduce PR desktop builds or a Flutter Web tray demo

## Reviewer checklist

- [ ] Issue linkage and scope are appropriate
- [ ] Root cause (bugs) is credible; fix is not a temporary hack
- [ ] Tests adequate for risk
- [ ] Docs / handoff match the change
- [ ] Required CI checks green; branch up to date
