# T014 — 🔐 triage.py: harden the K133 invisible-character allowlist

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T014 | S | 3 | backend | 2 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (the path that publishes comments on a public repo). The orchestrator adds the Approved line after the human says "yes".

**Goal (1 sentence):** Close the hidden channels left open in T010 round 6 (conjoining Hangul jamo, U+1D159, trailing spaces) and add the direct tests qa asked for. · **Spec:** `docs/delix/SPEC.md#REQ-5`, §6 (the user sees the comment exactly); T010 card K132/K133, Round 6

## Files (line numbers against f805e17 = main 556189f)
- Modify: `scripts/triage.py`
  - lines 51–53: extend the K133 comment, add `0x1D159` to `INVISIBLE_IN_ALLOWED`, and add `INVISIBLE_RANGES = ((0x1160, 0x11FF), (0xD7B0, 0xD7FF))` (both ends inclusive).
  - lines 285–287 `visible()`: a character in `INVISIBLE_RANGES` is not visible.
  - `build()`: insert after line 329 (the `invisible character` check), before line 330 (`if OPAQUE_RE…`): `if any(line != line.rstrip() for line in comment.split("\n")): reasons.append("trailing space before a line break")`.
- Test: `tests/triage_tests.sh`: insert new lines only, after line 346 and before line 347 (`blocked "zero-width char again"`). Line 347 has to stay the last record-17 write, because line 354 expects record 17 to be BLOCKED. Do not change any existing line.

## Interfaces
- Produced: a new BLOCKED reason with exactly this text: `trailing space before a line break` (exit 4, no `HASH:` line). Items 1 and 2 reuse `invisible character`.
- Unchanged: CLI, exit codes, `SANITIZER_VERSION`, the hash formula, `feedback.sanitize`. Comments that are CLEAN today keep their HASH; the existing H12/H15/H16 assertions stay green.

## Global Constraints (from the spec and T010)
- K133: the allowlist stays. The check runs on `NFKC(raw)` and on the sanitized `comment` (`scripts/triage.py:328`); one selector only after a visible `So` character.
- Trailing-space rule: `comment` = `sanitize("\n".join(parts))` (`:312-319`) and the published text is `comment + "\n\n" + marker` (`:402`), so every line of `comment`, the last one included, is followed by a line break. BLOCKED when any line ends in a whitespace character (`str.isspace`). NFKC has already turned NBSP and other Zs into U+0020. A space between words stays CLEAN; a line of only spaces is BLOCKED.
- Stdlib only, no new regex (linear check). `feedback.py` stays untouched (K115).

## Steps
1. Insert these tests before line 347 with the existing `blocked`/`clean` helpers (`:286-290`, `:330-332`); write code points with `chr()`.
   - `blocked … invisible`: `"a"+chr(0x11a8)+"b"`; `"x"+chr(0x1161)*8`; `"x"+chr(0xd7b0)+"y"`; `"x"+chr(0x1d159)+"y"`; `"a"+chr(0x115f)+"b"`; `"a"+chr(0x1160)+"b"`; `"a"+chr(0xffa0)+"b"`; questions `d["decision"]="needs-info"; d["questions"]=["Which"+chr(0x11a8)+" OS?"]`; questions `["Which"+chr(0x3164)+"OS?"]`.
   - `blocked … "trailing space"`: `"a  \nb"`; `"a \nb"`; `"a\n \nb"`; `"Done. "`; questions `["Which OS? "]` with `needs-info`.
   - `clean`: `chr(0xd55c)+chr(0xad6d)+" text"`; `chr(0x1100)+chr(0x1161)+" text"` (NFKC composes it to U+AC00); `"a b\nc d"`.
   - Run, see **red** for the jamo, U+1D159 and trailing-space tests (the U+115F/U+1160/U+FFA0/U+3164 tests pin current behaviour and are already green).
2. Implement only the three edits in Files.
3. Green: `bash tests/triage_tests.sh`, then the full loop.
4. Commit `T014: block conjoining jamo, U+1D159 and trailing spaces in triage comments`; PR body has "## How I tested" (open it with `--body-file`).

## Verification command → expected output
- `bash tests/triage_tests.sh` → every line ✔ (17 new), last line `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → every script `ALL PASSED`
- `python3 -c 'import sys;sys.path.insert(0,"scripts");import triage as t;print(t.invisible("a"+chr(0x11a8)+"b"),t.invisible("x"+chr(0x1161)*8),t.invisible(chr(0xd55c)+chr(0xad6d)),t.invisible(chr(0x1d159)))'` → `True True False True`
- `git diff origin/main -- tests/triage_tests.sh | grep -c '^-[^-]'` → `0`; `git diff --stat origin/main -- scripts/feedback.py` → empty

## Review Focus
- Ranges are inclusive. U+115F stays in the set (outside the range). U+D7C7–D7CA and U+D7FC–D7FF are Cn and already blocked.
- The trailing check covers the last comment line, lines inside `reason`, and `Questions:` items; placeholders add no spaces.
- `invisible()` stays linear (round 6: 200k characters in 0.037 s).
- Note only: archaic Hangul sequences that do not compose under NFKC are now BLOCKED (fails closed; spec note at close with the K133 note on combining marks, keycaps, ZWJ).

## Don'ts
- Untouchable: `scripts/feedback.py`, hooks (`scripts/*_gate.py`, `hooks/**`), `README*`, `CHANGELOG.md`, `.claude-plugin/**`, `.github/**`, `docs/delix/**`.
- `show`/`index` input cleaning is out of scope; do not touch `Cleaner` (`:72-84`).
- Do not edit existing test lines; inserts only. Test looks wrong: `NEEDS_CONTEXT`. No network.

## Report contract
`.delix/report.md` (≤ 1.5K tokens): status · commands + output (number of ✔ lines) · PR number · assumptions. Read only this card, SPEC REQ-5 and §6.
