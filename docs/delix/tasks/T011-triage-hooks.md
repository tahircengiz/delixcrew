# T011 — 🔐 Hook rules: close the agent's triage write paths

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T011 | M | 3 | backend | 1 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (protected `scripts/bash_gate.py`, `scripts/write_gate.py`). The orchestrator adds the Approved line after the human says "yes".

**Goal (1 sentence):** Session-wide deny rules for triage `apply`, `gh issue`/`gh label`/`gh api` writes and writes into the triage dir. · **Spec:** `docs/delix/SPEC.md#REQ-7`

## Files
- Modify: `scripts/bash_gate.py`: insert a new block after line 41 (end of the feedback `gh` block), before line 43 (`GIT = …`). Lines 17–41 stay byte-identical.
- Modify: `scripts/write_gate.py`: insert after line 21, before line 23 (`agent = …`).
- Test: `tests/hook_tests.sh`: append only, before line 149 (`rm -rf "$T"`).

## Interfaces
- Produced: deny reason exactly `delixcrew: triage decisions are applied only by the user from their own terminal`.
- Consumed: env `DELIXCREW_TRIAGE_DIR` (default `~/.claude/delixcrew/triage`), inlined (do not import `triage.py`); the exempt shape T012 writes: `python3 "<abs path>/scripts/triage.py" record <n> <<'TRIAGE_EOF'`.

## Global Constraints (from the spec)
- Conditions (K125): (a) and (b) are **unconditional**, like feedback (a)/(b) at `scripts/bash_gate.py:29-31`. (c) and (d) apply only when the command contains `delixcrew` or the cwd's git remote is `tahircengiz/delixcrew` (reuse the remote check at `:36-41`; call `git` only after a pattern matched).
- Rules:
  - (a) `\btriage\.py['"]?\s+(?:-\S+\s+)*['"]?apply\b`
  - (b) `script`, `expect`, `unbuffer` or `pty.spawn` together with `triage.py`
  - (c) `\bgh\s+issue\s+(close|reopen|lock|unlock|delete|transfer|pin|unpin|develop)\b`, or `\bgh\s+label\b`
  - (d) `\bgh\s+api\b` with `graphql`, or with a write flag: `-f`, `-F`, `--field`, `--raw-field`, `--input` (also attached forms such as `-fq=x`), `-X`/`--method` with any value other than GET (case-insensitive; `-XPOST`, `--method=PATCH` count).
- Exemption for (a)/(b): run them on the first line only when the whole trimmed command fullmatches the `ADD_HEREDOC` shape (`scripts/bash_gate.py:23-28`) with `triage\.py[ \t]+record[ \t]+\d+` in place of `feedback\.py[ \t]+add`; quoted delimiter not repeated in the body; same non-overlapping classes, no `$` in the path. (c)/(d) always on the full text.
- `write_gate.py`: deny Write/Edit/MultiEdit/NotebookEdit into the triage dir in every session, same `realpath` + `commonpath` approach as lines 14–21.

## Steps
1. Append tests (reuse `fbdeny`-style helpers with the new message, `bashjson`, `hd`, `$N/repo` whose remote is delixcrew, `tests/hook_tests.sh:97`).
   - Deny in `$N/repo`, also with `agent_type: delixcrew:qa`: `gh issue close 12`; `python3 scripts/triage.py apply 12 --confirm abc`; `gh api graphql -f query='mutation{addLabelsToLabelable(x)}'`; `gh label create x`; `gh api repos/x/y/issues/1/labels -X POST`; `--method=PATCH`; `script -q /dev/null python3 scripts/triage.py apply 1`.
   - Deny unconditionally (K125): `python3 scripts/triage.py apply 12 --confirm abc` in `$N` (no remote, no `delixcrew` in the command).
   - Deny the exempt-shape tricks of `tests/hook_tests.sh:121-128` with `triage.py record 12`.
   - Allow: record heredoc whose body says `"does not apply to v0.4, script output"`, path `python3 "/opt/delixcrew/scripts/triage.py"`; `gh issue list` and `gh api repos/x/y/pulls` in `$N/repo`; `gh api repos/x/y/pulls -X GET`; `gh issue close 3` in a repo whose remote is `https://example.com/o/other.git`; `python3 scripts/triage.py show 12`.
   - Write gate: deny writes into `$T/home/.claude/delixcrew/triage/12.json` (`HOME=$T/home`) and into `$DELIXCREW_TRIAGE_DIR/12.json`.
   - ReDoS timing: hook time per probe minus hook time for `ls` < 0.1 s. Probes: 12 × `$aaa…` in the record path, 20k `-a ` after `triage.py`, a 200 KB body, 5k delimiter lines.
   - Run, see **red**.
2. Implement.
3. Green: `bash tests/hook_tests.sh`, all earlier lines still ✔; existing feedback denies keep `FBMSG` (triage block runs after the feedback block, `tests/hook_tests.sh:96`).
4. Commit `T011: hook rules for triage write paths`; PR body has "## How I tested".

## Verification command → expected output
`bash tests/hook_tests.sh` → all ✔, last line `ALL PASSED`; the full loop → all `ALL PASSED`

## Review Focus
- Rule (d) must not catch read-only `gh api` calls (`--jq`, `-H`, `--paginate`). Note: the existing 0.5.0 rule already denies every `gh api … issues` call in delixcrew, read-only included; leave it as is.
- Known residual (K77, note only): `gh issue -R x close` (flag before the subcommand), the list form `["triage.py","apply"]`. TTY + `APPLY <hash>` still stops the `triage.py` path.

## Don'ts
- Untouchable: `scripts/common.py`, `hooks/hooks.json`, `scripts/feedback.py`, `scripts/triage.py`, `docs/delix/**`, `.github/**`.
- Do not edit existing test lines; append only. No network. Test looks wrong: NEEDS_CONTEXT.

## Report contract
`.delix/report.md` (≤ 2K tokens): status · command + output (with timing numbers) · PR number · assumptions. Read only this card and SPEC REQ-7, §6.

## Review findings
### Round 1 (4016a4c) — qa ACCEPT · security 🔐 HUMAN_APPROVAL with 1 Medium → fixing
Deterministic gates: CI `test` pass; from `git archive 4016a4c`: 4× `ALL PASSED`; test file diff 99 insertions, 0 deletions;
`bash_gate.py` lines 17–41 byte-identical.
To fix (round 1):
- [Medium] `scripts/write_gate.py:23-25`: write-gate bypass on a case-insensitive filesystem (APFS default).
  `os.path.realpath` keeps the given letter case, so a Write to `~/.CLAUDE/delixcrew/TRIAGE/12.json` (or
  `.../delixcrew/Triage/...`) fails the `commonpath` check yet lands in the real triage dir. Fix: compare the
  `.casefold()` of both realpaths before `commonpath`, for the triage check only. Test (append): a Write to an
  upper-case variant (`$T/home/.CLAUDE/delixcrew/TRIAGE/12.json` with `HOME=$T/home`, and an upper-cased segment of
  `$DELIXCREW_TRIAGE_DIR`) is denied with the triage message; the `tqx` lookalike allow test stays green.
Noted, no fix:
- Pre-existing (K129, follow-up): the 0.5.0 feedback-queue check (`write_gate.py:18-21`) has the same case flaw.
- [Low] (c)/(d) look at the hook's cwd: a leading `cd <delixcrew checkout> &&` from another project, or GraphQL with an
  opaque node id from a non-delixcrew cwd, passes. Same class as the 0.5.0 rule (K125); residual.
- P2 (qa): the issues-path `-X POST` test asserts deny with the feedback message (rule order); covered separately.
