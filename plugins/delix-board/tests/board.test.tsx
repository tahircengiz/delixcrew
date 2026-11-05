import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

import { cut, minutes, parseCard, parseMetrics, parseState, runProgress } from '../hooks/parse'
import { FILES, IMPL, LAYOUT, LAYOUT_COMMITS, LAYOUT_TREES, MAIN, MAIN_TREE, ORCH, ROOT, RUN_ALL, TEMPLATE_STATE, TIE, WORKTREES } from './fixtures'
import { derive, type Raw } from '../hooks/parse'
import { PARITY } from './board_parity'

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
    expect((await band.find({ type: 'Text', text: /kapı bekliyor/ }))?.text).toMatch(/1 kapı bekliyor/)
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
  expect((await band.find({ type: 'Text', text: /kapı bekliyor/ }))?.text).toMatch(/1 kapı bekliyor/)
  await band.unmount()
})

test('a session in the lead worktree reads that worktree STATE, not the main checkout behind it', async ($, on) => {
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

test('an implementer worktree session reads the lead STATE, not its own dispatch-time copy', async ($, on) => {
  world(on, LAYOUT, { top: IMPL, common: `${MAIN}/.git`, trees: LAYOUT_TREES, commits: LAYOUT_COMMITS })
  await $.session.start({ cwd: IMPL, surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Button', key: 'card-T011' })).toBeDefined()
  await ui.unmount()
})

test('a main checkout session follows a lead worktree opened after it started', async ($, on) => {
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

test('derive output equals the parity fixture (K252)', () => {
  expect(derive(PARITY.raw as unknown as Raw)).toEqual(PARITY.expected)
})

type RawTree = { status: string | null; state_diff_exit: number | null; state_log_ct: number | null; state_mtime: number | null; files: Record<string, string> }
type RawWorld = { now: number; self: string; common_dir: string; worktree_list: string; for_each_ref: string; fetch_head_mtimes: Record<string, number>; worktrees: Record<string, RawTree> }

/** Git and the files exactly as one raw input of derive describes them; counts the git calls. */
function gitWorld(on: On, raw: RawWorld) {
  const calls = { n: 0 }
  const now = mock.clock(on, { now: raw.now * 1000 })
  mock.store(on)
  const disk = new Map<string, { text: string; mtimeMs: number }>()
  for (const [path, tree] of Object.entries(raw.worktrees)) {
    for (const [rel, text] of Object.entries(tree.files)) {
      const mtimeMs = rel === 'docs/delix/STATE.json' && tree.state_mtime !== null ? tree.state_mtime * 1000 : 1
      disk.set(`${path}/${rel}`, { text, mtimeMs })
    }
  }
  for (const [path, seconds] of Object.entries(raw.fetch_head_mtimes)) disk.set(path, { text: '', mtimeMs: seconds * 1000 })
  const missing = (path: string) => new Error(`ENOENT: ${path}`)
  const out = (stdout: string, exitCode = 0) => ({ value: { exitCode, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
  on('process.run', (_, e) => {
    calls.n += 1
    const tree = raw.worktrees[e.init?.cwd ?? '']
    if (e.argv.includes('--show-toplevel')) return out(`${raw.self}\n`)
    if (e.argv.includes('--git-common-dir')) return out(`${raw.common_dir}\n`)
    if (e.argv.includes('worktree')) return out(raw.worktree_list)
    if (e.argv.includes('for-each-ref')) return out(raw.for_each_ref)
    if (e.argv.includes('status')) return tree === undefined || tree.status === null ? out('', 128) : out(tree.status)
    if (e.argv.includes('diff')) return out('', tree?.state_diff_exit ?? 0)
    if (e.argv.includes('log')) return out(`${tree?.state_log_ct ?? ''}\n`)
    return out('', 1)
  })
  on('fs.exists', (_, e) => ({ value: disk.has(e.path) }))
  on('fs.stat', (_, e) => {
    const file = disk.get(e.path)
    if (file === undefined) throw missing(e.path)
    return { value: { kind: 'file', size: file.text.length, mtimeMs: file.mtimeMs, isLink: false } }
  })
  on('fs.read', (_, e) => {
    const file = disk.get(e.path)
    if (file === undefined) throw missing(e.path)
    return { value: file.text }
  })
  on('fs.list', (_, e) => {
    const prefix = e.path.replace(/\/$/, '') + '/'
    const children = new Map<string, boolean>()
    for (const p of disk.keys()) {
      if (!p.startsWith(prefix)) continue
      const [name, ...rest] = p.slice(prefix.length).split('/')
      if (name) children.set(name, (children.get(name) ?? false) || rest.length > 0)
    }
    if (children.size === 0) throw missing(e.path)
    return { value: [...children].map(([name, isDir]) => ({ name, kind: isDir ? 'dir' : 'file', size: 1, mtimeMs: 1, isLink: false })) }
  })
  on('command.register', () => ({ value: { command: 'delix-board' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.status', () => ({ value: undefined }))
  on('ui.toast', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.attach', (_, e) => ({ clientId: e.clientId }))
  on('session.surfaces', () => ({ value: [] }))
  on('session.cwd', () => ({ value: raw.self }))
  return { calls, now }
}

test('one 20-second look asks git at most 3 + 3N times (K257)', async ($, on) => {
  const { calls, now } = gitWorld(on, PARITY.raw)
  await $.session.start({ cwd: PARITY.raw.self, surface: 'desktop', isInteractive: true })
  calls.n = 0
  await now.advance(20_100)
  expect(calls.n).toBeGreaterThan(0)
  expect(calls.n).toBeLessThanOrEqual(3 + 3 * 16)
})

test('the board shows the five sections and the card ledger', async ($, on) => {
  const raw = JSON.parse(JSON.stringify(PARITY.raw)) as RawWorld
  const lead = raw.worktrees['/r/.claude/worktrees/lead-c']
  if (lead) lead.state_log_ct = 1762299999
  gitWorld(on, raw)
  await $.session.start({ cwd: raw.self, surface: 'desktop', isInteractive: true })
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    for (const heading of ['Leads', 'Ajanlar', 'Seni bekliyor', "Merge'e hazır", 'Git işleri']) {
      expect(await ui.find({ type: 'Text', text: heading })).toBeDefined()
    }
    expect(await ui.find({ type: 'Text', text: 'gh pr merge 60 --squash --match-head-commit d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /unsafe name: run by hand/ })).toBeDefined()
    await ui.press({ key: 'card-T029' })
    expect(await ui.find({ type: 'Text', text: /qa r1 @d1d1d1d REJECT · by claude\/lead-c/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /qa r2 @d2d2d2d ACCEPT · by claude\/lead-c/ })).toBeDefined()
    await ui.press({ key: 'tab-pano' })
    await ui.unmount()
  }
})

test('derive follows the T029 edge rules: no branch and no detached line, a null remote tip or qa sha', () => {
  const sha = (c: string) => c.repeat(40)
  const tree = (path: string, head: string, ...rest: string[]) => [`worktree ${path}`, `HEAD ${head}`, ...rest, ''].join('\n')
  const state = {
    cards: {
      T001: { status: 'in_review', pr: 7, tier: 1, agents: [{ role: 'implementer', by: 'claude/x', branch: 't001' }, { role: 'qa', round: 1, verdict: 'ACCEPT' }] },
      T002: { status: 'in_review', pr: 8, tier: 1, agents: [{ role: 'implementer', branch: 't002' }, { role: 'qa', round: 1, verdict: 'ACCEPT', sha: sha('5') }] },
    },
  }
  const raw: Raw = {
    default_branch: 'main',
    now: 1800000000,
    self: '/r',
    source: '/r',
    worktree_list: [
      tree('/r', sha('1'), 'branch refs/heads/main'),
      tree('/r/bare', sha('2'), 'bare'),
      tree('/r/both', sha('3'), 'branch refs/heads/feat', 'detached'),
      tree('/r/impl', sha('4'), 'branch refs/heads/t001'),
    ].join('\n'),
    for_each_ref: [
      ['refs/heads/main', sha('1'), 'refs/remotes/origin/main', '', '1799999000'],
      ['refs/heads/feat', sha('3'), 'refs/remotes/origin/feat', 'ahead 2', '1799999000'],
      ['refs/heads/t001', sha('4'), '', '', '1799999000'],
      ['refs/remotes/origin/t002', sha('5'), '', '', '1799999000'],
    ]
      .map(f => f.join('\t'))
      .join('\n'),
    worktrees: {
      '/r': { status: '', files: { 'docs/delix/STATE.json': JSON.stringify(state) } },
      '/r/bare': { status: '' },
      '/r/both': { status: '' },
      '/r/impl': { status: '', files: { '.delix/card': 'docs/delix/tasks/T001-x.md' } },
    },
  }
  const d = derive(raw)
  expect(d.agents.map(a => [a.path, a.branch, a.upstream])).toEqual([
    ['/r/impl', 't001', 'no upstream'],
    ['/r', 'main', 'in sync'],
    ['/r/bare', null, '?'],
    ['/r/both', 'feat', '2 ahead'],
  ])
  expect(d.queue).toEqual({
    waiting: [
      { card: 'T001', verification: null, reason: 'changed after review' },
      { card: 'T002', verification: null, reason: 'ready to merge' },
    ],
    ready: [{ card: 'T002', pr: 8, sha: sha('5') }],
    done: [],
  })
  expect(d.actions).toEqual([
    { kind: 'push', target: '/r/both', card: null, command: 'git -C /r/both push -u origin feat', note: '' },
    { kind: 'push', target: '/r/impl', card: 'T001', command: 'git -C /r/impl push -u origin t001', note: '' },
    { kind: 'merge', target: '#8', card: 'T002', command: `gh pr merge 8 --squash --match-head-commit ${sha('5')}`, note: '' },
  ])
})

test('a long space run in the spec heading or a run line costs linear time (T030 fix round 1, security Medium)', () => {
  const pad = ' '.repeat(100000)
  const raw: Raw = {
    default_branch: 'main',
    now: 1800000000,
    self: '/r',
    source: '/r',
    worktree_list: ['worktree /r', `HEAD ${'1'.repeat(40)}`, 'branch refs/heads/main', ''].join('\n'),
    for_each_ref: '',
    worktrees: { '/r': { status: '', files: { 'docs/delix/STATE.json': JSON.stringify({ spec: 'S.md', cards: {} }), 'S.md': `# T${pad}x \t\n` } } },
  }
  const t0 = Date.now()
  expect(derive(raw).leads.map(l => l.spec_title)).toEqual([`T${pad}x`])
  expect(Date.now() - t0).toBeLessThan(500)
  const t1 = Date.now()
  expect(runProgress(`ok 1${pad}x \n`).tail).toEqual([`ok 1${pad}x`])
  expect(Date.now() - t1).toBeLessThan(500)
})
