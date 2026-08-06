#!/usr/bin/env bash
# One-command release prep: bump version, finalize CHANGELOG, sync in-app
# release history, commit, tag, push. Triggers Release CD when the tag lands.
#
# Usage:
#   ./scripts/release/publish.sh patch|minor|major [--pre rc.N] [--dry-run]
#   ./scripts/release/publish.sh 1.0.0 [--dry-run]
#
# Requires: clean working tree (except CHANGELOG edits you intend to make first),
#           entries under ## [Unreleased] in CHANGELOG.md.
#
# Before running: audit `git log --oneline <last-tag>..HEAD` against
# [Unreleased] and fill any gaps — see docs/release/CI-CD.md#changelog-convention
# for the grouping/format convention (v1.4.0's CHANGELOG entry is the reference).
#
# Source of truth for notes: CHANGELOG.md. Derived asset (do not hand-edit):
#   ai_tray/assets/release_history.json
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PUBSPEC="$ROOT/ai_tray/pubspec.yaml"
CHANGELOG="$ROOT/CHANGELOG.md"
RELEASE_HISTORY="$ROOT/ai_tray/assets/release_history.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
  cat <<'EOF'
Publish AI Tray — bump, changelog, sync release history, commit, tag, push.

Usage:
  publish.sh patch|minor|major [--pre rc.N] [--dry-run]
  publish.sh 1.2.3 [--pre rc.N] [--dry-run]

Examples:
  publish.sh patch          # 1.0.0-rc.2 → 1.0.1 (stable bump)
  publish.sh 1.0.0          # pin GA version explicitly
  publish.sh patch --pre rc.3

Edit ## [Unreleased] in CHANGELOG.md only — never hand-edit
ai_tray/assets/release_history.json (regenerated here).

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

if ((${#PRE_ARGS[@]})); then
  NEW_VERSION=$("$SCRIPT_DIR/bump_version.sh" "$BUMP" "${PRE_ARGS[@]}")
else
  NEW_VERSION=$("$SCRIPT_DIR/bump_version.sh" "$BUMP")
fi
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

log "Syncing in-app release history from CHANGELOG…"
"$SCRIPT_DIR/sync_release_history.sh" "$CHANGELOG"

if $DRY_RUN; then
  log "Dry run — reverting pubspec, CHANGELOG, and release_history edits"
  git checkout -- "$PUBSPEC" "$CHANGELOG"
  if git ls-files --error-unmatch "$RELEASE_HISTORY" >/dev/null 2>&1; then
    git checkout -- "$RELEASE_HISTORY"
  else
    rm -f "$RELEASE_HISTORY"
  fi
  log "Would commit, tag $TAG, and push to origin"
  exit 0
fi

git add "$PUBSPEC" "$CHANGELOG" "$RELEASE_HISTORY"
git commit -m "$(cat <<EOF
chore(release): prepare $TAG

- Bump version to $NEW_VERSION
- Update CHANGELOG for $VERSION_NAME
- Sync ai_tray/assets/release_history.json
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
  2. Build AI-Tray-macOS-arm64.zip and AI-Tray-Windows-x64.zip
  3. Create the GitHub Release with CHANGELOG notes

Monitor: https://github.com/roshandroids/AI_Tray/actions/workflows/release.yml
Release: https://github.com/roshandroids/AI_Tray/releases/tag/$TAG
EOF
