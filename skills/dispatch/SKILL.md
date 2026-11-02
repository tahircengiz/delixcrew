---
name: dispatch
description: Splits the approved spec into task cards and dispatches them. Has the architect subagent write the cards and the wave plan, runs the conflict check, updates docs/delix/tasks and STATE.json, produces a dispatch prompt per card and explains how to open the implementer sessions (at most 3 in parallel). Use after gate 1, when the user says "dispatch", "split into tasks", or "/delix:dispatch".
argument-hint: [spec-path]
---

You are the `delix` orchestrator; in this step **you split and dispatch, you write no code**. Spec: $ARGUMENTS (default
`docs/delix/SPEC.md`). If the spec header lacks `approved (gate 1`, stop and route to `/delix:spec` (for size S an
approved card is enough).

## 1. Have the cards written
Size S with an approved card from `/delix:start`: skip this step (the card is the plan; put it into `STATE.json`
as a single wave and go to step 2). Otherwise `Agent` with `delix:architect`: the SPEC path, `docs/delix/delix.json` (protected paths, test paths, max parallel), "job B:
task card production". Write every card in the output to `docs/delix/tasks/T<nnn>-<slug>.md` (all fields of
`templates/task-card.md`; if a field is missing, ask the architect again, do not fill it with your own guess). Put
`## Wave plan` into `STATE.json.waves`, the cards into `STATE.json.cards` (status `open`, rounds 0).

## 2. Conflict and tier check
- Same file in two cards? Merge them or sequence them (separate waves). `Agent` with the architect, "job C".
- Is every card's tier consistent with `protected_paths`; mark Tier 3 cards with 🔐, they run in an **interactive**
  session with the user's security approval.
- Are the test and protected paths in every card's Files list compatible with the gate: appending to an existing test
  file and writing a protected path are allowed only when the path is written explicitly in backticks under Files
  (an exact path, not a glob). For Tier 3 cards the line `**🔐 Approved:** <YYYY-MM-DD> <who>` after the header table
  is written only after the user's explicit "yes" in chat and committed to main (the worktree branches from that
  commit); on an unapproved card the hook rejects the protected path.
- At most `max_parallel` (default 3) cards per wave; the rest go to the next wave.

## 3. Dispatch prompts
For every card fill `${CLAUDE_PLUGIN_ROOT}/templates/dispatch.md` and write it to `docs/delix/tasks/T<nnn>.dispatch.md`:
place in the plan, card path, interface decisions from earlier cards, resolved ambiguities. **No session history and no
full plan is passed.**

## 4. Open the sessions (in wave order)
One line per card for the user: card, role, tier, how to open it.
- **Claude Desktop (Code tab):** if the `start_session` tool exists, `use_worktree: true`, `context: fresh`, prompt =
  the dispatch file content; `initiation: user_asked` only when the user asked in this chat to open the sessions,
  otherwise (and always when this orchestrator was itself started by another session, where the app refuses a start)
  `initiation: own_initiative`: a card the user starts with one click. For Tier 3 cards always the card, the user opens
  the session (under their eyes). Desktop names the worktree branch itself (e.g. `claude/<random>`), not
  `worktree-delix-T<nnn>`: take the branch from the implementer's report and do not look it up by name.
- **Terminal:** Tier 1–2:
  `claude -p --worktree delix-T<nnn> --plugin-dir <plugin root> --permission-mode auto --max-turns 60 --max-budget-usd <budget> "$(cat docs/delix/tasks/T<nnn>.dispatch.md)"`;
  Tier 3: `claude -w delix-T<nnn> --plugin-dir <plugin root> --permission-mode auto` interactively. `--plugin-dir` is
  needed only when the plugin is not installed permanently (otherwise the implementer cannot find the `implement` skill
  and the hooks). `--bare` is not used. Fix round (headless card): not `--resume`, a new session in the same worktree
  (measured, A2: 0.44 vs 1.11 USD, both green):
  `cd <worktree> && claude -p --permission-mode auto --max-budget-usd <budget> --output-format json "$(cat <root>/docs/delix/tasks/T<nnn>.dispatch.md)
  Fix round <n>: the card is already implemented and committed (<sha>); fix only the P0/P1s below. ## Review findings
  <finding text, verbatim from the card's section on main> ## Diff summary $(git diff <default_branch>...<branch> --stat)"`.
  `total_cost_usd`, `num_turns`, `duration_ms` from the result JSON go into the metrics.
- The worktree branches from the default branch; if a card's dependency is not merged yet, work interface-first.
  **Caution:** `claude -p --worktree` may not branch from the current local `main` (in T009 it opened one commit behind,
  the implementer fast-forwarded). Do not dispatch before committing the card; write "base: <main SHA>" in the dispatch,
  or open the worktree yourself with `git worktree add .claude/worktrees/delix-T<nnn> -b worktree-delix-T<nnn> main` and
  run `cd` + `claude -p`.
For every opened card, `STATE.json` status → `in_progress`.

## 5. Wait and collect
When an implementer session finishes, `.delix/report.md` and a PR arrive; `STATE.json` status → `in_review`, then
`/delix:review`. While waiting the orchestrator **writes no code and does not do the card itself** (it pollutes the
context and skips the review).

Reply in the user's language; keep status values, verdict tokens and labels as written.
