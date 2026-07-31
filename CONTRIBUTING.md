# Contributing

Thanks for helping with AI Tray. This is a **solo-maintained** open-source
Flutter desktop companion — keep changes small, issue-linked, and reviewable.

## Day-1 path

1. **Handoff** — [`docs/project/AI_HANDOFF.md`](docs/project/AI_HANDOFF.md),
   [`PROJECT_CONTEXT.json`](docs/project/PROJECT_CONTEXT.json),
   [`NEXT_SESSION.md`](docs/project/NEXT_SESSION.md)
2. **Docs map** — [`docs/README.md`](docs/README.md)
3. **Run** — from `ai_tray/`: `flutter pub get` then `flutter run -d macos`
4. **Local quality** — [`docs/devops/LOCAL_DEVELOPMENT.md`](docs/devops/LOCAL_DEVELOPMENT.md)
5. **Dogfood** — [`docs/dogfood/README.md`](docs/dogfood/README.md)

AI agents: start at [`AGENTS.md`](AGENTS.md).

## Workflow

```
GitHub Issue → Feature branch → Implementation → Tests → Pull Request → Maintainer approval → Merge
```

1. Open or claim an Issue (templates under [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/)).
2. Branch from up-to-date `main` (do not push directly to `main`).
3. Follow Clean Architecture + Riverpod patterns already in `ai_tray/lib/`.
4. Architectural changes need an ADR under [`docs/adr/`](docs/adr/) and an entry
   in [`docs/project/DECISION_LOG.md`](docs/project/DECISION_LOG.md).
5. Add or update tests with behavior changes.
6. Open a PR with the [PR template](.github/PULL_REQUEST_TEMPLATE.md); link the Issue.
7. Ensure required Quality CI checks pass (see below).
8. Update the handoff package when product/architecture/process state changes
   (see [`.cursor/rules/project-handoff.mdc`](.cursor/rules/project-handoff.mdc)).

## Required CI checks (EP-004A)

PRs must pass **Ubuntu Quality CI** only:

| Required | Not required |
| --- | --- |
| Format | Build macOS |
| Analyze | Build Windows |
| Test | Desktop packaging |
| Validate workflows | |

Desktop binaries build only on **Release CD** (tag / `workflow_dispatch`).
Details: [`docs/release/CI-CD.md`](docs/release/CI-CD.md).

## Local validation

```bash
cd ai_tray
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --exclude-tags golden,screenshot
```

Copilot sidecar:

```bash
cd ai_tray/tool/copilot_sdk_bridge
npm ci
npm run check
```

Optional Lefthook: `lefthook install` from repo root.

## Hard constraints

- Do **not** invent usage values; label stale / LKG data.
- Do **not** use `/copilot_internal`, undocumented APIs, or scraping.
- Do **not** implement Cursor personal quota (PD-023).
- Do **not** add a Flutter Web playground of the tray (PD-025).
- Prefer targeted cleanup over rewrites (ADR-004 / PD-024).
- UI never calls CLI/SDK/APIs directly — go through repositories.

## Documentation

- Prefer updating existing docs over creating duplicates.
- Archive outdated material; do not delete history without reason.
- Keep-a-Changelog entries belong in root [`CHANGELOG.md`](CHANGELOG.md) when
  user-facing behavior ships.

## Ownership

Owned by **Roshan Shrestha** — see [`OWNERSHIP.md`](OWNERSHIP.md). Maintainer
approval is required before merge.
