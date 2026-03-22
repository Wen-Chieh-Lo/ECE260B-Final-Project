#!/usr/bin/env bash
# Restore route.enc + route.enc.dat from a Git commit, but NEVER overwrite files
# that already exist in the working tree (current version wins on conflict).
#
# Usage:
#   ./scripts/restore_route_enc_from_commit.sh [COMMIT]
# Default COMMIT: 469b737b08ec54acee4b91bd154e120698d5273f
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMMIT="${1:-469b737b08ec54acee4b91bd154e120698d5273f}"
git rev-parse --verify "${COMMIT}^{commit}" >/dev/null

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

git ls-tree -r --name-only "$COMMIT" | grep -E 'route\.enc$|route\.enc\.dat/' >"$TMP" || true

skipped=0
restored=0
failed=0

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ -e "$path" ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  if git restore --source="$COMMIT" --worktree --staged -- "$path"; then
    restored=$((restored + 1))
  else
    echo "FAILED: $path" >&2
    failed=$((failed + 1))
  fi
done <"$TMP"

echo "Commit: $COMMIT"
echo "Paths in commit: $(wc -l <"$TMP")"
echo "Skipped (already present, kept current): $skipped"
echo "Restored (was missing): $restored"
if [[ "$failed" -gt 0 ]]; then
  echo "Failed: $failed" >&2
  exit 1
fi
