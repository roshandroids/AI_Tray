#!/usr/bin/env bash
# Validate the official AI handoff package under docs/project/.
# Used by documentation.yml and Lefthook pre-push.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGE="$ROOT/docs/project"

REQUIRED_FILES=(
  "AI_HANDOFF.md"
  "PROJECT_STATE.md"
  "ARCHITECTURE_STATE.md"
  "PRODUCT_STATE.md"
  "ROADMAP.md"
  "NEXT_SESSION.md"
  "DECISION_LOG.md"
  "PROJECT_CONTEXT.json"
)

missing=0
for name in "${REQUIRED_FILES[@]}"; do
  path="$PACKAGE/$name"
  if [[ ! -f "$path" ]]; then
    echo "Missing handoff file: docs/project/$name" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path

path = Path("$PACKAGE") / "PROJECT_CONTEXT.json"
with path.open(encoding="utf-8") as handle:
    data = json.load(handle)

required_keys = ("schema_version", "updated_at", "version", "handoff")
missing_keys = [key for key in required_keys if key not in data]
if missing_keys:
    raise SystemExit(f"PROJECT_CONTEXT.json missing keys: {', '.join(missing_keys)}")

print(f"OK handoff package ({len(data)} top-level keys)")
print(f"OK PROJECT_CONTEXT.json schema_version={data.get('schema_version')}")
PY

echo "OK docs/project handoff consistency"
