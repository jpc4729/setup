import { atom, read, update } from 'claude-code'
import type {
  EngineInterface,
  Register,
  ToolCallInput,
  ToolCallResult,
} from 'claude-code'

import type {
  WorklogKind,
  WorklogListing,
  WorklogNode,
  WorklogSession,
  WorklogStatus,
} from '../types'

const PANE = 'worklog'
const RECORD = 'mcp__worklog__record'
const STORE_KEY = 'sessions-2'
const OLD_STORE_KEYS = ['sessions-1']
// Bounds for one session in memory and for the history on disk.
const KEEP_NODES = 200
const KEEP_SESSIONS = 5

// Change a tag when its value's fields change: it declines what an earlier
// version stored, which outlives a reload.
const session = atom({ plugin: 'worklog', key: 'session' } as const, null, {
  shape: 'session-1',
})
const past = atom({ plugin: 'worklog', key: 'past' } as const, null, {
  shape: 'session-1',
})
const listing = atom({ plugin: 'worklog', key: 'listing' } as const, null, {
  shape: 'listing-1',
})

const RECORDED: readonly WorklogKind[] = ['decision', 'rejected', 'finding', 'step']

const PREFIX: Record<WorklogKind, string> = {
  prompt: '',
  decision: 'Decision ',
  rejected: 'Rejected ',
  finding: 'Finding ',
  step: 'Step ',
  edit: 'Edit ',
  run: 'Bash ',
  agent: 'Agent ',
}

const COLOR: Record<WorklogStatus, string> = {
  running: 'warning',
  done: 'success',
  failed: 'error',
}

// The model reads the description and the schema on every request: keep both
// short. Edits, commands and subagents need no call: the hooks log them.
const DESCRIPTION =
  "Log a decision, rejected option, finding or key step to the user's work-log pane. Only what a reviewer must know, never routine work. Returns an id for parent."

const SCHEMA = {
  type: 'object',
  properties: {
    kind: { enum: RECORDED },
    title: { type: 'string' },
    detail: { type: 'string' },
    parent: { type: 'string' },
    file: { type: 'string' },
    line: { type: 'integer' },
  },
  required: ['kind', 'title'],
  additionalProperties: false,
}

type Dollar = EngineInterface
type NewNode = Omit<WorklogNode, 'id' | 'parent'> & { parent?: string | null }
type Row = { node: WorklogNode; lead: string; isRoot: boolean }
// On disk a node keeps no runtime ids, and `status` only when it failed.
type StoredNode = Omit<WorklogNode, 'status' | 'ref' | 'agent'> & {
  status?: 'failed'
}
type StoredSession = Omit<WorklogSession, 'seq' | 'nodes'> & { nodes: StoredNode[] }

const oneLine = (text: string, max: number) => {
  const line = text.trim().split('\n')[0]?.trim() ?? ''

  return line.length > max ? `${line.slice(0, max - 1)}…` : line
}

const basename = (path: string) => path.split('/').pop() || path

const lastRoot = (s: WorklogSession) => s.nodes.findLast(n => n.parent === null)

const isStored = (value: unknown): value is StoredSession =>
  typeof value === 'object' &&
  value !== null &&
  typeof (value as StoredSession).id === 'string' &&
  Array.isArray((value as StoredSession).nodes)

const compact = (s: WorklogSession): StoredSession => ({
  id: s.id,
  title: s.title,
  startedAt: s.startedAt,
  files: s.files,
  nodes: s.nodes.map(({ ref: _ref, agent: _agent, status, ...n }) =>
    status === 'failed' ? { ...n, status } : n,
  ),
})

const expand = (s: StoredSession): WorklogSession => ({
  ...s,
  seq: Math.max(0, ...s.nodes.map(n => Number(n.id.slice(1)) || 0)),
  nodes: s.nodes.map(n => ({ ...n, status: n.status ?? 'done' })),
})

// Drops the oldest prompts, each with all its nodes, until the session fits.
// A parent is always older than its children, so one pass finds them.
function trim(nodes: WorklogNode[]): WorklogNode[] {
  let kept = nodes
  while (kept.length > KEEP_NODES) {
    const root = kept.find(n => n.parent === null)
    if (root === undefined) {
      return kept.slice(-KEEP_NODES)
    }
    const gone = new Set([root.id])
    for (const n of kept) {
      if (n.parent !== null && gone.has(n.parent)) {
        gone.add(n.id)
      }
    }
    kept = kept.filter(n => !gone.has(n.id))
  }

  return kept
}

// Adds a node under `parent`, or under the current prompt when it is left
// out, and resolves its id; undefined while no session is live.
async function addNode($: Dollar, node: NewNode): Promise<string | undefined> {
  let id: string | undefined
  await update($, session, s => {
    if (s === null) {
      id = undefined

      return s
    }
    id = `n${s.seq + 1}`
    const parent =
      node.parent !== undefined ? node.parent : (lastRoot(s)?.id ?? null)

    return {
      ...s,
      seq: s.seq + 1,
      nodes: trim([...s.nodes, { ...node, id, parent }]),
    }
  })

  return id
}

// Changes the matching nodes; writes nothing when none match.
async function patchNodes(
  $: Dollar,
  isMatch: (n: WorklogNode) => boolean,
  change: Partial<WorklogNode>,
) {
  const live = await read($, session)
  if (live === null || !live.nodes.some(isMatch)) {
    return
  }
  await update($, session, s =>
    s === null
      ? s
      : {
          ...s,
          nodes: s.nodes.map(n => (isMatch(n) ? { ...n, ...change } : n)),
        },
  )
}

async function stored($: Dollar): Promise<StoredSession[]> {
  const value = await $.store.get(STORE_KEY)

  return Array.isArray(value) ? value.filter(isStored) : []
}

async function save($: Dollar, s: WorklogSession | null) {
  if (s === null || s.nodes.length === 0) {
    return
  }
  const rest = (await stored($)).filter(one => one.id !== s.id)
  await $.store.set(STORE_KEY, [...rest, compact(s)].slice(-KEEP_SESSIONS))
}

// Makes the live session the one the engine runs now. A new id (the first
// prompt, a resume) saves the old tree and loads the stored tree of the new id.
async function ensure($: Dollar) {
  const id = await $.session.id()
  const live = await read($, session)
  if (live?.id === id) {
    return
  }
  await save($, live)
  const found = (await stored($)).find(one => one.id === id)
  const startedAt = await $.clock.now()
  await update($, session, () =>
    found !== undefined
      ? expand(found)
      : { id, title: '', startedAt, seq: 0, nodes: [], files: [] },
  )
}

// Where an edit starts: the first changed line of its first hunk, and the
// lines it adds and removes.
function diffOf(result: unknown) {
  const record = result as { structuredPatch?: unknown } | null | undefined
  const hunks = Array.isArray(record?.structuredPatch)
    ? (record.structuredPatch as { newStart?: unknown; lines?: unknown }[])
    : []
  let line: number | undefined
  let added = 0
  let removed = 0
  for (const hunk of hunks) {
    let at = typeof hunk.newStart === 'number' ? hunk.newStart : undefined
    const lines = Array.isArray(hunk.lines) ? hunk.lines : []
    for (const text of lines) {
      const mark = typeof text === 'string' ? text[0] : undefined
      if (mark === '+' || mark === '-') {
        line ??= at
        mark === '+' ? (added += 1) : (removed += 1)
      } else if (at !== undefined) {
        at += 1
      }
    }
  }

  return { line, added, removed }
}

const pathOf = (e: ToolCallInput) =>
  e.tool === 'Edit' || e.tool === 'Write'
    ? e.file_path
    : e.tool === 'NotebookEdit'
      ? e.notebook_path
      : undefined

// The node a tool call of the main session starts; undefined for a call the
// log leaves out (reads, searches, the log's own tool).
async function startOf($: Dollar, e: ToolCallInput): Promise<NewNode | undefined> {
  const ref = e.tool_use_id
  if (e.tool === 'Bash') {
    const title = oneLine(e.description || e.command, 80)

    return { kind: 'run', title, status: 'running', ref }
  }
  if (e.tool === 'Agent') {
    const title = e.subagent_type ?? 'general-purpose'
    const detail = `(${oneLine(e.description, 60)})`

    return { kind: 'agent', title, detail, status: 'running', ref }
  }
  const path = pathOf(e)
  if (path === undefined) {
    return undefined
  }
  const cwd = await $.session.cwd()
  const title = path.startsWith(`${cwd}/`) ? path.slice(cwd.length + 1) : path

  return { kind: 'edit', title, status: 'running', ref }
}

async function finish(
  $: Dollar,
  id: string,
  e: ToolCallInput,
  ran: ToolCallResult,
  seconds: number,
) {
  const isThis = (n: WorklogNode) => n.id === id
  if (ran.deny !== undefined) {
    return patchNodes($, isThis, { status: 'failed', where: 'denied' })
  }
  const status: WorklogStatus = ran.isError === true ? 'failed' : 'done'
  if (e.tool === 'Bash') {
    if (ran.isReadOnly === true) {
      return update($, session, s =>
        s === null ? s : { ...s, nodes: s.nodes.filter(n => n.id !== id) },
      )
    }

    return patchNodes($, isThis, {
      status,
      ...(seconds > 0 && { where: `${seconds}s` }),
    })
  }
  if (e.tool === 'Agent') {
    // A background agent is still running here: its turn.complete ends it.
    return patchNodes(
      $,
      n => isThis(n) && (status === 'failed' || n.agent === undefined),
      { status },
    )
  }
  const path = pathOf(e)
  if (path === undefined) {
    return
  }
  const { line, added, removed } = diffOf(ran.result)
  const isNew = (ran.result as { type?: unknown } | undefined)?.type === 'create'
  const detail = isNew ? '(new)' : `(+${added} -${removed})`
  await update($, session, s =>
    s === null
      ? s
      : {
          ...s,
          files: s.files.includes(path) ? s.files : [...s.files, path],
          nodes: s.nodes.map(n =>
            isThis(n)
              ? {
                  ...n,
                  status,
                  ...(status === 'done' && { detail }),
                  ...(line !== undefined && { where: `:${line}` }),
                }
              : n,
          ),
        },
  )
}

// The tree in drawing order, each row with the connectors before its marker.
function layout(nodes: readonly WorklogNode[]): Row[] {
  const ids = new Set(nodes.map(n => n.id))
  const children = new Map<string, WorklogNode[]>()
  const roots: WorklogNode[] = []
  for (const n of nodes) {
    if (n.parent === null || !ids.has(n.parent)) {
      roots.push(n)
    } else {
      children.set(n.parent, [...(children.get(n.parent) ?? []), n])
    }
  }
  const rows: Row[] = []
  const walk = (node: WorklogNode, above: string, isLast: boolean, isRoot: boolean) => {
    rows.push({ node, lead: isRoot ? '' : `${above}${isLast ? '╰─' : '├─'}`, isRoot })
    const below = isRoot ? '' : `${above}${isLast ? '  ' : '│ '}`
    const list = children.get(node.id) ?? []
    list.forEach((child, i) => walk(child, below, i === list.length - 1, false))
  }
  for (const root of roots) {
    walk(root, '', true, true)
  }

  return rows
}

const dateOf = (ms: number) => new Date(ms).toISOString().slice(5, 16).replace('T', ' ')

export const register: Register = on => {
  // Off in a headless run (`claude -p`, the SDK): nothing draws there, so it
  // adds no tool and writes no history.
  let isLive = false
  // The person's own prompt, typed or a slash command line, for the next
  // turn's root. Turns that no person started go under the prompt before.
  let typed: string | undefined

  on('session.start', async ($, e, next) => {
    isLive = e.isInteractive
    if (isLive) {
      await $.tool.register({
        name: 'record',
        description: DESCRIPTION,
        inputSchema: SCHEMA,
        isDeferred: false,
      })
      await $.command.register({
        name: 'worklog',
        description: 'Show the work log: this session, history, or a stored session id',
        argumentHint: '[history | <session id>]',
      })
      for (const key of OLD_STORE_KEYS) {
        await $.store.delete(key)
      }
      void $.ui.open({ id: PANE, title: 'Work log' })
    }

    return next(e)
  })

  // Every answer shows in the pane or a toast, never as text the model reads.
  on('command.run', { command: 'worklog' }, async ($, e) => {
    typed = undefined
    const arg = e.args.trim().replace(/^#/, '')
    if (arg === 'history') {
      const rows: WorklogListing[] = (await stored($)).reverse().map(s => ({
        id: s.id,
        startedAt: s.startedAt,
        size: s.nodes.length,
        title: s.title,
      }))
      await update($, past, () => null)
      await update($, listing, () => rows)
    } else if (arg === '') {
      await update($, past, () => null)
      await update($, listing, () => null)
    } else {
      const found = (await stored($)).findLast(s => s.id.startsWith(arg))
      if (found === undefined) {
        $.ui.toast(`worklog: no stored session starts with ${arg}`)

        return {}
      }
      await update($, listing, () => null)
      await update($, past, () => expand(found))
    }
    await $.ui.open({ id: PANE, title: 'Work log' })

    return {}
  })

  on('prompt.submit', ($, e, next) => {
    const isPerson =
      (e.origin.kind === 'composer' || e.origin.kind === 'bridge') && e.isMeta !== true
    typed = !isPerson
      ? undefined
      : e.command !== undefined
        ? oneLine(`/${e.command.name} ${e.command.args}`, 80)
        : oneLine(e.text, 80)

    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    if (!isLive) {
      return next(e)
    }
    if (e.agentId !== undefined) {
      const agent = e.agentId
      await patchNodes($, n => n.agent === agent, { status: 'running' })

      return next(e)
    }
    await ensure($)
    const title = typed
    typed = undefined
    const live = await read($, session)
    const root = live === null ? undefined : lastRoot(live)
    if (title !== undefined || root === undefined) {
      const text = title ?? (oneLine(e.text, 80) || 'Session')
      await addNode($, {
        parent: null,
        kind: 'prompt',
        title: text,
        status: 'running',
        ref: e.turnId,
      })
      await update($, session, s =>
        s !== null && s.title === '' ? { ...s, title: text } : s,
      )
    } else {
      await patchNodes($, n => n.id === root.id, { status: 'running', ref: e.turnId })
    }

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    if (!isLive) {
      return next(e)
    }
    const status: WorklogStatus = e.reason === 'answer' ? 'done' : 'failed'
    if (e.agentId !== undefined) {
      const agent = e.agentId
      const where = `${Math.round(e.durationMs / 1000)}s`
      await patchNodes($, n => n.agent === agent, { status, where })
    } else {
      const turnId = e.turnId
      await patchNodes($, n => n.kind === 'prompt' && n.ref === turnId, { status })
      await save($, await read($, session))
    }

    return next(e)
  })

  on('session.end', async ($, e, next) => {
    typed = undefined
    if (isLive) {
      await save($, await read($, session))
      if (e.reason === 'clear') {
        await update($, session, () => null)
      }
    }

    return next(e)
  })

  on('agent.spawn', async ($, e, next) => {
    const spawned = await next(e)
    if (isLive && spawned.agentId !== undefined) {
      const agent = spawned.agentId
      const ref = e.tool_use_id
      await patchNodes($, n => n.kind === 'agent' && n.ref === ref, { agent })
    }

    return spawned
  })

  on('tool.call', { tool: RECORD }, async ($, e) => {
    const input = e as unknown as Record<string, unknown>
    const text = (key: string, max: number) => {
      const value = input[key]

      return typeof value === 'string' && value.trim() !== ''
        ? oneLine(value, max)
        : undefined
    }
    const kind = RECORDED.find(k => k === input.kind)
    const title = text('title', 80)
    if (kind === undefined || title === undefined) {
      return { deny: `Needs kind (${RECORDED.join('|')}) and title.` }
    }
    const detail = text('detail', 80)
    const file = text('file', 400)
    const parent = text('parent', 20)
    const line =
      typeof input.line === 'number' && Number.isInteger(input.line) && input.line > 0
        ? input.line
        : undefined
    await ensure($)
    const live = await read($, session)
    if (parent !== undefined && live?.nodes.some(n => n.id === parent) !== true) {
      return { deny: `No node ${parent}.` }
    }
    // A subagent's node nests under its own agent row.
    const agentRow =
      e.agentId === undefined
        ? undefined
        : live?.nodes.find(n => n.agent === e.agentId)?.id
    const nest = parent ?? agentRow
    const added = await addNode($, {
      kind,
      title,
      status: 'done',
      ...(nest !== undefined && { parent: nest }),
      ...(detail !== undefined && { detail }),
      ...(file !== undefined && {
        where: `${basename(file)}${line === undefined ? '' : `:${line}`}`,
      }),
    })

    return { result: added ?? 'not logged' }
  })

  on('tool.call', async ($, e, next) => {
    const node = isLive && e.agentId === undefined ? await startOf($, e) : undefined
    const id = node === undefined ? undefined : await addNode($, node)
    if (id === undefined) {
      return next(e)
    }
    const startedAt = await $.clock.now()
    let ran: ToolCallResult
    try {
      ran = await next(e)
    } catch (error) {
      await patchNodes($, n => n.id === id, { status: 'failed' })
      throw error
    }
    const seconds = Math.round(((await $.clock.now()) - startedAt) / 1000)
    await finish($, id, e, ran, seconds)

    return ran
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const list = await read($, listing)

    if (list !== null) {
      return (
        <Box flexDirection="column" width={e.props.bodyColumns}>
          <Box flexDirection="row" gap={1} marginBottom={1}>
            <Text color="merged">⎇</Text>
            <Text weight="bold">History</Text>
            <Text dimColor>/worklog &lt;id&gt; shows one</Text>
          </Box>
          {list.length === 0 && <Text dimColor>No stored sessions yet.</Text>}
          {list.map(s => (
            <Box flexDirection="row" gap={2}>
              <Text weight="bold">#{s.id.slice(0, 8)}</Text>
              <Text dimColor>{dateOf(s.startedAt)}</Text>
              <Text dimColor>{s.size}</Text>
              <Box flexGrow={1} flexShrink={1}>
                <Text wrap="truncate-end">{s.title}</Text>
              </Box>
            </Box>
          ))}
        </Box>
      )
    }

    const saved = await read($, past)
    const shown = saved ?? (await read($, session))

    if (shown === null || shown.nodes.length === 0) {
      return <Text dimColor>No work recorded yet.</Text>
    }

    const steps = shown.nodes.filter(n => n.parent !== null).length
    const rows = layout(shown.nodes)

    return (
      <Box flexDirection="column" width={e.props.bodyColumns}>
        <Box flexDirection="row" gap={1}>
          <Text color="merged">⎇</Text>
          <Text weight="bold">#{shown.id.slice(0, 6)}</Text>
          <Text weight="bold" wrap="truncate-end">
            {shown.title}
          </Text>
        </Box>
        <Box flexDirection="row" gap={2} marginBottom={1}>
          <Text>
            <Text color="success">■</Text> {steps} {steps === 1 ? 'step' : 'steps'}
          </Text>
          <Text dimColor>
            {shown.files.length} {shown.files.length === 1 ? 'file' : 'files'}
          </Text>
          {saved !== null && <Text dimColor>saved</Text>}
        </Box>
        {rows.map(({ node, lead, isRoot }, i) => {
          const isRejected = node.kind === 'rejected'
          const marker = isRoot ? '▢' : '■'
          const color =
            isRejected || (isRoot && node.status === 'done')
              ? 'subtle'
              : COLOR[node.status]

          return (
            <Box
              flexDirection="row"
              justifyContent="space-between"
              marginTop={isRoot && i > 0 ? 1 : 0}
            >
              <Box flexGrow={1} flexShrink={1}>
                <Text wrap="truncate-end">
                  <Text color="subtle">{lead}</Text>
                  <Text color={color}>{marker}</Text>{' '}
                  <Text dimColor>{PREFIX[node.kind]}</Text>
                  <Text weight={isRejected ? 'regular' : 'bold'} dimColor={isRejected}>
                    {node.title}
                  </Text>
                  {node.detail !== undefined && <Text dimColor> {node.detail}</Text>}
                </Text>
              </Box>
              {node.where !== undefined && (
                <Box flexShrink={0} marginLeft={2}>
                  <Text>{node.where}</Text>
                </Box>
              )}
            </Box>
          )
        })}
      </Box>
    )
  })
}
