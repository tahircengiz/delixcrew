# T037 — board.py: K277 git hardening 2 (calls 6 and 7, origin/HEAD present) and one safe-read helper

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T037 | M | 2 | backend | 11 | open |

> Tier 2: no protected path (`scripts/board.py` is not in `protected_paths`). This is the board.py half of K277; T038 is the panel half, with the same rules.

**Goal (1 sentence):** board.py reads STATE history without running a signature program, reads the trusted STATE without replace refs, trusts nothing when `refs/remotes/origin/HEAD` is missing from call 3, and reads every file of another worktree through one helper that never follows a link, never blocks and never reads more than 1 MiB. · **Spec:** `docs/delix/specs/C-board-visibility.md` §4 (git row, calls 3, 6, 7), §6 (last paragraph), REQ-3, REQ-6; K262, K276, K277

**Docs/site:** none in this card. T032 (wave 13) lists the new argv. The lead updated spec §4 (rev 8) before dispatch.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/board.py`
- Test: `tests/board_tests.sh`: insertions only, at the four anchors under Tests; no existing line changes.

## Edit anchors (base 4ae458c)
1. Line 251 `            w["state_log_ct"] = _num((_out(["git", "log", "-1", "--format=%ct", "--", STATE_REL], p) or "").strip())`: the argv becomes `["git", "log", "-1", "--no-show-signature", "--format=%ct", "--", STATE_REL]`.
2. Lines 253–254 `    raw["trusted_state"] = _out(["git", "--no-lazy-fetch", "cat-file", "blob",`: insert `"--no-replace-objects",` after `"--no-lazy-fetch",`. The comment on line 252 adds K277.
3. Line 508 `    trusted = _state({"files": {STATE_REL: raw.get("trusted_state")}})  # R8' T: {} unless a JSON object`: T is `{}` when `"refs/remotes/origin/HEAD" not in refs` (`refs` is built on line 503).
4. New `_read_in(base, rel)` after line 163 (`        return None`, the end of `_mtime`), before line 166 `def _add_file(w, wt, rel):`.
5. `_add_file`, lines 166–179: lines 171–177 (realpath, stat, read) are replaced by `text = _read_in(wt, rel)`. The docstring names K277.
6. `collect()`:
   - line 708 `        card = read(os.path.join(path, ".delix", "card"))` becomes `card = _read_in(path, ".delix/card")`;
   - line 717 `        report = read(os.path.join(path, ".delix", "report.md"))` becomes `report = _read_in(path, ".delix/report.md")`.

## Rules (identical text in T038)
- **R-G6:** call 6 is `log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`.
- **R-G7:** call 7 is `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`.
- **R8'':** T is `{}` when the refs parsed from call 3 have no key `refs/remotes/origin/HEAD`, whatever `trusted_state` holds. Otherwise R8' applies unchanged.
- **S1, `_read_in(base, rel) -> str | None`:**
  - Path check: `rel` is a str, not absolute; split on `/`, no part may be `''`, `.` or `..`, and no part may hold a NUL. Otherwise None.
  - Open `base` with `O_RDONLY|O_DIRECTORY`. Links in `base` itself are followed, because it is git's path.
  - Each directory part: `os.open(part, O_RDONLY|O_NOFOLLOW|O_NONBLOCK|getattr(os,"O_DIRECTORY",0), dir_fd=fd)`, then require `S_ISDIR(os.fstat(new).st_mode)`.
  - Last part: `os.open(last, O_RDONLY|O_NOFOLLOW|O_NONBLOCK, dir_fd=fd)`, then require `S_ISREG` and `st_size <= MAX_READ` from `fstat`.
  - Read with `os.read` until EOF; more than `MAX_READ` bytes gives None.
  - Decode as strict UTF-8 (an error gives None), then turn `\r\n` and `\r` into `\n`, as `open()` text mode does today.
  - Close every fd in `finally`. `OSError` and `ValueError` give None.
- **Unchanged:** call order, the 4 + 3N budget, K254, K256, K274, every REQ-4 pattern. The own-root reads in `collect()` (`STATE.json`, task cards) and `delix.json` stay on `read()`, because K277 does not name them.
- **Not chosen:** reading call 7 by call 3's `origin/HEAD` objectname (`cat-file blob <sha>:…`). It costs the same number of calls but changes the §4 argv; K277 chose the derive check.

## Interfaces
- **Consumed:** the fixture pair, unchanged, and no fixture addition. `raw.for_each_ref` on fixture line 11 already holds the 5-field line `refs/remotes/origin/HEAD\ta0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0\t\t\t1762290000`, so `derive(raw) == expected` still holds.
- **Produced:** R8'' (T038 implements the same rule) and `_read_in`.

## Global Constraints (verbatim from the spec)
- §6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz."
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262)."
- §6: "Üçünün ön koşulu paylaşılan `.git`'e (config ya da ref) yazmaktır; … bu sertleştirmeler derinlemesine savunmadır."
- Python 3.9 stdlib only. `os.open(dir_fd=)`, `O_NOFOLLOW` and `O_NONBLOCK` behave the same on 3.9.6 and 3.12/3.13. `O_DIRECTORY` is read through `getattr` and backed by the `S_ISDIR` check. No API depends on the version, but run the tests on both.

## Steps
1. Add the tests and run `bash tests/board_tests.sh`. Each new test is **red** on the base; D3 is red by `AttributeError`.
2. Implement in `scripts/board.py` only.
3. Run again and see **green** with `python3` 3.9.6 and with 3.13 (put a `python3` → `python3.13` symlink first on `PATH`).
4. Commit `T037: board.py K277: call 6 --no-show-signature, call 7 --no-replace-objects, no origin/HEAD = nothing trusted, one safe-read helper`. Open a PR with `## How I tested`.

## Tests (each red first)
- **A**, after line 216 `git -C "$H/f" rm -q docs/delix/delix.json && gc -C "$H/f" commit -q -m "drop delix.json"` and before line 217 `cp "$H/f/docs/delix/STATE.json" …`:
  - **A1 (call 6):**
    1. In `$H/f`, append `\n` to STATE and `git add` it.
    2. Build a commit object: `printf 'tree %s\nparent %s\nauthor t <t@t> 1762000000 +0000\ncommitter t <t@t> 1762000000 +0000\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n x\n -----END PGP SIGNATURE-----\n\nsigned\n' "$(git -C "$H/f" write-tree)" "$(git -C "$H/f" rev-parse HEAD)" | git -C "$H/f" hash-object -t commit -w --stdin`, then `git -C "$H/f" update-ref HEAD <that sha>`.
    3. Set a marker script as `gpg.program` and `log.showSignature true` in the `$H/r` config.
    4. Run `board.py --json` from `$H/f`, then unset both settings.
    5. Expect: the marker does not exist.
    - If `hash-object` rejects the object, add `--literally` and say so in the report.
  - **A2 (call 7):**
    1. `ORIG=$(git -C "$H/r" rev-parse refs/remotes/origin/main)`.
    2. `git -C "$H/r" replace "$ORIG" "$(git -C "$H/f" rev-parse HEAD)"`.
    3. Run from `$H/f`, then `git -C "$H/r" replace -d "$ORIG"`.
    4. Expect: `ready == []` and no merge action. The base shows T001 ready.
- **B**, after line 229 (`PYS`, the end of the "T034 K262: forged STATE gives no merge" check) and before line 230 `# T034 5) …`:
  1. `git -C "$H/r" remote set-head origin -d`.
  2. `git -C "$H/r" update-ref refs/heads/refs/remotes/origin/HEAD "$(git -C "$H/r" rev-parse refs/remotes/origin/main)"`.
  3. Run from `$H/f`.
  4. Restore: delete that ref (`update-ref -d`) and run `remote set-head origin main`.
  5. Expect: `ready == []`, no merge action, and `{"card":"T001","verification":null,"reason":"review not on origin/main"}` in waiting.
- **C**, after line 251 `t5 && ok "T034: a 2 MiB spec is not read" || bad "T034: a 2 MiB spec was read"` and before line 252 `rm -rf "$H"`. Runs from `$H/r` with a 20 s subprocess timeout, like `t5`. Setup: `$H/impl/.delix/card` = `docs/delix/tasks/T001-x.md`.
  - C1: `.delix/report.md` is a symlink to a file outside the worktree holding `**Status:** BLOCKED`. Expect: the T001 row in `cards` has `report_status` null.
  - C2: `report.md` is a FIFO. Expect: exit 0 within the timeout.
  - C3: `.delix/card` is a FIFO (report removed). Expect: exit 0 within the timeout.
- **D**, after line 283 (`PYS`, the end of the "T034: a trusted card without pr" check) and before line 285 `cd /; rm -rf "$T"; …`:
  - D1: the fixture raw with the `refs/remotes/origin/HEAD` line removed from `for_each_ref` gives exactly the result asserted on lines 262–268.
  - D2: that line renamed to `refs/heads/refs/remotes/origin/HEAD` gives the same result.
  - D3: `board._read_in` in a temp dir under `signal.alarm(10)`:

    | Input | Expected |
    |---|---|
    | file holding `a\r\nb` | `"a\nb"` |
    | 1048576 bytes | read |
    | 1048577 bytes | None |
    | FIFO | None |
    | final symlink | None |
    | `ld/f.txt`, with `ld` a link to a dir inside the temp dir | None |
    | `../x`, `/etc/hosts`, `a//b`, `./f`, `""`, a name with a NUL | None |
    | the bytes `\xff` | None |
    | missing file | None |

## Verification command → expected output
- `bash tests/board_tests.sh` → `ALL PASSED`, on 3.9.6 and on 3.13
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `claude plugin validate .` → passes
- `git diff origin/main -- tests/board_tests.sh | grep -c '^-[^-]'` → `0`
- `git diff --quiet origin/main -- tests/fixtures/board_parity.json plugins/delix-board/tests/board_parity.ts` → exit 0
- `grep -cF -- '--no-show-signature' scripts/board.py` → `1`
- `grep -cF -- '--no-replace-objects' scripts/board.py` → `1`
- `git diff --stat origin/main` → only the 2 Files

## Review Focus
- `fstat` is called on the open fd and never `stat` on the path. Every open uses `O_NOFOLLOW|O_NONBLOCK`. No fd leaks on any error path.
- `derive` stays pure; R8'' reads only `refs`.
- `--no-lazy-fetch --no-replace-objects` come before `cat-file`; `--no-show-signature` comes after `log`.
- The existing H-repo Ready test (lines 219–229) still passes. That shows `for-each-ref refs/remotes` lists the `origin/HEAD` symref.

## Don'ts
- Untouchable: the fixture pair, `plugins/**`, `skills/**`, `scripts/common.py` and the other protected paths, and every existing test line.
- If derive's output and `expected` disagree, write `NEEDS_CONTEXT`, name the field and stop. No new dependencies.

## Report contract
`.delix/report.md` (≤ 2K tokens):
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output, `python3 --version` and `git --version`;
- PR number and branch;
- assumptions, including whether `--literally` was needed.

Read only this card and spec §4 and §6.

## Review findings (filled by the lead)
- Round 1 (PR #66, head `be5d89055ae78d8b1b95f182fb6f9cddcf9ce2c4`, 2026-11-12): qa `ACCEPT` (0 findings), security `CLEAN` (0 findings). Lead gates on the clean `git archive` of the head: the 12 shell suites exit 0 on Python 3.9.6 and 3.13.13, `claude plugin validate .` passes, 0 removed test lines, fixture pair unchanged; CI `check` and `test` pass. Red on base reproduced by the lead: the head's `board_tests.sh` against `board.py` of 4ae458c gives the 9 new checks ✘ and the 34 old ✔. Ready for gate 2.
  - Notes, not fixed (security unsure, accepted residuals): R8'' reads call 3 while call 7 resolves the name again (a concurrent `.git` writer between the two; the card's "Not chosen" keeps it); the last open runs before `fstat`, so a device node would reach its driver's `open` (needs root); calls 4–6 still run without `--no-lazy-fetch` in a treeless partial clone (not reproduced, outside K277).
