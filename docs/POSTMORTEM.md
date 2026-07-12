# Postmortem — AI Tray MVP (v1.0.0-rc1)

**Project:** AI Tray (Claude Code usage companion)  
**Closed as:** `v1.0.0-rc1` (dogfooding phase)  
**Date:** 2026-07-12  
**Decision:** Product Owner Decision 008 — Close MVP and Prepare for Dogfooding

This document captures lessons learned from Research → Decisions → ADRs → Lightweight Planning → Incremental Implementation → Release Hardening → Dogfooding.

---

## Product

### Initial assumptions

1. Developers want glanceable Claude Code **subscription usage** in the menu bar / tray without opening a browser.
2. The **Claude CLI** can be a reliable primary data source (`/usage`).
3. A small Flutter desktop MVP is enough to validate the product before multi-provider expansion.
4. Provider-agnostic architecture should be sketched early so Claude is not a permanent dead-end.
5. “Usage” is a stable, parseable concept users can trust as percentages and reset times.
6. Cross-platform (macOS + Windows) could ship together in the first release candidate.

### Validated assumptions

1. **CLI-as-source works for MVP** when Shape A (`Current session` / weekly lines) is returned — PoC PASS WITH LIMITATIONS; ADR-001 accepted.
2. **Research-before-code** prevented building a UI on a broken data dependency.
3. **Feature freeze + release hardening** produced a shippable RC without scope creep.
4. **Cache + soft failure** is necessary product behavior, not optional polish — users would otherwise see blank or invented numbers.
5. **Clean Architecture + Riverpod** matched the team’s Flutter standards and kept CLI details out of UI.
6. **Approval gates** (stop after PoC / ADR / planning / RC) kept product thinking ahead of implementation.

### Invalid (or weakened) assumptions

1. **`/usage` is always Shape A.** Intermittent Shape B (contribution analytics only) is common under polling — MVP cannot treat every CLI success as usable usage.
2. **Windows parity in RC1.** Windows scaffolding exists, but Release build cannot be verified on a macOS-only host; Windows remains experimental until smoked elsewhere.
3. **PATH is shared between Terminal and GUI apps.** Homebrew `claude` often requires an absolute path override in Settings.
4. **“Never invent %” is enough UX.** Soft failures and stale cache need clear product language; otherwise “unavailable” feels like a bug.
5. **Stock Flutter icons / unsigned builds are fine for early users.** Acceptable for dogfood; friction for anyone else (Gatekeeper, brand trust).

### Scope decisions that mattered

| Decision | Outcome |
|--|--|
| Claude-only MVP; multi-provider deferred | Kept delivery focused |
| CLI over scraping / reverse-engineering | Lower legal and churn risk; still format-churn risk |
| No analytics / charts / redesign in RC1 | Feature freeze held |
| Soft failure + LKG cache (ADR-002) | Made Shape B survivable |
| Dogfood RC1 before v1.0.0 / v1.1 | Explicitly preferred over rushing features |
| macOS-first dogfood; Windows later | Honest platform claim |

### MVP evaluation

| Criterion | Assessment |
|--|--|
| Solves the core job (see Claude usage at a glance)? | **Yes** on macOS when Shape A is available |
| Data trustworthiness? | **Yes** — no fabricated percentages; cache rules documented |
| Ship quality for personal dogfood? | **Yes** — RC1 approved |
| Ready for public GA? | **No** — complete manual QA, dogfood, Windows if claimed |
| Ready for v1.1 features? | **No** — PO gate; dogfood first |

**Verdict:** The MVP is **complete as a product slice**. Value will be proven (or refined) in dogfooding, not by adding features immediately.

---

## Engineering

### Architecture decisions that worked well

1. **Feature-first Clean Architecture** (UI → state → domain → data) with Claude isolated behind an adapter.
2. **`ProcessRunner` abstraction** enabled FakeProcessRunner tests without spawning CLI in unit tests.
3. **Single-flight refresh + bounded intervals** reduced Shape B storms and duplicate work.
4. **Domain models + `Result` / `AppFailure` codes** made UI state predictable (live / stale / error).
5. **Flutter assets for tray icons** (RC packaging fix) — source-tree icon paths fail in packaged `.app`s.
6. **Keeping ADRs short and binding** — agents and humans shared the same constraints.

### ADRs that proved valuable

| ADR | Why it mattered |
|--|--|
| **ADR-001** (Claude CLI data source) | Locked command shape (`-p '/usage'`, no `--bare`), auth expectations, and “CLI is SoT for MVP” so implementation did not thrash into scraping |
| **ADR-002** (error handling & resilience) | Defined Shape B softFailure, cache ages, retries, auth/CLI pause, logging — prevented ad-hoc error UX during autonomous coding |

Without ADR-002, Shape B would likely have been mishandled as hard failure or fake zeros.

### Areas of unnecessary complexity

1. **Provider-agnostic ports sketched early** were valuable as future seams but lightly used in MVP — acceptable, not free.
2. **Some settings `copyWith` awkwardness** for clearing optionals — small API friction, not worth a mid-MVP redesign.
3. **Deep planning docs vs. thin runtime docs** initially — fixed in Release Hardening by adding guides; planning artifacts remain historically useful.

Nothing major was “over-engineered into failure”; the bigger risk was under-specifying resilience (caught by ADR-002).

### Technical debt intentionally accepted

See also [RH-005](release/RH-005-technical-debt.md). Highlights:

- Windows unverified on RC host  
- Placeholder icons; unsigned macOS distribution  
- `local_notifier` deprecated macOS APIs  
- Accessibility unaudited  
- Thin widget/integration coverage beyond parser/refresh/unit smoke  
- Free-text parser maintenance burden (known, mitigated with fixtures)

These were **conscious** trade-offs to reach dogfoodable RC1 under feature freeze.

---

## AI Development

### What enabled autonomous progress

1. A **written product roadmap** + **autonomous execution guide** with explicit phases and stop gates.
2. **Numbered Product Owner decisions** (001–008) that unblocked or froze work without ambiguity.
3. **PoC-first** evidence (`research/claude-cli.md`) before Flutter implementation.
4. **ADRs as executable policy** — agents could implement without re-litigating CLI vs API each turn.
5. **Definition-of-done style backlog** (T-00x) and phase gates (A/B/C/D, then RH-00x).
6. **Feature freeze language** that listed forbidden work (analytics, redesign, refactors).
7. **Verification commands** (`analyze`, `test`, `build`) as acceptance signals in the same loop as coding.

### Prompts / directives that were most effective

1. **Decision packets** with “do not implement X” + “stop after Y” + approval gate.
2. **ADR templates** demanding status, context, decision, consequences — not open-ended essays.
3. **“PASS WITH LIMITATIONS” PoC framing** — forced honest Shape A/B reporting.
4. **Release Hardening task list (RH-001…005)** with named final deliverables.
5. **Explicit non-goals** (no charts, no multi-provider, no architecture refactor).
6. **Dogfood-before-v1.1 recommendation** — prevented the classic “RC then immediately feature branch” failure mode.

### Where human (Product Owner) review added the most value

1. **Choosing CLI over premature multi-source architecture** while still requiring PoC proof.
2. **Insisting on ADR-002** before coding resilience ad hoc.
3. **Rejecting scope creep** into analytics / redesign during hardening.
4. **Reframing success as dogfood RC1**, not “tag v1.0.0 and start v1.1.”
5. **Calling out process quality** (research → decisions → ADRs → …) as the asset worth preserving.
6. **Repo / identity hygiene** (personal remote, author email) — operational correctness agents can miss.

### How future AI-led projects could improve

1. Extract the delivery progression into a reusable **`ai-product-playbook`** (see Future).
2. Require a **one-page “Decision Log”** index linking D-001…N next to ADRs.
3. Run **platform matrix smoke** (or document “macOS-only RC”) before claiming cross-platform.
4. Add a **dogfood log template** at kickoff of RC, not only at the end.
5. Keep **manual QA checklists** ready before implementation ends so hardening is not documentation-only.
6. Prefer **asset packaging checks** (icons in bundle) in the Release Hardening script, not as a late surprise.
7. Separate **product freeze** from **bugfix** language so agents do not refuse legitimate stability patches.

---

## Future

### Application (after dogfood — not authorized now)

- Promote to `v1.0.0` only after RH-002 + real usage notes  
- Windows smoke if Windows is in-scope  
- Parser fixture expansion from dogfood captures  
- Icon / notarization polish  
- Then consider [v1.1 roadmap](release/v1.1-product-roadmap.md) under new PO decisions

### Delivery process improvements

Preserve this progression as a standard:

```text
Research → Decisions → ADRs → Lightweight Planning
  → Incremental Implementation → Release Hardening → Dogfooding
```

Recommended extraction: a reusable **`ai-product-playbook`** for greenfield Flutter / internal tools with Cursor + Claude, including:

| Playbook asset | Purpose |
|--|--|
| Master roadmap template | Vision, principles, non-goals |
| Decision record template | Numbered PO decisions + gates |
| ADR starter set | Data source, resilience, packaging |
| PoC protocol | PASS / FAIL / PASS WITH LIMITATIONS |
| Autonomous execution guide | Phases, forbidden work, verify commands |
| Release hardening checklist | RH-style tasks + final deliverables |
| Dogfood protocol | 1–2 weeks, annoyance log, promote criteria |

**Principle to keep:** never let implementation outrun product thinking.

---

## Closure

| Item | State |
|--|--|
| MVP | **Complete** |
| RC1 | **Approved** |
| Features | **Frozen** — none authorized |
| Phase | **Dogfooding** until further PO direction |
| Next engineering | Stability fixes from dogfood only, unless PO reopens scope |

Official project close for MVP delivery: **v1.0.0-rc1**.
