# AI Tray Documentation & Engineering Upgrade Master Prompt

## How to execute

Complete one phase at a time.

After each phase: - Commit changes. - Update
docs/reports/v2-refactor-plan.md with completed status. - Continue
automatically to the next phase. - Stop only if blocked. - Do not modify
application logic unless explicitly required.

------------------------------------------------------------------------

# Phase 1 --- Repository Governance

Goal: Bring repository governance to production quality.

Tasks: - Add LICENSE - Add SECURITY.md - Add CODE_OF_CONDUCT.md - Add
SUPPORT.md - Add OWNERSHIP.md

Requirements: - Adapt for AI Tray. - Do not copy Document Platform
verbatim. - Update README only if necessary.

Commit: docs: add repository governance

------------------------------------------------------------------------

# Phase 2 --- Community & Contributor Experience

Tasks: - Add CONTRIBUTING.md - Add AGENTS.md - Add .github/CODEOWNERS -
Add PR template - Add Issue templates

Requirements: - Optimize for an open-source solo-maintained project. -
Keep documentation concise.

Commit: docs: add contributor documentation

------------------------------------------------------------------------

# Phase 3 --- Documentation Foundation

Tasks: - Organize docs/ - Create missing folders - Improve
docs/README.md - Add docs/process/ - Add document templates - Improve
navigation

Requirements: - Do not duplicate existing docs. - Consolidate when
appropriate. - Preserve links.

Commit: docs: organize documentation structure

------------------------------------------------------------------------

# Phase 4 --- Engineering Standard

Create:

docs/ENGINEERING_STANDARD.md

Document: - Folder structure - Feature structure - Naming -
Documentation rules - ADR workflow - Testing standards - CI standards -
Release workflow - Definition of Done - Code review checklist

Reference existing docs instead of duplicating them.

Commit: docs: add engineering standards

------------------------------------------------------------------------

# Phase 5 --- Project Blueprint

Create:

docs/PROJECT_BLUEPRINT.md

Include: - Product vision - Goals - Architecture overview - Repository
layout - Documentation map - Development workflow - Release workflow -
Roadmap overview - Getting started

Link existing docs whenever possible.

Commit: docs: add project blueprint

------------------------------------------------------------------------

# Phase 6 --- Cursor Rules

Compare AI Tray with Document Platform.

Keep only rules that improve AI Tray.

Do NOT copy every rule.

Document: - Added rules - Removed rules - Reasoning

Commit: docs: refine cursor rules

------------------------------------------------------------------------

# Phase 7 --- Documentation Cleanup

Audit all documentation.

Fix: - Broken links - Duplicate docs - Outdated docs - Conflicting
information - Orphaned documents

Mark deprecated docs instead of deleting when appropriate.

Create a cleanup summary.

Commit: docs: cleanup documentation

------------------------------------------------------------------------

# Phase 8 --- Validation

Perform a final documentation audit.

Verify: - Links - Navigation - Folder structure - Templates - Governance
docs - Contributor workflow - Documentation consistency

Create:

docs/reports/documentation-validation-report.md

Commit: docs: finalize documentation upgrade

------------------------------------------------------------------------

# Rules

-   Follow docs/reports/v2-refactor-plan.md.
-   Base decisions on the repository.
-   Do not invent architecture.
-   Do not rewrite working documentation without reason.
-   Prefer references over duplication.
-   Keep AI Tray independent from Document Platform.
-   Preserve project history.
-   Commit after every phase.
-   Continue automatically until all phases are complete or a blocker is
    encountered.
