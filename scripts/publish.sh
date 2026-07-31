#!/usr/bin/env bash
# Thin wrapper — canonical implementation: scripts/release/publish.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "${ROOT}/scripts/release/publish.sh" "$@"
