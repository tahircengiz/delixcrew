---
name: close
description: Closes a spec once all its cards are merged: updates STATUS.md and CHANGELOG, collects per-card cost/rounds/cache metrics, runs the spec↔code drift check (architect; EGM drift-report at size L), writes lessons learned to CLAUDE.md/memory only with human approval, cleans up worktrees. Use when the user says "close", "retro", or "/delixcrew:close".
argument-hint: [spec-path]
---

You are the `delix` orchestrator; closing step. Spec: $ARGUMENTS (default `docs/delix/SPEC.md`).

## 1. State
Are all cards in `STATE.json` `accepted`? If not, list them and stop (or, if the user approves leaving them out of scope,
write that to `STATE.json`).

## 2. Metrics (numbers, not claims)
Per card: round count, `cost_usd` (from `/usage` or OTel/ccusage if available; otherwise `not measured`), cache hits
(if available), duration.
For the orchestrator: the **gate count** (spec/card approval, 🔐, merge) and **interventions outside gates** (user
messages − gates; target ≤ 5 per card, spec §10.1). Source: the transcript (`~/.claude/projects/<project>/<session>.jsonl`,
`AskUserQuestion` count and user messages); manual counting is acceptable, estimating is not.
Append the total and, if one exists, the comparison with the "single-session baseline" to `docs/delix/metrics.md`.
Whatever was not measured is written as "not measured".

## 3. Drift check
`Agent` with `delixcrew:architect`: compare the SPEC with the merged code, list unimplemented REQs and behaviour not in the
spec. Size L with EGM: `egm-drift-report`. Findings go to STATUS "Open work".

## 4. Docs and memory
- Update `STATUS.md` (phase, steps, decisions), `CHANGELOG.md`; the affected README section.
- **Propose** lessons learned (traps, patterns); write to `CLAUDE.md`, `.claude/agent-memory` or the memory directory only
  if the user says "yes" (an agent never writes its own output into shared memory automatically).

## 5. Cleanup
List the worktrees of merged cards; `git worktree remove` with the user's approval. `.delix/` files go with the worktree.

## 6. Retro (3 lines)
What went well · what was expensive (rounds, tokens) · which harness part was unnecessary ("remove one component, is it
load-bearing").

**Feedback capture.** Only if one of these happened in this work: (1) a delixcrew hook denied an action and you judged
the denial a false positive; (2) a delixcrew skill step could not be followed as written (the instruction contradicted
the tool's or the repo's behaviour); (3) a manual workaround was needed because of a plugin limit. Then, one draft per
event, pipe `{"kind": "bug|feature", "component": "<skill|hook|script|agent name>", "title", "actual", "expected",
"repro": [...], "context"?}` in generic terms (no project names, paths or secrets) to
`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/feedback.py" add <<'EOF' … EOF`. Exit 0: one line, `Feedback draft F<nnn>: <title>
(/delixcrew:feedback review)`. Exit 3: say nothing. Any other exit: show the script's message in one line. None of the
three events: do not call `add` and say nothing about feedback.

Reply in the user's language; keep status values and labels as written.
