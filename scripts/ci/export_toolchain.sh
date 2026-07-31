#!/usr/bin/env bash
# Export .ci/toolchain.env into GitHub Actions $GITHUB_ENV (or stdout if unset).
# Usage in workflows (after checkout):
#   - run: bash scripts/ci/export_toolchain.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="${ROOT}/.ci/toolchain.env"
[[ -f "${FILE}" ]] || { echo "Missing ${FILE}" >&2; exit 1; }

emit() {
  # Only KEY=VALUE assignment lines (skip comments / blanks)
  grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "${FILE}" | grep -v '^#'
}

if [[ -n "${GITHUB_ENV:-}" ]]; then
  emit >> "${GITHUB_ENV}"
  echo "Loaded toolchain pins from .ci/toolchain.env → GITHUB_ENV"
  emit | sed 's/^/  /'
else
  emit
fi
