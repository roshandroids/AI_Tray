# AI Tray

Flutter desktop companion for Claude Code subscription usage (macOS menu bar / Windows system tray).

**Status:** **v1.0.0-rc.2** (`1.0.0-rc.2+2`) · dogfooding · feature freeze (PD-011)  
**Docs:** [../docs/README.md](../docs/README.md) · [RC2 notes](../docs/release/release-notes-v1.0.0-rc2.md) · [Install](../docs/guides/installation.md)

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

## Scope (RC1)

Included: Claude CLI usage pipeline, tray shell, settings (interval, auto-refresh, notifications threshold, launch at login, CLI path), LKG cache, Shape A/B handling.

Not authorized without PO approval: analytics, charts, multi-provider, multi-account, UI redesigns, new settings, architecture refactors.
