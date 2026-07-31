#!/usr/bin/env bash
# Copilot SDK bridge: npm ci + npm run check (+ optional assemble).
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --assemble)
      TARGET="$2"
      shift 2
      ;;
    *)
      fail "Unknown argument: $1 (usage: bridge.sh [--assemble macos-arm64|windows-x64])"
      ;;
  esac
done

cd "${BRIDGE_DIR}"
require_cmd node
require_cmd npm

ACTUAL_NPM="$(npm --version)"
if [[ "${ACTUAL_NPM}" != "${NPM_VERSION}" ]]; then
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    fail "npm version ${ACTUAL_NPM} != pinned ${NPM_VERSION}"
  fi
  warn "npm ${ACTUAL_NPM} != pinned ${NPM_VERSION} (GHA enforces the pin)"
fi

log "npm ci"
npm ci
log "npm run check"
npm run check

if [[ -n "${TARGET}" ]]; then
  log "assemble sidecar --target ${TARGET}"
  node scripts/assemble_sidecar.mjs --target "${TARGET}"
  node scripts/verify_payload.mjs "../../build/copilot_sdk/${TARGET}"
  node scripts/smoke_protocol.mjs "../../build/copilot_sdk/${TARGET}"
fi
