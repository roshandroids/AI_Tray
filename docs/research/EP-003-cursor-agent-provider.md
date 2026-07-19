# EP-003 — Cursor Agent Provider Research

**Status:** Research complete · no provider implementation  
**Date:** 2026-07-18  
**Scope:** Determine whether Cursor Agent can become a first-class AI Tray provider using **supported** interfaces only.

## Verdict

Cursor Agent can be a first-class **agent execution / automation** provider via officially supported CLI, SDK, and Cloud Agents APIs.

It **cannot** today be a first-class **personal usage/quota** tray provider for Hobby/Pro users using only documented interfaces. Enterprise Admin/Analytics APIs cover team spend and events, not the personal “remaining % / reset date / Auto vs API pool” tray model.

Do **not** scrape undocumented dashboard endpoints. That conflicts with Cursor Terms of Service and is rejected for AI Tray.

---

## 1. Usage command

There is **no** `usage` subcommand on the installed Agent CLI.

The local “usage screen” is the help page:

| Field | Value |
| --- | --- |
| Command | `cursor-agent --help` |
| Aliases | `-h`, `help`, `agent --help` |
| Exit code | `0` |
| stdout | Full CLI usage + commands list |
| stderr | empty |
| Classification | Scriptable |

Binary discovery:

| Name | Path | Notes |
| --- | --- | --- |
| `cursor-agent` | `~/.local/bin/cursor-agent` | Bash wrapper → Node build |
| `agent` | `~/.local/bin/agent` | Same binary (symlink) |
| Version | `2026.07.16-899851b` | Via `--version` / `-v` only |
| Default PATH | Often missing `~/.local/bin` | GUI apps may not resolve the binary |

Important:

- Bare `cursor-agent` (no args) starts an **interactive** agent session.
- `cursor-agent usage` is **not** a usage API — unknown words are treated as agent prompts and can consume quota.

---

## 2. Structured output

| Capability | Supported? | Evidence |
| --- | --- | --- |
| JSON | Yes | `--print --output-format json`; `status`/`whoami`/`about --format json` |
| YAML | No | Not in local help or docs probed |
| Machine-readable | Yes | JSON + NDJSON `stream-json` |
| Silent mode | No dedicated flag | Headless via `--print` (+ typically `--trust`) |
| Programmatic mode | Yes | Headless CLI, SDK, Cloud Agents API, ACP |

Prefer JSON over free-text parsing wherever documented. Official stream-json allows additional fields; consumers must ignore unknown keys. Failures are non-zero exit + stderr (no success JSON).

Local JSON samples (redacted):

- `status --format json`: `status`, `isAuthenticated`, `hasAccessToken`, `hasRefreshToken`, `userInfo.{email,userId,...}` — token **presence** only, no raw secrets.
- `about --format json`: `cliVersion`, `model`, `subscriptionTier`, `osPlatform`, `osArch`, `userEmail`, `shell`, `lastRequestId`.

---

## 3. CLI discovery / command matrix

### Supported top-level commands (from local `--help`)

1. `install-shell-integration`
2. `uninstall-shell-integration`
3. `login`
4. `logout`
5. `mcp` (`login`, `list`, `list-tools`, `enable`, `disable`)
6. `plugin` → `marketplace` (`add`, `list`, `remove`, `update`)
7. `worker` (`start`, `debug`, …)
8. `status` / `whoami`
9. `models`
10. `about`
11. `update`
12. `create-chat`
13. `generate-rule` / `rule`
14. `agent`
15. `ls`
16. `resume`
17. `help`

Plus global options such as `--api-key`, `--print`, `--output-format`, `--mode`/`--plan`, `--resume`/`--continue`, `--model`, `--list-models`, `--force`/`--yolo`, `--sandbox`, `--trust`, `--workspace`, etc.

### Requested probes

| Exact command | Exit / result | stdout (summary) | stderr | Class |
| --- | --- | --- | --- | --- |
| `cursor-agent --help` | 0 | Full usage | empty | Scriptable |
| `cursor-agent -h` | 0 | Same | empty | Scriptable |
| `cursor-agent help` | 0 | Same | empty | Scriptable |
| `cursor-agent` (no args) | interactive / hung | Agent session | — | Interactive |
| `cursor-agent --version` / `-v` | 0 | `2026.07.16-899851b` | empty | Scriptable |
| `cursor-agent status` | 0 | Logged-in identity | empty | Scriptable |
| `cursor-agent whoami` | 0 | Same as status | empty | Scriptable |
| `cursor-agent about` | 0 | Version, model, tier, OS, email | empty | Scriptable |
| `cursor-agent models` | 0 | Model catalog | empty | Scriptable |
| `cursor-agent usage` | nonexistent → prompt | Would start agent | — | **Quota risk** |
| `cursor-agent account` | nonexistent → prompt | Would start agent | — | **Quota risk** |
| `cursor-agent config` | nonexistent → prompt | Would start agent | — | **Quota risk** |
| `cursor-agent doctor` | nonexistent → prompt | Would start agent | — | **Quota risk** |
| `cursor-agent version` | prompt | Agent reply text (not CLI version) | empty | **Quota consumed during research** |
| `cursor-agent help usage\|account\|config\|doctor\|version` | 1 | empty | dumps main usage | Command does not exist |

**Distinction:** Missing subcommands are not auth/env failures. `help <unknown>` returns exit 1. Running the bare unknown word starts an agent turn.

IDE `cursor` (`/Applications/Cursor.app/.../bin/cursor`) is the VS Code-style CLI and is **not** the Agent CLI.

---

## 4. Authentication

| Topic | Finding |
| --- | --- |
| How login works | `login` opens browser (`NO_OPEN_BROWSER` disables); or `--api-key` / `CURSOR_API_KEY` |
| Session persistence | Persists across CLI invocations after login |
| Credential storage | Path names observed only (contents not read): `~/.cursor/cli-config.json`, `agent-cli-state.json`; wrapper may use `AGENT_CLI_CREDENTIAL_STORE=file` |
| Token expiration | Not exposed as a tray-ready API |
| Authentication detection | `status` / `whoami` (text or JSON) reports authenticated + token presence flags |
| Account-ish info | `about` exposes subscription tier / email / model — no separate `account` command |

Mutating `login` / `logout` / `update` / worker start were not executed during research.

Official docs also document Dashboard API keys for SDK / Cloud Agents / Admin APIs.

---

## 5. Usage metrics capability matrix

| Need | Available via supported interfaces? | Where | Stability |
| --- | --- | --- | --- |
| Plan (personal) | No | Dashboard UI | Unsupported |
| Monthly usage | Partial | Enterprise spend/events; individual = dashboard | Enterprise / UI |
| Remaining % | No | Dashboard UI only | Unsupported |
| Reset date | No | Manage Subscription UI | Unsupported |
| API usage | Partial | Concepts in help; Enterprise event fees | Unsupported (personal) |
| Auto usage | Partial | Concepts in help; Enterprise events | Unsupported (personal) |
| On-demand usage | Partial | UI + Enterprise spend | Unsupported (personal) |
| Quota / credits / requests | Partial | Enterprise Admin fields | Enterprise-only |
| Models | Yes | `models` / `--list-models`, SDK, Cloud `/v1/models` | Stable |
| Current session | Yes | CLI/SDK session + run IDs | Stable |
| Per-run tokens | Yes | SDK `TokenUsage`; Cloud `GET /v1/agents/{id}/usage` | Stable / beta |

---

## 6. Diagnostics

| Need | Available? | Notes |
| --- | --- | --- |
| Version | Yes | `--version`, `about` |
| Health | Partial | Auth via `status`; worker `/healthz` `/readyz` `/metrics` only if private worker running |
| Connection | Partial | `status` endpoint/auth; MCP list readiness |
| Region | No | No tray API |
| Latency | No | No tray API |
| Configuration | Partial | CLI config / `--workspace` as execution inputs |
| Workspace | Yes | `--workspace` / related path options |

No `doctor` subcommand exists.

---

## 7. Official support surfaces

| Surface | Role | Stability (official) |
| --- | --- | --- |
| Cursor Agent CLI (`agent` / `cursor-agent`) | Terminal + headless agent | Product docs; CLI has `stable` / `lab` channels |
| ACP (`agent acp`) | JSON-RPC over stdio for custom clients | Advanced; hidden from default help |
| TypeScript / Python SDK | Programmatic Agent → Run | Documented for users |
| Cloud Agents REST API | Cloud agents/runs/usage | Public beta |
| Admin / Analytics / Org APIs | Team spend & events | Enterprise |
| Dashboard UI | Personal remaining / reset / on-demand | UI-only |

### Key official references

- [CLI overview](https://cursor.com/docs/cli/overview.md)
- [CLI parameters](https://cursor.com/docs/cli/reference/parameters.md)
- [Headless](https://cursor.com/docs/cli/headless.md)
- [Output format](https://cursor.com/docs/cli/reference/output-format.md)
- [Authentication](https://cursor.com/docs/cli/reference/authentication.md)
- [ACP](https://cursor.com/docs/cli/acp.md)
- [TypeScript SDK](https://cursor.com/docs/sdk/typescript.md)
- [Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints.md)
- [APIs overview](https://cursor.com/docs/api)
- [Admin API](https://cursor.com/docs/account/teams/admin-api.md)
- [Usage limits help](https://cursor.com/help/models-and-usage/usage-limits.md)
- [Terms of Service](https://cursor.com/terms-of-service) (includes scrape/harvest restrictions)

---

## 8. Stability classification

| Interface | Classification |
| --- | --- |
| CLI help / status / about / models / version flags | **Stable** (documented product CLI) |
| Headless JSON / stream-json | **Stable** docs; treat event schema as additive |
| SDK Agent create/send/prompt | **Supported**; tool-call arg/result schemas explicitly **not stable** |
| Cloud Agents REST | **Preview / public beta** |
| ACP | **Advanced / experimental-adjacent** (documented but hidden) |
| Personal remaining % / reset / pool remaining | **Unsupported** (UI-only) |
| Undocumented dashboard usage endpoints | **Internal / unsupported** — do not use |
| Enterprise Admin spend/events | **Stable for Enterprise**, wrong audience for Hobby/Pro tray |

---

## Architecture recommendation

```text
AI Tray (future, if pursued)
└─ Provider Registry
   └─ CursorProvider (automation-only)
      └─ CursorSdkAdapter / CursorCliAdapter
         └─ Official CLI headless JSON and/or Cursor SDK
```

Recommended boundaries:

1. **In scope (future epic):** auth detection, version, models, session/run identity, optional per-run token totals, structured failure mapping.
2. **Out of scope until Cursor ships a consumer API:** plan card, remaining %, reset date, Auto/API/on-demand remaining pools.
3. **Not primary tray backends:** ACP (too heavy), dashboard scraping (ToS), guessing usage from free-text agent replies.
4. **Optional later slice:** Enterprise Admin analytics behind an Enterprise gate — separate product, not Hobby/Pro parity with Claude/Copilot quota cards.

If AI Tray only needs quota monitoring today, **do not** add Cursor as a provider. Deep-link to [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage) instead.

---

## Risk assessment

| Risk | Severity | Notes |
| --- | --- | --- |
| Personal quota API gap | High | Core tray metrics unavailable on Hobby/Pro |
| Unknown-word → agent prompt | High | `usage` / `config` / `doctor` / `version` can burn quota |
| PATH / binary discovery | Medium | `~/.local/bin` often absent from GUI PATH |
| Cloud API / tool schema churn | Medium | Public beta; SDK tool payloads unstable |
| ToS if scraping dashboard | High | Rejected path |
| Enterprise-only spend APIs | Medium | Wrong audience for consumer tray |
| Interactive default CLI | Medium | Scripting requires `--print` (+ trust) explicitly |

---

## Implementation recommendation

**Stop after research. No production Cursor provider code.**

| Goal | Recommendation |
| --- | --- |
| Ship Cursor as Copilot-like usage/quota provider | **No — blocked** on supported interfaces |
| Ship Cursor as automation provider | **Conditional yes** in a **separate epic** using CLI/SDK only |
| Enterprise team spend in Tray | **Conditional later**, Enterprise-gated Admin API |
| Parse help text / agent replies for usage | **No** |
| Scrape dashboard / undocumented APIs | **No** |

### Decision for EP-003

Treat Cursor Agent as a candidate first-class **automation** provider with optional Enterprise analytics later — **not** as a complete first-class personal quota/usage provider until Cursor publishes an official consumer usage-summary API (plan, remaining, reset, Auto/API/on-demand pools).

### Suggested next product gate (not implementation)

1. Product Owner decides whether automation-provider value is worth a new epic without quota parity.
2. If yes, open EP-004 (or similar) with explicit non-goals around remaining %.
3. Revisit quota when Cursor documents a personal usage-summary endpoint.

---

## Research method

- Local black-box probe of installed `cursor-agent` / `agent` (no credential contents read; mutating auth/config not invoked; agent-starting probes stopped after `version` consumed quota).
- Official Cursor documentation for CLI, SDK, Cloud Agents, Admin APIs, usage-limits help, and Terms of Service.

No production code was added for a Cursor provider.
