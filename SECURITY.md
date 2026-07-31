# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| Latest release on [GitHub Releases](https://github.com/roshandroids/AI_Tray/releases) | Yes |
| `main` (unreleased) | Yes — reports welcome |
| Older tagged releases | Best effort; prefer upgrading |

## Reporting a vulnerability

**Do not** open public issues for security vulnerabilities.

Prefer [GitHub Security Advisories](https://github.com/roshandroids/AI_Tray/security/advisories/new)
for this repository. If that is unavailable, contact the primary maintainer
privately via the GitHub account that owns `roshandroids/AI_Tray`.

Include:

- Description of the issue and impact
- Steps to reproduce or proof of concept
- Affected platforms (macOS / Windows), providers (Claude / Copilot), or docs
- Suggested fixes if you have them

You should receive an acknowledgment when the report is seen. Disclosure timing
will be coordinated with the reporter.

## Security concern areas (AI Tray)

High-attention surfaces for this desktop companion:

- **CLI / process execution** — Invoking `claude` and related tools; command
  injection and unexpected process arguments
- **Copilot SDK sidecar** — Node bridge IPC (NDJSON), local process lifecycle,
  and trust boundary between Flutter and the sidecar
- **Cached usage data** — Last-known-good caches must not invent values; stale
  data must be labeled
- **Secrets & tokens** — Never log or commit provider credentials; prefer OS /
  CLI auth already present on the machine
- **Release artifacts** — Signed/notarized builds when available; verify
  download sources

Product hosts and end users remain responsible for their own machine auth,
network policies, and provider account security.

## Safe harbor

Good-faith research and private reporting conducted without privacy violation,
service disruption, or data exfiltration is appreciated. Do not access data that
is not yours.
