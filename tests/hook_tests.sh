#!/usr/bin/env bash
# Deterministic tests for the delix hook scripts. Run: bash tests/hook_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"; git -C "$T" init -q; mkdir -p "$T/.delix" "$T/docs/delix" "$T/tests" "$T/auth"
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
# T026 (K206): the Stop gate runs only an approved (git_common_dir, sha256) pair. The test record replaces
# common.trust_file through runpy (K203); each case approves its command list first; expected results are unchanged.
TREC="$T/trusthome/.claude/delixcrew/trust.json"
cat > "$T/run.py" <<'PY'
import runpy, sys
scripts, record, script = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, scripts)
import common
common.trust_file = lambda: record
sys.argv = [script] + sys.argv[4:]
runpy.run_path(script, run_name="__main__")
PY
tapprove(){ python3 - "$T" "$TREC" <<'PY'
import hashlib, json, os, subprocess, sys
cwd, rec = sys.argv[1], sys.argv[2]
with open(os.path.join(cwd, "docs", "delix", "delix.json"), encoding="utf-8") as f:
    cfg = json.load(f)
cmds = [cfg.get("test_command") or "pytest -q"] + list(cfg.get("extra_checks") or [])
sha = hashlib.sha256(json.dumps(cmds, ensure_ascii=False, separators=(",", ":")).encode("utf-8")).hexdigest()
out = subprocess.run(["git", "-C", cwd, "rev-parse", "--git-common-dir"], capture_output=True, text=True).stdout.rstrip("\n")
os.makedirs(os.path.dirname(rec), exist_ok=True); os.chmod(os.path.dirname(rec), 0o700)
data = {"version": 1, "entries": []}
if os.path.exists(rec):
    with open(rec, encoding="utf-8") as f:
        data = json.load(f)
data["entries"].append({"git_common_dir": os.path.realpath(os.path.join(cwd, out)), "sha256": sha, "approved_at": "2026-11-04T00:00:00+00:00"})
with open(rec, "w", encoding="utf-8") as f:
    json.dump(data, f)
os.chmod(rec, 0o600)
PY
}
tstop(){ printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$T/run.py" "$S" "$TREC" "$S/stop_gate.py" 2>/dev/null; }
tapprove; tstop; [ $? -eq 0 ] && echo "✔ stop: tests pass, stops" || { echo "✘ stop: should stop when tests pass"; FAIL=1; }
python3 - "$T/docs/delix/delix.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["test_command"]="false"; json.dump(d,open(p,"w"))
PY
tapprove; tstop; [ $? -eq 2 ] && echo "✔ stop: tests broken, blocks (exit 2)" || { echo "✘ stop: expected exit 2 on broken tests"; FAIL=1; }
grep -qF '[exit 1]' "$T/.delix/test-result.txt" && ! grep -qF '[not run:' "$T/.delix/test-result.txt" && echo "✔ stop: broken test ran ([exit 1], no [not run:)" || { echo "✘ stop: broken test did not run: $(cat "$T/.delix/test-result.txt")"; FAIL=1; }
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
# REQ-7 fix round 1: heredoc draft bodies do not trigger (a)/(b); `send` must be the subcommand; `gh issue new` = create
bashjson(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
HD=$(printf '%s\n' "python3 \"/x/scripts/feedback.py\" add <<'EOF'" '{"title": "preview hash differs on second send", "body": "the script wrapper path also fails"}' 'EOF')
allow  "heredoc add with send/script in body"  bash_gate.py "$(bashjson "$N" "$HD")"
fbdeny "quoted path feedback.py send denied"   bash_gate.py "$(bashjson "$N" "python3 \"/x/scripts/feedback.py\" send F001")"
fbdeny "send inside a shell heredoc denied"    bash_gate.py "$(bashjson "$N" "$(printf '%s\n' "bash <<'EOF'" 'python3 scripts/feedback.py send F001' 'EOF')")"
fbdeny "gh issue new delixcrew denied"         bash_gate.py "{\"tool_name\":\"Bash\",\"cwd\":\"$N\",\"tool_input\":{\"command\":\"gh issue new -R tahircengiz/delixcrew -t x\"}}"
# REQ-7 fix round 2: only the body of a `feedback.py … add` heredoc is exempt; pty wrappers inside other heredocs stay denied
fbdeny "pty.spawn in python3 - heredoc denied"  bash_gate.py "$(bashjson "$N" "$(printf '%s\n' "python3 - <<'EOF'" 'import pty; pty.spawn(["python3","scripts/feedback.py","send","F001"])' 'EOF')")"
fbdeny "script wrapping a bash heredoc denied"  bash_gate.py "$(bashjson "$N" "$(printf '%s\n' "script -q /dev/null bash <<'EOF'" 'python3 scripts/feedback.py "send" F001' 'EOF')")"
fbdeny "unterminated <<X does not hide the rest" bash_gate.py "$(bashjson "$N" "$(printf '%s\n' "echo '<<X'" 'script -q /dev/null python3 scripts/feedback.py "send" F001')")"
allow  "add heredoc body quoting feedback.py send" bash_gate.py "$(bashjson "$N" "$(printf '%s\n' "python3 \"/x/scripts/feedback.py\" add <<'EOF'" '{"title": "feedback.py send prints wrong hash"}' 'EOF')")"
# REQ-7 fix round 3: the exemption is a fullmatch of one quoted-delimiter `python3 …/feedback.py add <<'EOF'` call
SND='script -q /dev/null python3 scripts/feedback.py send F001'
hd(){ bashjson "$N" "$(printf '%s\n' "$@")"; }
fbdeny "unquoted <<EOF with \$(… send)"        bash_gate.py "$(hd 'python3 scripts/feedback.py add <<EOF' '$(python3 scripts/feedback.py send F001 --confirm abc)' 'EOF')"
fbdeny "unquoted <<EOF with backticks"        bash_gate.py "$(hd 'python3 scripts/feedback.py add <<EOF' '`python3 scripts/feedback.py send F001`' 'EOF')"
fbdeny "add # <<EOF comment trick"            bash_gate.py "$(hd 'python3 scripts/feedback.py add # <<EOF' "$SND" 'EOF')"
fbdeny "add \\<<EOF escape trick"             bash_gate.py "$(hd 'python3 scripts/feedback.py add \<<EOF' "$SND" 'EOF')"
fbdeny "add \"<<EOF quote trick"              bash_gate.py "$(hd 'python3 scripts/feedback.py add "<<EOF' "\"; $SND" 'EOF')"
fbdeny "command on the delimiter line"        bash_gate.py "$(hd "python3 scripts/feedback.py add <<'EOF'" '{"t":"x"}' "EOF; $SND")"
fbdeny "line after the delimiter"             bash_gate.py "$(hd "python3 scripts/feedback.py add <<'EOF'" '{"t":"x"}' 'EOF' "$SND")"
fbdeny "early delimiter inside the body"      bash_gate.py "$(hd "python3 scripts/feedback.py add <<'EOF'" '{"t":"x"}' 'EOF' "$SND" 'EOF')"
T3B='{"title": "feedback.py send under script prints $( and `x`", "body": "send"}'
T3O='python3 "/opt/plugins/delixcrew/scripts/feedback.py" add <<'"'EOF'"
allow  "T003 add heredoc, risky words in body" bash_gate.py "$(hd "$T3O" "$T3B" 'EOF')"
# REQ-7 fix round 4: no $VAR in the exempt path (ReDoS); the gate returns fast on long $-runs
T3V='python3 "${CLAUDE_PLUGIN_ROOT}/scripts/feedback.py" add <<'"'EOF'"
fbdeny "\${VAR} path gets no exemption"     bash_gate.py "$(hd "$T3V" '{"title": "feedback.py send prints wrong hash"}' 'EOF')"
timed(){ # name, json → bash_gate.py must answer in < 1 s
  python3 - "$S/bash_gate.py" "$2" <<'PYT' && echo "✔ $1" || { echo "✘ $1 (expected < 1 s)"; FAIL=1; }
import subprocess, sys, time
t = time.monotonic()
try:
    subprocess.run([sys.executable, sys.argv[1]], input=sys.argv[2], capture_output=True, text=True, timeout=5)
except subprocess.TimeoutExpired:
    sys.exit(1)
sys.exit(0 if time.monotonic() - t < 1 else 1)
PYT
}
DOL=$(printf '$aaaaaaaaaaaaaaa%.0s' $(seq 12))
timed "12 x \$aaa run, fast"                 "$(bashjson "$N" "python3 $DOL x")"
timed "12 x \$aaa in add heredoc path, fast" "$(hd "python3 \"$DOL/feedback.py\" add <<'EOF'" '{"t":"x"}' 'EOF')"
# REQ-7 (0.6.0): triage write paths; (a)/(b) in every session (K125), (c)/(d) only for delixcrew; record heredoc exempt
TRMSG="delixcrew: triage decisions are applied only by the user from their own terminal"
trdeny(){ # name, script, json[, env…] → deny with the exact triage message
  out=$(echo "$3" | env ${4:+"$4"} python3 "$S/$2"); if echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$TRMSG"; then echo "✔ $1"; else echo "✘ $1 (expected triage deny): $out"; FAIL=1; fi; }
bja(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","agent_type":sys.argv[3],"cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2" "$3"; }
R="$N/repo"
for a in "" "delixcrew:qa"; do
  trdeny "gh issue close, delixcrew remote ${a:-no agent}"      bash_gate.py "$(bja "$R" 'gh issue close 12' "$a")"
  trdeny "triage.py apply, delixcrew remote ${a:-no agent}"     bash_gate.py "$(bja "$R" 'python3 scripts/triage.py apply 12 --confirm abc' "$a")"
  trdeny "gh api graphql mutation ${a:-no agent}"               bash_gate.py "$(bja "$R" "gh api graphql -f query='mutation{addLabelsToLabelable(x)}'" "$a")"
  trdeny "gh label create ${a:-no agent}"                       bash_gate.py "$(bja "$R" 'gh label create x' "$a")"
  deny   "gh api issues labels -X POST (feedback rule first) ${a:-no agent}" bash_gate.py "$(bja "$R" 'gh api repos/x/y/issues/1/labels -X POST' "$a")"
  trdeny "gh api -X POST ${a:-no agent}"                        bash_gate.py "$(bja "$R" 'gh api repos/x/y/labels -X POST' "$a")"
  trdeny "gh api --method=PATCH ${a:-no agent}"                 bash_gate.py "$(bja "$R" 'gh api repos/x/y/labels/bug --method=PATCH' "$a")"
  trdeny "script wrapper triage.py apply ${a:-no agent}"        bash_gate.py "$(bja "$R" 'script -q /dev/null python3 scripts/triage.py apply 1' "$a")"
done
trdeny "gh api -XPOST attached"            bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/labels -XPOST')"
trdeny "gh api --method patch lowercase"   bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/labels/bug --method patch')"
trdeny "gh api -fq=x attached field"       bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/labels -fq=x')"
trdeny "gh api -F field"                   bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/labels -F name=bug')"
trdeny "gh api --raw-field"                bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/labels --raw-field name=bug')"
trdeny "gh api --input"                    bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/labels --input body.json')"
trdeny "gh issue reopen -R delixcrew"      bash_gate.py "$(bashjson "$N" 'gh issue reopen 12 -R tahircengiz/delixcrew')"
trdeny "gh label in a chain, delixcrew"    bash_gate.py "$(bashjson "$R" 'gh pr list && gh label delete bug --yes')"
trdeny "triage.py apply, no remote (K125)" bash_gate.py "$(bashjson "$N" 'python3 scripts/triage.py apply 12 --confirm abc')"
trdeny "quoted path, flag before apply"    bash_gate.py "$(bashjson "$N" "python3 \"/x/scripts/triage.py\" -v 'apply' 12")"
trdeny "expect + triage.py, no remote"     bash_gate.py "$(bashjson "$N" 'expect -c "spawn python3 scripts/triage.py apply 1"')"
trdeny "pty.spawn + triage.py heredoc"     bash_gate.py "$(hd "python3 - <<'EOF'" 'import pty; pty.spawn(["python3","scripts/triage.py","apply","1"])' 'EOF')"
# the exempt shape is exactly one quoted-delimiter `python3 …/triage.py record <n> <<'EOF'` call (fix-round tricks above)
SNT='script -q /dev/null python3 scripts/triage.py apply 12'
trdeny "record: unquoted <<EOF with \$(… apply)" bash_gate.py "$(hd 'python3 scripts/triage.py record 12 <<EOF' '$(python3 scripts/triage.py apply 12 --confirm abc)' 'EOF')"
trdeny "record: unquoted <<EOF with backticks"   bash_gate.py "$(hd 'python3 scripts/triage.py record 12 <<EOF' '`python3 scripts/triage.py apply 12`' 'EOF')"
trdeny "record # <<EOF comment trick"            bash_gate.py "$(hd 'python3 scripts/triage.py record 12 # <<EOF' "$SNT" 'EOF')"
trdeny "record \\<<EOF escape trick"             bash_gate.py "$(hd 'python3 scripts/triage.py record 12 \<<EOF' "$SNT" 'EOF')"
trdeny "record \"<<EOF quote trick"              bash_gate.py "$(hd 'python3 scripts/triage.py record 12 "<<EOF' "\"; $SNT" 'EOF')"
trdeny "record: command on the delimiter line"   bash_gate.py "$(hd "python3 scripts/triage.py record 12 <<'EOF'" '{"t":"x"}' "EOF; $SNT")"
trdeny "record: line after the delimiter"        bash_gate.py "$(hd "python3 scripts/triage.py record 12 <<'EOF'" '{"t":"x"}' 'EOF' "$SNT")"
trdeny "record: early delimiter inside the body" bash_gate.py "$(hd "python3 scripts/triage.py record 12 <<'EOF'" '{"t":"x"}' 'EOF' "$SNT" 'EOF')"
trdeny "record: \${VAR} path gets no exemption"  bash_gate.py "$(hd "python3 \"\${CLAUDE_PLUGIN_ROOT}/scripts/triage.py\" record 12 <<'EOF'" "$SNT" 'EOF')"
trdeny "record without a number, no exemption"   bash_gate.py "$(hd "python3 scripts/triage.py record <<'EOF'" "$SNT" 'EOF')"
TRO="python3 \"/opt/delixcrew/scripts/triage.py\" record 12 <<'TRIAGE_EOF'"
allow "record heredoc, trigger words in body"    bash_gate.py "$(bashjson "$R" "$(printf '%s\n' "$TRO" '{"reason": "does not apply to v0.4, script output"}' 'TRIAGE_EOF')")"
allow "record heredoc, body names triage.py apply" bash_gate.py "$(hd "$TRO" '{"reason": "maintainer runs triage.py apply 12 under script"}' 'TRIAGE_EOF')"
allow "unquoted record path, plain body"         bash_gate.py "$(hd "python3 scripts/triage.py record 12 <<'EOF'" '{"t":"x"}' 'EOF')"
allow "gh issue list, delixcrew remote"          bash_gate.py "$(bashjson "$R" 'gh issue list')"
allow "gh api pulls, delixcrew remote"           bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/pulls')"
allow "gh api pulls -X GET"                      bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/pulls -X GET')"
allow "gh api pulls --method=get"                bash_gate.py "$(bashjson "$R" 'gh api repos/x/y/pulls --method=get')"
allow "gh api read-only flags (--jq -H --paginate)" bash_gate.py "$(bashjson "$R" "gh api repos/x/y/pulls --paginate -H 'Accept: application/json' --jq '.[].number'")"
allow "gh issue view, delixcrew remote"          bash_gate.py "$(bashjson "$R" 'gh issue view 12 --json title,body,labels')"
allow "triage.py show"                           bash_gate.py "$(bashjson "$R" 'python3 scripts/triage.py show 12')"
allow "triage.py preview / index"                bash_gate.py "$(bashjson "$N" 'python3 scripts/triage.py preview 12 && python3 scripts/triage.py index')"
mkdir -p "$N/other" && git -C "$N/other" init -q && git -C "$N/other" remote add origin https://example.com/o/other.git
allow "gh issue close, other repo"               bash_gate.py "$(bashjson "$N/other" 'gh issue close 3')"
allow "gh label create, other repo"              bash_gate.py "$(bashjson "$N/other" 'gh label create bug')"
allow "gh api graphql, other repo"               bash_gate.py "$(bashjson "$N/other" "gh api graphql -f query='mutation{x}'")"
# write gate: no direct write into the triage dir, in every session (triage.py record is the only writer)
mkdir -p "$T/tq"
trdeny "triage dir write (default ~)"     write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/home/.claude/delixcrew/triage/12.json\"}}" "HOME=$T/home"
trdeny "triage dir edit (env dir)"        write_gate.py "{\"tool_name\":\"Edit\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/tq/12.json\"}}" "DELIXCREW_TRIAGE_DIR=$T/tq"
trdeny "triage dir, relative path"        write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$T/tq\",\"tool_input\":{\"file_path\":\"12.json\"}}" "DELIXCREW_TRIAGE_DIR=$T/tq"
trdeny "triage dir write, reviewer too"   write_gate.py "{\"tool_name\":\"MultiEdit\",\"agent_type\":\"delixcrew:qa\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/tq/12.json\"}}" "DELIXCREW_TRIAGE_DIR=$T/tq"
trdeny "triage dir NotebookEdit"          write_gate.py "{\"tool_name\":\"NotebookEdit\",\"cwd\":\"$N\",\"tool_input\":{\"notebook_path\":\"$T/tq/n.ipynb\"}}" "DELIXCREW_TRIAGE_DIR=$T/tq"
DELIXCREW_TRIAGE_DIR="$T/tq" allow "triage lookalike dir is free" write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"${T}/tqx/12.json\"}}"
# ReDoS: hook time per probe minus hook time for `ls` < 0.1 s (best of 3 each)
python3 - "$T" "$N" <<'PYP'
import json, sys
t, n = sys.argv[1], sys.argv[2]
dol = "$aaaaaaaaaaaaaaa" * 12
probes = {
    "dol": f"python3 \"{dol}/triage.py\" record 12 <<'EOF'\n{{\"t\":\"x\"}}\nEOF",
    "flags": "python3 scripts/triage.py " + "-a " * 20000 + "x",
    "body": "python3 \"/x/scripts/triage.py\" record 12 <<'EOF'\n" + ("triage.py -a gh api -X " * 30 + "\n") * 300 + "EOF",
    "delim": "python3 scripts/triage.py record 12 <<'EOF'\n" + "EOF\n" * 5000 + "EOF",
}
for k, c in probes.items():
    with open(f"{t}/probe-{k}.json", "w") as f:
        json.dump({"tool_name": "Bash", "cwd": n, "tool_input": {"command": c}}, f)
PYP
rtime(){ # name, probe json file
  d=$(python3 - "$S/bash_gate.py" "$(bashjson "$N" ls)" "$2" <<'PYT'
import subprocess, sys, time
def best(data):
    ts = []
    for _ in range(3):
        t = time.monotonic()
        subprocess.run([sys.executable, sys.argv[1]], input=data, capture_output=True, text=True, timeout=5)
        ts.append(time.monotonic() - t)
    return min(ts)
base = best(sys.argv[2])
d = best(open(sys.argv[3]).read()) - base
print(f"{d:.3f}")
sys.exit(0 if d < 0.1 else 1)
PYT
  ) && echo "✔ $1 (Δ $d s)" || { echo "✘ $1 (Δ ${d:-timeout} s, expected < 0.1)"; FAIL=1; }; }
rtime "ReDoS: 12 x \$aaa in record path" "$T/probe-dol.json"
rtime "ReDoS: 20k -a after triage.py"    "$T/probe-flags.json"
rtime "ReDoS: 200 KB record body"        "$T/probe-body.json"
rtime "ReDoS: 5k delimiter lines"        "$T/probe-delim.json"
# T011 fix round 1: the triage dir check ignores letter case (APFS is case-insensitive by default)
trdeny "triage dir, upper-cased ~ path"   write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/home/.CLAUDE/delixcrew/TRIAGE/12.json\"}}" "HOME=$T/home"
trdeny "triage dir, upper-cased env dir"  write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"$T/TQ/12.json\"}}" "DELIXCREW_TRIAGE_DIR=$T/tq"
DELIXCREW_TRIAGE_DIR="$T/tq" allow "triage lookalike dir still free (case fix)" write_gate.py "{\"tool_name\":\"Write\",\"cwd\":\"$N\",\"tool_input\":{\"file_path\":\"${T}/TQX/12.json\"}}"
# T024 REQ-3 (#36, K182, K187, K188): one capture call of either script exempts its body from both scripts' (a)/(b);
# a path starting with `-` is never a capture call; deny cases use the generic deny helper (rule order unchanged)
FAH="python3 \"/x/scripts/feedback.py\" add <<'EOF'"; TRH="python3 \"/x/scripts/triage.py\" record 12 <<'EOF'"
allow "T024 cross: add body names triage.py apply"        bash_gate.py "$(hd "$FAH" '{"title": "triage.py apply 12 --confirm abc fails"}' 'EOF')"
allow "T024 cross: add body, triage.py under script"      bash_gate.py "$(hd "$FAH" '{"title": "triage.py record hangs under script"}' 'EOF')"
allow "T024 cross: record body names feedback.py send"    bash_gate.py "$(hd "$TRH" '{"reason": "feedback.py send F001 --confirm abc is refused"}' 'EOF')"
allow "T024 cross: record body, feedback.py under script" bash_gate.py "$(hd "$TRH" '{"reason": "feedback.py add hangs under script"}' 'EOF')"
PSF='import pty; pty.spawn(["python3","/x/feedback.py","send","F001","--confirm","abc"])'
PST='import pty; pty.spawn(["python3","/x/triage.py","apply","12","--confirm","abc"])'
for c in 'python3 -ic/x/feedback.py add' 'python3 "-ic/x/feedback.py" add' 'python3 -ic/x/triage.py record 12' 'python3 "-ic/x/triage.py" record 12'; do
  deny "T024 option-like path [$c], body drives feedback send" bash_gate.py "$(hd "$c <<'EOF'" "$PSF" 'EOF')"
  deny "T024 option-like path [$c], body drives triage apply"  bash_gate.py "$(hd "$c <<'EOF'" "$PST" 'EOF')"
done
for c in 'python3 ^x/feedback.py add' 'python3 ^x/triage.py record 12'; do # zsh extendedglob: ^x/… can expand to -ic/…
  deny "T024 glob path [$c], body drives feedback send" bash_gate.py "$(hd "$c <<'EOF'" "$PSF" 'EOF')"
  deny "T024 glob path [$c], body drives triage apply"  bash_gate.py "$(hd "$c <<'EOF'" "$PST" 'EOF')"
done
XT='python3 scripts/triage.py apply 12 --confirm abc'; XF='python3 scripts/feedback.py send F001 --confirm abc'
xtricks(){ # label, carrier call without the heredoc operator, the other script's write call
  local w="$1" c="$2" p="$3"
  deny "T024 $w: unquoted <<EOF with \$(…)"              bash_gate.py "$(hd "$c <<EOF" "\$($p)" 'EOF')"
  deny "T024 $w: unquoted <<EOF with backticks"           bash_gate.py "$(hd "$c <<EOF" "\`$p\`" 'EOF')"
  deny "T024 $w: command on the delimiter line"           bash_gate.py "$(hd "$c <<'EOF'" '{"t":"x"}' "EOF; $p")"
  deny "T024 $w: line after the delimiter"                bash_gate.py "$(hd "$c <<'EOF'" '{"t":"x"}' 'EOF' "$p")"
  deny "T024 $w: early delimiter inside the body"         bash_gate.py "$(hd "$c <<'EOF'" '{"t":"x"}' 'EOF' "$p" 'EOF')"
  deny "T024 $w: <<- and a tab-indented early delimiter"  bash_gate.py "$(hd "$c <<-'EOF'" '{"t":"x"}' "$(printf '\tEOF')" "$p" 'EOF')"
  deny "T024 $w: header suffix | bash"                    bash_gate.py "$(hd "$c <<'EOF' | bash" "$p" 'EOF')"
  deny "T024 $w: header suffix && x"                      bash_gate.py "$(hd "$c <<'EOF' && x" "$p" 'EOF')"
  deny "T024 $w: # <<EOF comment trick"                   bash_gate.py "$(hd "$c # <<EOF" "$p" 'EOF')"
  deny "T024 $w: \\<<EOF escape trick"                    bash_gate.py "$(hd "$c \\<<EOF" "$p" 'EOF')"
  deny "T024 $w: \"<<EOF quote trick"                     bash_gate.py "$(hd "$c \"<<EOF" "\"; $p" 'EOF')"
  deny "T024 $w: cd x && <capture>"                       bash_gate.py "$(hd "cd x && $c <<'EOF'" "$p" 'EOF')"
  deny "T024 $w: <capture>; echo x"                       bash_gate.py "$(hd "$c <<'EOF'; echo x" "$p" 'EOF')"
}
xtricks "add carrier"    'python3 "/x/scripts/feedback.py" add'     "$XT"
xtricks "record carrier" 'python3 "/x/scripts/triage.py" record 12' "$XF"
deny "T024 add carrier: \${VAR} path"    bash_gate.py "$(hd "python3 \"\${CLAUDE_PLUGIN_ROOT}/scripts/feedback.py\" add <<'EOF'" '{"title": "triage.py apply 12 --confirm abc"}' 'EOF')"
deny "T024 record carrier: \${VAR} path" bash_gate.py "$(hd "python3 \"\${CLAUDE_PLUGIN_ROOT}/scripts/triage.py\" record 12 <<'EOF'" '{"reason": "feedback.py send F001 --confirm abc"}' 'EOF')"
python3 - "$T" "$N" <<'PYX'
import json, sys
t, n = sys.argv[1], sys.argv[2]
probes = {
    "xadd": "python3 \"/x/scripts/feedback.py\" add <<'EOF'\n" + ("triage.py -a apply script " * 25 + "\n") * 100 + "EOF",
    "xrec": "python3 \"/x/scripts/triage.py\" record 12 <<'EOF'\n" + ("feedback.py -a send script " * 25 + "\n") * 100 + "EOF",
}
for k, c in probes.items():
    with open(f"{t}/probe-{k}.json", "w") as f:
        json.dump({"tool_name": "Bash", "cwd": n, "tool_input": {"command": c}}, f)
PYX
rtime "ReDoS: 65 KB cross body in add heredoc"    "$T/probe-xadd.json"
rtime "ReDoS: 67 KB cross body in record heredoc" "$T/probe-xrec.json"
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
