# Claude Code CLI — Session & Resume Capability Report

**Tested version:** `2.1.220` (installed fresh via `npm install -g @anthropic-ai/claude-code`)
**Test method:** `claude --help`, subcommand `--help` output, `claude doctor`, and live invocations of `claude -p ...` in a sandboxed Linux container. The account was **not authenticated**, so actual model responses could not be captured — but the CLI's argument parsing, error handling, JSON schemas, and on-disk session files are all real, observed output, not documentation guesses. Everything below is labeled with how it was confirmed.

Because this is a fast-moving CLI (this build postdates most training data), **re-run `claude --help` and `claude <subcommand> --help` against the exact version you ship against** before locking your integration.

---

## 1. Session Management

| Question | Answer | Confirmed by |
|---|---|---|
| Command to list all sessions? | `claude agents --json` — prints a JSON array of active (interactive + background) sessions. Add `--all` to include completed background sessions. Add `--cwd <path>` to filter to one project. | `claude agents --help` (live) |
| Is `--resume` the only way to browse? | No — `claude agents --json` is a scriptable listing path. `claude --resume` (no value) opens an **interactive picker** but that only works in a TTY; in `--print` mode it errors out (see §2). `--from-pr [value]` also opens a picker filtered/searched by PR. | live test |
| Non-interactive mode? | Yes: `-p` / `--print`. | `claude --help` |
| JSON output? | Yes: `--output-format json` (single result) or `--output-format stream-json` (NDJSON-style streaming), both **only valid with `--print`**. `claude agents --json` is a separate, simpler JSON listing. | live test, schemas below |
| Parseable without terminal-UI scraping? | Yes, fully — see §5. No scraping required for anything covered here. | live test |

---

## 2. Resume Support — Confirmed

```
claude --resume <session-id>
claude -r <session-id>
claude --resume            # interactive picker (TTY only)
claude --resume <search-term>   # picker pre-filtered/searched (TTY only)
```

- `--resume` (short `-r`) takes an **optional** value: a session ID *or* a search term for the picker.
- Confirmed live: resuming a real session ID keeps the **same `session_id`** in the output JSON (i.e., it's a true resume, not a new session).
- Confirmed live: resuming a bogus/non-existent ID fails immediately and cleanly:
  ```
  $ claude --resume 00000000-0000-0000-0000-000000000000 -p "continue"
  No conversation found with session ID: 00000000-0000-0000-0000-000000000000
  ```
  (exit code 1, plain stderr text — not JSON, even when `--output-format json` was requested, since the process errors before a result envelope is built).
- Confirmed live: **in `--print` mode, `--resume` requires an explicit ID or title** — the interactive picker is disabled:
  ```
  $ claude -p --resume
  Error: --resume requires a valid session ID or session title when used with --print.
  Usage: claude -p --resume <session-id|title>
  ```
  This is the single most important fact for your app: **you must resolve the session ID yourself** (via `claude agents --json` or by reading transcript files — see §3) before calling resume non-interactively. There is no server-side "resume by fuzzy title" in headless mode.
- `--continue` / `-c`: resumes the **most recent conversation in the current working directory** — no ID needed, but it's directory-scoped and picks "most recent" for you, not a specific one.
- `--fork-session`: used **with** `--resume` or `--continue`; instead of continuing in place, it clones the history into a **new** session ID. Useful if you want to branch a resume queue without mutating the original transcript.
- `--session-id <uuid>`: lets you **assign** a specific UUID to a brand-new session (must be a valid UUID you generate). This means your app can pre-generate the session ID before ever calling Claude, which is convenient for a resume-queue design.
- `--from-pr [value]`: resumes a session that's linked to a GitHub PR, by PR number/URL, or opens a picker searchable by PR.

Example invocations:
```bash
claude --resume 3ed33b01-91f3-4c00-abd3-c4ac5fac4972 -p "Continue from where we stopped." --output-format json
claude --continue -p "Continue" --output-format json
claude --session-id 11111111-1111-1111-1111-111111111111 -p "Start fresh with a known ID" --output-format json
```

---

## 3. Session Metadata

Two independent, verified sources give you metadata — pick based on need:

### A. `claude agents --json` (live session registry)
Confirmed to run and return `[]` when no active/background sessions exist. Per the `--help` text, entries cover **active sessions (interactive + background)**, and with `--all`, completed background ones too. This is the right tool for "what's running right now," not full history.

### B. On-disk transcripts (confirmed by direct inspection)
Every session — even ones that error before any model output — is persisted as a JSONL file at:
```
~/.claude/projects/<sanitized-cwd>/<session-id>.jsonl
```
`<sanitized-cwd>` is the working directory with `/` replaced by `-` (observed: `/home/claude/testproj` → `-home-claude-testproj`). This means **project path is recoverable from the file path alone**, and confirmed as a `cwd` field inside every record too.

Fields observed directly in real JSONL records:

| Field | Where seen | Notes |
|---|---|---|
| `sessionId` / `session_id` | every record | matches the filename |
| `cwd` | every record | project path |
| `gitBranch` | user/message records | live git branch at time of message |
| `timestamp` | every record | ISO-8601, per-event |
| `version` | every record | Claude Code version that wrote it |
| `model` | assistant message envelope (`message.model`) | `"<synthetic>"` was seen only because the call errored pre-model (auth failure); a real completion should carry the actual model id |
| `usage` (tokens) | assistant message (`message.usage`) | `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, etc., **per message** |
| message role/content | `type: "user"` / `type: "assistant"` records | full transcript, so message count = count of `user`/`assistant` typed lines |
| `promptId`, `uuid`, `parentUuid` | every record | lets you reconstruct the message tree/order |
| `-n / --name` display name | confirmed flag exists (`-n, --name <name>`: "shown in the prompt box, /resume picker, and terminal title") | not yet confirmed as a distinct persisted field name in the JSONL in this test — treat as **flag confirmed, on-disk field name unconfirmed** until you inspect a named session's file |
| status ("running"/"completed") | exposed via `claude agents --json --all` per `--help` wording | not independently verified beyond the empty-array test; the flag and its stated purpose are confirmed, the exact field names in a non-empty result are not |

### C. `--output-format stream-json` init event (confirmed live)
The very first line of a `stream-json` run is a `type: "system", subtype: "init"` record containing, all confirmed by direct output:
```json
{
  "type": "system", "subtype": "init",
  "cwd": "...", "session_id": "...",
  "tools": ["Task","Bash", "..."],
  "mcp_servers": [],
  "model": "claude-opus-5[1m]",
  "permissionMode": "default",
  "slash_commands": ["...", "..."],
  "claude_code_version": "2.1.220",
  "agents": ["claude","Explore","general-purpose","Plan","statusline-setup"],
  "skills": ["...", "..."],
  "capabilities": ["interrupt_receipt_v1","interrupt_cancel_queued_v1","msg_lifecycle_v1"],
  "memory_paths": { "auto": ".../memory/" }
}
```
This is the richest single machine-readable metadata snapshot for a session, and it's emitted at session start with **no auth required** to see the envelope (auth only gates the actual model turn).

### D. `--output-format json` result envelope (confirmed live)
The **final** line/result of a `-p --output-format json` run, confirmed live:
```json
{
  "is_error": true,
  "duration_api_ms": 0, "duration_ms": 174,
  "num_turns": 1,
  "stop_reason": "stop_sequence",
  "session_id": "3ed33b01-91f3-4c00-abd3-c4ac5fac4972",
  "total_cost_usd": 0,
  "usage": { "input_tokens": 0, "output_tokens": 0, "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0, "...": "..." },
  "modelUsage": {},
  "permission_denials": [],
  "terminal_reason": "api_error",
  "subtype": "success",
  "result": "Not logged in · Please run /login",
  "type": "result",
  "uuid": "f57b1542-930f-4eeb-b368-cbbef943d108"
}
```
This gives you **cost, token usage, turn count, session id, and a final status string** per run — exactly what a "resume queue" dashboard would want to log per attempt.

---

## 4. Non-interactive Usage — Confirmed

| Method | Works? | Notes |
|---|---|---|
| `claude -p "prompt"` | ✅ confirmed | positional `prompt` argument |
| `claude --resume <id> "prompt"` | ✅ (grammar confirmed via `--help`; combine with `-p`) | `claude --resume <id> -p "Continue from where we stopped."` |
| `claude --resume <id> --prompt "..."` | ❌ | there is **no** `--prompt` flag — the prompt is a **positional argument**, not a named flag. Don't build against `--prompt`. |
| `echo "text" \| claude -p` | ✅ confirmed | stdin is read; CLI even warns if stdin is slow/empty ("no stdin data received in 3s...") — confirmed live |
| `claude -p` with `--input-format stream-json` | documented in `--help`, not exercised live | for realtime streaming input, pairs with `--output-format stream-json` |

Practical pattern confirmed to parse correctly:
```bash
claude --resume 3ed33b01-91f3-4c00-abd3-c4ac5fac4972 -p "Continue from where we stopped." --output-format json
```

---

## 5. Output Formats — Confirmed flags

All gated behind `--print` / `-p`:

| Flag value | Format | Confirmed |
|---|---|---|
| `--output-format text` (default) | plain text | implied default |
| `--output-format json` | single JSON result object at end of run | ✅ live, schema above |
| `--output-format stream-json` | NDJSON, one JSON object per line, streamed in real time | ✅ live, init-event schema above |
| `--input-format stream-json` | realtime streaming **input** (pairs with `--print`) | documented in `--help`, not exercised |
| `--include-partial-messages` | include partial/streaming chunks in `stream-json` output | documented, requires `--print` + `stream-json` |
| `--include-hook-events` | include hook lifecycle events in the stream | documented, requires `stream-json` |
| `--forward-subagent-text` | forwards subagent text/thinking as regular turns in the stream | documented, requires `--print` + `stream-json` |
| `--json-schema <schema>` | constrains/validates structured output against a JSON Schema | documented in `--help`, not exercised (needs auth) |
| `claude agents --json` | separate flat JSON array of live/background sessions | ✅ live (returned `[]`) |
| `claude auth status` | JSON auth status | ✅ live: `{"loggedIn": false, "authMethod": "none", "apiProvider": "firstParty"}` |

No NDJSON output was found outside of `stream-json`; that flag *is* the NDJSON mechanism.

---

## 6. Automation Workflows

**A. Launch → auto-resume → auto-send prompt**
**Officially supported.** Confirmed grammar:
```bash
claude --resume <session-id> -p "Continue from where we stopped." --output-format json
```
No UI automation needed. This is a single CLI invocation your Flutter app can shell out to and parse stdout as JSON.

**B. List sessions → pick one programmatically → resume it**
**Officially supported**, in two parts:
1. List: `claude agents --json` (live sessions) and/or scan `~/.claude/projects/**/*.jsonl` for full history (confirmed file layout, §3B).
2. Resume: feed the chosen `session_id` into `--resume <id> -p ...` (confirmed, §2).
No terminal scraping required — both halves are structured data.

**C. Schedule a resume for later (e.g., "resume when quota resets")**
**Not a CLI feature.** There is no `--at`, `--schedule`, `--cron`, or wait/delay flag anywhere in `claude --help` or any subcommand's `--help`. Notably, the session transcript *does* reveal that Claude Code's in-session agent has internal tools named `CronCreate`, `CronList`, `CronDelete`, and `ScheduleWakeup` (seen in a `deferred_tools_delta` / tool-list attachment) — but these are **tools available to the model inside a running session**, not CLI flags or subcommands you can invoke from outside. There is no `claude cron ...` or `claude schedule ...` command. **Scheduling a resume is your app's responsibility** (e.g., your own OS-level timer/cron/WorkManager equivalent that shells out to `claude --resume <id> -p "..."` at the right time). This should not be relied upon as an undocumented backdoor — it's an internal agent capability, not a supported external interface.

---

## 7. Hidden/Advanced Flags — What `--help` actually contains

Full `claude --help` and `claude agents --help` output was captured live (not reproduced from memory). Noteworthy items beyond the obvious, all **documented in `--help` itself** (i.e., not secret, just easy to miss):

- `--bare`: minimal mode — skips hooks, LSP, plugin sync, memory, keychain reads; useful for a clean scripted invocation with explicit context only.
- `--safe-mode`: disables all customizations (CLAUDE.md, skills, plugins, hooks, MCP, themes) for troubleshooting; admin policy settings still apply.
- `--no-session-persistence`: **only with `--print`** — disables saving the session, meaning it cannot later be resumed. Important negative-case flag for your app to *avoid* if you want everything resumable.
- `--max-budget-usd <amount>`: hard cost cap per run, **only with `--print`** — directly useful for an automated resume-queue that must not runaway-spend.
- `--fallback-model <model list>`: automatic fallback chain when the primary model is overloaded, **only with `--print`**; retries the primary at the start of each turn.
- `--prompt-suggestions`: in print/SDK mode, emits a predicted-next-prompt message after each turn — could feed a "suggested continue" UI affordance.
- `--exclude-dynamic-system-prompt-sections`: strips machine-specific info (cwd, env, git status) from the system prompt for better prompt-cache reuse across users/machines.
- `claude project purge [path]`: deletes all Claude Code state (transcripts, tasks, file history, config) for a project — a real, destructive, documented command; surface this in your UI only behind explicit confirmation.
- `agents --json` also accepts `--all` and `--cwd <path>` filters (confirmed above).

No flags were found that aren't listed in `--help` — this version does not appear to hide resume/session/automation functionality behind undocumented switches. `-h`/`--help` output was consistent across the top-level and per-subcommand invocations tested.

---

## 8. Recommended Architecture for AI Tray (Flutter Desktop)

Given everything confirmed above, prefer **CLI process invocation + JSON parsing** over any terminal-UI automation — no PTY scraping is needed anywhere in this design.

**Process wrapper layer**
- Shell out via `Process.run`/`Process.start` in Dart.
- Always pass `-p --output-format stream-json` for anything long-running (progressive UI updates, partial message rendering) or `-p --output-format json` for simple fire-and-forget calls.
- Parse stdout line-by-line as NDJSON when using `stream-json`; parse the single trailing JSON object when using `json`.
- Always pass `--session-id <uuid>` when *creating* a new tracked session, so your app — not the CLI — owns the ID from the start (confirmed flag, §2).

**Session Browser**
- Primary source: walk `~/.claude/projects/**/*.jsonl` (confirmed layout) to build full history — directory name decodes to project path, filename is the session ID, and each line gives you timestamps, git branch, model, and per-message token usage.
- Secondary/live source: `claude agents --json --all` for what's currently active or recently completed, to badge "live" vs "archived" sessions in your UI.
- Don't rely on an on-disk field for a human-readable session title beyond what `-n/--name` sets — confirm the persisted field name against your shipped version before building a title column.

**Resume Queue**
- Each queue item stores: `session_id`, `cwd` (needed because Claude Code scopes some behavior, like `--continue`, to the working directory), and the next prompt text.
- Executing an item: `claude --resume <session_id> -p "<prompt>" --output-format json`, in the stored `cwd` as the process working directory.
- Use `--max-budget-usd` per queued run to cap spend, and `--fallback-model` to keep the queue moving if the primary model is overloaded (both confirmed flags, §7).
- Use `--fork-session` if a queued action is exploratory and shouldn't mutate the canonical transcript.

**Resume at quota reset**
- No CLI-native scheduling exists (confirmed, §6C) — implement this entirely in your Flutter app: a local timer/OS scheduler (e.g., a background isolate, or the OS's own task scheduler) that fires a normal `claude --resume ...` invocation once the reset time is reached. Treat the CLI purely as an on-demand executor, not a scheduler.

**Resume by clicking a notification**
- Straightforward given the above: the notification payload just needs to carry the `session_id` (and `cwd`); the click handler runs the same confirmed `--resume <id> -p "..." --output-format json` invocation.

**Limitations / things not to build against**
- `--resume` without an ID/title is interactive-only and **fails hard** under `--print` (confirmed) — never assume a headless fuzzy-picker exists.
- No confirmed stable field name for session "title" beyond the `-n/--name` flag's stated UI effects; verify before depending on it for display.
- No official session **status** enum was observed (only the *existence* of a `--all` "completed background sessions" distinction) — don't hardcode assumed values like `"running"/"completed"/"failed"` without checking a populated `agents --json` result on your target version.
- Cron/schedule tool names (`CronCreate`, `ScheduleWakeup`, etc.) are internal agent tools, not CLI surface — do not build a feature around invoking them directly from outside a session.
- All of the above was captured against `2.1.220` without an authenticated account, so actual model-turn behavior (real `model` values, real token counts, real cost figures) was not observed — only the surrounding scaffolding (flags, error handling, file formats, envelope schemas). Re-verify field values (not just field presence) once you test with a logged-in account.
