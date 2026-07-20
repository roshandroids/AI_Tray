#!/usr/bin/env bash
# Lightweight Conventional Commits check for Lefthook commit-msg.
# Accepts: type(scope)?: subject  — types aligned with common Flutter repos.
set -euo pipefail

MSG_FILE="${1:-}"
if [[ -z "$MSG_FILE" || ! -f "$MSG_FILE" ]]; then
  echo "Usage: check_conventional_commit.sh <commit-msg-file>" >&2
  exit 2
fi

# First non-comment line is the subject.
subject="$(grep -v '^#' "$MSG_FILE" | sed '/^[[:space:]]*$/d' | head -n 1 || true)"

if [[ -z "$subject" ]]; then
  echo "Commit message is empty." >&2
  exit 1
fi

# Allow merge / revert commits produced by git itself.
if [[ "$subject" =~ ^Merge\  ]] || [[ "$subject" =~ ^Revert\  ]]; then
  exit 0
fi

pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?(!)?: .+'

if [[ ! "$subject" =~ $pattern ]]; then
  cat >&2 <<EOF
Commit message does not follow Conventional Commits:

  $subject

Expected: type(scope)?: description
Types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
Example: ci: remove desktop builds from PR quality workflow
EOF
  exit 1
fi
