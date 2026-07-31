# ADR-005: FlexColorScheme branded personalization

**Status:** Accepted  
**Date:** 2026-07-31  
**Deciders:** Product Owner / maintainer  
**Related:** PD-026, D-021, PD-014, PD-021

---

## Context

AI Tray shipped a fixed dual-palette Material 3 theme (PD-021) with only
theme-mode persistence (PD-014). Users need selectable branded color themes,
independent typography, and a forward-compatible app-icon path without
rewriting every tray surface that consumes `TrayColorTokens`.

## Decision

1. Build themes with **FlexColorScheme** Material 3 using **custom-only**
   `FlexSchemeColor` seeds (no built-in `FlexScheme` catalogs).
2. Own personalization in `ai_tray/lib/theme/` with `ThemePreset`,
   `FontPreset`, `AppIconPreset`, `AppTheme`, and
   `PersonalizationController`.
3. Derive `TrayColorTokens` / `TrayTypography` from the generated
   `ColorScheme` so existing UI call sites keep working.
4. Bundle Inter, JetBrains Mono, Fira Code, IBM Plex Sans, IBM Plex Mono, and
   Geist offline; other font presets use system fallbacks. No `google_fonts`.
5. Persist theme mode, theme preset, font preset, and app icon via
   `settings_v1_*` SharedPreferences keys.
6. Provide `AppIconSwitcher` with an unsupported desktop default; Settings
   shows the picker disabled with an explanation while still persisting the
   selection.

## Consequences

### Positive

- Immediate theme/font updates without restart
- Extensible preset catalogs without business-logic churn
- Offline, consistent typography on supported bundles
- Platform-agnostic icon architecture ready for future adapters

### Negative / trade-offs

- Larger binary from bundled fonts
- Visual golden baselines change with Cursor + Inter defaults
- Runtime dock/taskbar icon switching remains unimplemented on desktop

### Follow-ups

- Optional macOS/Windows `AppIconSwitcher` adapters when APIs allow
- Consider bundling Source Sans 3 if demand appears

## Alternatives considered

| Option | Why not |
| --- | --- |
| Built-in FlexScheme catalogs | Violates branded-palette requirement |
| `google_fonts` runtime fetch | Offline tray constraint |
| Hide app-icon UI until supported | Users cannot pre-select; architecture less exercised |

## References

- `ai_tray/lib/theme/`
- Settings Appearance section
- PD-026 / D-021 in `docs/project/DECISION_LOG.md`
