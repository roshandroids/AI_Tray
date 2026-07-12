# S-005 — QA Expansion

**Date:** 2026-07-12  
**Gate:** Increased coverage and passing suite — **PASS**

## Objective

Expand automated tests: cache, refresh, repository, adapter, error paths.

## Summary

| Area | Coverage added |
|--|--|
| Adapter | `/usage` args, binary path, non-zero exit, bad JSON, auth/CLI health |
| Cache | InMemory + SharedPreferences round-trip + corrupt JSON |
| Refresh | Timeout keeps LKG; unknown output does not invent cache |
| Repository | Success status; CLI missing pause; timeout retains cache |
| Stability | 500-cycle + single-flight |

Sleep/wake: not automated (platform); remains dogfood / RH-002.

## Files changed

- `test/unit/adapter/claude_cli_adapter_test.dart`
- `test/unit/cache/usage_cache_test.dart`
- `test/unit/repository/usage_repository_test.dart`
- `test/unit/refresh/refresh_service_test.dart` (error paths)
- Plus S-002/S-003 tests

## Tests

`flutter analyze` clean · **`flutter test` → 56 passed**

## Metrics

34 → **56** tests.

## Risks

Widget/tray integration still thin.

## Conventional Commit

`test: expand adapter, cache, repository, and refresh coverage`

## Architecture Impact

None.

## Recommendation

Proceed to S-006.
