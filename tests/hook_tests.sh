#!/usr/bin/env bash
# Deterministic tests for the delix hook scripts. Run: bash tests/hook_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"; mkdir -p "$T/.delix" "$T/docs/delix" "$T/tests" "$T/auth"
echo "docs/delix/tasks/T001-x.md" > "$T/.delix/card"
python3 - "$T/docs/delix/delix.json" <<'PY'
import json,sys; json.dump({"test_command":"true","extra_checks":[],"protected_paths":["auth/**",".env*"],"test_paths":["tests/**"]},open(sys.argv[1],"w"))
PY
echo "def test_a(): assert 1" > "$T/tests/test_a.py"
deny(){ # name, script, json  → output must contain deny
  out=$(echo "$3" | python3 "$S/$2"); if echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "✔ $1"; else echo "✘ $1 (expected deny)"; FAIL=1; fi; }
allow(){ out=$(echo "$3" | python3 "$S/$2"); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q deny; then echo "✔ $1"; else echo "✘ $1 (expected allow)"; FAIL=1; fi; }
deny  "reviewer Write denied"             write_gate.py "{\"tool_name\":\"Write\",\"agent_type\":\"delixcrew:qa\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/x.py\"}}"
deny  "architect Edit denied"             write_gate.py "{\"tool_name\":\"Edit\",\"agent_type\":\"delixcrew:architect\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/x.py\"}}"
allow "inactive without card"             write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"/tmp\",\"tool_input\":{\"file_path\":\"/tmp/x.py\"}}"
deny  "implementer protected path auth/"  write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/auth/x.py\"}}"
deny  "implementer edits existing test"   write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"tests/test_a.py\"}}"
allow "implementer new test file"         write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"tests/test_b.py\"}}"
allow "implementer free file"             write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"portal/app.py\"}}"
allow "free file, absolute path"          write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/portal/app.py\"}}"
# A13: writing outside cwd (worktree) — relative escape, absolute other dir, prefix lookalike (cwd + 'x')
deny  "outside cwd: ../ escape"           write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"../outside.py\"}}"
deny  "outside cwd: absolute other dir"   write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$(dirname "$T")/outside.py\"}}"
deny  "outside cwd: prefix lookalike"     write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"${T}x/portal/app.py\"}}"
deny  "outside cwd: even a free name"     write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"/tmp/try.txt\"}}"
# Card-specific permission (Files list + 🔐 Approved line)
mkdir -p "$T/docs/delix/tasks"; echo "x" > "$T/tests/listed.py"; echo "x" > "$T/auth/allowed.py"
cat > "$T/docs/delix/tasks/T001-x.md" <<'MD'
# T001 — x

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T001 | S | 3 | backend | 1 | open |

## Files (disjoint ownership)
- Modify: `auth/allowed.py` (`fn_x` 10–20)
- Modify (append only): `tests/listed.py:12` (~line 156)

## Steps
- `auth/not_in_files.py`
MD
allow "listed existing test file"         write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/tests/listed.py\"}}"
deny  "unlisted existing test"            write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"tests/test_a.py\"}}"
out=$(echo "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/allowed.py\"}}" | python3 "$S/write_gate.py")
echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -q "Approved line" && echo "✔ protected + listed + unapproved denied" || { echo "✘ protected + listed + unapproved denied (expected 'Approved line' message)"; FAIL=1; }
deny  "path outside Files section ignored" write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/not_in_files.py\"}}"
python3 - "$T/docs/delix/tasks/T001-x.md" <<'PY2'
import sys; p=sys.argv[1]; s=open(p).read(); s=s.replace("| T001 | S | 3 | backend | 1 | open |\n", "| T001 | S | 3 | backend | 1 | open |\n\n**🔐 Approved:** 2026-11-01 tahir\n"); open(p,"w").write(s)
PY2
allow "protected + listed + approved"     write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/allowed.py\"}}"
deny  "protected + unlisted + approved"   write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/x.py\"}}"
deny  "writing the card file denied"      write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/docs/delix/tasks/T001-x.md\"}}"
deny  "docs/delix/** write denied"        write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"docs/delix/new.md\"}}"
allow "own .delix/ dir is free"           write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\".delix/report.md\"}}"
deny  "reviewer denied even when listed+approved" write_gate.py "{\"tool_name\":\"Edit\",\"agent_type\":\"delixcrew:qa\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/allowed.py\"}}"
allow "inactive without card (docs/delix)" write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"/tmp\",\"tool_input\":{\"file_path\":\"/tmp/docs/delix/x.md\"}}"
deny  "implementer .env redirect"         bash_gate.py  "{\"tool_name\":\"Bash\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"echo X=1 >> .env\"}}"
allow "security git diff"                 bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git diff main...HEAD\"}}"
allow "security git -C diff"              bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git -C /tmp/wt diff main...HEAD\"}}"
allow "security git -C log"               bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git -C /tmp/wt log --oneline -5\"}}"
deny  "security git -C commit"            bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git -C /tmp/wt commit -m x\"}}"
deny  "security git -C checkout"          bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git -C /tmp/wt checkout main\"}}"
deny  "security git -C chained push"      bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git -C /tmp/wt diff && git -C /tmp/wt push\"}}"
deny  "security git -C diff redirect"     bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git -C /tmp/wt diff > out.patch\"}}"
deny  "security sed -i"                   bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:security\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"sed -i s/a/b/ x.py\"}}"
deny  "qa Bash"                           bash_gate.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"delixcrew:qa\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"ls\"}}"
# Stop
printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$S/stop_gate.py" 2>/dev/null; [ $? -eq 0 ] && echo "✔ stop: tests pass, stops" || { echo "✘ stop: should stop when tests pass"; FAIL=1; }
python3 - "$T/docs/delix/delix.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["test_command"]="false"; json.dump(d,open(p,"w"))
PY
printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$S/stop_gate.py" 2>/dev/null; [ $? -eq 2 ] && echo "✔ stop: tests broken, blocks (exit 2)" || { echo "✘ stop: expected exit 2 on broken tests"; FAIL=1; }
printf '{"cwd":"%s","stop_hook_active":true}' "$T" | python3 "$S/stop_gate.py" 2>/dev/null; [ $? -eq 0 ] && echo "✔ stop: stop_hook_active → stops" || { echo "✘ stop_hook_active"; FAIL=1; }
echo "NEEDS_CONTEXT: card unclear" > "$T/.delix/report.md"
printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$S/stop_gate.py" 2>/dev/null; [ $? -eq 0 ] && echo "✔ stop: NEEDS_CONTEXT report → stops" || { echo "✘ NEEDS_CONTEXT"; FAIL=1; }
# No python3 on PATH: each PreToolUse hook still blocks (exit 2) and says why in one line
mkdir -p "$T/empty-path"
python3 -c 'import json,sys; [print(h["command"]) for e in json.load(open(sys.argv[1]))["hooks"]["PreToolUse"] for h in e["hooks"]]' "$ROOT/hooks/hooks.json" |
while IFS= read -r cmd; do
  err=$(env -i PATH="$T/empty-path" CLAUDE_PLUGIN_ROOT="$ROOT" /bin/sh -c "$cmd" </dev/null 2>&1); rc=$?
  if [ $rc -eq 2 ] && [ "$(printf '%s\n' "$err" | wc -l)" -eq 1 ] && echo "$err" | grep -q '^delixcrew: python3 not found'; then echo "✔ no python3: blocks with message (${cmd##*/})"
  else echo "✘ no python3 (${cmd##*/}): rc=$rc, stderr: $err"; exit 1; fi
done || FAIL=1
# REQ-7: known feedback send paths and queue-dir writes are denied in every session (no card, any agent_type)
N="$T/nocard"; mkdir -p "$N/repo" "$T/home" "$T/q"
FBMSG="delixcrew: feedback is sent only by the user from their own terminal"
fbdeny(){ # name, script, json[, env…] → deny with the exact feedback message
  out=$(echo "$3" | env ${4:+"$4"} python3 "$S/$2"); if echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$FBMSG"; then echo "✔ $1"; else echo "✘ $1 (expected feedback deny): $out"; FAIL=1; fi; }
for a in "" "delixcrew:qa"; do
  fbdeny "feedback.py send denied ${a:-no agent}"   bash_gate.py "{\"tool_name\":\"Bash\",\"agent_type\":\"$a\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"cd scripts && python3 feedback.py send F001 --confirm abc\"}}"
  fbdeny "pty wrapper send denied ${a:-no agent}"   bash_gate.py "{\"tool_name\":\"Bash\",\"agent_type\":\"$a\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"printf 'SEND x' | script -q /dev/null python3 scripts/feedback.py send F001\"}}"
  fbdeny "gh issue create delixcrew ${a:-no agent}" bash_gate.py "{\"tool_name\":\"Bash\",\"agent_type\":\"$a\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"gh issue create -R tahircengiz/delixcrew -t x -b y\"}}"
done
fbdeny "unbuffer + feedback.py denied"     bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"unbuffer python3 scripts/feedback.py list\"}}"
fbdeny "gh api issues delixcrew denied"    bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"gh api repos/tahircengiz/delixcrew/issues -f title=x\"}}"
git -C "$N/repo" init -q && git -C "$N/repo" remote add origin https://github.com/tahircengiz/delixcrew.git
fbdeny "gh issue create, cwd remote delixcrew" bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N/repo\",\"tool_input\":{\"command\":\"gh issue create -t x\"}}"
allow "gh pr view not affected"           bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"gh pr view 12\"}}"
allow "gh issue create other repo"        bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"gh issue create -R example/other -t x\"}}"
allow "feedback.py add is free"           bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"python3 scripts/feedback.py add < d.json\"}}"
fbdeny "queue dir write (default ~)"      write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/home/.claude/delixcrew/feedback/config.json\"}}" "HOME=$T/home"
fbdeny "queue dir edit (env dir)"         write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/q/F001.json\"}}" "DELIXCREW_FEEDBACK_DIR=$T/q"
fbdeny "queue dir write, reviewer too"    write_gate.py "{\"tool_name\":\"MultiEdit\",\"agent_type\":\"delixcrew:qa\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/q/F001.json\"}}" "DELIXCREW_FEEDBACK_DIR=$T/q"
DELIXCREW_FEEDBACK_DIR="$T/q" allow "queue lookalike dir is free" write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"${T}/qx/F001.json\"}}"
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
