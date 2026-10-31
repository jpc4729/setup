import { expect, mock, test } from 'claude-code/testing'

const PANE = {
  plugin: 'worklog',
  component: 'Pane',
  requestId: 'worklog',
  props: {
    title: 'Work log',
    isFocused: false,
    bodyColumns: 70,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

const COMMAND = {
  command: 'worklog',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: true, columns: 120 },
} as const

test('a typed prompt draws as a tree, and the store keeps it compact', async ($, on) => {
  // Nothing sits beneath the plugin: each hook here stands for the engine.
  const disk = new Map<string, unknown>()
  on('store.get', (_, e) => ({ value: disk.get(e.key) }))
  on('store.set', (_, e) => {
    disk.set(e.key, e.value)

    return { value: undefined }
  })
  on('store.delete', (_, e) => {
    disk.delete(e.key)

    return { value: undefined }
  })
  mock.clock(on, { now: Date.UTC(2026, 9, 30, 9, 0) })
  on('session.id', () => ({ value: 'a3f9c2e1-session' }))
  on('session.cwd', () => ({ value: '/repo' }))
  on('command.register', () => ({ value: { command: 'worklog' } }))
  on('tool.register', () => ({ value: { tool: 'mcp__worklog__record' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('prompt.submit', (_, e) => ({ text: e.text }))
  on('turn.start', (_, e) => ({ turnId: e.turnId }))
  on('turn.complete', () => ({ text: '' }))
  on('tool.call', (_, e) => {
    if (e.tool === 'Edit') {
      const patch = { newStart: 10, newLines: 3, oldStart: 10, oldLines: 3 }
      const lines = [' a', ' b', '-old', '+new']

      return { result: { structuredPatch: [{ ...patch, lines }] } }
    }
    if (e.tool === 'Bash' && e.command === 'ls') {
      return { result: {}, isReadOnly: true }
    }

    return e.tool === 'Bash' && e.command === 'pnpm test'
      ? { result: {}, isError: true }
      : { result: {} }
  })

  await $.session.start({ cwd: '/repo', surface: 'terminal', isInteractive: true })
  await $.prompt.submit({
    text: 'Add token refresh\nmore words',
    origin: { kind: 'composer' },
    wait: false,
  })
  await $.turn.start({ text: 'Add token refresh\nmore words', turnId: 't1' })
  const decision = await $.tool.call({
    tool: 'mcp__worklog__record',
    kind: 'decision',
    title: 'Refresh in the interceptor',
  })
  expect(decision).toMatchObject({ result: 'n2' })
  await $.tool.call({
    tool: 'mcp__worklog__record',
    kind: 'rejected',
    title: 'Refresh in each call',
    parent: 'n2',
  })
  await $.tool.call({
    tool: 'Edit',
    file_path: '/repo/src/client.ts',
    old_string: 'old',
    new_string: 'new',
  })
  await $.tool.call({ tool: 'Bash', command: 'ls' })
  await $.tool.call({ tool: 'Bash', command: 'pnpm test', description: 'Run the tests' })
  await $.turn.complete({
    answer: 'Done.',
    durationMs: 1000,
    isAborted: false,
    turnId: 't1',
    reason: 'answer',
  })
  // A background notice starts a turn no person typed: no new root.
  await $.turn.start({ text: '<task-notification>done</task-notification>', turnId: 't2' })
  await $.tool.call({ tool: 'Bash', command: 'git commit', description: 'Commit the change' })
  await $.turn.complete({
    answer: '',
    durationMs: 1000,
    isAborted: false,
    turnId: 't2',
    reason: 'answer',
  })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const rows = (await ui.findAll({ type: 'Text', text: /[▢■] / })).map(t => t.text)
  expect(rows).toEqual([
    '■ 5 steps',
    '▢ Add token refresh',
    '├─■ Decision Refresh in the interceptor',
    '│ ╰─■ Rejected Refresh in each call',
    '├─■ Edit src/client.ts (+1 -1)',
    '├─■ Bash Run the tests',
    '╰─■ Bash Commit the change',
  ])
  expect(await ui.find({ type: 'Text', text: ':12' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: '1 file' })).toBeDefined()
  await ui.unmount()

  // On disk: no runtime ids, and a status only where a node failed.
  const kept = disk.get('sessions-2') as { nodes: object[] }[]
  expect(kept[0]?.nodes[4]).toEqual({
    id: 'n6',
    parent: 'n1',
    kind: 'run',
    title: 'Run the tests',
    status: 'failed',
  })
  expect(kept[0]?.nodes[1]).toEqual({
    id: 'n2',
    parent: 'n1',
    kind: 'decision',
    title: 'Refresh in the interceptor',
  })

  // The history shows in the pane; the model reads no command text.
  const history = await $.command.run({ ...COMMAND, args: 'history' })
  expect(history.text).toBeUndefined()
  const list = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await list.find({ type: 'Text', text: '#a3f9c2e1' })).toBeDefined()
  expect(await list.find({ type: 'Text', text: 'Add token refresh' })).toBeDefined()
  await list.unmount()
})

test('a headless run adds no tool and records nothing', async ($, on) => {
  const disk = new Map<string, unknown>()
  on('store.get', (_, e) => ({ value: disk.get(e.key) }))
  on('store.set', (_, e) => {
    disk.set(e.key, e.value)

    return { value: undefined }
  })
  on('store.delete', (_, e) => {
    disk.delete(e.key)

    return { value: undefined }
  })
  let registered = 0
  on('tool.register', () => {
    registered += 1

    return { value: { tool: 'mcp__worklog__record' } }
  })
  on('session.id', () => ({ value: 's1' }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('turn.start', (_, e) => ({ turnId: e.turnId }))
  on('tool.call', () => ({ result: {} }))

  await $.session.start({ cwd: '/', surface: null, isInteractive: false })
  await $.turn.start({ text: 'hi', turnId: 't1' })
  await $.tool.call({ tool: 'Bash', command: 'touch a', description: 'Make a file' })

  expect(registered).toBe(0)
  expect(disk.get('sessions-2')).toBeUndefined()
})

test('a record call without kind and title is refused', async $ => {
  const refused = await $.tool.call({ tool: 'mcp__worklog__record', title: 'x' })
  expect(refused).toMatchObject({
    deny: 'Needs kind (decision|rejected|finding|step) and title.',
  })
})
