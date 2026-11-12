# T040 — F010: the card's verification output goes to `.delix/evidence/verification.txt` (design B; the Stop gate stays unchanged)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T040 | S | 2 | docs | 12 | open |

> Tier 2 under design B: skill and agent text only. `scripts/stop_gate.py` is not touched, so K213/K218 stay exactly as they are. The user chose design B (K278, 2026-11-12). Dispatch waits for T039's merge (same file `skills/review/SKILL.md`).

**Goal (1 sentence):** The implementer writes the Verification command output to a file the Stop gate never opens, and the review and qa read both files. · **Spec:** feedback draft F010 (the user's local draft, quoted by the lead in the dispatch); `docs/delix/specs/C-board-visibility.md` K278. No REQ: size S, gate 1 is this card plus the user's answer on K278.

**Docs/site:** none.
- README:94 and :148 and site usage:157 already list `.delix/evidence/`.
- site usage:156 ("`test-result.txt`: the Stop hook's test output") becomes exactly true.

**Reach: every reader of `.delix/test-result.txt` at 4ae458c.**
- Changed here: `skills/implement/SKILL.md:36`, `skills/review/SKILL.md:11`, `:14`, `:36`, `agents/qa.md:13`.
- Unchanged, because they describe the gate's own output, which stays:
  - `skills/implement/SKILL.md:40–42`;
  - `scripts/stop_gate.py:4`, `:15`, `:27`, `:47`, `:81`;
  - `tests/hook_tests.sh:106`; `tests/trust_tests.sh:145`, `:148–150`, `:154`, `:178`, `:241–249`;
  - `README.md` and `README.tr.md` `:94`, `:128`, `:148`;
  - `site/index.html` and `site/tr/index.html` `:124`, `:482`, `:483`; `site/usage.html` and `site/tr/usage.html` `:156`;
  - the panel: `plugins/delix-board/hooks/data.ts:279`, `:284`, `hooks/parse.ts:285`, `hooks/views.tsx:517`, `tests/fixtures.ts:90`, `docs/spec/delix-board.md:37`. The panel keeps showing the gate output.
- board.py reads neither file.
- History, unchanged: `CHANGELOG.md:28`, `docs/legal/kontrol-listesi-degerlendirme.md:25`, `:65`, `docs/delix/SPEC.md` (Spec B), `STATUS.md`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `skills/implement/SKILL.md` (lines 36–37)
- Modify: `skills/review/SKILL.md` (lines 11–13, 14, 36–37). Base: main after T039; T039 leaves these lines untouched.
- Modify: `agents/qa.md` (line 13)
- Create: `tests/evidence_tests.sh`

## Edit anchors (each phrase in backticks-in-quotes stays on one physical line; ` / ` marks a line break)
1. Implement, lines 36–37 (`- Write the outputs to `.delix/test-result.txt` (the reviewer reads it). …`) become:
   "- Write the Verification command output to `.delix/evidence/verification.txt` (the reviewer reads it): one block per / command, `$ <command>`, its output, `[exit <code>]`. Never put it in `.delix/test-result.txt`: the Stop gate rewrites / `.delix/test-result.txt` at every stop with the `delix.json` commands only. For ui-ux / template changes a screenshot or / Playwright evidence is mandatory (`.delix/evidence/`)."
2. Review, lines 11–13 become:
   "- Does the card's worktree have `.delix/report.md`, `.delix/test-result.txt` (the Stop gate output) and / `.delix/evidence/verification.txt` (the Verification command output); does the report follow the contract / (`DONE|…|BLOCKED`). …"
   The rest of the sentence is unchanged.
3. Review, line 14 starts "- Does `.delix/evidence/verification.txt` match the card's expected output; …".
4. Review, line 36: "- `delixcrew:qa` — diff path, card path, SPEC path, round count and both test output files / (`.delix/test-result.txt`, `.delix/evidence/verification.txt`). Expected: …".
5. qa.md, line 13: "SPEC.md path, the files holding the test/CI output (`.delix/test-result.txt`, the Stop gate output, and / `.delix/evidence/verification.txt`, the Verification command output), a focus list."

## Interfaces
- Consumed: the Stop gate block format `$ <c>` / output / `[exit n]` (`scripts/stop_gate.py:65`).
- Produced: the project file `.delix/evidence/verification.txt`.

## Global Constraints (verbatim)
- F010 expected: "the implement and review skills both name one file under .delix/evidence/ for the card's verification output".
- K213/K218 untouched: no file under `scripts/` changes.

## Steps
1. Write `tests/evidence_tests.sh` with the `ok`/`bad` and `ALL PASSED` shape of `tests/ledger_tests.sh` and `grep -qF` checks for these phrases:
   - "Write the Verification command output to `.delix/evidence/verification.txt`"
   - "Never put it in `.delix/test-result.txt`"
   - "`.delix/evidence/verification.txt` (the Verification command output)"
   - "Does `.delix/evidence/verification.txt` match the"
   - "(`.delix/test-result.txt`, `.delix/evidence/verification.txt`)"
   - "`.delix/evidence/verification.txt`, the Verification command output"
   - plus `! grep -qF 'Write the outputs to `.delix/test-result.txt`' skills/implement/SKILL.md`.

   Run it and see **red**.
2. Edit the 3 files.
3. Run again and see **green**.
4. Commit `T040: F010 verification output in .delix/evidence/verification.txt`; open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/evidence_tests.sh` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `claude plugin validate .` → passes
- `git diff --stat origin/main` → only the 4 Files
- `git diff origin/main -- scripts | wc -l` → `0`

## Review Focus
- Implement lines 40–42 (`[not run: …]` in `test-result.txt`) are unchanged.
- The reviewer reads both files.
- The format matches the gate's block format.

## Don'ts
- Untouchable: `scripts/**`, `README*`, `site/**`, `plugins/**`, `docs/**`, every existing test file.

## Report contract
`.delix/report.md` (≤ 1K tokens): status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`) · commands and output · PR number and branch · assumptions.

Read only this card.

## Review findings (filled by the lead)
- (none yet)
