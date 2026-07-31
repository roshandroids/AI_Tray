#!/usr/bin/env bash
# Release orchestrator (local DX). Multi-platform ship remains Release CD on tag.
#
# Flags:
#   --check-only     run ./scripts/check.sh all and exit
#   --local-only     check → build (host) → package; no tags / no publish
#   --build          include host build (with --publish or alone with --package)
#   --package        include packaging
#   --publish ARGS…  after checks (and optional build/package), run canonical publish
#
# Safe default with no flags: print help (does not bump/tag).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/ci/_lib.sh
source "${ROOT}/scripts/ci/_lib.sh"

DO_CHECK=false
DO_BUILD=false
DO_PACKAGE=false
DO_PUBLISH=false
CHECK_ONLY=false
LOCAL_ONLY=false
PUBLISH_ARGS=()

usage() {
  cat <<'EOF'
AI Tray release orchestrator

Usage:
  ./scripts/release.sh --check-only
  ./scripts/release.sh --local-only          # check → build → package (dogfood)
  ./scripts/release.sh --publish patch       # check → canonical tag/push → Release CD
  ./scripts/release.sh --build --package --publish minor

Flags:
  --check-only     Quality gate only (format/analyze/bridge/test/workflows)
  --local-only     check + host build + package; does NOT tag or publish
  --build          Build for the current host OS
  --package        Package zip + checksums into dist/
  --publish …      Delegate to ./scripts/publish.sh (bump/tag/push → GHA Release CD)

Notes:
  - GitHub Actions Quality CI always re-verifies on PR/push (ignores CI_MODE).
  - Shipping both macOS + Windows artifacts is done by Release CD after tag push.
  - Preferred maintainer mode is recorded in .ci/config (CI_MODE) for docs/DX only.
  - Use ./scripts/check.sh full for handoff validation (Documentation workflow / pre-push).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --check-only)
      CHECK_ONLY=true
      DO_CHECK=true
      shift
      ;;
    --local-only)
      LOCAL_ONLY=true
      DO_CHECK=true
      DO_BUILD=true
      DO_PACKAGE=true
      shift
      ;;
    --build)
      DO_BUILD=true
      DO_CHECK=true
      shift
      ;;
    --package)
      DO_PACKAGE=true
      DO_CHECK=true
      shift
      ;;
    --publish)
      DO_PUBLISH=true
      DO_CHECK=true
      shift
      PUBLISH_ARGS=("$@")
      break
      ;;
    *)
      usage
      fail "Unknown argument: $1"
      ;;
  esac
done

if ! $DO_CHECK && ! $DO_BUILD && ! $DO_PACKAGE && ! $DO_PUBLISH; then
  usage
  exit 1
fi

HOST="$(host_os)"
BUILD_TARGET=""
case "${HOST}" in
  macos) BUILD_TARGET=macos ;;
  windows) BUILD_TARGET=windows ;;
esac

if $LOCAL_ONLY && $DO_PUBLISH; then
  fail "Refuse --local-only with --publish (local-only never tags or publishes)"
fi

if $DO_CHECK; then
  log "release: check"
  bash "${ROOT}/scripts/check.sh" all
fi

if $CHECK_ONLY; then
  log "release: --check-only complete"
  exit 0
fi

if $DO_BUILD; then
  [[ -n "${BUILD_TARGET}" ]] || fail "Host ${HOST} cannot build desktop targets (need macOS or Windows). Use Release CD for the other platform."
  log "release: build ${BUILD_TARGET}"
  bash "${ROOT}/scripts/build.sh" "${BUILD_TARGET}"
fi

if $DO_PACKAGE; then
  [[ -n "${BUILD_TARGET}" ]] || fail "Host ${HOST} cannot package desktop targets"
  log "release: package ${BUILD_TARGET}"
  bash "${ROOT}/scripts/package.sh" "${BUILD_TARGET}"
fi

if $LOCAL_ONLY; then
  log "release: --local-only complete (no tags; dogfood artifacts under dist/)"
  exit 0
fi

if $DO_PUBLISH; then
  [[ ${#PUBLISH_ARGS[@]} -gt 0 ]] || fail "--publish requires bump args (e.g. patch|minor|major|1.2.3)"
  log "release: publish via canonical scripts/publish.sh → Release CD (only path that creates tags)"
  bash "${ROOT}/scripts/publish.sh" "${PUBLISH_ARGS[@]}"
fi
