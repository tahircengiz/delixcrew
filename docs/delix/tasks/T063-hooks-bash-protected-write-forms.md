# T063 🔐 — Hooks: bash_gate's protected-path write check sees the write forms it did not see (K374)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T063 | S | 3 | backend | 32 | open |

**🔐 Approved:** 2026-11-21 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is protected (`docs/delix/delix.json:11`). The lead adds the Approved line after the
> user's item-specific yes in chat and commits it to main before the session starts; the session branches from that
> commit.
> - **K374, private until merged (K378):** `SECURITY.md` asks for private reporting, so this public card names no write
>   form. The exact replacement text (W1), the test file, the case table and the PR body are in the private brief that
>   the dispatch prompt carries below its public part. If the prompt has no `## Private brief (K374)` section, stop
>   with `NEEDS_CONTEXT`.
> - The lead filled the base SHA and the sha256s at dispatch from its prototype. If a placeholder is left in this card
>   or in the brief, stop with `NEEDS_CONTEXT`; the `<…>` fields of the brief's PR body are yours to fill from your own
>   run.

**Goal (1 sentence):** In a card worktree, the protected-path write check of `scripts/bash_gate.py` (lines 118–123)
also denies the write forms it did not see; commands that write no protected path stay allowed (cases in the brief).
· **Spec:** none (size S; gate 1 is this card's approval). STATUS §15 K374, K376 (scope: the whole check, lines
118–123), K377 (advisory after the release), K378 (private brief), K379 (lead measurements).

**Docs/site:** none in this card. CHANGELOG, the version and any README or site line go with the release card that
follows this one.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (W1: lines 118–120 of the check at 118–123; nothing else)
- Create: `tests/redirect_gate_tests.sh`
- Test: no existing test file changes.

## Interfaces
- **Consumed, unchanged:**
  - `common.matches(path, patterns, cwd) -> str | None` (`scripts/common.py:331-339`): folded given path first, then
    the folded real path; a path it cannot resolve matches `patterns[0]` (fail closed).
  - `common.deny(reason)` (`scripts/common.py:23-28`).
- **Produced:**
  - The deny message stays byte for byte:
    `delixcrew: the command writes to a protected path ('<target>' ~ <pattern>). Tier 3 path; human approval required.`
  - `<target>` is the word as W1 strips it.
- **Rule order in `bash_gate.py`:** unchanged. The check stays after `cfg` / `protected` (lines 113–116) and before the
  T041 push rule (line 125 on the base, 139 after W1).

## Global Constraints
- Python 3.9 standard library only; no new import (`re` is already imported), no new dependency, no signature change.
- Every new pattern is linear; the test's growth section measures it (t(160000) < 3 s and t(160000)/t(20000) < 20 per
  case, as `tests/ref_gate_tests.sh:126`).
- New lines are ASCII; at most 120 characters per added line in `scripts/` (121 in the diff, with its `+`).
- The suites run on Python 3.9.6 and on the 3.13 shim; CI runs 3.12.

## Edit anchors (base main `2e8a09a`, full SHA `2e8a09a22fb3bce6d08b7751e3584d08303c56bd`)
- `scripts/bash_gate.py` has 820 lines on the base; base sha256 is
  `fef73bf2d136995c7d08f0938368ac91f2a1315feb2aeb3b2a85c7f66d3d4d96`.
- **W1 · lines 118–120 · replace** (3 lines with 18 since fix round 3; lines 121–123 stay). The exact current and new
  text is in the private brief. Match the quoted current text before you edit; if it differs, stop with
  `NEEDS_CONTEXT`.
- The file then has 835 lines.
- Use the Edit tool, because the hook denies shell writes to protected paths.

**Lead prototype (round 4, 2026-11-24; on the PR head `2e9d442` and on main `ec5e7e4`; Python 3.9.6 and 3.13.13, git
2.54.0):** an independent applier of W1 and the brief's test file gives these sha256 prefixes (16 hex); compare yours
with `shasum -a 256 <file>`, and if one differs, find the anchor before you go on.

| file | base | round 1 | round 2 | round 3 | after (round 4) |
|---|---|---|---|---|---|
| `scripts/bash_gate.py` | `fef73bf2d136995c` | `7abc33a7cd15f2f3` | `b779aebe862d9953` | `715f9d099a6ed74e` | `36060c331bd01685` |
| `tests/redirect_gate_tests.sh` | (new) | `289e6b62c80d54b2` | `f29f3acff2676ec8` | `ca4d5bb4997c76ec` | `8a391097400e9156` |

On that copy the new test gave 49 `✘` / 51 `✔` on the base code (last line `FAILED`, exit 1), 1 `✘` / 99 `✔` on the
round-3 code, and 100 `✔`, 0 `✘` with W1. All 21 test files of the branch exit 0 on 3.9.6 and on the 3.13 shim
(1756 `✔`, 0 `✘`; the 20 files of the base: 1656 `✔`). On main `ec5e7e4` with W1, all 22 files exit 0 on both
(1790 `✔`, 0 `✘`).

## Steps
1. Baseline: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → 20 files, exit 0.
2. Write `tests/redirect_gate_tests.sh` from the brief with the Write tool and run it on the base code. You should see
   **red**: 49 `✘` / 51 `✔` (round 4; round 3: 49 / 50; round 2: 49 / 49; round 1: 42 / 46), last line `FAILED`, exit 1. Write the
   counts in the report.
3. Apply W1 with the Edit tool. `python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" scripts/bash_gate.py`
   prints nothing.
4. You should see **green**. Then run every suite on Python 3.9.6 and on the 3.13 shim.
5. Write the Verification output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output,
   `[exit <code>]`. That file stays local (`.delix/` is excluded).
6. Commit and push:
   - Run `git add scripts/bash_gate.py tests/redirect_gate_tests.sh` in a call of its own.
   - Commit `T063: bash_gate korunan yol kontrolü görmediği yazım biçimlerini de reddeder (K374)` in a call of its own.
   - Run `git push -u origin HEAD` alone, from the worktree root.
   - Write the PR body with the Write tool and open the PR with `--body-file`; the title is the commit subject. The body
     is the brief's PR body, with the counts filled in.

## Verification command → expected output
- `bash tests/redirect_gate_tests.sh` → 100 `✔`, no `✘`, last line `ALL PASSED`, exit 0.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, 21 files, no `✘`. Run it on 3.9.6 and through
  `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`.
- `claude plugin validate .` → exit 0.
- `git diff --numstat origin/main...HEAD` → exactly `18	3	scripts/bash_gate.py` and `166	0	tests/redirect_gate_tests.sh`.
- `git diff -U0 origin/main...HEAD -- scripts | grep -c '^@@'` → `1` (one hunk: W1 only).
- Added lines longer than 121 characters: `git diff -U0 origin/main...HEAD -- scripts | python3 -c "import sys; [print(len(l), l[:60]) for l in sys.stdin.read().splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"` → no output.
- Non-ASCII bytes: `python3 -c "import sys; d=open(sys.argv[1],'rb').read(); print(sum(1 for b in d if b > 126 or (b < 32 and b not in (9, 10))))" tests/redirect_gate_tests.sh` → `0`.

## Review Focus
- **Cases:** every row of the brief's case table is a case in the test, deny or allow as the table says; the forms the
  check saw before keep their deny (section 3 of the test).
- **Stay allowed:** the brief's allow rows (sections 4–6), and the allow rows of the existing suites.
- **Linear:** the growth section (7) passes for every case, and so does every existing growth case.
- **Deliberate over-denial (fail closed):** the brief lists it; qa checks that the test pins only what the table says.
- **Not in this card (README friction class, K220):** split quotes, variables and globs; the brief lists the rest.
- **Message:** unchanged, byte for byte; the test compares it with `grep -F`.

## Don'ts
- Untouchable:
  - `scripts/common.py`, `scripts/write_gate.py`, `scripts/stop_gate.py`, `scripts/trust.py`, `hooks/hooks.json`,
    `.github/**`, `docs/delix/**` (STATE.json too), `plugins/**`;
  - `README.md`, `README.tr.md`, `CHANGELOG.md`, `SECURITY.md`, `site/**`, `skills/**`, `agents/**`, `templates/**`;
  - every existing test file; every line of `bash_gate.py` outside W1.
- Change no signature and no message. Add no option, no dependency and no import.
- No write form from the brief and no test case name goes into the commit message, the PR title or the PR body (K374);
  the report is local.
- If a test looks wrong, stop with `NEEDS_CONTEXT`.

## Out of scope (each with the reason)
- Docs: the CHANGELOG line, the version and any README or site sentence go with the release card after this card
  merges.
- A GitHub Security Advisory: the user publishes it after the release (K377); the lead drafts it.

## Report contract
`.delix/report.md` (at most 1K tokens) holds:
- the status token;
- the red and green counts;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version` (3.9.6 and 3.13) and `git --version`;
- the PR number in the `**PR:**` line, and the branch;
- assumptions;
- every hook denial of your own commands.

Do not write STATE.json. Read only this card and the dispatch prompt's private brief.

## Review findings (filled by the lead)
- **Round 1** (PR #98, branch `claude/intelligent-turing-e8fdd2` @ `7a04c8931c435eac43584017f495910599848611`, 2026-11-21):
  - Deterministic gates:
    - both files equal the lead's prototype byte for byte (sha256 `7abc33a7cd15f2f3`, `289e6b62c80d54b2`); numstat
      `15 3` and `154 0`, one hunk under `scripts`;
    - the new test is red on the base code (42 `✘` / 46 `✔`) and green with W1 (88 `✔`); the Stop gate
      (`.delix/test-result.txt`) ends `[exit 0]` with no `✘`; CI `check` and `test` pass;
    - the lead's run on a `git archive` of the head: 21 files, 1744 `✔`, 0 `✘` on 3.9.6 and on the 3.13 shim.
  - Protected path `scripts/bash_gate.py` touched (Tier 3, the 🔐 Approved line is on the card); no existing test file
    changed.
  - qa: ACCEPT. No findings.
  - security: 🔐 HUMAN_APPROVAL. One Low finding: the word list still misses a few spellings of the same class. The base
    misses them too, so this is not a regression. The lead reproduced them on the base and on the branch. The forms are
    in the lead's private notes (K378).
    - Unsure (P2, no fix): each distinct word after the three commands costs one path lookup (linear; lead measured
      80000 words in 5.8 s; the Bash hook fails closed on its timeout).
- **Round 2 decision** (2026-11-22, user in chat: "Evet, 2. tur"; K380): the security Low finding is fixed in this
  PR; the P2 stays a note.
  - The lead prototyped the fix on the PR head.
  - W1 grows to 17 lines: the word list after the three commands now also reads past the characters that did not end
    the command.
  - The test gets 7 deny rows, 1 allow row and 2 growth cases (98 cases).
  - The lead's differential run (600000 commands, K381) shows that the fix denies every command the base denies. Growth
    stays linear.
  - The exact edits go to the implementer session in a private message (K378).
- **Round 2** (PR #98 @ `6446d24351622ffc8bd39ae7f9ee06eeddc91b6b`, 2026-11-22):
  - Deterministic gates:
    - both files equal the lead's round-2 prototype byte for byte (`b779aebe862d9953`, `f29f3acff2676ec8`); numstat
      `17 3` and `164 0`, one hunk under `scripts`;
    - the new test is red on the round-1 code (7 `✘` / 91 `✔`) and green with W1 (98 `✔`); the Stop gate ends
      `[exit 0]` with no `✘`; CI `check` and `test` pass;
    - the lead's run on a `git archive` of the head: 21 files, 1754 `✔`, 0 `✘` on 3.9.6 and on the 3.13 shim.
  - qa: ACCEPT. No findings.
  - security: 🔐 HUMAN_APPROVAL. One Medium finding: the substitution part added in round 2 reads a backslash unlike
    the rest of the pattern, so one class of input costs quadratic time. It is not a bypass: the Bash hook fails closed
    on its 60 s timeout. It breaks this card's linear constraint, and the round-2 growth cases did not cover it.
    - The lead reproduced it on the head: ×4 time per doubled length (K382).
    - The fix the reviewer proposed reads a backslash the same way inside and outside the substitution. The lead
      measured it as linear: ×2 per doubling.
    - Medium asks for a fix: fix round 2 adds that change and one growth case. The exact text is in the private notes
      (K378).
- **Round 3** (PR #98 @ `2e9d442d684cf4b4d9c073547dbb7fff9a8ae2f6`, 2026-11-24):
  - Deterministic gates:
    - both files equal the lead's round-3 prototype byte for byte (`715f9d099a6ed74e`, `ca4d5bb4997c76ec`); numstat
      `17 3` and `165 0`, one hunk under `scripts`;
    - the new test is red on the round-2 code (1 `✘` / 98 `✔`) and green with W1 (99 `✔`); the Stop gate ends
      `[exit 0]` with no `✘`; CI `check` and `test` pass;
    - the lead's run on a `git archive` of the head: 21 files, 1755 `✔`, 0 `✘` on 3.9.6 and on the 3.13 shim.
  - qa: ACCEPT. No findings.
  - security: 🔐 HUMAN_APPROVAL. One Medium finding: the quote scan inside the substitution part and the rest of the
    pattern still disagree on two more classes of input, so their time grows quadratically. It is not a bypass: the
    Bash hook fails closed on its 60 s timeout. It breaks this card's linear constraint.
    - The lead reproduced both on the head: ×3.7–3.8 time per doubled length. Round 2, round 1 and the base are linear
      on them (K383).
    - Medium asks for a fix. Fix round 3 is the last one the round cap allows (`max_review_rounds` 3).
    - The lead's fix drops the quote scan inside the substitution. The substitution now ends at its first closing
      parenthesis, so its inner scan is one character class with no alternation, linear by construction (K384). One
      growth case pins it. The exact text is in the private notes (K378).
- **Round 4** (PR #98 @ `923e7454653579f163dac5e86caef0743193aecf`, 2026-11-24):
  - Deterministic gates:
    - both files equal the lead's round-4 prototype byte for byte (`36060c331bd01685`, `8a391097400e9156`); numstat
      `18 3` and `166 0`, one hunk under `scripts`;
    - the new test is red on the round-3 code (1 `✘` / 99 `✔`) and green with W1 (100 `✔`); the Stop gate ends
      `[exit 0]` with no `✘`; CI `check` and `test` pass;
    - the lead's run on a `git archive` of the head: 21 files, 1756 `✔`, 0 `✘` on 3.9.6 and on the 3.13 shim.
  - qa: ACCEPT. No findings.
  - security: 🔐 HUMAN_APPROVAL for the protected path. No finding at any severity. The lead ran its two "unsure"
    items:
    - a second spelling of the known loss of K384; the base misses it too, so it is not a regression (private
      notes);
    - pre-existing and outside this card: a target with very many path parts costs super-linear time in the shared
      path check. It costs the same on the base and the head (40000 parts: 0.27 s; ×21–30 per ×8), and the hook fails
      closed on its timeout. It stays in the lead's private note for the maintainer's decision (K418).
  - Gate 2: the user merges with `--match-head-commit 923e7454653579f163dac5e86caef0743193aecf`.
