#!/usr/bin/env bash
# Bump ai_tray/pubspec.yaml version (single source of truth).
# Usage: bump_version.sh patch|minor|major|VERSION [--pre rc.N]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PUBSPEC="$ROOT/ai_tray/pubspec.yaml"

usage() {
  cat <<'EOF'
Usage:
  bump_version.sh patch|minor|major
  bump_version.sh 1.2.3 [--pre rc.1]

Updates ai_tray/pubspec.yaml only. Pair with publish.sh for full release.
EOF
  exit 1
}

[[ $# -lt 1 ]] && usage

BUMP="$1"
shift
PRERELEASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pre)
      PRERELEASE="${2:?--pre requires a value}"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

CURRENT=$(grep -E '^version:' "$PUBSPEC" | awk '{print $2}')
NAME="${CURRENT%%+*}"
BUILD="${CURRENT##*+}"
[[ "$BUILD" == "$CURRENT" ]] && BUILD=0

CORE="${NAME%%-*}"
IFS='.' read -r MAJOR MINOR PATCH <<<"$CORE"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

if [[ "$BUMP" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  IFS='.' read -r MAJOR MINOR PATCH <<<"$BUMP"
elif [[ "$BUMP" == "patch" ]]; then
  PATCH=$((PATCH + 1))
elif [[ "$BUMP" == "minor" ]]; then
  MINOR=$((MINOR + 1))
  PATCH=0
elif [[ "$BUMP" == "major" ]]; then
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
else
  usage
fi

NEW_CORE="${MAJOR}.${MINOR}.${PATCH}"
if [[ -n "$PRERELEASE" ]]; then
  NEW_NAME="${NEW_CORE}-${PRERELEASE}"
else
  NEW_NAME="$NEW_CORE"
fi

BUILD=$((BUILD + 1))
NEW_VERSION="${NEW_NAME}+${BUILD}"

if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
else
  sed -i "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
fi

echo "$NEW_VERSION"
