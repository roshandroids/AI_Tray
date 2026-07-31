# Bug handling

**Updated:** 2026-07-31  
Related: [DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md) ·
[`docs/dogfood/bug-triage-template.md`](../dogfood/bug-triage-template.md) ·
[`SUPPORT.md`](../../SUPPORT.md)

---

## Intake

1. Confirm it is not a known limitation
   ([`guides/known-limitations.md`](../guides/known-limitations.md),
   [`release/known-issues.md`](../release/known-issues.md)).
2. Open a Bug Issue (`.github/ISSUE_TEMPLATE/bug_report.yml`) or dogfood note.
3. Security → [`SECURITY.md`](../../SECURITY.md) only.

## Fix path

1. Reproduce on the reported platform/provider when possible.
2. Find root cause (parser, refresh, sidecar, UI state, packaging).
3. Fix at the correct layer — no temporary UI-only band-aids for data bugs.
4. Add a regression test when the failure is automatable.
5. PR with root cause + tests; update docs/handoff if behavior or process changed.

## Dogfood

Use [`docs/dogfood/`](../dogfood/) for daily observation and triage templates.
