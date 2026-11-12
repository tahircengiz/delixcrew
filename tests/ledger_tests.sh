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
# T036 (K262): reviewed SHA from step 1, push STATE before gate 2, merged only when MERGED, branch from gh
grep -qF 'the full step-1 SHA (`git rev-parse <branch>`, taken before the diff)' "$ROOT/skills/review/SKILL.md" && ok "review: sha is the step-1 SHA" || bad "review: step-1 SHA line missing"
grep -qF 'rebase on `origin/<default_branch>` and push it there' "$ROOT/skills/review/SKILL.md" && ok "review: STATE pushed before gate 2" || bad "review: push-before-gate-2 line missing"
grep -qF 'gh pr view <n> --json state,mergeCommit,headRefOid` and write it only when `state` is `MERGED`' "$ROOT/skills/close/SKILL.md" && ok "close: merged only when MERGED" || bad "close: MERGED check line missing"
grep -qF 'from `gh pr view <n> --json headRefName`, not from the report' "$ROOT/skills/dispatch/SKILL.md" && ok "dispatch: branch from gh" || bad "dispatch: headRefName line missing"
python3 - "$ROOT/templates/STATE.json" <<'PYS' && ok "template: valid JSON, agents [] and merged null" || bad "template STATE.json"
import json, sys
c = json.load(open(sys.argv[1], encoding="utf-8"))["cards"]["T001"]
assert c["agents"] == [] and c["merged"] is None, c
PYS
[ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
