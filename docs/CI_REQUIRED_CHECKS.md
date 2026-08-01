# Required status checks (GitHub ruleset)

After migrating to `roshandroids/platform-ci@v1`, required contexts are:

| Check | When |
|-------|------|
| `quality / Quality` | Every PR → main |

Optional (not required for merge): Deploy demos, Release (tags).

Do not require macOS/Windows builds on PRs.
