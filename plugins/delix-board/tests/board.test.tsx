import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

import { cut, minutes, parseCard, parseMetrics, parseState, runProgress } from '../hooks/parse'
import { FILES, IMPL, LAYOUT, LAYOUT_COMMITS, LAYOUT_TREES, MAIN, MAIN_TREE, ORCH, ROOT, RUN_ALL, TEMPLATE_STATE, TIE, WORKTREES } from './fixtures'

const SURFACES = ['terminal', 'desktop'] as const

const PANE = {
  plugin: 'delix-board',
  component: 'Pane',
  requestId: 'delix-board',
  props: { title: 'delix', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 200 }, view: {} },
} as const

const BAND = {
  plugin: 'delix-board',
  component: 'AbovePrompt',
  props: { hasSurvey: false, isWorking: false, maxRows: 6, bodyColumns: 80, scroll: { offset: 0, bodyRows: 6 }, view: {} },
} as const

/** Git as a worktree sees it: STATE's last commit time (s) and uncommitted STATE changes per worktree, file mtimes. */
type Repo = { top: string; common: string; trees: string; commits?: Record<string, number>; dirty?: string[]; mtimes?: Record<string, number> }

/** The engine beneath the plugin: a project on disk, git, commands, panes, toasts. `git` may change mid-test. */
function world(on: On, files: Record<string, string>, git: Repo = { top: ROOT, common: '.git', trees: WORKTREES }) {
  const toasts: string[] = []
  const now = mock.clock(on, { now: 1_000_000 })
  mock.store(on)
  const missing = (path: string) => new Error(`ENOENT: ${path}`)
  const out = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
  on('process.run', (_, e) => {
    if (e.argv.includes('rev-parse')) return out(`${git.top}\n${git.common}\n`)
    const cwd = e.init?.cwd ?? ''
    if (e.argv.includes('log')) return out(`${git.commits?.[cwd] ?? ''}\n`)
    if (e.argv.includes('status')) return out(git.dirty?.includes(cwd) ? ' M docs/delix/STATE.json\n' : '')
    return out(git.trees)
  })
  on('fs.exists', (_, e) => ({ value: e.path in files }))
  on('fs.stat', (_, e) => {
    const text = files[e.path]
    if (text === undefined) throw missing(e.path)
    return { value: { kind: 'file', size: text.length, mtimeMs: git.mtimes?.[e.path] ?? 1, isLink: false } }
  })
  on('fs.read', (_, e) => {
    const text = files[e.path]
    if (text === undefined) throw missing(e.path)
    return { value: text }
  })
  on('fs.list', (_, e) => {
    const prefix = e.path.replace(/\/$/, '') + '/'
    const names = Object.keys(files)
      .filter(p => p.startsWith(prefix) && !p.slice(prefix.length).includes('/'))
      .map(p => p.slice(prefix.length))
    if (names.length === 0) throw missing(e.path)
    return { value: names.map(name => ({ name, kind: 'file', size: 1, mtimeMs: 1, isLink: false })) }
  })
  on('command.register', () => ({ value: { command: 'delix-board' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.status', () => ({ value: undefined }))
  on('ui.toast', (_, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.attach', (_, e) => ({ clientId: e.clientId }))
  on('session.surfaces', () => ({ value: [] }))
  on('session.cwd', () => ({ value: ROOT }))
  return { toasts, now }
}

test('STATE waves in both shapes, cards, metrics and run output parse', async () => {
  expect(parseState(TEMPLATE_STATE)?.waves).toEqual([
    { wave: 1, cards: ['T001', 'T002'], note: '' },
    { wave: 2, cards: ['T003'], note: '' },
  ])
  const state = parseState(FILES[`${ROOT}/docs/delix/STATE.json`] ?? '')
  expect(state?.waves[1]?.cards).toEqual(['T002', 'T003'])
  expect(state?.cards.T003?.costUsd).toBe(0.97)
  const card = parseCard(FILES[`${ROOT}/docs/delix/tasks/T002-hardening.md`] ?? '')
  expect(card.table.tier).toBe(3)
  expect(parseState(FILES[`${ROOT}/docs/delix/arsiv/E1-STATE.json`] ?? '')?.cards.T000).toMatchObject({ status: 'accepted', tier: 3, rounds: 3 })
  expect(card.files.map(f => f.kind)).toEqual(['Modify', 'Test'])
  expect(card.reviewRounds).toHaveLength(2)
  expect(card.reviewRounds[0]?.findings.map(f => f.severity)).toEqual(['medium', 'low'])
  const metrics = parseMetrics(FILES[`${ROOT}/docs/delix/metrics.md`] ?? '')
  expect(metrics.T001).toEqual({ costUsd: 5.39, rounds: 2, durationMin: 18 })
  expect(metrics.T003?.durationMin).toBe(2.2)
  expect(minutes('2 dk 25 sn')).toBe(2.4)
  expect(cut('🔐 HUMAN_APPROVAL', 40)).toBe('◈ HUMAN_APPROVAL')
  expect(runProgress(RUN_ALL)).toMatchObject({ suites: 3, pass: 5, fail: 1 })
})

test('the board lists cards by wave with their pending gates, on every surface', async ($, on) => {
  world(on, FILES)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ type: 'Button', key: 'card-T002' })).toBeDefined()
    expect(await ui.find({ type: 'Button', key: 'card-T004' })).toBeDefined()
    expect((await ui.find({ type: 'Text', text: /5 kart/ }))?.text).toMatch(/tur 6/)
    expect(await ui.find({ type: 'Text', text: /Önceki spec · docs\/delix\/arsiv/ })).toBeDefined()
    expect(await ui.find({ type: 'Button', key: 'card-T000' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Tier 3 onayı/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /^ ?merge$/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Wave 2/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /b01-csp/ })).toBeDefined()
    if (surface === 'terminal') {
      expect(await ui.find({ type: 'Text', text: '●' })).toBeDefined()
      expect(await ui.find({ type: 'Raster' })).toBeDefined()
    } else {
      expect(await ui.find({ type: 'Svg' })).toBeDefined()
    }
    await ui.unmount()
  }
})

test('a card opens its detail: files, report, test result, review rounds', async ($, on) => {
  world(on, FILES)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'card-T002' })
    expect(await ui.find({ type: 'Text', text: /compose\.yaml/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /DONE_WITH_CONCERNS/ })).toBeDefined()
    expect((await ui.find({ type: 'Text', text: /GEÇTİ.*KALDI/ }))?.text).toMatch(/2 GEÇTİ \/ 0 KALDI/)
    expect(await ui.find({ type: 'Text', text: /^Round 1/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /capability is wider/ })).toBeDefined()
    await ui.press({ key: 'card-next' })
    expect(await ui.find({ type: 'Text', text: /Team page/ })).toBeDefined()
    await ui.press({ key: 'tab-pano' })
    await ui.unmount()
  }
})

test('metrics draw measured values and say which were not measured', async ($, on) => {
  world(on, FILES)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'tab-olcum' })
    expect(await ui.find({ type: 'Text', text: '$5.39' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: '18 dk' })).toBeDefined()
    expect((await ui.findAll({ type: 'Text', text: 'ölçülmedi' })).length).toBeGreaterThan(0)
    expect(await ui.find({ type: 'Text', text: /türetilmiş/ })).toBeDefined()
    await ui.press({ key: 'tab-pano' })
    await ui.unmount()
  }
})

test('a foreground run_all.sh is followed, counted and toasted', async ($, on) => {
  const { toasts } = world(on, FILES)
  on('tool.call', () => ({ result: { stdout: RUN_ALL, stderr: '', interrupted: false } }))
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  await $.tool.call({ tool: 'Bash', command: "ssh build-host 'cd ~/projects/x && bash tests/run_all.sh'" })
  expect(toasts.at(-1)).toMatch(/run_all\.sh başarısız: 5 GEÇTİ \/ 1 KALDI/)
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'tab-bekleme' })
    expect(await ui.find({ type: 'Text', text: 'Son koşular' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Bekleyen koşu yok/ })).toBeDefined()
    await ui.press({ key: 'tab-pano' })
    await ui.unmount()
  }
})

test('a background run tails its output file and ends on its task notification', async ($, on) => {
  const files = { ...FILES, '/tmp/b7.output': RUN_ALL }
  const { toasts, now } = world(on, files)
  on('tool.call', () => ({
    result: { stdout: '', stderr: '', interrupted: false, backgroundTaskId: 'b7' },
    text: 'Command running in background with ID: b7. Output is being written to: /tmp/b7.output',
  }))
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  await $.tool.call({ tool: 'Bash', command: 'bash tests/run_all.sh', run_in_background: true })
  await now.advance(2100)
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'tab-bekleme' })
    expect(await ui.find({ type: 'Text', text: 'run_all.sh' })).toBeDefined()
    expect((await ui.find({ type: 'Text', text: /takım/ }))?.text).toMatch(/takım 3 · kontrol 6/)
    expect(await ui.find({ type: 'Text', text: /teamguard_unit/ })).toBeDefined()
    await ui.unmount()
    const band = await $.ui.mount({ ...BAND, surface })
    expect(await band.find({ type: 'Button', key: 'band-open' })).toBeDefined()
    expect(await band.find({ type: 'Text', text: 'run_all.sh' })).toBeDefined()
    await band.unmount()
  }
  await $.session.append({
    door: 'delivery',
    origin: { kind: 'task-notification' },
    uuid: 'row-b7',
    message: { type: 'user', content: [{ type: 'text', text: '<task-notification><task-id>b7</task-id><status>completed</status></task-notification>' }] },
  })
  expect(toasts.at(-1)).toMatch(/run_all\.sh başarısız: 5 GEÇTİ \/ 1 KALDI/)
})

test('a folder without docs/delix shows the empty state', async ($, on) => {
  world(on, {})
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ type: 'Text', text: /delix projesi değil/ })).toBeDefined()
    await ui.unmount()
  }
})

test('a headless session starts nothing and follows no run', async ($, on) => {
  const { toasts } = world(on, FILES)
  on('tool.call', () => ({ result: { stdout: RUN_ALL, stderr: '', interrupted: false } }))
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  await $.session.start({ cwd: ROOT, surface: null, isInteractive: false })
  await $.tool.call({ tool: 'Bash', command: 'bash tests/run_all.sh' })
  expect(toasts).toEqual([])
  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect((await band.find({ type: 'Text' }))?.text).toBe('engine')
  await band.unmount()
})

test('the band names pending gates when nothing runs', async ($, on) => {
  world(on, FILES)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const band = await $.ui.mount({ ...BAND, surface })
    expect((await band.find({ type: 'Text', text: /kapı bekliyor/ }))?.text).toMatch(/2 kapı bekliyor/)
    await band.unmount()
  }
})

test('a desktop session (SDK, not interactive at start) starts when the desktop attaches', async ($, on) => {
  const { toasts } = world(on, FILES)
  on('tool.call', () => ({ result: { stdout: RUN_ALL, stderr: '', interrupted: false } }))
  await $.session.start({ cwd: ROOT, surface: null, isInteractive: false })
  await $.session.attach({ surface: 'desktop', clientId: 'desktop:default' })
  await $.tool.call({ tool: 'Bash', command: 'bash tests/run_all.sh' })
  expect(toasts).toHaveLength(1)
  const band = await $.ui.mount({ ...BAND, surface: 'desktop' })
  expect((await band.find({ type: 'Text', text: /kapı bekliyor/ }))?.text).toMatch(/2 kapı bekliyor/)
  await band.unmount()
})

test('a session in the orchestrator worktree reads that worktree STATE, not the main checkout behind it', async ($, on) => {
  world(on, LAYOUT, { top: ORCH, common: `${MAIN}/.git`, trees: LAYOUT_TREES, commits: LAYOUT_COMMITS })
  await $.session.start({ cwd: ORCH, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ type: 'Button', key: 'card-T010' })).toBeDefined()
    expect(await ui.find({ type: 'Button', key: 'card-T001' })).toBeUndefined()
    expect(await ui.find({ type: 'Text', text: /kaynak: orch/ })).toBeDefined()
    await ui.unmount()
  }
})

test('an implementer worktree session reads the orchestrator STATE, not its own dispatch-time copy', async ($, on) => {
  world(on, LAYOUT, { top: IMPL, common: `${MAIN}/.git`, trees: LAYOUT_TREES, commits: LAYOUT_COMMITS })
  await $.session.start({ cwd: IMPL, surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Button', key: 'card-T011' })).toBeDefined()
  await ui.unmount()
})

test('a main checkout session follows an orchestrator worktree opened after it started', async ($, on) => {
  const git = { top: MAIN, common: `${MAIN}/.git`, trees: MAIN_TREE, commits: LAYOUT_COMMITS }
  const { now } = world(on, LAYOUT, git)
  await $.session.start({ cwd: MAIN, surface: 'desktop', isInteractive: true })
  let ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Button', key: 'card-T001' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /kaynak:/ })).toBeUndefined()
  await ui.unmount()
  git.trees = LAYOUT_TREES
  await now.advance(20_100)
  ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Button', key: 'card-T010' })).toBeDefined()
  await ui.unmount()
})

test('equal `updated` stamps: the copy changed last wins, not the freshly pulled main checkout', async ($, on) => {
  world(on, TIE.files, { top: MAIN, common: `${MAIN}/.git`, trees: LAYOUT_TREES, ...TIE.repo })
  await $.session.start({ cwd: MAIN, surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /kabul/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /kaynak: orch/ })).toBeDefined()
  await ui.unmount()
})
