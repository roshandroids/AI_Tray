# Required status checks

| PR type | Required context |
|---------|------------------|
| Feature → main | `quality / Quality` |
| `release/*` → main | `quality / Quality` plus green `build / Build (macos)` and `build / Build (windows)` (discipline; ruleset requires Quality for all PRs) |

Tag publish is not a merge gate.
