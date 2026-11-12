# T038 — delix-board panel: the same K277 rules and one safe-read helper

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T038 | M | 2 | frontend | 11 | open |

> Tier 2: everything is under `plugins/delix-board/`. There is no visual change, so no design-token or screenshot step. T032 ships it as 0.1.5.

**Goal (1 sentence):** The panel follows T037's R-G6, R-G7 and R8'' word for word, and every file `readSnapshot` reads (root STATE, `previous`, metrics, cards, `.delix/card`, report, test-result, and derive's files) goes through one helper that checks every path part. · **Spec:** `docs/delix/specs/C-board-visibility.md` §4 (git row, calls 3, 6, 7), §6 (last paragraph), REQ-3, REQ-6; K262, K276, K277

**Docs/site:** none (T032).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `plugins/delix-board/hooks/data.ts`
- Modify: `plugins/delix-board/hooks/parse.ts`
- Test: `plugins/delix-board/tests/board.test.tsx`: **one existing line changes (line 678)**; everything else is insertion.

## Edit anchors (base 4ae458c)
- **`hooks/data.ts`:**
  - Line 140 `const trusted = stdout(await git(top, ['--no-lazy-fetch', 'cat-file', 'blob', …`: insert `'--no-replace-objects'` after `'--no-lazy-fetch'`.
  - Line 156 `const ct = stdout(await git(tree.path, ['log', '-1', '--format=%ct', '--', STATE]))?.trim() ?? ''`: insert `'--no-show-signature'` after `'-1'`.
  - Before line 64: a new `safeStat($, base, rel)`.
  - `readIfChanged` (lines 64–81) becomes `readIfChanged($, cache, base, rel, parse)` built on `safeStat`; its `mtimeMs` parameter goes.
  - Callers move to `(base, rel)`:
    - line 111 (`top`, `'docs/delix/delix.json'`);
    - lines 207–213 (`add`: the stat on 209–210 goes; it calls `readIfChanged($, texts, path, rel, t => t)`);
    - lines 249 and 256 (`root`, `docs/delix/STATE.json` and `docs/delix/metrics.md`);
    - line 255 (`root`, `state.previous`);
    - line 261 (`root`, `` `docs/delix/tasks/${f.name}` ``, keeping `file: path`);
    - line 273 (`tree.path`, `.delix/card`);
    - lines 283–284 (`tree.path`, `.delix/report.md` and `.delix/test-result.txt`).
- **`hooks/parse.ts`:** after line 633 `  const trustedState = ((): Json => {`, insert `    if (!refs.has('refs/remotes/origin/HEAD')) return {}` (`refs` is built on line 482). The comment on line 632 names K277.
- **`tests/board.test.tsx`:**
  - **Changed line 678:** the expected argv becomes `[[...K263, '--no-lazy-fetch', '--no-replace-objects', 'cat-file', 'blob', 'refs/remotes/origin/HEAD:docs/delix/STATE.json']]`.
  - Insert before line 45 `    if (text === undefined) throw missing(e.path)`: `    if (text === undefined && Object.keys(files).some(p => p.startsWith(e.path + '/'))) return { value: { kind: 'dir', size: 0, mtimeMs: 1, isLink: false } }`
  - Insert before line 331 `    if (file === undefined) throw missing(e.path)`: `    if (file === undefined && [...disk.keys()].some(p => p.startsWith(e.path + '/'))) return { value: { kind: 'dir', size: 0, mtimeMs: 1, isLink: false } }`
  - Insert after line 415 `      ['refs/remotes/origin/t002', sha('5'), '', '', '1799999000'],`: `      ['refs/remotes/origin/HEAD', sha('1'), '', '', '1799999000'],`
  - Insert after line 533 `      refLine('refs/heads/done-1', hex('7'), '', '', '1799999000'),`: `      refLine('refs/remotes/origin/HEAD', hex('1'), '', '', '1799999000'),`
  - New tests go after line 692 (the file's last line).
  - Why: the two fakes must answer `dir` for directory paths, or the part walk turns every test red. The two raws without `origin/HEAD` would turn red under R8''.

## Rules
- R-G6, R-G7 and R8'' exactly as in T037:
  - **R-G6:** call 6 is `log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`.
  - **R-G7:** call 7 is `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`.
  - **R8'':** T is `{}` when the refs parsed from call 3 have no key `refs/remotes/origin/HEAD`, whatever `trusted_state` holds. Otherwise R8' applies unchanged.
- **S1, `safeStat` → `{path, mtimeMs} | null`:**
  - Path check: `rel` is not `''`, does not start with `/`, and has no part `''`, `.` or `..`.
  - Every part below `base` stats as `kind === 'dir' && isLink === false`.
  - The last part stats as `kind === 'file' && isLink === false && size <= MAX_FILE_BYTES`.
  - Any throw gives null.
- **`readIfChanged`:** `safeStat` first (on null, delete the cache entry and return null), then the mtime cache, then `$.fs.read`. A text longer than `MAX_FILE_BYTES` is dropped.
- **Remaining risk, to be named in the report:** `$` has no open-by-handle API, so a swap between the last stat and the read stays open. The length check bounds what is kept, not what is read.

## Interfaces
- Consumed: the fixture pair, unchanged (see T037).
- Produced: R8'', parity through the shared tests.

## Global Constraints (verbatim from the spec)
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262)."
- §6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz."
- `derive` reads no `$`.

## Steps
1. Make the insertions and the line-678 change, then add the tests. Run `claude plugin test plugins/delix-board` and see the new tests **red**.
2. Implement in `data.ts` and `parse.ts` only.
3. Run again and see **green**.
4. Find the `$.fs.stat` type or doc for `isLink` (the `claude-code` module that the test runner resolves) and quote it in the report.
5. Commit `T038: delix-board K277: call 6/7 flags, no origin/HEAD = nothing trusted, safe reads on every path part`. Open a PR with `## How I tested`.

## Tests (each red first)
1. Pure: the PARITY raw with the `refs/remotes/origin/HEAD` line removed equals `derive({...PARITY.raw, trusted_state: '{"cards":{}}'})`. The same holds with that line renamed to `refs/heads/refs/remotes/origin/HEAD`.
2. One look: at least one argv contains `log`, and every `log` argv contains `--no-show-signature`.
3. The `spy` stat override marks `/r/.claude/worktrees/lead-c/docs/delix/specs` as `isLink: true`. Expect `/Spec C: board visibility/` absent and `/ · claude\/lead-c · - · açık 7/` present (as at lines 617–618).
4. lead-c's STATE gets `previous` `'../outside/STATE.json'`, then `'/outside/STATE.json'`. Expect: no `fs.stat` or `fs.read` path contains `/../` or equals `/outside/STATE.json`. Record the paths with a local wrapper like `spy` on line 480.
5. Stat override: root STATE `isLink: true`, one task card `size: 2097152`, one `.delix/test-result.txt` `kind: 'fifo'`. Expect: none of these paths appears in `fs.read`.

## Verification command → expected output
- `claude plugin test plugins/delix-board` → all pass, 0 fail
- `claude plugin validate plugins/delix-board` and `claude plugin validate .` → pass
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0 (includes the fixture `cmp`)
- `git diff origin/main -- plugins/delix-board/tests/board.test.tsx | grep -c '^-[^-]'` → `1` (line 678)
- `git diff --stat origin/main` → only the 3 Files

The Stop gate runs only the `delix.json` commands; write the `claude plugin test` output under `.delix/evidence/` and name the file in the report.

## Review Focus
- The `isLink` semantics have evidence (a typings quote), else the report says `unverified`.
- The `chooseRoot` tests (lines 247–289) still pass through the `dir` fakes.
- Flag positions as in T037.
- The cache keys are unchanged (`join(base, rel)`).

## Don'ts
- Untouchable: `tests/fixtures.ts`, `tests/board_parity.ts`, `hooks/views.tsx`, `hooks/gfx.tsx`, `hooks/wait.ts` (its reads on lines 95–97 and 118 are not in K277; name them in the report), `hooks/hooks.json`, `.claude-plugin/plugin.json`, everything outside `plugins/delix-board/`.
- No existing test line other than 678 changes.
- If derive and the fixture disagree, write `NEEDS_CONTEXT`. No new dependencies.

## Report contract
`.delix/report.md` (≤ 2K tokens):
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- commands and output, and the `isLink` evidence;
- PR number and branch;
- the residual race and the `wait.ts` reads;
- assumptions.

Read only this card and spec §4 and §6.

## Review findings (filled by the lead)
- (none yet)
