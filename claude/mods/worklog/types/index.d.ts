export type WorklogKind =
  | 'prompt'
  | 'decision'
  | 'rejected'
  | 'step'
  | 'finding'
  | 'summary'
  | 'edit'
  | 'run'
  | 'agent'

export type WorklogStatus = 'running' | 'done' | 'failed'

export type WorklogNode = {
  id: string
  // null for a root (a prompt); a missing parent draws the node as a root too
  parent: string | null
  kind: WorklogKind
  title: string
  // dim text after the title
  detail?: string
  // the right-hand column: `file.ts:12`, a duration
  where?: string
  status: WorklogStatus
  // the turn id of a prompt, or the tool_use_id of a tool call
  ref?: string
  // the subagent id of an agent node, set at agent.spawn
  agent?: string
}

export type WorklogSession = {
  id: string
  title: string
  startedAt: number
  seq: number
  nodes: WorklogNode[]
  // absolute paths edited in the session
  files: string[]
}

declare module 'claude-code' {
  interface PluginState {
    worklog: {
      session: Shaped<WorklogSession | null>
      // a stored session the pane shows in place of the live one
      past: Shaped<WorklogSession | null>
    }
  }
}
