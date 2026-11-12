// Reads a delix project through `$` into one Snapshot. Files are parsed again
// only when their mtime moved; the worktree list, and with it the checkout whose
// STATE.json is read, is asked every 20 seconds.

import type { EngineInterface } from 'claude-code'

import type { Card, CardReport, Snapshot, TestResult } from '../types'
import {
  derive,
  gateCount,
  gatesOf,
  parseCard,
  parseMetrics,
  parseReport,
  parseState,
  parseTestResult,
  parseWorktrees,
  trimSlashes,
  type MetricRow,
  type ParsedCard,
  type ParsedState,
  type Raw,
  type RawWorktree,
} from './parse'

type Cached<T> = { mtimeMs: number; value: T }

/** What one 20-second look learns from git: derive's input without `now` and the files. */
type GitLook = Omit<Raw, 'now' | 'worktrees'> & { worktrees: Record<string, Omit<RawWorktree, 'files'>> }

export type Cache = {
  files: Map<string, Cached<unknown>>
  /** File texts for derive, kept apart from `files`, where the same path (STATE, a report, a card) is cached parsed. */
  texts: Map<string, Cached<unknown>>
  worktrees: { at: number; list: { path: string; branch: string }[]; root: string | null; git: GitLook }
}

export const newCache = (): Cache => ({ files: new Map(), texts: new Map(), worktrees: { at: 0, list: [], root: null, git: { worktrees: {} } } })

const STATE = 'docs/delix/STATE.json'
const REFS_FORMAT = '--format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)'

/** K263: every git call takes no optional lock (another worktree's index stays unwritten) and runs no fsmonitor hook from the shared config. */
const GIT = ['git', '--no-optional-locks', '-c', 'core.fsmonitor=false']
/** Spec C §6: a file the board reads is a regular file, not a link, of at most 1 MiB. */
const MAX_FILE_BYTES = 1048576

const join = (...parts: string[]) => parts.join('/').replace(/\/+/g, '/')
export const basename = (p: string) => trimSlashes(p).split('/').pop() ?? p

/** `git worktree list --porcelain -z` in the newline form the parsers read; '' when a field holds a newline or a CR (K263). */
export function zList(text: string): string {
  const fields = text.split('\0')
  return fields.some(f => f.includes('\n') || f.includes('\r')) ? '' : fields.join('\n')
}

/** The session's checkout: the git toplevel of `cwd`, else `cwd` itself. */
export async function findTop($: EngineInterface, cwd: string): Promise<string> {
  const git = await $.process.run([...GIT, 'rev-parse', '--show-toplevel'], { cwd, timeoutMs: 5000 }).catch(() => undefined)
  const top = git?.exitCode === 0 ? git.stdout.trim().split('\n')[0] : undefined
  return top || cwd
}

/**
 * S1 (Spec C §6, K277): `rel` under `base` when it names a regular file of at most 1 MiB reached through no link.
 * `rel` is not empty, not absolute and has no part `''`, `.` or `..`; every part below `base` stats as a directory
 * that is not a link, the last part as a file that is not a link. `$.fs.stat`'s `isLink` speaks of the path itself
 * only, so each part is asked. Any throw is null.
 */
async function safeStat($: EngineInterface, base: string, rel: string): Promise<{ path: string; mtimeMs: number } | null> {
  const parts = rel.split('/')
  if (rel === '' || rel.startsWith('/') || parts.some(p => p === '' || p === '.' || p === '..')) return null
  try {
    for (let i = 1; i < parts.length; i++) {
      const dir = await $.fs.stat(join(base, ...parts.slice(0, i)))
      if (dir.kind !== 'dir' || dir.isLink !== false) return null
    }
    const path = join(base, rel)
    const file = await $.fs.stat(path)
    return file.kind === 'file' && file.isLink === false && file.size <= MAX_FILE_BYTES ? { path, mtimeMs: file.mtimeMs } : null
  } catch {
    return null
  }
}

/** `rel` under `base` parsed, through `safeStat`; parsed again only when its mtime moved. A text over 1 MiB is dropped. */
async function readIfChanged<T>($: EngineInterface, cache: Cache, base: string, rel: string, parse: (text: string) => T): Promise<T | null> {
  const stat = await safeStat($, base, rel)
  if (stat === null) {
    cache.files.delete(join(base, rel))
    return null
  }
  const hit = cache.files.get(stat.path)
  if (hit && hit.mtimeMs === stat.mtimeMs) return hit.value as T
  const text = await $.fs.read(stat.path).catch(() => undefined)
  if (typeof text !== 'string' || text.length > MAX_FILE_BYTES) return null
  const value = parse(text)
  cache.files.set(stat.path, { mtimeMs: stat.mtimeMs, value })
  return value
}

/**
 * When a worktree's STATE.json last really changed: its mtime while it has uncommitted changes, else the time of
 * the commit that last touched it. A checkout or pull gives an old copy a fresh mtime, and the lead does
 * not always move `updated`, so neither is trusted alone. From the look's results; no call of its own.
 */
const changedAt = (tree: Seen): number => (tree.isDirty ? tree.mtimeMs : (tree.logCt ?? 0) * 1000)

/** One worktree as the look saw it: STATE there and uncommitted, `.delix/card` there, STATE's mtime and last commit time (s). */
type Seen = { path: string; hasState: boolean; hasCard: boolean; isDirty: boolean; mtimeMs: number; logCt: number | null }

/**
 * The checkout whose STATE.json is live. The lead may write it in its own worktree (the desktop app opens
 * one per session) while the main checkout stays behind, and every implementer worktree holds the copy of its
 * dispatch. Among the worktrees holding one, implementer worktrees (`.delix/card`) left out: the copy changed last;
 * on a tie the session's own checkout, then the main checkout (listed first).
 */
function chooseRoot(top: string, trees: Seen[]): string {
  const found: { path: string; changedAt: number; rank: number }[] = []
  for (const [i, tree] of trees.entries()) {
    if (!tree.hasState || tree.hasCard) continue
    found.push({ path: tree.path, changedAt: changedAt(tree), rank: tree.path === top ? 0 : i === 0 ? 1 : 2 })
  }
  found.sort((a, b) => b.changedAt - a.changedAt || a.rank - b.rank)
  return found[0]?.path ?? top
}

/** The branch `origin/<default>...HEAD` compares with: delix.json's `default_branch` when it is a plain name, else `main`. */
async function defaultBranch($: EngineInterface, cache: Cache, top: string): Promise<string> {
  const value = await readIfChanged($, cache, top, 'docs/delix/delix.json', text => {
    try {
      const json: unknown = JSON.parse(text)
      return typeof json === 'object' && json !== null && 'default_branch' in json ? json.default_branch : null
    } catch {
      return null
    }
  })
  return typeof value === 'string' && /^[A-Za-z0-9][A-Za-z0-9._/-]*$/.test(value) ? value : 'main'
}

/**
 * The 20-second look (Spec C §4, K257, K262): at most 4 + 3N git calls for N worktrees, each in its worktree as `cwd`.
 * Four for the repository (common dir, worktree list, refs, the STATE at origin/HEAD), then per worktree
 * `status`, and for a card-less one whose STATE is not uncommitted the three-dot `diff` and, if it holds a STATE,
 * its last commit time.
 */
async function worktrees($: EngineInterface, cache: Cache, top: string, now: number) {
  if (now - cache.worktrees.at < 20_000 && cache.worktrees.at !== 0) return cache.worktrees
  const git = (cwd: string, args: string[]) => $.process.run([...GIT, ...args], { cwd, timeoutMs: 5000 }).catch(() => undefined)
  const stdout = (run: Awaited<ReturnType<typeof git>>) => (run?.exitCode === 0 ? run.stdout : null)
  const commonLine = stdout(await git(top, ['rev-parse', '--git-common-dir']))?.split('\n')[0]?.trim() ?? ''
  const common = commonLine === '' ? null : commonLine.startsWith('/') ? commonLine : join(top, commonLine)
  const listZ = stdout(await git(top, ['worktree', 'list', '--porcelain', '-z']))
  const listText = listZ === null ? null : zList(listZ)
  const list = listText === null ? [] : parseWorktrees(listText)
  const refs = stdout(await git(top, ['for-each-ref', 'refs/heads', 'refs/remotes', REFS_FORMAT])) ?? ''
  const def = await defaultBranch($, cache, top)
  // R1 (K262), R-G7 (K277): the STATE the lead pushed; `cat-file blob` runs no textconv or filter, `--no-lazy-fetch` keeps
  // it off the network, `--no-replace-objects` reads the blob itself, not a `refs/replace/*` stand-in.
  const trusted = stdout(await git(top, ['--no-lazy-fetch', '--no-replace-objects', 'cat-file', 'blob', `refs/remotes/origin/HEAD:${STATE}`]))
  const facts: GitLook['worktrees'] = {}
  const seen: Seen[] = []
  for (const tree of list) {
    const hasCard = await $.fs.exists(join(tree.path, '.delix/card')).catch(() => false)
    const stat = await $.fs.stat(join(tree.path, STATE)).catch(() => undefined)
    const hasState = stat?.kind === 'file'
    const mtimeMs = stat?.mtimeMs ?? 0
    const status = stdout(await git(tree.path, ['status', '--porcelain']))
    const isDirty = status !== null && status.split('\n').some(l => l.slice(3) === STATE)
    let diffExit: number | null = null
    let logCt: number | null = null
    if (!hasCard && !isDirty) {
      const diff = await git(tree.path, ['diff', '--no-ext-diff', '--quiet', `origin/${def}...HEAD`, '--', STATE])
      diffExit = diff?.exitCode === 0 || diff?.exitCode === 1 ? diff.exitCode : null
      if (hasState) {
        // R-G6 (K277): `--no-show-signature`, so `log.showSignature` runs no `gpg.program` per signed commit.
        const ct = stdout(await git(tree.path, ['log', '-1', '--no-show-signature', '--format=%ct', '--', STATE]))?.trim() ?? ''
        logCt = /^\d+$/.test(ct) ? Number(ct) : null
      }
    }
    facts[tree.path] = { status, state_diff_exit: diffExit, state_log_ct: logCt, state_mtime: isDirty && hasState ? Math.floor(mtimeMs / 1000) : null }
    seen.push({ path: tree.path, hasState, hasCard, isDirty, mtimeMs, logCt })
  }
  const fetchHeads: Record<string, number> = {}
  if (common !== null) {
    const stamp = async (path: string) => {
      const stat = await $.fs.stat(path).catch(() => undefined)
      if (stat?.kind === 'file') fetchHeads[path] = Math.floor(stat.mtimeMs / 1000)
    }
    await stamp(join(common, 'FETCH_HEAD'))
    for (const entry of await $.fs.list(join(common, 'worktrees')).catch(() => [])) await stamp(join(common, 'worktrees', entry.name, 'FETCH_HEAD'))
  }
  const root = chooseRoot(top, seen)
  cache.worktrees = {
    at: now,
    list,
    root,
    git: { default_branch: def, trusted_state: trusted, self: top, source: root, common_dir: common, fetch_head_mtimes: fetchHeads, worktree_list: listText ?? '', for_each_ref: refs, worktrees: facts },
  }
  return cache.worktrees
}

/** The project files a STATE points derive at: its spec, and the file of each open Tier 3 card; relative paths inside the checkout only. */
function linkedFiles(text: string | undefined): string[] {
  let state: unknown = null
  try {
    state = text === undefined ? null : JSON.parse(text)
  } catch {
    return []
  }
  const isRecord = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v)
  if (!isRecord(state)) return []
  const out: string[] = typeof state.spec === 'string' ? [state.spec] : []
  if (isRecord(state.cards)) {
    for (const card of Object.values(state.cards)) {
      if (isRecord(card) && card.tier === 3 && card.status === 'open' && typeof card.file === 'string') out.push(card.file)
    }
  }
  return out.filter(p => p !== '' && !p.startsWith('/') && !p.split('/').includes('..'))
}

/** derive's `files` per worktree (STATE, `.delix/card`, `.delix/report.md` and what the STATE points at), each read again only when its mtime moved. */
async function withFiles($: EngineInterface, cache: Cache, facts: GitLook['worktrees']): Promise<Record<string, RawWorktree>> {
  const texts: Cache = { ...cache, files: cache.texts }
  const out: Record<string, RawWorktree> = {}
  for (const [path, seen] of Object.entries(facts)) {
    const files: Record<string, string> = {}
    const add = async (rel: string) => {
      const text = await readIfChanged<string>($, texts, path, rel, t => t)
      if (text !== null) files[rel] = text
    }
    for (const rel of [STATE, '.delix/card', '.delix/report.md']) await add(rel)
    for (const rel of linkedFiles(files[STATE])) await add(rel)
    out[path] = { ...seen, files }
  }
  return out
}

const emptySnapshot = (root: string): Snapshot => ({
  isDelix: false,
  root,
  project: basename(root),
  source: null,
  spec: null,
  previous: null,
  size: null,
  updated: null,
  envOwner: null,
  waves: [],
  cards: [],
  verifications: [],
  worktreeCount: 0,
  agents: [],
  leads: [],
  queue: { waiting: [], ready: [], done: [] },
  actions: [],
  fetchedAt: 'never fetched',
})

/** One pass over the project seen from the session's checkout `top`: STATE, cards, metrics, worktrees and their .delix files. */
export async function readSnapshot($: EngineInterface, top: string, cache: Cache, now: number): Promise<Snapshot> {
  const seen = await worktrees($, cache, top, now)
  const trees = seen.list
  const root = seen.root ?? top
  const main = trees[0]?.path ?? root
  const delix = join(root, 'docs/delix')
  const state = await readIfChanged<ParsedState | null>($, cache, root, STATE, parseState)
  const taskEntries = await $.fs.list(join(delix, 'tasks')).catch(() => [])
  const cardFiles = taskEntries.filter(f => f.kind === 'file' && /^T\d{3}-.*\.md$/.test(f.name))
  if (state === null && cardFiles.length === 0) return emptySnapshot(root)

  // Cards of an earlier spec keep their files; their record is in the archived STATE `previous` names.
  const previous = state?.previous ? await readIfChanged<ParsedState | null>($, cache, root, state.previous, parseState) : null
  const metrics = (await readIfChanged($, cache, root, 'docs/delix/metrics.md', parseMetrics)) ?? ({} as Record<string, MetricRow>)
  const parsedCards: Record<string, ParsedCard & { file: string }> = {}
  for (const f of cardFiles) {
    const id = f.name.slice(0, 4)
    const path = join(delix, 'tasks', f.name)
    const card = await readIfChanged($, cache, root, `docs/delix/tasks/${f.name}`, parseCard)
    if (card) parsedCards[id] = { ...card, file: path }
  }

  const reports: Record<string, { path: string; branch: string; report: CardReport | null; test: TestResult | null }> = {}
  for (const tree of trees) {
    const dot = join(tree.path, '.delix')
    const entries = await $.fs.list(dot).catch(() => [])
    const byName = new Map(entries.map(e => [e.name, e]))
    let id: string | null = null
    const cardEntry = byName.get('card')
    if (cardEntry) {
      const text = await readIfChanged($, cache, tree.path, '.delix/card', t => t)
      id = /(T\d{3})/.exec(text ?? '')?.[1] ?? null
    }
    id ??= /(T\d{3})/.exec(tree.branch || basename(tree.path))?.[1] ?? null
    if (id === null) continue
    const reportEntry = byName.get('report.md')
    const testEntry = byName.get('test-result.txt')
    reports[id] = {
      path: tree.path,
      branch: tree.branch,
      report: reportEntry ? await readIfChanged($, cache, tree.path, '.delix/report.md', parseReport) : null,
      test: testEntry ? await readIfChanged($, cache, tree.path, '.delix/test-result.txt', parseTestResult) : null,
    }
  }

  // Spec C: derive on the look's git part and the files as they are now (K252: the same rules as board.py).
  const derived = derive({ ...seen.git, now: Math.floor(now / 1000), worktrees: await withFiles($, cache, seen.git.worktrees) })

  const waveOf: Record<string, number> = {}
  for (const w of state?.waves ?? []) for (const id of w.cards) waveOf[id] ??= w.wave
  const ids = [...new Set([...Object.keys(state?.cards ?? {}), ...Object.keys(parsedCards)])].sort()
  const cards: Card[] = ids.map(id => {
    const isArchived = state !== null && Object.keys(state.cards).length > 0 && !(id in state.cards)
    const s = isArchived ? previous?.cards[id] : state?.cards[id]
    const p = parsedCards[id]
    const m = metrics[id]
    const r = reports[id]
    const status = s?.status ?? p?.table.status ?? 'open'
    const tier = s?.tier ?? p?.table.tier ?? null
    const pr = s?.pr ?? (r?.report?.pr ? `#${r.report.pr}` : null)
    const isMerged = pr !== null && /^merge\b/i.test(pr)
    const agents = s?.agents ?? []
    const reasons = agents.length > 0 ? derived.queue.waiting.filter(w => w.card === id).map(w => w.reason) : null
    return {
      id,
      title: p?.title ?? '',
      role: s?.role ?? p?.table.role ?? '?',
      tier,
      wave: isArchived ? null : (waveOf[id] ?? s?.wave ?? p?.table.wave ?? null),
      status,
      isArchived,
      rounds: s?.rounds ?? m?.rounds ?? null,
      pr,
      isMerged,
      costUsd: s?.costUsd ?? m?.costUsd ?? null,
      durationMin: m?.durationMin ?? null,
      gateCount: gateCount(tier),
      qa: s?.qa ?? null,
      security: s?.security ?? null,
      approved: s?.approved ?? null,
      gates: isArchived ? [] : gatesOf({ tier, status, pr, isMerged, reasons }, r?.report?.status ?? null),
      files: p?.files ?? [],
      reviewRounds: p?.reviewRounds ?? [],
      worktree: r?.path ?? null,
      branch: r?.branch ?? null,
      report: r?.report ?? null,
      test: r?.test ?? null,
      agents,
    }
  })
  cards.sort((a, b) => Number(a.isArchived) - Number(b.isArchived) || (a.wave ?? 99) - (b.wave ?? 99) || a.id.localeCompare(b.id))

  return {
    isDelix: true,
    root,
    project: basename(main),
    source: root === main ? null : basename(root),
    spec: state?.spec ?? null,
    previous: state?.previous ?? null,
    size: state?.size ?? null,
    updated: state?.updated ?? null,
    envOwner: state?.envOwner ?? null,
    waves: state?.waves ?? [],
    cards,
    verifications: state?.verifications ?? [],
    worktreeCount: trees.length,
    agents: derived.agents,
    leads: derived.leads,
    queue: derived.queue,
    actions: derived.actions,
    fetchedAt: derived.fetched_at,
  }
}
