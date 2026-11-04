# T030 — delix-board: derive() in the panel, Leads/Ajanlar/Seni bekliyor/Merge'e hazır/Git işleri, card ledger, K255 gate fix

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T030 | L | 2 | frontend | 7 | open |

> Tier 2: no protected path is touched (`plugins/delix-board/**` is not in `protected_paths`; the protected pattern `.claude-plugin/**` is anchored at the repo root). It is Tier 2 for new behaviour and a visual change.

**Goal (1 sentence):** The panel gathers the same git facts within 3 + 3N calls per 20-second look, runs a pure `derive(raw)` with rules R (identical to T029), shows five new text sections in Pano and the `agents` ledger in Kart, and fixes the gate rule (K255). · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-1`–`#REQ-6`; §4, §5; K252, K254–K257, K260

**Docs/site:** none in this card (T032).

## Files
- Modify: `plugins/delix-board/hooks/parse.ts` (StateCard lines 41–53; parseState lines 100–112; gatesOf lines 318–327; insert after line 330 `export const gateCount …`)
- Modify: `plugins/delix-board/hooks/data.ts` (Cache line 26; changedAt 65–72; chooseRoot 80–90; worktrees 92–98; emptySnapshot 100–114; readSnapshot 117–218)
- Modify: `plugins/delix-board/hooks/views.tsx` (header: insert after line 64; pano: insert after line 196; kart: insert after line 360)
- Modify: `plugins/delix-board/hooks/register.tsx` (line 17 only)
- Modify: `plugins/delix-board/types/index.d.ts` (new types after line 9; Card insert after line 35; Snapshot insert after line 64)
- Test: `plugins/delix-board/tests/board.test.tsx` (K255: lines 228 and 241 change; insert after line 5; append after line 287)

## Edit anchors (base origin/main ad27168, unchanged at d9ac35b)
1. `register.tsx` line 17: `{ shape: 'snapshot-3' }` → `{ shape: 'snapshot-4' }` (spec §5).
2. `types/index.d.ts`:
   - add `AgentRecord`, `AgentRow`, `LeadRow`, `WaitEntry`, `ReadyEntry`, `DoneEntry`, `Action` (shapes from R6, R8–R10).
   - Card: add `agents: AgentRecord[]`.
   - Snapshot: add `agents: AgentRow[]`, `leads: LeadRow[]`, `queue: { waiting: WaitEntry[]; ready: ReadyEntry[]; done: DoneEntry[] }`, `actions: Action[]`, `fetchedAt: number | 'never fetched'`.
3. `parse.ts`:
   - StateCard gets `agents: AgentRecord[]` (only object records) and `merged: { sha: string; head: string; at: string } | null`. parseState fills both.
   - Export `type Raw` (R1) and `derive(raw: Raw)` (R1–R12) after line 330.
   - Replace `gatesOf` (318–327) with:
```ts
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
```
   - `reasons` is null when the card has no non-empty `agents` list; otherwise it is the card's R8 reasons in the source STATE.
4. `data.ts` (I/O), in the 20-second part (`worktrees`):
   - `$.process.run(argv, { cwd, timeoutMs: 5000 })` with the worktree as `cwd`, never `-C` (the existing test mock keys on `init.cwd`).
   - argv:
     - `['git','rev-parse','--git-common-dir']` (cwd top; first output line; relative → joined to top)
     - `['git','worktree','list','--porcelain']`
     - `['git','for-each-ref','refs/heads','refs/remotes','--format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)']`
     - per worktree `['git','status','--porcelain']`
     - per card-less worktree with a clean STATE `['git','diff','--quiet','origin/<default>...HEAD','--','docs/delix/STATE.json']`
     - per card-less worktree whose STATE exists and is clean `['git','log','-1','--format=%ct','--','docs/delix/STATE.json']`
   - `chooseRoot` and `changedAt` use these results and make no calls of their own. A dirty STATE's time is `$.fs.stat` mtimeMs.
   - Budget ≤ 3 + 3N per look (K257).
   - FETCH_HEAD: stat `<common>/FETCH_HEAD`, `$.fs.list(<common>/worktrees)`, then stat `<name>/FETCH_HEAD`; seconds = floor(mtimeMs / 1000).
   - `now` = floor(`$.clock.now()` / 1000); `self` = top; `source` = the chooseRoot result; `files` as in T029 rules G, through `readIfChanged`.
   - `readSnapshot` (every 4 s) runs `derive` on the cached git part plus the current files, fills the new Snapshot fields, `card.agents`, and `gates` (with `reasons`). `emptySnapshot` returns empty values and `fetchedAt: 'never fetched'`.
5. `views.tsx`. Existing exports only (`ACCENT`, `WARN`, `MERGE`, `GOOD`, `BAD`, `MUTED`, theme keys, the existing `IconName` set); no new colour or component.
   - Header, after line 64: `<Text dimColor size="caption">` `son fetch: YYYY-MM-DD HH:MM UTC` or `fetch yok`.
   - Pano, after line 196: five blocks with `<Text weight="semibold">` headings `Leads`, `Ajanlar`, `Seni bekliyor`, `Merge'e hazır`, `Git işleri`. Rows:

     | Block | Row text | Empty text |
     |---|---|---|
     | Leads | `<ana checkout or basename(path)>[ (kaynak)] · <branch or -> · <spec_title or -> · açık n · bekleyen n · hazır n[ · stale]` | — |
     | Ajanlar | `<role> · <basename(path)> · <branch or detached> · <upstream> · <lands>[ · commit'lenmemiş n]` | — |
     | Seni bekliyor | `<card> · <reason>` or `<name> (doğrulama) · <reason>` | `Bekleyen yok.` |
     | Merge'e hazır | `<card> · PR #n · @<sha7>` | `Hazır kart yok.` |
     | Git işleri | a caption `<kind> · <target>`, then `<Text mono>` with the full command (no `cut()`), or `<Text>` with the note | `Bekleyen git işi yok.` |

     Under the Git işleri block, the caption `Komutları sen çalıştırırsın; panel çalıştırmaz.`
   - Kart, after line 360: heading `Kayıt` (icon `users`). Rows:
     - implementer: `implementer · by <by> · <branch or -> · <session or ->`
     - others: `<role> r<round> @<sha7 or -> <verdict or -> · by <by>`
     - none: `Kayıt yok.`
6. `tests/board.test.tsx` (K255; these are the only changed lines):
   - line 228 `    expect((await band.find({ type: 'Text', text: /kapı bekliyor/ }))?.text).toMatch(/2 kapı bekliyor/)` → `…toMatch(/1 kapı bekliyor/)`
   - line 241 `  expect((await band.find({ type: 'Text', text: /kapı bekliyor/ }))?.text).toMatch(/2 kapı bekliyor/)` → `…toMatch(/1 kapı bekliyor/)`
   - Why: T003 (`accepted`, `pr: '#12'`, fixtures.ts line 20) loses its merge gate. T002 (`in_review`, PR #14 from its report, fixtures.ts lines 19 and 89) keeps lock and merge, so line 105 `/^ ?merge$/` still passes.
   - `fixtures.ts`: no line changes.
   - Insert after line 5: `import { derive, type Raw } from '../hooks/parse'` and `import { PARITY } from './board_parity'`.

## Rules R: derive(raw), pure (identical to T029)
- **R1 Input.** `raw` has `default_branch`, `now` (s), `self`, `source`, `common_dir`, `fetch_head_mtimes` {path: s}, `worktree_list`, `for_each_ref`, and `worktrees` {path: {`status` str|null, `state_diff_exit` 0|1|null, `state_log_ct` int|null, `state_mtime` int|null, `files` {relpath: text}}}. A missing key counts as null or empty. `derive` never throws.
- **R2 Parse.**
  - `worktree_list`: blocks split by an empty line. Read `worktree <path>`, `HEAD <sha>`, and either `branch refs/heads/<b>` (strip that prefix once) or `detached`; ignore other lines. The first block is the main checkout.
  - `for_each_ref`: only lines with exactly 5 TAB fields (refname, objectname, upstream, track, committer time); skip others.
  - A STATE is the JSON of `files["docs/delix/STATE.json"]`; invalid or missing means no cards and no verifications.
- **R3 Upstream text** of a checked-out branch b, from line `refs/heads/b`:

  | Input | Text |
  |---|---|
  | no line | `?` |
  | upstream field empty | `no upstream` |
  | track `""` | `in sync` |
  | `ahead N` | `N ahead` |
  | `behind N` | `N behind` |
  | `ahead N, behind M` | `N ahead, M behind` |
  | `gone` | `gone` |
  | detached | `detached <HEAD[:7]>` |

  The short upstream is the upstream without a leading `refs/remotes/`.
- **R4 Source.** The source STATE is the STATE of `raw.source`. byValues = every `by` of every `agents` record in it.
- **R5 Role.**
  - `files[".delix/card"]` contains `T\d{3}` → `implementer T<nnn>`, card `T<nnn>`.
  - Else `lead` if any of: (a) a `status` line whose text from index 3 equals `docs/delix/STATE.json`; (b) `state_diff_exit == 1`; (c) the branch is in byValues.
  - Else `other`.
- **R6 Agent row** `{path, branch, main, role, card, upstream, uncommitted, lands, opened_by, last_round}`:
  - `branch`: null when detached. `main`: true for the first block.
  - `uncommitted`: count of non-empty status lines; `"?"` when status is null.
  - `lands`: an implementer whose card has a PR (R7) → `PR #<n> → <default_branch>`; else, if an upstream is configured → `pushed: <short upstream>`; else `local only`.
  - `opened_by`: the `by` of the card's last `implementer` record in the source STATE, else null.
  - `last_round`: for an implementer card in the source STATE, let R = the max `round` of its `qa`/`security` records. Each such record with round R, in list order, becomes `<role> r<round> @<sha[:7] or -> <verdict or -> · by <by>`. Otherwise `[]`.
  - Order: lead, then implementer, then other; then by path, using plain code-point comparison (`a < b`, never `localeCompare`).
- **R7 Card facts in a STATE S.**
  - `pr`: a positive int, or a string matching `^#?[0-9]+$` → int; else null (`merge <sha>` → null). For an implementer worktree's card whose `pr` is null, use the report's `**PR:** #(\d+)`.
  - Report status: `\*\*Status:\*\*\s*([A-Z_]+)` in `.delix/report.md` of the worktree whose card it is.
  - Branch: `branch` of the last `implementer` record if not null, else that worktree's branch.
  - Remote tip: objectname of `refs/remotes/origin/<branch>` (no line → null).
  - Tier: the int value; a non-int counts as 2.
- **R8 Queue of S.** R = max round over `qa`/`security` records; qa = the last `qa` record with round R; sec = the last `security` record with round R.
  - **Ready:** status `in_review`, an int pr, qa verdict `ACCEPT` or `ACCEPT_WITH_NOTES`, (tier < 2, or sec verdict `CLEAN` or `🔐 HUMAN_APPROVAL`), and remote tip == qa sha → `{card, pr, sha: <qa sha>}`.
  - **Waiting** reasons, in this order:
    1. `ready to merge`
    2. `tier 3 approval`: status `open`, tier 3, and the card's `file` (in S's worktree `files`) is missing or has no line starting with `**🔐 Approved:**`
    3. `needs_context` / `blocked`: report status NEEDS_CONTEXT / BLOCKED, and status in open, in_progress, in_review or fixing
    4. `escalated`
    5. `changed after review`: every ready condition holds except tip == sha
    6. `no review record`: status `in_review`, an int pr, and `agents` missing or empty

    Each gives `{card, verification: null, reason}`. Then every verification whose verdict starts with `FIX` and has no non-empty `resolution` gives `{card: null, verification: <name>, reason: "verification FIX"}`.
  - **Done:** status `accepted` → `{card, pr}`.
  - Order: lists by card id (code point); a card's reasons in the order above; verifications last, in STATE order.
- **R9 Leads.** The main checkout first, then every other `lead` row by path. Row: `{path, branch, main, source, spec_title, open, waiting, ready, changed_at, stale}`.
  - `source`: path == `raw.source`.
  - `spec_title`: the first line of `files[<STATE.spec>]` that starts with `# `, minus `# ` and trailing spaces; else null.
  - `open`: cards with status open, in_progress, in_review or fixing.
  - `waiting`: distinct card ids with a card reason (R8) in that STATE.
  - `ready`: count of ready cards.
  - `changed_at`: `state_mtime` if R5a holds, else `state_log_ct`; null if missing.
  - Last activity = the max of the known values among the branch committer time and `changed_at`. `stale` = not main, last activity known, and now − last activity > 604800.
- **R10 Actions.** Consider every worktree except the main checkout and `raw.self`.
  - **Push candidate:** branch not null and ≠ default_branch; upstream text not `gone` or `?`; and the text is `no upstream` or contains `ahead`. Command `git -C <path> push -u origin <branch>`, target = path.
  - **Remove candidate:** either the card is in the source STATE with status `accepted` and `merged` as an object; or the last activity is known and now − it > 604800, an upstream is configured, and the text is `in sync` or `N behind`. Last activity is R9's (branch time and `changed_at`) for leads, and only the branch committer time for other worktrees. Command `git worktree remove <path>`, target = path.
  - For each candidate, in this order: uncommitted ≠ 0 (or `?`) → command null, note `uncommitted <n> files: commit or discard in its session`; a name fails its pattern → command null, note `unsafe name: run by hand`; else note `""`.
  - **Merge:** each ready card of the source STATE → `gh pr merge <pr> --squash --match-head-commit <sha>`, target `#<pr>`.
  - **Delete:** each source card with a `merged` object whose branch (R7, implementer record) meets all of: a `refs/heads/<branch>` line exists; the branch is not checked out in any worktree; its objectname == `merged.head`. Command `git branch -D <branch>`, target = branch.
  - `card`: the worktree's card for push/remove, the card itself for merge/delete, else null.
  - Name patterns:
    - branch: `^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$`
    - path: `^/[A-Za-z0-9_./-]+$` (K260)
    - PR: a positive int
    - SHA: `^[0-9a-f]{40}$`
  - An action is `{kind, target, card, command, note}`. Order by (card if not null, else target) in code-point order, then push < merge < remove_worktree < delete_branch.
- **R11** `fetched_at` = the max value in `fetch_head_mtimes`, or `"never fetched"` when it is empty.
- **R12** The output is `{agents, leads, queue: {waiting, ready, done}, actions, fetched_at}`; the queue is the source STATE's.

## Tests to append (after line 287)
1. `derive output equals the parity fixture (K252)`: `expect(derive(PARITY.raw as unknown as Raw)).toEqual(PARITY.expected)`.
2. A new helper `gitWorld(on, raw)` serves one raw and counts `process.run` calls:
   - `mock.clock(on, { now: raw.now * 1000 })`;
   - process.run by argv: `--show-toplevel` → `raw.self`; `--git-common-dir` → `raw.common_dir`; `worktree` → `worktree_list`; `for-each-ref` → `for_each_ref`; `status` → `worktrees[cwd].status`; `diff` → exitCode `state_diff_exit ?? 0`; `log` → `state_log_ct`;
   - fs.exists/stat/read/list from `worktrees[path].files`. The STATE stat mtimeMs is `state_mtime * 1000` when that is set, else 1. FETCH_HEAD paths get mtimeMs `value * 1000`. List returns the direct child names.
3. `one 20-second look asks git at most 3 + 3N times (K257)`: start at `raw.self`, set `calls.n = 0`, `now.advance(20_100)`, then `0 < calls.n <= 3 + 3 * 16`.
4. `the board shows the five sections and the card ledger`: use a copy (`JSON.parse(JSON.stringify(PARITY.raw))`) with `worktrees['/r/.claude/worktrees/lead-c'].state_log_ct = 1762299999`, so `chooseRoot` picks lead-c. On both surfaces find:
   - the headings `Leads`, `Ajanlar`, `Seni bekliyor`, `Merge'e hazır`, `Git işleri`;
   - a Text equal to `gh pr merge 60 --squash --match-head-commit d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2`;
   - a Text matching `/unsafe name: run by hand/`.

   Then press `card-T029` and find `/qa r1 @d1d1d1d REJECT · by claude\/lead-c/` and `/qa r2 @d2d2d2d ACCEPT · by claude\/lead-c/`.

## Interfaces
- Consumed, read-only (on main before dispatch, K252; in no card's Files):
  - `plugins/delix-board/tests/board_parity.ts` (`export const PARITY = ` + the JSON bytes)
  - `tests/fixtures/board_parity.json` (its source; T029 checks the byte copy)
- Produced:
  - `derive(raw: Raw)` and `type Raw` from `hooks/parse.ts`
  - the Snapshot fields above
  - atom shape `snapshot-4`

## Global Constraints (verbatim from the spec)
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 3 + 3N git çağrısı yapar (K257)."
- K252: "panel board.py'yi çağırmaz (delix-board delix'ten bağımsız kurulur)".
- K255: "Panelin `accepted` + PR → `merge` kuralı yanlış (review skill §4); düzeltilir".
- Design: "mevcut delix-board görsel dili (docs/spec/delix-board.md §7); yeni renk ve bileşen yok." Only `gfx.tsx` exports; no emoji (`plain()`).
- §6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz." No `$.fs.write`, no `fetch`, no `gh`, no button that runs a command.

## Steps
1. Make the two K255 line changes and append the tests. Run `claude plugin test plugins/delix-board` and see **red**.
2. Implement anchors 1–5.
3. Run and see **green** on both surfaces. Open the pane in Claude Desktop in this repo and save a screenshot of Pano and Kart to `.delix/evidence/`.
4. Commit `T030: delix-board derive(), five sections, card ledger, K255 gate fix (Spec C)`. Open a PR with `## How I tested`.

## Verification command → expected output
- `claude plugin test plugins/delix-board` → all pass (14 existing + 4 new).
- `claude plugin validate plugins/delix-board` → passes.
- `git diff origin/main -- plugins/delix-board/tests/board.test.tsx | grep -c '^-[^-]'` → `2`.
- `git diff origin/main -- plugins/delix-board/tests/fixtures.ts plugins/delix-board/tests/board_parity.ts` → no output.

## Review Focus
- The existing chooseRoot tests (lines 245–287) still pass, which means the calls are passed with `cwd` and not `-C`.
- Commands render uncut; sorting uses code-point comparison.
- `derive` reads no `$`.
- The budget holds when chooseRoot needs `log` for every card-less clean worktree.

## Don'ts
- Untouchable: `plugins/delix-board/tests/fixtures.ts`, `plugins/delix-board/tests/board_parity.ts`, `hooks/gfx.tsx`, `hooks/wait.ts`, `plugins/delix-board/hooks/hooks.json`, `plugins/delix-board/.claude-plugin/plugin.json` (T032 bumps it), and everything outside `plugins/delix-board/`.
- No other existing test line changes. If one fails, write `NEEDS_CONTEXT`.
- If the fixture disagrees with R, do not edit it: write `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 1–2K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- test output;
- screenshot paths;
- the PR number;
- assumptions.

Read only this card and spec §3–§6.

## Review findings (filled by the lead)
- (none yet)
