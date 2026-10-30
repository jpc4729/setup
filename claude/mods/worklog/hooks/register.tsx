import { atom, read, update } from 'claude-code'
import type {
  EngineInterface,
  Register,
  ToolCallInput,
  ToolCallResult,
} from 'claude-code'

import type {
  WorklogKind,
  WorklogNode,
  WorklogSession,
  WorklogStatus,
} from '../types'

const PANE = 'worklog'
const RECORD = 'mcp__worklog__record'
const STORE_KEY = 'sessions-1'
// The store holds 4 MiB for all keys: these bound one session and the history.
const KEEP_NODES = 400
const KEEP_SESSIONS = 10

// Change a tag when its value's fields change: it declines what an earlier
// version stored, which outlives a reload.
const session = atom({ plugin: 'worklog', key: 'session' } as const, null, {
  shape: 'session-1',
})
const past = atom({ plugin: 'worklog', key: 'past' } as const, null, {
  shape: 'session-1',
})

const RECORDED: readonly WorklogKind[] = [
  'decision',
  'rejected',
  'step',
  'finding',
  'summary',
]
const STATUSES: readonly WorklogStatus[] = ['running', 'done', 'failed']

const PREFIX: Record<WorklogKind, string> = {
  prompt: '',
  decision: 'Decision ',
  rejected: 'Rejected ',
  step: 'Step ',
  finding: 'Finding ',
  summary: 'Summary ',
  edit: 'Edit ',
  run: 'Bash ',
  agent: 'Agent ',
}

const COLOR: Record<WorklogStatus, string> = {
  running: 'warning',
  done: 'success',
  failed: 'error',
}

const RULES = `# Work log
The user watches a tree of this session's work in a pane beside the chat. Prompts, file edits, commands that change state and subagent runs are logged by themselves. Call ${RECORD} for what the hooks cannot see: each decision you make (kind "decision", the reason in \`detail\`), each option you rejected (kind "rejected", \`parent\` the decision's id), each finding of a check or review (kind "finding", with \`file\` and \`line\` when known), and one line at the end of a task (kind "summary"). For a long step, record it with status "running" and update it by \`id\` when it ends. Keep titles short. Do not record reads or routine steps.`

const SCHEMA = {
  type: 'object',
  properties: {
    kind: {
      type: 'string',
      enum: RECORDED,
      description: 'What the node is. Required when adding.',
    },
    title: {
      type: 'string',
      description: 'One short line. Required when adding.',
    },
    detail: {
      type: 'string',
      description: 'A short reason or note, shown dim after the title.',
    },
    parent: {
      type: 'string',
      description: 'The id of the node to nest under. Default: the current prompt.',
    },
    file: { type: 'string', description: 'A file the node is about.' },
    line: { type: 'integer', minimum: 1, description: 'A line in that file.' },
    status: { type: 'string', enum: STATUSES, description: 'Default "done".' },
    id: {
      type: 'string',
      description: 'The id of an existing node to update instead of adding one.',
    },
  },
  additionalProperties: false,
}

type Dollar = EngineInterface
type NewNode = Omit<WorklogNode, 'id' | 'parent'> & { parent?: string | null }
type Row = { node: WorklogNode; lead: string; isRoot: boolean }

const oneLine = (text: string, max: number) => {
  const line = text.trim().split('\n')[0]?.trim() ?? ''

  return line.length > max ? `${line.slice(0, max - 1)}…` : line
}

const basename = (path: string) => path.split('/').pop() || path

const lastRoot = (s: WorklogSession) => s.nodes.findLast(n => n.parent === null)

// A background task's notice reads as its <summary>, other markup as its text.
const promptTitle = (text: string) => {
  const summary = /<summary>([\s\S]*?)<\/summary>/.exec(text)?.[1]

  return oneLine(summary ?? text.replace(/<[^>]+>/g, ' '), 120)
}

const isSession = (value: unknown): value is WorklogSession =>
  typeof value === 'object' &&
  value !== null &&
  typeof (value as WorklogSession).id === 'string' &&
  Array.isArray((value as WorklogSession).nodes)

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

async function patchNodes(
  $: Dollar,
  isMatch: (n: WorklogNode) => boolean,
  change: Partial<WorklogNode>,
) {
  await update($, session, s =>
    s === null
      ? s
      : {
          ...s,
          nodes: s.nodes.map(n => (isMatch(n) ? { ...n, ...change } : n)),
        },
  )
}

async function stored($: Dollar): Promise<WorklogSession[]> {
  const value = await $.store.get(STORE_KEY)

  return Array.isArray(value) ? value.filter(isSession) : []
}

async function save($: Dollar, s: WorklogSession | null) {
  if (s === null || s.nodes.length === 0) {
    return
  }
  const rest = (await stored($)).filter(one => one.id !== s.id)
  await $.store.set(STORE_KEY, [...rest, s].slice(-KEEP_SESSIONS))
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
  await update(
    $,
    session,
    () => found ?? { id, title: '', startedAt, seq: 0, nodes: [], files: [] },
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

export const register: Register = on => {
  // The slash command a turn runs: its row reads as the typed line, not the
  // skill body the model gets. Every prompt sets or clears it.
  let commandLine: string | undefined

  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'record',
      description:
        'Adds a node to the work log tree the user sees beside the chat, or updates one by id. Use it for decisions, rejected options, findings, long steps and the summary of a task; edits, commands and subagents are logged by themselves. Returns the node id, to pass later as `parent` or `id`.',
      inputSchema: SCHEMA,
      isDeferred: false,
    })
    await $.command.register({
      name: 'worklog',
      description: 'Show the work log of this session or of a stored one',
      argumentHint: '[history | <session id>]',
    })
    if (e.isInteractive) {
      void $.ui.open({ id: PANE, title: 'Work log' })
    }

    return next(e)
  })

  on('command.run', { command: 'worklog' }, async ($, e) => {
    const arg = e.args.trim().replace(/^#/, '')
    if (arg === 'history') {
      const all = (await stored($)).reverse()
      const lines = all.map(
        s =>
          `#${s.id.slice(0, 8)}  ${new Date(s.startedAt).toISOString().slice(0, 16).replace('T', ' ')}  ${s.nodes.length} nodes  ${s.title}`,
      )

      return { text: lines.length > 0 ? lines.join('\n') : 'No stored sessions yet.' }
    }
    if (arg === '') {
      await update($, past, () => null)
      await $.ui.open({ id: PANE, title: 'Work log' })

      return { text: 'Work log opened.' }
    }
    const found = (await stored($)).findLast(s => s.id.startsWith(arg))
    if (found === undefined) {
      return { text: `No stored session id starts with "${arg}". Run /worklog history.` }
    }
    await update($, past, () => found)
    await $.ui.open({ id: PANE, title: 'Work log' })

    return {
      text: `Showing session #${found.id.slice(0, 8)}. Run /worklog to show this session again.`,
    }
  })

  on('prompt.compose', async ($, e, next) => {
    const composed = await next(e)
    if (!e.tools.includes(RECORD)) {
      return composed
    }

    return {
      ...composed,
      sections: [
        ...composed.sections,
        { id: 'worklog:rules', text: RULES, scope: 'session' },
      ],
    }
  })

  on('prompt.submit', ($, e, next) => {
    commandLine =
      e.command === undefined
        ? undefined
        : oneLine(`/${e.command.name} ${e.command.args}`, 120)

    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    if (e.agentId !== undefined) {
      const agent = e.agentId
      await patchNodes($, n => n.agent === agent, { status: 'running' })

      return next(e)
    }
    await ensure($)
    const text = e.text.trim()
    if (text === '') {
      // A continuation runs under the prompt before it.
      const live = await read($, session)
      const root = live === null ? undefined : lastRoot(live)
      if (root !== undefined) {
        await patchNodes($, n => n.id === root.id, { status: 'running', ref: e.turnId })
      }
    } else {
      const title = commandLine ?? promptTitle(text)
      commandLine = undefined
      await addNode($, {
        parent: null,
        kind: 'prompt',
        title,
        status: 'running',
        ref: e.turnId,
      })
      await update($, session, s => (s !== null && s.title === '' ? { ...s, title } : s))
    }

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
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
    await save($, await read($, session))
    if (e.reason === 'clear') {
      await update($, session, () => null)
    }

    return next(e)
  })

  on('agent.spawn', async ($, e, next) => {
    const spawned = await next(e)
    if (spawned.agentId !== undefined) {
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
    const status = STATUSES.find(s => s === input.status)
    const title = text('title', 120)
    const detail = text('detail', 160)
    const file = text('file', 400)
    const line =
      typeof input.line === 'number' && Number.isInteger(input.line) && input.line > 0
        ? input.line
        : undefined
    const id = text('id', 20)
    const parent = text('parent', 20)
    if (input.kind !== undefined && kind === undefined) {
      return { deny: `kind must be one of: ${RECORDED.join(', ')}.` }
    }
    if (input.status !== undefined && status === undefined) {
      return { deny: `status must be one of: ${STATUSES.join(', ')}.` }
    }
    if (id === undefined && (kind === undefined || title === undefined)) {
      return { deny: 'kind and title are required to add a node.' }
    }
    await ensure($)
    const live = await read($, session)
    const has = (nodeId: string) => live?.nodes.some(n => n.id === nodeId) === true
    const where =
      file === undefined
        ? undefined
        : `${basename(file)}${line === undefined ? '' : `:${line}`}`

    if (id !== undefined) {
      if (!has(id)) {
        return { deny: `No work log node has the id ${id}.` }
      }
      await patchNodes($, n => n.id === id, {
        ...(kind !== undefined && { kind }),
        ...(title !== undefined && { title }),
        ...(detail !== undefined && { detail }),
        ...(where !== undefined && { where }),
        ...(status !== undefined && { status }),
      })

      return { result: `Updated ${id}.` }
    }
    if (kind === undefined || title === undefined) {
      return { deny: 'kind and title are required to add a node.' }
    }
    if (parent !== undefined && !has(parent)) {
      return { deny: `No work log node has the id ${parent}.` }
    }
    // A subagent's node nests under its own agent row.
    const agentRow =
      e.agentId === undefined
        ? undefined
        : live?.nodes.find(n => n.agent === e.agentId)?.id
    const added = await addNode($, {
      kind,
      title,
      status: status ?? 'done',
      ...(parent !== undefined || agentRow !== undefined
        ? { parent: parent ?? agentRow }
        : {}),
      ...(detail !== undefined && { detail }),
      ...(where !== undefined && { where }),
    })

    return { result: `Recorded ${added}.` }
  })

  on('tool.call', async ($, e, next) => {
    const node = e.agentId === undefined ? await startOf($, e) : undefined
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
          <Text dimColor>{shown.files.length} {shown.files.length === 1 ? 'file' : 'files'}</Text>
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
