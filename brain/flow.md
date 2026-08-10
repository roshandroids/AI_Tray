---
slug: flow
title: Key flows
role: key flows
updated: "2026-08-09T23:52:34"
---

# Key flows

## Usage refresh flow

Verified against `features/usage/data/services/refresh_service.dart`.

```mermaid
sequenceDiagram
  participant UI
  participant RefreshService
  participant AIProvider
  participant Validator
  participant Cache

  UI->>RefreshService: refresh(settings, currentStatus)
  alt refresh already in flight for this providerId
    RefreshService-->>UI: join existing Future, coalesced
  else
    RefreshService->>AIProvider: fetchUsageRaw(config)
    AIProvider-->>RefreshService: raw stdout or JSON, or failure
    opt retryable outcome: incomplete rate limits, timeout, non-zero exit, unknown
      RefreshService->>RefreshService: delay, soft 3s or hard 2s, fetch once more
    end
    alt raw fetch succeeded
      RefreshService->>Validator: validate parsed candidate
      alt validation succeeded, Shape A
        RefreshService->>Cache: write usage
        RefreshService-->>UI: RefreshOutcome.success
      else validation failed, incomplete or unknown shape
        RefreshService->>Cache: read LKG
        RefreshService-->>UI: RefreshOutcome.softFailure, plus cached usage if any
      end
    else raw fetch failed: CLI, process, auth, or timeout error
      opt cliNotInstalled, notAuthenticated, or repeated hard failures
        RefreshService->>AIProvider: healthCheck(config)
      end
      RefreshService->>Cache: read LKG
      RefreshService-->>UI: RefreshOutcome.failure, plus cached usage if any
    end
  end
```

`AIProvider` above is whichever adapter is active (Claude or Copilot);
`Cache` is the Last-Known-Good `UsageCache`.

See [[caching-strategy]] for exactly which failures are soft vs hard and why,
and [[usage-data-model]] for how `RefreshOutcome` + `isFromCache` map to the
`Live / Cached / Refreshing / Error / Waiting` status the UI shows.

## Session resume / queue flow (v2, separate context)

```mermaid
sequenceDiagram
  participant UI
  participant Repo
  participant FS
  participant Attended
  participant Queue
  participant Notif

  UI->>Repo: list or read sessions
  Repo->>FS: enumerate jsonl files under home claude projects
  FS-->>Repo: parsed sessions, malformed or truncated lines skipped, isComplete degraded
  Repo-->>UI: SessionSummary list, most-recently-active first

  alt attended resume, Resume now
    UI->>Attended: resume(session)
    Attended->>Attended: forkSession false, continue in place
  else queued resume
    UI->>Queue: enqueue(session, budgetCap)
    Note over Queue: constructor throws ArgumentError if budgetCap missing or non-positive
    Queue->>Queue: forkSession true by default, never mutate a transcript the user may be continuing elsewhere
    Queue->>Queue: single-flight executor, checks cwd exists immediately before running
    Queue->>Notif: notify on every terminal outcome
    Notif-->>UI: click-through opens SessionDetailPage
  end
```

Non-goals for this flow today: no cooperative cancellation of a `running`
item (only `pending` items can be cancelled, finished ones cleared), no
Resume Scheduler (unattended/timer-driven) yet, no cross-session analytics.
See `roadmap`.
