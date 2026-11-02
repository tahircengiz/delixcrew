// Reads a delix project through `$` into one Snapshot. Files are parsed again
// only when their mtime moved; the worktree list is asked every 20 seconds.

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
  worktrees: { at: number; list: { path: string; branch: string }[] }
}

export const newCache = (): Cache => ({ files: new Map(), worktrees: { at: 0, list: [] } })

const join = (...parts: string[]) => parts.join('/').replace(/\/+/g, '/')
const dirname = (p: string) => p.replace(/\/[^/]*\/?$/, '') || '/'
const basename = (p: string) => p.replace(/\/+$/, '').split('/').pop() ?? p

/** The project root: the main checkout when it holds docs/delix/STATE.json (the orchestrator writes it there), else the toplevel. */
export async function findRoot($: EngineInterface, cwd: string): Promise<string> {
  const has = (dir: string) => $.fs.exists(join(dir, 'docs/delix/STATE.json')).catch(() => false)
  const git = await $.process
    .run(['git', 'rev-parse', '--show-toplevel', '--git-common-dir'], { cwd, timeoutMs: 5000 })
    .catch(() => undefined)
  if (git?.exitCode === 0) {
    const [top, common] = git.stdout.trim().split('\n')
    if (top && common) {
      const commonAbs = common.startsWith('/') ? common : join(cwd, common)
      const main = /\/\.git\/?$/.test(commonAbs) ? dirname(commonAbs.replace(/\/$/, '')) : null
      if (main !== null && main !== top && (await has(main))) return main
      return top
    }
  }
  return cwd
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

async function worktrees($: EngineInterface, cache: Cache, root: string, now: number) {
  if (now - cache.worktrees.at < 20_000 && cache.worktrees.at !== 0) return cache.worktrees.list
  const run = await $.process.run(['git', 'worktree', 'list', '--porcelain'], { cwd: root, timeoutMs: 5000 }).catch(() => undefined)
  cache.worktrees = { at: now, list: run?.exitCode === 0 ? parseWorktrees(run.stdout) : [] }
  return cache.worktrees.list
}

const emptySnapshot = (root: string): Snapshot => ({
  isDelix: false,
  root,
  project: basename(root),
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

/** One pass over the project: STATE, cards, metrics, worktrees and their .delix files. */
export async function readSnapshot($: EngineInterface, root: string, cache: Cache, now: number): Promise<Snapshot> {
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
  const trees = await worktrees($, cache, root, now)
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
    project: basename(root),
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
