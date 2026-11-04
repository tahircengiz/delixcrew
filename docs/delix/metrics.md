# delix metrics

## Self-feeding feedback (SPEC `docs/delix/archive/0.5.0-self-feeding/SPEC.md`, closed 2026-11-03, 0.5.0)

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

## Self-feeding feedback rev 3 (drift follow-up, closed 2026-11-03; archive `docs/delix/archive/0.5.0-self-feeding/`)

Source: `STATE.json`, `gh pr view` (createdAt → mergedAt), session transcripts (`message.usage`, deduplicated by
message id). Session cost in USD: not measured; eval spend is the implementer's `claude plugin eval` report.

| card | tier | PR | review rounds | PR open → merge | implementer tokens (out / cache read / cache write) | eval spend |
|---|---|---|---|---|---|---|
| T008 feedback.py rev 3 | 3 | #20 | 1 (0 findings in the change) | 26 min | 25K / 3.1M / 125K (8 min session) | — |
| T009 discriminating eval | 2 | #21 | 2 (security FIX: 1 High, 2 Medium) | 25 min | 52K / 11.0M / 176K (23 min, both rounds) | 2.03 USD (cap 6) |

Orchestrator session (start, spec, dispatch, reviews, close): output 89K, cache read 17.6M, cache write 248K tokens
(2 transcript files). Subagent tokens (architect ×3, security ×4, qa ×3, claude-code-guide ×1): not measured.

**Gates and interventions** (counted by hand from this session's user turns):
- `AskUserQuestion` calls: 3 (1 grill question, gate 1, one call with 🔐 T008 + eval budget + push).
- Gates: 1 spec + 1 🔐 card approval + 1 budget + 1 push + 2 merges = 6.
- Interventions outside gates: 3 ("start both", "give the merge command", one failed merge from a short SHA in my
  command) → 1.5 per card (target ≤ 5).

**Eval discrimination:** `feedback-file-approval` with 1.00 / without 0.50 (pass rate 1.00 / 0.00); before rev 3:
1.00 / 1.00.

## Triage 0.6.0 (closed 2026-11-03; SPEC `docs/delix/archive/0.6.0-triage/SPEC.md`, cards T010–T015)

Source: `STATE.json`, `gh pr view` (createdAt → mergedAt), the orchestrator transcript (`message.usage`, deduplicated
by message id). Session cost in USD: not measured. Implementer and subagent tokens: not measured.

| card | tier | PR | review rounds | PR open → merge | note |
|---|---|---|---|---|---|
| T010 triage.py | 3 | #24 | 6 | 76 min | same class (mention/HTML) found in three forms, then invisible characters; K131–K133 |
| T011 hook rules | 3 | #23 | 2 | 32 min | security Medium (case-insensitive write gate) |
| T012 skill + job D + start §1a | 3 | #22 | 2 | 94 min | security 2 Medium (HASH spoof line, input checks); waited for T010 |
| T014 invisible hardening | 3 | #28 | 1 | 10 min | split off by K132 |
| T013 docs, CI, 0.6.0 | 3 | #27 | 1 | 13 min | merged last |

Orchestrator session (spec, dispatch, reviews, close): output 244K, cache read 59.1M, cache write 622K tokens
(250 assistant messages, both context windows).

**Gates and interventions** (counted from this session's transcript, not estimated):
- `AskUserQuestion` calls: 8 (grill 6, gate 1, 🔐 T010–T013).
- Typed user messages: 13. Gates among them: 🔐 T014 (1), round-cap decisions (3: "Son tur", "Dar bir tur daha",
  "merge + T014"). Merges (5) ran in the user's own terminal and are not counted as messages.
- Interventions outside gates: 9 (push approvals ×6, "Açık kalsın", two "close if done" questions) → 1.8 per card
  (target ≤ 5). The T014 approval message also approved a push; it is counted once, as a gate. Messages the user sent through the parent session (allowlist
  decision K133, merge relays) are not counted here.

**No single-session baseline** exists for this feature.

## Feedback temizliği (closed 2026-11-04; SPEC `docs/delix/archive/0.6.x-feedback-cleanup/SPEC.md`, cards T016–T019)

Source: `STATE.json`, `gh pr view` (createdAt → mergedAt), the session transcripts (`message.usage`, summed per
assistant message, not deduplicated). Session cost in USD: not measured.

| card | tier | PR | review rounds | PR open → merge | implementer tokens (out / cache read / cache write) | note |
|---|---|---|---|---|---|---|
| T016 feedback.py URL allowlist | 3 | #33 | 3 (4 review passes) | 627 min (merge waited overnight) | 232K / 22.7M / 477K | F1–F4, G1–G2, H1–H2; every round found a new plain-text host form |
| T017 write_gate casefold | 3 | #32 | 0 | 13 min | 27K / 3.7M / 209K | |
| T019 CI runs all tests | 3 | #37 | 0 | 23 min | 15K / 3.6M / 161K | added during review (K149) |
| T018 README + CHANGELOG | 1 | #38 | 0 | 12 min | 30K / 5.4M / 268K | |

Lead session (spec, dispatch, reviews, close, both context windows): output 423K, cache read 85.6M, cache write 1.74M.
Subagents (18: scout, architect, qa, security): output 821K, cache read 13.9M, cache write 2.95M.

**Gates and interventions** (counted from the lead transcript, not estimated):
- `AskUserQuestion` calls: 4. These were grill 1, gate 1, 🔐 T016+T017 with push, and 🔐 T019 with push.
- Button and typed replies: 10. Gates among them were 4 merge approvals (the merges themselves ran in the user's terminal) and 1 push approval.
- Interventions outside gates: 3 ("İkisini başlat", "Evet, T019 ekle", "Başlat"), plus the grill answer, which makes 4 → 1.0 per card (target ≤ 5).

**No single-session baseline** exists for this feature.

## Feedback süzgeci kalan açıklar (closed 2026-11-04; SPEC `docs/delix/SPEC.md`, cards T020–T021)

Source: `STATE.json`, `gh pr view` (createdAt → mergedAt), the session transcripts (`message.usage`, summed per
assistant message, not deduplicated). Session cost in USD: not measured.

| card | tier | PR | review rounds | PR open → merge | implementer tokens (out / cache read / cache write) | note |
|---|---|---|---|---|---|---|
| T020 feedback.py filter gaps | 3 | #39 | 3 (4 review passes) | 129 min | 237K / 30.0M / 505K | round 1 deterministic (CI growth test red, K163 wrong, K173); round 2 security 1 Medium + 3 Low; round 3 4 Low; final pass 1 Low on both trees (§6, K176) |
| T021 README + CHANGELOG | 1 | #43 | 0 | 10 min | 32K / 6.1M / 245K | 1 P2 (validate LISTING_URL_SCHEME warning) |

Lead session (start, spec, dispatch, reviews, close; two context windows): output 406K, cache read 69.9M, cache write
1.05M. Subagents (11: scout, architect, qa, security): output 576K, cache read 10.7M, cache write 2.03M.

**Gates and interventions** (counted from the lead transcript and this conversation, not estimated):
- `AskUserQuestion` calls: 6 (grill 3, gate 1, 🔐 T020 with push, round-3 decision).
- Gates: gate 1, 🔐 T020, round-3 decision (cap), 2 merges (run in the user's own terminal).
- Interventions outside gates: grill answers 3, push approvals 3, "merge komutunu ver" 1, implementer card starts 2
  → 9, 4.5 per card (target ≤ 5). The start request came from the parent session and is not counted.

**No single-session baseline** exists for this feature.
