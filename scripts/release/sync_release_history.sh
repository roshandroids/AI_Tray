#!/usr/bin/env bash
# Generate ai_tray/assets/release_history.json from CHANGELOG.md (SoT).
# Never hand-edit the JSON — re-run this script (or publish.sh) instead.
#
# Usage:
#   ./scripts/release/sync_release_history.sh
#   ./scripts/release/sync_release_history.sh /path/to/CHANGELOG.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHANGELOG="${1:-$ROOT/CHANGELOG.md}"
OUT="$ROOT/ai_tray/assets/release_history.json"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "error: missing CHANGELOG at $CHANGELOG" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

python3 - "$CHANGELOG" "$OUT" <<'PY'
import json
import re
import sys
from pathlib import Path

changelog_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
text = changelog_path.read_text(encoding="utf-8")

heading = re.compile(
    r"^## \[([^\]]+)\] — (\d{4}-\d{2}-\d{2})\n",
    re.MULTILINE,
)
matches = list(heading.finditer(text))
releases = []

for i, match in enumerate(matches):
    version = match.group(1)
    if version.lower() == "unreleased":
        continue
    start = match.end()
    end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
    # Stop at compare-link footer blocks that start with bare [version]:
    body = text[start:end]
    footer = re.search(r"\n\[[^\]]+\]:\s+https?://", body)
    if footer:
        body = body[: footer.start()]
    notes = body.strip()
    releases.append(
        {
            "version": version,
            "date": match.group(2),
            "notesMarkdown": notes,
        }
    )

payload = {
    "schemaVersion": 1,
    "generatedFrom": "CHANGELOG.md",
    "releases": releases,
}

out_path.write_text(
    json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
print(f"Wrote {len(releases)} release(s) → {out_path}")
PY
