# Fork Customizations

This fork (`lcy2080/opencode`) tracks upstream `anomalyco/opencode` using a
**two-branch layout** so upstream sync is conflict-free by construction.

## Branches

| Branch | Role | Updates via |
|--------|------|-------------|
| `dev` | Mirror of `upstream/dev`. **Zero fork commits.** | Fast-forward only. `sync-upstream-v2.yml` advances it to `upstream/dev` on every run. |
| `release` | `dev` + fork customizations. **Build target.** | `sync-upstream-v2.yml` rebases it onto `dev` whenever `dev` advances. |

The authoritative list of fork commits is `git log dev..release --oneline`.

## Versioning

Format: `{upstream}-oc-{fork}` (e.g., `1.4.6-oc-1.0.1`).

- **upstream**: `packages/opencode/package.json` version (updated with every `dev` fast-forward).
- **fork**: `fork-version.json` version (manually bumped when adding or changing fork features).

`packages/script/src/index.ts` auto-derives the combined version at build time
when `fork-version.json` exists — no `OPENCODE_VERSION` env var needed.

## Current fork customizations

### 1. `feat: fork-version.json + auto-versioning`
- `fork-version.json`, `packages/script/src/index.ts`
- Auto-enforces `{upstream}-oc-{fork}` during build when the file is present.
- **Conflict risk:** Low (isolated block in script index).

### 2. `feat(tui): batch streaming part.delta events (50ms flush)`
- `packages/opencode/src/cli/cmd/tui/context/sync.tsx`
- Accumulates streaming deltas in a Map and flushes inside `batch()` every 50ms.
- Eliminates per-token re-render jank during long LLM responses.
- **Conflict risk:** Medium — touches the core streaming event handler.

### 3. `perf(session): cache project metadata with 5s TTL in listGlobal`
- `packages/opencode/src/session/session.ts`
- Module-level `Map<ProjectID, ProjectInfo>` with a 5s TTL and null sentinel for missing IDs.
- Replaces upstream's per-call fresh Map that re-queries `ProjectTable` on every page.
- **Conflict risk:** Low — isolated around `listGlobal`.

### 4. `feat(tui): emergency ANSI cleanup on abnormal exit`
- `packages/opencode/src/cli/cmd/tui/app.tsx`, `context/exit.tsx`
- Registers `process.on("exit")` with ANSI reset sequences for mouse tracking,
  Kitty keyboard protocol, alternate screen, cursor, bracketed paste, raw mode.
- Adds SIGTERM/SIGINT handlers routing through the existing `exit()` path.
- Prevents terminal garbage after OOM/crash.
- **Conflict risk:** Low — additive, positioned right after `createCliRenderer()`.

### 5. `feat(dist): Windows/Unix wrapper scripts`
- `packages/opencode/script/wrapper/opencode-wrapper.cmd`, `opencode-wrapper.sh`
- Safety net for SIGKILL where in-process cleanup cannot run. Wrappers invoke
  the core binary and issue ANSI resets via PowerShell / `printf + stty sane`
  if the process exits non-zero.
- **Conflict risk:** None (fork-only files).

### 6. `feat(tui): sidebar git-info plugin`
- New `packages/opencode/src/cli/cmd/tui/feature-plugins/sidebar/git-info.tsx`
- Registered in `packages/opencode/src/cli/cmd/tui/plugin/internal.ts`.
- `packages/opencode/src/cli/cmd/tui/plugin/api.tsx` exposes `default_branch`
  and `is_worktree` on `state.vcs`.
- `packages/plugin/src/tui.ts` extends `VcsInfo` public type.
- `default_branch` comes from upstream's `vcs.Info` schema (already populated).
- `is_worktree` is derived from `sync.path` so it is SDK-schema-free and
  null-safe.
- **Conflict risk:** Low for the new file; Medium if upstream reshapes
  `plugin/internal.ts` or `plugin/api.tsx`.

### 7. `chore(.opencode): enable opencode provider options block`
- `.opencode/opencode.jsonc`
- Changes `"provider": {}` to `"provider": { "opencode": { "options": {} } }`
  so per-repo provider overrides can be added without touching the user's
  global config.
- **Conflict risk:** Low.

### 8. `ci: fork sync infrastructure`
- `.github/workflows/build-custom.yml` — Windows x64 binary on `release` pushes.
- `.github/workflows/sync-upstream-v2.yml` — scheduled dev/release sync.
- `.husky/post-merge` — post-pull notice when upstream has new commits.
- `patches/custom/PATCHES.md` — this document.
- **Conflict risk:** None (fork-only files).

## Dropped patches (upstream adopted or improved)

| Original fork patch | Upstream status |
|---------------------|----------------|
| IME 30ms submit defer | 1.4.6+ does double-defer + direct `plainText` read (more robust). |
| Cursor encoding (`id\|time` string) | 1.4.6+ uses the identical format with legacy base64 fallback. |
| `sync.data.path?` null-safety on `is_worktree` | Already handled upstream via `sync.path` getter. |

## Syncing with upstream

### Automatic (preferred)

Scheduled `sync-upstream-v2.yml` runs Mon/Thu 06:00 UTC. On each run:

1. Fast-forwards `dev` to `upstream/dev` (conflict-free by contract).
2. Rebases `release` onto the new `dev`.
   - **Success:** `release` is force-with-lease pushed; `build-custom` picks
     it up and produces the next Windows binary.
   - **Conflict:** a snapshot branch `sync/release-rebase-YYYYMMDD-<sha7>`
     is pushed at `upstream/dev` and a draft PR (base = `release`) is
     opened so the maintainer resolves locally.

Manual trigger:

```bash
gh workflow run sync-upstream-v2.yml                  # real run
gh workflow run sync-upstream-v2.yml -f dry_run=true  # report-only
```

### Manual resolution of a blocked rebase

```bash
git fetch origin
git checkout release
git rebase origin/dev
# resolve conflicts, git add, git rebase --continue
git push origin release --force-with-lease
# close the draft sync PR; the resolved release is already pushed
```

## Adding a new fork customization

1. Branch off `release`.
2. Land the change with a conventional commit message (`feat`, `perf`, `fix`).
3. Merge to `release` (no PR against `dev` — `dev` is upstream-only).
4. Bump `fork-version.json` if the change affects runtime behavior.
5. Add a section to this document describing intent and conflict risk.

## Safety tags

The branch restructure preserved two archive tags:

- `archive/dev-pre-sync-20260424` — the original 41-commit `dev` on upstream 1.4.2.
- `archive/pre-branch-restructure-20260424` — `release`'s starting state (dev+9 customizations on upstream 1.4.6).

Neither is referenced by the sync workflow; they exist solely to make the
2026-04-24 restructure revertable.
