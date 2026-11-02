#!/usr/bin/env bash
# Deterministic tests for board.py. Run: bash tests/board_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
T="$(mktemp -d)"; cd "$T" || exit 1

# 1) empty project → no cards, BOARD not written
out=$(python3 "$S/board.py"); echo "$out" | grep -q "No cards" && ok "empty project: No cards" || bad "empty project: expected No cards"
[ ! -e docs/delix/BOARD.md ] && ok "empty project: BOARD not written" || bad "empty project: BOARD must not be written"

# 2) fake project: git repo + STATE + 2 cards + report in a worktree
git init -q -b main . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
mkdir -p docs/delix/tasks
cat > docs/delix/STATE.json <<'J'
{"spec":"docs/delix/SPEC.md","size":"M","updated":"2026-11-01T10:00:00Z","waves":[["T001","T002"]],
 "cards":{"T001":{"file":"docs/delix/tasks/T001-api.md","role":"backend","tier":2,"status":"in_progress","pr":null,"rounds":0,"cost_usd":null},
          "T002":{"file":"docs/delix/tasks/T002-auth.md","role":"backend","tier":3,"status":"accepted","pr":12,"rounds":2,"cost_usd":1.5}}}
J
printf '# T001 — api\n\n| id | size | tier | role | wave | status |\n|---|---|---|---|---|---|\n| T001 | M | 2 | backend | 1 | open |\n' > docs/delix/tasks/T001-api.md
printf '# T002 — auth\n' > docs/delix/tasks/T002-auth.md
printf '# T003 — card file only\n\n| id | size | tier | role | wave | status |\n|---|---|---|---|---|---|\n| T003 | S | 1 | frontend | 2 | open |\n' > docs/delix/tasks/T003-ui.md
git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -q -m cards
git worktree add -q "$T/wt-T001" -b delix-T001 >/dev/null 2>&1
mkdir -p "$T/wt-T001/.delix"; echo "docs/delix/tasks/T001-api.md" > "$T/wt-T001/.delix/card"
printf '# Report — T001\n\n**Status:** NEEDS_CONTEXT\n**PR:** #7 (delix-T001)\n\n## Evidence\n- `pytest -q` → 3 passed\n\n## Concerns / remaining work\n- Keycloak realm name missing from spec\n' > "$T/wt-T001/.delix/report.md"

out=$(python3 "$S/board.py")
[ ! -e docs/delix/BOARD.md ] && ok "default: BOARD not written" || bad "default: BOARD must not be written"
out=$(python3 "$S/board.py" --write)
echo "$out" | grep -q "| 1 | T001 | backend | 2 | in_progress | 0 | #7 | not measured | NEEDS_CONTEXT · Keycloak realm name missing from spec | needs_context |" && ok "T001 row (report, PR, gate)" || { bad "T001 row"; echo "$out"; }
echo "$out" | grep -q "| 1 | T002 | backend | 3 | accepted | 2 | #12 | \$1.50 | - | merge |" && ok "T002 row (cost, merge gate)" || { bad "T002 row"; echo "$out"; }
echo "$out" | grep -q "| 2 | T003 | frontend | 1 | open | 0 | - | not measured | - | - |" && ok "T003 from card file only" || { bad "T003 row"; echo "$out"; }
[ -f docs/delix/BOARD.md ] && grep -q "T001" docs/delix/BOARD.md && ok "--write: BOARD.md written" || bad "BOARD.md missing"
python3 "$S/board.py" --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d["cards"])==3 and d["cards"][0]["worktree"], d' && ok "--json output" || bad "--json"

# 3) /delix:verify record (STATE.json.verifications) → "Verifications" table; with and without cards
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p))
d["verifications"]=[{"name":"a10c-e7","date":"2026-11-02","sha":"abcdef0123","base":"40735be","input":"a10c-e7","tier":"3 🔐","verdict":"FIX 🔐",
 "report":"docs/delix/verifications/2026-11-02-a10c-e7.md","gates":{"gitleaks":"PASS","local":"PASS","remote_unit":"PASS 41/41","full":"not run: no --full"},
 "qa":"ACCEPT_WITH_NOTES","security":"🔐 HUMAN_APPROVAL","cost_usd":1.25}]
json.dump(d,open(p,"w"),ensure_ascii=False)
PYS
out=$(python3 "$S/board.py")
echo "$out" | grep -qF "| 2026-11-02 | a10c-e7 | abcdef0 | 3 🔐 | PASS | PASS | PASS 41/41 | not run: no --full | ACCEPT_WITH_NOTES | 🔐 HUMAN_APPROVAL | FIX 🔐 | \$1.25 | \`docs/delix/verifications/2026-11-02-a10c-e7.md\` |" && ok "verification row (project with cards)" || { bad "verification row"; echo "$out"; }
echo "$out" | grep -qF "Pending fixes:** a10c-e7" && ok "verifications: pending fixes" || bad "verifications: pending fixes"
python3 "$S/board.py" --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["verifications"][0]["name"]=="a10c-e7", d' && ok "--json verifications" || bad "--json verifications"
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p)); d["cards"]={}; json.dump(d,open(p,"w"),ensure_ascii=False)
PYS
rm -f docs/delix/tasks/*.md
out=$(python3 "$S/board.py")
echo "$out" | grep -q "No cards" && echo "$out" | grep -qF "| 2026-11-02 | a10c-e7 |" && ok "verifications: visible without cards too" || { bad "verifications without cards"; echo "$out"; }

cd /; rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
