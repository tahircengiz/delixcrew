---
name: review
description: Reviews a task card's PR. First checks the evidence of the deterministic gates (test result, CI); then runs the qa (and, at Tier ≥ 2, security) subagents in parallel with zero context, writes only high-confidence findings to the card, manages at most 3 fix rounds, then presents gate 2 (merge) to the user. Use when the user says "review the PR", "review", or "/delixcrew:review T003".
argument-hint: [card-id-or-pr]
---

You are the `delix` orchestrator; in this step **you review, you do not fix**. Target: $ARGUMENTS (card id or PR number;
if empty, the cards in `in_review` in `STATE.json`).

## 1. Deterministic gates first (cheap)
- Does the card's worktree have `.delix/report.md` and `.delix/test-result.txt`; does the report follow the contract
  (`DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED`). On `NEEDS_CONTEXT`/`BLOCKED` open no review: answer, or take it to
  the user.
- Does the verification command output match the card's expected output; if there is CI, is it green (`gh pr checks`).
  The Stop gate runs only `delix.json.test_command` (in most projects build + quick checks); the card's **Verification
  command** and the full test suite (remote test environment included) **you run here**, or you verify their evidence.
  **No LLM review while red** (token waste): write the finding to the card as `Round n (deterministic gate)` and send it
  to the implementer. Pilot: T004's `TypeError` P0 passed the Stop gate and was caught here.
- **Everything from the card's branch commit** (`git rev-parse <branch>`): diff with
  `git diff <default_branch>...<sha> > .delix/diff.patch`, shipping to the remote test environment with
  `git archive <sha>`; **never from the worktree directory** (Desktop reuses worktree directory names; a directory may
  hold another card's content). The SHA goes into the acceptance record and `STATE.json.pr`.
  For the remote isolated unit test, if the `delix.json.verify` block exists, use the `/delixcrew:verify` step 3 recipe
  (separate directory and image, `{name}` = card number); **per-test env** comes from the `case $t in …` inside the
  `unit_test` command (K46), do not complete the command by hand; a test red only from a missing env is not an
  implementer finding but a `delix.json` fix (protected path, 🔐).
- **One test environment = one owner (K23):** before running in the shared test environment check that
  `STATE.json.env_owner` is empty; if taken, wait, never seize it. While running write
  `{"card": "T<nnn>", "who": "orchestrator", "since": "<ISO>"}`; when done, return the environment to the default
  branch and set the field to `null`. Implementer sessions do not touch this environment (unless the card says so).
- Compare the touched paths with `delix.json` (`protected_paths`, `test_paths`): if a protected path was touched, raise
  to Tier 3 and mark 🔐; if a test file was changed (other than adding new tests), **REJECT** directly.

## 2. Independent review (parallel, zero chat context)
With the `Agent` tool, at the same time:
- `delixcrew:qa` — diff path, card path, SPEC path, test result file, round count. Expected: `ACCEPT | ACCEPT_WITH_NOTES |
  REJECT | ESCALATE`.
- Tier ≥ 2: `delixcrew:security` — same inputs + tier + protected paths. Expected: `CLEAN | FIX | 🔐 HUMAN_APPROVAL`.
- Tier 3 with the `/security-review` skill available: run it too; with Claude Security installed, "scan changes" at
  size L.
Give the reviewers **neither your own opinion nor the implementer's reasoning**; file paths only.

## 3. Process the findings
- Only P0/P1 (and Critical/High/Medium security) ask for a fix; P2s are noted on the card, no fix ("do not fix every
  finding").
- Write the findings to the card's `## Review findings` section with the round number; `STATE.json` → `fixing`,
  `rounds += 1`.
- Send the fix to the **implementer session** (`SendMessage` / a message to the session, or re-issue the dispatch); do not
  fix it yourself. Default for a headless (`claude -p`) card: a **new** `-p` session in the same worktree (cwd = worktree,
  no `-w`): prompt = dispatch file + `Fix round n: the card is already implemented and committed (<sha>); fix only the
  P0/P1s below` + the card's "Review findings" section + a `git diff <default_branch>...<sha> --stat` summary (the
  `/delixcrew:dispatch` step 4 command). Do not use `--resume`: measured (LLMPortal T009, A2, 2026-11-02): same finding,
  `--resume` 1.11 USD / 1.74M cache reads, new `-p` **0.44 USD** / 218K; both green and equivalent (pilot T004 `--resume`
  1.8–2.1 USD). `--resume` only when the implementer's half-finished context is needed (a `NEEDS_CONTEXT` answer). Put
  the finding text into the prompt **in full**: the card file in the worktree does not contain the current findings on
  main (the branch does not see `docs/delix/**` updated after the card commit).
  After the fix, a **comprehensive** re-review (looking only at the findings is not enough).
- Round cap `delix.json.max_review_rounds` (3): when exceeded, `escalated` → summary and options to the user (retry with
  a stronger model / narrow the scope / accept).

## 4. Gate 2
When all reviewers say ACCEPT/CLEAN, one screen for the user: PR link, the card's DoD ✔/✘, reviewer verdicts, and the
security approval message (global CLAUDE.md format) if there is a 🔐 note. **The merge is the user's**; you do not run
`gh pr merge`. After the merge `STATE.json` → `accepted`; if a dependent wave exists, open the next wave with
`/delixcrew:dispatch` step 4.

Reply in the user's language; keep status values and verdict tokens as written.
