#!/usr/bin/env bash
# One-command release prep: bump version, finalize CHANGELOG, commit, tag, push.
# Triggers the Release workflow when the tag reaches GitHub.
#
# Usage:
#   ./scripts/release/publish.sh patch|minor|major [--pre rc.N] [--dry-run]
#   ./scripts/release/publish.sh 1.0.0 [--dry-run]
#
# Requires: clean working tree (except CHANGELOG edits you intend to make first),
#           entries under ## [Unreleased] in CHANGELOG.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PUBSPEC="$ROOT/ai_tray/pubspec.yaml"
CHANGELOG="$ROOT/CHANGELOG.md"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
  cat <<'EOF'
Publish AI Tray — bump, changelog, commit, tag, push.

Usage:
  publish.sh patch|minor|major [--pre rc.N] [--dry-run]
  publish.sh 1.2.3 [--pre rc.N] [--dry-run]

Examples:
  publish.sh patch          # 1.0.0-rc.2 → 1.0.1 (stable bump)
  publish.sh 1.0.0          # pin GA version explicitly
  publish.sh patch --pre rc.3

After push, GitHub Actions builds macOS + Windows and publishes the release.
EOF
  exit 1
}

log() { echo -e "${GREEN}→${NC} $*"; }
fail() { echo -e "${RED}error:${NC} $*" >&2; exit 1; }

DRY_RUN=false
BUMP=""
PRE_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    patch | minor | major)
      BUMP="$1"
      shift
      ;;
    --pre)
      PRE_ARGS=(--pre "$2")
      shift 2
      ;;
    [0-9]*.[0-9]*.[0-9]*)
      BUMP="$1"
      shift
      ;;
    *)
      usage
      ;;
  esac
done

[[ -z "$BUMP" ]] && usage

cd "$ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
  fail "Working tree must be clean before publishing. Commit or stash changes first."
fi

if [[ ! -f "$CHANGELOG" ]]; then
  fail "Missing CHANGELOG.md at repo root"
fi

if ! grep -q '^## \[Unreleased\]' "$CHANGELOG"; then
  fail "CHANGELOG.md must contain an ## [Unreleased] section"
fi

# Require unreleased content beyond the heading.
UNRELEASED_LINES=$(python3 - <<'PY' "$CHANGELOG"
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"^## \[Unreleased\]\n(.*)(?=^## \[|\Z)", text, re.MULTILINE | re.DOTALL)
body = (m.group(1) if m else "").strip()
print(1 if body else 0)
PY
)
if [[ "$UNRELEASED_LINES" == "0" ]]; then
  fail "Add release notes under ## [Unreleased] before publishing"
fi

NEW_VERSION=$("$SCRIPT_DIR/bump_version.sh" "$BUMP" "${PRE_ARGS[@]}")
VERSION_NAME="${NEW_VERSION%%+*}"
TAG="v${VERSION_NAME}"
TODAY=$(date +%Y-%m-%d)

log "New version: $NEW_VERSION (tag $TAG)"

# Move [Unreleased] content into a dated version section.
python3 - "$VERSION_NAME" "$TODAY" "$CHANGELOG" <<'PY'
import re
import sys

version, today, path = sys.argv[1:4]
text = open(path, encoding="utf-8").read()

pattern = r"(## \[Unreleased\]\n)(.*?)(\n## \[|\Z)"
match = re.search(pattern, text, re.DOTALL)
if not match:
    raise SystemExit("Could not parse [Unreleased] section")

header, body, tail = match.group(1), match.group(2).rstrip(), match.group(3)
if not body.strip():
    raise SystemExit("[Unreleased] is empty")

new_section = f"## [{version}] — {today}\n{body}\n\n"
replacement = header + "\n" + new_section + tail.lstrip("\n")
text = text[: match.start()] + replacement + text[match.end() :]
open(path, "w", encoding="utf-8").write(text)
PY

log "Updated CHANGELOG.md → [$VERSION_NAME]"

if $DRY_RUN; then
  log "Dry run — reverting pubspec and CHANGELOG edits"
  git checkout -- "$PUBSPEC" "$CHANGELOG"
  log "Would commit, tag $TAG, and push to origin"
  exit 0
fi

git add "$PUBSPEC" "$CHANGELOG"
git commit -m "$(cat <<EOF
chore(release): prepare $TAG

- Bump version to $NEW_VERSION
- Update CHANGELOG for $VERSION_NAME
EOF
)"

git tag -a "$TAG" -m "AI Tray $VERSION_NAME"

log "Pushing commit and tag $TAG to origin…"
git push origin HEAD
git push origin "$TAG"

cat <<EOF

${GREEN}Published $TAG locally and pushed to origin.${NC}

GitHub Actions will:
  1. Validate pubspec version
  2. Build AI-Tray-macOS-arm64.zip, AI-Tray-macOS-x64.zip, AI-Tray-Windows-x64.zip
  3. Create the GitHub Release with CHANGELOG notes

Monitor: https://github.com/roshandroids/AI_Tray/actions/workflows/release.yml
Release: https://github.com/roshandroids/AI_Tray/releases/tag/$TAG
EOF
