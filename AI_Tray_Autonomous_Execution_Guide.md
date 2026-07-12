# AI Tray --- Autonomous Delivery Plan

## Product Owner Execution Guide (Cursor)

Purpose: Allow Cursor to continue implementation autonomously until the
MVP is complete.

## Mission

Build a production-quality Flutter desktop app for macOS and Windows
that displays Claude Code usage from the installed Claude CLI.

## Scope

### MVP

-   Flutter desktop foundation
-   macOS menu bar
-   Windows system tray
-   Claude CLI adapter
-   Usage retrieval
-   Refresh timer
-   Last-known-good cache
-   Settings
-   Notifications
-   Launch at login

### Out of Scope

-   Analytics
-   Charts
-   Multi-provider
-   Multi-account
-   Telemetry

## Mandatory Rules

1.  Follow ADR-001 and ADR-002.
2.  Claude CLI may only be accessed through ClaudeAdapter.
3.  Never expose CLI DTOs to UI.
4.  Never fabricate usage values.
5.  Every task must compile, pass analyze and tests.
6.  Architecture changes require a new ADR.
7.  Continue automatically unless blocked by an ADR-worthy decision.

## Autonomous Workflow

### Phase A

-   T-003 Core Infrastructure
-   T-004 Dependency Injection
-   T-005 Bootstrap

Gate A: - Clean analyze - Tests pass

### Phase B

-   T-006 Claude Adapter
-   T-007 Process Runner
-   T-008 Parser
-   T-009 Validator
-   T-010 Repository
-   T-011 Cache
-   T-012 Refresh Service

Gate B: - Shape A supported - Shape B soft failure - Parser fixtures
pass - Cache validated

### Phase C

-   T-013 Tray/Menu Bar
-   T-014 Popup
-   T-015 Refresh wiring
-   T-016 Settings
-   T-017 Launch at Login
-   T-018 Notifications

Gate C: - Working tray - Live refresh - Manual refresh - Stale/live
indicators

### Phase D

-   T-019 Error UX
-   T-020 Accessibility
-   T-021 Packaging

Gate D: - macOS build - Windows ready - Tests green

## Task Report Format

For every task provide: - Objective - Files changed - Tests - Risks -
Conventional Commit - Architecture Impact - Completion checklist

Proceed to the next task automatically unless blocked.

## Definition of Done

-   Compiles
-   flutter analyze clean
-   Tests pass
-   ADR compliant
-   Docs updated if needed

## Stop Conditions

Stop only if: - CLI output changes incompatibly. - New ADR required. -
MVP scope changes. - Security/privacy issue discovered.

## Final Deliverables

When MVP is complete provide: 1. Implementation summary 2. Remaining
technical debt 3. v1.1 roadmap 4. Release checklist

Do not implement post-MVP features without Product Owner approval.
