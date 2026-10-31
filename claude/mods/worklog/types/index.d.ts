export type WorklogKind =
  | 'prompt'
  | 'decision'
  | 'rejected'
  | 'finding'
  | 'step'
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
  // runtime only, never stored: a prompt's turn id or a call's tool_use_id
  ref?: string
  // runtime only, never stored: the subagent id of an agent node
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

// One stored session as `/worklog history` lists it.
export type WorklogListing = {
  id: string
  startedAt: number
  size: number
  title: string
}

declare module 'claude-code' {
  interface PluginState {
    worklog: {
      session: Shaped<WorklogSession | null>
      // a stored session the pane shows in place of the live one
      past: Shaped<WorklogSession | null>
      // the history list the pane shows in place of a tree
      listing: Shaped<WorklogListing[] | null>
    }
  }
}
