# Custom Patches for opencode fork

These patches are maintained on top of upstream `anomalyco/opencode` dev branch.
Use `script/sync-upstream.sh` to rebase when upstream updates.

## Versioning

Format: `{upstream}-oc-{fork}` (e.g., `1.4.6-oc-1.0.0`)

- **upstream**: `packages/opencode/package.json` version (auto-updated on sync)
- **fork**: `fork-version.json` version (manually bumped for fork-specific changes)

Bump fork version when adding new patches or features. Reset is not needed on upstream sync.

Version is automatically computed from these two files — **no manual `OPENCODE_VERSION` env var needed** for local builds.

## Patch 0: Fork Versioning Auto-Enforcement

**File:**
- `packages/script/src/index.ts`

**What:** When `fork-version.json` is present and `OPENCODE_VERSION` is not set, auto-compute version as `{upstream}-oc-{fork}` instead of falling back to the `0.0.0-dev-TIMESTAMP` preview format.

**Why:** Prevents accidental builds with wrong version. The enforcement is in the single code path that all build scripts share, so there's nothing to forget.

**Conflict Risk:** Low — isolated block inserted between two `if` branches. Upstream has no `fork-version.json` so behavior there is unchanged.

---

## Patch 1: TUI Rendering Optimization

**Files:**
- `packages/opencode/src/cli/cmd/tui/context/sync.tsx`
- `packages/opencode/src/cli/cmd/tui/routes/session/index.tsx`

**What:** Batch streaming delta updates (50ms flush), set `streaming={!props.message.time.completed}` to skip layout recalculation for completed messages, add timer cleanup.

**Why:** Every LLM streaming token triggered an immediate store update and re-render, causing UI jank. Completed messages kept recalculating layout unnecessarily.

**Architecture Note:** Ported to upstream's `useEvent` / `event.subscribe()` architecture (1.4.6+). Uses solid-js `batch()` already imported by upstream.

**Conflict Risk:** Medium — touches core streaming event handler in sync.tsx.

---

## Patch 2: DB Query Optimization

**Files:**
- `packages/opencode/src/session/session.ts` (was `session/index.ts` in ≤1.4.2)

**What:** Add 5s TTL project metadata cache in `listGlobal()`. Cache null for missing project IDs to avoid repeated lookups.

**Why:** Redundant DB queries on every paginated session list request.

**Note:** Cursor encoding optimization (id|time string format + legacy base64 fallback) was adopted by upstream in 1.4.6 — no longer needed as a fork patch.

**Conflict Risk:** Low — isolated cache block around the DB query in `listGlobal()`.

---

## Patch 3: Terminal Emergency Cleanup

**Files:**
- `packages/opencode/src/cli/cmd/tui/app.tsx`
- `packages/opencode/src/cli/cmd/tui/context/exit.tsx`

**What:** On abnormal exit (OOM, uncaught exception), write ANSI disable sequences via `writeSync` to reset mouse tracking, Kitty keyboard protocol, alternate screen, cursor, and raw mode. Add SIGTERM/SIGINT handlers to `exit.tsx`.

**Why:** When opencode crashes without calling `renderer.destroy()`, mouse tracking remains enabled and produces garbage characters in the shell on mouse movement.

**Conflict Risk:** Low — `emergencyCleanup` block inserted after `createCliRenderer()`, isolated from upstream logic.

---

## Patch 4: Sidebar Git Worktree Display

**Files:**
- `packages/opencode/src/cli/cmd/tui/feature-plugins/sidebar/git-info.tsx` (new)
- `packages/opencode/src/cli/cmd/tui/plugin/api.tsx`
- `packages/plugin/src/tui.ts`

**What:** Show `default_branch` and `is_worktree` flag in VCS info. New `git-info.tsx` sidebar component.

**Why:** Git worktree users need to see which branch is the default and whether they are in a worktree.

**Conflict Risk:** Low for new file; Medium for `api.tsx` and `tui.ts` type extensions.

---

## Dropped Patches (adopted by upstream)

| Patch | Upstream version | Notes |
|-------|-----------------|-------|
| IME 30ms timer fix | 1.4.6 | Upstream uses double-defer + direct `plainText` read in `submit()`. More robust than our 30ms approach. |
| Cursor encoding (id\|time format) | 1.4.6 | Upstream adopted identical `id\|time` string format with legacy base64 fallback. |

---

## Reapplying Patches

```bash
# Automated (recommended)
./script/sync-upstream.sh

# Manual fresh-start (when conflict count is too high for rebase)
git checkout -b sync/upstream-X.Y.Z upstream/dev
# Apply patches per this document
git checkout dev && git reset --hard sync/upstream-X.Y.Z
git push origin dev --force-with-lease
```
