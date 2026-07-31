#!/usr/bin/env bash
# Shared library for AI Tray scripts. Source from other scripts; do not execute.
# shellcheck shell=bash

if [[ "${AI_TRAY_LIB_LOADED:-}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi
AI_TRAY_LIB_LOADED=1

_AI_TRAY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${_AI_TRAY_LIB_DIR}/../.." && pwd)"
APP_DIR="${ROOT}/ai_tray"
BRIDGE_DIR="${APP_DIR}/tool/copilot_sdk_bridge"
DIST_DIR="${ROOT}/dist"
CI_CONFIG="${ROOT}/.ci/config"
TOOLCHAIN_ENV="${ROOT}/.ci/toolchain.env"

# Toolchain pins — single source: .ci/toolchain.env (env overrides allowed)
if [[ -f "${TOOLCHAIN_ENV}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${TOOLCHAIN_ENV}"
  set +a
fi
FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.9}"
NODE_VERSION="${NODE_VERSION:-22.17.0}"
NPM_VERSION="${NPM_VERSION:-10.9.2}"
APP_NAME="${APP_NAME:-AI Tray}"

# CI_MODE is for local DX / docs only. Never gate GitHub Actions on this value.
CI_MODE="${CI_MODE:-}"
if [[ -z "${CI_MODE}" && -f "${CI_CONFIG}" ]]; then
  # shellcheck disable=SC1090
  CI_MODE="$(grep -E '^[[:space:]]*CI_MODE=' "${CI_CONFIG}" | tail -1 | cut -d= -f2- | tr -d '[:space:]' || true)"
fi
CI_MODE="${CI_MODE:-local}"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

log() { printf '%s→%s %s\n' "${GREEN}" "${NC}" "$*"; }
warn() { printf '%s!%s %s\n' "${YELLOW}" "${NC}" "$*" >&2; }
fail() { printf '%serror:%s %s\n' "${RED}" "${NC}" "$*" >&2; exit 1; }

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd (run ./scripts/doctor.sh)"
}

host_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux) echo linux ;;
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    *) echo unknown ;;
  esac
}

ensure_dist() {
  mkdir -p "${DIST_DIR}"
}

cd_root() { cd "${ROOT}"; }
cd_app() { cd "${APP_DIR}"; }
