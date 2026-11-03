# T002 — 🔐 Hook rules: block the agent's known send paths

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T002 | M | 3 | backend | 1 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (protected hook scripts). The orchestrator adds the Approved line after the human's "yes".

**Goal (1 sentence):** Session-wide deny rules for feedback send paths and for queue-dir writes. · **Spec:** `docs/delix/SPEC.md#REQ-7`

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (insert after line 15 `cwd = …`, before line 21 `if agent in REVIEWERS`)
- Modify: `scripts/write_gate.py` (insert after `g = read_input()`, before the reviewer check)
- Test: `tests/hook_tests.sh` (append only, before the final `rm -rf "$T"` line; existing lines unchanged)

## Interfaces
- Consumed: env `DELIXCREW_FEEDBACK_DIR`, default `~/.claude/delixcrew/feedback` (same resolution as T001; inline it, do not import feedback.py).
- Produced: deny reason, exactly `delixcrew: feedback is sent only by the user from their own terminal`.

## Global Constraints (verbatim from the spec)
- "kart ve `agent_type` kontrolünden **önce**, her oturumda" (before the card and `agent_type` checks, in every session). The three Bash rules are:
  - (a) `feedback.py` together with `send`;
  - (b) `script|expect|unbuffer|pty.spawn` together with `feedback.py`;
  - (c) `gh issue (create|comment|edit)`, or `gh api` + `issues`, when the command contains `delixcrew` or the cwd's git remote is `tahircengiz/delixcrew`.
- `write_gate.py`: deny Write/Edit/MultiEdit into the queue dir in every session. "mevcut kurallar aynen" (existing rules unchanged).

## Steps
1. Append tests in a fresh dir `$T/nocard` (no `.delix/card`):
   - Deny the 3 commands from SPEC REQ-7 "ajan göndermeye çalışır", also with `agent_type: delixcrew:qa` (same message).
   - Deny `gh api repos/tahircengiz/delixcrew/issues -f title=x`.
   - Deny `gh issue create -t x` in a `git init` dir whose remote is `https://github.com/tahircengiz/delixcrew.git` (no network).
   - Allow `gh pr view 12`, `gh issue create -R example/other -t x`, `python3 scripts/feedback.py add < d.json`.
   - Write gate: deny `$HOME/.claude/delixcrew/feedback/config.json` (`HOME=$T/home`) and `$DELIXCREW_FEEDBACK_DIR/F001.json`.
   - Run and see **red**.
2. Implement. Only call `git -C <cwd> remote -v` (timeout 5 s) when the `gh` pattern already matched.
   Use `os.path.realpath` + `commonpath` for the queue-dir check.
3. Green: `bash tests/hook_tests.sh`.
4. Commit `T002: hook rules for feedback send paths`. PR body has "## How I tested".

## Verification command → expected output
`bash tests/hook_tests.sh` → all ✔, last line `ALL PASSED`

## Review Focus
- `\bscript\b` must not match `scripts/feedback.py add` (covered by the allow test).
- The "no python3" loop and every existing deny/allow still pass.
- Known-path coverage only (K77); do not claim full blocking in messages.

## Don'ts
- Untouchable: `scripts/common.py`, `hooks/hooks.json`, `scripts/feedback.py`, `docs/delix/**`, `.github/**`.
- Do not edit existing test lines; append only.
- No network. If a test looks wrong: NEEDS_CONTEXT.

## Report contract
`.delix/report.md` (≤ 2K tokens): status · command + output · PR number · assumptions · remaining work. Read only this card and SPEC REQ-7, §6.

## Review findings (filled by the orchestrator)
