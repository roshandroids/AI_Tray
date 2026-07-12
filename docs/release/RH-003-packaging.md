# RH-003 — Packaging Validation

**Release:** v1.0.0-rc.1  
**Date:** 2026-07-12

---

## Tray icon assets

| Asset | Path | Status |
|--|--|--|
| macOS tray (template-capable PNG) | `ai_tray/assets/tray/tray_icon_32.png` | Present; declared in `pubspec.yaml` |
| Windows tray (ICO) | `ai_tray/assets/tray/tray_icon.ico` | Present; declared in `pubspec.yaml` |
| Code reference | `TrayController.start` → `assets/tray/...` | Updated for packaged builds |

**Note:** Flutter default app icons remain in platform runners; tray uses dedicated Flutter assets so Release bundles include them.

---

## Application icon

| Platform | Location | Status |
|--|--|--|
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (16–1024) | Present (Flutter default artwork) |
| Windows | `windows/runner/resources/app_icon.ico` | Present |

**RC1 limitation:** Icons are stock Flutter placeholders, not final brand art. Acceptable for dogfood; replace before public marketing.

---

## Bundle metadata

### macOS (`AppInfo.xcconfig` + Info.plist)

| Field | Value |
|--|--|
| `PRODUCT_NAME` | AI Tray |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.aitray.app` |
| `PRODUCT_COPYRIGHT` | Copyright © 2026 AI Tray. All rights reserved. |
| `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` ← pubspec version name |
| `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` ← pubspec build number |

### Windows (`Runner.rc`)

| Field | Behavior |
|--|--|
| Icon | `IDI_APP_ICON` → `resources\app_icon.ico` |
| Version | Driven by Flutter `FLUTTER_VERSION_*` macros from pubspec |

---

## Version information

| Source | Value |
|--|--|
| `ai_tray/pubspec.yaml` | **`1.0.0-rc.1+1`** |
| Recommended git tag | **`v1.0.0-rc1`** |
| Stable release tag (later) | `v1.0.0` — only after dogfood |
| macOS `CFBundleShortVersionString` (observed) | Flutter may normalize pre-release to **`1.0.0.1`** in Info.plist — treat **pubspec + git tag** as the RC identity |

---

## Release packaging instructions

### macOS (this host)

```bash
cd ai_tray
flutter pub get
flutter analyze
flutter test
flutter build macos --release

# Artifact
open build/macos/Build/Products/Release/AI\ Tray.app
# Or copy the .app to /Applications for dogfood
```

Optional zip for distribution:

```bash
cd build/macos/Build/Products/Release
ditto -c -k --sequesterRsrc --keepParent "AI Tray.app" AI-Tray-1.0.0-rc.1-macos.zip
```

**Not in RC1:** notarization, Developer ID signing, Sparkle updates, DMG branding.

### Windows (Windows host required)

```bash
cd ai_tray
flutter pub get
flutter analyze
flutter test
flutter build windows --release
# Artifact under build/windows/x64/runner/Release/
```

---

## Packaging checklist

- [x] Tray assets in Flutter `assets/` and referenced by code
- [x] App icons exist for macOS + Windows runners
- [x] Bundle ID / product name set
- [x] Version bumped to RC1
- [x] Build instructions documented
- [ ] Code signing / notarization (deferred)
- [ ] Windows Release artifact produced on Windows CI/host (deferred)
- [ ] Custom brand icons (deferred to post-dogfood / v1.0.0 polish)
