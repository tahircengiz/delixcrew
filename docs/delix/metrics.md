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

## Feedback süzgeci kalan açıklar (closed 2026-11-04; SPEC `docs/delix/archive/0.6.2-feedback-filter-gaps/SPEC.md`, cards T020–T021)

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

## Triage ve feedback akışında üç düzeltme, #34–#36 (closed 2026-11-04; SPEC `docs/delix/SPEC.md`, cards T023–T024)

Source: `STATE.json`, `gh pr view` (createdAt → mergedAt), the session transcripts (`message.usage`, summed per
assistant message, not deduplicated; only the transcript file each implementer session started, because Desktop
reuses worktree directories). Session cost in USD: not measured.

| card | tier | PR | review rounds | PR open → merge | implementer tokens (out / cache read / cache write) | note |
|---|---|---|---|---|---|---|
| T023 confirm prompt + exit 8 line | 3 | #49 | 0 | 21 min | 176K / 31.6M / 486K (+ 2 subagents 47K / 1.7M / 242K) | the session also ran its own qa/security pass after the PR and opened a side session for the P2 (RecursionError); both are in these numbers |
| T024 bash_gate cross capture | 3 | #48 | 1 | 60 min | 70K / 11.8M / 320K | round 1: security "unsure" note reproduced by the lead (`^` with zsh `extendedglob`, Low); the fix was prototyped before the round and matched byte for byte |

Lead session (status, project status, triage of #34–#36, start, spec, dispatch, reviews, close; one context window
plus a compaction): output 611K, cache read 100.4M, cache write 1.45M. Subagents (14: scout, architect, qa, security,
security-review): output 664K, cache read 22.5M, cache write 2.68M. Cards PR #47 open → merge: 2 min.

**Gates and interventions** (counted from the lead transcript, from the start request on; the triage consents
`accept #34`–`#36` belong to triage and are not counted):
- `AskUserQuestion` calls: 5 (gate 1, PR shape, 🔐 T023 + T024 in one call, publishing the hole before the fix, the
  `^` fix decision).
- Gates: request approval, gate 1, 🔐 T023, 🔐 T024, the `^` review decision, 3 merges (#47, #49, #48, run in the
  user's terminal) → 8.
- Interventions outside gates: "Evet, tek spec", PR shape, publishing decision, "merge komutunu ver", "İkisini başlat"
  → 5, 2.5 per card (target ≤ 5).

**No single-session baseline** exists for this feature.

## Stop gate güven çapası ve bash_gate düzeltmeleri, spec B #17 (closed 2026-11-04; SPEC `docs/delix/SPEC.md`, cards T026–T028)

Sources:
- `STATE.json`;
- `gh pr view` (createdAt → mergedAt);
- the session transcripts (`message.usage`, summed per assistant message, not deduplicated). Desktop reuses worktree directories, so each card's transcript was picked by the card id in its dispatch text.

Session cost in USD: not measured.

| card | tier | PR | review rounds | PR open → merge | implementer tokens (out / cache read / cache write) | note |
|---|---|---|---|---|---|---|
| T026 Stop gate trust anchor | 3 | #57 | 2 | 44 min | 178K / 23.0M / 471K | 2 High findings, both reproduced by the lead on the branch before each round (`diff.external` before confirmation, K217; promisor lazy fetch through an `ext::` helper, K223); both fixes prototyped on a scratch copy first; the rounds went to the same session |
| T027 bash_gate cat heredoc, trust rules | 3 | #56 | 0 | 27 min | 72K / 9.1M / 272K | merged first (K222) |
| T028 docs and site | 2 | #58 | 0 | 15 min | 129K / 28.7M / 409K | 3 Low wording notes go to the follow-up card (K229) |

Lead session, from the start request on (start, spec, grill, dispatch, 4 reviews, close; spans a compaction): output 388K, cache read 91.5M, cache write 1.31M. Subagents (14: architect, security, qa): output 642K, cache read 15.0M, cache write 2.82M.

**Gates and interventions** (counted from the lead transcript, from the start request on):
- `AskUserQuestion` calls: 5 (grill K199–K202, gate 1).
- Gates, 8 in all:
  - request approval;
  - gate 1;
  - 🔐 T026 + T027 cards (one message);
  - 🔐 T027 merge and 🔐 T026 merge;
  - 3 merges (#56, #57, #58), run in the user's terminal.
- Interventions outside gates, 11 in all (3.7 per card; target ≤ 5):
  - grill answers: 4;
  - record push approvals: 3;
  - implementer card starts: 3;
  - "Evet, kapat": 1.

Not counted: the start request ("sıradaki adıma devam et"), as in earlier closes, and the issue close for #34–#36, which belongs to the previous spec.

**No single-session baseline** exists for this feature.

## Spec C: board görünürlüğü (closed 2026-11-12; SPEC `docs/delix/specs/C-board-visibility.md`, cards T029–T041)

Sources:
- `STATE.json`;
- `gh pr view` (createdAt → mergedAt);
- the session transcripts (`message.usage`, summed per assistant message, not deduplicated, as for spec B). Each
  card's transcript was picked by the card id in its dispatch text; the implementer sessions started no subagents.

Session cost in USD: not measured.

| card | tier | PR | fix rounds | PR open → merge | implementer tokens (out / cache read / cache write) | note |
|---|---|---|---|---|---|---|
| T031 lead skills write the ledger | 2 | #59 | 0 | 7.6 h | 96K / 9.6M / 385K | wave 7; merged the next morning |
| T029 board.py derive, Git actions | 2 | #60 | 1 | 7.5 h | 266K / 35.1M / 532K | Medium (a CR in a STATE field opened a bash fence), reproduced and prototyped by the lead (K269) |
| T030 delix-board panel | 2 | #62 | 1 | 7.2 h | 491K / 81.5M / 1.4M | Medium (`\s+$` quadratic, ×4 measured), prototyped |
| T033 release 0.6.3 | 3 | #61 | 0 | 28 min | 66K / 13.0M / 277K | 🔐; ships spec B, inside this spec's STATE |
| T036 lead skills: SHA, MERGED, STATE push | 2 | #63 | 0 | 43 min | 70K / 8.2M / 292K | wave 9 (K262) |
| T034 board.py trusted ledger | 2 | #64 | 1 | 90 min | 188K / 30.6M / 515K | wave 9 (K262, K263) |
| T035 panel trusted ledger | 2 | #65 | 1 | 87 min | 324K / 60.4M / 769K | wave 9 (K262, K263) |
| T037 board.py K277 | 2 | #66 | 0 | 44 min | 117K / 20.9M / 400K | wave 11 |
| T038 panel K277 | 2 | #67 | 0 | 47 min | 144K / 21.2M / 459K | wave 11 |
| T039 review §4 MERGED | 2 | #68 | 0 | 35 min | 75K / 16.9M / 281K | wave 11 |
| T040 F010 evidence file | 2 | #70 | 0 | 22 min | 56K / 8.1M / 243K | wave 12 |
| T041 implementer push rule | 3 | #69 | 3 | 122 min | 560K / 95.7M / 905K | 🔐; round 4 over the cap on the user's yes (K283); every Medium reproduced by the lead with real git 2.54 and each fix prototyped first |
| T032 docs and site | 2 | #71 | 0 | 15 min | 164K / 30.5M / 616K | wave 13; Low notes and a reproduced partial-clone lazy fetch go to follow-ups (K284) |

Implementers, 13 sessions: output 2.6M, cache read 431.9M, cache write 7.1M.

Lead sessions (two; the second was started from the first for the follow-up cards, wave 11–13 and this close):
- first lead, whole transcript (2026-11-04T19:23Z to 2026-11-12T18:36Z): output 1.4M, cache read 251.6M, cache write
  6.0M; subagents (25): output 1.9M, cache read 50.8M, cache write 7.5M;
- second lead, to 2026-11-12T20:40Z (spans compactions): output 1.0M, cache read 201.3M, cache write 2.6M; subagents
  (23): output 1.2M, cache read 46.0M, cache write 5.3M.

**Gates and interventions** (counted from both lead transcripts, from the start request on):
- `AskUserQuestion` calls: 8 (first lead 7: grill 4, gate 1, 🔐 T033 with the merge order, the fake-source design;
  second lead 1: F010 design, ruleset bypass, 🔐 T041).
- Gates, 18 in all:
  - gate 1;
  - 🔐 T033 and 🔐 T041 card approvals;
  - Stop gate `trust.py allow` in the user's terminal;
  - T041 past the round cap ("Evet, 4. tur");
  - 13 merges (#59–#71), each run by the user with `--match-head-commit`, 🔐 T033 and T041 among them.
- Interventions outside gates, 32 in all (2.5 per card; target ≤ 5):
  - grill answers: 4;
  - decisions the lead asked for: 4 (merge order, fake source K262, F010 design K278, ruleset);
  - card and session starts: 14 (13 implementer sessions and the second lead);
  - merge notes ("Merge ettim" and the like): 4, and "Evet, önce #61": 1;
  - a merge command run twice (#67, #70; the second run found it merged): 2;
  - user housekeeping in the terminal (`v0.6.3` tag, `git pull --ff-only`): 2;
  - "kontrol": 1.

Not counted: the start request, as in earlier closes.

**No single-session baseline** exists for this feature.
