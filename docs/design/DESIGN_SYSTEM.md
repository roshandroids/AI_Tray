# AI Tray Design System

**Version:** PD-021  
**Status:** Official design direction  
**Primary typeface:** JetBrains Mono (IBM Plex Mono fallback)

This document is the source of truth for visual language. Implement screens with
tokens and shared components — do not hardcode colors, type sizes, or spacing.

---

## Principles

| Principle | Meaning |
| --- | --- |
| Developer-first | Dense, terminal-inspired, fast to scan |
| Minimal chrome | Borders over shadows; no decorative cards |
| Semantic tokens | Widgets consume meaning (`success`), not hex |
| One composition | Desktop windows, not mobile scroll walls |
| Status in the icon | Tray ring encodes usage + health alone |

Peers: Claude Code, Warp, Ghostty, Raycast, Linear, GitHub Desktop.

---

## Theme architecture

```
lib/core/theme/
  app_theme.dart          # Material ThemeData from tokens
  color_tokens.dart       # TrayColorTokens (dark + light)
  typography.dart         # TrayTypography + TrayFonts
  spacing.dart            # Spacing 8-pt scale (+ exports)
  radius.dart             # RadiusTokens
  shadows.dart            # ShadowTokens (prefer none)
  icons.dart              # IconTokens sizes
  component_theme.dart    # Shared panel/button decorations
  theme_controller.dart   # System / Dark / Light preference
  theme_context.dart      # context.colors / context.typography
```

```
lib/core/components/
  progress_ring.dart
  usage_progress_bar.dart
  metric_card.dart
  status_badge.dart
  log_chip.dart
  section_chrome.dart     # InfoRow, SectionCard, TerminalPanel, SectionDivider
  settings_chrome.dart    # SettingsNavRail, SettingsTile, SettingsGroup
```

Access tokens via:

```dart
context.colors
context.typography
Spacing.md
RadiusTokens.md
```

---

## Color palette

### Dark (default)

| Token | Hex | Role |
| --- | --- | --- |
| background | `#0D1117` | Window canvas |
| surface | `#161B22` | Panels / cards |
| surfaceAlt | `#21262D` | Elevated / hover |
| border | `#30363D` | Separators |
| textPrimary | `#E6EDF3` | Titles & values |
| textSecondary | `#8B949E` | Labels |
| textMuted | `#6E7681` | Captions |
| success | `#22C55E` | Live / OK / 0–50% |
| warning | `#EAB308` | Cached / 50–80% |
| highUsage | `#F97316` | 80–95% |
| error | `#EF4444` | Failures / 95%+ |
| info | `#3B82F6` | Refreshing |
| purpleAccent | `#A855F7` | Primary accent |
| cyanAccent | `#06B6D4` | Secondary accent |

### Light

Intentional GitHub-light palette (not inverted dark). Same semantic names;
hex values live only in `TrayColorTokens.light`.

### Usage bands

```
0–50%   → success
50–80%  → warning
80–95%  → highUsage
95%+    → error
```

Use `TrayColorTokens.usageBand(percent)`.

---

## Typography

Family: **JetBrains Mono** → IBM Plex Mono → system monospace.

| Preset | Size / weight | Use |
| --- | --- | --- |
| display / title | 18 / 700 | App bar, product title |
| section | 14 / 600 | Section headers |
| label | 12 / 500 | Field labels |
| body | 12 / 400 | Body copy |
| caption | 11 / 400 | Hints, footnotes |
| monoData | 12 / 500 | Metrics & KV values |
| status | 12 / 600 | Badges |
| terminalOutput | 12 / 400 | Log lines |

No arbitrary font sizes in feature widgets.

---

## Spacing

8-point scale:

| Token | px |
| --- | --- |
| xs | 4 |
| sm | 8 |
| md | 16 |
| lg | 24 |
| xl | 32 |
| xxl (2xl) | 48 |

Layout constants: `contentMaxWidth` 720, `settingsRailWidth` 168,
`progressRingSize` 72.

### Radius

`sm` 4 · `md` 6 · `lg` 8 · `full` pill.

### Shadows

Prefer 1px borders. `ShadowTokens.none` is the default.

---

## Components

| Component | Purpose |
| --- | --- |
| ProgressRing | Circular usage with band color |
| UsageProgressBar | Thin horizontal fill |
| MetricCard | Label + ring + reset + optional sparkline |
| StatusBadge | ● Live / Cached / Error / … |
| HealthIndicator | Auth/CLI/Parser/Cache OK lines |
| InfoRow | Dense key/value |
| SectionCard / TerminalPanel | Bordered section |
| SectionDivider | Hairline rule |
| SettingsNavRail | Left settings navigation |
| SettingsTile / SettingsGroup | Setting rows |
| LogChip | DEBUG / INFO / WARN / ERROR chips |

---

## Iconography

Material outlined icons at `IconTokens` sizes (14 / 16 / 18). Prefer outline
variants; keep color from semantic tokens.

---

## Tray indicator

Monochrome **template** menu-bar glyph (filled rounded square). Usage is never
encoded in the icon.

| Channel | Role |
| --- | --- |
| Icon | Identity + connection (template; refresh = opacity pulse) |
| Title | Adaptive `%` (default), always `%`, or icon-only |
| Tooltip | Full usage + status |
| Color | Attention only (future); day-to-day is system template tint |

**Title density (Settings → Appearance → Menu Bar)**

| Mode | Behavior |
| --- | --- |
| Adaptive (default) | Show `%` at ≥ threshold (default 90%), or while refreshing/error |
| Always show % | Title whenever session % is available |
| Icon only | Empty title; details in menu + tooltip |

**Platform notes**

- **macOS menu bar:** `assets/tray/tray_menubar_template.png` (+ dim variant)
  via `trayManager.setIcon(..., isTemplate: true)`. Separate from the app icon.
- **Windows:** `tray_manager` expects `.ico`; static asset is used.
- **Usage-ring PNGs:** `TrayRingIconRenderer` remains for docs / screenshots;
  it is not the live menu-bar icon.

---

## Screens

### Dashboard

Metric cards (session / week), Status + CLI Health terminal panels, compact
keyboard footer (`⌘R` / `⌘L` / `⌘,`). Responsive: stacks under ~720px.

### Settings

Left navigation rail: Appearance, Refresh, Notifications, App Behavior, CLI,
Diagnostics, Logs, Advanced, About. Not a long mobile settings list.

### Diagnostics

Live Application / Refresh / Parser·Cache / Tools panels.

### Logs

Filter chips, search, copy / clear / export / open folder, columnar rows
(timestamp · level · component · message + recovery hint).

---

## Motion

Subtle only:

- Progress ring / bar ease (~400ms)
- Status badge color fades
- Settings section swaps via rail selection
- Hover: surfaceAlt on rail items

No bounce, glow pulses, or flashy transitions.

---

## Accessibility

- Contrast: dark & light palettes target WCAG AA for text on surface
- Status never color-only (dot + label)
- Keyboard: ⌘R refresh, ⌘L logs, ⌘, settings; Material focus rings
- Semantics on meters, badges, and tray tooltips
- Respect OS text scale; avoid fixed overflow for 125–150% desktop scaling

---

## Do / Don't

**Do**

- Import tokens and shared components
- Keep information density high
- Use monospace for all metrics

**Don't**

- Hardcode `Color(0x…)` in feature UI
- Invent padding outside the spacing scale
- Use soft purple gradient marketing looks
- Add large empty hero/dashboard whitespace

---

## Change control

Visual language changes require Product Owner approval (decision series PD-*).
Domain / parser / refresh algorithm remain out of scope for design-system work.
