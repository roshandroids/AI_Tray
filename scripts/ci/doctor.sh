#!/usr/bin/env bash
# Developer environment validation (non-destructive).
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

PASS=0
FAIL=0
WARN=0

ok() { printf '  %sOK%s  %s\n' "${GREEN}" "${NC}" "$*"; PASS=$((PASS + 1)); }
bad() { printf '  %sFAIL%s %s\n' "${RED}" "${NC}" "$*"; FAIL=$((FAIL + 1)); }
soft() { printf '  %sWARN%s %s\n' "${YELLOW}" "${NC}" "$*"; WARN=$((WARN + 1)); }

have() { command -v "$1" >/dev/null 2>&1; }

echo "AI Tray doctor (host=$(host_os), preferred CI_MODE=${CI_MODE})"
echo "Pins: Flutter ${FLUTTER_VERSION} · Node ${NODE_VERSION} · npm ${NPM_VERSION}"
echo

# Git
if have git; then ok "git $(git --version | awk '{print $3}')"; else bad "git missing"; fi

# Flutter / Dart
if have flutter; then
  FV="$(flutter --version 2>/dev/null | head -1 | sed -n 's/.*Flutter \([0-9.]*\).*/\1/p' || true)"
  if [[ -z "${FV}" ]]; then
    FV="$(flutter --version 2>/dev/null | awk '/Flutter/{print $2; exit}' || true)"
  fi
  if [[ "${FV}" == "${FLUTTER_VERSION}" ]]; then
    ok "flutter ${FV}"
  elif [[ -n "${FV}" ]]; then
    soft "flutter ${FV} (pinned ${FLUTTER_VERSION} — GHA uses the pin)"
  else
    soft "flutter present but version unreadable"
  fi
else
  bad "flutter missing"
fi

if have dart; then
  DV="$(dart --version 2>&1 | sed -n 's/.*version \([0-9.]*\).*/\1/p' | head -1 || true)"
  if [[ -n "${DV}" ]]; then
    ok "dart ${DV}"
  else
    soft "dart present but version unreadable"
  fi
else
  bad "dart missing"
fi

# Node / npm (Copilot bridge)
if have node; then
  ok "node $(node --version 2>/dev/null || echo unknown)"
else
  bad "node missing (required for Copilot bridge)"
fi

if have npm; then
  NV="$(npm --version 2>/dev/null || true)"
  if [[ "${NV}" == "${NPM_VERSION}" ]]; then
    ok "npm ${NV}"
  elif [[ -n "${NV}" ]]; then
    soft "npm ${NV} (pinned ${NPM_VERSION})"
  else
    soft "npm present but version unreadable"
  fi
else
  bad "npm missing"
fi

# GitHub CLI (local publish/tag helpers)
if have gh; then
  ok "gh $(gh --version | head -1)"
else
  soft "gh missing (optional locally; Release CD uses GITHUB_TOKEN)"
fi

# Ruby (workflow YAML parse)
if have ruby; then
  ok "ruby $(ruby -e 'print RUBY_VERSION')"
else
  soft "ruby missing (needed for ./scripts/check.sh workflows)"
fi

OS="$(host_os)"
if [[ "${OS}" == "macos" ]]; then
  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode CLT ($(xcode-select -p))"
  else
    bad "Xcode command line tools missing (xcode-select -p failed)"
  fi
  if have xcodebuild; then
    ok "xcodebuild present"
  else
    bad "xcodebuild missing (macOS desktop builds)"
  fi
  if have pod; then
    ok "CocoaPods $(pod --version 2>/dev/null | head -1)"
  else
    soft "CocoaPods (pod) missing — may be required for some macOS plugin builds"
  fi
elif [[ "${OS}" == "windows" ]]; then
  soft "Windows host — ensure Visual Studio C++ desktop workload for flutter build windows"
elif [[ "${OS}" == "linux" ]]; then
  soft "Linux host — AI Tray does not publish Linux desktop artifacts (use Release CD for macOS/Windows)"
fi

# Android not used for product; soft note only if sdk present
if [[ -n "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]]; then
  soft "Android SDK detected but unused by AI Tray desktop product"
else
  soft "Android SDK not configured (not required for AI Tray)"
fi

echo
echo "Summary: ${PASS} ok · ${WARN} warn · ${FAIL} fail"
if [[ "${FAIL}" -gt 0 ]]; then
  fail "doctor found ${FAIL} blocking issue(s)"
fi
log "doctor passed (warnings are non-blocking)"
