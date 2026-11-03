// A small delix project shaped like the pilot's (object waves, merged and open
// cards, a Tier 3 card, a verification), with made-up names and numbers.

export const ROOT = '/p'

const STATE = {
  spec: 'docs/delix/SPEC.md',
  size: 'M',
  tier: 3,
  updated: '2026-11-02T21:50:00+03:00',
  previous: 'docs/delix/arsiv/E1-STATE.json',
  env_owner: null,
  waves: [
    { wave: 1, cards: ['T001'], note: 'test-first' },
    { wave: 2, cards: ['T002', 'T003'], note: 'no code dependency; T002 interactive' },
  ],
  cards: {
    T001: { file: 'docs/delix/tasks/T001-tests.md', role: 'backend', tier: 2, status: 'accepted', rounds: 2, pr: 'merge 10d71a9', cost_usd: 5.39, qa: 'ACCEPT', security: 'CLEAN' },
    T002: { file: 'docs/delix/tasks/T002-hardening.md', role: 'devops', tier: 3, status: 'in_review', rounds: 1, pr: null, cost_usd: null, qa: 'ACCEPT', security: '🔐 HUMAN_APPROVAL' },
    T003: { file: 'docs/delix/tasks/T003-page.md', role: 'frontend', tier: 2, status: 'accepted', rounds: 0, pr: '#12', cost_attempts_usd: [0.5, 0.47] },
  },
  verifications: [
    { name: 'b01-csp', date: '2026-11-02', tier: 2, verdict: 'ACCEPT', qa: 'ACCEPT_WITH_NOTES', security: 'CLEAN', cost_usd: 1.38 },
  ],
}

const T002 = `# T002 — Container hardening for the database

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T002 | S | 3 | devops | 2 | in_review |

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: \`compose.yaml\`, only lines 42–54
- Test: \`tests/db_hardening.sh\` (new)

## Steps
1. Red, then green.

## Review findings (filled by the orchestrator)
- Round 1 (838c7f1; qa **ACCEPT**, security **HUMAN_APPROVAL**):
  - **[security, Medium] \`compose.yaml:51\` capability is wider than needed.**
  - P2 (no fix asked): the test result file misses one command.
- Round 2 (f6b9c67): qa ACCEPT, security no findings
`

const T004 = `# T004 — Docs for the new page

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T004 | S | 1 | docs | 3 | open |

## Files
- Modify: \`README.md\`
`

const METRICS = `# Metrics

| Kalem | Maliyet USD | Tur | Süre (duvar) | Not |
|---|---|---|---|---|
| T001 tests (headless) | 5,39 (1,53 + 1,77 + 2,09) | 2 düzeltme turu | 13:22–13:40 | resume |
| T003 page (headless) | 0,97 | 0 | 2,2 dk | green first time |
| **Toplam** | **≈ 6,4** | | | |
`

/** An archived STATE in the old Turkish spelling, naming the card T000. */
const OLD_STATE = { spec: 'docs/ekip/SPEC.md', boy: 'M', kartlar: { T000: { dosya: 'docs/ekip/tasks/T000-otp.md', rol: 'backend', kademe: 3, status: 'kabul', tur: 3, pr: null } } }

export const RUN_ALL = `=== gen_env_test
GEÇTİ  env file is generated
GEÇTİ  secrets are not printed
=== portal_smoke
GEÇTİ  login page answers 200
GEÇTİ  csp header is set
KALDI  admin page answers 200 — 502
=== teamguard_unit
GEÇTİ  team guard refuses a stranger
`

export const FILES: Record<string, string> = {
  [`${ROOT}/docs/delix/STATE.json`]: JSON.stringify(STATE),
  [`${ROOT}/docs/delix/metrics.md`]: METRICS,
  [`${ROOT}/docs/delix/arsiv/E1-STATE.json`]: JSON.stringify(OLD_STATE),
  [`${ROOT}/docs/delix/tasks/T000-otp.md`]: '# T000 — OTP tests\n\n| id | size | tier | role | wave | status |\n|---|---|---|---|---|---|\n| T000 | M | 3 | backend | 1 | open |\n',
  [`${ROOT}/docs/delix/tasks/T001-tests.md`]: '# T001 — Acceptance tests\n',
  [`${ROOT}/docs/delix/tasks/T002-hardening.md`]: T002,
  [`${ROOT}/docs/delix/tasks/T003-page.md`]: '# T003 — Team page\n',
  [`${ROOT}/docs/delix/tasks/T004-docs.md`]: T004,
  '/w/t002/.delix/report.md': '# Report — T002\n\n**Status:** DONE_WITH_CONCERNS\n**PR:** #14\n\n## Concerns\n- the probe ran on a copy\n',
  '/w/t002/.delix/test-result.txt': 'GEÇTİ  red 4/8\nGEÇTİ  green 8/8\n',
}

export const WORKTREES = `worktree ${ROOT}\nHEAD 1\nbranch refs/heads/main\n\nworktree /w/t002\nHEAD 2\nbranch refs/heads/delix-T002\n\n`

// The desktop app's layout: the orchestrator writes STATE in its own session worktree, the main checkout is
// behind on a closed spec, an implementer worktree holds the dispatch-time copy (and may touch `updated`).
export const MAIN = '/m'
export const ORCH = '/m/.claude/worktrees/orch'
export const IMPL = '/m/.claude/worktrees/impl'

const layoutState = (updated: string, cards: Record<string, string>) =>
  JSON.stringify({
    spec: 'docs/delix/SPEC.md',
    updated,
    waves: [{ wave: 1, cards: Object.keys(cards) }],
    cards: Object.fromEntries(Object.entries(cards).map(([id, status]) => [id, { role: 'backend', tier: 2, status, rounds: 0 }])),
  })

export const LAYOUT: Record<string, string> = {
  [`${MAIN}/docs/delix/STATE.json`]: layoutState('2026-11-03T12:45:00Z', { T001: 'accepted' }),
  [`${MAIN}/docs/delix/tasks/T001-old.md`]: '# T001 — Closed spec card\n',
  [`${ORCH}/docs/delix/STATE.json`]: layoutState('2026-11-03T17:45:00Z', { T010: 'in_progress', T011: 'open' }),
  [`${ORCH}/docs/delix/tasks/T010-script.md`]: '# T010 — Triage script\n',
  [`${ORCH}/docs/delix/tasks/T011-hooks.md`]: '# T011 — Triage hooks\n',
  [`${IMPL}/.delix/card`]: 'docs/delix/tasks/T010-script.md\n',
  [`${IMPL}/docs/delix/STATE.json`]: layoutState('2026-11-03T18:00:00Z', { T010: 'in_review' }),
  [`${IMPL}/docs/delix/tasks/T010-script.md`]: '# T010 — Triage script\n',
}

const tree = (path: string, head: number, branch: string) => `worktree ${path}\nHEAD ${head}\nbranch refs/heads/${branch}\n\n`
export const MAIN_TREE = tree(MAIN, 1, 'main')
export const LAYOUT_TREES = MAIN_TREE + tree(ORCH, 2, 'claude/orch') + tree(IMPL, 3, 'claude/impl')

/** The template's list-of-lists waves. */
export const TEMPLATE_STATE = JSON.stringify({ waves: [['T001', 'T002'], ['T003']], cards: { T001: { tier: 2, status: 'open' } } })
