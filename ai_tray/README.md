# AI Tray

Flutter desktop companion for Claude Code usage (macOS menu bar / Windows system tray).

**Status:** T-001 foundation complete. Feature implementation follows the approved MVP backlog.

## Prerequisites

- Flutter stable (3.38+ / Dart 3.10+)
- macOS: Xcode + CocoaPods as required by Flutter desktop
- Windows: Visual Studio desktop workload (for Windows builds)
- Claude Code CLI is **not** required for T-001

## Project layout

See `docs/architecture/folder-structure.md` in the repository root. Source lives under `lib/` with feature-first Clean Architecture placeholders.

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

## Build (macOS)

```bash
cd ai_tray
flutter build macos
```

## Scope boundary (T-001)

Included:

- Flutter desktop project (`macos`, `windows`)
- Approved folder skeleton
- Riverpod + logging wired via `bootstrap.dart`
- Blank foundation shell
- `very_good_analysis` lint baseline

Not included (later tasks):

- Claude CLI integration
- Tray / menu bar
- Settings, notifications, refresh services, business logic
