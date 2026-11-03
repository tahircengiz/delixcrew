---
name: status
description: Shows the current state of delix work. From docs/delix/STATE.json, the task cards and the .delix/report.md files in implementer worktrees it prints the wave · card · role · tier · status · rounds · PR · cost · last report · pending gate (🔐, merge) table into the chat; on request (`--write`) regenerates docs/delix/BOARD.md. Read-only, writes no code. Use when the user says "status", "board", "how are the cards", "which card is waiting", or "/delixcrew:status".
allowed-tools: Bash(python3 *board.py*)
---

You are the `delix` orchestrator; this step is **read-only**: no code, no card or STATE changes, no sessions.
The table below was produced by `${CLAUDE_PLUGIN_ROOT}/scripts/board.py` in this project's root; no file was written.
If the user says "write it to a file" / "BOARD.md" / "Obsidian", run again with `--write` (`docs/delix/BOARD.md`; it must
be in the project `.gitignore`, never committed).

## Board

!`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/board.py"`

## What you do

1. Print the table **as is** into the chat (no skipped rows, no reformatting). If it says "No cards" at the top, say only
   this: there is no delix work in this project or no cards have been dispatched yet; start with `/delixcrew:start <request>`,
   dispatch with `/delixcrew:dispatch`. No file searching, no script writing.
2. Below the table at most 3 lines of comment: the **pending gates** (🔐 = Tier 3 card, needs an interactive session
   under the user's eyes and security approval; `merge` = gate 2, a human merges the PR; `needs_context` / `blocked` =
   the implementer report is waiting for help, `/delixcrew:review <card>` or more context on the card) and what is next. If a
   "Verifications" table exists (`/delixcrew:verify`, card-less work): `FIX` rows wait for the user's fix, `🔐` asks for
   approval in chat; count these inside the same 3 lines.
3. If the table is not above (e.g. `!` commands disabled), run the command yourself:
   `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/board.py"` (in the project root). Use no other tool.

The cost column comes from `STATE.json.cost_usd`; `/delixcrew:close` fills it, when empty "not measured" is correct, never
estimate. Worktrees are found with `git worktree list`; the mapping is the `.delix/card` content or `T<nnn>` in the
branch name. Reply in the user's language; keep the table verbatim.
