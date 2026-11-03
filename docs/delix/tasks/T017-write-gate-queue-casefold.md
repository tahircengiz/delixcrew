# T017 — 🔐 write_gate.py: case- and normalization-insensitive queue and triage dir check

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T017 | S | 3 | backend | 1 | open |

> 🔐 Tier 3: `scripts/write_gate.py` is a protected path (`docs/delix/delix.json:10`). The lead adds the Approved line after the human says "yes".

**🔐 Approved:** 2026-11-03 tahircengiz

**Goal (1 sentence):** Deny Write/Edit into the feedback queue and the triage dir whatever the letter case or Unicode normalization of either path. · **Spec:** `docs/delix/SPEC.md#REQ-6`; K129

## Files
- Modify: `scripts/write_gate.py`
- Create: `tests/write_gate_case_tests.sh`

## Edit anchors (base 79ef030; match the content, not only the number)
1. Insert after line 8 `import sys`: `import unicodedata`.
2. Insert after line 10 `from common import REVIEWERS, card_path, delix_json, deny, matches, read_input  # noqa: E402`:
   `def _fold(p):` docstring `REQ-6 (K129): APFS ignores letter case and Unicode normalization; realpath keeps both as given.` body `return unicodedata.normalize("NFD", os.path.realpath(p)).casefold()`.
3. Replace line 18 `    queue = os.path.realpath(os.path.expanduser(os.environ.get("DELIXCREW_FEEDBACK_DIR") or "~/.claude/delixcrew/feedback"))` → `    queue = _fold(os.path.expanduser(os.environ.get("DELIXCREW_FEEDBACK_DIR") or "~/.claude/delixcrew/feedback"))`.
4. Replace line 19 `    target = os.path.realpath(os.path.join(g.get("cwd") or os.getcwd(), os.path.expanduser(_path)))` → `    target = _fold(os.path.join(g.get("cwd") or os.getcwd(), os.path.expanduser(_path)))`.
5. Replace lines 22–26 (the comment starting `    # REQ-7 (0.6.0): same for the triage record dir`, `    triage = os.path.realpath(…)`, `    triage = triage.casefold()`, `    if os.path.commonpath([triage, target.casefold()]) == triage:`) with: a one-line comment `# REQ-7 (0.6.0): same for the triage record dir (triage.py record via Bash is the only writer)`, `    triage = _fold(os.path.expanduser(os.environ.get("DELIXCREW_TRIAGE_DIR") or "~/.claude/delixcrew/triage"))`, `    if os.path.commonpath([triage, target]) == triage:`.
   Lines 20, 21 and 27 (the two `deny` calls) stay unchanged.

## Interfaces
- Unchanged: hook input JSON, exit codes and the exact deny texts `delixcrew: feedback is sent only by the user from their own terminal` / `delixcrew: triage decisions are applied only by the user from their own terminal`.

## Global Constraints (from the spec)
- Both sides of both comparisons use `unicodedata.normalize("NFD", realpath(p)).casefold()`; the deny messages stay the same (REQ-6).
- A neighbouring path (`~/.claude/delixcrew/feedback-notes.md`) is not denied by this rule.
- No new regex. Stdlib only.

## Steps
1. Create `tests/write_gate_case_tests.sh` in the style of `tests/hook_tests.sh:1-13,86-89`: `unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR`; `T=$(mktemp -d)`; cwd `$T/nocard` (no `.delix/card`); `HOME=$T/home`. Build the NFC/NFD strings and the hook JSON with `python3` (`json.dumps`), because macOS `bash` 3.2 has no `$'\u…'`. Pass env vars with `env VAR=…`. Each deny case checks `"permissionDecision": "deny"` plus the exact message:
   1. Write `$T/home/.claude/delixcrew/FEEDBACK/F001.json` → feedback deny
   2. Edit `~/.Claude/DelixCrew/feedback/config.json` (literal `~`) → feedback deny
   3. `DELIXCREW_FEEDBACK_DIR=$T/Masaüstü/fb` (NFC), target `$T/Masaüstü/fb/F001.json` (NFD) → feedback deny
   4. The same with the env value NFD and the target NFC → feedback deny
   5. `DELIXCREW_TRIAGE_DIR=$T/Masaüstü/tq` (NFC), target NFD `…/tq/12.json` → triage deny
   6. `DELIXCREW_TRIAGE_DIR` NFD, target NFC upper case `$T/MASAÜSTÜ/TQ/12.json` → triage deny
   7. Write `~/.claude/delixcrew/feedback-notes.md` → allow (rc 0, no `deny` in the output)
   8. Feedback env NFC `…/fb`, target `$T/Masaüstü/fbx/F001.json` → allow
   Run it and see **red** for cases 1–6 (7–8 pin the current behaviour).
2. Implement edits 1–5.
3. Make it **green**: `bash tests/write_gate_case_tests.sh`, then `bash tests/hook_tests.sh` (lines 102–105, 207–212 and 249–251 stay green), then the full loop.
4. Commit `T017: write_gate compares queue and triage dirs case- and NFD-insensitively`. The PR body has "## How I tested" (`--body-file`).

## Verification command → expected output
- `bash tests/write_gate_case_tests.sh` → 8 ✔ lines, last line `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `git diff --stat origin/main -- tests/hook_tests.sh scripts/common.py scripts/feedback.py` → empty

## Review Focus
- Module-level `target` is used only on lines 19–26; `outside_cwd()` (lines 60–64) has its own `realpath` and stays unchanged.
- `casefold()` can change length (`ß` → `ss`). `commonpath` compares path components, so the lookalike `…/fbx` stays free (case 8).
- On a case-sensitive Linux filesystem, a `FEEDBACK` dir is now denied as well. That is fail closed and accepted by the spec.

## Don'ts
- Do not touch: `scripts/common.py`, `scripts/bash_gate.py`, `scripts/stop_gate.py`, `hooks/hooks.json`, `scripts/feedback.py`, `scripts/triage.py`, every existing `tests/*`, `docs/delix/**`.
- Do not reorder the checks in `write_gate.py` and do not reword any deny text. If a test looks wrong, report `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 1K tokens): status · commands + output · PR number · assumptions. Read only this card and SPEC REQ-6.

## Review findings (filled by the lead)

### Round 0 (2026-11-03, PR #32, dd0f1e5, base f46f006)
- Deterministic gates (lead, from `git archive dd0f1e5`): `bash tests/write_gate_case_tests.sh` 8 ✔ ALL PASSED; full `tests/*_tests.sh` loop exit 0; diff touches only the two Files paths; CI `test` + `check` SUCCESS.
- qa: ACCEPT_WITH_NOTES (P0 0, P1 0). security: 🔐 HUMAN_APPROVAL (no finding; check is a strict superset of the old one, `hooks.json` onFailure block covers crashes; gitleaks clean).
- [P2, no fix] `.github/workflows/tests.yml:20-27` runs only hook/board/feedback/triage tests, so `tests/write_gate_case_tests.sh` (and T016's `tests/sanitize_tests.sh`, `site_tests.sh`, `trust_tests.sh`) never run in CI. Not in this card's Files; follow-up CI card (lead).
- [Note] `casefold(NFD(x))` differs from Unicode canonical caseless match only for rare combining marks in the dir path itself; default path is ASCII.
