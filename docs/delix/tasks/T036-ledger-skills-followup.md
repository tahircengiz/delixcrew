# T036 — Lead skills: reviewed SHA from step 1, `merged` only when MERGED, branch from gh, STATE pushed before gate 2

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T036 | S | 2 | docs | 9 | open |

> Tier 2: skill text only; no protected path. It changes what the lead writes into STATE.json and when it pushes it.

**Goal (1 sentence):** The review, close and dispatch skills record the SHA the reviewers actually saw, write `merged` only for a merged PR, take `branch` from GitHub, and push the round's STATE records to `origin/<default_branch>` before gate 2, because Ready to merge now comes only from that copy (K262). · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-2`, `#REQ-3`; §4 (data rows), §6 (K262 paragraph); K262

**Docs/site:** none in this card (T032, wave 10).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `skills/review/SKILL.md` (line 46; §4 line 68)
- Modify: `skills/close/SKILL.md` (lines 12–13)
- Modify: `skills/dispatch/SKILL.md` (line 70)
- Test: `tests/ledger_tests.sh` (new checks inserted after line 14, before line 15 `python3 - "$ROOT/templates/STATE.json" <<'PYS' ...`; no existing line changes)

## Edit anchors (base: the main commit that adds this card; lines unchanged since e3070ec). Reflow to the file's line width; keep every other word.
1. `skills/review/SKILL.md` line 46: replace the sentence "`sha` is the full `git rev-parse <branch>` you reviewed, never 7 characters." with "`sha` is the full step-1 SHA (`git rev-parse <branch>`, taken before the diff) that the reviewers' diff was made from; never 7 characters, never re-read after the review."
2. `skills/review/SKILL.md` §4 line 68: after "When all reviewers say ACCEPT/CLEAN," insert "first commit `STATE.json` with this round's records, rebase on `origin/<default_branch>` and push it there (where that branch takes only pull requests, the lead's STATE pull request is merged first); `/delixcrew:status` shows Ready to merge only from that copy (K262). Then" and continue with the existing "one screen for the user: ...".
3. `skills/close/SKILL.md` lines 12–13: "read it with `gh pr view <n> --json mergeCommit,headRefOid` and write it." becomes "read it with `gh pr view <n> --json state,mergeCommit,headRefOid` and write it only when `state` is `MERGED`; otherwise list the card and stop."
4. `skills/dispatch/SKILL.md` line 70: "fill `branch` (from the report's `**PR:** #<n> (<branch>)`)" becomes "fill `branch` (from `gh pr view <n> --json headRefName`, not from the report)".

## Interfaces
- Consumed: the record shapes in spec §4 (unchanged), checked byte for byte by `tests/ledger_tests.sh` lines 9–13.
- Produced: none for code. T034 and T035 read the pushed copy of STATE.

## Global Constraints (verbatim from the spec)
- K262: "Bedel: kart, lead kaydı push edene kadar `review not on origin/<default>` ile bekler".
- §6: "Bilinen sınır: lead'in `gh pr merge` çalıştırmasını bir hook engellemez (yalnız skill metni)". The skills keep saying the lead never runs `gh pr merge` or a Git actions command.

## Steps
1. Add one `grep -qF` check per new phrase (anchors 1–4) after line 14; run `bash tests/ledger_tests.sh`, see the new checks **red**.
2. Edit the three skills.
3. Run, see **green**.
4. Commit `T036: lead skills record the step-1 SHA, write merged only when MERGED, branch from gh, push STATE before gate 2 (K262)`; open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/ledger_tests.sh` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `claude plugin validate .` → passes
- `git diff origin/main -- tests/ledger_tests.sh | grep -c '^-[^-]'` → `0`
- `git diff --stat origin/main` → only the 4 Files

## Review Focus
- The record shapes stay byte-identical (lines 9–13 of the test still pass).
- The review skill still says the merge is the user's and the lead does not run `gh pr merge`.
- The push sentence names `origin/<default_branch>` and does not suggest a force push.

## Don'ts
- Untouchable: `scripts/**`, `plugins/**`, `hooks/**`, `docs/delix/**`, `skills/status/**`, every existing test line.
- If a phrase in the anchors does not match the file, write `NEEDS_CONTEXT` with the line you found and stop.

## Report contract
`.delix/report.md` (≤ 1K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · the commands and their output · PR number and branch · assumptions. Read only this card and the spec sections named above.

## Review findings (filled by the lead)
- Round 1 (PR #63, head `d56b8a52e02d46a4b035dfd3f3336e0f7d3ab8ae`, 2026-11-12): qa `ACCEPT` (P2 1), security `CLEAN` (Low 1). Gates green: `ledger_tests.sh` ALL PASSED, the shell-test loop, `claude plugin validate .`. Ready for gate 2.
  - Follow-up, not in this card: [P2/Low] `skills/review/SKILL.md:77` still writes `merged` after the merge with no `state`/`MERGED` check (`close` now has one); tighten it and `tests/ledger_tests.sh` line 14 in one change. Unsure: who merges the lead's STATE pull request (the user); fetch before the rebase; `<n>` for `gh pr view` still comes from the report. Existing gap (spec §6, follow-up 🔐): sessions can push to the default branch.
