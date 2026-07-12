# S-003 — Parser Hardening

**Date:** 2026-07-12  
**Gate:** Parser suite green — **PASS**

## Objective

Expand fixtures/regression coverage; validate Shape A/B and unknown handling; review CLI compatibility.

## Summary

Added fixtures: decimal %, ASCII dot separator, minimal Shape B, empty, auth prompt, unknown blurb. Expanded parser + validator assertions. No invented percentages on unknown/auth text.

### CLI compatibility review

| Topic | Finding |
|--|--|
| Command | Still `claude -p '/usage' --output-format json` (ADR-001) |
| Shape A | Session + week lines with `·` or `.` separators |
| Shape B | Contribution analytics without session % |
| Risk | Free-text churn remains — keep fixtures current during dogfood |

No parser code change required beyond fixtures/tests for RC1 formats observed.

## Files changed

- `test/fixtures/claude_usage/*` (new samples)
- `test/unit/parser/usage_parser_test.dart` (expanded)

## Tests

Parser suite green within full `flutter test`.

## Metrics

Parser-focused cases: 10 (was 4).

## Risks

Future Claude Code wording changes — dogfood captures → new fixtures.

## Conventional Commit

`test: expand Claude usage parser fixtures and regressions`

## Architecture Impact

None.

## Recommendation

Proceed to S-004.
