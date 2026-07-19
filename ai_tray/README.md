# AI Tray

Flutter desktop companion for Claude Code and GitHub Copilot subscription usage
(macOS menu bar / Windows system tray).

**Status:** Multi-provider platform through EP-002 (v1.3.3)
**Docs:** [../docs/README.md](../docs/README.md) ·
[Provider architecture](../docs/architecture/provider-platform.md) ·
[GitHub Copilot](../docs/providers/github-copilot.md) ·
[Install](../docs/guides/installation.md)

## Prerequisites

- Flutter stable (3.38+ / Dart 3.10+)
- macOS: Xcode + CocoaPods as required by Flutter desktop
- Windows: Visual Studio desktop workload (Windows builds only on Windows hosts)
- Claude Code CLI installed and authenticated (`claude auth login`) for Claude
- GitHub Copilot authentication available to the bundled SDK sidecar for Copilot

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

Golden / screenshot suites are tagged and skipped by default in routine runs:

```bash
flutter test --tags golden
flutter test test/screenshot/readme_screenshots_test.dart --tags screenshot
```

## Build (macOS Release)

```bash
cd ai_tray
flutter build macos --release
# → build/macos/Build/Products/Release/AI Tray.app
```

Windows: `flutter build windows --release` on a Windows host. See
[packaging](../docs/release/RH-003-packaging.md).

Published GitHub Releases currently ship **macOS arm64** and **Windows x64**.

## Layout

Feature-first Clean Architecture under `lib/`. See
[folder structure](../docs/architecture/folder-structure.md) and
[architecture overview](../docs/guides/architecture-overview.md).

## Scope

Included: provider registry and capabilities, Claude CLI usage pipeline, GitHub
Copilot SDK sidecar + experimental quota mapping, capability-driven dashboard,
persisted provider selection, tray shell, settings, diagnostics, logs, LKG
cache, and Shape A/B Claude handling.

Copilot quota uses the official experimental `account.getQuota` RPC and degrades
gracefully when unavailable. See
[known limitations](../docs/guides/known-limitations.md).
