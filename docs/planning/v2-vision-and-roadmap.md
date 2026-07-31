# AI Tray — v2 Vision & Roadmap

**Status:** **Approved for Implementation — architecture frozen** (see
"Lock," end of document). Major decisions in this document are locked;
further architectural changes happen through new ADRs, not ad hoc edits
here.
**Depends on:** `docs/reports/project-status-report.md` (v1 architecture audit),
`docs/claude_code_cli_capability_report.md` (Claude CLI research, verified
against `2.1.220`), `docs/project/ROADMAP.md`, ADR-001..004
**Assumption per brief:** `--resume`, `claude agents --json`, JSON/`stream-json`
output, JSONL transcripts under `~/.claude/projects/`, session IDs, and
continue/fork workflows are treated as confirmed CLI capabilities. This
document does not re-verify them; it verifies how they interact with AI
Tray's *existing* code, since that is what determines real engineering cost.

Two package-level facts were checked fresh for this design (not carried over
from the prior audit) because a headline recommendation depends on them:

- `ProcessRunner.run()` defaults to `timeout: Duration(seconds: 8)` and
  `IoProcessRunner` responds to a timeout by `process.kill(ProcessSignal.sigkill)`
  (`ai_tray/lib/features/providers/data/process/io_process_runner.dart`). The
  timeout is a per-call parameter, so the port itself doesn't need to change
  shape for longer-running calls — but nothing above it currently passes
  anything but the 8s default, and there is no cancellation path other than
  timeout.
- `local_notifier 0.1.6`'s `LocalNotification` exposes `onClick`, `onClickAction`,
  `onShow`, and `onClose` callbacks (confirmed via the package's published API
  docs), but has no generic payload/data field. Click-to-resume is therefore
  buildable today — the session/`cwd` context has to be captured in the
  `onClick` closure at construction time (the same place `TrayController`
  already constructs each `LocalNotification`), not read off a payload field.

---

## Design Review — This Revision

Three structural suggestions were evaluated against the existing architecture,
Clean Architecture principles, and this document's own stated priorities
(lightweight, gated milestones, reuse over invention). None were applied
automatically; each was checked for whether it makes the design *objectively*
stronger, not just different.

| # | Suggestion | Verdict | Why (detail at the cross-reference) |
| --- | --- | --- | --- |
| 1 | Model Queue/Scheduler as subdomains of a Sessions bounded context instead of separate top-level features | **Accepted, with one deviation from the suggested layout** | Directly matches existing precedent (`features/providers/` already uses internal subdomains — `core/`, `copilot/`, `data/`, `domain/`, `presentation/` — for one bounded context rather than one feature per provider). Queue and Scheduler both operate on session identity and both depend on a shared `resume()` capability; treating them as independent top-level features would force awkward cross-feature imports for no benefit. See §6.1 note and §7 (rewritten). |
| 2 | Introduce a provider abstraction now for future CLIs (Gemini, Codex, Cursor, Aider) | **Rejected for v2; trigger documented for later** | Exactly one confirmed implementation (Claude) exists. `AIProvider`/`ProviderRegistry` was justified in v1 because it had *two* concrete, real implementations from day one (Claude + Copilot) — a session/resume abstraction today would be shaped by guesswork against zero other confirmed CLI surfaces. This is the same premature-generalization risk this document already flags for databases (§14) and streaming (§15). See new §6.1. |
| 3 | Document a workspace-centric dashboard (project → sessions/queue/quota/activity) as a long-term direction | **Documented as v3+ direction only; not scoped, not built** | It's a plausible convergence point once Browser + Queue + Scheduler + existing quota data all exist, and it's a genuinely different shape from the already-postponed Session Analytics (operational "what's active now" vs. analytical "trends over time"). Scoping it now would violate this document's own principle 6 (ship the read-only capability alone first) and the milestone-gating logic. See new §1.1 and the updated "What belongs in v3?" answer. |

The milestone-based roadmap (§21) is **unchanged in sequence and gating**
(M1 → M2 → M3 still ship in that order for the same reasons) — only the
internal module layout underneath it moved, which is a documentation/
folder-structure correction, not a scope or sequencing change.

---

## 1. Product Vision

AI Tray v1 answers one question: *"how much of my Claude/Copilot quota have I
used?"* It is entirely observational — every code path in the v1 audit reads
external state and never writes to it.

**v2 vision:** AI Tray becomes a lightweight desktop companion for *managing*
Claude Code sessions — see what sessions exist, resume one with a click,
queue a few resumes for later, and get notified when they're done — without
becoming a chat client, an IDE, or a general automation platform. The Claude
CLI remains the only actor that talks to a model; AI Tray only ever shells
out to it, the same way it does today for `/usage`.

**Explicit non-goals (stated up front, revisited in §21):**

- AI Tray does not render chat/conversation UI beyond a session's own
  metadata and summary — it is not a Claude Code client replacement.
- AI Tray does not become a generic workflow/automation engine (no rules
  engine, no arbitrary triggers, no scripting surface).
- AI Tray does not take actions on a session with no cost/safety guardrail.

Formalized as **ADR-010 — AI Tray is an Orchestration Companion** (§16): the
guardrail every future feature proposal, in v2 and beyond, should be checked
against first.

### 1.1 Long-Term Direction (v3+, documented only — not scoped in v2)

Once Session Browser, Resume Queue, and Resume Scheduler exist, the natural
convergence point is a **workspace-centric view**: pick a project and see, in
one place, its active/live sessions, its queued and scheduled resumes, and
the quota status that gates them — essentially "what's happening right now
in this project," organized by workspace instead of by feature type. This is
distinct from Session Analytics (§3/§4, also v3+): analytics looks backward
(trends, cost over time); a workspace view looks at the present moment.

This is recorded here as a plausible north star only. It is not designed,
not scoped, and not part of any v2 milestone — doing so now would mean
designing a dashboard around data (Queue history, Scheduler outcomes) that
doesn't exist yet, which is the same speculative-design mistake this
document avoids elsewhere (§14's database trigger, §6.1's provider-
abstraction trigger). If v3 planning happens, this is the first product
question worth revisiting, once M1–M3 usage data exists to design it against.

## 2. Design Principles

These extend, not replace, the five invariants already recorded in
`docs/project/AI_HANDOFF.md` §"Architecture invariants."

1. **Reuse before rebuild.** Every v2 capability must state which existing
   port, service, or pattern it extends before any new abstraction is
   proposed (§9–§12 each do this explicitly).
2. **v1 was read-only; v2 introduces write/act capability, and that is a
   category change, not a queue field.** Anything that runs
   `claude --resume` unattended spends the user's money and runs an agent
   with tool permissions in their working directory while no human is
   watching. Every acting feature must default to safe behavior, not
   feature-flag safety in later:
   - A cost cap (`--max-budget-usd`) is **mandatory**, not optional, on every
     queued or scheduled resume — there is no "run without a cap" path in the
     UI.
   - Unattended execution (queue/scheduler) defaults to `--fork-session`, so
     an automated run never silently mutates a transcript the user might be
     actively continuing elsewhere by hand. Manual, attended "Resume now"
     from the Browser may continue in place, because a human is present to
     notice.
   - Auto-execution is an explicit, separate, off-by-default setting — an
     item sitting in the queue is inert until the user turns on
     auto-execute or presses "run" themselves.
   - If a queue item's stored `cwd` no longer exists at execution time, it
     fails fast with a visible error; it never creates the directory or
     silently substitutes another one.
   - `claude project purge` (destructive, documented, per the capability
     report §7) is never surfaced or wrapped by any v2 UI.
3. **JSONL files are the source of truth; nothing about the CLI's live
   session registry is load-bearing.** The capability report only observed
   `claude agents --json` returning `[]` — field names in a populated result
   are unconfirmed. The Session Browser must render completely and
   correctly from JSONL alone; `agents --json` is enrichment only (a
   "live"/"archived" badge), and its absence or a missing field must degrade
   silently, never break the list.
4. **A killed process is an accepted, ordinary state, not an error state.**
   Claude Code writes JSONL incrementally; `SIGKILL` on timeout simply ends
   the file abruptly, the same as a user's own `Ctrl-C`. The Browser and
   Queue must render an incomplete/truncated session honestly, not treat it
   as corruption.
5. **No new storage technology until an existing one demonstrably can't do
   the job.** v1 has exactly one persistence mechanism
   (`SharedPreferences`). v2 keeps it unless a specific, named requirement
   forces a change (§14 explains why v2 doesn't hit that wall).
6. **Ship the read-only capability alone before shipping anything that
   acts.** Session Browser has no safety surface to design and de-risks the
   filesystem/parsing work in isolation. Resume Queue and Scheduler are
   gated on it shipping (§17 milestones).

## 3. Recommended v2 Scope

Evaluated against user value, engineering effort, maintainability, and fit
with "lightweight companion, not automation platform":

| Idea (from brief) | Recommendation | Why |
| --- | --- | --- |
| Session Browser | **Build (M1)** | High value (nothing today shows session history), moderate effort, read-only, reuses `ProcessRunner` + design system, de-risks everything else |
| Session Repository | **Build, reframed** | Not a database — a thin index over JSONL files plus a small `SharedPreferences`-backed store for the (bounded) queue/schedule. See §14. |
| Resume Queue | **Build (M2)** | Directly reuses `RefreshService`'s single-flight/retry shape and `ProcessRunner`'s buffered call; the natural second step after Browser |
| Resume Scheduler | **Build, narrowed (M3, gated)** | Reuses `UsageRepositoryImpl`'s timer/backoff/`recoverScheduleIfOverdue` pattern almost directly; scoped to "fire while the app is running," not a guaranteed OS-level cron |
| Session Analytics | **Postpone to v3** | Downstream of Browser + Queue; building it now has no real usage data to analyze and risks becoming a BI dashboard, which contradicts "lightweight" |
| Better notifications | **Build (M2)** | `onClick` is confirmed available; lowest effort, extends an existing dependency and an existing code path (`TrayController.maybeNotify`) |
| Workflow automation | **Reject as stated; reframe** | "Automation" as a generic rules/triggers engine is scope creep against the product's own positioning. What the brief actually wants — queue + schedule + notify — is already M2/M3. No separate automation epic. |
| Future providers (session features) | **Explicitly out of scope for v2** | Only Claude's CLI has a confirmed resume/session/JSONL surface; Cursor is blocked by PD-023 and Copilot has no equivalent session model. Usage/quota multi-provider support is unaffected and unchanged. |

## 4. Features to Postpone

Stated explicitly so they are a decision, not an oversight:

- **Full Session Analytics dashboard** (trends, cost-over-time charts) — v3,
  gated on Session Repository accumulating real data from Browser/Queue use.
- **True OS-level wake scheduling** (a registered `launchd`/Task Scheduler
  job that fires even if AI Tray is quit) — only worth the new
  dependency/complexity if the app-resident scheduler in M3 turns out to be
  unreliable enough that users complain.
- **Cooperative cancellation of a running resume** — v1 (and this design)
  has no cancel path beyond timeout-then-kill. Building real cancellation
  (SIGINT + confirm, or a protocol-level cancel) is real, separate work;
  v2's answer to "cancel a queue item" is "wait for the timeout."
- **Streaming/live progressive view of a resuming session** —
  `--output-format stream-json` is real, but M2's Resume Queue only needs
  the buffered `--output-format json` result (§15). Live output view is only
  worth building if users specifically ask to *watch* a queued resume run,
  which is a chat-client-adjacent feature this product intentionally avoids.
- **New tracked session creation** (`--session-id <uuid>` pre-generation) —
  v2 resumes *existing* sessions; starting new ones from AI Tray is a
  different, larger feature (effectively a prompt-composer) not requested
  here.
- **Multi-provider session/resume support** — see §3 table.
- **A generic workflow automation engine** — see §3 table.

## 5. User Journeys

1. **"What sessions do I have?"** (M1) — Open the Session Browser from the
   tray or in-window nav. See sessions grouped/searchable by project path,
   each with last-activity time and message count, sourced entirely from
   JSONL files; a live badge appears only where `agents --json` returned a
   match.
2. **"I want to continue this session right now."** (M2) — From a session's
   detail view, type a continuation prompt, click "Resume now." AI Tray
   runs `claude --resume <id> -p "<prompt>" --output-format json` in the
   session's `cwd`, continuing in place (attended default), and shows
   cost/tokens/turns/result when it completes.
3. **"Queue a few resumes to run while I'm away, capped at $2 each."** (M2) —
   From the Browser, add 2–3 sessions to the Resume Queue with a prompt and
   a mandatory budget cap each; turn on auto-execute. Items run sequentially
   (single-flight), forking by default since no one is watching; a
   notification fires per completion.
4. **"Notify me and click straight through to the result."** (M2) — Clicking
   a queue-completion notification opens AI Tray focused on that session's
   result — `onClick` captured the session id/`cwd` at notification-creation
   time.
5. **"Resume my long task automatically when my weekly quota resets."** (M3,
   gated) — Schedule a queued item against the best-effort reset time
   already surfaced by the usage dashboard. If AI Tray is running when the
   deadline passes, the scheduler fires the queue item exactly like a manual
   auto-execute run. The UI states plainly that this requires AI Tray to be
   running — no promise of firing after sleep or quit.

## 6. Technical Architecture

```
Presentation                 Session Browser / Session Detail / Resume Queue /
                              Schedule pages (new) — reuse core/components
State (Riverpod)              SessionBrowserController, ResumeQueueController,
                              ScheduleController (new AsyncNotifiers) — same
                              shape as existing controllers, no new pattern
Domain                        ClaudeSession, SessionSummary, ResumeOutcome,
                              ResumeQueueItem, ScheduledResume (new immutable
                              models, organized as Sessions-bounded-context
                              subdomains — see §7) + SessionRepository,
                              ResumeQueueRepository, ScheduleRepository
                              ports (new, mirroring
                              UsageRepository/SettingsRepository)
Data                           FileSystemSessionRepository (new; wraps a new
                              SessionFileSystem port), ClaudeSessionService
                              (new; wraps existing ProcessRunner for
                              `agents --json` and `--resume ... json`),
                              SharedPreferences-backed Queue/Schedule
                              repositories (new, same pattern as
                              SettingsRepositoryImpl), NotificationGateway
                              (new port wrapping local_notifier)
External                      Claude CLI only (unchanged invocation pattern;
                              §6.1 explains why no provider abstraction sits
                              in front of it yet), ~/.claude/projects/**/*.jsonl
                              (read-only, new), SharedPreferences (unchanged),
                              local_notifier (unchanged dependency, new seam
                              around it)
```

No new Flutter package dependency is required for M1–M3. `local_notifier`,
`shared_preferences`, `flutter_riverpod` already cover everything designed
here.

### 6.1 Provider Extensibility for Sessions (evaluated, deferred)

The brief asks whether a provider abstraction should be introduced now so
future CLIs (Gemini CLI, Codex CLI, Cursor CLI, Aider) are easier to add
later. **Decision: no — not in v2.** This is deliberate, not an oversight,
and the reasoning is worth stating precisely because it looks, on the
surface, like the same multi-provider problem ADR-003 already solved for
usage/quota:

- **ADR-003's `AIProvider`/`ProviderRegistry` abstraction was validated
  against two concrete, real implementations from the start** (Claude and
  Copilot were both being built when the registry was designed). An
  interface shaped by one real example and guesses about others tends to be
  wrong in the ways that matter — extra parameters nobody needed, missing
  ones nobody anticipated — and has to be reworked anyway once the second
  real implementation arrives.
- **Zero of the four named CLIs (Gemini, Codex, Cursor, Aider) have a
  confirmed resume/session/transcript surface researched to the depth of
  `docs/claude_code_cli_capability_report.md`.** Cursor is already a known
  case: PD-023 blocked it as a *usage* provider for the identical
  reason — no official API to build against. Building a `SessionProvider`
  port today would mean designing an interface against one data point,
  which is the same premature-generalization risk this document already
  rejects for storage (§14) and streaming (§15).
- This is consistent with — not a reversal of — the product decision already
  in §3/§4 (session/resume features are Claude-only for v2).

**What this deliberately does *not* mean:** naming things as if no
abstraction will ever exist. Classes are named after the vendor
(`ClaudeSessionService`, `ClaudeSession`), matching the codebase's own
convention of vendor-named concrete adapters behind generic ports
(`ClaudeCliAdapter` implements `AIProvider`) — a generic name on a
single-vendor concrete class would misrepresent it as already abstracted
when it isn't.

**Named trigger for revisiting this decision:** if and when a second CLI's
session/resume/transcript surface is researched and confirmed to a similar
depth as the existing Claude capability report, *and* a second
implementation is actually being built (not merely proposed) — the same
bar ADR-003's abstraction cleared. Until then, keep the CLI-argument
construction and JSONL-path assumptions isolated inside
`ClaudeSessionService` and the session parser (§10), so that if the trigger
is met, extracting a port is a rename-and-extract-interface exercise, not an
untangling of Claude-specific assumptions scattered across controllers and
UI. This trigger is proposed as ADR-009 (§16).

## 7. Module Structure

**Revised from the original proposal** (three separate top-level features:
`features/sessions/`, `features/resume_queue/`, `features/scheduler/`) to
**one Sessions bounded context with internal subdomains**, each still
following `presentation/domain/data` layering within its own scope. This
follows existing precedent directly: `features/providers/` already organizes
one bounded context (the multi-provider platform) into named subdomains
(`core/`, `copilot/`, `data/`, `domain/`, `presentation/`) rather than one
top-level feature per provider — the same shape applies here, because
Browser, Detail, Resume, Queue, and Scheduler all operate on the same
aggregate concept (a Claude session and what you do with it) and share
identity, not just a UI theme the way `settings`/`tray`/`diagnostics` do.

```
lib/features/sessions/
  ├── domain/
  │   ├── ports/
  │   │   └── session_file_system.dart       # new FS port, mirrors ProcessRunner's shape
  │   ├── models/
  │   │   ├── session_summary.dart           # list-view projection — returned by SessionRepository.listSessions(),
  │   │   │                                  # read by browser/
  │   │   ├── claude_session.dart            # full parsed session — returned by SessionRepository.readSession(),
  │   │   │                                  # read by detail/
  │   │   └── resume_outcome.dart            # cost/tokens/turns/stopReason/resultText — returned by
  │   │                                      # ClaudeSessionService.resume(), read by BOTH resume/ (manual) and
  │   │                                      # queue/ (ResumeQueueItem.result)
  │   └── repositories/
  │       └── session_repository.dart        # listSessions() + readSession() — shared by browser/ and detail/
  ├── data/
  │   ├── fs/
  │   │   └── io_session_file_system.dart
  │   ├── parsers/
  │   │   └── jsonl_session_parser.dart      # index pass (browser) + lazy full-transcript pass (detail) —
  │   │                                      # kept together since both share one tolerate-and-degrade discipline
  │   ├── repositories/
  │   │   └── file_system_session_repository.dart
  │   └── process/
  │       └── claude_session_service.dart    # ONE class, two capabilities — listLiveSessions() [agents --json,
  │                                          # used by browser/] and resume() [--resume ... json, used by
  │                                          # resume/ and queue/] — mirrors ClaudeCliAdapter's existing pattern
  │                                          # of bundling one vendor's related CLI calls into one class
  │
  ├── browser/                               # session list (M1) — presentation only; its model is at the
  │   └── presentation/                      # sessions/ root (above), not duplicated or re-exported here
  │       session_browser_controller.dart / session_browser_page.dart
  │
  ├── detail/                                # single-session view (M1) — presentation only, same reason
  │   └── presentation/
  │       session_detail_controller.dart / session_detail_page.dart
  │
  ├── resume/                                # attended "Resume now" action (M2) — presentation only;
  │   └── presentation/                      # ResumeOutcome lives at the sessions/ root (above), not here,
  │                                          # because queue/ needs it too (see rule 1 below). Wires the
  │                                          # detail page's "Resume now" button to
  │                                          # sessions/data/process/claude_session_service.dart
  │
  ├── queue/                                 # unattended/batch resume (M2)
  │   ├── domain/
  │   │   ├── models/resume_queue_item.dart  # references ResumeOutcome from the sessions/ root for its
  │   │   │                                  # `result` field — used ONLY by queue/, so it stays local
  │   │   └── repositories/resume_queue_repository.dart
  │   ├── data/repositories/shared_preferences_resume_queue_repository.dart
  │   └── presentation/resume_queue_controller.dart / resume_queue_page.dart
  │
  ├── scheduler/                              # M3 only, built on §11's core primitive
  │   ├── domain/models/scheduled_resume.dart # used ONLY by scheduler/, stays local
  │   ├── data/repositories/shared_preferences_schedule_repository.dart
  │   └── presentation/schedule_controller.dart / schedule_page.dart
  │
  └── analytics/                              # v3 — name reserved only; no code in v2 (§4)

lib/core/scheduling/
  └── deadline_scheduler.dart                 # extracted from UsageRepositoryImpl (§11) —
                                              # cross-cutting (usage refresh + session scheduler both
                                              # depend on it), so it stays in core/, not sessions/

lib/core/notifications/                       # replaces the empty features/notifications/
  ├── notification_gateway.dart               # port wrapping local_notifier
  └── io_notification_gateway.dart
```

**Correction from an earlier pass of this document:** `SessionSummary`,
`ClaudeSession`, and `ResumeOutcome` were originally shown living inside
`browser/`, `detail/`, and `resume/` respectively. That violated this
section's own placement rule below — the root-level `SessionRepository`
returns `SessionSummary`/`ClaudeSession`, and the root-level
`ClaudeSessionService.resume()` returns `ResumeOutcome`, so a shared root
component would have had to import from three different subdomains, and
`queue/` would have had to import `ResumeOutcome` from `resume/` sideways.
Fixed by moving all three to `sessions/domain/models/` at the root, which is
also why `browser/`, `detail/`, and `resume/` are presentation-only above.

Two placement rules make this consistent rather than arbitrary:

1. **Anything used by more than one session subdomain lives at the
   `sessions/` root** (the FS port, the three models above, `SessionRepository`,
   and `ClaudeSessionService`), the same way `providers/core/` holds what
   `providers/copilot/` and `providers/data/claude/` both need. Anything used
   by exactly one subdomain lives inside it (`ResumeQueueItem` in `queue/`,
   `ScheduledResume` in `scheduler/`).
2. **Anything used by session features *and* by unrelated v1 features stays
   in `core/`** — `DeadlineScheduler` (used by session scheduling *and* usage
   refresh) and `NotificationGateway` (used by session notifications *and*
   the existing usage-threshold notification) are cross-cutting
   infrastructure, not Sessions-specific, so they do not move into
   `features/sessions/` even though this revision nests the rest of the
   session work into one bounded context.

**This borrows `providers/`'s subdomain *shape*, not its alias layer.**
ADR-004 identifies `providers/`'s ~35 compatibility re-export files
(`providers/domain/` mostly forwarding to `providers/core/`) as debt from
letting two names for the same type coexist during a migration. Sessions has
no equivalent: each model above is defined exactly once, at exactly one
location, and every subdomain imports that one definition directly — there
is no `sessions/domain/` re-exporting a `sessions/core/`. Citing `providers/`
here is about the "one bounded context, named subdomains" shape, not an
endorsement of the shim pattern ADR-004 is cleaning up.

`browser/` and `detail/` are kept as separate subdomains (matching the
original suggestion) rather than merged into one, because the roadmap
already treats them as two distinct controllers/features (§21, Feature 1.2.1
vs. 1.2.2) and `detail/` alone grows a dependency on `resume/` that `browser/`
never needs — collapsing them would blur that boundary for no real savings.

`features/notifications/` (currently three empty `.gitkeep` files) is
retired in favor of `core/notifications/`, since the gateway is cross-cutting
infrastructure (used by usage-threshold notifications, queue completion, and
scheduled-resume firing alike), not a vertical feature slice. This is an
explicit answer to the open question the v1 audit flagged in §15/§17.2 of the
status report.

## 8. Domain Model

All new models follow the existing convention: `@immutable`, `copyWith`,
value equality, no `freezed`/`json_serializable`.

- **`SessionSummary`** (lives at the `sessions/` root, §7 — read by
  `browser/`) — `sessionId`, `projectPath` (decoded from the JSONL
  directory name), `lastActivityAt` (from file mtime or last line's
  timestamp — cheapest available signal), `messageCount` (approximate, from
  a fast line count, not a full parse), `isLive` (nullable — `null` when
  `agents --json` didn't confirm either way, per design principle 3).
- **`ClaudeSession`** (lives at the `sessions/` root, §7 — read by
  `detail/`) — full detail: adds `model`, `gitBranch`, `tokenUsageTotals`
  (aggregated from `message.usage` across the transcript), `title` (only
  populated if the on-disk field name is confirmed for the shipped CLI
  version — otherwise `null`, never guessed), `isComplete` (false if the
  transcript appears to end mid-turn — design principle 4).
- **`ResumeOutcome`** (lives at the `sessions/` root, §7 — read by both
  `resume/` and `queue/`) — `costUsd`, `tokens`, `numTurns`, `stopReason`,
  `resultText`, mapped directly from the CLI's own JSON result envelope
  documented in the capability report §3D. Introduced as its own named
  model (rather than inlined into `ResumeQueueItem`) specifically because it
  is produced by **two** different callers — the attended "Resume now"
  action and the unattended queue executor — and both need to render the
  identical fields; giving it one name at the shared root avoids duplicating
  the shape or making one caller depend on the other's model.
- **`ResumeQueueItem`** (lives in the `queue/` subdomain — used only there)
  — `id` (app-generated), `sessionId`, `cwd`, `prompt`, `maxBudgetUsd`
  (required, no nullable "unlimited" path), `forkSession` (bool, defaults
  `true` for anything created via auto-execute, `false` only when created
  via the attended "Resume now" action), `status`
  (`pending | running | succeeded | failed`), `createdAt`, `executedAt`,
  `result` (nullable `ResumeOutcome`).
- **`ScheduledResume`** (M3, lives in the `scheduler/` subdomain — used only
  there) — `queueItemId` (a plain `String` ID, not a typed reference to
  `ResumeQueueItem` — the same loose, by-ID coupling `ResumeQueueItem.sessionId`
  already uses toward `ClaudeSession`, so `scheduler/` never imports `queue/`'s
  domain model), `targetAt` (`DateTime`), `basis`
  (`quotaReset | fixedTime` — for provenance/debugging, not behavior),
  `status`.
- **New `FailureCode` values** (extending the existing 11-value enum, not
  replacing it): `sessionNotFound` (returned by `SessionRepository.readSession()`
  when the underlying file has been deleted/moved between list load and open
  — exercised in M1, §21 Feature 1.2.2), `workingDirectoryMissing` (returned
  when a queue item's stored `cwd` no longer exists at execution time — design
  principle 2, exercised in M2, §21 Feature 2.2.2), and `budgetCapRequired`.
  `budgetCapRequired` is **not** what the constructor throws — the
  `ResumeQueueItem` constructor mirrors `AppSettings` and throws
  `ArgumentError` synchronously, the same as today, for the enqueue path.
  It is the return value for a distinct call site the constructor guard
  cannot cover: `ResumeQueueRepository` reading a previously-stored item back
  from `SharedPreferences` that turns out to be missing a cap (e.g. written
  by an older build). See §9 for the read-path behavior this failure code
  supports.

## 9. Repository Architecture

Three new repository ports, each modeled directly on an existing one:

| New port | Module home (§7) | Modeled on | Storage |
| --- | --- | --- | --- |
| `SessionRepository` (`listSessions()`, `readSession(id)`, `refreshIndex()`) | `sessions/` root — shared by `browser/` and `detail/` | `UsageRepository`'s read/stream shape | None owned — reads JSONL live each call; `refreshIndex()` re-scans the directory tree |
| `ResumeQueueRepository` (`list()`, `enqueue()`, `updateStatus()`, `remove()`) | `sessions/queue/` | `SettingsRepository`'s read/write shape | `SharedPreferences`, one JSON array under a new key, capped at a fixed size (e.g. 50 items — oldest completed items evicted first) |
| `ScheduleRepository` (M3) | `sessions/scheduler/` | Same shape as above | `SharedPreferences`, similarly bounded |

`SessionRepository` deliberately owns no cache of its own — it is a read
projection over the CLI's own files, consistent with design principle 3
(JSONL is the source of truth). This sidesteps the "does the cache go stale
relative to the CLI" question entirely: there is no cache to go stale.

**Stored-data edge cases, stated explicitly rather than left implicit:**

- **Malformed stored queue/schedule item on read** (e.g. an item written by
  an older build, missing a field a newer build requires — concretely,
  `maxBudgetUsd`): `ResumeQueueRepository`/`ScheduleRepository` skip that one
  item and log a warning, the same tolerate-and-degrade discipline
  `UsageParser` already applies to CLI output (design principle 3) — they do
  not fail the whole `list()` call, and they do not fall back to a
  reconstructed default the way `SharedPreferencesSettingsRepository` does
  for settings (there is no sane default for a missing budget cap). This is
  the read-path use of `FailureCode.budgetCapRequired` (§8) — distinct from
  the constructor-level `ArgumentError` that guards the enqueue path.
- **Bounded list full with nothing eligible to evict** (all items still
  `pending`/`running`, none `succeeded`/`failed` to make room): `enqueue()`
  fails with a visible error rather than silently evicting a pending item a
  user is still waiting on. This is the same fail-fast-and-surface rule
  design principle 2 already applies to a stale `cwd` — applied here to a
  different piece of state this document introduces.
- **New `SharedPreferences` keys follow the existing versioned-prefix
  convention** already used for settings (`settings_v1_`) and the usage
  cache (`usage_lkg_v2_<providerId>`) — e.g. `resume_queue_v1`,
  `schedule_v1` — so a future shape change has the same migration precedent
  v1 already established, rather than inventing a new one.

## 10. Session Architecture

Two-pass parsing, chosen specifically to keep the Browser fast on machines
with a large `~/.claude/projects/` tree:

1. **Index pass** (cheap, runs for every session on every Browser open/
   refresh): enumerate files under `~/.claude/projects/**/*.jsonl`; for each,
   read the directory name (project path), the filename (session id), and
   file stat (mtime, size) — optionally the *first* and *last* line only,
   not the whole file, to get a timestamp range and a rough line count.
   Produces `SessionSummary` for the list view.
2. **Detail pass** (only when a session is opened): stream-parse the full
   file line by line, tolerating malformed/incomplete lines exactly the way
   `UsageParser` tolerates Shape A/B — a bad line is skipped and logged, not
   fatal. Produces `ClaudeSession`.

`agents --json --all` is called once per Browser session-list refresh (not
per file) and merged onto the index pass purely to set `isLive`; a decode
failure or missing field on that call never blocks rendering the JSONL-derived
list (design principle 3).

## 11. Scheduler Architecture

`UsageRepositoryImpl` already contains a correct, sleep/wake-safe scheduling
primitive: a single `Timer`, a generation counter to reject stale fires, and
`recoverScheduleIfOverdue()` to catch up after the process was suspended.
Rather than write a second implementation for Resume Scheduler, M3 extracts
that primitive into `lib/core/scheduling/deadline_scheduler.dart` as a small,
generic "run this closure at this `DateTime`, recover if overdue" utility,
then:

- `UsageRepositoryImpl` is migrated to use it (behavior-preserving —
  existing refresh/backoff tests must keep passing unchanged), proving the
  extraction didn't regress the one consumer that matters today.
- `ScheduleController` becomes the second consumer, scheduling a
  `ResumeQueueItem` execution at a target `DateTime` instead of a fixed
  relative interval.

**Explicit limitation, stated in the UI, not just in this document:**
quota-reset times are parsed from Claude's own free-text usage schema, which
ADR-001 already documents as unstable; and the scheduler only fires while AI
Tray is running — there is no OS-level wake mechanism in v2 (§4). If the
process is asleep or quit when the deadline passes, the fire happens on next
launch via the same "recover if overdue" check `UsageRepositoryImpl` already
uses, not retroactively.

## 12. Notification Architecture

Today, `TrayController.maybeNotify()` constructs a `LocalNotification`
directly and calls `.show()` inline — there is no seam, and (confirmed by
the v1 audit) no notification test exists. v2 introduces a
`NotificationGateway` port:

```
abstract interface class NotificationGateway {
  Future<void> notify({
    required String title,
    required String body,
    void Function()? onClick,
  });
}
```

`IoNotificationGateway` wraps `local_notifier` (using its confirmed `onClick`
callback); a `FakeNotificationGateway` records calls for tests, mirroring
`FakeProcessRunner`. `TrayController.maybeNotify` is migrated to call the
gateway with no behavior change (first story in M2, done before anything
new depends on it). Queue-completion and scheduled-resume-fired
notifications are then just two more callers of the same gateway, each
supplying an `onClick` closure that captures the relevant `sessionId`/`cwd`
at construction time — no payload field is needed because the closure is
created and consumed within the same running process (§ preamble).

## 13. Data Flow

**Read flow (Session Browser, M1) — no external process spawned per item:**
```
SessionBrowserController.refresh()
  -> SessionRepository.listSessions()
    -> SessionFileSystem.enumerate('~/.claude/projects/**/*.jsonl')
    -> JsonlSessionParser.indexPass() per file -> SessionSummary
  -> ClaudeSessionService.listLiveSessions() [`claude agents --json --all`,
     via existing buffered ProcessRunner] -> merge isLive onto summaries
  -> UI list
```

**Act flow (Resume Queue execution, M2):**
```
ResumeQueueController (auto-execute on, or user pressed "run now")
  -> ResumeQueueRepository.next(status: pending)
  -> ClaudeSessionService.resume(item)
    -> ProcessRunner.run('claude',
         ['--resume', item.sessionId, '-p', item.prompt,
          '--output-format', 'json',
          '--max-budget-usd', item.maxBudgetUsd,
          if (item.forkSession) '--fork-session'],
         timeout: resumeTimeout,       // long, explicit — not the 8s default
         workingDirectory: item.cwd)
  -> parse trailing JSON result envelope -> ResumeQueueItem.result
  -> ResumeQueueRepository.updateStatus(succeeded | failed)
  -> NotificationGateway.notify(onClick: () => open session detail)
```

**Schedule flow (M3):** identical to the act flow, except entry into it is
triggered by `DeadlineScheduler` firing instead of the user or auto-execute
loop.

## 14. Storage Strategy

No new storage technology for v2. Justification, not just a preference:

- `SessionRepository` owns no persisted state — JSONL files are the data.
- `ResumeQueueRepository` and `ScheduleRepository` persist small, bounded
  lists (tens of items, not thousands of transcripts) — exactly the shape
  `SharedPreferences` already handles correctly for `AppSettings` and the
  usage LKG cache.
- The one workload that *would* need a real database — cross-session
  aggregate analytics queries — is precisely the workload postponed to v3
  (§4). Introducing `sqflite`/`drift` now, before that workload exists,
  would be new dependency surface with no immediate consumer.

**Explicit revisit trigger:** if v3 Session Analytics needs queries across
the full session history at a scale `SharedPreferences` can't reasonably
serve, that is the point to open an ADR proposing an embedded database — not
before.

## 15. CLI Integration Strategy

No new process abstraction. `ClaudeSessionService` (data layer, alongside
`ClaudeCliAdapter`, not merged into it — a different concern from usage
polling) adds two capabilities, both through the existing `ProcessRunner`
port, both using its existing buffered request/response contract:

| Call | Command | Notes |
| --- | --- | --- |
| Liveness enrichment | `claude agents --json --all [--cwd <path>]` | Buffered; default 8s timeout is fine — this is a metadata listing, not a model turn |
| Resume execution | `claude --resume <id> -p "<prompt>" --output-format json [--max-budget-usd <cap>] [--fork-session] [--fallback-model <list>]` | Buffered — `--output-format json` is a single trailing JSON object, **not** streaming, confirmed in the capability report §3D/§5. Must be called with an explicit, generous timeout (not the 8s default) since a real model turn can run minutes; a timeout still results in `SIGKILL` (§ preamble) — accepted per design principle 4. |

`--output-format stream-json` is intentionally not used anywhere in v2
(§4) — nothing in the recommended scope needs progressive output, so no
streaming variant of `ProcessRunner` is built. If a future milestone needs
live output, that is new work, not a v2 dependency.

## 16. Required ADRs

Numbered from ADR-005 (existing: ADR-001..004). Product decisions numbered
from the next available `PD-` id per `docs/project/DECISION_LOG.md`
convention — this document proposes their content; it does not edit that
file.

- **ADR-005 — Claude session data is JSONL-sourced, not app-persisted.**
  Records §9/§14: no session database, `SessionRepository` is a read
  projection, `agents --json` is enrichment-only.
- **ADR-006 — Resume execution safety model.** Records design principle 2 in
  full: mandatory budget cap, fork-by-default for unattended execution,
  explicit auto-execute opt-in, stale-`cwd` fail-fast, no `project purge`
  exposure, accepted timeout/`SIGKILL` semantics with no v2 cancellation.
- **ADR-007 — Scheduler is app-resident, not OS-level, in v2.** Records §11's
  explicit reliability limitation and the extraction of
  `DeadlineScheduler` from `UsageRepositoryImpl`.
- **ADR-008 — Sessions is one bounded-context feature, not three independent
  top-level features.** Records §7's revised module structure: Browser,
  Detail, Resume, Queue, and Scheduler are subdomains of
  `features/sessions/`, following the same internal-subdomain *shape* as
  `features/providers/` — explicitly not its alias/re-export layer, which
  ADR-004 already identifies as debt (§7 states this distinction directly).
  `DeadlineScheduler` and `NotificationGateway` stay in `core/` because they
  are cross-cutting, not Sessions-specific.
- **ADR-009 — Session/resume functionality remains Claude-only; a provider
  abstraction is deferred, not rejected.** Records §6.1 in full: no
  `SessionProvider` port is introduced in v2 because exactly one confirmed
  implementation exists; the named trigger for revisiting is a second CLI's
  session/resume/transcript surface being researched to the same depth as
  the existing Claude capability report *and* a second implementation
  actually being built.
- **ADR-010 — AI Tray is an orchestration companion.** The highest-level
  product-positioning guardrail, applying to every future feature, not just
  v2: AI Tray orchestrates official AI CLIs (today: Claude Code, via the
  process/CLI adapters this document and ADR-001 describe) — it is not a
  chat client, not an IDE, and does not replace Claude Code itself. It does
  not duplicate a provider's own UI (a session's content is summarized, not
  rendered as a full conversation view — §1's non-goals). It extends
  existing AI workflows (see sessions, resume, quota) rather than competing
  with them or recreating them inside AI Tray. Every future feature proposal
  should be checked against this before being checked against anything else
  in this document: if a proposal makes AI Tray *replace* a CLI's own
  interface rather than *orchestrate* it, that is a reason to reject or
  reframe it, independent of engineering cost. This formalizes what §1
  already states as product vision and non-goals.
- **Proposed PD entries** (content only, for `DECISION_LOG.md` when this
  scope is approved): v2 is a session-workflow companion, not a chat client
  (§1, ADR-010); no generic workflow-automation engine is built (§3);
  session/resume features remain Claude-only until another provider
  publishes an equivalent CLI surface (§3).

## 17. Testing Strategy

Extends, not replaces, the existing convention (fakes over mocks, fixtures
for external-format drift, tag-excluded goldens):

- **`FakeSessionFileSystem`** and a new `test/fixtures/claude_sessions/`
  directory (mirroring `test/fixtures/claude_usage/`): valid multi-message
  transcripts, an empty file, a file with one malformed JSON line mid-stream,
  and a file that ends abruptly mid-turn (simulating a killed resume) — the
  parser must handle all four without throwing.
- **`FakeNotificationGateway`** records `notify()` calls and lets tests
  assert an `onClick` was supplied and does what's expected, without a real
  OS notification center — closing the gap the v1 audit found (no
  notification tests exist today).
- **Resume Queue tests**: budget-cap-required constructor validation (mirrors
  `AppSettings`'s existing `ArgumentError` pattern), fork-default logic for
  auto-execute vs. attended runs, bounded-list eviction behavior, and
  stale-`cwd` fail-fast behavior — all achievable with `FakeProcessRunner` and
  an in-memory queue repository, no real CLI needed.
- **Scheduler tests**: migrate `UsageRepositoryImpl`'s existing timer/backoff/
  `recoverScheduleIfOverdue` tests to run against the extracted
  `DeadlineScheduler` directly, then add the same suite against
  `ScheduleController` — proving the extraction is behavior-preserving is a
  release gate for M3, not optional cleanup.
- All new tests run on the existing Ubuntu-only `quality.yml` — none of this
  needs a macOS/Windows runner, since there is no new native plugin.

## 18. Documentation Changes

- New `docs/architecture/session-platform.md` describing §6–§15 for future
  contributors (parallel to the existing `docs/architecture/*` files),
  including the Sessions bounded-context module layout (§7).
- ADR-005 through ADR-010 added to `docs/adr/`, indexed in
  `docs/adr/README.md`.
- `docs/project/ROADMAP.md`, `ARCHITECTURE_STATE.md`, and `PRODUCT_STATE.md`
  updated once this scope is approved and M1 starts (not before — per the
  handoff package's own rule against claiming work that hasn't happened).
- `docs/project/DECISION_LOG.md` gets the PD entries from §16 once approved.
- A new `docs/guides/session-workflows.md` (parallel to
  `docs/guides/user-guide.md`) documenting Browser/Queue/Scheduler for end
  users, written after M1/M2 ship, not speculatively now.

## 19. CI/CD Changes

Minimal — this scope introduces no new native dependency, no new build
target, and no new external SDK:

- New fixture directory (`test/fixtures/claude_sessions/`) needs no new CI
  job; it runs inside the existing `flutter test --exclude-tags
  golden,screenshot` step in `quality.yml`.
- New Session Browser UI gets goldens tagged `golden`, consistent with the
  existing exclude-from-PR convention — no change to `quality.yml`'s
  structure.
- No change to `release.yml`, `maintenance.yml`, or
  `reusable-flutter-web-demo.yml` is implied by this scope.
- If ADR-005 through ADR-010 are added, `documentation.yml`'s relative-link
  check already covers `docs/adr/` — no workflow edit needed, just correct
  cross-links.

## 20. Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| `agents --json` field names differ from what a populated result actually contains (only `[]` was observed) | JSONL is the primary source; liveness is enrichment-only and degrades silently (design principle 3) |
| Unattended resume spends money or acts without oversight | Mandatory budget cap + fork-by-default for unattended runs + explicit auto-execute opt-in (design principle 2, ADR-006) |
| A killed process (timeout) leaves a partial JSONL file | Treated as an expected state, not corruption; Browser renders incomplete sessions honestly (design principle 4) |
| Scheduler doesn't fire because the machine slept or AI Tray was quit | Stated as a known limitation in the UI itself, not just documentation; `recoverScheduleIfOverdue`-style catch-up on next launch (§11) |
| Stored `cwd` no longer exists at execution time | Fail fast with a visible error; never create directories or guess a substitute (design principle 2) |
| Scope creep toward a general automation engine | Explicitly rejected in §3/§4 as a product decision (PD entry), not left as an implicit boundary |
| "Session Repository" is read as "we need a database" | ADR-005 records the JSONL-as-source-of-truth decision explicitly, with a stated revisit trigger (§14) |
| New `NotificationGateway` seam becomes a fourth ad hoc I/O pattern instead of a consistent one | Modeled directly on the existing `ProcessRunner` port+fake convention, not invented fresh |

---

## 21. Execution Roadmap

Three milestones, gated in sequence. M2 does not start design work until M1
has shipped; M3 does not start until M2 has real usage evidence (§ "Next
milestone" logic from the prior status report §17.3 applies here too — don't
build the scheduler on a queue nobody has used yet).

### Milestone 1 — Session Visibility (read-only)

**Goal:** Users can see their Claude session history inside AI Tray. No
mutation, no cost, no safety surface to design — this milestone exists to
de-risk filesystem access and JSONL parsing in isolation.

#### Epic 1.1 — Session Data Access

**Feature 1.1.1 — Session File System Port**

- **Story: Define `SessionFileSystem` port + fake**
  - Goal: A testable seam for enumerating/reading files under
    `~/.claude/projects/`, mirroring `ProcessRunner`'s port+fake shape.
  - Dependencies: none.
  - Complexity: S
  - Risks: none material — this is a narrow interface.
  - Acceptance criteria: port compiles with no production implementation
    yet; `FakeSessionFileSystem` supports injecting an in-memory directory
    tree for tests.

- **Story: Implement production FS reader**
  - Goal: `IoSessionFileSystem` walks `~/.claude/projects/**/*.jsonl` and
    exposes file metadata (path, mtime, size) plus a line reader.
  - Dependencies: previous story.
  - Complexity: M
  - Risks: path-decoding edge cases (the capability report notes `/` is
    replaced by `-` in directory names — reversing that mapping cleanly for
    display needs care, especially for project paths that themselves contain
    `-`).
  - Acceptance criteria: correctly enumerates a real `~/.claude/projects/`
    tree on a dev machine; unit-tested against `FakeSessionFileSystem`'s
    in-memory tree for the reversible-path-decoding edge case.

**Feature 1.1.2 — JSONL Session Parser**

- **Story: Index-pass parser**
  - Goal: Produce `SessionSummary` from file metadata + first/last line only
    (no full-file parse), per §10.
  - Dependencies: Feature 1.1.1.
  - Complexity: M
  - Risks: "last line" isn't always the most recent event if a file was
    truncated mid-write — acceptable per design principle 4, must not throw.
  - Acceptance criteria: builds a correct summary list against fixture files
    including a truncated one, without parsing full file contents (verified
    by a test asserting the parser doesn't read past a bounded byte window
    for the index pass).

- **Story: Full-transcript lazy parser**
  - Goal: Produce `ClaudeSession` (message count, model, git branch, token
    totals) only when a session is opened.
  - Dependencies: previous story.
  - Complexity: L
  - Risks: schema drift across CLI versions (explicitly flagged as
    unconfirmed in the capability report for several fields) — must follow
    `UsageParser`'s tolerate-and-degrade discipline, not throw on an
    unexpected field.
  - Acceptance criteria: correctly parses a full valid transcript fixture;
    degrades (returns partial `ClaudeSession` with `isComplete: false`, not
    an exception) on a malformed-line fixture and a mid-turn-truncated
    fixture.

- **Story: Fixture-based resilience test suite**
  - Goal: Lock in parser tolerance behavior as regression tests.
  - Dependencies: previous two stories.
  - Complexity: M
  - Risks: none material.
  - Acceptance criteria: `test/fixtures/claude_sessions/` contains the four
    fixture types listed in §17; each has a corresponding assertion.

**Feature 1.1.3 — Live Session Enrichment**

- **Story: `agents --json --all` adapter method**
  - Goal: `ClaudeSessionService.listLiveSessions()` via existing
    `ProcessRunner`, default timeout.
  - Dependencies: none (parallel to Feature 1.1.1/1.1.2).
  - Complexity: S
  - Risks: populated-result field names are unconfirmed (§ preamble) — must
    be defensive on shape, matching design principle 3.
  - Acceptance criteria: returns `null`/empty gracefully on any decode
    failure; never throws into the caller.

- **Story: Merge liveness onto the summary list**
  - Goal: Combine Feature 1.1.2's index pass with Feature 1.1.3's liveness
    call into one `SessionBrowserController` result.
  - Dependencies: both previous features.
  - Complexity: M
  - Risks: none beyond what's already listed above.
  - Acceptance criteria: list renders fully and correctly with the
    liveness call stubbed to fail/return unexpected shape (test asserts no
    regression to the base list).

#### Epic 1.2 — Session Browser UI

**Feature 1.2.1 — Session List Page**

- **Story: `SessionBrowserController` + list UI**
  - Goal: `AsyncNotifier`-based controller (same shape as
    `SettingsNotifier`/`ThemeController`) driving a list page built from
    existing `core/components/`.
  - Dependencies: Epic 1.1 complete.
  - Complexity: M
  - Risks: none material — this is UI composition over already-tested data.
  - Acceptance criteria: widget test renders a populated list from fixture
    data; empty-state renders when no sessions exist (reusing the existing
    `tray_empty_state.dart` pattern).

- **Story: Search/filter by project path**
  - Goal: Client-side filter over the loaded summary list.
  - Dependencies: previous story.
  - Complexity: S
  - Risks: none.
  - Acceptance criteria: typing a filter narrows the visible list; clearing
    it restores the full list.

**Feature 1.2.2 — Session Detail View**

- **Story: Detail page**
  - Goal: Render `ClaudeSession` (message count, model, last activity, git
    branch).
  - Dependencies: Feature 1.1.2 (full parser).
  - Complexity: M
  - Risks: the session file can be deleted or moved between the Browser's
    list load and the user opening it (a real race, not hypothetical —
    `claude project purge` or ordinary cleanup can remove a transcript at
    any time).
  - Acceptance criteria: widget test renders detail for a complete fixture
    session; a second test confirms `SessionRepository.readSession()` for a
    now-missing file returns `FailureCode.sessionNotFound` and the detail
    page renders a clear "session no longer available" state instead of
    throwing — this is the acceptance criterion that exercises
    `sessionNotFound` (§8), which no other story in this roadmap covers.

- **Story: Graceful incomplete-session rendering**
  - Goal: Detail page visibly (not silently) indicates `isComplete: false`
    sessions per design principle 4.
  - Dependencies: previous story.
  - Complexity: S
  - Risks: none.
  - Acceptance criteria: widget test asserts the incomplete-state indicator
    renders for the truncated fixture.

**M1 exit criteria:** Session Browser ships to `main` behind normal Quality
CI gates, with no mutation capability anywhere in the shipped code — this is
independently verifiable by grep (no `--resume`, no write calls) as a release
check.

---

### Milestone 2 — Manual Resume + Better Notifications (gated on M1 shipped)

**Goal:** Introduce the first mutating capability, with the safety model
from design principle 2 enforced from the first line of code, not bolted on
after.

**What "gated on M1 shipped" actually gates:** the reason for the gate is
sequencing risk — validate the read-only session/JSONL work in isolation
(M1) before building anything that mutates a session on top of it (§2,
design principle 6). That reasoning applies to Epic 2.2 (Manual Resume,
Resume Queue) and Epic 2.3 (notifications *about* resume outcomes) — both
touch session mutation directly or depend on something that does. It does
not apply to Epic 2.1 below, which is why that epic's own dependency line
differs from the milestone-level gate; see its note.

#### Epic 2.1 — Notification Gateway (built first — both Queue and later Scheduler depend on it)

**Feature 2.1.1 — Notification Gateway Port**

- **Story: Define `NotificationGateway` port + fake**
  - Goal: Per §12 — port wrapping `local_notifier`, `FakeNotificationGateway`
    for tests.
  - Dependencies: none. **This is a deliberate, narrow exception to "gated
    on M1 shipped":** this story touches neither session reading nor session
    mutation — it wraps `TrayController.maybeNotify`, an already-shipped v1
    code path that has zero notification test coverage today (a real,
    present gap, not a speculative future one). It may start any time. Do
    not read this as "infrastructure work may generally start early" — Epic
    3.1 below is the counter-example where the same-sounding argument does
    *not* hold.
  - Complexity: S
  - Risks: confirm `onClick` behaves identically on both macOS and Windows
    builds of `local_notifier` — the capability check in this document's
    preamble was doc-based, not a live dual-platform test.
  - Acceptance criteria: port + fake compile and are unit-tested; a manual
    dogfood note is added to `docs/dogfood/` to verify `onClick` fires on a
    real macOS notification (Windows verification tracked separately, since
    Windows remains Experimental per existing product state).

- **Story: Migrate `TrayController.maybeNotify` to the gateway**
  - Goal: Zero behavior change — existing threshold-notification tests must
    keep passing unmodified.
  - Dependencies: previous story.
  - Complexity: S
  - Risks: regression in existing notification behavior if the migration is
    not behavior-preserving.
  - Acceptance criteria: existing `TrayController` tests pass unchanged;
    new test confirms the gateway is called with the same title/body as
    before.

#### Epic 2.2 — Resume Execution

**Feature 2.2.1 — Manual Resume Action**

- **Story: `ClaudeSessionService.resume()`**
  - Goal: Buffered `ProcessRunner` call per §15's table, with an explicit,
    generous timeout parameter (not the 8s default) and parsing of the
    trailing JSON result envelope.
  - Dependencies: M1's `ClaudeSessionService` foundation (Feature 1.1.3).
  - Complexity: M
  - Risks: the SIGKILL-on-timeout behavior (§ preamble) must be an accepted,
    tested outcome, not an unhandled exception — test explicitly for a
    timeout producing a clean `failure` result, not a crash.
  - Acceptance criteria: `FakeProcessRunner`-backed test confirms a
    successful resume parses cost/tokens/turns/result correctly, and a
    simulated timeout produces a handled failure, not an uncaught exception.

- **Story: "Resume now" wired from Session Detail**
  - Goal: Attended, continue-in-place-by-default resume action in the UI.
  - Dependencies: previous story, Feature 1.2.2.
  - Complexity: M
  - Risks: none beyond what's already covered.
  - Acceptance criteria: widget test drives the action against a fake
    service and asserts the result renders.

- **Story: Result surfaced in-app**
  - Goal: Show cost/tokens/turns/stop-reason after a manual resume.
  - Dependencies: previous story.
  - Complexity: S
  - Risks: none.
  - Acceptance criteria: widget test asserts all four fields render.

**Feature 2.2.2 — Resume Queue**

- **Story: `ResumeQueueItem` model + bounded repository**
  - Goal: Per §8/§9 — constructor-level budget-cap-required validation
    (mirrors `AppSettings`'s pattern), `SharedPreferences`-backed bounded
    list.
  - Dependencies: Epic 2.1 not required yet (notifications come later in
    this feature); Feature 2.2.1's service.
  - Complexity: M
  - Risks: eviction-policy correctness under concurrent writes — mitigate by
    reusing the same "read-modify-write full list" pattern already proven in
    `SharedPreferencesSettingsRepository`.
  - Acceptance criteria: constructing an item without a budget cap throws
    `ArgumentError` (test asserts this explicitly, matching design
    principle 2); list caps at the configured size, evicting oldest
    completed items first.

- **Story: Enqueue from Session Detail**
  - Goal: UI to add a session + prompt + budget cap to the queue.
  - Dependencies: previous story.
  - Complexity: M
  - Risks: none beyond form-validation UX.
  - Acceptance criteria: widget test confirms the form will not submit
    without a budget cap value.

- **Story: Sequential executor**
  - Goal: Reuses `RefreshService`'s single-flight coalescing shape (one
    item executing at a time), defaults `forkSession: true` for
    auto-executed items, `false` only for attended manual runs (design
    principle 2).
  - Dependencies: previous two stories, Feature 2.2.1.
  - Complexity: L
  - Risks: this is the story where the safety model (mandatory cap,
    fork-default, stale-`cwd` fail-fast) all has to compose correctly —
    highest-risk story in the milestone.
  - Acceptance criteria: test suite covers (a) fork defaults correctly by
    execution mode, (b) stale `cwd` fails fast without side effects, (c)
    only one item executes at a time even if auto-execute is triggered
    twice concurrently.

- **Story: Queue UI**
  - Goal: Render pending/running/succeeded/failed items.
  - Dependencies: previous story.
  - Complexity: M
  - Risks: none.
  - Acceptance criteria: widget test renders one item of each status.

#### Epic 2.3 — Click-to-Resume Notifications

**Feature 2.3.1 — Queue-Completion Notifications**

- **Story: Notify on queue item completion**
  - Goal: `NotificationGateway.notify()` call with an `onClick` closure
    capturing the completed item's session id, opening its detail/result
    view.
  - Dependencies: Epic 2.1, Feature 2.2.2's executor.
  - Complexity: M
  - Risks: none beyond the dual-platform `onClick` verification already
    tracked in Epic 2.1.
  - Acceptance criteria: `FakeNotificationGateway`-backed test asserts
    `onClick` is supplied and, when invoked, navigates to the correct
    session.

- **Story: Manual dogfood checklist entry**
  - Goal: Add a Resume Queue notification click-through check to the
    existing macOS dogfood checklist (`docs/dogfood/POST_EP002_MACOS_ARM64.md`
    pattern).
  - Dependencies: previous story.
  - Complexity: S
  - Risks: none.
  - Acceptance criteria: checklist entry exists and has been executed once
    before M2 is declared shipped.

**M2 exit criteria:** Manual resume and queued/auto-executed resume both
ship with the full safety model (mandatory cap, fork-default, stale-`cwd`
fail-fast, no `project purge` exposure) enforced and tested — not partially.
Click-to-resume notifications work on at least macOS (primary supported
target).

---

### Milestone 3 — Resume Scheduler (gated on M2 real usage evidence — do not start on a timer)

**Goal:** Let a queued item fire automatically at a target time (typically a
quota reset), reusing the scheduling primitive already proven in
`UsageRepositoryImpl`.

#### Epic 3.1 — Scheduling Primitive Extraction

**Feature 3.1.1 — `DeadlineScheduler`**

- **Story: Extract Timer/generation/`recoverIfOverdue` into `core/scheduling/`**
  - Goal: Behavior-preserving extraction of the exact logic already in
    `UsageRepositoryImpl._reschedule`/`recoverScheduleIfOverdue`.
  - Dependencies: **the same M3 gate as Epic 3.2 — real M2 usage evidence,
    not merely "M2 has shipped."** An earlier draft of this story said the
    extraction could start "independent of Epic 3.2" once M2 shipped. That
    was wrong on this document's own terms: `UsageRepositoryImpl`'s existing
    scheduling already works correctly without this extraction, so the
    extraction's only justification is enabling a second consumer
    (`ScheduleController`) whose existence is explicitly evidence-gated —
    generalizing a primitive for an unconfirmed second consumer is exactly
    the premature-abstraction pattern §6.1 and §14 reject elsewhere in this
    document. (Contrast with Epic 2.1, which has an independent, already-real
    justification and is correctly allowed to start early.)
  - Complexity: M
  - Risks: regressing the one working consumer (`UsageRepositoryImpl`) —
    mitigated by the next story being a hard gate.
  - Acceptance criteria: new utility has its own unit tests covering
    fire-on-deadline, generation-token staleness rejection, and
    recover-if-overdue, independent of `UsageRepositoryImpl`.

- **Story: Migrate `UsageRepositoryImpl` to use it**
  - Goal: Zero behavior change to usage refresh scheduling.
  - Dependencies: previous story.
  - Complexity: M
  - Risks: this is the release gate for the whole milestone — a regression
    here affects the v1 feature every user already depends on.
  - Acceptance criteria: **all existing `test/unit/repository/usage_repository_test.dart`
    and `test/unit/stability/long_running_refresh_test.dart` tests pass
    unmodified.** This is a hard requirement, not a nice-to-have.

#### Epic 3.2 — Resume at Quota Reset

**Feature 3.2.1 — Scheduled Queue Items**

- **Story: Schedule a queue item against a target `DateTime`**
  - Goal: UI to pick a queued item and a target time (pre-filled from the
    dashboard's own best-effort reset time).
  - Dependencies: Epic 3.1, Milestone 2 complete.
  - Complexity: M
  - Risks: reset-time accuracy is inherently best-effort (ADR-001) — must be
    stated in the picker UI itself, not just this document.
  - Acceptance criteria: widget test confirms the UI surfaces the
    best-effort caveat text; scheduling persists a `ScheduledResume` record.

- **Story: Fire via `DeadlineScheduler`**
  - Goal: When the deadline passes and AI Tray is running, execute the
    linked queue item through the same executor built in M2 — no separate
    execution path.
  - Dependencies: previous story, Feature 2.2.2's executor.
  - Complexity: M
  - Risks: `ScheduledResume.queueItemId` can point at a `ResumeQueueItem`
    that no longer exists by the time the deadline fires (the user removed
    it, or it was evicted from the bounded list) — an orphaned reference
    this document had not previously addressed.
  - Acceptance criteria: test confirms a scheduled item fires exactly once
    at its deadline and once more on "overdue recovery" if the deadline
    passed while the fake clock was "asleep," matching
    `recoverScheduleIfOverdue`'s existing contract; a second test confirms
    that when `queueItemId` no longer resolves to a stored item, the
    `ScheduledResume` is marked failed with a visible reason and no
    execution is attempted — the same fail-fast-and-surface rule design
    principle 2 already applies to a stale `cwd` (§9), applied here to a
    stale queue-item reference.

**M3 exit criteria:** Scheduled resume reuses `DeadlineScheduler` and the M2
executor with no new execution path; the UI states the reliability
limitation explicitly; `UsageRepositoryImpl`'s existing test suite is
unmodified in outcome.

---

## Final Architecture Validation

A pass over the whole document (not a rewrite) checking eight specific
failure modes. Where a genuine issue was found, it was fixed in this
revision — the list below states the finding *and* the fix, not just the
finding.

**Duplicated responsibilities.** Checked every new class against every
other for overlapping purpose (`ClaudeCliAdapter` vs. `ClaudeSessionService`;
`SessionRepository` vs. `ResumeQueueRepository` vs. `ScheduleRepository`;
the two-pass parser's index vs. detail pass). None found — each owns a
distinct concern, and where two callers need the same shape
(`ResumeOutcome`, needed by both manual resume and Queue), it is named once
rather than duplicated. No fix needed.

**Unnecessary abstractions.** Checked `SessionFileSystem`, `ResumeOutcome`,
and `NotificationGateway` for a real justification beyond "matches an
existing pattern." All three have one: `SessionFileSystem` and
`NotificationGateway` exist because their production code needs fixture/fake
testability the way `ProcessRunner` already does; `ResumeOutcome` exists
because two real callers need the identical shape today, not speculatively.
No fix needed here — but this check is what caught the two premature-
abstraction issues listed under "milestone dependency issues" below.

**Circular dependencies.** Found and fixed: §7's own placement rule ("shared
code lives at the `sessions/` root") was violated by the tree it described —
`SessionSummary`, `ClaudeSession`, and `ResumeOutcome` were shown living
inside `browser/`, `detail/`, and `resume/` respectively, while the
root-level `SessionRepository` and `ClaudeSessionService` returned them,
which would have forced the root to import from three subdomains. Fixed by
moving all three models to `sessions/domain/models/` at the root (§7, §8).
No true Dart-level import cycle existed, but the dependency direction was
backwards relative to the document's own stated rule — worth fixing on
those terms regardless.

**Hidden technical debt.** Found and fixed three cases where new state
introduced a decision this document hadn't stated, each resolved with the
same fail-fast-and-surface pattern already established for stale `cwd`
(design principle 2): a bounded queue full of only pending/running items
with nothing eligible to evict (§9), a `ScheduledResume` whose linked
`ResumeQueueItem` no longer exists by the time its deadline fires (§21,
Epic 3.2), and a stored queue/schedule item deserialized from an older
build missing a now-required field (§9, using the previously-unused
`FailureCode.budgetCapRequired`). Also added: new `SharedPreferences` keys
follow the existing `_v1_`-style versioning convention rather than inventing
one (§9).

**Milestone dependency issues.** Found and fixed two gating
inconsistencies, both in §21: Epic 2.1's story said it could start "in
parallel with M1's late stories," which reads as a contradiction of the
Milestone 2 header's "gated on M1 shipped" until the actual reason for that
gate is stated precisely — it exists to sequence session-*mutating* work
after session-*reading* work is validated, and Epic 2.1 (a pure refactor of
an already-shipped, already-untested v1 notification path) touches neither.
That reasoning does not transfer to Epic 3.1, which originally claimed it
could start "independent of Epic 3.2" — but `UsageRepositoryImpl`'s
scheduling already works without the extraction, so extracting a
generalized primitive early would be generalizing for a second consumer
this document itself gates on unconfirmed evidence, the exact pattern §6.1
and §14 reject. Epic 3.1 is now gated identically to Epic 3.2. Both fixes
are stated in place in §21 with the reasoning, not just the corrected
dependency line, so a future reader doesn't reapply the wrong pattern to
the other epic.

**Conflicting ADRs.** Checked ADR-005 through ADR-010 against ADR-001..004
for contradiction, not just topic overlap. Found one point needing
clarification rather than a true conflict: ADR-008 cites `features/providers/`'s
internal-subdomain structure as precedent, and ADR-004 separately identifies
`providers/`'s ~35 compatibility re-export files as debt — read carelessly,
ADR-008 could look like it's repeating what ADR-004 is cleaning up. Fixed by
stating explicitly, in both §7 and ADR-008's entry, that Sessions borrows the
subdomain *shape* and has no equivalent alias/re-export layer. No other ADR
conflicts found; ADR-009's deferral is stated as consistent with, not a
reversal of, ADR-003.

**Implementation gaps.** Beyond the technical-debt items above: confirmed
every `FailureCode` value introduced in §8 now has a named producer and a
named consumer. `sessionNotFound` had neither before this pass (fixed —
§21, Feature 1.2.2). `workingDirectoryMissing` was already exercised
(Feature 2.2.2's "Sequential executor"). `budgetCapRequired` had a producer
implied but no distinct call site named (fixed — clarified as the read-path
failure, distinct from the constructor's `ArgumentError`, in §8 and §9).

**Missing acceptance criteria.** The `sessionNotFound` gap above was the one
substantive miss; every other story already had a testable, specific
acceptance criterion (checked against: does it name what's asserted, not
just "works correctly").

**Conclusion:** the issues found above were structural inconsistencies
between this document's stated rules and its own detail — exactly the kind
of thing a bounded-context restructuring and a milestone-gated roadmap are
prone to when written across multiple passes — and all of them are now
fixed in place, not merely noted. No issue found rose to a flaw in the
underlying decisions locked in the brief's "final recommendation" (Sessions
as one bounded context, Browser-first, JSONL as source of truth, no
database, no streaming port, the resume safety model, evidence-gated
Scheduler, Claude-only until a second CLI surface is confirmed, workspace
dashboard deferred). **This document is architecture-complete and
implementation-ready.**

---

## Final Answers

### What should NOT be built in v2?

- A general workflow-automation engine (rules, triggers, macros beyond
  queue+schedule+notify).
- A full Session Analytics dashboard — there's no data to analyze yet, and
  building it now front-loads UI work onto a feature with no users.
- Any new database technology — nothing in v2's actual scope needs one
  (§14).
- True OS-level wake scheduling — the app-resident scheduler with an honest
  reliability caveat is the right amount of engineering for the evidence
  available today.
- Cooperative cancellation of a running resume — timeout-then-kill is the
  accepted v2 answer; real cancellation is separate work with its own design
  space (SIGINT semantics, partial-result handling).
- Multi-provider session/resume support, **and no `SessionProvider`
  abstraction built in anticipation of it** — no second CLI (Gemini, Codex,
  Cursor, Aider) has a confirmed resume/session/transcript surface to design
  an interface against (§6.1, ADR-009), the same blocker pattern PD-023
  already applies to Cursor as a usage provider.
- Any UI path that can invoke `claude project purge`.

### What belongs in v3?

- Full Session Analytics (token/cost trends, charts) — once M1/M2 have
  produced real session and queue-result data to analyze.
- OS-level wake scheduling — if M3's app-resident scheduler proves
  insufficient in practice.
- Real cancellation of an in-flight resume.
- Reconsidering an embedded database — only if v3 analytics needs
  aggregate queries `SharedPreferences` genuinely can't serve (§14's
  explicit revisit trigger).
- Multi-provider session support — if and when a second provider publishes
  an equivalent resume/session/transcript surface, per ADR-009's named
  trigger (§6.1, §16).
- **A workspace-centric dashboard** (project → active sessions, queued
  resumes, quota status, recent activity, resume shortcuts, per §1.1) — a
  plausible convergence point once Browser/Queue/Scheduler have real usage
  to design against, and distinct from Session Analytics (this is a
  present-state operational view, not a historical/trend view).

### What architectural mistakes should be avoided?

- **Building a session database before there's a workload that needs one.**
  This is the single biggest mistake the original v2 idea list risked —
  "Session Repository" reads as "add a database," and nothing in the actual
  user journeys requires one.
- **Treating `agents --json`'s unconfirmed field names as load-bearing.**
  Anything that breaks the Browser if that call's shape is slightly
  different than expected is a design bug, not bad luck — design principle
  3 exists specifically to prevent this.
- **Adding a streaming process port before anything needs streaming.**
  `--output-format json` is buffered and sufficient for every M1–M3 journey;
  building a streaming `ProcessRunner` variant now would be speculative
  infrastructure with no consumer.
- **Letting unattended execution inherit the 8-second default timeout, or
  skip the budget cap, "just for now."** Both are exactly the kind of
  shortcut that turns into a real incident (runaway cost, or a resume that
  silently fails every time because it's killed before the CLI can respond)
  — both are explicit acceptance criteria in M2, not follow-up hardening.
- **Building Resume Scheduler before Resume Queue has any real usage** —
  scheduling on top of a feature nobody has validated is speculative effort
  in the riskiest, most failure-prone part of the design (background
  execution while unattended).
- **Introducing a `SessionProvider` abstraction for Gemini/Codex/Cursor/Aider
  before any of them has a confirmed resume/session surface** (§6.1) — the
  same category of mistake as building a database before there's a
  workload: an interface designed against zero real second implementations
  is a guess, and ADR-003's own abstraction was only trustworthy because it
  had two concrete implementations to validate against from the start.

### What are the highest-ROI features?

1. **Session Browser (M1)** — highest value-to-effort ratio in the whole
   plan: it's the one feature every other idea depends on, it's read-only
   (no safety design needed), and it reuses `ProcessRunner` + the existing
   design system almost entirely as-is.
2. **Click-to-resume notifications (M2, Epic 2.3)** — smallest unit of new
   work in the entire roadmap (one confirmed-available callback on an
   existing dependency) for a feature that directly answers "why does this
   app need to exist" (you get pinged and one click gets you back to work).
3. **Resume Queue with mandatory budget caps (M2, Epic 2.2)** — the feature
   that actually differentiates "workflow companion" from "usage monitor,"
   and its core mechanics (single-flight, bounded persisted list) are
   already proven patterns in this codebase, not new engineering risk.

### If this were an open-source project, what roadmap would this be?

Exactly the three milestones above, released independently rather than as
one v2 branch — Session Browser (M1) as its own tagged release the moment
it's done, since it's genuinely useful standalone and has zero safety
surface to get right before shipping. That also produces the real usage
signal the gating logic for M2→M3 depends on, instead of assuming it. The
"mutating" milestone (M2) would get the most review scrutiny of any change
in the project's history so far — it's the first feature that spends the
user's money and acts on their behalf — and would ship with the safety
model (mandatory cap, fork-default, explicit opt-in) as launch-blocking
acceptance criteria, not a fast-follow. The scheduler (M3) would only get
scoped in detail once M2's real telemetry (how many queue items people
actually create, how often auto-execute gets turned on) makes the case for
it — an open-source maintainer accountable to their own users has no reason
to build a scheduler for a queue no one has used yet.

---

## Lock

**Approved for Implementation.** The architecture in this document —
Sessions as one bounded context (§7, ADR-008), Session Browser first (M1),
JSONL as the sole source of truth with no database (§14, ADR-005), no
streaming `ProcessRunner` variant (§15), the resume safety model (§2
principle 2, ADR-006), Resume Scheduler gated on real M2 usage evidence
(§21, ADR-007), Claude-only session support with a provider abstraction
deferred to a named trigger (§6.1, ADR-009), the workspace-centric dashboard
deferred to v3+ (§1.1), and the orchestration-companion product guardrail
(ADR-010) — is now **frozen**.

This means, concretely:

- The milestone sequence (M1 → M2 → M3), the module structure (§7), the
  domain model (§8), and the ten ADRs proposed in §16 are the implementation
  baseline. The next work on this scope is **implementation**, starting with
  Milestone 1, Epic 1.1, Feature 1.1.1 — not further architecture discussion.
- **Changes to a locked decision happen through a new ADR, not an edit to
  this document.** If implementation surfaces a reason one of the locked
  decisions above needs to change (for example, if M2 telemetry shows the
  app-resident scheduler is unworkable, or the FS-enumeration approach
  proves too slow on a large `~/.claude/projects/` tree), that is expected —
  this document's own risk table (§20) anticipated several such triggers —
  and the correct response is a new ADR that supersedes the specific one
  affected, following the existing `docs/adr/` convention, not a silent
  rewrite of §7–§15 here.
- This document itself is still a **proposal artifact** in the sense that it
  has not yet been copied into `docs/project/ROADMAP.md`, `DECISION_LOG.md`,
  or `docs/adr/` — §18 already states those updates happen once M1 starts,
  and that remains true. "Locked" describes the architecture's status, not a
  claim that the handoff package has been updated; do not treat this
  document as a substitute for that sync.
- ADR-010 (§16) is the standing guardrail for scope decisions beyond this
  roadmap: any future feature proposal — in v3 or sooner — should be
  checked against "does this orchestrate an official CLI, or does it
  recreate/replace one" before it is checked against anything else.

*This document does not modify `docs/project/ROADMAP.md`, `DECISION_LOG.md`,
or any ADR file directly — those updates happen when M1 implementation
begins, per §18.*
