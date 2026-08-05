# AI Tray V4 — Phase 0 UX Audit & Implementation Roadmap

**Status:** Draft for sign-off — implementation must not begin until priorities/sequencing below are confirmed.
**Method:** Full static read of `ai_tray/lib/` (navigation, all 8 page files, `core/components/`, `core/theme/`, `theme/`, `tray/`), cross-referenced against git history (V2/V3 commits) and `docs/design/DESIGN_SYSTEM.md` (PD-021). A live runtime pass (build, navigate every screen, resize to a large window, exercise keyboard shortcuts) was attempted but did not complete — it stalled on macOS window-focus/automation permissions and, on retry, escalated into an invasive attempt to attach `lldb` to the running app process to force window control, which was killed rather than allowed to continue. **Everything in this document is code-derived, not runtime-observed.** No screenshots exist. Claims about visual appearance, layout at large window widths, animation feel, and whether keyboard shortcuts actually fire are inferred from source, not verified live — flagged inline throughout with "needs confirmation" or "not confirmed" wherever this matters.
**Scope:** This is a gap analysis, not a greenfield audit. Several things the V4 brief asks for already exist — command palette (⌘K), a dedicated queue page, color-coded tray states, an 8-preset theme system, a spacing/typography/motion token layer. The audit below identifies what's genuinely missing, what's inconsistent/duplicated, and what needs completion — not what to build from scratch.

---

## 0. The decision that gates everything else

`docs/design/DESIGN_SYSTEM.md` (PD-021, "official design direction") states the current principles: **developer-first, dense, terminal-inspired**; peers listed are Claude Code, Warp, Ghostty, Raycast, Linear, GitHub Desktop; explicit rule "no decorative cards," "borders over shadows."

The V4 brief's target peers are Raycast, Cursor, Warp, **Linear, GitHub Desktop, Docker Desktop, Tailscale, Arc Browser, Notion** — and it explicitly wants the opposite of a dense terminal utility: "should not feel like a dashboard showing statistics... should feel like a workspace," adaptive cards with 24px padding, micro-interactions, animated counters, coach marks, onboarding.

These are not the same design language. Half the current peer list (Warp, Ghostty — terminal emulators) and half the V4 peer list (Notion, Arc, Docker Desktop — spacious, illustrated, animated) pull in different directions. This isn't a blocker to starting, but it is a decision the roadmap depends on: **is V4 evolving PD-021's principles, or superseding them?** Section 8 (Foundations) assumes supersession — new spacing/card rules — because that's what the brief asks for, but this should be an explicit, named decision (see the checkpoint questions at the end of this doc) rather than something that drifts implicitly screen-by-screen.

---

## 1. Design system & tokens

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 1.1 | `ComponentTheme.panel()/.panelAlt()/.outlinedAction()` (`core/theme/component_theme.dart`) is defined but has **zero call sites** anywhere in `lib/`. | Dead abstraction — the "shared decoration helper" that should prevent duplication isn't wired to anything. | None directly, but it signals the design-system layer has already drifted from the code once; a V4 rebuild risks repeating this unless the new primitives are enforced (lint rule / review, not just documentation). | Delete it, or make it the actual backing for `SectionCard`/`MetricCard`/new `InfoCard` — don't leave a third, unused option once V4 primitives land. | P2 |
| 1.2 | Three independent status→color/label switch statements: `LogChip` (over `LogLevel`), `QueueStatusChip` (over `ResumeQueueStatus`), `StatusBadge._color` (over `TrayStatusKind`), plus a **fourth** string-based status switch in `TrayMenuBuilder.fromStatus()` for the native tray menu text. | Each maps a different enum to the same `TrayColorTokens` palette independently. Any new status kind or color-band tweak (e.g. changing the 80%/95% usage thresholds) has to be updated in 3-4 places by hand. | Indirect — inconsistency risk (e.g. tray menu says "Cached" while the in-app badge shows a different shade) if one switch is updated and another is missed. | One `StatusPresentation` resolver (icon/color/label) that all four consume, keyed by a single shared status concept where possible. | P1 (fold into the design-system consolidation pass, before per-screen redesign) |
| 1.3 | No shared `EmptyState` widget. Three independently-built empty states: `_SessionListEmptyState`, `_QueueEmptyState`, `TrayEmptyState` (163 lines, the most elaborate, dashboard-only) — different structure, different styling per instance. | Directly duplicates work the brief explicitly asks to eliminate ("Remove duplicated layouts. Remove duplicated styles."). New empty states (Notifications page, Help Center, About) will otherwise get a *fourth* bespoke pattern. | Inconsistent empty-state polish across the app — some are one-line, some (dashboard) are richly copy-written per failure code. | Build `EmptyState` (icon/illustration + title + body + optional action) as a V4 primitive; port the three existing ones onto it, keeping `TrayEmptyState`'s per-`FailureCode` copy logic as the *content*, not the *chrome*. | P1 |
| 1.4 | Every one of the 5 shell-hosted pages (`UsagePage`, `SessionBrowserPage`, `ResumeQueuePage`, `LogsPage`, `SettingsPage`) wraps itself in its own `Scaffold` + `AppBar`. | The shell already renders one persistent frame (`app_shell.dart`'s `Row([NavigationRail, ..., IndexedStack])`); nesting 5 separate `AppBar`s inside it means 5 slightly different toolbar treatments for what should read as one continuous window. | Visually the app can feel like 5 stitched-together mini-apps rather than one workspace — directly undercuts the brief's "should feel like a workspace" goal. | Introduce a shared `PageHeader`/`Toolbar` primitive rendered *inside* the shell's content area, not a per-page `Scaffold`/`AppBar`. Collapse to one shell-level app bar (or none) with per-page header content slotted in. | P1 |
| 1.5 | Widget-to-file naming is non-obvious: `InfoRow`/`SectionCard`/`SectionDivider` live in `section_chrome.dart`; `StatusBadge`/`HealthIndicator` live in `status_badge.dart`; `SettingsNavRail`/`SettingsSection` live in `settings_chrome.dart`. | Not a user-facing issue, but it's a maintenance-cost item that will compound as the V4 primitive list (`PageHeader`, `InfoCard`, `MetricCard`, `StatusCard`, `QuickActionCard`, `ProviderCard`, `ProjectCard`, `SessionCard`, `Toolbar`, `SearchBar`, `CommandBar`, `PropertyGrid`, `Timeline`, `ProgressRing`, `StatusBadge`, `EmptyState`, `LoadingState`, `ErrorState`, `Skeleton`, dialogs, `Toast`, `Tooltip`, `CoachMark`, `ConfirmationDialog`) roughly triples the component count. | None directly. | One file per primitive (or a barrel file `lib/core/components/components.dart` re-exporting everything) as the V4 component set lands, rather than continuing the "chrome" grouping convention. | P3 |
| 1.6 | Typography and color token files carry multiple compatibility aliases (`heading→section`, `bodySmall→caption`, `meterValue→monoData`, `badge→status`, `emptyTitle→section`; `surfaceRaised`, `divider`, `title`, `primary`, `onPrimary`, `meterFill`, `statusRefreshing`, `statusIdle`). | Two names for the same role means new code can pick either one inconsistently, and it's unclear from the token file alone which is canonical. | None directly. | As part of the V4 token pass, pick one canonical name per role and remove the aliases (or explicitly mark them `@Deprecated`). | P2 |
| 1.7 | Tray icon renderer (`tray_ring_icon_renderer.dart:20`) hardcodes `const colors = TrayColorTokens.dark` — the live macOS menu-bar ring **always renders in the dark palette**, regardless of the user's active `ThemePreset` or light/dark mode. | The theme system (8 presets, light+dark each) exists specifically so the app matches user preference, but the one piece of UI that's visible *at all times* (the tray icon) ignores it entirely. | Low-severity visual inconsistency for users on a light preset/light menu bar — the ring's color bands (green/yellow/orange/red) are fixed regardless of theme, though this is arguably fine since they're semantic status colors, not brand colors. Worth a deliberate decision, not an accident. | Either confirm this is intentional (status colors should stay constant so users can read them at a glance regardless of theme — reasonable) and document it, or thread the active palette through. Low effort either way; the actual gap is that it's undocumented/accidental right now. | P3 |

---

## 2. Navigation & shell

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 2.1 | `NavigationRail` in `app_shell.dart` has **no responsive logic at all** — no `LayoutBuilder`, no width-based collapse/extend. Meanwhile individual pages (Dashboard, About, Session Detail) cap content at 720px and center it, while Settings/Logs/Sessions/Queue have no cap and stretch full width. Window has no `maximumSize`, so it's freely resizable to any monitor size. | Directly the brief's stated problem: "Current layout wastes space on large monitors... Do NOT keep the UI centered in a narrow column." Confirmed structurally: 3 of 8 pages are hard-capped at 720px with fixed margins beyond that on any window wider than ~750px; the other 4-5 stretch with no card-reflow logic, so at very large widths they likely just get very wide single-column lists rather than "reflowing" cards. | On any monitor above ~1400px this is visible immediately — either dead margin (capped pages) or an unnaturally wide single column (uncapped pages). This is probably the single most visible gap relative to the brief. | Shell-level responsive breakpoints (Compact/Wide/Ultra-wide) with a **content grid** primitive that lets cards reflow into multiple columns at Wide/Ultra-wide, replacing the two inconsistent patterns (hard cap vs. no cap) with one deliberate system. | P0 — this blocks nearly every per-screen redesign below, since each screen's layout should be defined in terms of the new grid, not re-derived per page. |
| 2.2 | `NavigationRail` is fixed at `labelType: .all` — never collapses to icon-only, never extends with more label space; no collapse affordance. | Brief asks for "Support collapse... Prepare for future features." | At narrow window widths the rail may compete for space with content (Settings' own nested rail is 168px + main rail — two rails at once on a small window). Not confirmed broken, but structurally has no defense against it. | Collapsible rail (icon-only at Compact, icon+label at Wide+) as part of the same responsive pass as 2.1. | P1 |
| 2.3 | About, Diagnostics, and Session Detail are **not shell destinations** — they're pushed as full-screen `MaterialPageRoute`s that cover the nav rail entirely (back button returns to shell). | Navigating to Diagnostics or About means losing the persistent nav rail — you can't jump straight from Diagnostics to Sessions without backing out first. This is a real "feels like separate mini-apps" tax, same root cause as 1.4. | Concretely: user checking Diagnostics after seeing a dashboard error can't ⌘1-5 jump to another tab from there; must back out first. Minor friction, but compounds with 1.4. | Decide deliberately whether About/Diagnostics become shell-adjacent (e.g. a slide-over panel within the shell, not a route push) or stay as modal-style pushes — right now it's inconsistent by omission, not by design. Session Detail staying a push (it's a drill-down, not a destination) is fine and matches the brief's "Session Details... Continue Conversation" framing. | P2 |
| 2.4 | Keyboard handling is entirely `HardwareKeyboard.instance.addHandler` + a manual `Focus.onKeyEvent` in the command palette — no use of Flutter's `Shortcuts`/`Actions`/`Intent` framework anywhere in the repo. | Works today, but every new shortcut (brief wants global ⌘K already covered, but Help Center, Product Tour restart, per-page shortcuts) means extending one large manual switch in `_onKey` rather than a declarative, composable shortcut map. | None today; risk is maintainability as shortcut surface grows with V4's expanded scope (Help, onboarding restart, coach marks, etc.). | Not urgent to rewrite the existing 5 shortcuts, but new V4 shortcuts should go through a proper `Shortcuts`/`Actions` registry to avoid one increasingly large `_onKey` function. | P3 |
| 2.5 | Command palette already exists and covers: go-to-destination, provider switch, Diagnostics, About, continue-last-session, queue-task, refresh, theme toggle, and fuzzy session search — this is most of what the brief's "Command Palette" section asks for. | Not a problem — flagged so implementation doesn't duplicate it. | N/A | Extend, don't rebuild: add Help Center, Product Tour, Settings sub-sections, and keyboard-shortcut list as additional actions in the existing `_buildActions()` registry. Palette keyboard nav is manual arrow-key handling, not `Shortcuts`/`Actions` — fine to leave as-is unless 2.4 gets tackled. | P2 (extension, not net-new) |

---

## 3. Dashboard

Current dashboard (`usage_page.dart`, 1034 lines) is metrics-first: provider dropdown, status badge, `MetricCard`s with `ProgressRing`s for session/weekly usage, a queue-status strip, empty-state on failure. It has an internal 560px breakpoint and a 720px content cap.

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 3.1 | No "Continue Last Session" / "Queue Task" primary actions on the dashboard itself — those exist as command-palette actions and on the Session Detail page, but the dashboard (the default landing screen) leads with metrics, not action. | This is exactly the brief's core complaint: "should not feel like a dashboard showing statistics... every screen should have a clear primary action." Confirmed: `UsagePage`'s primary visual weight is the `MetricCard`/`ProgressRing` pair, not a call-to-action. | New/returning users land on a screen that tells them a number, not what to do next. | Restructure per the brief: primary zone (Continue Last Session, Queue Task, Recent Sessions, Recent Queue, Command Palette entry point) above/beside the secondary metrics zone (Usage, Provider, Health, Notifications, Recent Activity, Reset countdown). Requires the 720px cap to be replaced by the new responsive grid (2.1) so primary+secondary zones can sit side-by-side on wide windows instead of stacking in a narrow column. | P0 (highest-visibility screen; also the one most explicitly called out in the brief) |
| 3.2 | No "Productivity Coach" concept exists at all — no proactive, situational messaging ("usage resets in 42 minutes," "queue idle," "Claude disconnected"). | Net-new feature, not a gap in existing code — flagging so it's scoped correctly as new work, not a redesign of something present. | N/A yet. | Needs its own small rules engine: a prioritized list of situational messages (reset countdown, queue state, notification-disabled, provider disconnected, usage-exhausted, no-activity-today) evaluated against current state, showing the single highest-priority one. Depends on: reset countdown data (exists — `MetricCard` already shows reset time), queue state (exists — `ResumeQueueRepository`), notification-enabled state (exists — settings), provider connection state (exists — health checks). All inputs exist; the coach is a new synthesis layer, not new data plumbing. | P1 |
| 3.3 | Health breakdown (Authentication/CLI/Cache/Parser/Filesystem/Permissions/Network) doesn't exist on the dashboard today — `HealthIndicator` component exists and is used, but only for a narrower set of checks; the full breakdown lives in Diagnostics (a separate full-screen push, per 2.3). | Brief wants per-item clickable health on the dashboard itself. | Users must leave the dashboard (full navigation push) to see *any* health detail beyond the status badge. | Surface a compact `StatusCard`/health summary on the dashboard (using the primitives already partially built in Diagnostics) that deep-links into the relevant Diagnostics section per item, rather than requiring the diagnostics page for all detail. | P1 |
| 3.4 | Usage card shows progress/remaining/reset — brief additionally wants trend and "estimated remaining usage" (a forecast, not just current state). | Trend/forecast is new derived data, not present in `MetricCard` today (it has a "mini sparkline," per the components inventory, so some historical data may already be plumbed — needs confirmation, not assumed). | Users can't currently answer "will I run out before reset" — a task-relevant question the brief specifically calls out. | Confirm what data the existing sparkline draws from; if it's real usage history, a trend/forecast line item is a presentation change, not new data collection. If not, scope data collection first. | P2 |

---

## 4. Sessions (browser)

Current (`session_browser_page.dart`, 321 lines): grouped by project, search, expand/collapse, first/live group auto-expanded, bespoke empty state, no max-width cap.

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 4.1 | Most of the brief's ask here already exists: project grouping, sort-by-recent, expandable groups, current-project-expanded, search. Genuinely missing per the brief: branch name, session count per group, live-status indicator per group (vs. per session), and explicit "hide long filesystem paths." | Listing this to prevent over-scoping a full rebuild. | N/A for the parts that exist. | Confirm current display fields against the ground-truth inventory before redesigning; likely a targeted addition (branch, count, path truncation) to `ProjectGroup` rendering, not a rewrite. | P2 |
| 4.2 | No shared `SessionCard`/`ProjectCard` primitive — rows are presumably bespoke `ListTile`-style widgets local to this page (not confirmed line-by-line, but no shared card component appears in the inventory). | Same duplication concern as section 1 — if Dashboard's "Recent Sessions" (3.1) needs to render sessions too, it'll either duplicate this page's row rendering or the two need to share a `SessionCard` primitive from day one. | N/A directly. | Build `SessionCard`/`ProjectCard` once, use on both the Sessions browser and the Dashboard's "Recent Sessions" zone. | P1 (dependency for 3.1) |

---

## 5. Session Detail

Current (`session_detail_page.dart`, 570 lines): primary "Continue conversation" action, secondary collapsed "Queue task," technical fields under "Advanced" disclosure, 720px cap, distinct loading/not-found/error states.

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 5.1 | Structurally this page **already matches the brief closely** — primary action first, technical detail collapsed, distinct not-found vs. error states. | Flagging as a "mostly done" surface, not a gap. | N/A | Verify against brief specifics not yet confirmed: "Large editor," "Prompt suggestions" (continuing-conversation input affordances) — these may not exist yet and would be genuinely new. Also: brief asks to "Explain Queue," "Explain Continue," "Make purpose obvious" — i.e. inline contextual copy/tooltips, which per section 9 don't exist anywhere in the app (zero `Tooltip` widgets found). | P2 for copy/explanation additions; confirm scope of "Large editor" / "Prompt suggestions" before estimating. |
| 5.2 | No `Semantics` gap here — this page already has accessibility labels (confirmed in inventory). | Not an issue. | N/A | N/A | — |

---

## 6. Queue

Current (`resume_queue_page.dart`, 259 lines): pending/running/succeeded/failed, `QueueStatusChip`, retry on failed, visibility-gated 2s polling, bespoke empty state, no max-width cap.

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 6.1 | Brief additionally wants: Cancelled state (distinct from Failed), a History section, Duration display, filters, search. Current page has 4 states (no explicit Cancelled) and no search/filter. | Real gap, not just presentation — Cancelled as a distinct state from Failed may require a data-model change (`ResumeQueueStatus` enum), not just UI. | Users can't currently distinguish "I cancelled this" from "this failed" after the fact, and can't search/filter a long queue history. | Check `ResumeQueueStatus` enum for a `cancelled` value before scoping — if absent, this is a small domain-model change threaded through the repository, not just the page. | P1 (data-model dependency should be resolved before the page redesign) |
| 6.2 | Duration isn't shown per the ground-truth inventory (not confirmed present or absent — needs a quick check of `ResumeQueueRepository`'s stored fields before scoping). | Unknown-cost item until confirmed. | — | Confirm start/end timestamps are already persisted per queue item; if so, duration is presentation-only. | P2 |

---

## 7. Logs

Current (`logs_page.dart`, 554 lines): search, level filter, provider filter, group-by-provider, expandable rows with metadata drawer, export, distinguishes empty-vs-no-match. This is already close to the brief's ask (toolbar, quick filters, expandable details, grouping).

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 7.1 | No virtual scrolling confirmed (brief explicitly asks for it under both Logs and Performance sections). Flutter's `ListView.builder` may already provide this implicitly if that's what's used — needs confirmation, not assumed broken. | Long log lists could jank without virtualization. | Only manifests with large log volumes — needs the runtime pass to confirm. | Confirm `ListView.builder`/`SliverList` usage; if a non-virtualized `Column`/`ListView` (non-builder) is used, that's the actual fix. | P2 |
| 7.2 | No `Semantics` usage found in `logs_page.dart` (confirmed absent in inventory). | Screen readers have no labels for log rows, filters, or the export action. | Accessibility gap for any screen-reader user trying to audit logs. | Add `Semantics` to filter controls and row summaries as part of the design-system consolidation pass, not deferred to "polish." | P1 |
| 7.3 | No "Sticky toolbar" confirmed — needs runtime check on scroll behavior. | — | — | Confirm during runtime pass. | P3 |

---

## 8. Settings

Current (`settings_page.dart`, 662 lines): left `SettingsNavRail` (168px fixed, own search) + content pane for Appearance/Refresh/Notifications/App Behavior/CLI/Advanced (Advanced holds navigation rows to Diagnostics/Logs/About, not real settings).

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 8.1 | Brief explicitly says "Replace ExpansionTiles" — not confirmed whether the current sections use `ExpansionTile` internally (ground-truth inventory didn't check this specific widget). | Needs a quick grep before scoping as a real finding vs. already-resolved. | — | Grep `ExpansionTile` in `settings/presentation/`; if present, replace with the sidebar-nav pattern the brief describes (which the page structurally already has at the top level — `SettingsNavRail` — so this may be about sub-section content, not the top-level nav). | P2 |
| 8.2 | No theme preview cards / accent-picker grid / font-picker with live preview confirmed — Appearance section presumably lists the 8 `ThemePreset`s and font presets, but "Large theme preview cards... Live preview" is a presentation upgrade regardless of current implementation. | The theme *system* (8 presets, `ThemeFactory`) is fully built — this is a presentation gap on top of real infrastructure, not a data/logic gap. | Users can't currently preview a theme before committing (needs runtime confirmation). | Build theme-preview-card and font-preview-card primitives once; the underlying `ThemePreset`/`FontPreset` enums already support "here's what N would look like" without switching. | P1 (high leverage — infra exists, only presentation is missing) |
| 8.3 | No global settings search across sections is confirmed as absent (only `SettingsNavRail`'s own local filter over section *labels* exists, per inventory: "own local search field filtering by label/keywords"). This filters which sections are shown, not settings *within* sections. | Brief wants search across all individual settings, not just section names. | Users can't jump directly to a specific setting by typing its name if they don't know which section it's in. | Flatten searchable settings into an index (label + section + keywords) rather than only filtering the rail. | P2 |
| 8.4 | Danger Zone (Reset / Clear cache / Delete logs / Disconnect provider) doesn't appear to exist — Advanced section currently just links to Diagnostics/Logs/About. | Net-new, and these are destructive actions — needs confirmation dialogs (brief lists `ConfirmationDialog` as a primitive for this reason). | Users currently have no in-app way to reset state/clear cache without external intervention (needs confirmation this is really absent, not just unlisted in the inventory). | Scope as new work, gated behind the `ConfirmationDialog` primitive (section 1's component list) — don't ship destructive settings actions without it. | P2 |

---

## 9. About / Diagnostics / Notifications / Help Center / Onboarding

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 9.1 | **No onboarding/first-run flow exists at all** — confirmed by repo-wide search (zero matches for onboarding/welcome/tutorial/first-run). `AiTrayApp` goes straight to `AppShell` on launch. | Explicit brief requirement (5-step First Run Experience) with literally nothing to build on. | New users get zero introduction to the mental model (tray app, sessions, queue, providers) — likely the single biggest first-impression gap relative to the brief. | Net-new: welcome → provider choice → CLI auto-detect/validate → feature tour → ready. CLI auto-detect/validate should reuse existing Diagnostics health-check logic (don't rebuild detection twice). | P0 for user-facing polish, but sequence *after* the design-system primitives (section 1) exist, since onboarding will consume `EmptyState`/`CoachMark`/dialog primitives directly. |
| 9.2 | **No Help Center exists** — no searchable in-app documentation surface. | Explicit brief requirement; also reduces support burden if genuinely useful. | Users hit friction points (what does Queue mean, why is my usage capped) with nowhere to look inside the app. | Net-new. Content can mostly be authored from what already exists in `docs/` (this repo already has extensive internal docs) — the work is UI + information architecture, not new subject-matter research. | P2 (valuable, but not blocking — de-prioritize relative to fixing the surfaces it would explain) |
| 9.3 | **No Product Tour / coach marks** anywhere in the codebase. | Explicit brief requirement, depends on the `CoachMark` primitive (net-new) and a defined tour script. | — | Net-new, sequence after onboarding (9.1) since it's a restartable version of the same content. | P3 |
| 9.4 | **No standalone Notifications page** — notification behavior is one Settings section plus a working `NotificationGateway` abstraction (real + fake implementations already exist, wired to `TrayController.maybeNotify()`). | Brief wants notification preview, history, and test-notification as a dedicated experience, not buried in Settings. | Users can't currently see past notifications or preview what one looks like before enabling. | The gateway abstraction already supports firing test notifications; history is the only new data need (would require persisting sent notifications, currently fire-and-forget). Scope the persistence need explicitly — it's the one piece that isn't presentation-only. | P2 |
| 9.5 | Diagnostics page (`diagnostics_page.dart`, 607 lines) already has: live health dashboard, refresh status, parser state, provider-specific diagnostics, warnings list, and a 720px responsive breakpoint. Missing per the brief: **repair actions per check** ("Every check: Status, Description, Repair action") — current inventory shows status/description patterns but no confirmed "repair action" affordance. | Diagnostics telling you something is broken without an in-app fix is a dead end — brief specifically calls this out. | User sees "Authentication: failed" and must leave the app to fix it (re-run CLI login, etc.) rather than a button that does it. | Add a repair-action slot per health check row; many repairs (re-authenticate, clear cache, restart CLI detection) likely just re-invoke existing Diagnostics/CLI logic already present for the initial check. | P1 |
| 9.6 | About page (`about_page.dart`, 361 lines) already has hero, live version/build, changelog rendering, GitHub links, system info, Diagnostics link — close to brief's ask. Missing: "Copy diagnostics" as an explicit About-page action (may exist inside Diagnostics itself — not confirmed). | Minor gap if genuinely absent. | Low — users can likely already reach diagnostics-copy from the Diagnostics page itself. | Confirm whether copy-diagnostics exists on the Diagnostics page; if so, this is just a convenience shortcut from About, not new functionality. | P3 |

---

## 10. Accessibility & keyboard

| # | Issue | Why it's a problem | User impact | Proposed solution | Priority |
|---|---|---|---|---|---|
| 10.1 | `Semantics` usage exists in 12 files (mostly shared components + 3-4 pages) but is **absent from `logs_page.dart`, `diagnostics_page.dart`, `about_page.dart`, `resume_queue_page.dart`** — 4 of 8 top-level pages. | Screen-reader users get no labels on roughly half the app's screens. | Concrete accessibility failure, not theoretical — confirmed by grep, not inferred. | Add `Semantics` to the 4 gap pages as part of the design-system pass — likely low effort if the new shared primitives (Toolbar, cards) carry `Semantics` internally, since most of these pages' content is built from shared pieces once the V4 primitives land. | P1 |
| 10.2 | Zero `Tooltip` widget usage anywhere; tooltips only exist via `IconButton(tooltip:)`'s built-in param on a handful of icon buttons. | Brief wants "Use tooltips. Inline help. Help icons." broadly, e.g. explaining Budget/Queue/Provider concepts — current tooltip coverage is incidental (icon-button hover text), not deliberate contextual help. | Users have no in-context explanation for non-obvious concepts (budget caps, queue behavior) outside of hovering the handful of icon buttons that happen to have one. | Build a `Tooltip`/inline-help primitive and deliberately place it on concept-introducing UI (Budget field, Queue explanation, Provider capability differences) rather than relying on incidental `IconButton` tooltips. | P2 |
| 10.3 | Reduced-motion (`MediaQuery.disableAnimations` via `MotionTokens.reduced()`) is only checked in `progress_ring.dart` and the dashboard's animated percent counter — not verified elsewhere. | New micro-interactions (brief wants animated counters/queue/notifications broadly) risk being added without the reduced-motion check that already exists as a pattern in exactly 2 places. | Motion-sensitive users get inconsistent treatment — some animations respect the preference, others (once built) might not if the pattern isn't systematically applied. | Route all new animation through a shared helper that consults `MotionTokens.reduced()` by construction (e.g. an `AnimatedIf`-style wrapper), rather than requiring every new widget to remember the check. | P2 |
| 10.4 | No `Shortcuts`/`Actions`/`Intent` framework usage (see 2.4) — also relevant here since Flutter's accessibility tooling integrates better with the declarative framework than raw `HardwareKeyboard` handlers. | Secondary accessibility angle beyond maintainability. | Marginal — not a demonstrated failure, a structural risk as shortcut surface grows. | Same fix as 2.4. | P3 |

---

## 11. Performance

No performance problems were *confirmed* in the static read (this needs the runtime pass + profiling, not a code-read guess). What's confirmed structurally:

- `IndexedStack` keeps all 5 shell pages alive simultaneously (`app_shell.dart`) — reasonable for state preservation, but means all 5 pages' widget trees exist at once; worth confirming this doesn't cause redundant work (e.g. `ResumeQueuePage`'s polling is already gated on visibility, a good sign this was considered).
- No confirmed use of `ListView.builder` vs. plain `Column`+`ListView` for Logs/Sessions/Queue lists — flagged in 7.1, relevant to Sessions and Queue too if they grow large.
- Debounced search: not confirmed present or absent in Sessions/Logs/Settings search fields — needs a targeted check, not assumed.

**Recommendation:** treat Performance as a validation gate on the redesigned screens (measure after rebuilding with real data volumes), not a separate up-front audit item, since most of "the fix" is "use `.builder` constructors and debounce inputs" — good practice to apply while rebuilding each screen rather than a standalone project phase.

---

## 12. What's already good — don't rebuild

Explicit call-out per the audit's own instructions (avoid recommending rebuilds of things that work):

- Command palette (⌘K) — full action registry + fuzzy session search. Extend, don't replace.
- 8-preset branded theme system (`ThemeFactory`, `ThemePalette`) with FlexColorScheme-generated M3 roles, live-swappable, light+dark per preset.
- Motion tokens with three named durations, two curves, and a reduced-motion helper.
- Spacing/typography/color token layer (`core/theme/`) — needs alias cleanup (1.6) and enforcement (1.1), not replacement.
- Tray color-coded states (V3 phase 3) — ring renderer with live/cached/error/idle/refreshing states, dashed-vs-solid semantics, 30-minute render cache.
- `NotificationGateway` abstraction (real + fake) already supports the "test notification" ask in 9.4's Notifications page.
- Session Detail's information hierarchy (primary action first, technical detail collapsed) already matches the brief's intent — needs polish, not restructuring.
- Distinct empty/error/not-found states exist per-page already (just not unified — see 1.3).

---

## 13. Roadmap (dependency-ordered, not brief-document-ordered)

The brief itself says primitives before screens; this roadmap follows that, then sequences screens by how much they block other screens, then net-new surfaces, then polish/validation.

**Phase 1 — Foundations (blocks everything else)**
1. Resolve the design-language decision (Section 0) — evolve vs. supersede PD-021.
2. Responsive shell: breakpoints (Compact/Wide/Ultra-wide), collapsible nav rail, content grid primitive replacing the 720px-cap-vs-no-cap split (2.1, 2.2).
3. Core primitives: `EmptyState`, `PageHeader`/`Toolbar` (replacing per-page `Scaffold`/`AppBar`), unified `StatusPresentation` resolver, `SessionCard`/`ProjectCard`, `ConfirmationDialog`, `Tooltip`/inline-help wrapper (1.2, 1.3, 1.4, 4.2, 8.4, 10.2).
4. Token cleanup: remove/deprecate compatibility aliases, wire or delete `ComponentTheme` (1.1, 1.6).

**Phase 2 — Highest-leverage screen redesigns**
5. Dashboard: action-first restructure using the new grid + cards (3.1), Productivity Coach v1 (3.2 — all input data already exists), health summary surfaced from Diagnostics (3.3).
6. Settings: theme/font preview cards (8.2 — pure presentation on top of existing infra, high visible payoff for the effort), global settings search (8.3).
7. Diagnostics: repair actions per check (9.5).

**Phase 3 — Remaining screen polish + net-new surfaces**
8. Sessions/Queue: confirmed-missing fields (branch, count, Cancelled state — resolve the `ResumeQueueStatus` model question in 6.1 first), search/filter.
9. Logs: virtualization/Semantics confirmation and fixes (7.1, 7.2).
10. Accessibility sweep: `Semantics` on the 4 gap pages (10.1).
11. Onboarding (9.1) — built on Phase 1 primitives, reusing Diagnostics' existing CLI-detection logic.
12. Notifications page (9.4) — add history persistence, reuse existing gateway.

**Phase 4 — Polish, tour, help, validation**
13. Product Tour / coach marks (9.3), Help Center (9.2).
14. Final polish pass: second UX audit as a fresh user, fix inconsistencies found.
15. Validation: `flutter analyze`, `flutter test`, desktop build, responsiveness at Compact/Wide/Ultra-wide, keyboard nav, onboarding, tour, command palette, accessibility. Before/after screenshots of every major screen. Final written UX review (what changed, why, remaining V5 items, architecture notes).

---

## 14. Open questions for sign-off (before Phase 1 starts)

1. **Design language** (Section 0): does V4 keep PD-021's "developer-first, dense, terminal-inspired, no decorative cards" direction, or move toward the brief's Notion/Arc/Docker-Desktop-inspired spacious/card-first direction? This changes the actual pixel values chosen in Phase 1 step 2-3.
2. **Sequencing**: does the priority order above (Foundations → Dashboard/Settings/Diagnostics → remaining screens → net-new surfaces → polish) match your priorities, or is there a screen/feature you want pulled forward (e.g. onboarding first, since it's the most visible gap for new users, even though it depends on Phase 1 primitives)?
3. **Scope confirmation for uncertain items**: several findings above (6.1 Cancelled state, 6.2 duration data, 8.1 ExpansionTiles, 9.4 notification history, 9.6 copy-diagnostics) are flagged as "needs a quick check" rather than confirmed — should I resolve these now (a few minutes of targeted grep/read) before Phase 1, or fold that into each phase as it comes up?
4. **Runtime findings**: the parallel live-app pass (screenshots, resize behavior, actual keyboard shortcut verification) hadn't completed at the time this draft was written — worth a short follow-up read once it lands, in case it surfaces something that reprioritizes the above.
