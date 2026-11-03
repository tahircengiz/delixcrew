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
- Round 1 (2026-11-03; qa ACCEPT, security 🔐 HUMAN_APPROVAL with Lows; orchestrator integration check). Fix:
  - [P1, orchestrator, reproduced] `scripts/bash_gate.py` rule (a)/(b): the whole command string is matched, including heredoc bodies. T003's skills capture drafts as `python3 "<root>/scripts/feedback.py" add <<'EOF' {json} EOF`; a draft whose text contains the word `send` or `script` (any finding about the send step) is denied. Reproduced at 0852d9b: command `python3 "/x/scripts/feedback.py" add <<'EOF'` + JSON with title `preview hash differs on second send` → deny. Fix: match rules (a)–(c) against the command with heredoc bodies removed (text after the first line containing `<<` up to the delimiter), or require `send` to be the subcommand after `feedback.py` while keeping `cd scripts && python3 feedback.py send …` and the pty-wrapper cases denied. Add an allow test for exactly this heredoc `add` with `send` and `script` in the body, and keep all existing deny tests.
  - [Medium, security unsure, orchestrator verified: `gh issue new --help` prints "Create an issue on GitHub"] rule (c) misses the `gh issue new` alias of `create`. Fix: add `new` to the alternation; add a deny test `gh issue new -R tahircengiz/delixcrew -t x`.
- Round 1 notes (Low, no fix required; follow-up candidates): case-insensitive FS lets `~/.claude/DelixCrew/Feedback/config.json` bypass the write-gate queue check (`write_gate.py:41-43`); Bash redirects into the queue dir are not denied outside a card (spec gap, K77 residual); `gh issue -R … create` (flag before subcommand) and `gh api graphql` createIssue are not matched (K77 residual).
- Round 2 (2026-11-03, re-review of 1197842; qa REJECT, security FIX). Fix:
  - [P1/Medium, regression, orchestrator reproduced: denied at 0852d9b, allowed at 1197842] `scripts/bash_gate.py:21-24`: rule (b) runs on `no_heredoc`, which strips every heredoc body whatever command receives it, so a pty wrapper inside a heredoc passes both rules. Allowed now: (1) `python3 - <<'EOF'` / `import pty; pty.spawn(["python3","scripts/feedback.py","send","F001"])` / `EOF`; (2) `script -q /dev/null bash <<'EOF'` / `python3 scripts/feedback.py "send" F001` / `EOF`; (3) `echo '<<X'` + newline + `script -q /dev/null python3 scripts/feedback.py "send" F001` (the `|\Z` branch strips to the end). Fix: strip a heredoc body only when that heredoc's opening line runs `feedback.py … add`; drop the `|\Z` alternative; widen rule (a) to a quoted or list-style subcommand (e.g. `\bfeedback\.py['"]?(?:\s*,\s*|\s+)(?:-\S+\s+)*['"]?send\b`). Add deny tests for the three commands; keep the allow test for a heredoc `add` whose body contains `send`/`script`.
  - [P2, qa] rule (a) still matches inside a `feedback.py add` heredoc body: a draft titled "feedback.py send prints wrong hash" is denied. Covered by the same fix (exempt the body of a heredoc whose opening line is `feedback.py … add`); add an allow test.
- Round 3 (2026-11-03, re-review of 148138d; qa REJECT P1, security FIX Medium; both reproduced by the orchestrator, 0 deny at 148138d). Last round (max 3). Fix by **allowlist, not more blocklist**:
  - [P1, qa] unquoted heredoc: `python3 scripts/feedback.py add <<EOF` / `$(python3 scripts/feedback.py send F001 --confirm abc)` / `EOF` is allowed (the shell expands `$(…)` and backticks in an unquoted body); also the backtick form.
  - [Medium, security] the exempt first line accepts `#`, `\`, `'`, `"` between `add` and `<<`: `python3 scripts/feedback.py add # <<EOF` / `script -q /dev/null python3 scripts/feedback.py send F001` / `EOF` is allowed (bash reads a comment, line 2 runs); same with `add \<<EOF` and `add "<<EOF` + newline + `"; …send…`.
  - Required design: strip the body **only** when the whole command (after trimming) fullmatches exactly one capture call: `python3 <path ending in feedback.py, optionally double-quoted> add <<'DELIM'` (or `<<"DELIM"`, quoted delimiter required), newline, body, newline, the same `DELIM` alone on the last line, and nothing after it. Any other shape → rules (a)–(c) run on the full command text. Deny tests: unquoted `<<EOF` + `$(…send…)`, backtick form, `add # <<EOF`, `add \<<EOF`, `add "<<EOF`, a valid quoted add heredoc followed by `; script … feedback.py send …` or a second line after the delimiter. Allow tests: the T003 form `python3 "<root>/scripts/feedback.py" add <<'EOF'` with `send`, `script`, `feedback.py send` and `$(` inside the body. Keep all earlier tests.
  - Not in scope (K77 residual, note only): variable indirection (`f=feedback.py; python3 $f send`), the plain word `expect` over-blocking.
