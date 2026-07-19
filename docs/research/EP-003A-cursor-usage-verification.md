# EP-003A — Cursor Usage Verification

**Status:** Research complete · no implementation  
**Date:** 2026-07-18  
**Installed CLI:** `agent` / `cursor-agent` `2026.07.16-899851b`  
**Working directory:** AI Tray repository root

## Conclusion

`/usage` is **not** available as a programmatic Cursor Agent usage command.
Every print-mode `/usage` variant exited successfully only because it executed
an agent turn. The result was free-form prose saying plan usage was unavailable,
not a quota payload.

`--output-format json` exists and is parseable, but it wraps the same prose plus
token counts for that single agent turn. Those token counts are not plan usage,
remaining allowance, pool percentages, credits, or reset information.

Official Cursor documentation supports headless `-p` and JSON output generally,
but does not document `/usage` or slash-command execution in print mode.

**Recommendation:** Do not use or parse `agent -p "/usage"` in AI Tray.

## Environment

`agent` was not on the shell's default `PATH`. Tests used:

```text
/Users/roshanshrestha/.local/bin/agent
```

This resolves to:

```text
/Users/roshanshrestha/.local/share/cursor-agent/versions/2026.07.16-899851b/cursor-agent
```

No auth/config changes were made. No secrets appeared in output.

## Summary matrix

| Command | Exit | Non-interactive | Plan usage returned | JSON |
| --- | ---: | --- | --- | --- |
| `agent -p "/usage"` | 0 | Yes | No | No |
| `agent --print "/usage"` | 0 | Yes | No | No |
| `agent -p --output-format json "/usage"` | 0 | Yes | No; per-turn tokens only | Yes |
| `agent -p --output-format text "/usage"` | 0 | Yes | No | No |
| `agent -p "Run /usage"` | 0 | Yes | No | No |
| `agent -p "/help"` | 0 | Yes | No; agent-generated workspace help | No |
| `agent --help` | 0 | Yes | No; local CLI help | No |

## Metric availability

| Requested field | Observed? |
| --- | --- |
| Usage % | No |
| Included % | No |
| Auto % | No |
| API % | No |
| On-demand % | No |
| Reset date | No |
| Per-turn input/output/cache token counts | Yes, JSON command only |

## Exact command results

### 1. `agent -p "/usage"`

- Actual invocation:
  `/Users/roshanshrestha/.local/bin/agent -p "/usage"`
- Exit code: `0`
- Elapsed: `119.324s`
- stderr: empty
- Classification: non-interactive agent turn; process succeeded, usage lookup did
  not

stdout:

```text
`/usage` isn’t a Cursor Agent/CLI slash command, so I can’t pull your plan quota from here.

**Check usage here:**
- [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage)
- Or in the editor: **Settings → Cursor Settings → usage / Models & Pricing**

You’ll see the included model pools, API spend, and when the billing cycle resets.
```

### 2. `agent --print "/usage"`

- Actual invocation:
  `/Users/roshanshrestha/.local/bin/agent --print "/usage"`
- Exit code: `0`
- Elapsed: `20.744s`
- stderr: empty
- Classification: non-interactive agent turn; no plan usage

stdout:

```text
I can’t pull your Cursor plan usage from this chat — `/usage` is handled by Cursor itself, not by the agent.

To check usage:

1. **Cursor app:** Settings → Account / Usage
2. **Web:** [cursor.com/settings](https://cursor.com/settings)
3. **CLI:** if you’re in the Cursor agent CLI, run `/usage` there (native command, not this agent)

If you meant something else (e.g. API token usage in this project), say which and I can look it up.
```

### 3. `agent -p --output-format json "/usage"`

- Actual invocation:
  `/Users/roshanshrestha/.local/bin/agent -p --output-format json "/usage"`
- Exit code: `0`
- Elapsed: `126.013s`
- stderr: empty
- Classification: non-interactive agent turn; parseable JSON envelope, but no
  plan usage

stdout:

```json
{"type":"result","subtype":"success","is_error":false,"duration_ms":123678,"duration_api_ms":123678,"result":"Checking how Cursor reports usage so I can pull your current numbers.`/usage` isn’t a Cursor agent command, so I can’t read your remaining quota from here.\n\n**Check your usage:**\n- Dashboard: [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage)\n- Desktop: Cursor Settings → account/usage\n\n**Plans use two monthly pools:**\n1. First-party models (Auto, Composer, etc.)\n2. API usage (included amount depends on plan: Pro $20, Pro Plus $70, Ultra $400)\n\nIn the CLI, `/about` shows account/plan identity only — not remaining balance.","session_id":"3d0e4b69-ea11-4399-8eae-d4c7ece70b4c","request_id":"09bbd50d-7fc9-48e2-8920-5f56f7f72ba4","usage":{"inputTokens":13265,"outputTokens":762,"cacheReadTokens":50944,"cacheWriteTokens":0}}
```

Observed JSON fields:

- Result envelope: `type`, `subtype`, `is_error`, `duration_ms`,
  `duration_api_ms`, `result`, `session_id`, `request_id`
- Per-turn token usage: `inputTokens`, `outputTokens`, `cacheReadTokens`,
  `cacheWriteTokens`

The `usage` object is agent-turn token accounting, not account quota.

### 4. `agent -p --output-format text "/usage"`

- Actual invocation:
  `/Users/roshanshrestha/.local/bin/agent -p --output-format text "/usage"`
- Exit code: `0`
- Elapsed: `31.755s`
- stderr: empty
- Classification: non-interactive agent turn; no plan usage

stdout:

```text
I can’t pull your Cursor plan usage from this chat — that data lives in your account, not in the agent session.

Check it here:
- **Dashboard:** [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage)
- **In the app:** Settings → Cursor Settings → Usage / Subscription

If you’re in the Cursor CLI and `/usage` should show a live breakdown, try running it again there; if it still lands in chat like this, the CLI surface may not be wired to the usage endpoint yet.
```

### 5. `agent -p "Run /usage"`

- Actual invocation:
  `/Users/roshanshrestha/.local/bin/agent -p "Run /usage"`
- Exit code: `0`
- Elapsed: `20.060s`
- stderr: empty
- Classification: non-interactive agent turn; no plan usage

stdout:

```text
`/usage` is a Cursor client command — I can’t run it from this agent session.

To see your usage:

1. In Cursor Chat / Agent input, type `/usage` and submit it yourself
2. Or open **Cursor Settings → Account / Usage** (wording varies by app version)

That view shows plan limits, usage for the current billing period, and remaining allowance.
```

### 6. `agent -p "/help"`

- Actual invocation:
  `/Users/roshanshrestha/.local/bin/agent -p "/help"`
- Exit code: `0`
- Elapsed: `10.288s`
- stderr: empty
- Classification: non-interactive agent turn; `/help` was interpreted as a
  prompt and returned workspace-specific prose

stdout:

```text
Here’s what I can help with in this workspace:

### Common requests
- **Code** — implement features, fix bugs, refactor Dart/Flutter (Clean Architecture + Riverpod)
- **Git** — commit, PR create/update (only when you ask)
- **Docs** — keep `docs/project/` handoff in sync after significant work
- **Debug** — investigate failures, run tests/analyze via Dart MCP
- **Review** — Bugbot / security review when you explicitly ask

### Useful phrases
| You say | I do |
|---|---|
| `implement …` / `fix …` | Write or change code |
| `commit` / `create a PR` | Git + GitHub (after you ask) |
| `analyze this` / `why is … broken` | Investigate without coding first |
| `what's next` / `handoff` | Read project state and next session plan |
| `merge ready?` | Pre-merge checklist |

### Project notes
- Repo: **AI Tray** (Flutter)
- Branch right now: `cursor/ep002-phase3-ui-quality`
- Source of truth: `docs/project/` (`AI_HANDOFF.md`, `NEXT_SESSION.md`, etc.)

### Limits
- I only commit when you ask
- Non-`.dart` changes need your OK before staging/committing
- I won’t push or force-push unless you ask

What do you want to work on?
```

### 7. `agent --help`

- Actual invocation: `/Users/roshanshrestha/.local/bin/agent --help`
- Exit code: `0`
- Elapsed: `0.360s`
- stderr: empty
- Classification: local, non-interactive CLI help; no agent turn

stdout:

```text
Usage: agent [options] [command] [prompt...]

Start the Cursor Agent

Arguments:
  prompt                       Initial prompt for the agent

Options:
  -v, --version                Output the version number
  --api-key <key>              API key for authentication (can also use
                               CURSOR_API_KEY env var)
  -H, --header <header>        Add custom header to agent requests (format:
                               'Name: Value', can be used multiple times)
  -p, --print                  Print responses to console (for scripts or
                               non-interactive use). Has access to all tools,
                               including write and shell. (default: false)
  --output-format <format>     Output format (only works with --print): text |
                               json | stream-json (default: "text")
  --stream-partial-output      Stream partial output as individual text deltas
                               (only works with --print and stream-json format)
                               (default: false)
  --mode <mode>                Start in the given execution mode. plan:
                               read-only/planning (analyze, propose plans, no
                               edits). ask: Q&A style for explanations and
                               questions (read-only). (choices: "plan", "ask")
  --plan                       Start in plan mode (shorthand for --mode=plan).
                               (default: false)
  --resume [chatId]            Select a session to resume (default: false)
  --continue                   Continue previous session (default: false)
  --model <model>              Model to use (e.g., gpt-5, sonnet-4-thinking).
                               Parameterized models accept quoted bracket
                               overrides, e.g.
                               'claude-opus-4-8[context=1m,effort=high,fast=false]'
  --list-models                List available models and exit (default: false)
  -f, --force                  Force allow commands unless explicitly denied
                               (default: false)
  --yolo                       Alias for --force (Run Everything) (default:
                               false)
  --auto-review                Use Auto-review (Smart Auto): a server classifier
                               auto-runs safe tool calls and prompts for the
                               rest (default: false)
  --sandbox <mode>             Explicitly enable or disable sandbox mode
                               (overrides config) (choices: "enabled",
                               "disabled")
  --approve-mcps               Automatically approve all MCP servers (default:
                               false)
  --trust                      Trust the current workspace without prompting
                               (only works with --print/headless mode) (default:
                               false)
  --workspace <path-or-name>   Workspace directory or saved workspace name to
                               use (defaults to current working directory)
  --add-dir <path>             Add an additional workspace root directory (can
                               be specified multiple times)
  --plugin-dir <path>          Load a local plugin directory (can be specified
                               multiple times)
  -w, --worktree [name]        Start in an isolated git worktree at
                               ~/.cursor/worktrees/<reponame>/<name>. If
                               omitted, a name is generated.
  --worktree-base <branch>     Branch or ref to base the new worktree on
                               (default: current HEAD)
  --skip-worktree-setup        Skip running worktree setup scripts from
                               .cursor/worktrees.json (default: false)
  -h, --help                   Display help for command

Commands:
  install-shell-integration    Install shell integration to ~/.zshrc
  uninstall-shell-integration  Remove shell integration from ~/.zshrc
  login                        Authenticate with Cursor. Set NO_OPEN_BROWSER to
                               disable browser opening.
  logout                       Sign out and clear stored authentication
  mcp                          Manage MCP servers
  plugin                       Manage plugins and plugin marketplaces
  worker [options]             Start a private cloud worker that connects to
                               Cursor to run agents in your environment
  status|whoami [options]      View authentication status
  models                       List available models for this account
  about [options]              Display version, system, and account information
  update                       Update Cursor Agent to the latest version
  create-chat                  Create a new empty chat and return its ID
  generate-rule|rule           Generate a new Cursor rule with interactive
                               prompts
  agent [prompt...]            Start the Cursor Agent
  ls                           Resume a chat session
  resume                       Resume the latest chat session
  help [command]               Display help for command
```

No `/usage` slash command or usage-quota subcommand is listed.

## Stability comparison

All `/usage` prompt variants consistently refused or redirected to
dashboard/settings, but their wording and links varied. One response claimed a
native CLI `/usage` existed while others said it did not. This contradiction is
strong evidence that the text is generated model prose, not a stable interface.

The JSON envelope is documented to evolve additively, but the `result` value
remains free-form model text. It is unsuitable for quota parsing.

## Official support

Official Cursor documentation confirms:

- `-p` / `--print` is supported for non-interactive scripting.
- `--output-format text|json|stream-json` is supported in print mode.
- Consumers should ignore unknown JSON fields; optional fields may vary.

Official documentation does **not** confirm:

- `/usage` as a CLI slash command
- Slash-command evaluation inside headless prompts
- A personal usage API/CLI for included, Auto, API, on-demand percentages or
  reset date

Official references:

- [Headless CLI](https://cursor.com/docs/cli/headless.md)
- [CLI parameters](https://cursor.com/docs/cli/reference/parameters.md)
- [Output format](https://cursor.com/docs/cli/reference/output-format.md)
- [Slash commands](https://cursor.com/docs/cli/reference/slash-commands.md)
- [Models and pricing](https://cursor.com/docs/models-and-pricing.md)
- [Usage and limits](https://cursor.com/help/models-and-usage/usage-limits.md)
- [SDK token usage](https://cursor.com/docs/sdk/typescript.md#token-usage)
- [APIs overview](https://cursor.com/docs/api.md)

## Recommendation

1. Do not implement Cursor plan-usage retrieval through Agent prompts.
2. Do not parse text from `agent -p "/usage"`.
3. Do not interpret JSON `usage` token counters as subscription quota.
4. Keep personal allowance/reset information dashboard-only.
5. Revisit only if Cursor documents a consumer usage-summary CLI/API.

This verification reinforces PD-023 and the EP-003 recommendation. No production
code was implemented.
