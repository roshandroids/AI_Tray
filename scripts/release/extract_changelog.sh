#!/usr/bin/env bash
# Extract the CHANGELOG.md section for a release version (stdout).
# Usage: extract_changelog.sh 1.0.0
set -euo pipefail

VERSION="${1:?Usage: extract_changelog.sh VERSION}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHANGELOG="$ROOT/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
  exit 1
fi

python3 - "$VERSION" "$CHANGELOG" <<'PY'
import re
import sys

version = sys.argv[1]
path = sys.argv[2]
text = open(path, encoding="utf-8").read()

# Match ## [1.0.0] or ## [1.0.0] — 2026-07-12
pattern = rf"^## \[{re.escape(version)}\](?: — [^\n]+)?\n"
match = re.search(pattern, text, re.MULTILINE)
if not match:
    sys.exit(1)

start = match.end()
next_heading = re.search(r"^## \[", text[start:], re.MULTILINE)
end = start + next_heading.start() if next_heading else len(text)
section = text[start:end].strip()
if section:
    print(section)
PY
