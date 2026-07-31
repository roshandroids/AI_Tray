#!/usr/bin/env bash
# Static analysis (flutter analyze --fatal-infos).
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

cd_app
require_cmd flutter
if [[ ! -d .dart_tool ]]; then
  log "flutter pub get"
  flutter pub get
fi
log "flutter analyze --fatal-infos"
flutter analyze --fatal-infos
