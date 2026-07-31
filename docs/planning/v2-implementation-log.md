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
