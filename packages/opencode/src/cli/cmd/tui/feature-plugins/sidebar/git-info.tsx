import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui"
import { createMemo, Show } from "solid-js"

const id = "internal:sidebar-git-info"

function View(props: { api: TuiPluginApi }) {
  const theme = () => props.api.theme.current
  const vcs = createMemo(() => props.api.state.vcs)
  const isWorktree = createMemo(() => vcs()?.is_worktree ?? false)

  return (
    <Show when={vcs()?.branch}>
      <box>
        <text fg={theme().text}>
          <b>Branch</b>
        </text>
        <text fg={theme().textMuted}>
          <span style={{ fg: theme().text }}>{vcs()!.branch}</span>
          <Show when={vcs()?.default_branch && vcs()!.branch !== vcs()!.default_branch}>
            <span style={{ fg: theme().textMuted }}> {"\u2192"} {vcs()!.default_branch}</span>
          </Show>
        </text>
        <Show when={isWorktree()}>
          <text fg={theme().textMuted}>
            <span style={{ fg: theme().warning }}>worktree</span>
          </text>
        </Show>
      </box>
    </Show>
  )
}

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    order: 150,
    slots: {
      sidebar_content() {
        return <View api={api} />
      },
    },
  })
}

const plugin: TuiPluginModule & { id: string } = {
  id,
  tui,
}

export default plugin
