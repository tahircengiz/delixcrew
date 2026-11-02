// Pure parsers for delix's files: no I/O, so the tests reach them directly.
// Rules follow delix's scripts/board.py where it has one.

import type { CardFile, CardReport, Finding, ReviewRound, TestResult, Verification, Wave } from '../types'

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

/** A task card: title, its top table row, the Files list and the review rounds the orchestrator wrote. */
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

/** The pending gates of a card, board.py's rules; a PR recorded as `merge <sha>` is merged already. */
export function gatesOf(card: { tier: number | null; status: string; pr: string | null; isMerged: boolean }, reportStatus: string | null): string[] {
  const gates: string[] = []
  const isOpen = OPEN_STATUSES.includes(card.status)
  if (card.tier === 3 && isOpen) gates.push('lock')
  if (card.status === 'accepted' && card.pr !== null && !card.isMerged) gates.push('merge')
  if (card.status === 'escalated') gates.push('escalated')
  if ((reportStatus === 'NEEDS_CONTEXT' || reportStatus === 'BLOCKED') && isOpen) gates.push(reportStatus.toLowerCase())
  return gates
}

/** The decision points a card passes through (derived): card approval, 🔐 at Tier 3, merge. */
export const gateCount = (tier: number | null) => 1 + (tier === 3 ? 1 : 0) + 1

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
