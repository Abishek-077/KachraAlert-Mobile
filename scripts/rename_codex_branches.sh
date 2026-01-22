#!/usr/bin/env bash
set -euo pipefail

remote="${1:-origin}"
old_prefix="${2:-codex/}"
new_prefix="${3:-sprint-4/}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

if ! git remote get-url "$remote" >/dev/null 2>&1; then
  echo "Error: remote '$remote' does not exist." >&2
  exit 1
fi

git fetch "$remote" --prune

mapfile -t branches < <(git for-each-ref --format='%(refname:strip=3)' "refs/remotes/$remote/${old_prefix}*")

if [ ${#branches[@]} -eq 0 ]; then
  echo "No remote branches found with prefix '$old_prefix' on remote '$remote'."
  exit 0
fi

echo "Renaming ${#branches[@]} branch(es) from '$old_prefix' to '$new_prefix' on remote '$remote'."

for old_branch in "${branches[@]}"; do
  new_branch="${old_branch/#$old_prefix/$new_prefix}"

  if [ "$old_branch" = "$new_branch" ]; then
    echo "Skipping '$old_branch' (no prefix change)."
    continue
  fi

  echo "Creating '$new_branch' from '$old_branch'..."
  git fetch "$remote" "$old_branch:$new_branch"
  git push "$remote" "$new_branch"

  echo "Deleting old branch '$old_branch' from remote..."
  git push "$remote" --delete "$old_branch"

done

echo "Done."
