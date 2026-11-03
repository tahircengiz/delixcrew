// Reads a delix project through `$` into one Snapshot. Files are parsed again
// only when their mtime moved; the worktree list, and with it the checkout whose
// STATE.json is read, is asked every 20 seconds.

import type { EngineInterface } from 'claude-code'

import type { Card, CardReport, Snapshot, TestResult } from '../types'
import {
  gateCount,
  gatesOf,
  parseCard,
  parseMetrics,
  parseReport,
  parseState,
  parseTestResult,
  parseWorktrees,
  type MetricRow,
  type ParsedCard,
  type ParsedState,
} from './parse'

type Cached<T> = { mtimeMs: number; value: T }

export type Cache = {
  files: Map<string, Cached<unknown>>
  worktrees: { at: number; list: { path: string; branch: string }[]; root: string | null }
}

export const newCache = (): Cache => ({ files: new Map(), worktrees: { at: 0, list: [], root: null } })

const join = (...parts: string[]) => parts.join('/').replace(/\/+/g, '/')
const basename = (p: string) => p.replace(/\/+$/, '').split('/').pop() ?? p

/** The session's checkout: the git toplevel of `cwd`, else `cwd` itself. */
export async function findTop($: EngineInterface, cwd: string): Promise<string> {
  const git = await $.process.run(['git', 'rev-parse', '--show-toplevel'], { cwd, timeoutMs: 5000 }).catch(() => undefined)
  const top = git?.exitCode === 0 ? git.stdout.trim().split('\n')[0] : undefined
  return top || cwd
}

async function readIfChanged<T>($: EngineInterface, cache: Cache, path: string, mtimeMs: number | null, parse: (text: string) => T): Promise<T | null> {
  let mtime = mtimeMs
  if (mtime === null) {
    const stat = await $.fs.stat(path).catch(() => undefined)
    if (!stat || stat.kind !== 'file') {
      cache.files.delete(path)
      return null
    }
    mtime = stat.mtimeMs
  }
  const hit = cache.files.get(path)
  if (hit && hit.mtimeMs === mtime) return hit.value as T
  const text = await $.fs.read(path).catch(() => undefined)
  if (typeof text !== 'string') return null
  const value = parse(text)
  cache.files.set(path, { mtimeMs: mtime, value })
  return value
}

/**
 * The checkout whose STATE.json is live. The orchestrator may write it in its own worktree (the desktop app opens
 * one per session) while the main checkout stays behind, and every implementer worktree holds the copy of its
 * dispatch. Among the worktrees holding one, implementer worktrees (`.delix/card`) left out: the newest `updated`;
 * on a tie the session's own checkout, then the main checkout (listed first), then the newest mtime. A fresh
 * checkout has a fresh mtime, so mtime only breaks ties.
 */
async function chooseRoot($: EngineInterface, cache: Cache, top: string, trees: { path: string }[]): Promise<string> {
  const found: { path: string; updated: number; rank: number; mtimeMs: number }[] = []
  for (const [i, tree] of trees.entries()) {
    const path = join(tree.path, 'docs/delix/STATE.json')
    const stat = await $.fs.stat(path).catch(() => undefined)
    if (!stat || stat.kind !== 'file') continue
    if (await $.fs.exists(join(tree.path, '.delix/card')).catch(() => false)) continue
    const state = await readIfChanged<ParsedState | null>($, cache, path, stat.mtimeMs, parseState)
    const updated = Date.parse(state?.updated ?? '')
    found.push({ path: tree.path, updated: Number.isNaN(updated) ? 0 : updated, rank: tree.path === top ? 0 : i === 0 ? 1 : 2, mtimeMs: stat.mtimeMs })
  }
  found.sort((a, b) => b.updated - a.updated || a.rank - b.rank || b.mtimeMs - a.mtimeMs)
  return found[0]?.path ?? top
}

async function worktrees($: EngineInterface, cache: Cache, top: string, now: number) {
  if (now - cache.worktrees.at < 20_000 && cache.worktrees.at !== 0) return cache.worktrees
  const run = await $.process.run(['git', 'worktree', 'list', '--porcelain'], { cwd: top, timeoutMs: 5000 }).catch(() => undefined)
  const list = run?.exitCode === 0 ? parseWorktrees(run.stdout) : []
  cache.worktrees = { at: now, list, root: await chooseRoot($, cache, top, list) }
  return cache.worktrees
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
})

/** One pass over the project seen from the session's checkout `top`: STATE, cards, metrics, worktrees and their .delix files. */
export async function readSnapshot($: EngineInterface, top: string, cache: Cache, now: number): Promise<Snapshot> {
  const seen = await worktrees($, cache, top, now)
  const trees = seen.list
  const root = seen.root ?? top
  const main = trees[0]?.path ?? root
  const delix = join(root, 'docs/delix')
  const state = await readIfChanged<ParsedState | null>($, cache, join(delix, 'STATE.json'), null, parseState)
  const taskEntries = await $.fs.list(join(delix, 'tasks')).catch(() => [])
  const cardFiles = taskEntries.filter(f => f.kind === 'file' && /^T\d{3}-.*\.md$/.test(f.name))
  if (state === null && cardFiles.length === 0) return emptySnapshot(root)

  // Cards of an earlier spec keep their files; their record is in the archived STATE `previous` names.
  const previous = state?.previous ? await readIfChanged<ParsedState | null>($, cache, join(root, state.previous), null, parseState) : null
  const metrics = (await readIfChanged($, cache, join(delix, 'metrics.md'), null, parseMetrics)) ?? ({} as Record<string, MetricRow>)
  const parsedCards: Record<string, ParsedCard & { file: string }> = {}
  for (const f of cardFiles) {
    const id = f.name.slice(0, 4)
    const path = join(delix, 'tasks', f.name)
    const card = await readIfChanged($, cache, path, f.mtimeMs, parseCard)
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
      const text = await readIfChanged($, cache, join(dot, 'card'), cardEntry.mtimeMs, t => t)
      id = /(T\d{3})/.exec(text ?? '')?.[1] ?? null
    }
    id ??= /(T\d{3})/.exec(tree.branch || basename(tree.path))?.[1] ?? null
    if (id === null) continue
    const reportEntry = byName.get('report.md')
    const testEntry = byName.get('test-result.txt')
    reports[id] = {
      path: tree.path,
      branch: tree.branch,
      report: reportEntry ? await readIfChanged($, cache, join(dot, 'report.md'), reportEntry.mtimeMs, parseReport) : null,
      test: testEntry ? await readIfChanged($, cache, join(dot, 'test-result.txt'), testEntry.mtimeMs, parseTestResult) : null,
    }
  }

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
      gates: isArchived ? [] : gatesOf({ tier, status, pr, isMerged }, r?.report?.status ?? null),
      files: p?.files ?? [],
      reviewRounds: p?.reviewRounds ?? [],
      worktree: r?.path ?? null,
      branch: r?.branch ?? null,
      report: r?.report ?? null,
      test: r?.test ?? null,
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
  }
}
