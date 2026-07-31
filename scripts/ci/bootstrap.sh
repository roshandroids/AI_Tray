#!/usr/bin/env bash
# Fetch Flutter + Copilot bridge dependencies.
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

cd_root
bash "$(cd "$(dirname "$0")" && pwd)/doctor.sh" || warn "doctor reported issues — continuing bootstrap"

cd_app
require_cmd flutter
log "flutter pub get"
flutter pub get

cd "${BRIDGE_DIR}"
require_cmd npm
log "npm ci (bridge)"
npm ci

log "bootstrap complete"
