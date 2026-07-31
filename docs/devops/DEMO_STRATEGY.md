# Demo Strategy — AI Tray

**Updated:** 2026-07-27  
**Decisions:** PD-025 / D-016  
**Showcase contract:** [`showcase/demos.json`](../../showcase/demos.json)

## RSProjects Demo Standard (applied)

| Rule | Application here |
|------|------------------|
| Every repo exposes ≥1 runnable demonstration | Yes — the **product** `ai_tray` |
| Library/package → playground demos | N/A — this is an application/product |
| Application/product → app itself is the demo | **Yes** — no duplicate playground |
| Do not create playgrounds that duplicate the product | Enforced |

## Step 1 — Audit

| Item | Status | Recommendation |
|------|--------|----------------|
| Repository type | **Product / application** (single Flutter desktop app under `ai_tray/`) | Treat product as the demo; do not add `examples/*_demo` |
| Runnable demonstration | **Yes** — `ai_tray` (macOS + Windows) | Keep product as SSOT; document local run + Releases |
| Demo sufficient for showcasing | **Yes** for desktop tray product; screenshots under `docs/assets/screenshots/` | Showcase launches Releases / download CTA, not an iframe |
| Web deployment | **No** — no `web/` platform; tray/CLI/sidecar are native | Do not invent Flutter Web hosting |
| Release distribution | **Yes** — GitHub Releases (`AI-Tray-macOS-arm64.zip`, `AI-Tray-Windows-x64.zip`) | Primary distribution path |
| CI builds the demo/product | **Yes** — [`release.yml`](../../.github/workflows/release.yml) on tag / `workflow_dispatch` | Quality analyzes/tests on PR; Release publishes artifacts |
| Separate playground | Absent (correct) | Do not create one |
| Showcase metadata | Present | `demos.json` lists `id: main` (type `desktop`) |

### Why no extra playground

Realistic AI Tray usage requires menu-bar/tray, `window_manager`, Claude CLI, and
the Copilot Node sidecar. A second “demo app” would duplicate the product and
still could not embed on the web. Per the Demo Standard: **the application is
the demo.**

## Step 2 — Decision

**Product repository path:** improve the existing product experience — do not
create another demo application.

| Requirement | Status |
|-------------|--------|
| Builds successfully | Local: `flutter run -d macos\|windows`; CI Release builds desktop |
| CI produces distributable artifacts | `release.yml` → GitHub Release assets |
| Release process documented | [`docs/release/CI-CD.md`](../release/CI-CD.md) |
| Web deployment (if applicable) | Not applicable |
| Showcase metadata references runnable product | [`showcase/demos.json`](../../showcase/demos.json) → `demos[0].id = main` |

## Repository structure (kept)

```text
ai_tray/                 # product = the demo
showcase/
  metadata.json
  demos.json             # multi-demo index (product entry)
  README.md
  media/
docs/devops/DEMO_STRATEGY.md
.github/workflows/
  quality.yml            # analyze / test (PR)
  release.yml            # build + publish product artifacts
  reusable-flutter-web-demo.yml  # for other RSProjects; unused here
```

## How to run locally

```bash
cd ai_tray
flutter pub get
flutter run -d macos    # or: flutter run -d windows
```

## How the demo is distributed

1. Bump / tag via release scripts (see CI-CD.md).
2. [`release.yml`](../../.github/workflows/release.yml) builds macOS arm64 + Windows x64.
3. Publishes a GitHub Release with zip assets.
4. Showcase discovers [`demos.json`](../../showcase/demos.json) and launches
   `url` / `download` (latest Releases page).

Latest: https://github.com/roshandroids/AI_Tray/releases/latest

## Showcase contract

```json
{
  "id": "main",
  "title": "AI Tray",
  "type": "desktop",
  "url": "https://github.com/roshandroids/AI_Tray/releases/latest",
  "download": "https://github.com/roshandroids/AI_Tray/releases/latest"
}
```

- `type: desktop` — not `flutter-web`
- `policy.webEmbed: unavailable` — portal must not expect an iframe
- Multiple demos supported structurally; AI Tray has one product demo today

[`metadata.json`](../../showcase/metadata.json) `showcase.demo` notes desktop
download availability and points at `demos.json`.

## CI/CD

| Workflow | Role |
|----------|------|
| **Quality** | Format / Analyze / Test on PR — product quality gate |
| **Release** | Builds and publishes the runnable product (the demo) |
| **Documentation** | Handoff / docs validation |
| **Maintenance** | Dependency outdated reports |
| **reusable-flutter-web-demo** | Callable template for library repos with web demos — **not used by AI Tray** |

No CI change required beyond documenting product-as-demo; Release already
publishes distributable artifacts.

## Adding another demo later

Only if a **distinct** non-duplicate surface appears (e.g. a documented web-safe
slice that is not a second tray app):

1. Append to `demos.json` (new `id`).
2. If web: call `reusable-flutter-web-demo.yml` and set `type: flutter-web`.
3. Update this doc and the handoff package.

Do **not** clone `ai_tray` into `examples/ai_tray_demo`.

## Related

- [CI-CD.md](../release/CI-CD.md)
- [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md)
- [showcase/README.md](../../showcase/README.md)
- [RSProjects PROJECT_INTEGRATION.md](https://github.com/roshandroids/rsprojects-showcase/blob/main/docs/PROJECT_INTEGRATION.md)
