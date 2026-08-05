#!/usr/bin/env bash
# Zip release artifacts + SHA-256 checksums into dist/ (or --out DIR).
# Usage: package.sh macos|windows [--out DIR]
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

TARGET="${1:-}"
shift || true
OUT_DIR="${DIST_DIR}"
HOST="$(host_os)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT_DIR="$2"
      shift 2
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  case "${HOST}" in
    macos) TARGET=macos ;;
    windows) TARGET=windows ;;
    *)
      fail "No package target for host '${HOST}'. Pass macos|windows on a matching OS."
      ;;
  esac
  log "No target specified — packaging for host (${TARGET})"
fi

[[ -n "${TARGET}" ]] || fail "Usage: package.sh [macos|windows] [--out DIR]"
mkdir -p "${OUT_DIR}"
OUT_DIR="$(cd "${OUT_DIR}" && pwd)"

checksum() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${file}" | tee "${file}.sha256"
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${file}" | tee "${file}.sha256"
  else
    warn "No shasum/sha256sum — skipping checksum for ${file}"
  fi
}

case "${TARGET}" in
  macos|macos-arm64)
    APP_PATH="${APP_DIR}/build/macos/Build/Products/Release/${APP_NAME}.app"
    [[ -d "${APP_PATH}" ]] || fail "Missing ${APP_PATH} — run ./scripts/build.sh macos first"
    ZIP="${OUT_DIR}/AI-Tray-macOS-arm64.zip"
    rm -f "${ZIP}" "${ZIP}.sha256"
    log "ditto zip → ${ZIP}"
    (
      cd "$(dirname "${APP_PATH}")"
      ditto -c -k --sequesterRsrc --keepParent "$(basename "${APP_PATH}")" "${ZIP}"
    )
    checksum "${ZIP}"
    ;;
  windows|windows-x64)
    REL_DIR="${APP_DIR}/build/windows/x64/runner/Release"
    [[ -d "${REL_DIR}" ]] || fail "Missing ${REL_DIR} — run ./scripts/build.sh windows first"
    ZIP="${OUT_DIR}/AI-Tray-Windows-x64.zip"
    rm -f "${ZIP}" "${ZIP}.sha256"
    log "zip Windows release → ${ZIP}"
    if command -v powershell.exe >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
      PS=powershell.exe
      command -v pwsh >/dev/null 2>&1 && PS=pwsh
      # Git Bash auto-converts POSIX-looking paths in argv, but mangles one
      # embedded inside this quoted -Command string (e.g. /d/a/... becomes
      # D:\d\a\...). Pre-convert with cygpath and disable that conversion so
      # our already-native path passes through untouched.
      REL_DIR_WIN="${REL_DIR}"
      ZIP_WIN="${ZIP}"
      if command -v cygpath >/dev/null 2>&1; then
        REL_DIR_WIN="$(cygpath -w "${REL_DIR}")"
        ZIP_WIN="$(cygpath -w "${ZIP}")"
      fi
      MSYS_NO_PATHCONV=1 "${PS}" -NoProfile -Command \
        "Compress-Archive -Path '${REL_DIR_WIN}\\*' -DestinationPath '${ZIP_WIN}' -Force"
    elif command -v zip >/dev/null 2>&1; then
      (
        cd "${REL_DIR}"
        zip -r "${ZIP}" .
      )
    else
      fail "Need pwsh/powershell or zip to package Windows artifacts"
    fi
    checksum "${ZIP}"
    ;;
  *)
    fail "Unknown target: ${TARGET} (use macos|windows)"
    ;;
esac

log "package OK → ${ZIP}"
echo "${ZIP}"
