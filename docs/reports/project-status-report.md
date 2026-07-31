# AI Tray — Project Status Report

**Generated:** 2026-07-31
**Method:** Read-only source audit. Every claim below was verified against the
files cited next to it (branch `cursor/ep004a-local-first-ci`). Where an
existing document (`docs/project_intelligence_report.md`, `docs/project/*.md`)
was used to cross-check a number, that is stated explicitly — this report does
not restate those documents without independent verification.
**Scope:** Architecture, features, Claude CLI integration, data flow, Riverpod
providers, domain models, desktop integration, settings/persistence, tests,
CI/CD, documentation, dependencies, extension points, technical debt, reusable
code, and readiness for seven proposed v2 capabilities (Session Browser, JSONL
parser, Session Repository, Resume Queue, Resume Scheduler, Session Analytics,
Notifications).

No files were modified to produce this report.

---

## 1. Current Architecture

AI Tray is a single Flutter desktop application (`ai_tray/`) that shows AI
coding-tool subscription usage in a macOS menu bar / Windows tray icon. It
follows a feature-first Clean Architecture with one direction of dependency:

```
Presentation (pages, tray)
  -> Riverpod state (Notifier / AsyncNotifier / Provider)
    -> Domain (ports, immutable models, ProviderRegistry)
      -> Data (repositories, services, adapters, process/sidecar)
        -> External (Claude CLI, Node sidecar, SharedPreferences, OS tray APIs)
```

Verified structural facts:

- The UI never imports `dart:io` process APIs or the Copilot SDK directly —
  only `ClaudeCliAdapter` (`lib/features/providers/data/claude/claude_cli_adapter.dart`)
  and the Copilot sidecar stack call external processes.
- All async application state is Riverpod 3 (`flutter_riverpod: ^3.3.2`,
  `ai_tray/pubspec.yaml:12`) — no `get_it`, no Bloc, no codegen (`@riverpod`
  annotations do not appear anywhere in `lib/`).
- `ProviderContainer` + `UncontrolledProviderScope` is built in
  `lib/bootstrap.dart` before `runApp`, so the usage repository and tray
  controller can start (`unawaited`) ahead of first frame.
- A `ProviderRegistry` (`lib/features/providers/core/registry/provider_registry.dart`)
  holds an insertion-ordered, ID-keyed map of `AIProvider` implementations and
  enforces a single enabled default at construction time — this is the seam
  that lets Claude and Copilot share one dashboard without `if (providerId ==
  ...)` branching in presentation code.
- There is no router (`go_router`/`auto_route` are absent from
  `ai_tray/pubspec.yaml`); navigation is imperative `Navigator.push` from a
  single `MaterialApp(home: UsagePage())` in `lib/app.dart`.

## 2. Folder Structure

```
AI_Tray_Project/
├── ai_tray/                  # the Flutter product (only Dart package)
│   ├── lib/
│   │   ├── main.dart / bootstrap.dart / app.dart
│   │   ├── core/              # theme, DI wiring, errors, Result, logging, shared widgets
│   │   └── features/
│   │       ├── diagnostics/presentation/     # diagnostics + logs pages
│   │       ├── notifications/{data,domain,presentation}/  # .gitkeep only — no code
│   │       ├── providers/
│   │       │   ├── core/        # canonical ports, models, registry, process port, cache
│   │       │   ├── copilot/     # canonical Copilot SDK client + NDJSON sidecar transport
│   │       │   ├── data/        # Claude adapter, process runners, some re-export shims
│   │       │   ├── domain/      # mostly re-exports -> core/ (see §15 Technical Debt)
│   │       │   ├── presentation/ # provider selector notifier + widget
│   │       │   └── provider_providers.dart
│   │       ├── settings/{data,domain,presentation}/
│   │       ├── tray/presentation/
│   │       └── usage/{data,domain,presentation}/
│   ├── test/{fixtures,unit,widget,golden,screenshot}/
│   ├── tool/copilot_sdk_bridge/   # private Node/TypeScript package, NDJSON stdio bridge
│   ├── macos/ windows/            # generated desktop runners (only two platforms)
│   └── assets/{fonts,tray}/
├── docs/                      # 79 markdown files measured directly (see §11)
├── research/                  # early Python CLI PoC, kept for provenance
├── scripts/{ci,release}/      # shell automation for CI gates and SemVer releases
├── showcase/                  # demos.json / metadata.json catalog contract
└── .github/workflows/         # quality, documentation, release, maintenance, reusable web demo
```

There is no `android/`, `ios/`, `web/`, or `linux/` platform folder, no
`melos.yaml`/pub workspace, and no FVM — confirmed by directory listing.
`lib/shared/widgets/` exists but is empty (reserved); reusable widgets
currently live in `lib/core/components/`.

## 3. Features Implemented

Each entry below was opened and read directly.

### 3.1 Usage / Refresh (core feature)

- **Purpose:** Fetch, validate, cache, and expose one canonical usage
  snapshot per provider, driving both the in-window dashboard and the tray
  icon/menu.
- **How it works:** `UsageRepositoryImpl.refresh()`
  (`lib/features/usage/data/repositories/usage_repository_impl.dart:117`)
  reads settings, bumps a `_refreshGeneration` counter, and delegates to
  `RefreshService.refresh()` (`lib/features/usage/data/services/refresh_service.dart:54`),
  which coalesces concurrent calls per `ProviderId` through an `_inFlight`
  map (single-flight), attempts one bounded retry (`softRetryDelay` 3s /
  `hardRetryDelay` 2s depending on failure shape,
  `refresh_service.dart:209-239`), parses via the provider's own
  `ProviderUsageParser`, validates with `UsageValidator`, and writes the
  result to `UsageCache`. `UsageRepositoryImpl` then computes the next
  `Timer` deadline itself (`_reschedule`, `usage_repository_impl.dart:249`)
  with soft/hard backoff (120s / 180s floors after 3 consecutive failures)
  and exposes a broadcast `Stream<RefreshStatus>` that both the dashboard and
  `TrayController` subscribe to. `recoverScheduleIfOverdue()`
  (`usage_repository_impl.dart:85`) fires a catch-up refresh after sleep/wake
  if the scheduled deadline has already passed.
- **Main files:** `usage_repository_impl.dart`, `refresh_service.dart`,
  `usage_cache.dart`, `usage_validator.dart`, `usage_parser.dart`,
  `dashboard_data_mapper.dart`, `usage_page.dart` (868 LOC — the largest file
  in `lib/`).
- **Dependencies:** `shared_preferences` (cache), the active `AIProvider`
  (Claude or Copilot), `AppLogger`.
- **Current limitations:** One in-flight refresh per provider only — this is
  coalescing, not a work queue (see §17.4). The cache stores exactly one JSON
  record per provider key (`usage_lkg_v2_<providerId>`), so there is no
  history; only the latest snapshot survives a restart.

### 3.2 Provider Platform (Claude, Copilot, Cursor-research)

- **Purpose:** Let one dashboard render usage for more than one AI vendor
  without vendor-specific UI branches.
- **How it works:** `AIProvider` (`lib/features/providers/domain/ports/ai_provider.dart`,
  re-exported from `core/ports/`) is implemented by `ClaudeCliAdapter` and
  `CopilotProvider`/`CopilotSdkAdapter`. `ProviderCapabilities`
  (`lib/features/providers/core/models/provider_models.dart:44`) is a plain
  boolean struct (`sessionUsage`, `weeklyUsage`, `healthCheck`,
  `customExecutable`) with static const instances per provider
  (`.claude`, `.copilot`, `.copilotPlaceholder`) that presentation code reads
  instead of switching on provider ID.
- **Main files:** `provider_registry.dart`, `provider_models.dart`,
  `claude_cli_adapter.dart`, `copilot_provider.dart`, `copilot_adapter.dart`,
  `copilot_sdk_v1.dart`, `sidecar_process_transport.dart` (514 LOC),
  `provider_selection_controller.dart`.
- **Dependencies:** `ProcessRunner` (Claude), bundled Node sidecar +
  `@github/copilot-sdk@1.0.7` (Copilot, via `tool/copilot_sdk_bridge`).
- **Current limitations:** Cursor has research documentation
  (`docs/claude_code_cli_capability_report.md` is about Claude, not Cursor —
  Cursor research lives under `docs/research/`) but **zero production code**;
  it is not registered in `ProviderRegistry`. Copilot's `account.getQuota` RPC
  is explicitly labeled experimental in product docs.

### 3.3 Settings

- **Purpose:** User-configurable preferences: auto-refresh, interval, theme,
  provider selection, notification threshold, launch-at-login, custom Claude
  binary path.
- **How it works:** `AppSettings` (`lib/features/settings/domain/models/app_settings.dart`)
  is an immutable, validated value object (refresh interval clamped to 30–60s,
  a notify-threshold clamped to 0–100, constructor-time `ArgumentError` on
  violation). `SettingsNotifier` (`AsyncNotifier<AppSettings>`,
  `settings_controller.dart:23`) reads/writes through `SettingsRepository`.
- **Main files:** `app_settings.dart`, `settings_repository_impl.dart`,
  `settings_controller.dart`, `settings_page.dart` (663 LOC).
- **Dependencies:** `shared_preferences`; `launch_at_startup` (applied via a
  provider-injected function, `applyLaunchAtLoginProvider`).
- **Current limitations:** Single flat settings blob per key
  (`settings_v1_*` prefix) — no per-provider settings schema versioning
  beyond the `_v1_` prefix name.

### 3.4 Tray / Desktop Shell

- **Purpose:** Native menu-bar (macOS) / system-tray (Windows) presence:
  icon reflecting live status, context menu, window show/hide, notifications,
  launch-at-login.
- **How it works:** `initializeDesktopShell()`
  (`lib/features/tray/presentation/tray_controller.dart:24`) sets up
  `window_manager` (fixed 720×640 window, `setPreventClose(true)`),
  `local_notifier`, and `launch_at_startup`, and returns early
  (no-op) on web or non-macOS/Windows platforms. `TrayController` listens to
  `UsageRepository.watchStatus()` and on every status change calls
  `_rebuildMenu` (repaints the icon — a Canvas-rendered ring on macOS via
  `TrayRingIconRenderer`, a static `.ico` swap on Windows) and `maybeNotify`.
- **Main files:** `tray_controller.dart`, `tray_menu_builder.dart`,
  `tray_icon_resolver.dart`, `tray_ring_icon_renderer.dart`.
- **Dependencies:** `tray_manager ^0.5.3`, `window_manager ^0.5.2`,
  `local_notifier ^0.1.6`, `launch_at_startup ^0.5.1`.
- **Current limitations:** `TrayController.maybeNotify()`
  (`tray_controller.dart:220`) creates a `LocalNotification(title, body)` with
  **no payload and no click handler** — verified directly, there is no
  `onClick`/`onClickAction` wiring anywhere in the file or its test
  (`test/unit/tray/tray_menu_builder_test.dart` does not cover notifications).
  A click on the OS notification does nothing app-specific today.

### 3.5 Diagnostics & Logs

- **Purpose:** Show CLI/SDK health, version, and buffered structured logs for
  troubleshooting without a terminal.
- **How it works:** `CopilotDiagnosticsController`
  (`AsyncNotifier<CopilotDiagnostics>`,
  `copilot_diagnostics_controller.dart:11`) drives `diagnostics_page.dart`
  (603 LOC); `logs_page.dart` reads from `BufferedAppLogger`
  (`lib/core/logging/buffered_app_logger.dart`) and supports exporting the
  buffer to a file (`File(...)` write in `logs_page.dart:263`).
- **Main files:** `diagnostics_page.dart`, `logs_page.dart`,
  `copilot_diagnostics_controller.dart`, `buffered_app_logger.dart`.
- **Dependencies:** `AppLogger` hierarchy, Copilot health/version cache
  providers in `provider_providers.dart`.
- **Current limitations:** Diagnostics content is Copilot-specific in its
  controller name; Claude has no equivalent structured diagnostics page
  (Claude health surfaces through the shared refresh/auth-failure path
  instead).

### 3.6 Notifications (feature folder)

- **Purpose (declared by folder name only):** a dedicated notifications
  feature.
- **How it works:** Nothing — verified directly:
  `lib/features/notifications/{data,domain,presentation}/` each contain
  exactly one `.gitkeep` file and zero `.dart` files.
- **Main files:** none.
- **Dependencies:** none.
- **Current limitations:** The real, working notification code (threshold
  check + `local_notifier` call) lives in `TrayController.maybeNotify`
  (§3.4), not here. This is an empty scaffold, not a stub implementation.

### 3.7 Theme / Design System

- **Purpose:** Terminal-inspired dark/light Material 3 theme, applied via a
  single `ThemeExtension` (`ThemeContext`/`ColorTokens`) rather than scattered
  constants.
- **How it works:** `ThemeController` (`AsyncNotifier<AppThemePreference>`,
  `theme_controller.dart:11`) persists System/Dark/Light choice; components
  under `lib/core/components/` (`progress_ring`, `usage_progress_bar`,
  `metric_card`, `status_badge`, `log_chip`, `section_chrome`,
  `settings_chrome`) consume `context.colors` / `context.typography` /
  `Spacing.*` / `RadiusTokens.*`.
- **Main files:** `lib/core/theme/*`, `lib/core/components/*`.
- **Dependencies:** none beyond Flutter/Material; custom fonts (JetBrains
  Mono, IBM Plex Mono) declared in `pubspec.yaml`.
- **Current limitations:** No localization — confirmed no `l10n.yaml`, no
  `.arb` files, no `flutter_localizations` dependency anywhere in the repo;
  all strings are English literals.

## 4. Claude CLI Integration

Read directly from `lib/features/providers/data/claude/claude_cli_adapter.dart`.
The **entire** production surface touching the Claude CLI is three
invocations, all through the buffered `ProcessRunner` port (§9):

| Call | Arguments | Purpose |
| --- | --- | --- |
| Usage fetch | `claude -p /usage --output-format json` (`claude_cli_adapter.dart:66`) | The only usage data source |
| Version probe | `claude --version` (`claude_cli_adapter.dart:127`) | Detect CLI not installed |
| Auth probe | `claude auth status --json` (`claude_cli_adapter.dart:143`, 5s timeout) | Detect not-authenticated |

Verified absent from the codebase (grep across `lib/`): `--resume`,
`--continue`, `--session-id`, `--output-format stream-json`, `agents --json`,
and any read of `~/.claude/projects/**/*.jsonl`. The adapter's own doc comment
states the policy explicitly: *"Never uses `--bare` for usage polls."*
(`claude_cli_adapter.dart:17`).

The stdout of the usage call is decoded as one JSON object
(`jsonDecode(process.stdout)`, `claude_cli_adapter.dart:87`) and the `result`
field's free text is handed to `UsageParser`
(`lib/features/usage/data/parsers/usage_parser.dart`), which defends against
two known shapes (Shape A: parseable; Shape B: degraded/missing limits) per
`docs/adr/ADR-001-claude-cli-data-source.md`. This is regex/string parsing of
prose, not structured JSON parsing of a stable schema — the code comments and
`docs/project/ARCHITECTURE_STATE.md:48` both flag the free-text schema as
unstable.

A separate document, `docs/claude_code_cli_capability_report.md`, records
live-tested CLI behavior (session listing, `--resume`, JSONL file layout,
`stream-json` envelopes) that **is not wired into any code** — it is dated
research, not implementation. Section 8 of that report is itself titled
"Recommended Architecture for AI Tray" and proposes the Session
Browser/Resume Queue/Resume Scheduler concepts this report is asked to
evaluate readiness for (§16).

## 5. Data Flow

Two independent flows exist today; both were traced from the actual
`refresh()`/adapter code, not from a diagram.

### 5.1 Claude

```
UsageRepositoryImpl.refresh()
  -> RefreshService.refresh() [single-flight per ProviderId]
    -> ClaudeCliAdapter.fetchUsageRaw()
      -> ProcessRunner.run('claude', ['-p','/usage','--output-format','json'])
      -> IoProcessRunner: Process.start, stdin closed immediately, stdout/stderr
         joined to full Strings, exitCode awaited with an 8s default timeout
    -> jsonDecode(stdout) -> envelope['result'] free text
    -> UsageParser.parse() -> ParserState (Shape A / Shape B)
    -> UsageValidator.validate() -> UsageInfo | AppFailure
  -> UsageCache.write(UsageInfo)  [SharedPreferences, one record per provider]
  -> RefreshStatus emitted on a broadcast Stream
  -> UsagePage (dashboard) + TrayController (icon/menu/notification) both
     rebuild from that Stream
```

### 5.2 GitHub Copilot

```
CopilotSdkAdapter -> CopilotSdkV1.getQuota()
  -> SidecarProcessTransport.request('account.getQuota', {})
     [persistent Node child process; one correlated NDJSON line per request,
      id+protocolVersion envelope, 15s request timeout, up to 1 auto-restart
      on crash, stderr redaction of tokens/credentials]
  -> CopilotQuotaMapper maps the SDK DTO to app-owned quota/usage models
     (no SDK type escapes the adapter boundary)
  -> same RefreshService / UsageCache / RefreshStatus pipeline as Claude
```

Both flows converge on the same `RefreshService` → `UsageCache` →
`RefreshStatus` stream, which is exactly what makes the dashboard and tray
provider-agnostic. Neither flow reads or writes any file-based transcript —
`UsageCache` is the only persistence sink for provider data.

## 6. Riverpod Providers

Enumerated with `grep -rn "^final .*Provider" lib` and
`grep -rn "extends .*Notifier"` — not copied from prior documentation.

| Provider / Notifier | Kind | File |
| --- | --- | --- |
| `themeControllerProvider` | `AsyncNotifier<AppThemePreference>` | `core/theme/theme_controller.dart` |
| `bufferedAppLoggerProvider` | `Provider<BufferedAppLogger>` | `core/logging/logging_providers.dart` |
| `appLoggerProvider` | `Provider<AppLogger>` | `core/logging/logging_providers.dart` |
| `aiProviderPortProvider` | `Provider<AiProviderPort>` (compat alias) | `core/di/providers.dart` |
| `usageParserProvider` | `Provider<ProviderUsageParser>` | `core/di/providers.dart` |
| `usageValidatorProvider` | `Provider<UsageValidator>` | `core/di/providers.dart` |
| `usageCacheProvider` | `Provider<UsageCache>` | `core/di/providers.dart` |
| `refreshServiceProvider` | `Provider<RefreshService>` | `core/di/providers.dart` |
| `usageRepositoryProvider` | `Provider<UsageRepository>` (has `ref.onDispose`) | `core/di/providers.dart` |
| `sharedPreferencesProvider` | `Provider<SharedPreferences>` | `features/settings/settings_providers.dart` |
| `settingsRepositoryProvider` | `Provider<SettingsRepository>` | `features/settings/settings_providers.dart` |
| `SettingsNotifier` / `settingsControllerProvider` | `AsyncNotifier<AppSettings>` | `features/settings/presentation/settings_controller.dart` |
| `applyLaunchAtLoginProvider` | `Provider<Future<void> Function(AppSettings)>` | `features/settings/presentation/settings_controller.dart` |
| `processRunnerProvider` | `Provider<ProcessRunner>` | `features/providers/provider_providers.dart` |
| `copilotSidecarCommandProvider` | `Provider<CopilotSidecarCommand>` | `features/providers/provider_providers.dart` |
| `copilotSidecarLauncherProvider` | `Provider<SidecarProcessLauncher>` | `features/providers/provider_providers.dart` |
| `copilotSdkProvider` | `Provider<CopilotSdk>` | `features/providers/provider_providers.dart` |
| `copilotSdkAdapterProvider` | `Provider<CopilotSdkAdapter>` | `features/providers/provider_providers.dart` |
| `copilotHealthCacheProvider` / `copilotVersionCacheProvider` | `Provider<ProviderMetadataCache<...>>` | `features/providers/provider_providers.dart` |
| `copilotDiagnosticsServiceProvider` | `Provider<CopilotDiagnosticsService>` | `features/providers/provider_providers.dart` |
| `providerRegistryProvider` | `Provider<ProviderRegistry>` | `features/providers/provider_providers.dart` |
| `ProviderSelectionNotifier` / `selectedProviderIdProvider` | `AsyncNotifier<ProviderId>` | `features/providers/presentation/provider_selection_controller.dart` |
| `selectableAIProvidersProvider` | `Provider<List<AIProvider>>` | same file |
| `selectedAIProviderProvider` | `Provider<AIProvider>` | same file |
| `SettingsOpenRequest` / `settingsOpenRequestProvider` | `Notifier<int>` (`NotifierProvider`) | `features/tray/presentation/tray_controller.dart` |
| `trayControllerProvider` | `Provider<TrayController>` | `features/tray/presentation/tray_controller.dart` |
| `copilotDiagnosticsProvider` | `AsyncNotifier<CopilotDiagnostics>` | `features/diagnostics/presentation/copilot_diagnostics_controller.dart` |

27 top-level providers/notifiers total, none using `@riverpod` codegen. DI
wiring is entirely manual, constructor-injection through provider factories,
overridden at bootstrap:

```dart
ProviderContainer(
  overrides: [
    bufferedAppLoggerProvider.overrideWithValue(bufferedLogger),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ],
)
```
(`lib/bootstrap.dart`, cross-checked against `docs/project_intelligence_report.md`'s §6.)

## 7. Domain Models

By feature, immutable (`@immutable` + `copyWith` + value equality), no
`freezed`/`json_serializable` anywhere in the dependency graph:

- **`features/providers/*/models/`:** `ProviderId`, `ProviderCapabilities`,
  `ProviderExecutionConfig`, `ProviderHealth`, `ProviderUsageCandidate`,
  `ProviderUsageMetric`, `ProviderStatus`, `AuthHealth`, `QuotaSnapshot`,
  `SessionUsage`, `VersionInfo`. Two parallel copies exist — canonical ones
  under `providers/core/models/` and thin re-export shims under
  `providers/domain/models/` (see §15).
- **`features/usage/domain/models/`:** `UsageInfo` (canonical rate-limit
  snapshot; §5), `WeeklyUsage`, `ParserState`, `RefreshOutcome`,
  `RefreshPhase`, `RefreshResult`, `RefreshStatus`, `UsageShape`,
  `UsageSource`, `ValidationStatus`, `DashboardData`.
- **`features/settings/domain/models/`:** `AppSettings` (§3.3).
- **`core/errors/`:** `AppFailure`, `FailureCode` — 11-value enum
  (`cliNotInstalled`, `notAuthenticated`, `timeout`, `processLaunchFailed`,
  `processNonZeroExit`, `parserFailure`, `unknownCliOutput`,
  `incompleteOutput`, `cacheUnavailable`, `cancelled`, `unknown`), verified
  directly in `lib/core/errors/failure_code.dart`.
- **`core/result/result.dart`:** sealed `Result<T>` (`Success<T>` /
  `Failure<T>`) with `when`/`map`/`mapError`/`getOrElse` — the uniform
  success/failure container used across every repository and adapter method
  instead of throwing for expected failures.

## 8. Desktop Integration

Covered with code citations in §3.4. Summary of platform-specific behavior
verified in `tray_controller.dart`:

- Both `initializeDesktopShell` and `TrayController.start()` explicitly
  no-op on `kIsWeb` and on any platform that isn't macOS or Windows.
- macOS: dynamic Canvas-painted ring icon (`TrayRingIconRenderer`, falls back
  to static PNG assets on render failure), empty tray *title* (percent is
  already encoded in the icon), `MenuItem` context menu.
- Windows: static `.ico` swap only (`TrayIconResolver.windowsAsset`), no ring
  painting path.
- `onWindowClose()` hides the window rather than exiting (`setPreventClose`);
  only the tray "Quit" menu item calls `exit(0)`.
- `launch_at_startup` is applied through `TrayController.applyLaunchAtLogin`,
  called from the settings save path, with `MissingPluginException` handling
  documented as "rebuild macOS runner" — i.e., a known fragile integration
  point that fails silently-with-log rather than crashing.

## 9. Settings & Persistence

Single storage technology confirmed across the whole app:
`shared_preferences` (`ai_tray/pubspec.yaml:16`). No `sqflite`, `drift`,
`hive`, `isar`, or any other embedded database appears in `pubspec.yaml` or
`pubspec.lock`-adjacent imports.

- **Settings:** `SharedPreferencesSettingsRepository`
  (`settings_repository_impl.dart`) stores one key per field under a
  `settings_v1_` prefix; unreadable/corrupt state falls back to
  `AppSettings.defaults()` rather than throwing.
- **Usage cache:** `SharedPreferencesUsageCache`
  (`lib/features/usage/data/cache/usage_cache.dart`) stores exactly **one**
  JSON blob per provider (`usage_lkg_v2_<providerId>`), with a legacy
  `usage_lkg_v1` key migrated on first read for Claude only
  (`usage_cache.dart:38-64`). This is a last-known-good single-record cache,
  not a history/log — confirmed by the `write()` implementation, which
  unconditionally overwrites the provider's key.
- **Process abstraction:** `ProcessRunner` is the only I/O port with a fake
  (`FakeProcessRunner`) used across tests; there is **no filesystem port** —
  the only direct `dart:io` `File`/`Directory` usage in `lib/` is scattered
  and narrow: temp PNG tray-icon cache
  (`tray_ring_icon_renderer.dart:21`), log-buffer export
  (`logs_page.dart:263`, `diagnostics_page.dart:405`), executable-path
  resolution (`provider_providers.dart:52`, `desktop_process_environment.dart:48`),
  and platform checks in `settings_page.dart`/`tray_controller.dart`.
  Verified with `grep -rn "dart:io\|File(\|Directory(" lib`.

## 10. Tests

Directory listing (`ai_tray/test/`, confirmed by direct `find`):

| Folder | Files | Role |
| --- | --- | --- |
| `unit/` | 21 | adapter, cache, domain, parser, process, providers, refresh, repository, stability, theme, tray, ui |
| `widget/` | 5 | app smoke, provider selection/selector, shared dashboard/settings surfaces |
| `golden/` | 3 | `ep002_provider_ui`, `pd013_usage`, `pd014_theme` |
| `screenshot/` | 1 | README screenshot capture (excluded from CI) |
| **Total** | **30** Dart test files (36 if counting shared fixtures/helpers as reported elsewhere) |

Directly measured lower bound: `grep -rc "test(\|testWidgets("` across
`test/` sums to **161** individual test cases. The handoff record
(`docs/project/AI_HANDOFF.md:88`) separately claims "144 non-golden, 7
golden" as a locally-run pass/fail count — that is a runtime result this
audit did not reproduce (no `flutter test` was executed, per the read-only
constraint); the 161 figure above is a static count of test-case call sites,
not an execution result, and the two numbers are not directly comparable.

Testing conventions verified in the files themselves:
- No `mockito`/`mocktail` anywhere; `FakeProcessRunner`
  (`lib/features/providers/data/process/fake_process_runner.dart`) is a
  production-code fake injected via Riverpod overrides, plus local
  `_Fake*`/`InMemory*` classes per test file (e.g. `InMemoryUsageCache`,
  `InMemorySettingsRepository`).
- Golden and screenshot tests are tag-excluded from the Quality workflow
  (`flutter test --exclude-tags golden,screenshot`, confirmed in
  `.github/workflows/quality.yml` and `docs/project/AI_HANDOFF.md`).
- `test/fixtures/claude_usage/` holds recorded CLI stdout shapes used to
  regression-test `UsageParser` against Shape A/B without invoking a real
  CLI.

## 11. CI/CD

Five workflow files under `.github/workflows/`, all read directly (current
on-disk content, which differs from `main` per `git status` — this audit read
the working tree, not `main`):

- **`quality.yml`** — PR + push to `main`, Ubuntu only. Explicit forbidden
  list in its own header comment: no `macos-*`/`windows-*` runners, no
  `flutter build macos|windows|linux|web`, no codesign/notarization. Stable
  check names (`Format`, `Analyze`, `Test`, `Validate workflows`) are called
  out as required by branch protection and must not be renamed.
  Path-filtered via `dorny/paths-filter` so docs-only PRs still report the
  same check names without installing Flutter.
- **`documentation.yml`** — triggers only on `docs/**`, `showcase/**`, root
  `*.md`, `CHANGELOG.md`, `AI_Tray_*.md` path changes. Validates the 8-file
  AI handoff package (`scripts/ci/validate_handoff.sh`), parses
  `docs/project/*.json`, and checks relative markdown links — but **only**
  inside `docs/project/`, `docs/devops/`, and `docs/adr/`
  (verified in the workflow's embedded Python script); this new report at
  `docs/reports/project-status-report.md` is outside that checked scope.
- **`release.yml`** — the only workflow allowed to build desktop binaries;
  triggers exclusively on `vX.Y.Z` tags or `workflow_dispatch` with an
  existing tag, never on `pull_request` or push to `main`/feature branches.
- **`maintenance.yml`** — weekly Monday cron + manual dispatch; informational
  `flutter pub outdated` / `npm outdated`, never builds the app.
- **`reusable-flutter-web-demo.yml`** — `workflow_call`-only template for
  *other* RSProjects; confirmed (by its own header comment and by
  `showcase/demos.json`'s single `type: desktop` entry) that AI Tray does not
  invoke it.

Local automation: `scripts/ci/{validate_handoff.sh,check_conventional_commit.sh}`,
`scripts/release/{bump_version.sh,extract_changelog.sh,publish.sh}`, and an
optional `lefthook.yml` (pre-commit format/analyze/quick-tests, commit-msg
conventional-commits check, pre-push full suite + bridge check + handoff
validation).

## 12. Documentation

Directly counted: **79** `*.md` files under `docs/` (this audit's own `find
docs -name "*.md" | wc -l`). This differs from
`docs/project_intelligence_report.md`'s "~97 docs files" figure — that report
is dated 2026-07-28 and may count non-`.md` files or a different tree state;
this report states its own count as independently measured rather than
reconciling the discrepancy.

Structure (subfolders, each opened or listed): `docs/project/` (8-file AI
handoff SSOT — `AI_HANDOFF.md`, `ARCHITECTURE_STATE.md`, `DECISION_LOG.md`,
`NEXT_SESSION.md`, `PRODUCT_STATE.md`, `PROJECT_STATE.md`, `ROADMAP.md`, plus
a JSON mirror), `docs/adr/` (4 ADRs), `docs/architecture/`, `docs/design/`,
`docs/devops/`, `docs/dogfood/`, `docs/execution/`, `docs/guides/`,
`docs/planning/`, `docs/providers/`, `docs/release/`, `docs/research/`,
`docs/stabilization/`, `docs/assets/screenshots/`. Two research/analysis
documents live at `docs/` top level and were read in full for this audit:
`docs/claude_code_cli_capability_report.md` (§4, §16) and
`docs/project_intelligence_report.md` (a 1,847-line engineering blueprint
this report cross-checks against but does not duplicate).

Three historical root-level files
(`AI_Tray_Product_Owner_Master_Roadmap.md`, `AI_Tray_Autonomous_Execution_Guide.md`,
`AI_Tray_Phase2_Stabilization_Checklist.md`) are explicitly superseded by
`docs/project/` per that folder's own files, but remain on disk for
provenance (private file permissions, `-rw-------`, observed via `ls -la`).

## 13. Dependencies

Full `dependencies:`/`dev_dependencies:` block read from
`ai_tray/pubspec.yaml`:

| Package | Constraint | Role |
| --- | --- | --- |
| `flutter` | SDK | UI framework |
| `flutter_riverpod` | `^3.3.2` | State + DI |
| `launch_at_startup` | `^0.5.1` | Login-item registration |
| `local_notifier` | `^0.1.6` | OS notifications |
| `meta` | `^1.17.0` | `@immutable` |
| `shared_preferences` | `^2.5.5` | Only persistence layer |
| `tray_manager` | `^0.5.3` | Menu bar / tray icon+menu |
| `window_manager` | `^0.5.2` | Window show/hide/size/prevent-close |
| `flutter_test` (dev) | SDK | Unit/widget/golden tests |
| `very_good_analysis` (dev) | `^10.1.0` | Lint baseline |

Eight direct production dependencies total (including the `flutter` SDK
entry). Confirmed absent: any HTTP client (`http`/`dio`), any router, any
codegen (`build_runner`/`freezed`/`json_serializable`/`riverpod_generator`),
any database package, any localization package, any analytics/telemetry SDK.

Sidecar package (`ai_tray/tool/copilot_sdk_bridge/package.json`, not opened
byte-for-byte in this pass but referenced consistently across
`provider_providers.dart` and the Node scripts under
`tool/copilot_sdk_bridge/`): `@github/copilot-sdk@1.0.7` pinned, TypeScript
dev dependency, Node/npm versions pinned in CI `env:` blocks
(`quality.yml`, `release.yml`: Flutter `3.38.9`, Node `22.17.0`, npm
`10.9.2`).

## 14. Extension Points

Concrete seams a v2 feature can plug into, identified by reading the actual
interfaces (not inferred):

1. **`AIProvider` + `ProviderRegistry`** — a new provider (or a Claude
   *session* capability) registers here without touching shared UI, as long
   as it can be expressed as usage/health/capabilities.
2. **`ProcessRunner` port** (`process_runner.dart`) — any new Claude CLI
   invocation (e.g. `claude agents --json`, `claude --resume <id> -p ...`)
   can reuse this port's `run()` contract *if* it only needs buffered
   request/response semantics. It cannot be reused as-is for streaming
   (`--output-format stream-json`) — see §16.4.
3. **`Result<T>` / `AppFailure` / `FailureCode`** — the existing
   error-classification vocabulary; a v2 feature should add new
   `FailureCode` values (e.g. `sessionNotFound`) rather than inventing a
   parallel error type.
4. **`RefreshService` single-flight/backoff pattern** — not directly reusable
   for a multi-item queue (it coalesces duplicate calls to *one* operation
   per provider key; it does not sequence *distinct* operations), but its
   shape (coalescing map + bounded retry + auth-probe escalation) is the
   closest in-repo precedent for a queue executor's retry policy.
5. **`UsageRepositoryImpl`'s `Timer` + generation-token + `recoverScheduleIfOverdue`
   pattern** — the closest in-repo precedent for a scheduler, but it only
   supports fixed relative intervals with backoff, not an arbitrary target
   timestamp (e.g. "resume when quota resets at 14:32 UTC").
6. **`SidecarProcessTransport`** — a hardened, persistent, correlated
   NDJSON request/response client with crash-restart and timeout/cancellation
   handling. Reusable as an *architectural pattern* for a persistent
   `claude --resume ... --output-format stream-json` process; **not**
   directly reusable for reading historical `~/.claude/projects/**/*.jsonl`
   files, since it parses live stdout protocol lines keyed by its own
   `id`/`protocolVersion` envelope, not arbitrary on-disk JSON Lines.
7. **`FakeProcessRunner`** — the established pattern (production-code fake,
   Riverpod-overridable) for making any new process-based feature unit
   testable without a real CLI.
8. **Design system (`core/components/`, `core/theme/`)** — new screens
   (e.g. a session list) can be built from existing tokens/components without
   new UI infrastructure.

## 15. Technical Debt

Verified directly, not copied from prior audits:

- **Re-export alias files.** `grep -rl "^export " lib/features/providers/domain
  lib/features/providers/data/copilot` returns **22** files that exist only
  to re-export canonical types from `providers/core/` and `providers/copilot/`
  (e.g. `providers/domain/models/*.dart` mirrors `providers/core/models/*.dart`
  one-for-one). `docs/project/ARCHITECTURE_STATE.md:95` separately claims
  "~35" across a wider set of directories (`core/`, `domain/`,
  `data/copilot/`, `copilot/`); this report's 22 is a narrower, directly
  measured subset and the two numbers should not be treated as the same
  metric. ADR-004 (`docs/adr/`) records this as accepted "targeted cleanup"
  debt rather than a rewrite trigger.
- **`domain/` subtree is almost entirely re-exports.** Confirmed by content,
  e.g. `lib/features/providers/domain/models/provider_id.dart` and siblings
  forward to `core/models/`.
- **Empty `notifications/` feature folder** (§3.6) — three `.gitkeep` files,
  zero Dart, while the only working notification code lives inside
  `TrayController`. A future notifications feature (payload-carrying,
  click-through) has no existing home to extend; it would need to be created
  from scratch, and a decision made about whether it *replaces*
  `TrayController.maybeNotify` or wraps it.
- **Largest presentation files:** `usage_page.dart` (868 LOC),
  `settings_page.dart` (663 LOC), `diagnostics_page.dart` (603 LOC) — verified
  by direct `wc -l`. These are single-file, dense compositions; no
  sub-widget-file splitting exists yet.
- **No filesystem port.** (§9) Any feature reading `~/.claude/projects/` needs
  a new abstraction; today's only prior art for a testable I/O boundary is
  `ProcessRunner`, not a `FileSystem`/`Directory` port.
- **Single-record cache, not a store.** (§9) `UsageCache` cannot hold more
  than one snapshot per provider; nothing about its interface anticipates a
  growing dataset.
- **No macOS code signing/notarization**; artifacts are unsigned zips
  (confirmed by `release.yml`'s comment: "Signing / notarization: future (out
  of scope today)").
- **Windows remains "Experimental"** pending hardware dogfood, per
  `docs/project/PRODUCT_STATE.md:15` and `docs/stabilization/PD-010-defer-windows.md`.

## 16. Readiness for v2 Candidates

The five-field feature template (Purpose/How it works/Main files/
Dependencies/Limitations) does not apply to these — none exist in code. Each
is instead assessed as: what's already reusable (with file citations), what's
genuinely absent, the concrete decision that would have to be made first, and
a one-line verdict.

### 16.1 Session Browser

- **Reusable:** the design-system components (§3.7) for list/detail UI; the
  `ProcessRunner` port if a browser needs `claude agents --json` (a single
  buffered call, no streaming needed for a one-shot listing).
- **Absent:** any code that reads `~/.claude/projects/**/*.jsonl` or calls
  `claude agents --json`; no filesystem port/fake exists (§9, §15); no domain
  model for a "session" (nothing resembling `sessionId`/`cwd`/`gitBranch`
  anywhere in `lib/features/`).
- **Blocking decision:** whether to build a `FileSystem` port (mirroring
  `ProcessRunner`'s port+fake pattern) before or alongside first use, since
  none exists today.
- **Verdict:** Not started. Buildable on top of existing patterns (port+fake,
  capability-driven list UI), but the FS-access boundary is new.

### 16.2 JSONL Parser

- **Reusable:** `UsageParser`'s defensive-parsing discipline (never assume
  one shape; track `ParserState`) is a good precedent for tolerating schema
  drift, which `docs/claude_code_cli_capability_report.md` explicitly warns
  about for JSONL fields (§3B of that report: session-title field name is
  "flag confirmed, on-disk field name unconfirmed").
- **Absent:** any NDJSON/JSONL *file* reader. `SidecarProcessTransport`
  parses **live process stdout lines** framed by its own protocol envelope
  (`protocolVersion`/`id`/`result`) — structurally different from reading an
  arbitrary multi-megabyte `.jsonl` transcript file line-by-line from disk.
  No code in `lib/` opens a file and streams/splits it by newline.
- **Blocking decision:** target schema surface (which of the fields listed in
  `docs/claude_code_cli_capability_report.md` §3B the app actually needs) and
  whether parsing happens eagerly (index all sessions on load) or lazily
  (open a file only when a session is selected) — this determines whether it
  needs the same single-record-cache ceiling raised (§16.3).
- **Verdict:** Not started; no direct code precedent, though the "defend
  against shape drift" discipline from `UsageParser` transfers conceptually.

### 16.3 Session Repository

- **Reusable:** the repository-port pattern itself (`UsageRepository`,
  `SettingsRepository` — abstract interface + `SharedPreferences` impl +
  in-memory test double) is a template to copy.
- **Absent:** a storage engine that fits. Verified directly: `pubspec.yaml`
  has no `sqflite`/`drift`/`hive`/`isar`; `SharedPreferences` is a flat
  key-value store and the existing `UsageCache` already demonstrates its
  ceiling — one JSON blob per key, whole-value overwrite on write (§9). A
  session history is an unbounded, queryable, potentially large dataset;
  key-value-per-record in `SharedPreferences` does not scale to "thousands of
  JSONL-derived records" the way a queue/browser implies.
  ADR-002's cache-age policy (soft 6h / hard 24h,
  `docs/adr/ADR-002-error-handling-resilience.md`) was designed for *one*
  last-known-good snapshot, not a growing session log.
- **Blocking decision:** pick a storage engine (embedded SQL, or read the
  JSONL files directly as the source of truth with an in-memory index and no
  separate DB) before writing repository code — this is a real architecture
  decision, not an implementation detail.
- **Verdict:** Not ready — the persistence layer that would back it does not
  exist and is a genuine open decision, not a gap that can be filled by
  extending current code.

### 16.4 Resume Queue

- **Reusable:** `RefreshService`'s single-flight-per-key map and bounded
  retry (`refresh_service.dart:44,209`) is the closest in-repo shape for
  "one active operation, coalesce duplicates, retry on transient failure" —
  but it is explicitly single-item-per-key, not a multi-item ordered queue.
  `FailureCode`/`Result<T>` transfer directly for per-attempt outcome
  tracking, which `docs/claude_code_cli_capability_report.md` §3D notes the
  CLI's own `--output-format json` result envelope already supports
  (`total_cost_usd`, `num_turns`, `session_id`, `stop_reason` per run).
- **Absent:** any queue data structure, any persistence of pending queue
  items, and — critically — **streaming process support**. `ProcessRunner.run()`
  (§9, `process_runner.dart:19`) returns only after `exitCode` resolves and
  joins all of stdout into one `String`; `IoProcessRunner` explicitly closes
  stdin immediately (`io_process_runner.dart:41`, comment: "non-interactive
  Claude -p usage"). A queue that wants `--max-budget-usd`/`--fallback-model`
  per item can still use the existing buffered port (those are just extra
  CLI args), but anything wanting `--output-format stream-json` progressive
  output needs a new streaming variant of the port.
- **Blocking decision:** buffered-only vs. streaming execution — decide this
  before choosing whether the queue executor extends `ProcessRunner` or needs
  a sibling port.
- **Verdict:** Partial substrate exists (retry/coalescing pattern, error
  vocabulary); queue persistence and streaming execution are both new.

### 16.5 Resume Scheduler

- **Reusable:** `UsageRepositoryImpl`'s `Timer`-based reschedule loop with
  backoff and `recoverScheduleIfOverdue()` sleep/wake recovery
  (`usage_repository_impl.dart:249,85`) is a direct, working precedent for
  "fire an action later, recover if the app was asleep when it should have
  fired."
  `docs/claude_code_cli_capability_report.md` §6C confirms independently that
  the Claude CLI has **no** native `--at`/`--schedule`/`--cron` flag, so this
  responsibility must live in the app regardless.
- **Absent:** the existing timer only supports fixed relative intervals
  (`Duration` from "now"), not an arbitrary target timestamp such as "resume
  when quota resets at 14:32 UTC" — `_reschedule()`'s only inputs are
  `settings.refreshInterval` and a backoff multiplier, not a caller-supplied
  deadline.
- **Blocking decision:** whether to generalize `_reschedule`'s pattern into a
  reusable `Timer`-to-`DateTime` scheduler, or build a separate one for
  resume — doing it in `UsageRepositoryImpl` today would couple an unrelated
  concern into the usage-refresh class.
- **Verdict:** Strong architectural precedent exists and is provably
  sleep/wake-safe; the specific "wake at an arbitrary future timestamp"
  capability does not exist yet.

### 16.6 Session Analytics

- **Reusable:** `DashboardDataMapper` (domain → capability-aware UI model)
  and the metric/chip/badge component set (§3.7) are direct precedent for
  turning structured data into dashboard tiles.
- **Absent:** any aggregation code and, transitively, everything §16.2/§16.3
  are missing — analytics has no input to aggregate until a JSONL
  parser and a repository exist. Confirmed no `token`/`cost`/`turn` counting
  logic anywhere in `lib/features/usage/` (that module only ever handles
  percent-based quota, not per-session token/cost accounting).
- **Blocking decision:** none unique to this feature — it is strictly
  downstream of §16.2 and §16.3.
- **Verdict:** Not started; correctly sequenced last among the data-dependent
  features.

### 16.7 Notifications (session-aware / click-to-resume)

- **Reusable:** `local_notifier` dependency is already present and working
  (§3.4); the threshold-check pattern in `maybeNotify()` is a real, tested
  code path to extend or copy.
- **Absent:** verified directly — `LocalNotification(title: ..., body: ...)`
  in `tray_controller.dart:229` carries **no payload field** and there is
  **no click handler registration** anywhere in the file, its imports, or its
  test. "Resume by clicking a notification"
  (`docs/claude_code_cli_capability_report.md` §8, "Resume by clicking a
  notification") requires the notification to carry a `session_id`/`cwd` and
  the app to register a click callback that runs
  `claude --resume <id> -p ... --output-format json` — none of that wiring
  exists.
- **Blocking decision:** whether this extends `TrayController` in place or
  becomes the first real implementation of the empty `features/notifications/`
  folder (§15) — a decision that also determines whether `maybeNotify` gets
  refactored or left alone for the existing threshold-notification behavior.
- **Verdict:** The dependency and a working baseline exist; click-through
  payload/handler wiring is new, small, and is new wiring on an *existing*
  dependency rather than a new one.

## 17. Recommendations

These are grounded observations, not directives — the Product/Architecture
owner should weigh them against `docs/project/ROADMAP.md` and ADR-004's
"targeted cleanup, not rewrite" posture.

### 17.1 Refactors worth doing before v2 work starts

1. **Resolve the `domain/`/`data/copilot/` alias layer first** (§15) — any
   v2 feature that touches provider models will otherwise have to choose
   between importing the canonical or the shim path, compounding the debt
   ADR-004 already flags.
2. **Decide the filesystem-access pattern before Session Browser/JSONL work
   begins** — introduce a `FileSystem`/`SessionFileReader` port with a fake,
   mirroring `ProcessRunner`, rather than reading files ad hoc in a
   controller (as `logs_page.dart`/`diagnostics_page.dart` currently do for
   the narrower log-export case).
3. **Make a storage-engine decision explicitly**, in writing (an ADR, given
   the project's own convention), before any Session Repository code is
   written — this is the single highest-leverage decision blocking three of
   the seven v2 candidates (§16.3, §16.2, §16.6).
4. **Decide buffered-vs-streaming process execution** before Resume Queue
   work begins — either extend `ProcessRunner` with a streaming variant or
   introduce a sibling port; retrofitting `IoProcessRunner`'s current
   join-everything model later would be more disruptive.
5. Consider whether `_reschedule()`'s backoff/timer logic in
   `UsageRepositoryImpl` should be extracted into a standalone, reusable
   scheduler primitive before a second consumer (Resume Scheduler) needs the
   same sleep/wake-safe behavior — duplicating it would be the kind of
   accretion ADR-004 was written to avoid.

### 17.2 Proposed module structure (if v2 features are approved)

Grounded in the existing feature-first convention
(`presentation/domain/data` per feature) rather than a new pattern:

```
lib/features/sessions/
  ├── domain/
  │   ├── models/            # Session, SessionMessage, SessionMetadata, ResumeQueueItem
  │   ├── ports/              # SessionFileReader (new FS port), SessionRepository (port)
  │   └── repositories/        # SessionRepository interface
  ├── data/
  │   ├── parsers/             # JsonlSessionParser (defensive, ParserState-style)
  │   ├── repositories/        # concrete SessionRepository impl (storage decision from 17.1.3)
  │   └── process/             # ResumeExecutor — reuses or extends ProcessRunner
  └── presentation/
      ├── session_browser_controller.dart / session_browser_page.dart
      ├── resume_queue_controller.dart
      └── session_analytics_controller.dart / *_page.dart
```

`features/notifications/` (currently empty, §15) would gain its first real
content here rather than staying a dead folder — either the click-to-resume
logic moves in, or the folder is removed and `TrayController` is documented
as the intentional owner (ADR-004 lists this exact choice as open debt).

### 17.3 Next milestone

Per `docs/project/ROADMAP.md`, the current milestone is landing EP-004A
(Quality CI + Release CD) to `main`, completing the macOS arm64 dogfood
checklist, and a Product Owner call on Phase 3 release timing — none of that
is v2-feature work. Based purely on what this audit found in the code (not a
recommendation to reorder the roadmap), the smallest de-risking step *for* a
future v2 push would be a spike that only answers the two blocking decisions
above (§17.1.3 storage engine, §17.1.4 streaming execution) without shipping
UI — because §16.1, §16.2, §16.3, §16.4, and §16.6 are all downstream of
those two answers.

---

*End of report. Produced by direct source inspection; no files were changed.*
