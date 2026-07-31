#!/usr/bin/env bash
# Build desktop release binary for the host platform (or an explicit target).
# Usage: build.sh [macos|windows]
#   No args → build for the current host OS (macOS or Windows only).
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

HOST="$(host_os)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"

if [[ -z "${TARGET}" ]]; then
  case "${HOST}" in
    macos) TARGET=macos ;;
    windows) TARGET=windows ;;
    *)
      fail "No desktop target for host '${HOST}'. Pass macos|windows on a matching OS, or use Release CD for the other platform."
      ;;
  esac
  log "No target specified — building for host (${TARGET})"
fi

case "${TARGET}" in
  macos|macos-arm64)
    [[ "${HOST}" == "macos" ]] || fail "Cannot build macOS on host '${HOST}'. Run on macOS, or ship via Release CD (tag push)."
    SIDECAR="macos-arm64"
    bash "${SCRIPT_DIR}/bridge.sh" --assemble "${SIDECAR}"
    cd_app
    require_cmd flutter
    log "flutter pub get"
    flutter pub get
    log "flutter build macos --release"
    COPILOT_SIDECAR_TARGET="${SIDECAR}" flutter build macos --release
    node "${BRIDGE_DIR}/scripts/verify_payload.mjs" \
      "${APP_DIR}/build/macos/Build/Products/Release/${APP_NAME}.app/Contents/Resources/copilot_sdk"
    log "macOS arm64 build OK"
    ;;
  windows|windows-x64)
    [[ "${HOST}" == "windows" ]] || fail "Cannot build Windows on host '${HOST}'. Run on Windows, or ship via Release CD (tag push)."
    SIDECAR="windows-x64"
    bash "${SCRIPT_DIR}/bridge.sh" --assemble "${SIDECAR}"
    cd_app
    require_cmd flutter
    log "flutter pub get"
    flutter pub get
    log "flutter build windows --release"
    flutter build windows --release
    node "${BRIDGE_DIR}/scripts/verify_payload.mjs" \
      "${APP_DIR}/build/windows/x64/runner/Release/copilot_sdk"
    log "Windows x64 build OK"
    ;;
  linux|ios|android)
    fail "Target '${TARGET}' is not a published AI Tray artifact (ship macOS arm64 + Windows x64 only via Release CD)"
    ;;
  *)
    fail "Unknown target: ${TARGET} (use macos|windows, or omit to auto-detect host)"
    ;;
esac
