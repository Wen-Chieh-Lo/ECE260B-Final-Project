#!/bin/bash
# =============================================================================
# Delete all files and directories matching .gitignore rules
# Usage: ./clean_gitignore.sh [--dry-run] [--force]
#   --dry-run  Show what would be deleted without actually deleting
#   --force    Skip confirmation prompt and delete immediately
# =============================================================================

set -e
cd "$(git rev-parse --show-toplevel)"

DRY_RUN=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force)   FORCE=true ;;
    -n)        DRY_RUN=true ;;
  esac
done

# Collect items to delete
# Sort by path depth (deepest first) to avoid deleting parent before children
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
{
  # 1. Untracked files/dirs that are ignored
  git ls-files --others --ignored --exclude-standard 2>/dev/null
  # 2. Directories (git ls-files may only list files)
  find . -path ./.git -prune -o -type d -print 2>/dev/null | while read d; do
    [ "$d" = "." ] && continue
    git check-ignore -q "$d" 2>/dev/null && echo "$d"
  done
} | sort -u > "$tmpfile"

to_delete=()
while IFS= read -r path; do
  [ -n "$path" ] && [ -e "$path" ] && to_delete+=("$path")
done < "$tmpfile"

# Sort by path length descending (delete children before parents)
sorted=()
for path in "${to_delete[@]}"; do
  sorted+=("$(printf '%06d %s' "${#path}" "$path")")
done
IFS=$'\n' sorted=($(printf '%s\n' "${sorted[@]}" | sort -r))
unset IFS

# Exit if nothing to delete
[ ${#to_delete[@]} -eq 0 ] && echo "No files matching .gitignore to delete" && exit 0

# Confirmation prompt (when not dry-run and not --force)
if ! $DRY_RUN && ! $FORCE; then
  echo "About to delete ${#to_delete[@]} items matching .gitignore"
  read -p "Continue? [y/N] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && echo "Cancelled" && exit 0
fi

deleted_count=0
for item in "${sorted[@]}"; do
  path="${item:7}"  # Strip length prefix
  [ ! -e "$path" ] && continue  # May have been removed by parent dir
  if $DRY_RUN; then
    echo "Would delete: $path"
  else
    rm -rf "$path"
    echo "Deleted: $path"
  fi
  ((deleted_count++)) || true
done

# Note: tracked files that match .gitignore
tracked_ignored=$(git ls-files -ci --exclude-standard 2>/dev/null || true)
if [ -n "$tracked_ignored" ]; then
  echo ""
  echo "The following files are tracked by Git but match .gitignore:"
  echo "$tracked_ignored" | head -20
  [ $(echo "$tracked_ignored" | wc -l) -gt 20 ] && echo "... ($(echo "$tracked_ignored" | wc -l) total)"
  echo ""
  echo "To delete them, run: git ls-files -ci --exclude-standard | xargs rm -f"
fi

if $DRY_RUN && [ $deleted_count -gt 0 ]; then
  echo ""
  echo "Dry run: $deleted_count items would be deleted. Remove --dry-run to execute."
fi
