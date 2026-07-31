#!/usr/bin/env bash
# Thin user-facing wrapper → scripts/ci/test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "${ROOT}/scripts/ci/test.sh" "$@"
