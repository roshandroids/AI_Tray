#!/usr/bin/env bash
# Validate workflow YAML + Quality companions stay ubuntu-only.
set -euo pipefail
# shellcheck source=scripts/ci/_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

cd_root
require_cmd ruby

log "Assert Quality CI companions use Ubuntu only"
for f in \
  .github/workflows/quality.yml \
  .github/workflows/documentation.yml \
  .github/workflows/maintenance.yml
do
  if [[ -f "$f" ]] && grep -E 'runs-on:[[:space:]]*(macos|windows)' "$f"; then
    fail "$f must not use macos/windows runners (Release CD owns desktop builds)"
  fi
  echo "OK ubuntu-only: $f"
done

log "Parse workflow YAML"
for f in .github/workflows/*.yml; do
  ruby -ryaml -e 'YAML.load_file(ARGV[0]); puts "OK #{ARGV[0]}"' "$f"
done
