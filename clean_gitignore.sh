#!/bin/bash
# =============================================================================
# Delete all files and directories matching .gitignore rules
# Usage: ./clean_gitignore.sh [--dry-run] [--force] [--delete-tracked]
#   --dry-run        Show what would be deleted without actually deleting
#   --force          Skip confirmation prompt and delete immediately
#   --delete-tracked Also remove tracked files that match .gitignore (git rm)
# =============================================================================

set -e
cd "$(git rev-parse --show-toplevel)"

DRY_RUN=false
FORCE=false
DELETE_TRACKED=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=true ;;
    --force)          FORCE=true ;;
    --delete-tracked) DELETE_TRACKED=true ;;
    -n)               DRY_RUN=true ;;
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

# Tracked files that match .gitignore (for dry-run display)
tracked_ignored=$(git ls-files -ci --exclude-standard 2>/dev/null || true)

# Exit if nothing to delete (unless dry-run with tracked, or delete-tracked with tracked)
if [ ${#to_delete[@]} -eq 0 ]; then
  if $DRY_RUN && [ -n "$tracked_ignored" ]; then
    :  # Continue to show tracked files in dry-run
  elif $DELETE_TRACKED && [ -n "$tracked_ignored" ]; then
    :  # Continue to delete tracked files
  else
    echo "No files matching .gitignore to delete"
    exit 0
  fi
fi

# Sort by path length descending (delete children before parents)
sorted=()
for path in "${to_delete[@]}"; do
  sorted+=("$(printf '%06d %s' "${#path}" "$path")")
done
IFS=$'\n' sorted=($(printf '%s\n' "${sorted[@]}" | sort -r))
unset IFS

# Confirmation prompt (when not dry-run and not --force)
if ! $DRY_RUN && ! $FORCE; then
  msg="About to delete ${#to_delete[@]} untracked items matching .gitignore"
  $DELETE_TRACKED && [ -n "$tracked_ignored" ] && tracked_n=$(echo "$tracked_ignored" | wc -l) && msg="$msg and $tracked_n tracked items (git rm)"
  echo "$msg"
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

# Delete tracked files that match .gitignore (when --delete-tracked and not dry-run)
if $DELETE_TRACKED && ! $DRY_RUN && [ -n "$tracked_ignored" ]; then
  echo ""
  echo "$tracked_ignored" | while read -r path; do
    if [ -n "$path" ] && [ -e "$path" ]; then
      git rm -rf "$path" 2>/dev/null && echo "Removed (tracked): $path" || true
    fi
  done
fi

# Dry-run: also show tracked files that match .gitignore
if $DRY_RUN && [ -n "$tracked_ignored" ]; then
  echo ""
  if $DELETE_TRACKED; then
    echo "The following tracked files would also be removed (--delete-tracked):"
    echo "$tracked_ignored" | while read -r path; do
      [ -n "$path" ] && [ -e "$path" ] && echo "Would remove (tracked): $path"
    done
  else
    echo "The following files are tracked by Git but match .gitignore (use --delete-tracked to remove):"
    echo "$tracked_ignored" | while read -r path; do
      [ -n "$path" ] && [ -e "$path" ] && echo "Would delete (tracked): $path"
    done
  fi
  tracked_count=$(echo "$tracked_ignored" | wc -l)
  echo ""
  if $DELETE_TRACKED; then
    echo "Dry run: $deleted_count untracked + $tracked_count tracked items would be deleted. Remove --dry-run to execute."
  else
    echo "Dry run: $deleted_count untracked items can be deleted, $tracked_count tracked items require --delete-tracked."
  fi
elif [ -n "$tracked_ignored" ] && ! $DELETE_TRACKED; then
  echo ""
  echo "The following files are tracked by Git but match .gitignore:"
  echo "$tracked_ignored" | head -20
  [ $(echo "$tracked_ignored" | wc -l) -gt 20 ] && echo "... ($(echo "$tracked_ignored" | wc -l) total)"
  echo ""
  echo "To delete these files, run with --delete-tracked or: git ls-files -ci --exclude-standard | xargs git rm --cached"
fi

if $DRY_RUN && [ $deleted_count -gt 0 ] && [ -z "$tracked_ignored" ]; then
  echo ""
  echo "Dry run: $deleted_count items would be deleted. Remove --dry-run to execute."
fi
