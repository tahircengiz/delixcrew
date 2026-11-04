// Pure parsers for delix's files: no I/O, so the tests reach them directly.
// Rules follow delix's scripts/board.py where it has one.

import type {
  Action,
  AgentRecord,
  AgentRow,
  CardFile,
  CardReport,
  DoneEntry,
  Finding,
  LeadRow,
  ReadyEntry,
  ReviewRound,
  TestResult,
  Verification,
  WaitEntry,
  Wave,
} from '../types'

export const OPEN_STATUSES = ['open', 'in_progress', 'in_review', 'fixing']
const REPORT_STATUSES = ['DONE_WITH_CONCERNS', 'DONE', 'NEEDS_CONTEXT', 'BLOCKED']

type Json = Record<string, unknown>

const isObject = (v: unknown): v is Json => typeof v === 'object' && v !== null && !Array.isArray(v)
const str = (v: unknown): string | null => (typeof v === 'string' && v !== '' ? v : typeof v === 'number' ? String(v) : null)
const num = (v: unknown): number | null => {
  if (typeof v === 'number' && Number.isFinite(v)) return v
  if (typeof v === 'string' && /^\d+$/.test(v.trim())) return Number(v.trim())
  return null
}

/** The first number in a cell, Turkish decimal comma or dot: "≈ 22,7" → 22.7. */
export function firstNumber(text: string): number | null {
  const m = /(\d+(?:[.,]\d+)?)/.exec(text)
  return m?.[1] === undefined ? null : Number(m[1].replace(',', '.'))
}

/** A wall-clock cell in minutes: "4,3 dk", "2 dk 25 sn", "40 sn", "13:22–13:40", "≈ 1 sa 30 dk". */
export function minutes(text: string): number | null {
  const range = /(\d{1,2}):(\d{2})\s*[–-]\s*(\d{1,2}):(\d{2})/.exec(text)
  if (range) {
    const [, h1, m1, h2, m2] = range.map(Number) as [number, number, number, number, number]
    const span = h2 * 60 + m2 - (h1 * 60 + m1)
    return span >= 0 ? span : null
  }
  const h = /(\d+(?:[.,]\d+)?)\s*(?:sa|saat|h)\b/.exec(text)
  const m = /(\d+(?:[.,]\d+)?)\s*(?:dk|min)\b/.exec(text)
  const s = /(\d+(?:[.,]\d+)?)\s*(?:sn|s)\b/.exec(text)
  if (!h && !m && !s) return null
  const n = (x: RegExpExecArray | null) => (x?.[1] === undefined ? 0 : Number(x[1].replace(',', '.')))
  return Math.round((n(h) * 60 + n(m) + n(s) / 60) * 10) / 10
}

export type StateCard = {
  file: string | null
  role: string | null
  tier: number | null
  wave: number | null
  status: string | null
  rounds: number | null
  pr: string | null
  costUsd: number | null
  qa: string | null
  security: string | null
  approved: string | null
  /** The `agents` ledger (Spec C §4), object records only. */
  agents: AgentRecord[]
  merged: { sha: string; head: string; at: string } | null
}

export type ParsedState = {
  spec: string | null
  size: string | null
  updated: string | null
  envOwner: string | null
  previous: string | null
  waves: Wave[]
  cards: Record<string, StateCard>
  verifications: Verification[]
}

// The STATE.json of delix's earlier name (`ekip`) spelled its keys and statuses in Turkish; an archived one still does.
const OLD_STATUS: Record<string, string> = {
  acik: 'open', suruyor: 'in_progress', incelemede: 'in_review', duzeltme: 'fixing', kabul: 'accepted', ret: 'rejected', eskale: 'escalated',
}

/** STATE.json; `waves` as the template's `[["T001"]]` or LLMPortal's `[{ wave, cards, note }]`, old Turkish keys too. */
export function parseState(text: string): ParsedState | null {
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    return null
  }
  if (!isObject(raw)) return null
  const waves: Wave[] = []
  const rawWaves = Array.isArray(raw.waves) ? raw.waves : []
  rawWaves.forEach((w, i) => {
    if (Array.isArray(w)) {
      waves.push({ wave: i + 1, cards: w.filter((c): c is string => typeof c === 'string'), note: '' })
    } else if (isObject(w)) {
      const list = w.cards ?? w.kartlar
      const cards = Array.isArray(list) ? list.filter((c): c is string => typeof c === 'string') : []
      waves.push({ wave: num(w.wave) ?? i + 1, cards, note: str(w.note ?? w.not) ?? '' })
    }
  })
  const cards: Record<string, StateCard> = {}
  const rawCards = raw.cards ?? raw.kartlar
  if (isObject(rawCards)) {
    for (const [id, c] of Object.entries(rawCards)) {
      if (!isObject(c)) continue
      const attempts = Array.isArray(c.cost_attempts_usd)
        ? c.cost_attempts_usd.filter((x): x is number => typeof x === 'number')
        : []
      const cost = typeof c.cost_usd === 'number' ? c.cost_usd : attempts.length > 0 ? attempts.reduce((a, b) => a + b, 0) : null
      cards[id] = {
        file: str(c.file ?? c.dosya),
        role: str(c.role ?? c.rol),
        tier: num(c.tier ?? c.kademe),
        wave: num(c.wave),
        status: ((s: string | null) => (s === null ? null : (OLD_STATUS[s] ?? s)))(str(c.status)),
        rounds: num(c.rounds ?? c.tur),
        pr: str(c.pr),
        costUsd: cost,
        qa: str(c.qa),
        security: str(c.security),
        approved: str(c.approved),
        agents: (Array.isArray(c.agents) ? c.agents : []).filter(isObject).map(a => ({
          role: str(a.role) ?? '?',
          by: str(a.by),
          round: num(a.round),
          sha: str(a.sha),
          verdict: str(a.verdict),
          at: str(a.at),
          branch: str(a.branch),
          session: str(a.session),
        })),
        merged: isObject(c.merged) ? { sha: str(c.merged.sha) ?? '', head: str(c.merged.head) ?? '', at: str(c.merged.at) ?? '' } : null,
      }
    }
  }
  const verifications: Verification[] = (Array.isArray(raw.verifications) ? raw.verifications : [])
    .filter(isObject)
    .map(v => ({
      name: str(v.name) ?? '?',
      date: str(v.date) ?? '',
      tier: num(v.tier),
      verdict: str(v.verdict) ?? '-',
      qa: str(v.qa),
      security: str(v.security),
      costUsd: typeof v.cost_usd === 'number' ? v.cost_usd : null,
    }))
  const owner = raw.env_owner
  const envOwner = isObject(owner) ? [str(owner.card), str(owner.who), str(owner.since)].filter(Boolean).join(' · ') : str(owner)
  return {
    spec: str(raw.spec),
    size: str(raw.size ?? raw.boy),
    updated: str(raw.updated ?? raw.guncelleme),
    previous: str(raw.previous),
    envOwner: envOwner === '' ? null : envOwner,
    waves,
    cards,
    verifications,
  }
}

function section(text: string, heading: RegExp): string[] {
  const lines = text.split('\n')
  const start = lines.findIndex(l => heading.test(l))
  if (start < 0) return []
  const out: string[] = []
  for (const line of lines.slice(start + 1)) {
    if (/^##\s/.test(line)) break
    out.push(line)
  }
  return out
}

const tidy = (s: string) => s.replace(/\*\*|`/g, '').replace(/\s+/g, ' ').trim()

export type ParsedCard = {
  title: string
  table: { role: string | null; tier: number | null; wave: number | null; status: string | null }
  files: CardFile[]
  reviewRounds: ReviewRound[]
}

/** A task card: title, its top table row, the Files list and the review rounds the lead wrote. */
export function parseCard(text: string): ParsedCard {
  const lines = text.split('\n')
  const titleLine = lines.find(l => /^#\s/.test(l)) ?? ''
  const title = tidy(titleLine.replace(/^#\s+/, '').replace(/^T\d{3}\s*[—–-]\s*/, ''))
  const table: ParsedCard['table'] = { role: null, tier: null, wave: null, status: null }
  const rowAt = lines.findIndex(l => /^\|\s*T\d{3}\s*\|/.test(l))
  if (rowAt >= 0) {
    const cells = (l: string) => l.trim().replace(/^\||\|$/g, '').split('|').map(x => x.trim().toLowerCase())
    const row = cells(lines[rowAt] ?? '')
    const head = rowAt >= 2 ? cells(lines[rowAt - 2] ?? '') : []
    const at = (name: string, fallback: number) => {
      const i = head.indexOf(name)
      return row[i >= 0 ? i : fallback] ?? ''
    }
    table.role = at('role', 3) || null
    table.tier = firstNumber(at('tier', 2))
    table.wave = firstNumber(at('wave', 4))
    table.status = at('status', 5) || null
  }
  const files: CardFile[] = []
  for (const line of section(text, /^##\s+Files\b/i)) {
    const m = /^-\s+(?:\*\*)?([A-Za-zÇĞİÖŞÜçğıöşü]+)(?:\*\*)?\s*:\s*(.+)$/.exec(line)
    if (m?.[1] !== undefined && m[2] !== undefined) files.push({ kind: m[1], path: tidy(m[2]) })
  }
  const reviewRounds: ReviewRound[] = []
  for (const line of section(text, /^##\s+(Review findings|İnceleme bulguları)/i)) {
    const top = /^-\s+(.+)$/.exec(line)
    const nested = /^\s{2,}-\s+(.+)$/.exec(line)
    if (top?.[1] !== undefined) {
      reviewRounds.push({ title: tidy(top[1]), findings: [] })
    } else if (nested?.[1] !== undefined && reviewRounds.length > 0) {
      const text = tidy(nested[1])
      reviewRounds[reviewRounds.length - 1]?.findings.push({ text, severity: severity(text) })
    }
  }
  return { title, table, files, reviewRounds }
}

/** The severity a finding names: High/Yüksek, Medium/Orta, Low/Düşük, P0–P2. */
export function severity(text: string): string | null {
  const m = /\b(Critical|Kritik|High|Yüksek|Medium|Orta|Low|Düşük|P0|P1|P2)\b/.exec(text)
  if (!m?.[1]) return null
  const map: Record<string, string> = {
    Critical: 'high', Kritik: 'high', High: 'high', Yüksek: 'high', P0: 'high',
    Medium: 'medium', Orta: 'medium', P1: 'medium',
    Low: 'low', Düşük: 'low', P2: 'low',
  }
  return map[m[1]] ?? null
}

/** .delix/report.md → status, PR, one-line summary (board.py's report_summary). */
export function parseReport(text: string): CardReport {
  let status: string | null = /\*\*Status:\*\*\s*([A-Z_]+)/.exec(text)?.[1] ?? null
  if (status === null) status = REPORT_STATUSES.find(s => text.includes(s)) ?? null
  const prRaw = /\*\*PR:\*\*\s*#?(\d+)/.exec(text)?.[1]
  let summary = ''
  for (const heading of ['## Concerns', '## Evidence']) {
    const i = text.indexOf(heading)
    if (i < 0) continue
    for (const line of text.slice(i).split('\n').slice(1)) {
      const s = line.trim()
      if (s.startsWith('## ')) break
      if (s.startsWith('- ') && !['', '…', '...'].includes(s.slice(2).trim())) {
        summary = s.slice(2).trim()
        break
      }
    }
    if (summary) break
  }
  if (!summary) summary = text.split('\n').map(l => l.trim()).find(l => l && !l.startsWith('#') && !l.startsWith('**')) ?? ''
  return { status, pr: prRaw === undefined ? null : Number(prRaw), summary: tidy(summary) }
}

// No `\b` after the words: `İ` is no word character to a non-unicode regex.
const PASS_RE = /^\s*(?:GEÇTİ|PASS(?:ED)?|ok)(?=[\s:]|$)/
const FAIL_RE = /^\s*(?:KALDI|FAIL(?:ED)?|not ok)(?=[\s:]|$)/

/** A run's output: suites (`=== name`), checks passed and failed, the last lines. */
export function runProgress(text: string, tailLines = 8): { suites: number; pass: number; fail: number; tail: string[] } {
  let suites = 0
  let pass = 0
  let fail = 0
  const lines = text.split('\n')
  for (const line of lines) {
    if (/^===\s+\S/.test(line)) suites += 1
    else if (FAIL_RE.test(line)) fail += 1
    else if (PASS_RE.test(line)) pass += 1
  }
  const tail = lines.map(l => l.replace(/\s+$/, '')).filter(l => l !== '').slice(-tailLines)
  return { suites, pass, fail, tail }
}

/** .delix/test-result.txt → counts and the last lines. */
export function parseTestResult(text: string): TestResult {
  const { pass, fail, tail } = runProgress(text, 12)
  return { pass, fail, tail }
}

export type MetricRow = { costUsd: number | null; rounds: number | null; durationMin: number | null }

/** metrics.md tables whose first cell names a card: cost, rounds and wall time, by column header. */
export function parseMetrics(text: string): Record<string, MetricRow> {
  const out: Record<string, MetricRow> = {}
  let head: string[] = []
  const cells = (l: string) => l.trim().replace(/^\||\|$/g, '').split('|').map(x => x.trim())
  for (const line of text.split('\n')) {
    if (!line.trim().startsWith('|')) {
      head = []
      continue
    }
    const row = cells(line)
    if (row.every(c => /^:?-{2,}:?$/.test(c))) continue
    if (head.length === 0) {
      head = row.map(c => c.toLowerCase())
      continue
    }
    const id = /\b(T\d{3})\b/.exec(row[0] ?? '')?.[1]
    if (id === undefined) continue
    const col = (re: RegExp) => {
      const i = head.findIndex(h => re.test(h))
      return i >= 0 ? (row[i] ?? '') : ''
    }
    const costCell = col(/maliyet|cost|usd/)
    const roundCell = col(/^tur|round/)
    const timeCell = col(/süre|duration|time/)
    const cost = /orkestratörde|ölçülmedi|not measured/.test(costCell) ? null : firstNumber(costCell)
    const rounds = firstNumber(roundCell)
    const prev = out[id]
    out[id] = {
      costUsd: prev?.costUsd ?? cost,
      rounds: prev?.rounds ?? (rounds === null ? null : Math.round(rounds)),
      durationMin: prev?.durationMin ?? minutes(timeCell),
    }
  }
  return out
}

/** `git worktree list --porcelain` → path and branch per worktree. */
export function parseWorktrees(text: string): { path: string; branch: string }[] {
  const out: { path: string; branch: string }[] = []
  let path: string | null = null
  let branch = ''
  for (const line of [...text.split('\n'), '']) {
    if (line.startsWith('worktree ')) {
      path = line.slice('worktree '.length)
      branch = ''
    } else if (line.startsWith('branch ')) {
      branch = line.slice('branch '.length).replace('refs/heads/', '')
    } else if (line === '' && path !== null) {
      out.push({ path, branch })
      path = null
    }
  }
  return out
}

/** K254/K255: a card with an `agents` ledger follows Spec C REQ-3 (its R8 reasons); one without follows board.py's rule. */
export function gatesOf(card: { tier: number | null; status: string; pr: string | null; isMerged: boolean; reasons: string[] | null }, reportStatus: string | null): string[] {
  const gates: string[] = []
  const isOpen = OPEN_STATUSES.includes(card.status)
  if (card.reasons !== null) {
    if (card.reasons.includes('tier 3 approval')) gates.push('lock')
    if (card.reasons.includes('ready to merge')) gates.push('merge')
    if (card.status === 'escalated') gates.push('escalated')
    for (const r of ['needs_context', 'blocked']) if (card.reasons.includes(r)) gates.push(r)
    return gates
  }
  if (card.tier === 3 && isOpen) gates.push('lock')
  if (card.status === 'in_review' && card.pr !== null && !card.isMerged) gates.push('merge')
  if (card.status === 'escalated') gates.push('escalated')
  if ((reportStatus === 'NEEDS_CONTEXT' || reportStatus === 'BLOCKED') && isOpen) gates.push(reportStatus.toLowerCase())
  return gates
}

/** The decision points a card passes through (derived): card approval, 🔐 at Tier 3, merge. */
export const gateCount = (tier: number | null) => 1 + (tier === 3 ? 1 : 0) + 1

/** What git and the files say about one worktree (Spec C §4); a missing key counts as null or empty. */
export type RawWorktree = {
  status?: string | null
  state_diff_exit?: number | null
  state_log_ct?: number | null
  state_mtime?: number | null
  files?: Record<string, string> | null
}

/** derive's input, rule R1: the §4 git outputs and the files, the same for board.py and the panel. */
export type Raw = {
  default_branch?: string | null
  now?: number | null
  self?: string | null
  source?: string | null
  common_dir?: string | null
  fetch_head_mtimes?: Record<string, number> | null
  worktree_list?: string | null
  for_each_ref?: string | null
  worktrees?: Record<string, RawWorktree> | null
}

export type Derived = {
  agents: AgentRow[]
  leads: LeadRow[]
  queue: { waiting: WaitEntry[]; ready: ReadyEntry[]; done: DoneEntry[] }
  actions: Action[]
  fetched_at: number | 'never fetched'
}

const STATE_PATH = 'docs/delix/STATE.json'
const WEEK = 604800
const LOCK = '\u{1F510}'
const BRANCH_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*(\/[A-Za-z0-9][A-Za-z0-9._-]*)*$/
const PATH_RE = /^\/[A-Za-z0-9_./-]+$/
const SHA_RE = /^[0-9a-f]{40}$/
const ROLE_ORDER = ['lead', 'implementer', 'other']
const KIND_ORDER = ['push', 'merge', 'remove_worktree', 'delete_branch']
const UNSAFE = 'unsafe name: run by hand'

const isInt = (v: unknown): v is number => typeof v === 'number' && Number.isInteger(v)
const textOf = (v: unknown): string | null => (typeof v === 'string' ? v : null)
const filled = (v: unknown): string | null => (typeof v === 'string' && v !== '' ? v : null)
/** Plain code-point order, as Python sorts strings (never localeCompare). */
const byCode = (a: string, b: string) => (a < b ? -1 : a > b ? 1 : 0)
const emptyDerived = (): Derived => ({ agents: [], leads: [], queue: { waiting: [], ready: [], done: [] }, actions: [], fetched_at: 'never fetched' })

type Tree = { path: string; head: string; branch: string | null; main: boolean }
type Ref = { object: string; upstream: string; track: string; time: number | null }
type Queue = Derived['queue'] & { reasons: Map<string, string[]> }

/** R2: `git worktree list --porcelain`, blocks split by an empty line; the first block is the main checkout. */
function rawTrees(text: string): Tree[] {
  const out: Tree[] = []
  let block: { path: string | null; head: string; branch: string | null } = { path: null, head: '', branch: null }
  for (const line of [...text.split('\n'), '']) {
    if (line === '') {
      if (block.path !== null) out.push({ path: block.path, head: block.head, branch: block.branch, main: out.length === 0 })
      block = { path: null, head: '', branch: null }
    } else if (line.startsWith('worktree ')) {
      block.path = line.slice('worktree '.length)
    } else if (line.startsWith('HEAD ')) {
      block.head = line.slice('HEAD '.length)
    } else if (line.startsWith('branch ')) {
      const b = line.slice('branch '.length)
      block.branch = b.startsWith('refs/heads/') ? b.slice('refs/heads/'.length) : b
    } else if (line === 'detached') {
      block.branch = null
    }
  }
  return out
}

/** R2: `git for-each-ref` lines with exactly five TAB fields. */
function rawRefs(text: string): Map<string, Ref> {
  const refs = new Map<string, Ref>()
  for (const line of text.split('\n')) {
    const f = line.split('\t')
    if (f.length !== 5) continue
    const [name, object, upstream, track, time] = f as [string, string, string, string, string]
    refs.set(name, { object, upstream, track, time: /^\d+$/.test(time) ? Number(time) : null })
  }
  return refs
}

/** Spec C derive(raw), rules R1–R12: pure, reads no `$`, never throws. The same rules as board.py's derive (K252). */
export function derive(raw: Raw): Derived {
  try {
    return deriveUnsafe(raw)
  } catch {
    return emptyDerived()
  }
}

function deriveUnsafe(raw: Raw): Derived {
  const def = textOf(raw.default_branch) ?? ''
  const now = isInt(raw.now) ? raw.now : null
  const self = textOf(raw.self)
  const sourcePath = textOf(raw.source)
  const facts = isObject(raw.worktrees) ? (raw.worktrees as Record<string, unknown>) : {}
  const trees = rawTrees(textOf(raw.worktree_list) ?? '')
  const refs = rawRefs(textOf(raw.for_each_ref) ?? '')

  const factsOf = (path: string): Json => {
    const f = facts[path]
    return isObject(f) ? f : {}
  }
  const filesOf = (path: string): Json => {
    const f = factsOf(path).files
    return isObject(f) ? f : {}
  }
  const fileOf = (path: string, rel: string): string | null => textOf(filesOf(path)[rel])
  const statusLines = (path: string): string[] | null => {
    const s = textOf(factsOf(path).status)
    return s === null ? null : s.split('\n').filter(l => l !== '')
  }
  const stateDirty = (path: string) => (statusLines(path) ?? []).some(l => l.slice(3) === STATE_PATH)
  const stateOf = (path: string | null): Json | null => {
    const text = path === null ? null : fileOf(path, STATE_PATH)
    if (text === null) return null
    try {
      const parsed: unknown = JSON.parse(text)
      return isObject(parsed) ? parsed : null
    } catch {
      return null
    }
  }
  const cardsOf = (state: Json | null): Json => (state !== null && isObject(state.cards) ? state.cards : {})
  const records = (card: Json): Json[] => (Array.isArray(card.agents) ? card.agents.filter(isObject) : [])

  // R3
  const refOf = (branch: string) => refs.get(`refs/heads/${branch}`)
  const hasUpstream = (t: Tree) => t.branch !== null && (refOf(t.branch)?.upstream ?? '') !== ''
  const upstreamText = (t: Tree): string => {
    if (t.branch === null) return `detached ${t.head.slice(0, 7)}`
    const ref = refOf(t.branch)
    if (ref === undefined) return '?'
    if (ref.upstream === '') return 'no upstream'
    if (ref.track === '') return 'in sync'
    if (ref.track === 'gone') return 'gone'
    const both = /^ahead (\d+), behind (\d+)$/.exec(ref.track)
    if (both) return `${both[1]} ahead, ${both[2]} behind`
    const one = /^(ahead|behind) (\d+)$/.exec(ref.track)
    if (one) return `${one[2]} ${one[1]}`
    return '?'
  }
  const shortUpstream = (t: Tree) => (refOf(t.branch ?? '')?.upstream ?? '').replace(/^refs\/remotes\//, '')
  const branchTime = (t: Tree) => (t.branch === null ? null : (refOf(t.branch)?.time ?? null))

  // R4, R5
  const sourceState = stateOf(sourcePath)
  const sourceCards = cardsOf(sourceState)
  const byValues = new Set<string>()
  for (const c of Object.values(sourceCards)) if (isObject(c)) for (const r of records(c)) if (typeof r.by === 'string') byValues.add(r.by)
  const cardOf = (path: string) => {
    const m = /T\d{3}/.exec(fileOf(path, '.delix/card') ?? '')
    return m ? m[0] : null
  }
  const roleOf = (t: Tree): string => {
    const card = cardOf(t.path)
    if (card !== null) return `implementer ${card}`
    const f = factsOf(t.path)
    if (stateDirty(t.path) || f.state_diff_exit === 1 || (t.branch !== null && byValues.has(t.branch))) return 'lead'
    return 'other'
  }
  const cardTree = new Map<string, Tree>()
  for (const t of trees) {
    const card = cardOf(t.path)
    if (card !== null && !cardTree.has(card)) cardTree.set(card, t)
  }

  // R7
  const prOf = (id: string, card: Json): number | null => {
    const v = card.pr
    if (isInt(v) && v > 0) return v
    if (typeof v === 'string' && /^#?[0-9]+$/.test(v)) return Number(v.replace('#', ''))
    const t = cardTree.get(id)
    const m = t ? /\*\*PR:\*\* #(\d+)/.exec(fileOf(t.path, '.delix/report.md') ?? '') : null
    return m ? Number(m[1]) : null
  }
  const reportStatus = (id: string) => {
    const t = cardTree.get(id)
    return t ? (/\*\*Status:\*\*\s*([A-Z_]+)/.exec(fileOf(t.path, '.delix/report.md') ?? '')?.[1] ?? null) : null
  }
  const lastOf = (list: Json[], role: string) => list.filter(r => r.role === role).at(-1) ?? null
  const branchOf = (id: string, card: Json): string | null => {
    const b = lastOf(records(card), 'implementer')?.branch
    if (typeof b === 'string') return b
    return cardTree.get(id)?.branch ?? null
  }
  const tierOf = (card: Json) => (isInt(card.tier) ? card.tier : 2)
  const lastRound = (card: Json) => {
    const rounds = records(card).filter(r => (r.role === 'qa' || r.role === 'security') && isInt(r.round)).map(r => r.round as number)
    return rounds.length === 0 ? null : Math.max(...rounds)
  }

  // R8
  const queueOf = (state: Json | null, statePath: string | null): Queue => {
    const cards = cardsOf(state)
    const q: Queue = { waiting: [], ready: [], done: [], reasons: new Map() }
    for (const id of Object.keys(cards).sort(byCode)) {
      const card = cards[id]
      if (!isObject(card)) continue
      const status = textOf(card.status)
      const pr = prOf(id, card)
      const tier = tierOf(card)
      const list = records(card)
      const r = lastRound(card)
      const qa = r === null ? null : (list.filter(x => x.role === 'qa' && x.round === r).at(-1) ?? null)
      const sec = r === null ? null : (list.filter(x => x.role === 'security' && x.round === r).at(-1) ?? null)
      const branch = branchOf(id, card)
      const tip = branch === null ? null : (refs.get(`refs/remotes/origin/${branch}`)?.object ?? null)
      const qaSha = qa === null ? null : textOf(qa.sha)
      const isReviewed =
        status === 'in_review' &&
        pr !== null &&
        qa !== null &&
        (qa.verdict === 'ACCEPT' || qa.verdict === 'ACCEPT_WITH_NOTES') &&
        (tier < 2 || (sec !== null && (sec.verdict === 'CLEAN' || sec.verdict === `${LOCK} HUMAN_APPROVAL`)))
      const isReady = isReviewed && tip === qaSha
      const reasons: string[] = []
      if (isReady) reasons.push('ready to merge')
      if (status === 'open' && tier === 3) {
        const file = textOf(card.file)
        const text = file === null || statePath === null ? null : fileOf(statePath, file)
        if (text === null || !text.split('\n').some(l => l.startsWith(`**${LOCK} Approved:**`))) reasons.push('tier 3 approval')
      }
      const report = reportStatus(id)
      if ((report === 'NEEDS_CONTEXT' || report === 'BLOCKED') && status !== null && OPEN_STATUSES.includes(status)) reasons.push(report.toLowerCase())
      if (status === 'escalated') reasons.push('escalated')
      if (isReviewed && !isReady) reasons.push('changed after review')
      if (status === 'in_review' && pr !== null && (!Array.isArray(card.agents) || card.agents.length === 0)) reasons.push('no review record')
      for (const reason of reasons) q.waiting.push({ card: id, verification: null, reason })
      if (reasons.length > 0) q.reasons.set(id, reasons)
      if (isReady && pr !== null) q.ready.push({ card: id, pr, sha: qaSha })
      if (status === 'accepted') q.done.push({ card: id, pr })
    }
    const verifications = state !== null && Array.isArray(state.verifications) ? state.verifications.filter(isObject) : []
    for (const v of verifications) {
      if (typeof v.verdict === 'string' && v.verdict.startsWith('FIX') && filled(v.resolution) === null) {
        q.waiting.push({ card: null, verification: textOf(v.name), reason: 'verification FIX' })
      }
    }
    return q
  }

  // R6
  const roundLine = (r: Json) =>
    `${textOf(r.role) ?? '-'} r${String(r.round)} @${filled(r.sha)?.slice(0, 7) ?? '-'} ${filled(r.verdict) ?? '-'} · by ${filled(r.by) ?? '-'}`
  const agents: AgentRow[] = trees.map(t => {
    const role = roleOf(t)
    const card = cardOf(t.path)
    const lines = statusLines(t.path)
    const source = card === null ? null : sourceCards[card]
    const sourceCard = isObject(source) ? source : null
    const pr = card === null ? null : prOf(card, sourceCard ?? {})
    const r = sourceCard === null ? null : lastRound(sourceCard)
    return {
      path: t.path,
      branch: t.branch,
      main: t.main,
      role,
      card,
      upstream: upstreamText(t),
      uncommitted: lines === null ? '?' : lines.length,
      lands: pr !== null ? `PR #${pr} → ${def}` : hasUpstream(t) ? `pushed: ${shortUpstream(t)}` : 'local only',
      opened_by: sourceCard === null ? null : textOf(lastOf(records(sourceCard), 'implementer')?.by),
      last_round:
        sourceCard === null || r === null
          ? []
          : records(sourceCard)
              .filter(x => (x.role === 'qa' || x.role === 'security') && x.round === r)
              .map(roundLine),
    }
  })
  const rank = (role: string) => ROLE_ORDER.indexOf(role.split(' ')[0] ?? '')
  agents.sort((a, b) => rank(a.role) - rank(b.role) || byCode(a.path, b.path))

  // R9
  const changedAt = (path: string): number | null => {
    const f = factsOf(path)
    const v = stateDirty(path) ? f.state_mtime : f.state_log_ct
    return isInt(v) ? v : null
  }
  const lastActivity = (t: Tree, isLead: boolean): number | null => {
    const known = [branchTime(t), isLead ? changedAt(t.path) : null].filter((v): v is number => v !== null)
    return known.length === 0 ? null : Math.max(...known)
  }
  const isOld = (last: number | null) => last !== null && now !== null && now - last > WEEK
  const leadTrees = [...trees.filter(t => t.main), ...trees.filter(t => !t.main && roleOf(t) === 'lead').sort((a, b) => byCode(a.path, b.path))]
  const leads: LeadRow[] = leadTrees.map(t => {
    const state = stateOf(t.path)
    const q = queueOf(state, t.path)
    const cards = cardsOf(state)
    const spec = state === null ? null : textOf(state.spec)
    const specText = spec === null ? null : fileOf(t.path, spec)
    const heading = specText?.split('\n').find(l => l.startsWith('# ')) ?? null
    return {
      path: t.path,
      branch: t.branch,
      main: t.main,
      source: t.path === sourcePath,
      spec_title: heading === null ? null : heading.slice(2).replace(/\s+$/, ''),
      open: Object.values(cards).filter(c => isObject(c) && typeof c.status === 'string' && OPEN_STATUSES.includes(c.status)).length,
      waiting: q.reasons.size,
      ready: q.ready.length,
      changed_at: changedAt(t.path),
      stale: !t.main && isOld(lastActivity(t, true)),
    }
  })

  // R10
  const queue = queueOf(sourceState, sourcePath)
  const actions: Action[] = []
  const guarded = (kind: Action['kind'], target: string, card: string | null, isSafe: boolean, command: string, uncommitted: number | '?' = 0) => {
    if (uncommitted !== 0) actions.push({ kind, target, card, command: null, note: `uncommitted ${uncommitted} files: commit or discard in its session` })
    else if (!isSafe) actions.push({ kind, target, card, command: null, note: UNSAFE })
    else actions.push({ kind, target, card, command, note: '' })
  }
  for (const t of trees) {
    if (t.main || t.path === self) continue
    const row = agents.find(a => a.path === t.path)
    const uncommitted = row?.uncommitted ?? '?'
    const card = cardOf(t.path)
    const up = upstreamText(t)
    if (t.branch !== null && t.branch !== def && up !== 'gone' && up !== '?' && (up === 'no upstream' || up.includes('ahead'))) {
      guarded('push', t.path, card, PATH_RE.test(t.path) && BRANCH_RE.test(t.branch), `git -C ${t.path} push -u origin ${t.branch}`, uncommitted)
    }
    const source = card === null ? null : sourceCards[card]
    const isMergedCard = isObject(source) && source.status === 'accepted' && isObject(source.merged)
    const isIdle = isOld(lastActivity(t, row?.role === 'lead')) && hasUpstream(t) && (up === 'in sync' || /^\d+ behind$/.test(up))
    if (isMergedCard || isIdle) guarded('remove_worktree', t.path, card, PATH_RE.test(t.path), `git worktree remove ${t.path}`, uncommitted)
  }
  for (const r of queue.ready) {
    guarded('merge', `#${r.pr}`, r.card, r.pr > 0 && SHA_RE.test(r.sha ?? ''), `gh pr merge ${r.pr} --squash --match-head-commit ${r.sha}`)
  }
  const checkedOut = new Set(trees.map(t => t.branch).filter((b): b is string => b !== null))
  for (const id of Object.keys(sourceCards).sort(byCode)) {
    const card = sourceCards[id]
    if (!isObject(card) || !isObject(card.merged)) continue
    const branch = branchOf(id, card)
    if (branch === null || checkedOut.has(branch)) continue
    const ref = refOf(branch)
    if (ref === undefined || ref.object !== card.merged.head) continue
    guarded('delete_branch', branch, id, BRANCH_RE.test(branch), `git branch -D ${branch}`)
  }
  actions.sort((a, b) => byCode(a.card ?? a.target, b.card ?? b.target) || KIND_ORDER.indexOf(a.kind) - KIND_ORDER.indexOf(b.kind))

  // R11, R12
  const fetched = Object.values(isObject(raw.fetch_head_mtimes) ? raw.fetch_head_mtimes : {}).filter(isInt)
  return {
    agents,
    leads,
    queue: { waiting: queue.waiting, ready: queue.ready, done: queue.done },
    actions,
    fetched_at: fetched.length === 0 ? 'never fetched' : Math.max(...fetched),
  }
}

/** The path a background Bash call writes its output to, from the text the model read. */
export function backgroundOutputPath(text: string): string | null {
  const m = /(?:written to|Output(?: is being written)?(?: to)?)[:\s]+(\/\S+?)[.,;]?(?:\s|$)/i.exec(text) ?? /(\/\S+\.output)\b/.exec(text)
  return m?.[1] ?? null
}

/** Whether a task notification names this task, and how it ended. */
export function notificationStatus(text: string, taskId: string): string | null {
  if (!text.includes(taskId)) return null
  const tagged = /<status>\s*([a-z_]+)\s*<\/status>/i.exec(text)?.[1]
  if (tagged) return tagged.toLowerCase()
  return /\b(completed|failed|killed)\b/i.exec(text)?.[1]?.toLowerCase() ?? null
}

export const DEFAULT_PATTERNS: { label: string; re: RegExp }[] = [
  { label: 'run_all.sh', re: /\brun_all\.sh\b/ },
  { label: 'upgrade_restore_drill', re: /\bupgrade_restore_drill\b/ },
  { label: 'install_trial', re: /\binstall_trial\b/ },
  { label: 'release.sh', re: /\brelease\.sh\b/ },
  { label: 'build.sh', re: /\bbuild\.sh\b/ },
  { label: 'gh run watch', re: /\bgh\s+run\s+watch\b/ },
  { label: 'gh pr checks', re: /\bgh\s+pr\s+checks\b.*--watch\b/ },
  { label: 'docker build', re: /\bdocker\s+(?:compose\s+|buildx\s+)?build\b/ },
]

/** The label of the first pattern a command matches, built-ins first. */
export function matchCommand(command: string, extra: readonly string[]): string | null {
  for (const p of DEFAULT_PATTERNS) if (p.re.test(command)) return p.label
  for (const source of extra) {
    try {
      const m = new RegExp(source).exec(command)
      if (m) return m[0].slice(0, 32)
    } catch {
      // a pattern that does not compile is skipped
    }
  }
  return null
}

export const formatDuration = (ms: number) => {
  const s = Math.max(0, Math.round(ms / 1000))
  const m = Math.floor(s / 60)
  return m >= 60 ? `${Math.floor(m / 60)} sa ${m % 60} dk` : m > 0 ? `${m} dk ${s % 60} sn` : `${s} sn`
}

export const clock = (ms: number) => {
  const s = Math.max(0, Math.floor(ms / 1000))
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`
}

export const usd = (n: number | null) => (n === null ? 'ölçülmedi' : `$${n.toFixed(2)}`)

/** Data text as drawn: the lock emoji the records use becomes the board's own single-width lock, other emoji go (a double-width glyph shifts a terminal row). */
export const plain = (s: string) => s.replace(/\u{1F510}\uFE0F?/gu, '◈').replace(/\p{Extended_Pictographic}\uFE0F?/gu, '').replace(/ {2,}/g, ' ')

export const cut = (raw: string, n: number) => {
  const s = plain(raw)
  return n <= 1 ? '' : s.length > n ? s.slice(0, n - 1) + '…' : s
}
