# Showcase contract

Portal metadata for **RSProjects Showcase** so this product remains the source of truth for AI Tray.

| Path | Role |
|------|------|
| [`metadata.json`](metadata.json) | Catalog + showcase sections |
| [`demos.json`](demos.json) | Multi-demo index (SSOT for discoverable demos) |
| [`media/`](media/) | Prefer linking or copying screenshots from `docs/assets/screenshots/` |
| `schema.json` | Future — shared validation |
| `examples.json` | Future — example index |

## Demos (product-as-demo)

This repository is an **application/product**. Per the RSProjects Demo Standard,
the application itself is the demo — do not add a duplicate playground.

| id | Title | Type | Launch |
|----|-------|------|--------|
| `main` | AI Tray | `desktop` | [Latest Release](https://github.com/roshandroids/AI_Tray/releases/latest) |

- Local: `cd ai_tray && flutter run -d macos` (or `windows`)
- CI publish: [`.github/workflows/release.yml`](../.github/workflows/release.yml)
- Strategy: [`docs/devops/DEMO_STRATEGY.md`](../docs/devops/DEMO_STRATEGY.md)
- Web-demo reusable workflow (other RSProjects only): [`.github/workflows/reusable-flutter-web-demo.yml`](../.github/workflows/reusable-flutter-web-demo.yml)

Showcase must discover and launch entries from `demos.json` — not invent URLs.

Project Integration: [rsprojects-showcase — PROJECT_INTEGRATION.md](https://github.com/roshandroids/rsprojects-showcase/blob/main/docs/PROJECT_INTEGRATION.md) · [PROJECT_ONBOARDING.md](https://github.com/roshandroids/rsprojects-showcase/blob/main/docs/PROJECT_ONBOARDING.md)

**Note:** A root `LICENSE` file is not present in this repository yet; add one when publishing publicly so the onboarding prerequisites are fully met.
