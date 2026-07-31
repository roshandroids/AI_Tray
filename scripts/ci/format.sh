#!/usr/bin/env bash
# Format check (dart format --set-exit-if-changed).
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

cd_app
require_cmd dart
log "dart format --set-exit-if-changed ."
dart format --set-exit-if-changed .
