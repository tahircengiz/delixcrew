# delix metrics

## Self-feeding feedback (SPEC `docs/delix/SPEC.md`, closed 2026-11-03, 0.5.0)

Source: `STATE.json`, `gh pr view` (createdAt → mergedAt), session transcripts (`~/.claude/projects/…/*.jsonl`,
`message.usage`, deduplicated by message id). Cost in USD: not measured (no `/usage` per session; tokens are given
instead, not converted to money).

| card | tier | PR | review rounds | PR open → merge | implementer tokens (out / cache read / cache write) |
|---|---|---|---|---|---|
| T001 feedback.py | 3 | #6 | 1 | 20 min | 161K / 22.4M / 390K (worktree transcript, 3 files) |
| T002 hook rules | 3 | #4 | 4 (cap 3, 4th approved by the user) | 48 min | 54K / 9.2M / 143K |
| T003 skills | 3 | #5 | 0 | 69 min (waited for T002) | 25K / 2.8M / 95K |
| T004 forms, CI, 0.5.0 | 3 | #18 | 0 | 13 min | not measured (transcript not found) |
| T005 docs | 1 | #19 | 2 (1 scope gap from the orchestrator, 1 qa P1) | 13 min | not measured (transcript not found) |

Orchestrator session (spec, dispatch, all reviews and subagents' hand-backs): 10:38 → 12:52 (2 h 14 min);
output 192K, cache read 49.2M, cache write 541K tokens. Subagent (qa, security, architect) tokens are not included:
not measured.

**Gates and interventions** (orchestrator transcript, counted by hand from user messages):
- User messages after the task: 14. `AskUserQuestion` calls: 6 (4 grill questions, gate 1, issue #7 scope + channel).
- Gates: 1 spec (gate 1) + 2 🔐 card approvals (T001–T003 together, T004) + 4 merge approvals (T002, T003, T004+T005;
  T001's merge was reported) = 7.
- Interventions outside gates: 8 (commit, start review, T002 escalation decision, merge command, push ×3, start
  close) → 1.6 per card (target ≤ 5). Messages the user sent to other sessions (merge relays, T005 scope) are not
  counted here.

**Cache / cost notes:** not measured beyond the token counts above. No single-session baseline exists for this
feature.
