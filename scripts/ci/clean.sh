#!/usr/bin/env bash
# Remove Flutter build outputs and local dist artifacts.
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

cd_app
if command -v flutter >/dev/null 2>&1; then
  log "flutter clean"
  flutter clean || true
fi

cd_root
if [[ -d "${DIST_DIR}" ]]; then
  log "rm -rf dist/"
  rm -rf "${DIST_DIR}"
fi

# Common ephemeral zips at repo root from older packaging
rm -f "${ROOT}/AI-Tray-macOS-arm64.zip" "${ROOT}/AI-Tray-Windows-x64.zip" || true

log "clean complete"
