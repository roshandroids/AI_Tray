#!/usr/bin/env bash
# Aggregate quality gate used by local DX and GitHub Actions.
#
# Default `all` matches Quality CI exactly:
#   format + analyze + bridge + test + workflows
# Use `full` to also run handoff validation (Documentation workflow / pre-push).
#
# Usage: check.sh [all|full|format|analyze|test|bridge|workflows|handoff]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/ci/_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

cmd="${1:-all}"
shift || true

run_quality() {
  bash "${SCRIPT_DIR}/format.sh"
  bash "${SCRIPT_DIR}/analyze.sh"
  bash "${SCRIPT_DIR}/bridge.sh"
  bash "${SCRIPT_DIR}/test.sh"
  bash "${SCRIPT_DIR}/validate_workflows.sh"
}

case "$cmd" in
  all)
    run_quality
    log "check all — OK (matches Quality CI; preferred CI_MODE=${CI_MODE}; GHA still re-verifies)"
    ;;
  full)
    run_quality
    bash "${SCRIPT_DIR}/validate_handoff.sh"
    log "check full — OK (Quality CI + handoff)"
    ;;
  format) bash "${SCRIPT_DIR}/format.sh" ;;
  analyze) bash "${SCRIPT_DIR}/analyze.sh" ;;
  test) bash "${SCRIPT_DIR}/test.sh" "$@" ;;
  bridge) bash "${SCRIPT_DIR}/bridge.sh" "$@" ;;
  workflows) bash "${SCRIPT_DIR}/validate_workflows.sh" ;;
  handoff) bash "${SCRIPT_DIR}/validate_handoff.sh" ;;
  *)
    cat <<'EOF' >&2
Usage: check.sh [all|full|format|analyze|test|bridge|workflows|handoff]

  all         Quality CI parity: format + analyze + bridge + test + workflows
  full        all + handoff validation
  format      dart format --set-exit-if-changed
  analyze     flutter analyze --fatal-infos
  test        flutter test (excludes golden,screenshot)
  bridge      npm ci + npm run check [--assemble TARGET]
  workflows   YAML parse + ubuntu-only guardrail
  handoff     validate docs/project handoff package
EOF
    exit 1
    ;;
esac
