# AI Tray --- Phase 2 Stabilization Checklist

## Autonomous Iteration Plan (Cursor)

**Status:** v1.0.0-rc1 Accepted\
**Objective:** Produce a General Availability (GA) release through
stabilization only.

------------------------------------------------------------------------

# Mission

Improve reliability, quality, and release readiness **without adding new
user-facing features**.

## Success Criteria

-   Stable for daily use
-   Cross-platform verified
-   Clean architecture preserved
-   No critical known defects
-   Ready for v1.0.0 GA

------------------------------------------------------------------------

# Rules

-   No feature creep.
-   No architecture rewrites.
-   Respect ADR-001 and ADR-002.
-   Any new architecture decision requires a new ADR.
-   Work sequentially.
-   Continue automatically unless a blocker requires Product Owner
    input.

------------------------------------------------------------------------

# S-001 Windows Verification

-   Build on Windows
-   Fix build issues
-   Verify startup
-   Verify tray
-   Verify notifications
-   Verify launch-at-login
-   Produce Windows validation report

**Gate:** Windows build passes.

------------------------------------------------------------------------

# S-002 Long-running Stability

-   Run 6--12 hour refresh session
-   Verify no memory leaks
-   Verify no stale timer issues
-   Verify cache behavior
-   Record findings

**Gate:** No critical reliability issues.

------------------------------------------------------------------------

# S-003 Parser Hardening

-   Add new parser fixtures
-   Regression tests
-   Unknown-output handling
-   Shape A/B validation
-   Future CLI compatibility review

**Gate:** Parser suite green.

------------------------------------------------------------------------

# S-004 Performance

-   Measure startup time
-   Refresh latency
-   Idle CPU
-   Idle RAM
-   Optimize obvious bottlenecks only

**Gate:** Performance report complete.

------------------------------------------------------------------------

# S-005 QA Expansion

-   Cache tests
-   Refresh tests
-   Repository tests
-   Adapter tests
-   Error-path tests
-   Sleep/wake scenarios where practical

**Gate:** Increased coverage and passing suite.

------------------------------------------------------------------------

# S-006 Packaging

-   Verify icons
-   Bundle metadata
-   Versioning
-   Release packaging instructions

------------------------------------------------------------------------

# S-007 Documentation

-   Update README
-   Update troubleshooting
-   Update known issues
-   Synchronize architecture docs
-   Verify links

------------------------------------------------------------------------

# S-008 Technical Debt Review

Categorize: - Must fix before GA - Can wait for v1.0.1 - Candidate for
v1.1

Do not implement deferred items.

------------------------------------------------------------------------

# S-009 Dogfooding Support

Prepare: - Issue template - Daily observation log - Bug triage
template - Feedback checklist

------------------------------------------------------------------------

# S-010 Release Candidate Evaluation

Create: - GA Readiness Report - Open defects - Risks - Recommendation

Choose exactly one:

-   Ready for GA
-   Ship RC2
-   Continue stabilization

Stop and wait for Product Owner approval.

------------------------------------------------------------------------

# Deliverable Template

For each checklist item provide:

-   Objective
-   Summary
-   Files changed
-   Tests
-   Metrics
-   Risks
-   Conventional Commit
-   Architecture Impact
-   Recommendation

------------------------------------------------------------------------

# Stop Conditions

Stop immediately if: - Claude CLI output changes incompatibly - New
architecture decision required - Security/privacy issue found - Scope
expansion proposed

------------------------------------------------------------------------

# Definition of Done

Each checklist item: - Builds successfully - flutter analyze clean -
Tests pass - Documentation updated - No regression introduced

------------------------------------------------------------------------

# Final Deliverables

-   Stabilization Report
-   Windows Validation Report
-   Performance Report
-   QA Report
-   Technical Debt Review
-   GA Recommendation

After S-010, stop. Do not begin v1.1 without Product Owner approval.
