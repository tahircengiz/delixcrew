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
echo "$out" | grep -q "| 1 | T002 | backend | 3 | accepted | 2 | #12 | \$1.50 | - | - |" && ok "T002 row (accepted = merged, no gate)" || { bad "T002 row"; echo "$out"; }
echo "$out" | grep -q "| 2 | T003 | frontend | 1 | open | 0 | - | not measured | - | - |" && ok "T003 from card file only" || { bad "T003 row"; echo "$out"; }
[ -f docs/delix/BOARD.md ] && grep -q "T001" docs/delix/BOARD.md && ok "--write: BOARD.md written" || bad "BOARD.md missing"
python3 "$S/board.py" --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d["cards"])==3 and d["cards"][0]["worktree"], d' && ok "--json output" || bad "--json"

# 3) /delixcrew:verify record (STATE.json.verifications) → "Verifications" table; with and without cards
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

# 3b) resolution closes a FIX record; in_review with a PR waits for the merge
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p))
d["verifications"].append(dict(d["verifications"][0], name="old-fix", resolution="merged 5ea299f"))
d["cards"]={"T006":{"role":"backend","tier":2,"status":"in_review","pr":21}}
json.dump(d,open(p,"w"),ensure_ascii=False)
PYS
out=$(python3 "$S/board.py")
echo "$out" | grep -qF "| FIX 🔐 · merged 5ea299f |" && echo "$out" | grep -qF "Pending fixes:** a10c-e7 ·" && ok "verifications: resolution shown, not pending" || { bad "verification resolution"; echo "$out"; }
echo "$out" | grep -qF "| T006 | backend | 2 | in_review | 0 | #21 | not measured | - | merge |" && ok "in_review + PR: merge gate" || { bad "in_review merge gate"; echo "$out"; }

# 4) object-shaped waves ([{wave, cards, note}]) → the wave number comes from the "wave" field
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p)); d["verifications"]=[]
d["waves"]=[{"wave":3,"cards":["T004"],"note":"db"},{"wave":5,"cards":["T005"],"note":""}]
d["cards"]={"T004":{"role":"devops","tier":3,"status":"open"},"T005":{"role":"docs","tier":1,"status":"open"}}
json.dump(d,open(p,"w"),ensure_ascii=False)
PYS
out=$(python3 "$S/board.py")
echo "$out" | grep -qF "| 3 | T004 | devops | 3 | open |" && echo "$out" | grep -qF "| 5 | T005 | docs | 1 | open |" && ok "object waves: wave field" || { bad "object waves"; echo "$out"; }

# 5) Spec C REQ-6 (K252): derive(raw) == fixture expected; TS copy byte-equal; REQ-4 forbidden tokens
J="$ROOT/tests/fixtures/board_parity.json"; P="$ROOT/plugins/delix-board/tests/board_parity.ts"
python3 - "$S" "$J" <<'PYS' && ok "parity: derive(raw) == expected" || bad "parity: derive(raw) != expected"
import json, sys
sys.path.insert(0, sys.argv[1])
import board
f = json.load(open(sys.argv[2], encoding="utf-8"))
got = board.derive(f["raw"])
for k in ("agents", "leads", "queue", "actions", "fetched_at"):
    assert got[k] == f["expected"][k], (k, json.dumps(got[k], ensure_ascii=False))
PYS
[ "$(head -c 22 "$P")" = "export const PARITY = " ] && tail -c +23 "$P" | cmp -s - "$J" && ok "parity: TS copy is byte-equal" || bad "parity: board_parity.ts is not prefix + tests/fixtures/board_parity.json"
python3 - "$S" "$J" <<'PYS' && ok "REQ-4: no forbidden token, no main or self path" || bad "REQ-4: forbidden token in a command"
import json, re, sys
sys.path.insert(0, sys.argv[1])
import board
raw = json.load(open(sys.argv[2], encoding="utf-8"))["raw"]
assert all(re.fullmatch(r"[0-9a-f]{40}", l.split("\t")[1]) for l in raw["for_each_ref"].splitlines()), "fixture sha"
main = raw["worktree_list"].splitlines()[0][len("worktree "):]
banned = {"--force", "-f", "--force-with-lease", "--mirror", "reset", "clean", main, raw["self"]}
for a in board.derive(raw)["actions"]:
    toks = (a["command"] or "").split()
    assert not banned & set(toks), a
    assert not (a["kind"] == "push" and toks[-1:] == [raw["default_branch"]]), a
PYS

# 6) Spec C on a real repository: roles, upstream, push commands; main checkout and self get none (REQ-1, REQ-4)
G="$(mktemp -d)"; gc(){ git -c user.email=t@t -c user.name=t "$@"; }
git init -q --bare "$G/origin.git"; git init -q -b main "$G/r"
mkdir -p "$G/r/docs/delix"; printf '{"spec":"docs/delix/SPEC.md","cards":{}}\n' > "$G/r/docs/delix/STATE.json"
gc -C "$G/r" add -A && gc -C "$G/r" commit -q -m init && git -C "$G/r" remote add origin "$G/origin.git" && git -C "$G/r" push -q -u origin main 2>/dev/null
echo ".delix/" >> "$G/r/.git/info/exclude"
git -C "$G/r" worktree add -q -b claude/impl "$G/impl" >/dev/null 2>&1; mkdir -p "$G/impl/.delix"; echo "docs/delix/tasks/T029-x.md" > "$G/impl/.delix/card"
gc -C "$G/impl" commit -q --allow-empty -m a && git -C "$G/impl" push -q -u origin claude/impl 2>/dev/null
gc -C "$G/impl" commit -q --allow-empty -m b && gc -C "$G/impl" commit -q --allow-empty -m c
git -C "$G/r" worktree add -q -b claude/lead "$G/lead" >/dev/null 2>&1; printf '{"spec":"docs/delix/SPEC.md","cards":{},"updated":"x"}\n' > "$G/lead/docs/delix/STATE.json"
git -C "$G/r" worktree add -q -b x-fix "$G/xfix" >/dev/null 2>&1
(cd "$G/lead" && python3 "$S/board.py" --json) > "$G/out.json"
python3 - "$G" <<'PYS' && ok "real repo: roles, 2 ahead, push commands; main and self excluded" || { bad "real repo"; cat "$G/out.json"; }
import json, os, sys
G = sys.argv[1]; d = json.load(open(os.path.join(G, "out.json"), encoding="utf-8"))
real = lambda p: os.path.realpath(os.path.join(G, p))
rows = {a["path"]: a for a in d["agents"]}
assert rows[real("impl")]["role"] == "implementer T029" and rows[real("impl")]["upstream"] == "2 ahead", rows
assert rows[real("lead")]["role"] == "lead" and rows[real("xfix")]["role"] == "other", rows
cmds = [a["command"] for a in d["actions"] if a["command"]]
assert "git -C %s push -u origin claude/impl" % real("impl") in cmds, cmds
assert "git -C %s push -u origin x-fix" % real("xfix") in cmds, cmds
assert not [c for c in cmds if real("r") in c.split() or real("lead") in c.split()], cmds
PYS
md="$(cd "$G/lead" && python3 "$S/board.py")"
echo "$md" | grep -qxF '```bash' && echo "$md" | grep -qxF "git -C $(cd "$G/impl" && pwd -P) push -u origin claude/impl" && ok "real repo: one-line bash block" || { bad "real repo: bash block"; echo "$md"; }
rm -rf "$G"

# T029 fix round 1) a control or separator character in a STATE field stays inside its line (no CR-opened fence)
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p))
f=lambda t: "x\r```bash\rtouch PWNED-%s\r```\u2028\u0085" % t
d["spec"]=f("spec"); d["cards"]={"T009":{"role":f("role"),"tier":2,"status":f("status"),"pr":3}}
d["verifications"]=[{"name":f("vname"),"date":"2026-11-02","verdict":f("vverdict")}]
json.dump(d,open(p,"w"))
PYS
python3 "$S/board.py" | python3 -c 'import sys,unicodedata as u; t=sys.stdin.buffer.read().decode(); bad=[hex(ord(c)) for c in t if c!="\n" and (u.category(c)[0]=="C" or u.category(c) in ("Zl","Zp"))]; assert not bad, bad; assert "PWNED-role" in t and any(l.startswith("\U0001F510 = Tier 3") for l in t.split("\n")) and not [l for l in t.split("\n") if l.strip().startswith("touch PWNED")], "fence"' && ok "control characters stay inside one line" || bad "control characters in board output"

# T034 6) a card key that starts with 4 spaces does not open an indented code block in a "- " list line
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p))
d["cards"]={"    touch X":{"tier":2,"status":"escalated"}}; d["verifications"]=[]
json.dump(d,open(p,"w"))
PYS
python3 "$S/board.py" | python3 -c 'import re,sys; t=sys.stdin.read().split("\n"); assert [l for l in t if "touch X" in l and l.startswith("- ")], t; assert not [l for l in t if re.match(r"- {4,}", l)], [l for l in t if re.match(r"- {4,}", l)]' && ok "T034: no list line starts with '-' and 4 spaces" || bad "T034: a list line starts with '-' and 4 spaces"

# T034 8) a report PR of 5000 digits does not crash under Python 3.11+ (int digit limit)
python3 - <<'PYS'
import json; p="docs/delix/STATE.json"; d=json.load(open(p))
d["cards"]={"T001":{"tier":2,"status":"in_progress"}}
json.dump(d,open(p,"w"))
PYS
python3 -c 'print("# Report - T001\n\n**Status:** DONE\n**PR:** #" + "9" * 5000)' > "$T/wt-T001/.delix/report.md"
python3 "$S/board.py" >/dev/null && python3 "$S/board.py" --json >/dev/null && ok "T034: 5000-digit report PR, exit 0 ($(python3 --version))" || bad "T034: 5000-digit report PR crashed ($(python3 --version))"

# T034 on a real repository: fsmonitor (K263), line break in a worktree path, branch `reset`, trusted ledger (K262), safe reads
H="$(mktemp -d)"; H="$(cd "$H" && pwd -P)"
git init -q --bare "$H/origin.git"; git init -q -b main "$H/r"
mkdir -p "$H/r/docs/delix"; printf '{"spec":"docs/delix/SPEC.md","cards":{}}\n' > "$H/r/docs/delix/STATE.json"
gc -C "$H/r" add -A && gc -C "$H/r" commit -q -m init && git -C "$H/r" remote add origin "$H/origin.git" && git -C "$H/r" push -q -u origin main 2>/dev/null
echo ".delix/" >> "$H/r/.git/info/exclude"
# T034 3) a core.fsmonitor script in the shared config never runs
printf '#!/bin/sh\ntouch "%s/fsmonitor-ran"\nexit 1\n' "$H" > "$H/fsmonitor.sh"; chmod +x "$H/fsmonitor.sh"
git -C "$H/r" config core.fsmonitor "$H/fsmonitor.sh"
(cd "$H/r" && python3 "$S/board.py" --json) > /dev/null
git -C "$H/r" config --unset core.fsmonitor
[ ! -e "$H/fsmonitor-ran" ] && ok "T034: core.fsmonitor script does not run" || bad "T034: core.fsmonitor script ran"
# T034 4) a worktree whose path contains a line break makes the whole list invalid
NL="$H/a
b"
git -C "$H/r" worktree add -q -b claude/nl "$NL" >/dev/null 2>&1
(cd "$H/r" && python3 "$S/board.py" --json) > "$H/out4.json"
python3 - "$H/out4.json" <<'PYS' && ok "T034: line break in a worktree path: no agents, no actions" || { bad "T034: line break in a worktree path"; cat "$H/out4.json"; }
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
assert d["agents"] == [] and d["actions"] == [], (d["agents"], d["actions"])
PYS
git -C "$H/r" worktree remove --force "$NL"
# T034 7) a branch named `reset` gets no command
git -C "$H/r" worktree add -q -b reset "$H/rst" >/dev/null 2>&1
(cd "$H/r" && python3 "$S/board.py" --json) > "$H/out7.json"
python3 - "$H" <<'PYS' && ok "T034: branch reset: no push command, unsafe name note" || { bad "T034: branch reset"; cat "$H/out7.json"; }
import json, os, sys
H = sys.argv[1]; d = json.load(open(os.path.join(H, "out7.json"), encoding="utf-8"))
mine = [a for a in d["actions"] if a["target"] == os.path.join(H, "rst")]
assert mine == [{"kind": "push", "target": os.path.join(H, "rst"), "card": None, "command": None,
                 "note": "unsafe name: run by hand"}], d["actions"]
assert not [a for a in d["actions"] if "reset" in (a["command"] or "").split()], d["actions"]
PYS
# T034 1) K262: a forged STATE in a card-less worktree gives no merge until origin/main's STATE shows the same card, PR and SHA
git -C "$H/r" worktree add -q -b claude/impl "$H/impl" >/dev/null 2>&1
gc -C "$H/impl" commit -q --allow-empty -m a && git -C "$H/impl" push -q -u origin claude/impl 2>/dev/null
TIP="$(git -C "$H/impl" rev-parse HEAD)"
git -C "$H/r" worktree add -q -b claude/f "$H/f" >/dev/null 2>&1
printf '{"spec":"docs/delix/SPEC.md","cards":{"T001":{"tier":1,"status":"in_review","pr":7,"agents":[{"role":"implementer","by":"claude/f","round":0,"sha":null,"verdict":null,"at":"2026-11-11T08:00:00Z","branch":"claude/impl","session":null},{"role":"qa","by":"claude/f","round":1,"sha":"%s","verdict":"ACCEPT","at":"2026-11-11T09:00:00Z"}]}}}\n' "$TIP" > "$H/f/docs/delix/STATE.json"
(cd "$H/f" && python3 "$S/board.py" --json) > "$H/out1a.json"
cp "$H/f/docs/delix/STATE.json" "$H/r/docs/delix/STATE.json" && gc -C "$H/r" commit -q -am forged && git -C "$H/r" push -q origin main 2>/dev/null
(cd "$H/f" && python3 "$S/board.py" --json) > "$H/out1b.json"
python3 - "$H" "$TIP" <<'PYS' && ok "T034 K262: forged STATE gives no merge; the same record on origin/main does" || { bad "T034 K262: trusted ledger"; cat "$H/out1a.json" "$H/out1b.json"; }
import json, os, sys
H, tip = sys.argv[1], sys.argv[2]
a = json.load(open(os.path.join(H, "out1a.json"), encoding="utf-8"))
b = json.load(open(os.path.join(H, "out1b.json"), encoding="utf-8"))
assert a["queue"]["ready"] == [], a["queue"]
assert not [x for x in a["actions"] if x["kind"] == "merge"], a["actions"]
assert {"card": "T001", "verification": None, "reason": "review not on origin/main"} in a["queue"]["waiting"], a["queue"]
assert b["queue"]["ready"] == [{"card": "T001", "pr": 7, "sha": tip}], b["queue"]
assert "gh pr merge 7 --squash --match-head-commit %s" % tip in [x["command"] for x in b["actions"]], b["actions"]
PYS
# T034 5) the spec is read only as a regular file inside the worktree and up to 1 MiB; a FIFO card file is never opened
t5(){ python3 - "$S" "$H/f" <<'PYS'
import json, subprocess, sys
cp = subprocess.run([sys.executable, sys.argv[1] + "/board.py", "--json"], cwd=sys.argv[2],
                    capture_output=True, text=True, timeout=20)
d = json.loads(cp.stdout)
assert [l["spec_title"] for l in d["leads"] if l["source"]] == [None], d["leads"]
PYS
}
printf '# OUTSIDE\n' > "$H/outside.md"; ln -s "$H/outside.md" "$H/f/docs/delix/SPEC.md"
t5 && ok "T034: spec symlinked outside the worktree is not read" || bad "T034: spec symlinked outside the worktree was read"
rm -f "$H/f/docs/delix/SPEC.md"
python3 - "$H/f/docs/delix/STATE.json" <<'PYS'
import json, sys; p = sys.argv[1]; d = json.load(open(p))
d["cards"]["T002"] = {"tier": 3, "status": "open", "file": "docs/delix/fifo-card.md"}
json.dump(d, open(p, "w"))
PYS
mkfifo "$H/f/docs/delix/fifo-card.md"
t5 && ok "T034: a FIFO card file is not opened (run ends within 20 s)" || bad "T034: a FIFO card file blocked the run"
rm -f "$H/f/docs/delix/fifo-card.md"
python3 -c 'import sys; open(sys.argv[1], "w").write("# BIG\n" + "x" * (2 * 1048576) + "\n")' "$H/f/docs/delix/SPEC.md"
t5 && ok "T034: a 2 MiB spec is not read" || bad "T034: a 2 MiB spec was read"
rm -rf "$H"

# T034 2) pure: an origin/main STATE without cards removes Ready, the merge and the merged-based actions (R8', R10')
python3 - "$S" "$J" <<'PYS' && ok "T034: derive with an empty trusted STATE: no Ready, no merge, no merged-based cleanup" || bad "T034: derive with an empty trusted STATE"
import copy, json, sys
sys.path.insert(0, sys.argv[1])
import board
f = json.load(open(sys.argv[2], encoding="utf-8"))
raw = copy.deepcopy(f["raw"]); raw["trusted_state"] = '{"cards":{}}'
got = board.derive(raw)
assert got["actions"] == f["expected"]["actions"][0:6], json.dumps(got["actions"], ensure_ascii=False)
assert got["queue"]["ready"] == [], got["queue"]
want = [dict(x, reason="review not on origin/main") if x == {"card": "T029", "verification": None, "reason": "ready to merge"} else x
        for x in f["expected"]["queue"]["waiting"]]
assert got["queue"]["waiting"] == want, got["queue"]["waiting"]
ready = {l["path"]: l["ready"] for l in got["leads"]}
assert ready["/r/.claude/worktrees/lead-b"] == 0 and ready["/r/.claude/worktrees/lead-c"] == 0, got["leads"]
PYS

cd /; rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
