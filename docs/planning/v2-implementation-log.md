# AI Tray — v2 Implementation Log

**Purpose:** Running, incremental record of implementation progress against
the locked `docs/planning/v2-vision-and-roadmap.md`. This file is updated
story-by-story as work completes. It does not modify the roadmap, the
architecture, or any ADR — per the roadmap's own §18 ("update documentation
incrementally... instead of rewriting the roadmap") and its "Lock" section
(architectural changes happen only through a new ADR). Anything recorded
here as a "discovery" or "deviation" is an implementation-level detail
within the roadmap's existing scope, not a change to it.

**Format:** one entry per completed Feature, in roadmap order. Each entry
states what shipped, any deviation from the roadmap's description, any
discovery worth carrying into a later story, verification results, and
whether an ADR was needed (expected answer: no, unless a locked decision was
genuinely challenged).

---

## Milestone 1 — Session Visibility (read-only)

### Epic 1.1 — Session Data Access

#### Feature 1.1.1 — Session File System Port — ✅ Complete

**Stories completed:** Define `SessionFileSystem` port + fake · Implement
production FS reader.

**Files added:**
- `lib/features/sessions/domain/ports/session_file_system.dart` — port +
  `SessionFileRef`/`SessionFileStat`
- `lib/features/sessions/data/fs/io_session_file_system.dart` — production
  `dart:io` implementation + `defaultClaudeProjectsRoot()`
- `lib/features/sessions/data/fs/fake_session_file_system.dart` — in-memory
  fake (`addFile`/`removeFile`)
- `lib/features/sessions/data/fs/claude_project_path_decoder.dart` — reverses
  the `/`→`-` project-path sanitization only when the result resolves to a
  real directory; returns `null` rather than guessing
- `test/unit/sessions/{session_file_ref_test.dart, claude_project_path_decoder_test.dart, fake_session_file_system_test.dart, io_session_file_system_test.dart}`

**Files modified (expected fallout, not scope creep):**
- `lib/core/errors/failure_code.dart` — added `sessionNotFound`, already
  named and justified in the locked domain model (§8)
- `lib/features/usage/presentation/widgets/tray_empty_state.dart` — see
  "Regression" below

**Deviations from the roadmap:** None in module structure or domain model —
matches §7/§8 exactly. `ClaudeProjectPathDecoder` is an implementation detail
not named in §7's tree diagram (§7 only committed to the port + fake +
production reader); it exists to satisfy the "Implement production FS
reader" story's own stated risk ("path-decoding edge cases... needs care").

**Implementation discoveries for later milestones:**
- `File.stat()`/`FileSystemEntity.stat()` does **not** throw for a missing
  file — it returns a `FileStat` with `type == FileSystemEntityType.notFound`.
  This is the clean, non-exceptional path used to produce `sessionNotFound`,
  and is worth remembering for M2's stale-`cwd` check (design principle 2) —
  the same non-throwing pattern likely applies to `Directory.stat()`/
  `existsSync()` there too.
- `Uri.file(path).pathSegments` / manual regex splitting on `[\\/]` correctly
  parses both POSIX and Windows-style paths without adding `package:path` —
  confirms §6's "no new Flutter package dependency" claim holds in practice,
  not just in principle.
- `FailureCode` is a single cross-cutting enum with at least one exhaustive
  `switch` in v1 code far from anything session-related. **A `flutter
  analyze` scoped to only the files touched in the current story is not
  sufficient** to catch fallout from adding a new enum value — the full
  `flutter analyze`/`flutter test` run against the whole `lib/` tree is
  mandatory before a story extending `FailureCode` is considered done. (I
  grepped `lib/` for every other exhaustive switch over `FailureCode` after
  this and found none remaining — worth re-confirming when `M2` adds
  `workingDirectoryMissing` and `budgetCapRequired`.)

**Regression found and fixed:** Adding `FailureCode.sessionNotFound` broke
the exhaustive `switch (failure.code)` in `tray_empty_state.dart` (a v1
widget, unrelated to sessions) — a compile error, not a runtime bug. This is
**expected fallout of extending a shared enum**, exactly what the roadmap's
own domain model section anticipated ("extending the existing 11-value enum,
not replacing it") — **not an architectural issue**, so the "stop, document,
propose an ADR" process was not triggered. Fixed directly by bucketing
`sessionNotFound` with `unknown` in that switch, since a Session Browser
failure code is structurally unreachable through the usage-refresh path that
widget serves.

**ADR changes required:** None. No locked architectural decision (§16,
ADR-005..010) was challenged or changed.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on all new and modified files.

**Test results:**
- New: 24/24 passing (`test/unit/sessions/*`).
- Full suite (`flutter test --exclude-tags golden,screenshot`): **166
  passed, 5 failed** — all 5 pre-existing and unrelated; see below.

**Known unrelated failures (recorded once here so they are not
re-discovered or re-investigated by a later story):**

| Symptom | Affected files | Root cause |
| --- | --- | --- |
| `ListTile background color or ink splashes may be invisible` (Material-ancestor assertion) | `test/widget/about_settings_test.dart`, `test/widget/shared_surfaces_settings_test.dart` | Flutter SDK version drift |
| `Asset 'shaders/ink_sparkle.frag' manifest could not be decoded... Unsupported runtime stages format version` | `test/widget/ep002_ui_quality_test.dart` (2 cases), `test/widget/provider_selection_usage_test.dart`, `test/unit/ui/shared_surfaces_empty_logs_test.dart` | Flutter engine/shader-bundle version drift |

Root cause for both: this dev environment runs Flutter **3.44.8**; the
project is pinned to **3.38.9** (`docs/project/ARCHITECTURE_STATE.md`,
CI `env:` blocks) — a gap the v1 intelligence report already named as an
improvement opportunity ("Consider FVM... so local Flutter matches CI
3.38.9 exactly"). Confirmed unrelated to sessions work: none of the 5
affected files reference `sessions` (checked directly). Also confirmed this
working tree already contains substantial unrelated, uncommitted
in-progress work (a release-history feature, CI script reorganization,
workflow edits) that predates this implementation effort and was not
touched. **Action for v2 work: none** — do not attempt to fix these inside
session-related stories; they require either pinning local Flutter to
3.38.9 or a v1-scoped fix outside this roadmap's remit.

---

#### Feature 1.1.2 — JSONL Session Parser — ✅ Complete

**Stories completed:** Index-pass parser · Full-transcript lazy parser ·
Fixture-based resilience test suite.

**Files added:**
- `lib/features/sessions/domain/models/session_summary.dart`
- `lib/features/sessions/domain/models/claude_session.dart`
- `lib/features/sessions/domain/models/session_token_totals.dart` (small
  value object grouping the four `message.usage` counters — not itemized by
  name in §8, but needed to give `ClaudeSession.tokenTotals` a shape;
  consistent with §8's field list, not a deviation from it)
- `lib/features/sessions/data/parsers/jsonl_session_parser.dart`
- `test/fixtures/claude_sessions/{valid_multi_message,empty,malformed_middle_line,truncated_mid_turn}.jsonl`
  — the exact four fixture types §17 names
- `test/unit/sessions/{jsonl_session_parser_test.dart, jsonl_session_parser_fixtures_test.dart}`

**Files modified:** None outside `lib/features/sessions/` and tests/fixtures
— no cross-cutting types were touched this time (no new `FailureCode`
values were needed for this feature).

**Deviations from the roadmap:** None in shape or intent. One
implementation-level refinement worth recording as a deviation from my own
initial assumption, not from the locked doc: I originally expected to add a
`readTail(file, {maxBytes})` method to the `SessionFileSystem` port so the
index pass could cheaply read a file's last line. It turned out
unnecessary — `SessionSummary.lastActivityAt`'s own locked definition
("file mtime **or** last line's timestamp — cheapest available signal")
explicitly permits pure file mtime, which Feature 1.1.1's `stat()` already
provides with zero content reads. The index pass (`summarize()`) therefore
reads **no transcript content at all** — cheaper than even my own §10
prose implied, and the port was correctly left unchanged.

**Implementation discoveries for later milestones:**
- The transcript's own `cwd` field (confirmed present on every JSONL
  record, capability report §3B) gives the **detail pass** an authoritative,
  undecoded project path — `ClaudeSession.projectPath` never needs
  `ClaudeProjectPathDecoder`'s best-effort guessing at all. The decoder
  remains necessary only for `SessionSummary` (the index pass, which by
  design never reads content). Worth remembering when Feature 1.2.1/1.2.2
  wire the repository: prefer `ClaudeSession.projectPath` over
  `SessionSummary.projectPath` wherever both are available, since one is
  authoritative and the other is a best-effort fallback.
- `messageCount` is honestly asymmetric between the two models:
  `SessionSummary.messageCount` is a size-based **estimate** (index pass
  reads no content); `ClaudeSession.messageCount` is an accurate count (the
  detail pass reads everything). Both are named `messageCount` per §8's
  literal field name; the precision difference is documented on each field,
  not signaled by a different name — worth keeping in mind so a future UI
  story doesn't assume both are equally precise.
- `isComplete` semantics are deliberately asymmetric by position in the
  file: a malformed line **anywhere but the last** is skipped and does not
  affect `isComplete`; only the transcript's **final** line failing to
  parse sets `isComplete: false`. This distinguishes an ordinary
  killed-mid-write transcript (design principle 4) from an unrelated,
  isolated bad line elsewhere in an otherwise normally-closed file. Encoded
  as regression tests in both new test files — not just described here.
- `title` is hard-coded to always be `null` — no field name was guessed for
  `-n`/`--name`, per §8/design principle 3. If a future session inspects a
  real, named session's JSONL file and confirms the on-disk field name,
  that is the trigger to populate it; until then this is intentionally
  dead weight, not a bug.
- Re-confirmed the Feature 1.1.1 finding: no exhaustive `switch` over
  `FailureCode` was affected this time (none were added), but the discovery
  that a full-suite run is mandatory (not just a scoped `analyze`) still
  applied in spirit — full suite was run again below.
- Noted, not acted on: the locked roadmap (§21, Epic 1.1/1.2) has no
  explicit story for assembling `SessionRepository` itself (§9's port) —
  it is implied to happen inside Feature 1.2.1 ("`SessionBrowserController`
  + list UI", dependencies: "Epic 1.1 complete"). Flagging this now so it
  isn't mistaken for a missed story when Epic 1.2 starts — it is a
  roadmap granularity gap, not evidence of drift, and does not need an ADR.

**Regression found:** None this time — `flutter analyze --fatal-infos`
surfaced only routine line-length/adjacent-string lint issues in new test
code, all fixed directly (no production-code fallout).

**ADR changes required:** None.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on all new files.

**Test results:**
- New: 40/40 passing (`test/unit/sessions/*`, including the two new parser
  test files).
- Full suite (`flutter test --exclude-tags golden,screenshot`): **185
  passed, 2 failed** — both are the same pre-existing `ListTile`
  Material-ancestor failures already recorded under Feature 1.1.1 (same two
  files: `about_settings_test.dart`, `shared_surfaces_settings_test.dart`).
  The two `ink_sparkle.frag` shader-loading failures seen previously did
  **not** recur this run — consistent with known Flutter shader-warmup
  flakiness (order-dependent shader compilation caching within one test
  process), not a real fix or a new regression. No new failure signatures
  appeared; nothing further to investigate.

---

#### Feature 1.1.3 — Live Session Enrichment — ✅ Complete

**Stories completed:** `agents --json --all` adapter method · Merge
liveness onto the summary list.

**Files added:**
- `lib/features/sessions/data/process/claude_session_service.dart` —
  `ClaudeSessionService.listLiveSessions()`, wraps the existing
  `ProcessRunner` port exactly the way `ClaudeCliAdapter` does (same
  constructor shape, same binary-resolution helper, same `Result`-based
  error mapping) — no second CLI execution path introduced
- `lib/features/sessions/data/process/session_liveness_merger.dart` — a
  standalone, pure `mergeSessionLiveness(summaries, liveness)` function
- `test/unit/sessions/{claude_session_service_test.dart, session_liveness_merger_test.dart}`

**Files modified:** None outside `lib/features/sessions/` and tests — no
new `FailureCode` value was needed; every failure mode maps onto codes that
already exist (`processNonZeroExit`, `unknownCliOutput`, `timeout`,
`processLaunchFailed`), the same set `ClaudeCliAdapter` already uses.

**Deviations from the roadmap:** None in shape or intent, but one
placement decision worth recording since the roadmap doesn't name a file
for it: the second story ("merge liveness onto the summary list") is
implemented as a standalone pure function
(`session_liveness_merger.dart`), not as a method on
`SessionBrowserController` — that controller doesn't exist yet (it's
Feature 1.2.1, Epic 1.2, not started). This mirrors the same roadmap
granularity gap Feature 1.1.2 already flagged (no explicit story assembles
`SessionRepository` either) — merging is implemented and fully tested now,
at the layer that exists today, and `SessionBrowserController` calls it
directly, unchanged, once Epic 1.2 begins.

**Implementation discoveries for later milestones:**
- The capability report's caveat held exactly as described: `agents --json
  --all`'s populated-result field names are unconfirmed. `listLiveSessions()`
  handles this by trying three candidate id keys per entry (`sessionId`,
  `session_id`, `id`) and silently skipping any entry with none of them,
  rather than guessing a single name. Worth revisiting once a real
  populated response is observed on a dev machine with live sessions —
  confirming the actual key would let a later story drop the multi-key
  fallback, but there is no reason to block on that now.
- `mergeSessionLiveness`'s success path treats the CLI's returned id set as
  authoritative: matched ids get `isLive: true`, everything else gets
  `isLive: false`. Only a *failed* liveness `Result` leaves `isLive`
  untouched (`null`). This is a small interpretive choice the roadmap's
  §8 wording ("`null` when `agents --json` didn't confirm either way")
  didn't spell out for the success-but-partial case — recorded here so a
  later story doesn't second-guess it as a bug.

**Regression found:** None — no cross-cutting types were touched.

**ADR changes required:** None. No locked architectural decision (ADR-005,
ADR-009) was challenged; §6.1/§9's Claude-only, enrichment-only design
was implemented exactly as specified.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on `lib/features/sessions/` and `test/unit/sessions/`.

**Test results:**
- New: 15/15 passing (`claude_session_service_test.dart`: 10 cases
  covering successful enrichment, empty result, malformed JSON, non-list
  JSON shape, unknown/unrecognized entry fields, timeout, process launch
  failure, non-zero exit, custom binary path, and the exact argument list;
  `session_liveness_merger_test.dart`: 5 cases covering successful merge,
  failed-liveness passthrough, purity/no-mutation, determinism, and the
  empty-list edge case).
- Full suite (`flutter test --exclude-tags golden,screenshot`): **167
  passed, 11 failed** — all 11 are pre-existing compile errors in
  unrelated, uncommitted personalization/theme work already sitting in
  this working tree (not touched by this story): `lib/theme/
  personalization_controller.dart` (new, untracked) calls
  `AsyncValue.valueOrNull`, which this project's pinned `riverpod` version
  doesn't expose; `lib/features/settings/data/repositories/
  settings_repository_impl.dart` (modified, uncommitted) references a
  `Unit` type that isn't imported; `about_settings_test.dart` references an
  undefined `AppTheme.dark()`. Confirmed unrelated to sessions: grepped the
  full test-run log for `sessions` and every session test (Feature 1.1.1,
  1.1.2, and this feature's new tests) passed; none of the 11 failing
  files are under `features/sessions/` or reference it. This is the same
  "unrelated, uncommitted in-progress work predates this implementation
  effort" situation Feature 1.1.1 already documented — action for v2 work:
  none, do not fix it inside a sessions story.

---

## Milestone 1 — Session Visibility (read-only)

### Epic 1.2 — Session Browser UI

#### Feature 1.2.1 — Session List Page — ✅ Complete

**Stories completed:** `SessionBrowserController` + list UI · Search/filter
by project path.

**Files added:**
- `lib/features/sessions/domain/repositories/session_repository.dart` —
  port with a single `listSessions()` method. `readSession()`/
  `refreshIndex()` from §9's port sketch are deliberately **not** added
  yet — nothing in this feature needs them (Feature 1.2.2's detail view
  does), so building them now would be untested, unused surface. This
  fills the gap Feature 1.1.2's log entry flagged: "the locked roadmap has
  no explicit story for assembling `SessionRepository` itself... implied
  to happen inside Feature 1.2.1."
- `lib/features/sessions/data/repositories/file_system_session_repository.dart`
  — composes Feature 1.1.1's `SessionFileSystem`, Feature 1.1.2's
  `JsonlSessionParser.summarize()`, and Feature 1.1.3's
  `ClaudeSessionService`/`mergeSessionLiveness` — no new filesystem or CLI
  logic
- `lib/features/sessions/data/repositories/fake_session_repository.dart` —
  in-memory test double (mirrors `FakeProcessRunner`/
  `FakeSessionFileSystem`'s configurable-response shape), with a
  `holdNextResponse()`/`releaseResponse()` gate for deterministic
  loading-state widget tests
- `lib/features/sessions/session_providers.dart` — DI wiring
  (`sessionFileSystemProvider`, `claudeSessionServiceProvider`,
  `sessionRepositoryProvider`), same shape as `settings_providers.dart`;
  reuses the existing `processRunnerProvider` singleton rather than
  constructing a second one
- `lib/features/sessions/browser/presentation/session_browser_controller.dart`
  — `AsyncNotifier<List<SessionSummary>>`, same shape as
  `SettingsNotifier`/`ProviderSelectionNotifier`
- `lib/features/sessions/browser/presentation/session_list_filter.dart` —
  standalone pure `filterSessionsByProjectPath()` function (not a
  controller method), so filtering is unit-testable in isolation and
  never mutates or discards the controller's loaded list
- `lib/features/sessions/browser/presentation/session_browser_page.dart` —
  list page reusing `SectionCard` (`core/components/section_chrome.dart`)
  for tiles and `StatusBadge`/`TrayStatusKind.live`
  (`core/components/status_badge.dart`) for the live indicator; empty
  state mirrors `tray_empty_state.dart`'s visual pattern (Semantics +
  title/body via `type.emptyTitle`/`type.bodySmall`) rather than
  instantiating that widget directly, since its constructor is
  usage/provider-specific and doesn't fit a session list
- `test/unit/sessions/{session_list_filter_test.dart, file_system_session_repository_test.dart, session_browser_controller_test.dart}`
- `test/widget/session_browser_page_test.dart`

**Files modified:**
- `lib/features/sessions/data/fs/fake_session_file_system.dart` — added a
  `listFailure` field so tests can simulate a genuine enumeration error
  (permission denied / I/O error), distinct from the already-covered "no
  sessions yet" empty-success case; Feature 1.1.1's fake had no seam for
  this because nothing needed it until the repository's error-propagation
  path did
- `test/unit/sessions/fake_session_file_system_test.dart` — one new test
  for the above
- `lib/features/usage/presentation/usage_page.dart` — added a "Sessions"
  toolbar `IconButton` (`Icons.history_outlined`) next to Diagnostics,
  pushing `SessionBrowserPage` via the same bare
  `Navigator.push(MaterialPageRoute)` pattern already used for
  Settings/Diagnostics/Logs. Not named as a story in the roadmap, but
  without it the page is unreachable dead code; this is the minimal,
  pattern-following wiring, not a new navigation abstraction.
- `lib/core/di/providers.dart` — exports `sessionRepositoryProvider` and
  `sessionBrowserControllerProvider`, mirroring how
  `selectedProviderIdProvider` (an `AsyncNotifierProvider`, not just a
  plain repository provider) is already re-exported from this barrel.

**Deviations from the roadmap:** None in shape or intent. As anticipated
by Feature 1.1.2's log entry, this feature is where `SessionRepository`
itself got built — the roadmap named the port's eventual shape (§9:
`listSessions()`, `readSession(id)`, `refreshIndex()`) but not which story
assembles it; building only `listSessions()` now (see above) is a scope
decision, not a deviation, since `readSession`/`refreshIndex` have no
caller yet.

**Implementation discoveries for later milestones:**
- `SessionRepository` owns no cache (§9), so there is no meaningful
  difference between the initial load and a "refresh" — both are exactly
  the same `listSessions()` call. `SessionBrowserController.refresh()`
  simply re-invokes it; no separate `refreshIndex()` port method exists or
  is needed. Worth confirming this still holds once Feature 1.2.2 is
  built — if the detail view's `readSession()` ever needs its own
  re-scan semantics, that is the point to revisit, not now.
- A per-file `stat()` failure (a session deleted between listing and
  reading its metadata — the same race Feature 1.1.1's port already
  documented) is treated at the repository level exactly like Feature
  1.1.2 treats a malformed transcript line: skip that one item, log a
  warning, keep going. This is a second, independent application of the
  same tolerate-and-degrade discipline, at a different layer.
- `only_throw_errors` (analyzer, info-level) rejects throwing a raw
  `AppFailure` from `SessionBrowserController._load()` since `AppFailure`
  doesn't extend `Exception`/`Error` (deliberately, per its own doc
  comment). `ProviderSelectionNotifier`/`SettingsNotifier` already solve
  this by throwing a `StateError` with just the user-safe message and
  logging the full `AppFailure` separately — followed the identical
  pattern here rather than inventing a new one. Worth carrying into
  Feature 1.2.2's detail-page controller, which will hit the same lint.
- `UsageStatusMapper` (`features/usage/presentation/usage_status.dart`) is
  already reused outside `features/usage/` (by `core/components/`,
  `features/tray/`, `features/diagnostics/`) despite the bounded-context
  module structure in §7 — reusing `.relativeUpdated()` and
  `TrayStatusKind.live`/`StatusBadge` for the session tile's timestamp and
  live indicator follows that existing precedent rather than duplicating a
  relative-time formatter or inventing a session-specific status badge.

**Regression found:** None. The three tests that reference `UsagePage`
(`shared_dashboard_usage_test.dart`, `provider_selection_usage_test.dart`,
`ep002_ui_quality_test.dart`) were all already failing to compile before
this feature's changes (see Feature 1.1.3's log entry) for reasons
unrelated to sessions — none asserted anything about the toolbar's icon
set, so adding the Sessions `IconButton` carried no regression risk for
them.

**Branch note, recorded so it isn't mistaken for scope creep later:**
between this feature's implementation and its final verification, PR #13
squash-merged `feat/personalization-flex-theme` (which carried both this
work's Feature 1.1.1–1.1.3 commit and the unrelated theme-personalization
commit) into `main`; the working tree's checked-out branch moved to `main`
accordingly (confirmed via `git log`/`git branch -vv` — `main` is at
`5ebb037`, whose parent history shows the squashed commit message
containing both original commit bodies verbatim). This resolved the
previously-failing `UsagePage` compile errors (the personalization
work's own fixes landed as part of that merge) — not something done by,
or in the scope of, this feature.

One pre-existing, unrelated failure was discovered during final
verification: `test/unit/ui/shared_surfaces_controller_test.dart`
("settings load, save, timeout, and retry recover cleanly") fails with
`Expected: true, Actual: <false>` at its `save()` assertion (line 51) —
a `SettingsNotifier` test using a 40ms `operationTimeout`, unrelated to
sessions in every way (no import, call, or provider this feature touches).
Confirmed pre-existing, not caused by this feature's changes: `git stash
push -u` set the working tree to exactly `main`'s committed state, and
the same failure reproduced 3/3 runs before the stash was popped back.
Likely a timing-sensitive test whose fixed 40ms budget doesn't leave
enough margin under machine load — not a sessions concern, and not fixed
here per the same "don't fix pre-existing unrelated failures inside a
sessions story" rule Feature 1.1.1 established.

**ADR changes required:** None. No locked architectural decision was
challenged; `SessionRepository`'s shape and the "no cache" reasoning
implement §9 exactly as specified.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on every new/modified file in this feature.

**Test results:**
- New: 26 tests across 5 files, all passing — `session_list_filter_test.dart`
  (7: empty query, narrows by substring, case-insensitive, falls back to
  `sanitizedProjectDirName`, no-match, purity, determinism),
  `file_system_session_repository_test.dart` (6: builds summaries from
  seeded files, merges liveness onto matching sessions, a failed liveness
  call leaves `isLive` null without failing the list, a file that
  disappears between listing and stat is skipped, an empty directory
  succeeds empty, a genuine enumeration failure propagates),
  `session_browser_controller_test.dart` (5: populates state, surfaces a
  repository failure as `AsyncError`, `refresh()` re-queries and updates
  state, `refresh()` recovers from a prior error, `refresh()` is a no-op
  while already in flight), one new case in
  `fake_session_file_system_test.dart` (the new `listFailure` seam), and
  `test/widget/session_browser_page_test.dart` (7: populated list with
  path/activity/count, empty state, loading indicator via
  `holdNextResponse()`/`releaseResponse()`, refresh reflects newly added
  sessions, search narrows and clearing restores the list, no-match empty
  state, live badge shown only for `isLive == true`).
- Sessions-scoped suite (`test/unit/sessions/` +
  `test/widget/session_browser_page_test.dart`): **81/81 passing**.
- Full suite (`flutter test --exclude-tags golden,screenshot`): **266
  passed, 1 failed** — the single failure is the pre-existing, unrelated
  `shared_surfaces_controller_test.dart` timing test described above
  (verified independent of this feature via `git stash`); every other
  test passes, including the three `UsagePage`-referencing tests that
  were failing before this feature (see "Branch note" above for why).

---

#### Feature 1.2.2 — Session Detail View — ✅ Complete

**Stories completed:** Detail page · Graceful incomplete-session
rendering.

**Files added:**
- `lib/features/sessions/detail/presentation/session_detail_controller.dart`
  — `sessionDetailProvider`, a `FutureProvider.family<ClaudeSession,
  String>` (not an `AsyncNotifierProvider.family` — see discoveries
  below), plus `SessionLoadException` (carries the original
  `FailureCode`, extends `Error`)
- `lib/features/sessions/detail/presentation/session_detail_page.dart` —
  renders model, git branch, last activity, message count, token totals
  via `SectionCard`/`InfoRow` (`core/components/section_chrome.dart`,
  already used by 1.2.1); live badge reuses `StatusBadge`/
  `TrayStatusKind.live` exactly as the browser tile does; incomplete
  banner is a small local widget (the "graceful incomplete rendering"
  story); "session no longer available" state is its own distinct
  branch, keyed off `SessionLoadException.code == sessionNotFound`
- `test/unit/sessions/session_detail_controller_test.dart`,
  `test/widget/session_detail_page_test.dart`

**Files modified:**
- `lib/features/sessions/domain/repositories/session_repository.dart` —
  added `readSession(String sessionId)`. This is the method Feature
  1.2.1's log entry deliberately deferred ("nothing needs them yet") —
  this feature is the first and only caller.
- `lib/features/sessions/data/repositories/file_system_session_repository.dart`
  — implements `readSession()`: re-enumerates session files (no new
  lookup table — consistent with §9's "no cache, re-derive live each
  call"), matches by `sessionId`, and only then reads/parses the single
  matching file's full content. Returns `FailureCode.sessionNotFound`
  when no file matches — the real listing-vs-opening race §21 names for
  this exact feature.
- `lib/features/sessions/data/repositories/fake_session_repository.dart`
  — added `setSession()`/`setSessionFailure()` for the detail path,
  mirroring the existing `setSessions()`/`setFailure()` pair
- `test/unit/sessions/file_system_session_repository_test.dart` — added
  a `readSession` group (4 new cases)
- `lib/features/sessions/browser/presentation/session_browser_page.dart`
  — tiles are now wrapped in `InkWell` and push `SessionDetailPage`,
  matching the bare `Navigator.push(MaterialPageRoute)` pattern already
  used everywhere else in this codebase (no router)
- `test/widget/session_browser_page_test.dart` — added a
  tile-tap-opens-detail-page test

**Deviations from the roadmap:** None in shape or intent — `readSession()`
lands exactly where 1.2.1's log entry predicted it would.

**Implementation discoveries for later milestones (both significant —
read before building Feature 2.2.1's `ClaudeSessionService.resume()` or
any other new provider):**

1. **`AsyncNotifierProvider.family` does not exist in this project's
   installed `riverpod` (3.3.2) manual API.** Checked the installed
   package source directly (not assumed): `AsyncNotifierProvider` has no
   `static const family = ...Builder()` the way `Provider`,
   `FutureProvider`, and `StreamProvider` all do — a family notifier is
   codegen-only (`@riverpod`-annotated classes via `riverpod_generator`),
   which this codebase doesn't use anywhere (no `.g.dart` files, no
   `build_runner` dependency). `session_detail_controller.dart` therefore
   uses `FutureProvider.family` instead — same `AsyncValue` loading/data/
   error shape, no controller mutation methods needed since this feature
   has no "refresh" story. **Trigger for revisiting:** if a future
   feature needs a per-argument controller with mutation methods (not
   just a one-shot load), that is the point to either add
   `riverpod_generator` as a new dependency (a real decision, not a
   silent one) or hand-roll a family-keyed state map inside a
   non-family `AsyncNotifier` — not to reach for
   `AsyncNotifierProvider.family` again, since it isn't available.
2. **Riverpod 3.x retries a provider's failed `create` call automatically
   — up to 10× with exponential backoff — unless the thrown object `is
   Error`** (`ProviderContainer.defaultRetry`, checked directly in the
   installed package source: `if (error is ProviderException || error is
   Error) return null;`). Throwing `SessionLoadException` as a plain
   `implements Exception` type reproduced this as a real, reproduced
   test hang (30s timeout), not a hypothetical — the failure was logged
   immediately, but `.future` didn't settle until the retry backoff
   window was exhausted (well past any reasonable test/UI wait).
   Changing it to `extends Error` fixed it immediately. This retroactively
   explains *why* `SessionBrowserController._load()` (Feature 1.2.1) and
   `SettingsNotifier`/`ProviderSelectionNotifier` (pre-v2) all already
   throw `StateError` rather than a custom `Exception` type — their own
   comments cited only the `only_throw_errors` lint, but throwing a
   `StateError` (an `Error` subclass) also incidentally avoided this
   retry behavior. **This is a load-bearing rule for every future
   provider in this codebase, not just sessions:** a provider's `build`/
   `create` callback must throw something that `is Error` for an
   intentionally terminal failure — never a bare `Exception` implementer
   — or it will silently retry for up to ~30+ seconds before surfacing.
   Worth a shared note if this codebase adds more providers with typed
   failure information going forward.
3. Evaluated and reverted `FutureProvider.autoDispose` for
   `sessionDetailProvider`: a plain `ref.read(provider.future)`/
   `container.read(provider.future)` call — used by both the page and
   tests — has no active `ref.watch`/`container.listen` keeping it
   alive, so an autoDispose provider gets scheduled for disposal while
   its future is still pending, producing a `disposed during loading
   state` error (also reproduced directly, not assumed). No other
   provider in this codebase uses `autoDispose`, so keeping this one
   consistent (no autoDispose) was the simpler, lower-risk choice over
   teaching every read site to hold a keep-alive subscription.

**Regression found:** None. `InkWell`-wrapping the browser tile and
adding `SessionDetailPage` navigation only touches
`session_browser_page.dart`, already covered by Feature 1.2.1's own
widget tests (all still pass) plus the new tap-navigation test.

**ADR changes required:** None. `readSession()`'s shape and behavior
match §9 exactly; the retry/family discoveries above are riverpod-version
implementation details, not architectural decisions this roadmap governs.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on every new/modified file in this feature.

**Test results:**
- New: 4 repository cases (`readSession` group), 5
  `session_detail_controller_test.dart` cases (loads by id, keyed
  independently per id, `sessionNotFound` surfaces as
  `SessionLoadException` with the right code, other failures surface
  their own code, — 4 total plus the keying test), 5
  `session_detail_page_test.dart` widget cases (renders detail fields,
  session-not-found state, incomplete indicator shown/not-shown, live
  badge), and 1 new browser-page test (tap opens detail).
- Sessions-scoped suite (`test/unit/sessions/` + both session widget test
  files): **95/95 passing**.
- Full suite (`flutter test --exclude-tags golden,screenshot`): **280
  passed, 1 failed** — the single failure is the same pre-existing,
  unrelated `shared_surfaces_controller_test.dart` timing test recorded
  under Feature 1.2.1's log entry; nothing new.

**M1 exit criteria:** met. Session Browser (list + detail) is read-only —
independently verifiable by grep: no `--resume`, no write call anywhere
under `lib/features/sessions/`.

---

## Milestone 2 — Manual Resume + Better Notifications (gated on M1 shipped)

### Epic 2.1 — Notification Gateway

#### Feature 2.1.1 — Notification Gateway Port — ✅ Complete

**Stories completed:** Define `NotificationGateway` port + fake · Migrate
`TrayController.maybeNotify` to the gateway.

**Files added:**
- `lib/core/notifications/notification_gateway.dart` — port
  (`notify({title, body, onClick})`), lives in `core/` not
  `features/sessions/` since it's cross-cutting (§7 placement rule 2,
  §12)
- `lib/core/notifications/io_notification_gateway.dart` — wraps
  `local_notifier`, preserving `maybeNotify`'s exact prior behavior
  (catch-log-swallow on failure, never throws)
- `lib/core/notifications/fake_notification_gateway.dart` — records
  calls (title/body/onClick), mirrors `FakeProcessRunner`'s shape
- `lib/core/notifications/notification_providers.dart` —
  `notificationGatewayProvider`
- `test/unit/notifications/fake_notification_gateway_test.dart`,
  `test/unit/tray/tray_controller_test.dart` (new — none existed before,
  see discoveries)

**Files modified:**
- `lib/features/tray/presentation/tray_controller.dart` —
  `TrayController` takes a `notificationGateway` constructor parameter;
  `maybeNotify()` now calls `notificationGateway.notify(title: 'AI Tray',
  body: '...')` instead of constructing `LocalNotification` directly —
  same title/body string, same threshold logic, unchanged
- `lib/core/di/providers.dart` — exports `notificationGatewayProvider`;
  `trayControllerProvider` now wires it in
- `lib/features/notifications/{data,domain,presentation}/.gitkeep` —
  removed. §7 explicitly retires this empty placeholder feature in favor
  of `core/notifications/`; this story is where that retirement actually
  happens.
- `docs/dogfood/POST_EP002_MACOS_ARM64.md` — added checklist row 12 for
  the gateway migration and (forward-looking) `onClick` verification,
  per this feature's own acceptance criteria

**Deviations from the roadmap:** None in shape or intent.

**Implementation discoveries for later milestones:**
- **No `TrayController`/`maybeNotify` test existed before this feature** —
  confirmed by grepping `test/` for both names (zero hits), matching
  exactly what §12's own text already claimed ("no notification test
  exists"). So "existing tests must keep passing unmodified" had nothing
  to preserve; the 5 new `tray_controller_test.dart` cases are the first
  coverage this code path has ever had (notifies with correct title/body,
  suppressed below threshold, suppressed when disabled, suppressed for
  cached usage, suppressed with no threshold configured) — closing
  exactly the gap the v1 audit and this roadmap both flagged.
- **A second, unmigrated `LocalNotification` call site exists**:
  `DiagnosticsPage._testNotification()` (a "Test notification" diagnostic
  button) constructs `LocalNotification` directly, not through the new
  gateway. Left as-is deliberately — this story's roadmap text names only
  `TrayController.maybeNotify` as the migration target, and
  `_testNotification` is a `static` helper with no `ref`/DI access today,
  so migrating it would be new scope (threading a gateway into a static
  diagnostics helper), not a like-for-like swap. **Trigger for
  revisiting:** if Epic 2.3's `onClick`-driven notifications reveal any
  gateway behavior gap, checking this second call site for the same gap
  is the first place to look; otherwise it's cosmetic inconsistency, not
  a correctness issue.
- `IoNotificationGateway` has no automated test — `local_notifier` needs
  real platform channels (macOS/Windows native code) that don't exist in
  a plain `flutter test` VM run, the same reason `docs/claude_code_cli_capability_report.md`-style
  CLI-adjacent code gets fixture/fake tests instead of hitting the real
  thing. This is exactly why §12/Feature 2.1.1 asks for a **manual**
  dogfood checklist entry instead of an automated one — added as row 12
  above, not skipped.

**Regression found:** None. `TrayController`'s constructor gained a new
required parameter, a compile-level change only `trayControllerProvider`
needed updating for (one call site, confirmed by grep).

**ADR changes required:** None. This is exactly ADR-006's/§12's
`NotificationGateway` design, implemented as specified — ports+fake
modeled on `ProcessRunner`, cross-cutting placement in `core/`.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on every new/modified file in this feature.

**Test results:**
- New: 3 `fake_notification_gateway_test.dart` cases, 5
  `tray_controller_test.dart` cases — 8 total, all passing.
- Full suite (`flutter test --exclude-tags golden,screenshot`): **288
  passed, 1 failed** — the same pre-existing, unrelated
  `shared_surfaces_controller_test.dart` timing test recorded under
  Feature 1.2.1/1.2.2's log entries; nothing new.

---

### Epic 2.2 — Resume Execution

#### Feature 2.2.1 — Manual Resume Action — ✅ Complete

**This is the first *acting* feature in the codebase** — every prior
feature (M1, Epic 2.1) was read-only. Design principle 2's safety model
was applied from the first line, not bolted on after: attended
"Resume now" continues in place (`forkSession: false`), never forks,
never requires a budget cap (that requirement is scoped to *unattended*
execution — Feature 2.2.2's queue — per §2 principle 2's own wording and
user journey 2's text, neither of which mention a cap for manual resume).

**Stories completed:** `ClaudeSessionService.resume()` · "Resume now"
wired from Session Detail · Result surfaced in-app.

**Files added:**
- `lib/features/sessions/domain/models/resume_outcome.dart` —
  `ResumeOutcome` (sessionId, isError, costUsd, tokens, numTurns,
  stopReason, resultText), mapped from the CLI's confirmed
  `--output-format json` result envelope (capability report §3D); reuses
  `SessionTokenTotals` for the `usage` block rather than a new type
- `lib/features/sessions/resume/presentation/resume_controller.dart` —
  `ResumeController` (`AsyncNotifier<ResumeAttempt?>`) + `ResumeAttempt`
  (tags an outcome with the session id it belongs to — see discoveries)
- `test/unit/sessions/resume_controller_test.dart`

**Files modified:**
- `lib/features/sessions/data/process/claude_session_service.dart` —
  added `resume()` alongside the existing `listLiveSessions()`, per §7's
  "ONE class, two capabilities" design. Builds the confirmed
  `--resume <id> -p "<prompt>" --output-format json [--max-budget-usd
  <cap>] [--fork-session] [--fallback-model <list>]` grammar (§2/§3D/§15);
  10-minute default timeout (explicit, not `ProcessRunner`'s 8s default);
  tolerates a non-zero exit (bogus session id — confirmed live in the
  capability report to fail with plain stderr, not JSON), malformed JSON,
  and a non-object JSON shape, matching `listLiveSessions()`'s existing
  defensive-parsing discipline.
- `lib/features/sessions/detail/presentation/session_detail_page.dart` —
  added a "Resume now" section: a prompt field + button, disabled with no
  `ClaudeSession.projectPath` (never guesses a `cwd` — design principle
  3) and while a resume is in flight; renders cost/tokens/turns/stop
  reason/result text on success, an error message on failure.
- `lib/features/providers/data/process/fake_process_runner.dart` —
  `calls` now records `timeout`/`workingDirectory` alongside
  `executable`/`arguments` (previously only the latter two) — needed to
  actually verify `resume()` forwards the non-default timeout and the
  session's `cwd` correctly, which no existing test needed before.
  Confirmed no existing test depended on the old 2-tuple shape (grepped
  `test/` for `.calls` — the only hits were this feature's own new
  tests), so this was a safe, non-breaking enhancement, not a migration.
- `test/unit/sessions/claude_session_service_test.dart` — added a
  `resume` group (14 cases)
- `test/widget/session_detail_page_test.dart` — added 5 cases for the
  new "Resume now" section

**Deviations from the roadmap:** None in shape or intent. One explicit
scope decision, stated because it's easy to misread as an omission: this
story's UI has **no budget-cap input field** — confirmed intentional by
re-reading §2 principle 2 ("mandatory... on every *queued or scheduled*
resume") and user journey 2 (manual resume shows cost only *after*
completion, no pre-flight cap). `resume()` itself *does* accept an
optional `maxBudgetUsd` parameter — the queue executor (Feature 2.2.2)
will be the caller that always supplies one.

**Implementation discoveries for later milestones:**
- **`ResumeController` is a single, app-wide `AsyncNotifier`, not a
  family provider** — deliberately, continuing the same reasoning
  Feature 1.2.2 already established (`AsyncNotifierProvider.family`
  isn't available in this codebase's non-codegen riverpod usage). Unlike
  `sessionDetailProvider` (which *loads* per-id data), `resume()` is an
  imperative action that takes the session id as a call argument — the
  same shape `SettingsNotifier.save(settings)` already uses — so no
  family provider was needed at all, not even a `FutureProvider.family`
  workaround. The one wrinkle this shape introduces: a single app-wide
  controller means its last result would leak across different sessions'
  detail pages if not scoped somehow. Solved with `ResumeAttempt`
  (outcome + the session id it belongs to) — the page only renders a
  stored result when `attempt.sessionId == this page's sessionId`. Worth
  reusing this exact tagged-result shape for Feature 2.2.2's queue
  executor if it ever needs a similarly-shaped "last result, scoped to
  which item it's for" pattern.
- Confirmed live in the capability report and now covered by a
  regression test: a bogus/deleted session id fails the CLI call
  *before* any JSON envelope is built — plain stderr text, exit code 1,
  even when `--output-format json` was requested. `resume()` must check
  `exitCode != 0` **before** attempting `jsonDecode` (matches
  `listLiveSessions()`'s existing order of checks) — got this right the
  first time here because the capability report flagged it explicitly,
  but worth calling out for Feature 2.2.2, which will hit the identical
  case for a queue item whose session was deleted after being enqueued.
- `FakeProcessRunner.calls` gained `timeout`/`workingDirectory` fields
  (see "Files modified" above) — this is now the place to look for
  verifying *any* future `ProcessRunner` caller's non-default
  timeout/cwd, not just this feature's.

**Regression found:** None. `FakeProcessRunner.calls`'s shape change was
verified safe (see above) and the full suite confirms it.

**ADR changes required:** None. This story implements ADR-006's safety
model exactly as specified for the *attended* path — the unattended/queue
half of ADR-006 (mandatory cap, fork-by-default, stale-`cwd` fail-fast)
is Feature 2.2.2's remit, not touched here.

**Analyzer status:** Clean — `flutter analyze --fatal-infos` reports no
issues on every new/modified file in this feature.

**Test results:**
- New: 14 `claude_session_service_test.dart` `resume` cases (confirmed
  grammar, workingDirectory/timeout forwarding, fork-session
  presence/absence, budget cap presence/absence, fallback-model joining,
  full parse of cost/tokens/turns/stopReason/resultText, an `is_error`
  result still parses fully, a bogus-id non-zero exit, malformed JSON,
  non-object JSON, timeout, process launch failure, custom executable
  path), 3 `resume_controller_test.dart` cases (populates state tagged by
  session id, a failure surfaces as `AsyncError`, a second concurrent
  call is a no-op), 5 new `session_detail_page_test.dart` cases (button
  disabled until a prompt is entered, full result renders on success, an
  error renders on failure, unavailable state with no decoded project
  path) — 22 new, all passing.
- Sessions-scoped suite (`test/unit/sessions/` + both session widget test
  files): **116/116 passing**.
- Full suite (`flutter test --exclude-tags golden,screenshot`): **309
  passed, 1 failed** — the same pre-existing, unrelated
  `shared_surfaces_controller_test.dart` timing test; nothing new.

---
