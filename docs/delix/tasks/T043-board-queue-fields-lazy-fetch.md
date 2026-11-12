# T043 — Board: queue entries name who opened a card and its last round (K291), panel captions (K290), raw-input rules (K293), `--no-lazy-fetch` on calls 4–6 (K294), T038 notes

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T043 | L | 2 | frontend | 15 | open |

> **Tier 2.** No file of this card is in `docs/delix/delix.json` `protected_paths` (lines 7–18). `.claude-plugin/**` is anchored at the repo root, and `plugins/delix-board/.claude-plugin/plugin.json` is not touched. It is Tier 2 for new behaviour, ten files and a visual change in the panel.
>
> **Why one card for both surfaces.** Both suites compare the parity fixture with exact equality (`tests/board_tests.sh:79–88`, `plugins/delix-board/tests/board.test.tsx:293–295`). So K291's derive change, both derives and the fixture land in one PR (K298).
>
> **Wave 15 runs in parallel** with T044 (`scripts/bash_gate.py`) and T045 (`skills/review`, `skills/close`). No file is shared.

**Goal (1 sentence):** Each `queue.waiting[]`/`queue.ready[]` entry carries `opened_by` and `last_round` on both surfaces. The panel shows `changed_at` and the ledger in dim caption lines. Both surfaces collect raw input by one rule (`default_branch` pattern, call 5 only when `.delix/card` is absent in every form). Calls 4–6 carry `--no-lazy-fetch`. The three T038 review notes are fixed.

**Spec:** `docs/delix/specs/C-board-visibility.md` REQ-2, REQ-5, REQ-6, §4 (queue row, git row), §6; K284, K290, K291, K293, K294, K298.

**Docs/site:** none. T046 (wave 16) writes the docs and bumps the delix-board version. No Desktop screenshot in this card (K292).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/board.py`
- Modify: `plugins/delix-board/hooks/data.ts`
- Modify: `plugins/delix-board/hooks/parse.ts`
- Modify: `plugins/delix-board/hooks/views.tsx`
- Modify: `plugins/delix-board/hooks/register.tsx` — line 17 only
- Modify: `plugins/delix-board/types/index.d.ts` — lines 51 and 53 only
- Modify: `tests/fixtures/board_parity.json` — named exception to K252 (K298): only the delta under "Fixture delta"
- Modify: `plugins/delix-board/tests/board_parity.ts` — the same delta, same lines
- Test: `tests/board_tests.sh` — 6 named lines change; new checks at one anchor
- Test: `plugins/delix-board/tests/board.test.tsx` — 7 named lines change; new tests appended

## Edit anchors (base 1da4990)

### `scripts/board.py`
1. **New `_card_present(wt)`** (rule R-C), after line 215 (`        w["files"][rel] = text`, the end of `_add_file`) and before line 218 (`def _add_lead_files(w, wt):`).
2. **Line 234** `    raw = {"default_branch": default if isinstance(default, str) and default else "main",` becomes `    raw = {"default_branch": default if _ok(BRANCH_RE, default) else "main",`.
3. **Line 267** `        w["status"] = _out(["git", "status", "--porcelain"], p)`: the argv becomes `["git", "--no-lazy-fetch", "status", "--porcelain"]`.
4. **Line 270** `        if _card_id(w) is None and not _state_dirty(w["status"]):` becomes `        if not _card_present(p) and not _state_dirty(w["status"]):`.
5. **Line 271:** the argv starts `["git", "--no-lazy-fetch", "diff", "--no-ext-diff", "--quiet", …`.
6. **Line 288:** the argv starts `["git", "--no-lazy-fetch", "log", "-1", "--no-show-signature", …`. The comment on line 287 adds K294.
7. **New `_ledger(c)`** (rule R-Q), after line 447 (`    return r, last, (qa[-1] if qa else None), (sec[-1] if sec else None)`, the end of `_review`) and before line 450 (`def _pr(v):`).
8. **`_queue`:**
   - after line 488 (`        f = _facts(cid, c, refs, card_wt)`) insert `        opened_by, last_round = _ledger(c)  # K291`;
   - line 499 (`ready.append(…)`), line 514 (`waiting += […]`) and line 519 (the verification `waiting.append(…)`) get the two keys as in R-Q.
9. **Agents, lines 574–584:**
   - lines 574–580 (`impl = …` through `for a in last]`) become `        opened_by, last_round = _ledger(c)`;
   - line 583 becomes `                       "opened_by": opened_by,`;
   - line 584 stays.
10. **`git_sections`:**
    - after line 667 (`        return one_line(cell(x)).strip()`) insert the nested `ledger(x)` from R-M;
    - line 692 appends `+ ledger(x)` to the card branch;
    - line 696 appends `+ ledger(x)`.

### `plugins/delix-board/hooks/parse.ts`
1. **Line 412:** `const BRANCH_RE = …` becomes `export const BRANCH_RE = …`. The pattern does not change.
2. **New helpers** before line 580 (`  // R8, R8' (K262): …`): insert `roundLine` (moved verbatim from lines 646–648), `openedBy` and `roundLines` (R-Q), then delete lines 646–648.
   - Why: `queueOf` runs at line 644, before line 647 is evaluated. A `const` used there is in its temporal dead zone (TDZ), `derive` would catch the ReferenceError, and the parity test would see `emptyDerived`.
3. **`queueOf`:**
   - line 618 (`for (const reason of reasons) q.waiting.push(…)`), line 620 (`q.ready.push(…)`) and line 626 (the verification push) get the two keys.
   - Compute `const by = openedBy(card)` and `const rounds = roundLines(card)` once per card, before line 618.
4. **Agents map:**
   - delete line 656 (`const r = sourceCard === null ? null : lastRound(sourceCard)`; it is unused after this change);
   - lines 666–672 become `      opened_by: sourceCard === null ? null : openedBy(sourceCard),` and `      last_round: sourceCard === null ? [] : roundLines(sourceCard),`.

### `plugins/delix-board/hooks/data.ts`
1. **Import list (lines 8–24):** add `BRANCH_RE,`.
2. **New `export function utf8Bytes(text: string): number`** (R-T c), after line 55 (`}`, the end of `zList`).
3. **`readIfChanged` (lines 86–100)** gets a `kind: string` parameter before `parse` (R-T a):
   - the cache key becomes `` `${kind}:${path}` `` on lines 90, 93 and 98;
   - line 96 `text.length > MAX_FILE_BYTES` becomes `utf8Bytes(text) > MAX_FILE_BYTES`.
4. **Callers and their kinds:**

   | Line | Call | kind |
   |---|---|---|
   | 130 | delix.json read in `defaultBranch` | `'delix'` |
   | 229 | `withFiles` | `'text'` |
   | 267 | root STATE | `'state'` |
   | 273 | `previous` | `'state'` |
   | 274 | metrics | `'metrics'` |
   | 279 | task cards | `'card'` |
   | 291 | `.delix/card` | `'text'` |
   | 301 | report | `'report'` |
   | 302 | test-result | `'test'` |

5. **Line 138:** `/^[A-Za-z0-9][A-Za-z0-9._/-]*$/.test(value)` becomes `BRANCH_RE.test(value)`. The doc comment on line 128 says "the REQ-4 branch pattern (K293)".
6. **New `hasCardEntry($, tree)`** (R-C), after line 139 (`}`, the end of `defaultBranch`).
7. **Lines 164–167** become:
   - `const hasCard = await hasCardEntry($, tree.path)`
   - `const stat = await safeStat($, tree.path, STATE)`
   - `const hasState = stat !== null`
   - `const mtimeMs = stat?.mtimeMs ?? 0` (R-T b)
8. **Lines 168, 173 and 177:** the argv starts with `'--no-lazy-fetch'` (R-L). The comment on lines 141–146 names K293 and K294 in backticks.

### `plugins/delix-board/hooks/views.tsx`
1. **New `ledgerCaption`** (R-V), after line 157 (`const ROLE_COLOR …`).
2. **Leads, lines 171–177:** the `<Text>` row goes into `<Box flexDirection="column">`, followed by the Leads caption.
3. **Agents, lines 186–192:** the row goes into a column `Box`, followed by `{a.card === null ? null : ledgerCaption(k, a.opened_by, a.last_round)}`.
4. **Seni bekliyor, lines 199–204:** each row goes into a column `Box`, followed by `{e.card === null ? null : ledgerCaption(k, e.opened_by, e.last_round)}`.
5. **Merge'e hazır, lines 210–215:** each row goes into a column `Box`, followed by `{ledgerCaption(k, r.opened_by, r.last_round)}`.

### Other files
- `register.tsx` line 17: `{ shape: 'snapshot-4' }` becomes `{ shape: 'snapshot-5' }`. The Snapshot shape changes (WaitEntry, ReadyEntry), and spec §5 says the key goes up by one.
- `types/index.d.ts`:
  - line 51 becomes `export type WaitEntry = { card: string | null; verification: string | null; reason: string; opened_by: string | null; last_round: string[] }`;
  - line 53 becomes `export type ReadyEntry = { card: string; pr: number; sha: string | null; opened_by: string | null; last_round: string[] }`.

## Rules (identical on both surfaces)

### R-L (K294): calls 4–6 carry `--no-lazy-fetch`
Each argv starts after `git --no-optional-locks -c core.fsmonitor=false`:
- 4: `--no-lazy-fetch status --porcelain`
- 5: `--no-lazy-fetch diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json`
- 6: `--no-lazy-fetch log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`

Call 7 is unchanged. Calls 1–3 do not get the flag (K294 scope). In board.py, callers pass `["git", "--no-lazy-fetch", …]`; `_git` (line 137) adds the prefix.

### R-D (K293): `default_branch`
`default_branch` is the value when it is a string and matches `BRANCH_RE` exactly (`^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$`). Otherwise it is `main`.
- board.py: `_ok(BRANCH_RE, default)`. Not `_branch_ok`: the `reset`/`clean` exclusion is a command rule, not this one.
- Panel: `typeof value === 'string' && BRANCH_RE.test(value)`.

### R-C (K293): call 5 runs only when `.delix/card` is absent in every form
board.py:
```python
def _card_present(wt):
    """K293: <wt>/.delix/card exists in any form (regular file, link incl. a dangling one, directory, FIFO, a file
    that cannot be read). lstat follows no final link; only "not found" and "not a directory" count as absent, any
    other error as present (call 5 then does not run: fail closed)."""
    try:
        os.lstat(os.path.join(wt, ".delix", "card"))
    except (FileNotFoundError, NotADirectoryError):
        return False
    except (OSError, ValueError):
        return True
    return True
```
Panel:
```ts
/** K293: `.delix/card` is there in any form when the listing of `.delix` names an entry `card`, whatever its kind (a link is listed, not followed, a dangling one too). A `.delix` that cannot be listed but stats as a directory counts as holding one (fail closed); one that neither lists nor stats holds none. */
async function hasCardEntry($: EngineInterface, tree: string): Promise<boolean> {
  const dot = join(tree, '.delix')
  const entries = await $.fs.list(dot).catch(() => null)
  if (entries !== null) return entries.some(e => e.name === 'card')
  const stat = await $.fs.stat(dot).catch(() => undefined)
  return stat?.kind === 'dir'
}
```
- **Why not `$.fs.exists`:** its link semantics are not documented in this repo. The fakes (`board.test.tsx:42`, `:329`) only test key presence, and `data.ts:67–68` says `$.fs.stat` follows a link for `kind`. If `exists` follows links like Node's, it is false for a dangling link and for a directory the fakes do not list. `$.fs.exists(` no longer appears in `data.ts`.
- **Roles do not change:** derive still takes the card id from the file text (`_card_id`, `cardOf`), so the fixture's `agents` and `leads` do not move. A worktree with a broken card is not a lead because of the three-dot diff; a dirty STATE or a branch that is a `by` value still makes it one (REQ-1).

### R-Q (K291): the two new queue keys
**Source and format.** Same source and format as the Agents rows, taken from the card in the STATE being queued:
- `opened_by` is the last `implementer` record's `by` when that is a string, else null;
- `last_round` is one line `"<role> r<n> @<sha7 or -> <verdict or -> · by <by or ->"` per record of the latest `qa`/`security` round, in list order.

board.py:
```python
def _ledger(c):
    """K291 (R6): (opened_by, last_round) of one STATE card, as the Agents rows and the queue entries carry them."""
    impl = _implementers(c)
    n, last = _review(c)[:2]
    return (impl[-1]["by"] if impl and isinstance(impl[-1].get("by"), str) else None,
            ["%s r%d @%s %s · by %s" % (a["role"], n, _str(a.get("sha"))[:7] or "-", _str(a.get("verdict")) or "-",
                                             _str(a.get("by")) or "-") for a in last])
```
Panel (inserted before line 580; `roundLine` text unchanged):
```ts
  // R6 (K291): who opened a card and the lines of its latest qa/security round, for the Agents rows and the queue
  const roundLine = (r: Json) => …lines 647–648 verbatim…
  const openedBy = (card: Json): string | null => textOf(lastOf(records(card), 'implementer')?.by)
  const roundLines = (card: Json): string[] => {
    const r = lastRound(card)
    return r === null ? [] : records(card).filter(x => (x.role === 'qa' || x.role === 'security') && x.round === r).map(roundLine)
  }
```
**Key order and lists:**
- waiting entries: `card, verification, reason, opened_by, last_round`;
- ready entries: `card, pr, sha, opened_by, last_round`;
- each entry gets its own list (`list(last_round)` / `[...rounds]`);
- card-less (verification) entries carry `opened_by: null` and `last_round: []`;
- `queue.done` is unchanged.

### R-V (K290, K291): panel captions
```tsx
/** K290, K291: who opened a card and its last review round, one dim caption under the row; drawn whole (`plain`, no `cut`), so a narrow pane wraps it instead of cutting it. */
function ledgerCaption(k: Kit, by: string | null, rounds: string[]): RenderElement {
  const { Text } = k
  const text = plain(`açan ${by ?? '—'} · son tur ${rounds.length > 0 ? rounds.join('; ') : '—'}`)
  return <Text dimColor size="caption">{`  ${text}`}</Text>
}
```
- The indent goes outside `plain`, because `plain` collapses runs of spaces.
- Leads caption under each row: `<Text dimColor size="caption">{`  STATE değişti: ${l.changed_at === null ? '?' : utcMinute(l.changed_at)}`}</Text>`.
- Which rows get `ledgerCaption`:
  - Agents: every row with a card;
  - Seni bekliyor: every entry with a card;
  - Merge'e hazır: every entry;
  - never a verification entry.

### R-M (K291): board.py Markdown
```python
    def ledger(x):  # K291; % formatting: no backslash inside an f-string expression on Python 3.9
        return " · opened by %s · last round %s" % (item(x["opened_by"] or "—"), item("; ".join(x["last_round"]) or "—"))
```
- Waiting card line: `- <card> · <reason> · opened by <x|—> · last round <a; b|—>`. The verification line is unchanged.
- Ready line: `- <card> · PR #<n> · reviewed <sha7> · opened by … · last round …`.

### R-T: T038 review notes (all in `data.ts`)
- **(a) Cache key.** The read cache is keyed by `` `${kind}:${path}` ``, where `kind` is one fixed word per parser (see the caller table). Today a `previous` that names `docs/delix/delix.json` gets `defaultBranch`'s cached value, and `previous?.cards[id]` throws (lines 93–94, 314).
- **(b) `hasState`.** `hasState` is `safeStat(tree.path, STATE) !== null`, and `mtimeMs` comes from that result. So a linked STATE, a STATE under a linked directory, or one over 1 MiB is not a source candidate. Today it is `stat?.kind === 'file'` (lines 165–166), which is true for a link.
- **(c) 1 MiB limit.** The limit compares the UTF-8 byte length:
  ```ts
  export function utf8Bytes(text: string): number {
    let n = 0
    for (let i = 0; i < text.length; i++) {
      const c = text.charCodeAt(i)
      if (c < 0x80) n += 1
      else if (c < 0x800) n += 2
      else if (c >= 0xd800 && c <= 0xdbff && i + 1 < text.length && (text.charCodeAt(i + 1) & 0xfc00) === 0xdc00) {
        n += 4
        i += 1
      } else n += 3 // includes a lone surrogate (U+FFFD)
    }
    return n
  }
  ```
  No `TextEncoder` or `Buffer`: neither is verified in the engine.

### Unchanged
- call order and the 4 + 3N budget;
- K254, K256, K262, K274, R8'';
- every REQ-4 pattern;
- `_read_in` and `safeStat` themselves;
- `queue.done`, `agents` and `leads` in the fixture;
- `fixtures.ts`.

## Fixture delta (the named exception to K252, K298)
Edit both files with the Edit tool, the same eight lines, nothing else.
- The TS copy has the same line numbers, because its line 1 is `export const PARITY = {`. It stays `export const PARITY = ` + the JSON bytes.
- The fixture stays ASCII: the middle dot is written as the 6-character escape `\u00b7`, as the fixture already does (lines 44–45).
- The values come from the source STATE (`worktrees["/r/.claude/worktrees/lead-c"].files["docs/delix/STATE.json"]`).

Lines 65–71 become:
```
    {"card": "T029", "verification": null, "reason": "ready to merge", "opened_by": "claude/lead-c", "last_round": ["qa r2 @d2d2d2d ACCEPT \u00b7 by claude/lead-c", "security r2 @d2d2d2d CLEAN \u00b7 by claude/lead-c"]},
    {"card": "T030", "verification": null, "reason": "changed after review", "opened_by": "claude/lead-c", "last_round": ["qa r1 @e1e1e1e ACCEPT \u00b7 by claude/lead-c", "security r1 @e1e1e1e CLEAN \u00b7 by claude/lead-c"]},
    {"card": "T036", "verification": null, "reason": "no review record", "opened_by": null, "last_round": []},
    {"card": "T037", "verification": null, "reason": "tier 3 approval", "opened_by": null, "last_round": []},
    {"card": "T039", "verification": null, "reason": "needs_context", "opened_by": "claude/lead-c", "last_round": []},
    {"card": "T040", "verification": null, "reason": "escalated", "opened_by": null, "last_round": []},
    {"card": null, "verification": "v-fix", "reason": "verification FIX", "opened_by": null, "last_round": []}
```
Line 74 becomes:
```
    {"card": "T029", "pr": 60, "sha": "d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2", "opened_by": "claude/lead-c", "last_round": ["qa r2 @d2d2d2d ACCEPT \u00b7 by claude/lead-c", "security r2 @d2d2d2d CLEAN \u00b7 by claude/lead-c"]}
```
**Worktree-less ready card (REQ-2 scenario):** the fixture does not cover it. T028 (lead-b) is worktree-less and ready, but only lead-c's queue is in `expected`. It is tested in new tests below, not in the fixture.

## Existing test lines that change (named exceptions, like K255/K273)

### `tests/board_tests.sh`
All six break because K291 adds two keys to every queue entry. The file writes the middle dot raw (`·`); keep that.

| Line | Today | Becomes |
|---|---|---|
| 246 | `assert {"card": "T001", "verification": None, "reason": "review not on origin/main"} in a["queue"]["waiting"], a["queue"]` | `assert {"card": "T001", "verification": None, "reason": "review not on origin/main", "opened_by": "claude/f", "last_round": ["qa r1 @%s ACCEPT · by claude/f" % tip[:7]]} in a["queue"]["waiting"], a["queue"]` |
| 247 | `assert b["queue"]["ready"] == [{"card": "T001", "pr": 7, "sha": tip}], b["queue"]` | `assert b["queue"]["ready"] == [{"card": "T001", "pr": 7, "sha": tip, "opened_by": "claude/f", "last_round": ["qa r1 @%s ACCEPT · by claude/f" % tip[:7]]}], b["queue"]` |
| 260 | `assert {"card": "T001", …"review not on origin/main"} in d["queue"]["waiting"], d["queue"]` | `assert [x for x in d["queue"]["waiting"] if (x["card"], x["verification"], x["reason"], x["opened_by"]) == ("T001", None, "review not on origin/main", "claude/f")], d["queue"]` |
| 315 and 354 | `want = [dict(x, reason="review not on origin/main") if x == {"card": "T029", "verification": None, "reason": "ready to merge"} else x` | `want = [dict(x, reason="review not on origin/main") if (x["card"], x["reason"]) == ("T029", "ready to merge") else x` |
| 333 | `assert {"card": "T029", "verification": None, "reason": "review not on origin/main"} in d["queue"]["waiting"], d["queue"]["waiting"]` | the same dict plus `"opened_by": "claude/lead-c", "last_round": ["qa r2 @d2d2d2d ACCEPT · by claude/lead-c", "security r2 @d2d2d2d CLEAN · by claude/lead-c"]` |

### `plugins/delix-board/tests/board.test.tsx`

| Line | Becomes | Why |
|---|---|---|
| 439 | `      { card: 'T001', verification: null, reason: 'changed after review', opened_by: 'claude/x', last_round: ['qa r1 @- ACCEPT · by -'] },` | K291 |
| 440 | `      { card: 'T002', verification: null, reason: 'ready to merge', opened_by: null, last_round: ['qa r1 @5555555 ACCEPT · by -'] },` | K291 |
| 442 | `    ready: [{ card: 'T002', pr: 8, sha: sha('5'), opened_by: null, last_round: ['qa r1 @5555555 ACCEPT · by -'] }],` | K291 |
| 684 | `…every(a => a[4] === '--no-lazy-fetch' && a[5] === 'diff' && a[6] === '--no-ext-diff')).toBe(true)` | K294 |
| 685 | `  expect(argvs.filter(a => a.includes('--no-lazy-fetch')).every(a => a[4] === '--no-lazy-fetch' && ['status', 'diff', 'log', 'cat-file'].some(c => a.includes(c)))).toBe(true)` | K294 |
| 746 | `  for (const argv of logs) expect(argv).toEqual([...K263, '--no-lazy-fetch', 'log', '-1', '--no-show-signature', '--format=%ct', '--', 'docs/delix/STATE.json'])` | K294 |
| 803 | `  expect(await ui.find({ type: 'Button', key: 'card-T028' })).toBeDefined()` | R-T b: lead-c's linked STATE is no longer a source, so `/r` (newest of the rest) is, and its STATE lists T026–T028 |

`fixtures.ts`: no change.

## Interfaces
- **Consumed:** nothing from T044/T045.
- **Produced:**
  - the queue entry shapes in R-Q, in `board.py --json` and in the panel Snapshot;
  - the Markdown and caption formats in R-M and R-V (T046 documents them);
  - `BRANCH_RE` (exported from parse.ts);
  - `utf8Bytes` (exported from data.ts);
  - `_card_present` and `_ledger` in board.py.

## Global Constraints (verbatim from the spec)
- REQ-6: "`delix.json.default_branch` REQ-4'teki dal kalıbına (`^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$`) uyan bir metinse o, değilse `main`; çağrı 5 yalnız worktree'de `.delix/card` hiçbir biçimde (normal dosya, bağlantı, dizin, okunamayan dosya) yokken koşar; çağrı 4–6'nın argv'si §4'teki gibi `--no-lazy-fetch` taşır (K284, K294)."
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262)."
- §4: "bugünkü alanlar aynen + `"opened_by":"<lead branch>"|null` ve `"last_round":[…]`; ikisi Ajanlar satırındakiyle aynı kaynaktan ve aynı biçimde, kartsız (doğrulama) girdide `null` ve `[]` (K291)"
- §6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz; nesne okuyan çağrılar (4–7) `--no-lazy-fetch` taşır"
- §4 design: "mevcut delix-board görsel dili (docs/spec/delix-board.md §7); yeni renk ve bileşen yok."
  - Use only existing `Text` props (`dimColor`, `size="caption"`) and existing `gfx` exports.
  - No new colour, icon, size or spacing value.
  - Data text goes through `plain()`.
- Python 3.9 stdlib. No backslash inside an f-string expression. Run on 3.9.6 and 3.13.

## Steps
1. Apply the fixture delta.
   - `bash tests/board_tests.sh` shows `✘ parity: derive(raw) != expected` and `✔ parity: TS copy is byte-equal`.
   - The panel parity test fails.
2. Make the 13 named line changes and add the new tests. Run both suites and see each new test **red**.
3. Implement board.py. See the board suite green on `python3` 3.9.6 and on 3.13 (a `python3` → `python3.13` symlink first on `PATH`).
4. Implement the panel. Run `claude plugin test plugins/delix-board` and see it green.
5. Find the `claude-code` typing or doc for `$.fs.list` and `$.fs.exists` (link behaviour) and quote it in the report, or write `unverified`.
6. Run Verification and write every output to `.delix/evidence/verification.txt` (K278).
7. Commit `T043: queue opened_by/last_round (K291), panel captions (K290), raw-input rules (K293), --no-lazy-fetch on calls 4-6 (K294), T038 notes`. Run `git push -u origin HEAD` as its own command, with no `cd`. Open a PR with `## How I tested`.

## Tests (each red first)

### `tests/board_tests.sh`
Insert after line 399 (`PYS`, the end of the T037 D3 check) and before line 401 (`cd /; rm -rf "$T"; …`).

**B1 — K293/K294 raw input.**
- **Setup:**
  - `R="$(mktemp -d)"; R="$(cd "$R" && pwd -P)"`.
  - A repo `$R/r`, made like lines 160–162 but without a remote. One commit holds `docs/delix/STATE.json`. Add `.delix/` to `.git/info/exclude`.
  - Worktrees `plain idless link dangling dir fifo unreadable` at `$R/<n>`, on branches `w-<n>`.
  - `.delix/card` in each worktree:

    | Worktree | `.delix/card` |
    |---|---|
    | `plain` | none |
    | `idless` | `no card id\n` |
    | `link` | symlink to `$R/target` (which holds `docs/delix/tasks/T001-x.md`) |
    | `dangling` | symlink to `$R/missing` |
    | `dir` | a directory |
    | `fifo` | `mkfifo` |
    | `unreadable` | `x\n`, then `chmod 000` |

- **In Python:**
  - Wrap `subprocess.run` as `feedback_tests.sh:285–289` does: record `(list(argv), kw.get("cwd"))`, then call the real function.
  - Set `board.subprocess.run` to the wrapper.
  - For each `(value, want)` pair, write `$R/r/docs/delix/delix.json` = `{"default_branch": value}` and call `board.git_raw("$R/r")`. Pairs: `("-x","main")`, `("a b","main")`, `("a//b","main")`, `("a/","main")`, `("","main")`, `(7,"main")`, `("trunk","trunk")`, `("release/1.2","release/1.2")`.
- **Expect, for each pair:**
  - `raw["default_branch"] == want`;
  - the cwds of the `diff` calls, sorted, are exactly `[$R/plain, $R/r]`;
  - every `status` argv == K263 + `["--no-lazy-fetch","status","--porcelain"]` (8 of them);
  - every `diff` argv == K263 + `["--no-lazy-fetch","diff","--no-ext-diff","--quiet","origin/<want>...HEAD","--","docs/delix/STATE.json"]`;
  - at least one `log` argv, and each == K263 + `["--no-lazy-fetch","log","-1","--no-show-signature","--format=%ct","--","docs/delix/STATE.json"]`;
  - no argv containing `rev-parse`, `worktree` or `for-each-ref` contains `--no-lazy-fetch`.
- **Cleanup:** `chmod 600` the unreadable card, then `rm -rf "$R"`.

**B2 — REQ-2 worktree-less ready card.**
- `raw = json.loads(json.dumps(fixture["raw"]).replace("ACCEPT_WITH_NOTES", "ACCEPT"))` and `raw["source"] = "/r/.claude/worktrees/lead-b"`.
- `lines = ["qa r1 @2828282 ACCEPT · by claude/lead-b", "security r1 @2828282 \U0001F510 HUMAN_APPROVAL · by claude/lead-b"]`.
- Expect `derive(raw)["queue"]["ready"] == [{"card": "T028", "pr": 58, "sha": "28"*20, "opened_by": "claude/lead-b", "last_round": lines}]`.
- Expect the waiting list to hold the same keys with `"verification": None, "reason": "ready to merge"`.
- Expect `board.git_sections(dict(d, project="/r"))` to contain:
  - `"- T028 · PR #58 · reviewed 2828282 · opened by claude/lead-b · last round " + "; ".join(lines)`;
  - `"- T028 · ready to merge · opened by claude/lead-b · last round " + "; ".join(lines)`.

**B3 — Markdown from the fixture as is.**
`git_sections` contains:
- `- T029 · ready to merge · opened by claude/lead-c · last round qa r2 @d2d2d2d ACCEPT · by claude/lead-c; security r2 @d2d2d2d CLEAN · by claude/lead-c`
- the `- T029 · PR #60 · reviewed d2d2d2d · opened by …` line with the same tail;
- `- T036 · no review record · opened by — · last round —`
- `- v-fix (verification) · verification FIX`

In the Python strings, write `·` and `—` raw (as the file already does) or as the escapes `\u00b7` and `\u2014`; both give the same string.

### `plugins/delix-board/tests/board.test.tsx`
Append after line 807 (the last line). Use `W = '/r/.claude/worktrees'`.

**P0 — helper `rawSpy(on, over)`.**
- It wraps every handler. It records each `process.run` as `{ argv, cwd: e.init?.cwd ?? '' }`.
- For `fs.exists`, `fs.stat`, `fs.list` and `fs.read`, it first answers from `over[e.path]?.<exists|stat|list|read>`: `'throw'` throws; any other value returns `{ value }`. Otherwise it calls the original handler.
- Same casting style as `spy`, line 483.

**P1 — K293/K294 raw input, one test per `[value, want]` pair.**
- **Pairs (6 tests):** `['-x','main']`, `['a b','main']`, `['a//b','main']`, `['a/','main']`, `['a/-b','main']`, `['release/1.2','release/1.2']`.
- **Setup:**
  - deep-copy `PARITY.raw`;
  - put `docs/delix/delix.json` = `{"default_branch": value}` in lead-c's `files`;
  - add these `.delix` files:

    | Worktree | `.delix` setup |
    |---|---|
    | `fresh` | `.delix/card` = `no card id\n` |
    | `old` | `.delix/card` = `docs/delix/tasks/T001-x.md\n`; over `stat`: `{kind:'file',size:27,mtimeMs:1,isLink:true}` |
    | `flag-f` | `.delix/card/x` = `''` (a directory) |
    | `x_fix` | `.delix/card` = `docs/delix/tasks/T001-x.md\n`; over `read: 'throw'` |
    | `det` | over `` `${W}/det/.delix` `` `list: [{name:'card',kind:'file',size:0,mtimeMs:1,isLink:true}]`; over `` `${W}/det/.delix/card` `` `{exists:false, stat:'throw', read:'throw'}` (a dangling link) |

  - `gitWorld(recorded, raw)`, then start the session and record the look after `now.advance(20_100)`, as at lines 671–677.
- **Expect:**
  - diff cwds sorted == `['gone','lead-b','lead-c','mirror','semi'].map(n => `${W}/${n}`)`;
  - each diff argv == `[...K263, '--no-lazy-fetch', 'diff', '--no-ext-diff', '--quiet', `origin/${want}...HEAD`, '--', 'docs/delix/STATE.json']`;
  - 16 status argvs, each `[...K263, '--no-lazy-fetch', 'status', '--porcelain']`;
  - log argvs (at least one) as in line 746's new form;
  - no rev-parse/worktree/for-each-ref argv with the flag.

**P2 — R-T a (cache key).**
- `world(on, { ...FILES, [`${ROOT}/docs/delix/STATE.json`]: <FILES STATE with previous: 'docs/delix/delix.json'>, [`${ROOT}/docs/delix/delix.json`]: '{"default_branch":"main"}' })`.
- Expect `card-T002` defined on a terminal mount. On base the refresh throws and the snapshot stays null.

**P3 — R-T b (`hasState`).**
- `spy(on, …)` marks `` `${ORCH}/docs/delix/STATE.json` `` `isLink: true`.
- `world(linked, LAYOUT, { top: ORCH, common: `${MAIN}/.git`, trees: LAYOUT_TREES, commits: LAYOUT_COMMITS })`, session in ORCH.
- Expect `card-T001` defined and `/kaynak: orch/` absent.

**P4 — R-T c (1 MiB in UTF-8 bytes).**
- `dataHooks.utf8Bytes`:

  | Input | Expected |
  |---|---|
  | `'a'` | 1 |
  | `'é'` | 2 |
  | `'€'` | 3 |
  | `'\u{1F510}'` | 4 |
  | `'\ud800'` | 3 |
  | `'é'.repeat(524288)` | 1048576 |

- Then, as at lines 596–610 (lead-c `state_log_ct = 1762299999`), set the spec to `` `# Wide spec title\n${'é'.repeat(600000)}\n` ``. Its UTF-16 length is under 1 MiB, its UTF-8 length is over it.
- Expect `/Wide spec title/` absent and `/ · claude\/lead-c · - · açık 7/` present.

**P5 — K290/K291 captions.**
- Setup as at lines 373–377. On both surfaces, expect:
  - `/STATE değişti: 2025-11-04 23:46 UTC/` defined (lead-c's `changed_at` 1762299999);
  - exactly 3 Texts matching `/açan claude\/lead-c · son tur qa r2 @d2d2d2d ACCEPT · by claude\/lead-c; security r2 @d2d2d2d CLEAN · by claude\/lead-c/`: the Ajanlar row of impl-29, Seni bekliyor T029 and Merge'e hazır T029;
  - `/açan — · son tur —/` defined (T036).

**P6 — REQ-2 worktree-less ready card in the panel.**
- `raw = JSON.parse(JSON.stringify(PARITY.raw).replace(/ACCEPT_WITH_NOTES/g, 'ACCEPT'))`; lead-b `state_log_ct = 1762299999`.
- Pure check: `derive({...raw, source: lead-b}).queue.ready` equals B2's entry, with `'\u{1F510} HUMAN_APPROVAL'`.
- UI check (terminal):
  - `/kaynak: lead-b/` is defined;
  - exactly 2 Texts match `/açan claude\/lead-b · son tur qa r1 @2828282 ACCEPT · by claude\/lead-b; security r1 @2828282 ◈ HUMAN_APPROVAL · by claude\/lead-b/` (Seni bekliyor and Merge'e hazır; no Agents row). The pane draws the lock emoji as `◈` (`cut`, `board.test.tsx:94`).

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0. Run it on `python3` 3.9.6 and on 3.13.
- `bash tests/board_tests.sh | tail -1` → `ALL PASSED`
- `bash tests/board_tests.sh | grep -cF '✔'` → `46`
- `bash tests/board_tests.sh | grep -cF '✘'` → `0`
- `claude plugin test plugins/delix-board` → `48` pass, `0` fail
- `claude plugin validate .` and `claude plugin validate plugins/delix-board` → pass
- `git diff origin/main -- tests/board_tests.sh | grep -c '^-[^-]'` → `6`
- `git diff origin/main -- plugins/delix-board/tests/board.test.tsx | grep -c '^-[^-]'` → `7`
- `git diff origin/main -- tests/fixtures/board_parity.json | grep -c '^-[^-]'` → `8`, and with `'^+[^+]'` → `8`. Same two counts for `plugins/delix-board/tests/board_parity.ts`.
- `python3 -c 'import sys; sys.exit(any(c > 127 for c in open(sys.argv[1], "rb").read()))' tests/fixtures/board_parity.json` → exit 0
- `grep -cF -- '"--no-lazy-fetch"' scripts/board.py` → `4`
- `grep -cF -- "'--no-lazy-fetch'" plugins/delix-board/hooks/data.ts` → `4` (in comments, write the flag in backticks)
- `grep -cF '$.fs.exists(' plugins/delix-board/hooks/data.ts` → `0`
- `grep -cF "shape: 'snapshot-5'" plugins/delix-board/hooks/register.tsx` → `1`
- `git diff --stat origin/main` → only the 10 Files

## Review Focus
- The parity test is green on both surfaces. A TDZ slip, `roundLine` used before its line, would show as `emptyDerived`.
- `_card_present` uses `lstat`. Only "not found" and "not a directory" count as absent.
- Residual, name it in the report: a `.delix` that is searchable but not listable (x-only) with no `card` counts as holding one in the panel (stat fallback). board.py's `lstat` sees it exactly.
- git < 2.44 is not tested. Confirm by reading that calls 4–6 then fail closed: status `?` gives a note instead of a command, and no ready card.
- Python 3.9: no backslash inside an f-string expression (R-M uses `%`).
- Captions use `plain()` and no `cut()`; the indent goes outside `plain`.
- The cache delete on line 90 uses the same `kind:path` key as the set.
- `hasState` now also rejects a STATE over 1 MiB or under a linked directory.
- Each queue entry gets its own list.

## Don'ts
- Untouchable:
  - `docs/**`, `site/**`, `README*`, `CHANGELOG.md`, `skills/**`;
  - `scripts/bash_gate.py`, `scripts/common.py`, every other `protected_paths` entry;
  - `plugins/delix-board/.claude-plugin/plugin.json` (the version bump is T046's), `plugins/delix-board/README.md`;
  - `hooks/gfx.tsx`, `hooks/wait.ts`, `hooks/hooks.json`;
  - `plugins/delix-board/tests/fixtures.ts`.
- No existing test line changes except the 13 named above.
- No fixture change except the 8 lines. If derive and the delta disagree, write `NEEDS_CONTEXT`, name the field and stop.
- No new dependency, no `TextEncoder` or `Buffer`, no network, no partial-clone test.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.

## Report contract
`.delix/report.md` (≤ 2K tokens):
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output, `python3 --version` and `git --version`, and the path `.delix/evidence/verification.txt`;
- the `fs.list` / `fs.exists` typing quote, or `unverified`;
- PR number and branch;
- assumptions and the x-only `.delix` residual.

Read only this card and spec REQ-2, REQ-6, §4 (queue row, git row) and §6.

## Review findings (filled by the lead)
- Round 1: …
