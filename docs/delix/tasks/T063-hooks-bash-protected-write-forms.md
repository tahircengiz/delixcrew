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
  T041 push rule (line 125 on the base, 137 after W1).

## Global Constraints
- Python 3.9 standard library only; no new import (`re` is already imported), no new dependency, no signature change.
- Every new pattern is linear; the test's growth section measures it (t(160000) < 3 s and t(160000)/t(20000) < 20 per
  case, as `tests/ref_gate_tests.sh:126`).
- New lines are ASCII; at most 120 characters per added line in `scripts/` (121 in the diff, with its `+`).
- The suites run on Python 3.9.6 and on the 3.13 shim; CI runs 3.12.

## Edit anchors (base main `2e8a09a`, full SHA `2e8a09a22fb3bce6d08b7751e3584d08303c56bd`)
- `scripts/bash_gate.py` has 820 lines on the base; base sha256 is
  `fef73bf2d136995c7d08f0938368ac91f2a1315feb2aeb3b2a85c7f66d3d4d96`.
- **W1 · lines 118–120 · replace** (3 lines with 15; lines 121–123 stay). The exact current and new text is in the
  private brief. Match the quoted current text before you edit; if it differs, stop with `NEEDS_CONTEXT`.
- The file then has 832 lines.
- Use the Edit tool, because the hook denies shell writes to protected paths.

**Lead prototype (2026-11-21, `2e8a09a`, Python 3.9.6 and 3.13.13, git 2.54.0):** an independent applier of W1 and the
brief's test file gives these sha256 prefixes (16 hex); compare yours with `shasum -a 256 <file>`, and if one differs,
find the anchor before you go on.

| file | base | after |
|---|---|---|
| `scripts/bash_gate.py` | `fef73bf2d136995c` | `7abc33a7cd15f2f3` |
| `tests/redirect_gate_tests.sh` | (new) | `289e6b62c80d54b2` |

On that copy the new test gave 42 `✘` / 46 `✔` on the base code (last line `FAILED`, exit 1) and 88 `✔`, 0 `✘` with
W1; all 21 test files exit 0 on 3.9.6 and on the 3.13 shim (1744 `✔`, 0 `✘`; the 20 files of the base: 1656 `✔`).

## Steps
1. Baseline: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → 20 files, exit 0.
2. Write `tests/redirect_gate_tests.sh` from the brief with the Write tool and run it on the base code. You should see
   **red**: 42 `✘` / 46 `✔`, last line `FAILED`, exit 1. Write the counts in the report.
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
- `bash tests/redirect_gate_tests.sh` → 88 `✔`, no `✘`, last line `ALL PASSED`, exit 0.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, 21 files, no `✘`. Run it on 3.9.6 and through
  `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`.
- `claude plugin validate .` → exit 0.
- `git diff --numstat origin/main...HEAD` → exactly `15	3	scripts/bash_gate.py` and `154	0	tests/redirect_gate_tests.sh`.
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
