# T035 — delix-board panel: the same trusted-ledger rules, hardened git calls, regex and file Lows

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T035 | M | 2 | frontend | 9 | open |

> Tier 2: no protected path; everything is under `plugins/delix-board/`. It changes when the pane shows a merge command. The installed pane stays 0.1.4 until T032 bumps delix-board to 0.1.5.

**Goal (1 sentence):** The panel's `derive` follows exactly T034's rules R1, R8' and R10' (Ready to merge, the merge command and the `merged`-based cleanup only when `origin/<default>`'s STATE also shows the card, PR and SHA; K262), every git call runs with `--no-optional-locks -c core.fsmonitor=false`, `worktree list` uses `-z`, and the regex and file-read Lows are closed (K263). · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-3`, `#REQ-4`, `#REQ-6`; §4 (git row, call 7), §6 (K262 paragraph); K262, K263

**Docs/site:** none in this card (T032, wave 10).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `plugins/delix-board/hooks/data.ts`
- Modify: `plugins/delix-board/hooks/parse.ts`
- Modify: `plugins/delix-board/hooks/views.tsx`
- Test: `plugins/delix-board/tests/board.test.tsx` (insertions only, at the anchors below; no existing line changes)

## Edit anchors (base: the main commit that adds this card; code lines unchanged since e3070ec)
- `hooks/data.ts`
  - line 43 `const basename = (p: string) => p.replace(/\/+$/, '').split('/').pop() ?? p`: use a new exported `trimSlashes` from `parse.ts` (a loop that drops trailing `/`, linear).
  - lines 47 and 117 (`$.process.run(['git', ...` ): argv becomes `['git', '--no-optional-locks', '-c', 'core.fsmonitor=false', ...args]`.
  - line 121 `const listText = stdout(await git(top, ['worktree', 'list', '--porcelain']))`: add `-z` and pass the output through an exported `zList(text)`: split on NUL; any field containing `\n` or `\r` makes the result `''`; otherwise join the fields with `\n` (today's form).
  - after line 124 (`const def = await defaultBranch($, cache, top)`): one call in `top`, `['--no-lazy-fetch', 'cat-file', 'blob', `refs/remotes/origin/${def}:docs/delix/STATE.json`]` through `git` (so the two flags come first); stdout on exit 0, else `null`; put it as `trusted_state` into the object at line 161 (`git: { default_branch: def, ...`).
  - lines 191–194 (`const add = async (rel: string) => {`): add a file only when `$.fs.stat` gives `kind === 'file'`, `isLink === false` and `size <= 1048576`.
- `hooks/parse.ts`
  - `Raw` (lines 378–388): add `trusted_state?: string | null`.
  - lines 48–50 (`/(\d+(?:[.,]\d+)?)\s*(?:sa|saat|h)\b/` and the `sn|s` one): prefix `(?<!\d)` so the leftmost match is the same and the scan is linear.
  - lines 212, 217, 218 (`/^-\s+...(.+)$/`, `/^-\s+(.+)$/`, `/^\s{2,}-\s+(.+)$/`): add the `s` flag, so `.` also takes `\r` and the `\s+` / `.+` split cannot backtrack.
  - line 543 (`/^#?[0-9]+$/` → `Number(...)`): a value that is `0` gives `null`, as in board.py.
  - `queueOf` (lines 565–612) and line 680 (`const queue = queueOf(sourceState, sourcePath)`): R8' (TR applies to the source queue and to every Leads row's counts).
  - lines 694–712 (the `guarded(...)` push / remove / delete calls): R10' (`status`, `merged` and the branch from the trusted card), and a branch named `reset` or `clean` fails the check.
  - new exported `trimSlashes(p: string): string`.
- `hooks/views.tsx`
  - line 48 `const base = (p: string) => p.replace(/\/+$/, '').split('/').pop() ?? p`: export `base`, built on `trimSlashes`.
  - line 224 (`<Text color="warning">{cut(a.note, w)}</Text>`): show `a.note` uncut (P2: a narrow pane cut the note).
- `tests/board.test.tsx` (insert, do not change):
  - before line 39 (`    return out(git.trees)`): `    if (e.argv.includes('-z')) return out(git.trees.replace(/\n/g, '\0'))`
  - before line 318 (`    if (e.argv.includes('worktree')) return out(raw.worktree_list)`): `    if (e.argv.includes('-z')) return out(raw.worktree_list.replace(/\n/g, '\0'))`
  - before line 323 (`    return out('', 1)`): `    if (e.argv.includes('cat-file')) return typeof raw.trusted_state === 'string' ? out(raw.trusted_state) : out('', 128)`
  - the new tests after line 462 (the file's last line).
  The two git flags need no fake change: the fakes match with `includes`. `fixtures.ts` cards have no `agents`, so the K254 rule keeps the existing `merge` gate test (line 107) green.

## Rules (quote of the decided behaviour; the same text as T034)
- **R1:** `trusted_state` = stdout of the `cat-file` call; `null` on any failure. `cat-file blob` runs no textconv or filter.
- **R8':** T = `JSON.parse(trusted_state)` when it is a JSON object, else `{}`. TR = the set of `(card, pr, sha)` that today's R8 marks Ready on T, with no files and the same refs. A card that meets every Ready condition in a queue is Ready only if its `(card, pr, sha)` is in TR. Otherwise its reason in that slot (where `ready to merge` would be) is `review not on origin/<default>` (with the actual default branch), and it has no Ready entry and no merge action.
- **R10':** the delete_branch action and the `merged` condition of remove_worktree read `status`, `merged` and the branch from T's card with the same id; a card that T lacks gives neither.
- Unchanged: `Derived`'s shape, the five sections and their headings, the card table (K254), the REQ-4 patterns and banned tokens, `chooseRoot` (K256), no network and no writes.

## Interfaces
- Consumed: raw key `trusted_state` in the fixture pair (lead; `board_parity.ts` = `export const PARITY = ` + the JSON bytes). With it, derive must still return `expected` unchanged.
- Produced: `Raw.trusted_state`; the reason `review not on origin/<default>`. T034 implements the same rules in board.py.

## Global Constraints (verbatim from the spec)
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262)."
- §6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz."
- Design system: delix-board's visual language (`docs/spec/delix-board.md` §7); text-only change, no new colour or component.

## Steps
1. Add the tests below; run `claude plugin test plugins/delix-board`, see each **red** on the base.
2. Implement in the three hook files only.
3. Run, see **green**; both validates pass.
4. If you can load the pane from this worktree, save a screenshot of the Pano with a waiting `review not on origin/main` card to `.delix/evidence/`; if you cannot, say so in the report (the tests are the evidence).
5. Commit `T035: delix-board trusted ledger from origin/<default>, hardened git, linear regexes (K262, K263)`; open a PR with `## How I tested`.

## Tests (each red first)
1. Pure, the forged case: the fixture's raw with `trusted_state` `'{"cards":{}}'` gives exactly T034 test 2's result (`actions` = `expected.actions` items 0–5, `ready` empty, T029's reason `review not on origin/main` in place, lead-b and lead-c ready 0).
2. Timing: each under 500 ms at k = 100000: `basename` and `base` on `'/'.repeat(k) + 'x'`; the card parser on the line-212/217/218 inputs `'- ' + ' '.repeat(k) + '\r'`; the duration parser (lines 48–50) on `'1'.repeat(k) + 'x'`. Log the ×2 ratios at k = 10k, 20k, 40k, 80k. Leave unchanged, and name in the report, any pattern whose time does not grow about ×4 per doubling before the fix.
3. `zList`: a record with `\n` gives `''`; normal output gives the newline form.
4. A 2 MiB spec file: `spec_title` is null.
5. A branch named `reset`: no push command.
6. pr `"#0"`: the agent's "lands" text is not `PR #0`.
7. One look makes at most 4 + 3N `process.run` calls.

## Verification command → expected output
- `claude plugin test plugins/delix-board` → all pass, 0 fail
- `claude plugin validate plugins/delix-board` and `claude plugin validate .` → pass
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0 (includes the fixture `cmp`)
- `git diff origin/main -- plugins/delix-board/tests/board.test.tsx | grep -c '^-[^-]'` → `0`
- `git diff --stat origin/main` → only the 4 Files; `fixtures.ts` and `board_parity.ts` unchanged

## Review Focus
- The `chooseRoot` tests (lines 247–289) still pass through the `-z` fake.
- The flags come before the subcommand; `--no-lazy-fetch` only on `cat-file`.
- `derive` reads no `$`; it stays pure.
- R8'/R10' match T034 word for word; parity through the fixture.

## Don'ts
- Untouchable: `tests/fixtures.ts`, `tests/board_parity.ts`, `hooks/gfx.tsx`, `hooks/wait.ts`, `hooks/hooks.json`, `.claude-plugin/plugin.json` (T032 bumps it), everything outside `plugins/delix-board/`, every existing test line.
- If derive's output and the fixture's `expected` disagree, do not change either: write `NEEDS_CONTEXT`, name the field and stop.
- No new dependencies.

## Report contract
`.delix/report.md` (≤ 1–2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · the commands and their output · the timing ratios · the screenshot path · PR number and branch · assumptions · remaining work. Read only this card and the spec sections named above.

## Review findings (filled by the lead)
- (none yet)
