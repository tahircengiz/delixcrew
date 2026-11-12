# T039 — review skill §4: write `merged` only when the PR is `MERGED`

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T039 | S | 2 | docs | 11 | open |

> Tier 2 (lead, as T036): one sentence of skill text that copies the guard already in `skills/close/SKILL.md:13`. No code, no protected path. qa and security review it in parallel.

**Goal (1 sentence):** After the merge, the lead reads the PR state and writes `accepted` + `merged` only when it is `MERGED`. · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-2` ("Kullanıcı merge edince lead `status` → `accepted` ile aynı anda `merged`'i yazar"); T036 Review findings, line 60.

**Docs/site:** none; no README or site line describes this write.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `skills/review/SKILL.md` (§4, lines 75–79)
- Test: `tests/ledger_tests.sh`: **line 13 changes** (its substring disappears from the skill) and 2 lines are inserted after it; no other line changes.

## Edit anchors (base 4ae458c)
1. Replace lines 75–79, from `prints). After the merge, in one STATE write:` to `` `/delixcrew:dispatch` step 4. ``, with the text below. Keep lines ≤ 120 characters. Each quoted phrase stays on one physical line, because `grep -F` matches line by line.
   ```
   prints). After the merge, read `gh pr view <n> --json state,mergeCommit,headRefOid`; only when `state` is `MERGED`,
   in one STATE write: status → `accepted` and `merged` =
   `{"sha": "<merge commit 40 hex>", "head": "<merged PR head 40 hex>", "at": "<ISO-8601 Z>"}` (`mergeCommit.oid` → `sha`,
   `headRefOid` → `head`); otherwise leave the card `in_review`, tell the user the PR is not merged and stop. If a dependent
   wave exists, open the next wave with `/delixcrew:dispatch` step 4.
   ```
2. Test line 13 (`grep -qF 'gh pr view <n> --json mergeCommit,headRefOid' "$ROOT/skills/review/SKILL.md" && ok "review: merged source" || bad "review: gh pr view line missing"`) becomes:
   `grep -qF 'gh pr view <n> --json state,mergeCommit,headRefOid`; only when `state` is `MERGED`' "$ROOT/skills/review/SKILL.md" && ok "review: merged only when MERGED" || bad "review: MERGED check line missing"`
3. Insert after line 13:
   - `! grep -qF -- '--json mergeCommit,headRefOid' "$ROOT/skills/review/SKILL.md" && ok "review: no unguarded merged read" || bad "review: unguarded gh pr view still present"`
   - `grep -qF 'otherwise leave the card `in_review`' "$ROOT/skills/review/SKILL.md" && ok "review: not merged, stop" || bad "review: not-merged branch missing"`

## Interfaces
- Consumed: the `merged` shape (spec §4), checked byte for byte by test line 11.
- Produced: none.

## Global Constraints (verbatim from the spec)
- Review §4: "**The merge is the user's**; you do not run `gh pr merge`".
- The guard wording follows close §1 ("write it only when `state` is `MERGED`").

## Steps
1. Change test line 13 and add the two lines; run `bash tests/ledger_tests.sh` and see **red**.
2. Edit the skill.
3. Run again and see **green**.
4. Commit `T039: review §4 writes merged only when the PR is MERGED`; open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/ledger_tests.sh` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `claude plugin validate .` → passes
- `git diff origin/main -- tests/ledger_tests.sh | grep -c '^-[^-]'` → `1`
- `git diff --stat origin/main` → 2 files

## Review Focus
- The `merged` record line stays byte-identical (test line 11).
- The lead still never merges.
- The new phrase is on one physical line.

## Don'ts
- Untouchable: every other file and every other test line.
- If the anchor text differs, write `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 1K tokens): status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`) · commands and output · PR number and branch · assumptions.

Read only this card and spec REQ-2.

## Review findings (filled by the lead)
- Round 1 (PR #68, head `4c01f1de13ac7166c06cbc4a4559b12de67c87c0`, 2026-11-12): qa `ACCEPT` (0 findings), security `CLEAN` (0 findings). Lead gates on the clean `git archive` of the head: the 12 shell suites exit 0 on Python 3.9.6 and 3.13.13, `claude plugin validate .` passes, 1 removed test line (line 13, named in the card); CI `check` and `test` pass. Ready for gate 2.
  - Notes: the last sentence is wrapped differently from the anchor block (same words; every test phrase on one line). Spec §4 `merged` row now names the guarded read (lead, rev 8). Follow-up idea (security unsure, not this card): neither review §4 nor close §1 compares the merged `headRefOid` with the last reviewed `sha`, so a merge from the GitHub UI after an unreviewed push would still be written `accepted`.
