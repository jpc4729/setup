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

test('the pane draws one prompt as a tree and the history keeps it', async ($, on) => {
  // Nothing sits beneath the plugin: each hook here stands for the engine.
  mock.store(on)
  mock.clock(on, { now: Date.UTC(2026, 9, 30, 9, 0) })
  on('session.id', () => ({ value: 'a3f9c2e1-session' }))
  on('session.cwd', () => ({ value: '/repo' }))
  on('command.register', () => ({ value: { command: 'worklog' } }))
  on('tool.register', () => ({ value: { tool: 'mcp__worklog__record' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
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

    return { result: {}, isError: true }
  })

  await $.session.start({ cwd: '/repo', surface: 'terminal', isInteractive: true })
  await $.turn.start({ text: 'Add token refresh\nmore words', turnId: 't1' })
  const decision = await $.tool.call({
    tool: 'mcp__worklog__record',
    kind: 'decision',
    title: 'Refresh in the interceptor',
  })
  expect(decision).toMatchObject({ result: 'Recorded n2.' })
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

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const rows = (await ui.findAll({ type: 'Text', text: /[▢■] / })).map(t => t.text)
  expect(rows).toEqual([
    '■ 4 steps',
    '▢ Add token refresh',
    '├─■ Decision Refresh in the interceptor',
    '│ ╰─■ Rejected Refresh in each call',
    '├─■ Edit src/client.ts (+1 -1)',
    '╰─■ Bash Run the tests',
  ])
  expect(await ui.find({ type: 'Text', text: ':12' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: '1 file' })).toBeDefined()
  await ui.unmount()

  const history = await $.command.run({
    command: 'worklog',
    args: 'history',
    origin: { kind: 'composer' },
    presentation: { isFullscreen: true, columns: 120 },
  })
  expect(history.text).toBe('#a3f9c2e1  2026-10-30 09:00  5 nodes  Add token refresh')
})

test('a record call without kind and title is refused', async ($, on) => {
  mock.store(on)
  on('session.id', () => ({ value: 's1' }))

  const refused = await $.tool.call({ tool: 'mcp__worklog__record', title: 'x' })
  expect(refused).toMatchObject({ deny: 'kind and title are required to add a node.' })
})
