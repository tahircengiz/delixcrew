# T034 — board.py: trusted ledger from origin/<default>, hardened git calls, safe file reads and list lines

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T034 | M | 2 | backend | 9 | open |

> Tier 2: no protected path. `scripts/board.py` is not in `protected_paths`; `scripts/common.py` is, and this card does not touch it. It changes when the board prints a merge command.

**Goal (1 sentence):** board.py builds Ready to merge, the merge command and the `merged`-based cleanup only from cards that the `origin/<default>` copy of STATE also shows (K262), runs every git call with `--no-optional-locks -c core.fsmonitor=false` and `worktree list -z`, and closes the T029 Lows (K263). · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-3`, `#REQ-4`, `#REQ-6`; §4 (git row, call 7), §6 (K262 paragraph); K262, K263

**Docs/site:** none in this card (T032, wave 10).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/board.py`
- Test: `tests/board_tests.sh` (new tests only, inserted after line 139 and before line 141 `cd /; rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" ...`; no existing line changes)

## Edit anchors (base: the main commit that adds this card; code lines unchanged since e3070ec)
1. `_git` (lines 137–143, `def _git(argv, cwd, timeout=5, codes=(0,)):`): run `["git", "--no-optional-locks", "-c", "core.fsmonitor=false", *argv[1:]]`. Every git call in the file goes through it, including `worktrees()` (lines 56–74, which today calls `subprocess.run(["git", "worktree", "list", "--porcelain"], ...)` itself).
2. New `_worktree_text(root, timeout)`: `worktree list --porcelain -z`; split on NUL; if any field contains `\n` or `\r`, return `""` (the whole list is invalid); otherwise join the fields with `\n`, so the text equals today's porcelain form. Used by `worktrees()` and by `git_raw` line 205 (`for line in (_out(["git", "worktree", "list", "--porcelain"], root, timeout=10) or "").split("\n"):`).
3. `git_raw` (lines 186–189): add `"trusted_state": None` to the initial `raw` dict (before the outside-git `return raw`); after the common-dir call, one call in `root`: `["git", "--no-lazy-fetch", "cat-file", "blob", "refs/remotes/origin/<default>:docs/delix/STATE.json"]` through `_git` (so the two flags come first); stdout or `None`. `--no-lazy-fetch` goes on this call only (as `scripts/trust.py:45`, K223).
4. `_add_file` (lines 158–167): with `real = os.path.realpath(os.path.join(wt, rel))`, read only when `real` starts with `os.path.realpath(wt) + os.sep`, `stat.S_ISREG(os.stat(real).st_mode)` is true and the size is ≤ 1048576 bytes; otherwise leave the file out (never open a FIFO).
5. Line 91 (`pr = int(m.group(1))`): `pr = _num(m.group(1))`.
6. `_pr` line 396: a value that is `0` after `_num` gives `None`.
7. `_queue` (lines 418–456) and `derive` (lines 541–571): rules R8' and R10' below. TR applies to every queue: the source queue and each Leads row's counts.
8. Branch checks at lines 550 and 571 (`_ok(BRANCH_RE, br)`), and every other place a command takes a branch name: a branch named `reset` or `clean` fails the check (note `unsafe name: run by hand`).
9. `git_sections` lines 620, 621 and 624: each value interpolated into a `- ` list line passes through `one_line(cell(x)).strip()`, so no line starts with `-` followed by 4 or more spaces.

## Rules (quote of the decided behaviour; spec rev 5)
- **R1:** `trusted_state` = stdout of call 7 (anchor 3); `None` on any failure. `cat-file blob` runs no textconv or filter.
- **R8':** T = `json.loads(trusted_state)` when it is a JSON object, else `{}`. TR = the set of `(card, pr, sha)` that today's R8 marks Ready on T, with `files = {}` and the same refs. A card that meets every Ready condition in a queue is Ready only if its `(card, pr, sha)` is in TR. Otherwise its reason in that slot (where `ready to merge` would be) is `review not on origin/<default>` (with the actual default branch, e.g. `review not on origin/main`), and it has no Ready entry and no merge action.
- **R10':** the delete_branch action and the `merged` condition of remove_worktree read `status`, `merged` and the R7 branch from T's card with the same id; a card that T lacks gives neither.
- Unchanged: the card table and its pending gate column (K254), every REQ-4 pattern and banned token, K256 (source = own root), no network, no writes, no `gh`.

## Interfaces
- Consumed: raw key `trusted_state` in `tests/fixtures/board_parity.json` (added by the lead; a JSON string: lead-c's STATE plus lead-b's T028). With it, derive must still return the file's `expected` unchanged.
- Produced: `board.py --json` raw gains `trusted_state: str | null`; the new reason `review not on origin/<default>`. T035 implements the same rules in the panel; the fixture is the shared contract.

## Global Constraints (verbatim from the spec)
- §6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz."
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262)." board.py keeps the same order of calls (§4 git row).
- K262: "merge'e hazır, merge komutu ve `merged`'e dayanan temizlik yalnız `origin/<default>` STATE'i aynı kart, PR ve SHA'yı da gösterince".
- Python 3.9 stdlib only (CI runs 3.12; run the tests on both, see Verification).

## Steps
1. Add the tests below to `tests/board_tests.sh` at the anchor; run, see each **red** on the base.
2. Implement in `scripts/board.py` only.
3. Run, see **green** with `python3` (3.9.6 on the Mac) and with Python 3.13 (put a `python3` → `python3.13` symlink first on `PATH` if your machine has 3.13).
4. Commit `T034: board.py trusted ledger from origin/<default>, hardened git, safe reads (K262, K263)`; open a PR with `## How I tested` (commands and output).

## Tests (each red first)
1. Real repo: a card-less worktree `f` with a forged STATE (T001 tier 1, `in_review`, pr 7, `qa` r1 `ACCEPT`, `sha` = the pushed tip of a branch `claude/impl`). `board.py --json` run from `f`: `ready == []`, no merge action, T001 waits with `review not on origin/main`. After committing that STATE on the local origin's main and `git push origin main` (local bare remote), the same run gives `ready == [{T001, 7, tip}]` and the merge command.
2. Pure: the fixture's raw with `trusted_state` set to `'{"cards":{}}'`: `actions == expected.actions[0:6]` (the merge and the three `merged`-based actions are gone), `ready == []`, T029's waiting reason is `review not on origin/main` in the same position, lead-b and lead-c ready counts 0.
3. `core.fsmonitor` in the test repo's config set to a script that touches a marker: after `board.py` runs, the marker does not exist.
4. A worktree whose directory name contains `\n`: `agents == []` and `actions == []`.
5. The spec path a symlink to a file outside the worktree whose heading is `# OUTSIDE`, a Tier 3 open card whose `file` is a FIFO, and a 2 MiB spec: the run ends within a 20 s timeout and `spec_title` is null in each case.
6. A card key `"    touch X"`: no output line matches `^- {4,}`.
7. A branch named `reset`: no push command; its note is `unsafe name: run by hand`.
8. A report line `**PR:** #` followed by 5000 digits: exit 0 under Python 3.13.

## Verification command → expected output
- `bash tests/board_tests.sh` → `ALL PASSED` (with python3 3.9 and with 3.13)
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `claude plugin validate .` → passes
- `git diff origin/main -- tests/board_tests.sh | grep -c '^-[^-]'` → `0`
- `git diff --stat origin/main` → only the 2 Files

## Review Focus
- `derive` stays pure (no subprocess, os, open or clock).
- TR also applies to the Leads counts and to the `merged`-based actions.
- `--no-lazy-fetch` only on the `cat-file` call; no `fetch`, no `gh`; flags come before the subcommand.
- The fixture's `expected` is unchanged and still equals derive's output.

## Don'ts
- Untouchable: the fixture pair (`tests/fixtures/board_parity.json`, `plugins/delix-board/tests/board_parity.ts`), `plugins/**`, `skills/**`, `scripts/common.py` and the other protected paths, every existing test line.
- If derive's output and the fixture's `expected` disagree, do not change either: write `NEEDS_CONTEXT`, name the field and stop.
- No new dependencies.

## Report contract
`.delix/report.md` (≤ 1–2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · the commands and their output · `python3 --version` and `git --version` · PR number and branch · assumptions · remaining work. Read only this card and the spec sections named above.

## Review findings (filled by the lead)
- Round 1 (PR #64, head `e11d52e0e397e50761e1c96117fd7c5098b5d837`, 2026-11-12): qa `REJECT` (P1 1), security `FIX` (Medium 1, Low 1). Gates green: `board_tests.sh` ALL PASSED on 3.9.6 and 3.13, the fixture `cmp`, `claude plugin validate .`.
  - **[P1] K274, REQ-6 parity, `scripts/board.py:548` and `:596`:** TR and the `delete_branch` loop still read the local card worktree through `card_wt`: `_facts` takes `pr` from `.delix/report.md` when T's card has no `pr`, and the branch from the worktree when T has no implementer record. Lead reproduced: T's T029 without `pr` gives a merge 60 action in board.py and none in the panel. Fix: line 548 `_queue(trusted, {}, refs, {})["ready"]` (T alone, no local report or worktree branch); line 596 `_facts(cid, c, refs, {})["branch"]` (parity with the panel; a worktree branch is always checked out, so this changes no reachable output). Test: a pure test where T's T029 has no `pr`: `ready == []`, no merge action, T029 waits with `review not on origin/main`.
  - **[Medium] K276, `scripts/board.py:253-254` (call 7):** the trusted ref's name comes from `default_branch` in the root's `delix.json`, and the root is the untrusted card-less worktree (K256). A worktree that writes `{"default_branch":"claude/f"}`, commits a forged STATE and pushes `claude/f` makes that branch the trusted copy; fetch does not undo it. Fix: call 7 reads `refs/remotes/origin/HEAD:docs/delix/STATE.json` (fails closed when `origin/HEAD` is missing). Test setup: `git -C "$H/r" remote set-head origin main` after the H repo's `push -u origin main`. Test: the redirect above in `f`, `ready == []` and no merge action.
  - **[Low, raised to fix by the lead] K275, `scripts/board.py:235` (call 5):** `git diff --quiet` still runs an external diff helper marked trusted (`diff.external` + `diff.trustExitCode true` in the shared config, or a `.gitattributes` diff driver). Lead reproduced on git 2.54: 1 run, 0 with `--no-ext-diff`. Same class and precondition as the fsmonitor case K263 closes; one flag. Fix: `["git", "diff", "--no-ext-diff", "--quiet", ...]`. Test: a marker script as `diff.external` with `diff.trustExitCode true` never runs.
  - Lead prototype: all three red on the PR head, green with the fix, `ALL PASSED` on 3.9.6 and 3.13.
  - Follow-up, not in this card: [Low] `collect()` reads `.delix/card` and `.delix/report.md` of other worktrees with no realpath, regular-file or size check (a FIFO hangs `/delixcrew:status`; a symlink prints the target's first line); one safe-read helper (`O_NONBLOCK|O_NOFOLLOW`, `fstat`, bounded read). Unsure, recorded in spec §6: `filter.<driver>.clean` through a worktree `.gitattributes`; sessions can push to the default branch.
