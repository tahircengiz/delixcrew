# Verification — read-json-hardening (2026-11-04)

| input | sha | base | tier | verdict | cost |
|---|---|---|---|---|---|
| branch `claude/youthful-burnell-67b620` | 3197caa | e2a82db | 2 | ACCEPT | not measured |

Request / acceptance criteria source: brief from the session that started this one (the #34–#36 lead,
local_c2b9b2bb, 2026-11-04), saved for the reviewers as `delix-verify-read-json-hardening/request.md` in the workspace
(not in the repo) · Patch: `docs/delix/verifications/2026-11-04-read-json-hardening.patch` · Files touched: 3 (🔐: none)

Mode: single session + `/delixcrew:verify` (size S, Tier 2, well described; K43). Origin: the Low finding in the PR #49
security review. Base is `merge-base origin/main 3197caa` (the local `main` ref was behind `origin/main`). The archive
comes from `git archive 3197caa`, not from the worktree.

History: pass 1 ran on 0a7d020 (gates PASS, qa ACCEPT, security CLEAN). Under "unsure", security asked whether a record
nested just under the parser's limit parses and then crashes on the way back out. The lead measured it: Python 3.9.6
parses 993 levels and writes them back, but Python 3.13.13 parses 9,997 levels and `write_json` raises `RecursionError`
(queue record nested 2,000 levels: `drop F900` rc 1 on base). That broke "deeply nested is an invalid record" on 3.12+
(CI runs 3.12), so no report was written for 0a7d020. 3197caa adds a 32-level depth limit (red first: 2 checks) and
catches `ValueError` from `os.open` again (the old `open()` call had it). This report is pass 2, on 3197caa.

## Deterministic gates
| gate | command | result | evidence (last lines) |
|---|---|---|---|
| gitleaks (diff) | `gitleaks git -c .gitleaks.toml --log-opts=e2a82db..3197caa --no-banner` | PASS | 2 commits scanned · no leaks found |
| gitleaks (archive) | `gitleaks dir archive/ -c .gitleaks.toml --no-banner` | pre-existing finding 1 (also on base) | `evals/secret-refusal/prompt.md:7`, generic-api-key; same finding in the e2a82db archive; not in this patch (eval fixture) |
| local tests | `for t in tests/*_tests.sh; do bash "$t" \|\| exit 1; done` (in `archive/`, Python 3.9.6) | PASS (rc 0) | 8/8 PASS · board 15 · feedback 95 · hook 140 · sanitize 223 · site 23 · triage 158 · trust 14 · write_gate_case 8 ✔, 0 ✘ |
| extra check | `claude plugin validate .` (in `archive/`) | PASS (rc 0) | `✔ Validation passed with warnings`; 1 warning + 2 plugin directory warnings (root `CLAUDE.md`, no icon, `http://127.1/` in README), all on base too |
| remote isolated unit | — | not run: no delix.json.verify | — |
| full suite | — | not run: no --full | — |
| path check | `git diff --name-status e2a82db 3197caa` | PASS | `M scripts/feedback.py`, `M tests/feedback_tests.sh`, `M tests/triage_tests.sh`; removed or changed test lines: 0 |

Extra evidence (outside the gates, recorded by the session that did the work):
- Red first, against e2a82db's code with the new tests: triage 10 ✘ (rc 1 `RecursionError`, rc 124 FIFO timeout, padded
  record accepted), feedback 7 ✘; after 0a7d020, the 500-level record: feedback 2 ✘ (listed as valid, `drop` rewrote it).
- Python 3.13.13 via a PATH shim, on 3197caa's tree: feedback 95 ✔, triage 158 ✔, sanitize 223 ✔, 0 ✘.
- Python 3.13.13, a queue record nested 2,000 levels: base `list` rc 0 (listed), `drop F900` rc 1 `RecursionError`;
  3197caa `list` rc 0 (unreadable), `drop F900` rc 2 `error: unknown id F900`.
- `read_json` edge cases (Python 3.9.6): exactly 1 MiB parses, 1 byte more is `None`; `/dev/zero` symlink, a directory,
  a file without read permission and a FIFO kept open by a writer that sends `{}` are all `None` in under 0.01 s;
  3,000 calls leak 0 file descriptors.
- `json.loads` of a 1,048,575-digit number: 7.50 s on Python 3.9.6 (no `int_max_str_digits` limit in that patch
  release), `ValueError` at once on 3.13.13; 262,144 digits: 0.48 s on 3.9.6.

## Findings
### qa — ACCEPT
```
ACCEPT

No P0 or P1 findings.

Checked against the request:
- **Deep, FIFO and oversized files:** /scripts/feedback.py `read_json` (archive/scripts/feedback.py:126-148) now opens with O_NONBLOCK, so a FIFO cannot block. It then checks that the file is regular (fstat) and at most 1 MiB, reads at most 1 MiB, and walks the parsed JSON with an explicit stack to reject nesting past 32 levels. `RecursionError` and `MemoryError` are caught, and `os.close` runs in `finally`.
- **Callers:** `read_json` has these callers, and each handles `None`:
  - `load_config` (feedback.py:172): a non-dict result gives `enabled: no`.
  - `load_records` (feedback.py:191): a non-dict result goes into the `bad` list, which gives the "unreadable record" warning and the `BLOCKED` verdict.
  - `plugin_meta` (feedback.py:204): a non-dict result gives `{}`.
  - `triage.load_record` (triage.py:287): `validate(None, ...)` gives an invalid record, so `not_accepted` still returns exit 8 with the expected line and empty stdout, and `preview` returns `BLOCKED: invalid record` with exit 4.
- **Other open/load calls:** every other `json.load` and `open` in feedback.py and triage.py reads stdin or `gh` output, or writes. They are not record-file read paths. `board.py` has its own `read_json` and the request does not name it.
- **Tests:** the diff only adds lines. `gates.txt` reports 0 removed or changed test lines, and the paths in the "do not touch" list are untouched.
  - The new cases are a deep-JSON file, a FIFO and a padded file in both `feedback_tests.sh` and `triage_tests.sh`. They also cover a FIFO `config.json`, a record nested 500 levels, and exit codes 0, 2, 4 and 8.
  - A 5 s `guard` makes a hang fail the test instead of blocking the suite.
- **Gates:** the full test loop passes and `claude plugin validate .` passes with warnings that the diff did not introduce. I did not reproduce the red-first step.

Notes:
- [P2] gates.txt:12-13 · The archive-wide gitleaks scan reports 1 leak, while the diff-only scan is clean. I could not see which file it hit. The `documentationUrl "http://127.1/`" warning from the validator suggests it is in the README and predates this change. Confirm it is not in a file this change touched.
- Not verified: the 32-level cap and the 1 MiB cap apply to every `read_json` caller. Current files are far below both, so there is no regression today.
```
Lead note on the P2: the finding is `evals/secret-refusal/prompt.md:7` (generic-api-key, eval fixture), identical on
e2a82db, not in a touched file (gate table above).

### security — CLEAN
```
CLEAN

The change is clean. I found nothing I could show to be a vulnerability, no protected path was touched, and none of the new rejection cases fails open.

**Scope:** base e2a82db to 3197caa. Changed files: `scripts/feedback.py`, `tests/feedback_tests.sh`, `tests/triage_tests.sh`. None of them is in `protected_paths` (`scripts/common.py`, `write_gate.py`, `bash_gate.py`, `stop_gate.py`, `.github/**` and the rest are untouched). No dependency files changed and no CI or deploy files changed.

## Findings
None at Critical, High, Medium or Low.

## Checklist
1. **Secrets:** none in the diff (see scanners below).
2. **Identity and authorization:** not affected. A `read_json` that returns None still fails closed at every caller:
   - `load_config` gives `enabled: False` with no terms, so add and send are off. In `feedback.py:171`.
   - `load_records` puts the file in the `bad` list, and preview is BLOCKED with exit 4. In `feedback.py:180`.
   - `plugin_meta` returns `{}`, so `repo_ok` is False and apply is refused with exit 7. In `feedback.py:203` and `:769`.
   - In triage, `load_record` gives None. `prepare` then prints "BLOCKED: invalid record" with exit 4, and `not_accepted` keeps the plain stderr line with exit 8 and empty stdout. In `triage.py:282`, `:339` and `:138`.
3. **Input validation, `read_json` in `feedback.py:126-148`:**
   - Open with `O_NONBLOCK` and check `fstat` for S_ISREG on the same fd, so there is no TOCTOU window between the check and the read.
   - A FIFO, a symlink to a FIFO, a directory or a char device (for example `/dev/zero`, which used to read without end) is rejected before any read.
   - The read is capped at JSON_MAX+1, which also bounds files that report st_size 0, such as procfs.
   - The fd is closed exactly once: `closefd=False` plus `finally: os.close(fd)`.
   - RecursionError and MemoryError are caught.
   - `_shallow` walks with an explicit stack, so it is linear and never recurses.
   - The 1 MiB and 32-level limits are far above what the tool writes itself (TEXT_MAX, REASON_MAX and QUESTIONS_MAX are bounded, and records are 3 levels deep), so no legitimate file becomes unreadable.
   - Write paths stay safe: `drop` on an unreadable record says "unknown id" and leaves the file unchanged (tested), and `add` allocates new ids with O_EXCL.
4. **Dependencies:** none changed, and no new import (S_ISREG is done with a mask).
5. **CI and deploy surface:** not touched.
6. **Protected paths:** none touched, so no approval mark is needed.

**Tests:** the new tests stay inside `mktemp -d`, with `HOME`, `DELIXCREW_FEEDBACK_DIR` and `DELIXCREW_TRIAGE_DIR` all pointing there. Their `rm -f` and `mkfifo` never reach the user's real queue. The 5 s `guard` turns a hang into a failed test (rc 124) instead of stalling the suite. Gates show 0 removed or changed test lines and every suite passing.

## Unsure about
- **Size cap in characters:** `f.read(JSON_MAX + 1)` counts characters, not bytes. If a file grows between `fstat` and `read`, up to about 4 MiB of UTF-8 could be read. It stays bounded, so this is negligible.
- **Large integers:** the "never a hang" claim relies on Python's `int_max_str_digits` (default 4300 on 3.11+, which raises ValueError right away). With `PYTHONINTMAXSTRDIGITS=0`, or a Python older than that limit, 1 MiB of digits costs a lot of CPU time in `json.loads`. I could not run python3 here (the role is limited to scanners), so the installed Python version is not verified.
- **Opening tty devices:** `os.open` is called without `O_NOCTTY`, so a tty device at the record path is opened before it is rejected. This was already true of `open()`, and only the same user can place such a file.
- **Outside this diff, already on main:**
  - `scripts/board.py:35` has its own `read_json` for STATE.json. It catches only ValueError, with no FIFO or RecursionError handling.
  - `cmd_enable` (`feedback.py:693`) rewrites the config with `extra_terms: []` when `config.json` is unreadable and `--terms` is not given, so the user's terms are silently lost.

  Both are possible follow-ups.

## Scanners and commands
- `gitleaks dir <archive>/scripts/../patch.diff -c <archive>/.gitleaks.toml --redact=100`: no leaks found.
- Gate output for `gitleaks git` over e2a82db..3197caa: 2 commits, no leaks found.
- `gitleaks dir <archive> -c .gitleaks.toml --redact=100 -v`: 1 finding, `generic-api-key` at `evals/secret-refusal/prompt.md:7`. It is not in the diff. The same run on the base tree finds it at the same line, so it predates this change. It is an eval fixture for refusing secrets; the value is redacted and not repeated here.
- missing: semgrep
- missing: pip-audit (no dependency file changed, so not needed)
- missing: trivy
- Read and grep review of `read_json` and all its callers (`load_config`, `load_records`, `plugin_meta`/`repo_ok`, `triage.load_record`/`prepare`/`not_accepted`) and of the direct `json.loads` reads (stdin in `record`/`add`, `gh` output), plus a check of the test sandbox directories.
```
Lead note on "Large integers": measured above. On Python 3.9.6 (the macOS system `python3`), a 1 MiB file of digits
costs 7.50 s before it is refused as not a dict; 3.13 refuses it at once. Bounded, so not a hang; it needs a crafted
file in the user's own 0700 queue. The cap stays at 1 MiB (the largest record the tool can write is about 160 KB); a
smaller cap is a follow-up option.

Pass 1 security, outside the request (Low, already on main): `json.loads(sys.stdin.read())` in `triage.py record`
(`:254-256`) and `feedback.py add` (`:636-639` on 0a7d020) catches only `ValueError`, so deeply nested stdin gives a
`RecursionError` traceback and exit 1 instead of exit 2. Nothing is written (fails closed). A follow-up.

## Not run
- remote isolated unit: no `delix.json.verify` block
- full suite: no `--full`
- semgrep, trivy: missing (security role); pip-audit: not applicable (no dependency file)

## Verdict
**ACCEPT** · every gate that ran is PASS or a pre-existing finding, qa has no P0/P1, security CLEAN · applying is the
user's; after a fix run `/delixcrew:verify claude/youthful-burnell-67b620` again.

Follow-ups (not in this change): `board.py` `read_json` (same gap for `STATE.json`); stdin `RecursionError` in
`record`/`add`; `feedback.py enable` drops `extra_terms` when `config.json` is unreadable; optionally a smaller
`JSON_MAX` for old Python 3.9 patch releases.
