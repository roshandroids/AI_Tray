#!/usr/bin/env bash
# Unit + widget tests (excludes golden/screenshot tags).
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

cd_app
require_cmd flutter
if [[ ! -d .dart_tool ]]; then
  log "flutter pub get"
  flutter pub get
fi
log "flutter test --exclude-tags golden,screenshot"
flutter test --exclude-tags golden,screenshot
