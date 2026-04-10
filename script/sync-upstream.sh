#!/bin/bash
set -e

PATCHED_FILES=(
  "packages/opencode/src/cli/cmd/tui/context/sync.tsx"
  "packages/opencode/src/cli/cmd/tui/routes/session/index.tsx"
  "packages/opencode/src/cli/cmd/tui/component/prompt/index.tsx"
  "packages/opencode/src/session/index.ts"
  "packages/opencode/src/session/message-v2.ts"
  "packages/opencode/test/session/messages-pagination.test.ts"
)

echo "Fetching upstream..."
git fetch upstream

# Check if there are new upstream commits
BEHIND=$(git rev-list --count patches..upstream/dev)
if [ "$BEHIND" = "0" ]; then
  echo "Already up to date with upstream."
  exit 0
fi
echo "Upstream has $BEHIND new commit(s)."

# Pre-check: warn about patched files changed upstream
LAST_SYNCED=$(git merge-base patches upstream/dev)
CHANGED=$(git diff --name-only "$LAST_SYNCED" upstream/dev)
echo ""
echo "=== Conflict risk check ==="
RISK=0
for f in "${PATCHED_FILES[@]}"; do
  if echo "$CHANGED" | grep -q "$f"; then
    echo "  WARNING: $f changed upstream"
    RISK=1
  fi
done
if [ "$RISK" = "0" ]; then
  echo "  No patched files changed upstream. Low conflict risk."
fi
echo ""

# Attempt rebase
git checkout patches
if git rebase upstream/dev; then
  echo ""
  echo "Rebase successful!"
  git checkout dev
  git reset --hard patches

  # Regenerate patch files
  git format-patch -3 -o patches/custom/

  echo ""
  echo "=== Sync complete ==="
  echo "Verify with: git log --oneline upstream/dev..patches"
  echo "Push with:   git push origin patches dev --force-with-lease"
else
  echo ""
  echo "=== Rebase failed ==="
  echo "Resolve conflicts manually, then:"
  echo "  git rebase --continue"
  echo "  git checkout dev && git reset --hard patches"
  echo "  git format-patch -3 -o patches/custom/"
  echo "  git push origin patches dev --force-with-lease"
  echo ""
  echo "To abort: git rebase --abort"
fi
