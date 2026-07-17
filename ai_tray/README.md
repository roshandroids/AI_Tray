# AI Tray

Flutter desktop companion for Claude Code subscription usage (macOS menu bar / Windows system tray).

**Status:** Provider framework through PD-021
**Docs:** [../docs/README.md](../docs/README.md) · [Provider architecture](../docs/architecture/provider-platform.md) · [Install](../docs/guides/installation.md)

## Prerequisites

- Flutter stable (3.38+ / Dart 3.10+)
- macOS: Xcode + CocoaPods as required by Flutter desktop
- Windows: Visual Studio desktop workload (Windows builds only on Windows hosts)
- Claude Code CLI installed and authenticated (`claude auth login`)

## Run (macOS)

```bash
cd ai_tray
flutter pub get
flutter run -d macos
```

## Analyze & test

```bash
cd ai_tray
flutter analyze
flutter test
```

## Build (macOS Release)

```bash
cd ai_tray
flutter build macos --release
# → build/macos/Build/Products/Release/AI Tray.app
```

Windows: `flutter build windows --release` on a Windows host. See [packaging](../docs/release/RH-003-packaging.md).

## Layout

Feature-first Clean Architecture under `lib/`. See [folder structure](../docs/architecture/folder-structure.md) and [architecture overview](../docs/guides/architecture-overview.md).

## Scope

Included: provider registry and capabilities, Claude CLI usage pipeline, disabled
Copilot scaffold, capability-driven dashboard, tray shell, settings, LKG cache,
and Shape A/B handling.

Copilot parsing, authentication, and activation remain intentionally out of
scope. See [known limitations](../docs/guides/known-limitations.md).
