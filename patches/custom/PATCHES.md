# Custom Patches for opencode fork

These patches are maintained on top of upstream `anomalyco/opencode` dev branch.
Use `script/sync-upstream.sh` to rebase when upstream updates.

## Versioning

Format: `{upstream}-oc-{fork}` (e.g., `1.4.2-oc-1.0.0`)

- **upstream**: `packages/opencode/package.json` version (auto-updated on sync)
- **fork**: `fork-version.json` version (manually bumped for fork-specific changes)

Bump fork version when adding new patches or features. Reset is not needed on upstream sync.

## Patch 1: TUI Rendering Optimization

**Files:**
- `packages/opencode/src/cli/cmd/tui/context/sync.tsx`
- `packages/opencode/src/cli/cmd/tui/routes/session/index.tsx`

**What:** Batch streaming delta updates (50ms flush), memoize parts array, set streaming=false on completed messages, add timer cleanup.

**Why:** Every LLM streaming token triggered an immediate store update and re-render, causing UI jank. Completed messages kept recalculating layout unnecessarily.

**Conflict Risk:** Medium - these are core TUI event handling and rendering files.

---

## Patch 2: DB Query Optimization

**Files:**
- `packages/opencode/src/session/index.ts`
- `packages/opencode/src/session/message-v2.ts`
- `packages/opencode/test/session/messages-pagination.test.ts`

**What:** Add 5s TTL project metadata cache in listGlobal(), replace JSON+Base64 cursor encoding with simple string format, add legacy cursor fallback, cache null for missing project IDs.

**Why:** Redundant DB queries and unnecessary JSON serialization on every paginated request.

**Conflict Risk:** Low-Medium - query patterns are relatively stable.

---

## Patch 3: IME Composition Fix (Korean/CJK)

**Files:**
- `packages/opencode/src/cli/cmd/tui/component/prompt/index.tsx`

**What:** Defer submit by 30ms to allow IME to finalize composition before reading input value.

**Why:** When typing Korean text, pressing Enter fires submit before the OS commits the composing character, causing the last character to be dropped.

**Conflict Risk:** Low - isolated 14-line insertion near the submit() function.

---

## Reapplying Patches

```bash
# Automated (recommended)
./script/sync-upstream.sh

# Manual
git fetch upstream
git checkout patches
git rebase upstream/dev
# resolve conflicts if any
git checkout dev && git reset --hard patches
git format-patch -3 -o patches/custom/
git push origin patches dev --force-with-lease
```

## Regenerating Patch Files

```bash
git format-patch -3 -o patches/custom/
```
