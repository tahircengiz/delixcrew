# T031 — Lead skills write the ledger (agents, merged); status prints the Git actions and never runs them

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T031 | S | 2 | docs | 7 | open |

> Tier 2: skill text and the STATE template; no protected path. It changes what the lead writes into STATE.json.

**Goal (1 sentence):** The dispatch, review and close skills write the §4 records into `STATE.json`; the status skill prints the new sections as they are and says the lead never runs their commands; `templates/STATE.json` shows both fields; and a new test checks all of it. · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-2`; §4 (data rows, skill rows), §6 (known limit); K241, K253

**Docs/site:** none in this card (T032).

## Files
- Modify: `skills/dispatch/SKILL.md` (line 57; line 60)
- Modify: `skills/review/SKILL.md` (insert after line 41; lines 63–64)
- Modify: `skills/close/SKILL.md` (lines 10–11; line 32)
- Modify: `skills/status/SKILL.md` (line 3; lines 18–20; insert after line 25; line 26 renumbered)
- Modify: `templates/STATE.json` (insert after line 7; line 10)
- Test (create): `tests/ledger_tests.sh`

## Edit anchors (base origin/main ad27168; Spec B's T028 also edits `skills/dispatch/SKILL.md` after line 35, so match by content)
1. `skills/dispatch/SKILL.md`
   - Line 57 (`For every opened card, `STATE.json` status → `in_progress`.`) becomes: "For every opened card, `STATE.json` status → `in_progress`, and append to `STATE.json.cards.<T>.agents` (create the list if missing) `{"role": "implementer", "by": "<lead branch>", "round": 0, "sha": null, "verdict": null, "at": "<ISO-8601 Z>", "branch": "<name>"|null, "session": "<Desktop name>"|"-p"|null}`. `by` is your own branch (`git branch --show-current`). `branch` and `session` stay `null` until known. Append only; a re-dispatch appends a new record."
   - Line 60: after "`STATE.json` status → `in_review`" add ", fill `branch` (from the report's `**PR:** #<n> (<branch>)`) and `session` in the last implementer record".
2. `skills/review/SKILL.md`
   - Insert after line 41 ("Give the reviewers **neither your own opinion…** file paths only."): "**Ledger (Spec C REQ-2).** After each `delixcrew:qa` and each `delixcrew:security` run, append to `STATE.json.cards.<T>.agents` `{"role": "qa"|"security", "by": "<lead branch>", "round": <n>, "sha": "<40 hex>", "verdict": "<token>", "at": "<ISO-8601 Z>"}`. `round` is this review round (1, 2, 3). `sha` is the full `git rev-parse <branch>` you reviewed, never 7 characters. `verdict` is the returned token, REJECT and FIX too. Append only. `/delixcrew:status` reads gate 2 from these records."
   - Lines 63–64 become: "**The merge is the user's**; you do not run `gh pr merge` (the user runs the `gh pr merge <n> --squash --match-head-commit <sha40>` block that `/delixcrew:status` prints). After the merge, in one STATE write: status → `accepted` and `merged` = `{"sha": "<merge commit 40 hex>", "head": "<merged PR head 40 hex>", "at": "<ISO-8601 Z>"}`, read with `gh pr view <n> --json mergeCommit,headRefOid` (`mergeCommit.oid` → `sha`, `headRefOid` → `head`); if a dependent wave exists, open the next wave with". Line 65 stays.
3. `skills/close/SKILL.md`
   - Lines 10–11: append "Every `accepted` card with an `agents` list also carries `merged` `{"sha": "<merge commit 40 hex>", "head": "<merged PR head 40 hex>", "at": "<ISO-8601 Z>"}`; where it is missing, read it with `gh pr view <n> --json mergeCommit,headRefOid` and write it."
   - Line 32 becomes: "Run `/delixcrew:status` and show its Git actions (`remove_worktree`, `delete_branch`); the user runs each block with Desktop's Run button, and you never run them yourself. `.delix/` files go with the worktree."
4. `skills/status/SKILL.md`
   - Line 3 description: append ". Below the table: Leads, Agents, Waiting on you, Ready to merge and Git actions (one-line bash blocks the user runs)".
   - Lines 18–20, item 1, first sentence becomes: "Print the table and every section below it **as is** (no skipped rows, no reformatting); each Git actions command stays in its own one-line `bash` code block, which gives the user Desktop's Run button."
   - Insert after line 25 a new item "3. **You never run the Git actions commands yourself; the user runs them with Desktop's Run button.** `merge` is gate 2; `remove_worktree` and `delete_branch` are the user's cleanup; if asked to run one, give its block again."
   - Old item 3 (line 26) becomes 4.
   - `allowed-tools` (line 4) unchanged.
5. `templates/STATE.json`
   - Insert after line 7: `"$comment_agents": "Spec C ledger, written only by the lead: cards.<T>.agents gets an implementer record at dispatch and a qa/security record per review run (see skills/dispatch and skills/review); merged {sha, head, at} is written with status accepted after the user's merge.",`
   - Line 10: append `, "agents": [], "merged": null` inside the T001 object.

## Test (create tests/ledger_tests.sh)
```bash
#!/usr/bin/env bash
# Spec C REQ-2: lead skills carry the ledger record shapes; templates/STATE.json is valid JSON with the two fields. Run: bash tests/ledger_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; FAIL=0
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
IMPL='{"role": "implementer", "by": "<lead branch>", "round": 0, "sha": null, "verdict": null, "at": "<ISO-8601 Z>", "branch": "<name>"|null, "session": "<Desktop name>"|"-p"|null}'
REV='{"role": "qa"|"security", "by": "<lead branch>", "round": <n>, "sha": "<40 hex>", "verdict": "<token>", "at": "<ISO-8601 Z>"}'
MERGED='{"sha": "<merge commit 40 hex>", "head": "<merged PR head 40 hex>", "at": "<ISO-8601 Z>"}'
grep -qF "$IMPL" "$ROOT/skills/dispatch/SKILL.md" && ok "dispatch: implementer record" || bad "dispatch: implementer record missing"
grep -qF "$REV" "$ROOT/skills/review/SKILL.md" && ok "review: qa/security record" || bad "review: qa/security record missing"
grep -qF "$MERGED" "$ROOT/skills/review/SKILL.md" && ok "review: merged record" || bad "review: merged record missing"
grep -qF "$MERGED" "$ROOT/skills/close/SKILL.md" && ok "close: merged record" || bad "close: merged record missing"
grep -qF 'gh pr view <n> --json mergeCommit,headRefOid' "$ROOT/skills/review/SKILL.md" && ok "review: merged source" || bad "review: gh pr view line missing"
grep -qF 'You never run the Git actions commands yourself' "$ROOT/skills/status/SKILL.md" && ok "status: never runs Git actions" || bad "status: never-run line missing"
python3 - "$ROOT/templates/STATE.json" <<'PYS' && ok "template: valid JSON, agents [] and merged null" || bad "template STATE.json"
import json, sys
c = json.load(open(sys.argv[1], encoding="utf-8"))["cards"]["T001"]
assert c["agents"] == [] and c["merged"] is None, c
PYS
[ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
```

## Interfaces
- Consumed:
  - §4 record shapes (above).
  - T029's section names `Leads`, `Agents`, `Waiting on you`, `Ready to merge`, `Git actions`, and the merge command form `gh pr merge <n> --squash --match-head-commit <sha40>`. If T029 is unfinished, write against these names.
- Produced: the ledger records that T029 and T030 read.

## Global Constraints (verbatim from the spec)
- REQ-2: "`dispatch` uygulayıcıyı açınca bir `implementer` kaydı (dal ve Desktop oturum adı rapordan ya da `start_session` sonucundan bilinince doldurulur), `review` her `qa` ve `security` koşusu için incelenen SHA ve verdict'le bir kayıt. Kullanıcı merge edince lead `status` → `accepted` ile aynı anda `merged`'i yazar."
- §4: "\"Git actions komutlarını sen çalıştırmazsın\" satırı".
- §2: "architect ve verify çağrılarının kaydı" is out of scope: no record for them.
- K241: no hook; Tier 2.

## Steps
1. Create `tests/ledger_tests.sh`. Run it and see **red**.
2. Edit the five files per the anchors.
3. **Green.** Run the full loop and `claude plugin validate .`.
4. Commit `T031: lead skills write the Spec C ledger; status never runs Git actions`. Open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/ledger_tests.sh` → `ALL PASSED`.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0.
- `claude plugin validate .` → passes.
- `git diff --stat origin/main` → only the 6 files.

## Review Focus
- The shapes are byte-identical to §4.
- The review skill still says the lead does not run `gh pr merge`.
- `accepted` still means merged (K251).
- No record for architect or verify.

## Don'ts
- Untouchable: `scripts/**`, `plugins/**`, `hooks/**`, `.claude-plugin/**`, `docs/delix/**`, `skills/verify/**`, `skills/implement/**`, existing `tests/*` files.
- Do not change `allowed-tools` of the status skill.

## Report contract
`.delix/report.md` (≤ 1K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- commands and their output;
- the PR number;
- assumptions.

Read only this card and spec REQ-2, §4.

## Review findings (filled by the lead)
- (none yet)
