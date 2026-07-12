# AI Tray / Claude Companion

## Product Owner Master Roadmap (v1.0)

> **Purpose**
>
> This document is the single source of truth for the project.
> Cursor/Claude should use it as the primary planning document before
> implementing any code.

------------------------------------------------------------------------

# Executive Summary

Build a lightweight Flutter desktop application that lives in the macOS
menu bar and Windows system tray, providing developers with instant
visibility into their Claude Code usage.

The application should be architected as a provider-based platform so
additional AI providers (ChatGPT, Gemini, Cursor, etc.) can be added
without redesigning the application.

------------------------------------------------------------------------

# Product Vision

Create the best native desktop companion for AI-assisted software
development.

Initial focus: - Claude Code usage

Future: - Multi-provider dashboard - Usage analytics - Notifications -
Developer productivity hub

------------------------------------------------------------------------

# Product Principles

1.  Research before implementation.
2.  Documentation before coding.
3.  Small MVP with rapid validation.
4.  Clean Architecture.
5.  Flutter-first.
6.  Native desktop experience.
7.  Provider-agnostic design.
8.  Testable, maintainable, extensible.

------------------------------------------------------------------------

# Recommendations

## Recommendation 1 --- Validate the core assumption first

The largest technical risk is retrieving reliable usage information.

**Do not build the Flutter app until this is validated.**

Build a proof of concept that determines whether the Claude CLI can be
the application's official data source.

Success criteria: - Launch Claude CLI - Retrieve usage - Parse output
reliably - Confirm cross-platform support

------------------------------------------------------------------------

## Recommendation 2 --- Prefer Claude CLI over web scraping

Priority:

1.  Claude CLI
2.  Official API (if available)
3.  Browser companion extension
4.  Browser automation
5.  Reverse-engineered web requests

Reason: - Simpler - More maintainable - Fewer breaking changes

------------------------------------------------------------------------

## Recommendation 3 --- Build a platform, not a one-off tool

Even if the MVP only supports Claude, the architecture should support
multiple providers.

Create a provider interface from day one.

------------------------------------------------------------------------

## Recommendation 4 --- Separate responsibilities

Product Owner (ChatGPT) - Vision - Requirements - Prioritization -
Backlog - Acceptance criteria

Lead Engineer (Roshan) - Engineering decisions - Reviews - Final
approval

Cursor / Claude - Implementation - Refactoring - Tests - Documentation
updates

------------------------------------------------------------------------

# Project Lifecycle

Research ↓ Planning ↓ Execution ↓ QA ↓ Release

------------------------------------------------------------------------

# Phase 1 --- Research

## R1 Claude CLI Investigation (Highest Priority)

Questions: - Can `/usage` be executed programmatically? - Is there a
non-interactive command? - JSON output? - Stable output? -
Cross-platform? - Auth requirements? - Polling overhead? - Does querying
usage consume quota?

Deliverable: research/claude-cli.md

Definition of Done: A working proof of concept.

------------------------------------------------------------------------

## R2 Flutter Process Management

Research: - Process.start - Process.run - stdin/stdout/stderr -
Long-running processes - Background execution - Process lifecycle

Deliverable: research/flutter-processes.md

------------------------------------------------------------------------

## R3 Desktop Integration

Evaluate: - tray_manager - window_manager - local_notifier -
launch_at_startup

------------------------------------------------------------------------

## R4 Storage

Compare: - Drift - Hive - SharedPreferences

Select one with documented rationale.

------------------------------------------------------------------------

## R5 Native Features

Research: - Menu bar - System tray - Notifications - Launch at startup

------------------------------------------------------------------------

# Phase 2 --- Planning

## Epic 0 Discovery

Deliverables: - Vision - Goals - Non-goals - Personas - Risks - Success
metrics - Product roadmap

## Epic 1 PRD

-   Functional requirements
-   Non-functional requirements
-   User stories
-   Acceptance criteria
-   Edge cases

## Epic 2 UX

-   Wireframes
-   User flows
-   Tray interactions
-   Settings
-   Notification flows

## Epic 3 Architecture

-   ADRs
-   Folder structure
-   Provider interface
-   Error handling
-   Logging
-   Dependency graph

## Epic 4 Engineering Planning

Every feature must contain: - Problem statement - Business value -
Requirements - Technical design - Tasks - Test checklist - Definition of
Done

------------------------------------------------------------------------

# Phase 3 --- Execution

## Milestone 1 Foundation

-   Flutter desktop
-   CI
-   Riverpod
-   Logging
-   Tray
-   Settings

## Milestone 2 Claude Integration

-   CLI adapter
-   Process manager
-   Usage parser
-   Cache
-   Refresh service

## Milestone 3 UX

-   Menu bar/system tray
-   Popup
-   Notifications
-   Settings

## Milestone 4 Analytics

-   History
-   Charts
-   Statistics

## Milestone 5 Provider Expansion

-   Provider abstraction
-   ChatGPT
-   Gemini
-   Cursor

------------------------------------------------------------------------

# Repository Structure

``` text
docs/
├── research/
├── planning/
├── execution/
├── architecture/
└── adr/

research/
├── claude-cli.md
├── flutter-processes.md
├── desktop-integration.md
├── storage.md
└── native-features.md

planning/
├── vision.md
├── roadmap.md
├── prd.md
├── user-stories.md
├── acceptance-criteria.md
└── product-principles.md

execution/
├── milestones.md
├── sprint-01.md
├── sprint-02.md
├── release-checklist.md
└── definition-of-done.md
```

------------------------------------------------------------------------

# MVP Scope

Included: - Tray/menu bar - Claude usage - Reset timer - Auto refresh -
Manual refresh - Settings - Notifications - Startup at login

Excluded: - Analytics - Multi-account - Multi-provider - Team features

------------------------------------------------------------------------

# Success Metrics

-   Startup \< 2 seconds
-   Refresh \< 5 seconds
-   Idle RAM \< 100 MB
-   Works on macOS & Windows
-   Stable CLI integration
-   No browser dependency for MVP

------------------------------------------------------------------------

# Immediate Next Task

**Task 0001 --- Claude CLI Proof of Concept**

Do not start the Flutter application.

First, prove that the installed Claude CLI can provide reliable usage
information suitable for powering the application.

Only after this task is complete should implementation begin.

**Project Status:** Discovery Phase
