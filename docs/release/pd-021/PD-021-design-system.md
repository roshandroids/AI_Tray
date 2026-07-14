# PD-021 — Design System Implementation

**Status:** Ready for Product Owner review  
**Scope:** UI / UX / design system only (no parser, repository, refresh, domain)

## Delivered

### Design system

- Semantic color tokens (dark + intentional light)
- JetBrains Mono typography presets
- 8-pt spacing, radius, icon, shadow tokens
- Material themes composed from tokens
- Reusable components under `lib/core/components/`

### UI

- Dashboard: metric cards with progress rings, status + CLI health panels
- Settings: left navigation rail
- Diagnostics: live terminal panels
- Logs: search, filter chips, export/copy
- Tray (macOS): circular usage ring PNG via `TrayRingIconRenderer`
- Tray (Windows): static `.ico` (documented limitation)

### Docs

- [`docs/design/DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md)

## Known limitations

1. Claude CLI version still shows `—` (not in domain status without adapter change).
2. Windows tray cannot use runtime PNG rings through `tray_manager`.
3. Sparklines on metric cards are illustrative placeholders (not historical series).

## Acceptance checklist

- [x] JetBrains Mono throughout
- [x] Semantic color tokens; no widget-level magic colors (except tray track via tokens)
- [x] Reusable component library
- [x] Circular tray indicator (macOS) / documented Windows fallback
- [x] Responsive layouts
- [x] Existing functionality preserved (business logic untouched)
- [x] `flutter analyze --fatal-infos` clean
- [x] Tests pass (unit + golden)

## Stop gate

Await Product Owner review before additional features or release.

**Suggested review:** run the app, switch System/Dark/Light, open Dashboard → Settings rail → Diagnostics → Logs, and inspect the macOS menu-bar ring.
