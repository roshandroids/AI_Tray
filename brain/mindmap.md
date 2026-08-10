---
slug: mindmap
title: Feature mindmap
role: feature mindmap
updated: "2026-08-09T23:30:49"
---

# Feature mindmap

## Bounded contexts

```mermaid
mindmap
  root((AI Tray))
    Usage/Quota pipeline
      Claude Code (stable)
      GitHub Copilot (experimental, SDK sidecar)
      Cursor Agent (research only, no production code — PD-023)
    Session management (v2)
      Session Browser/Detail
      Manual resume (attended)
      Resume Queue (budget-capped, notified)
      Resume Scheduler (not started, v2 M3)
    App shell (V3/V4)
      NavigationRail + IndexedStack
      Command palette (Cmd+K)
      Onboarding + Product Tour
      Help Center
    Personalization
      FlexColorScheme presets
      Bundled fonts
      Adaptive tray density
    Platform integration
      macOS menu bar
      Windows system tray
      Node Copilot sidecar (NDJSON)
```

Usage/Quota and Session management are deliberately separate bounded
contexts: they share only `ClaudeSessionService` and `NotificationGateway`,
not state or a database. See `architecture` and [[usage-data-model]] /
[[caching-strategy]] for the pipeline, `flow` for the resume flow.
