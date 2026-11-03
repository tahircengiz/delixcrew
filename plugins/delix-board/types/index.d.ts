export type Finding = { text: string; severity: string | null }

export type ReviewRound = { title: string; findings: Finding[] }

export type CardFile = { kind: string; path: string }

export type CardReport = { status: string | null; pr: number | null; summary: string }

export type TestResult = { pass: number; fail: number; tail: string[] }

export type Card = {
  id: string
  title: string
  role: string
  tier: number | null
  wave: number | null
  status: string
  /** A card of an earlier spec: its file is here, current STATE does not list it; it holds no gate. */
  isArchived: boolean
  rounds: number | null
  pr: string | null
  isMerged: boolean
  costUsd: number | null
  durationMin: number | null
  gateCount: number
  qa: string | null
  security: string | null
  approved: string | null
  gates: string[]
  files: CardFile[]
  reviewRounds: ReviewRound[]
  worktree: string | null
  branch: string | null
  report: CardReport | null
  test: TestResult | null
}

export type Wave = { wave: number; cards: string[]; note: string }

export type Verification = {
  name: string
  date: string
  tier: number | null
  verdict: string
  qa: string | null
  security: string | null
  costUsd: number | null
}

export type Snapshot = {
  isDelix: boolean
  root: string
  project: string
  /** The worktree whose STATE.json is read, when it is not the main checkout. */
  source: string | null
  spec: string | null
  previous: string | null
  size: string | null
  updated: string | null
  envOwner: string | null
  waves: Wave[]
  cards: Card[]
  verifications: Verification[]
  worktreeCount: number
}

export type RunStatus = 'running' | 'passed' | 'failed' | 'silent'

export type Run = {
  id: string
  kind: 'bash' | 'agent'
  label: string
  command: string
  startedAt: number
  endedAt: number | null
  status: RunStatus
  isBackground: boolean
  taskId: string | null
  agentId: string | null
  outputPath: string | null
  outputSize: number
  lastGrowthAt: number
  suites: number
  pass: number
  fail: number
  tail: string[]
  expectedMs: number | null
  expectedSuites: number | null
  expectedChecks: number | null
}

export type View = 'pano' | 'bekleme' | 'kart' | 'olcum'

declare module 'claude-code' {
  interface PluginState {
    'delix-board': {
      snapshot: Shaped<Snapshot | null>
      runs: Shaped<Run[]>
      view: View
      selected: string | null
      now: number
    }
  }
}
