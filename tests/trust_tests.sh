#!/usr/bin/env bash
# Issue #8: a repo that ships its own .delix/card must not switch the hooks on (the Stop gate would run the repo's
# delix.json commands). The card counts only as a local, untracked file in a git work tree. Run: bash tests/trust_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"
G="git -c user.email=t@t -c user.name=t -c commit.gpgsign=false"
mkrepo(){ # dir → repo whose delix.json test_command touches $1/MARK (the "attacker command")
  mkdir -p "$1/docs/delix"
  printf '{"test_command":"touch %s/MARK","extra_checks":[]}' "$1" > "$1/docs/delix/delix.json"; }
stop(){ printf '{"cwd":"%s","stop_hook_active":false}' "$1" | python3 "$S/stop_gate.py" 2>"$1.err"; }
ran(){ [ -e "$1/MARK" ]; }
ok(){ echo "✔ $1"; }; ko(){ echo "✘ $1"; FAIL=1; }
# T026 (REQ-1–REQ-4, K203, K206): the record path is replaced through the common module attribute (runpy), never env;
# key.py recomputes the REQ-1 pair independently of common.py; pty.py types the answer on a pseudo-terminal
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
cat > "$T/key.py" <<'PY'
import hashlib, json, os, subprocess, sys
mode, cwd = sys.argv[1], sys.argv[2]
try:
    with open(os.path.join(cwd, "docs", "delix", "delix.json"), encoding="utf-8") as f:
        cfg = json.load(f)
except Exception:
    cfg = {}
cfg = cfg if isinstance(cfg, dict) else {}
extra = cfg.get("extra_checks") or []
cmds = [cfg.get("test_command") or "pytest -q"] + (extra if isinstance(extra, list) else [extra])
sha = hashlib.sha256(json.dumps(cmds, ensure_ascii=False, separators=(",", ":")).encode("utf-8")).hexdigest()
if mode == "h12":
    print(sha[:12]); sys.exit(0)
rec = sys.argv[3]
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
cat > "$T/pty.py" <<'PY'
import os, select, subprocess, sys, time
cwd, answer, args = sys.argv[1], sys.argv[2], sys.argv[3:]
m, s = os.openpty()
p = subprocess.Popen([sys.executable] + args, cwd=cwd, stdin=s, stdout=s, stderr=s)
os.close(s)
buf, sent, end = b"", False, time.monotonic() + 20
while time.monotonic() < end:
    if select.select([m], [], [], 0.1)[0]:
        try:
            chunk = os.read(m, 4096)
        except OSError:
            break
        if not chunk:
            break
        buf += chunk
        if not sent and b"then the hash): " in buf:
            os.write(m, answer.encode() + b"\n"); sent = True
    elif p.poll() is not None:
        break
rc = p.wait(timeout=20); os.close(m)
sys.stdout.write(buf.decode("utf-8", "replace")); sys.exit(rc)
PY
tstop(){ # dir[, VAR=value] → Stop gate with the test record; stderr in $1.err
  printf '{"cwd":"%s","stop_hook_active":false}' "$1" | env ${2:+"$2"} python3 "$T/run.py" "$S" "$TREC" "$S/stop_gate.py" 2>"$1.err"; }
approve(){ python3 "$T/key.py" approve "$1" "$TREC"; }
h12(){ python3 "$T/key.py" h12 "$1"; }

# 1) Foreign repo: .delix/card committed together with delix.json (git clone delivers both)
R="$T/foreign"; mkrepo "$R"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; rc=$?
ran "$R" && ko "tracked card: repo command ran" || ok "tracked card: repo command not run"
[ $rc -eq 0 ] && ok "tracked card: Stop exits 0" || ko "tracked card: Stop exit $rc"
[ "$(wc -l < "$R.err")" -eq 1 ] && grep -q '^delixcrew: ' "$R.err" && ok "tracked card: one stderr line" || ko "tracked card: stderr: $(cat "$R.err")"
out=$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"docs/delix/delix.json"}}' "$R" | python3 "$S/write_gate.py" 2>/dev/null)
echo "$out" | grep -q deny && ko "tracked card: write gate active" || ok "tracked card: write gate inactive"

# 2) Foreign repo: committed symlink .delix → a dir holding a committed 'card' (git sees no .delix/card)
R="$T/symlink"; mkrepo "$R"; mkdir -p "$R/docs/x"; echo "docs/delix/tasks/T001-x.md" > "$R/docs/x/card"; ln -s docs/x "$R/.delix"
git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; ran "$R" && ko "symlinked .delix: repo command ran" || ok "symlinked .delix: repo command not run"

# 3) Not a git work tree (archive download): card is not trusted
R="$T/archive"; mkrepo "$R"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
stop "$R"; ran "$R" && ko "no git: repo command ran" || ok "no git: repo command not run"

# 4) Normal dispatch: delix.json committed, .delix/ written locally and excluded (.git/info/exclude) → gate runs
R="$T/worktree"; mkrepo "$R"; git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
echo ".delix/" >> "$R/.git/info/exclude"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
approve "$R"; tstop "$R"; rc=$?
ran "$R" && ok "local card: Stop gate runs the test command" || ko "local card: test command not run"
[ $rc -eq 0 ] && ok "local card: passing command → exit 0" || ko "local card: Stop exit $rc"
out=$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"docs/delix/delix.json"}}' "$R" | python3 "$S/write_gate.py" 2>/dev/null)
echo "$out" | grep -q deny && ok "local card: write gate active" || ko "local card: write gate inactive"

# 4b) Real dispatch shape: linked worktree (git worktree add), .delix/ excluded in the common .git/info/exclude
R="$T/wt-main"; mkrepo "$R"; git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
echo ".delix/" >> "$R/.git/info/exclude"; W="$T/wt-linked"; git -C "$R" worktree add -q --detach "$W"
sed -i.bak "s|$R/MARK|$W/MARK|" "$W/docs/delix/delix.json"; rm -f "$W/docs/delix/delix.json.bak"
mkdir -p "$W/.delix"; echo "docs/delix/tasks/T001-x.md" > "$W/.delix/card"
approve "$W"; tstop "$W"; ran "$W" && ok "linked worktree: Stop gate runs the test command" || ko "linked worktree: test command not run"

# 4c) Foreign repo: only 'card' is a committed symlink into a tracked dir
R="$T/cardlink"; mkrepo "$R"; mkdir -p "$R/docs/x" "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/docs/x/card"
ln -s ../docs/x/card "$R/.delix/card"; git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; ran "$R" && ko "symlinked card: repo command ran" || ok "symlinked card: repo command not run"

# 5) Foreign repo: case variant .Delix/card (case-insensitive file systems see it as .delix/card; git pathspecs do not).
#    Proves something only on a case-insensitive file system (macOS); on Linux .delix/card does not exist at all.
R="$T/case"; mkrepo "$R"; mkdir -p "$R/.Delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.Delix/card"
git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; ran "$R" && ko "case variant .Delix: repo command ran" || ok "case variant .Delix: repo command not run"

# 6) Foreign repo: submodule at .delix whose repo holds 'card' (superproject index only has the gitlink)
M="$T/subsrc"; mkdir -p "$M"; echo "docs/delix/tasks/T001-x.md" > "$M/card"
git -C "$M" init -q && $G -C "$M" add -A && $G -C "$M" commit -qm x
R="$T/submodule"; mkrepo "$R"; git -C "$R" init -q
$G -C "$R" -c protocol.file.allow=always submodule add -q "$M" .delix 2>/dev/null && $G -C "$R" add -A && $G -C "$R" commit -qm x
[ -f "$R/.delix/card" ] || ko "submodule fixture not built"
stop "$R"; ran "$R" && ko "submodule .delix: repo command ran" || ok "submodule .delix: repo command not run"

# 7) Archive extracted inside another git repo: git walks up to the parent, where .delix/card is untracked
P="$T/parent"; mkdir -p "$P"; git -C "$P" init -q
R="$P/vendor/pkg"; mkrepo "$R"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
stop "$R"; ran "$R" && ko "archive inside a parent repo: repo command ran" || ok "archive inside a parent repo: repo command not run"
# T026 REQ-1/REQ-2 (K201, K213): an archive with its own .git and an empty record → nothing runs, exit 2, three lines
A="$T/own-git"; mkrepo "$A"; git -C "$A" init -q; mkdir -p "$A/.delix"; echo "docs/delix/tasks/T001-x.md" > "$A/.delix/card"
tstop "$A"; rc=$?
ran "$A" && ko "T026 archive with its own .git: command ran" || ok "T026 archive with its own .git: command not run"
[ $rc -eq 2 ] && ok "T026 archive with its own .git: exit 2" || ko "T026 archive with its own .git: exit $rc"
[ "$(wc -l < "$A.err")" -eq 3 ] && grep -qF "trust.py allow" "$A.err" && grep -qF "write BLOCKED in .delix/report.md naming this command, then stop" "$A.err" \
  && ok "T026 not approved: three stderr lines, trust.py allow, the BLOCKED step" || ko "T026 not approved: stderr: $(cat "$A.err")"
grep -qxF "[not run: commands not approved, hash $(h12 "$A")]" "$A/.delix/test-result.txt" && ok "T026 not approved: hash line in test-result.txt" || ko "T026 not approved: test-result: $(cat "$A/.delix/test-result.txt" 2>&1)"
echo "BLOCKED: Stop gate commands not approved" > "$A/.delix/report.md"; tstop "$A"; rc=$?
[ $rc -eq 0 ] && ! ran "$A" && ok "T026 not approved + BLOCKED report: exit 0" || ko "T026 not approved + BLOCKED report: exit $rc"
rm -f "$A/.delix/report.md" "$A/.delix/test-result.txt"; echo keep > "$T/outside.txt"; ln -s "$T/outside.txt" "$A/.delix/test-result.txt"
tstop "$A"; [ "$(cat "$T/outside.txt")" = keep ] && grep -qF "test-result.txt is a symlink" "$A.err" && ok "T026 symlinked test-result.txt, not approved: target unchanged, warning" || ko "T026 symlinked test-result.txt, not approved: $(cat "$T/outside.txt") / $(cat "$A.err")"
approve "$A"; tstop "$A"; [ "$(cat "$T/outside.txt")" = keep ] && ran "$A" && ok "T026 symlinked test-result.txt, approved: command runs, target unchanged" || ko "T026 symlinked test-result.txt, approved: $(cat "$A.err")"
NS="$T/nonstr"; mkrepo "$NS"; printf '{"test_command":"touch %s/MARK","extra_checks":"echo x"}' "$NS" > "$NS/docs/delix/delix.json"
git -C "$NS" init -q; mkdir -p "$NS/.delix"; echo "docs/delix/tasks/T001-x.md" > "$NS/.delix/card"
tstop "$NS"; rc=$?
! ran "$NS" && [ $rc -eq 2 ] && grep -qF "[not run: commands not approved, hash " "$NS/.delix/test-result.txt" && ok "T026 extra_checks not a list: nothing runs, exit 2" || ko "T026 extra_checks not a list: rc $rc"
(cd "$NS" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 7 ] && [ "$(wc -l < "$T/a.err")" -eq 1 ] && ok "T026 allow with a non-string command: exit 7, one stderr line" || ko "T026 allow with a non-string command: rc $rc: $(cat "$T/a.err")"
# T026 REQ-1 (K199, K211, K212): the approved checkout and its worktrees run; a symlinked or faked .git and GIT_* env do not
V="$T/victim"; mkrepo "$V"; git -C "$V" init -q && $G -C "$V" add -A && $G -C "$V" commit -qm x
echo ".delix/" >> "$V/.git/info/exclude"; mkdir -p "$V/.delix"; echo "docs/delix/tasks/T001-x.md" > "$V/.delix/card"
approve "$V"; tstop "$V"; ran "$V" && ok "T026 approved main checkout: command runs" || ko "T026 approved main checkout: not run: $(cat "$V.err")"; rm -f "$V/MARK"
VW="$T/victim-wt"; git -C "$V" worktree add -q --detach "$VW"; mkdir -p "$VW/.delix"; echo "docs/delix/tasks/T001-x.md" > "$VW/.delix/card"
tstop "$VW"; rc=$?; ran "$V" && [ $rc -eq 0 ] && ok "T026 worktree of the approved checkout: runs, exit 0" || ko "T026 worktree of the approved checkout: rc $rc: $(cat "$VW.err")"; rm -f "$V/MARK"
fake(){ mkdir -p "$1/docs/delix" "$1/.delix"; cp "$V/docs/delix/delix.json" "$1/docs/delix/"; echo "docs/delix/tasks/T001-x.md" > "$1/.delix/card"; }
fake "$T/ln-abs"; ln -s "$V/.git" "$T/ln-abs/.git"
fake "$T/ln-rel"; ln -s ../victim/.git "$T/ln-rel/.git"
fake "$T/ln-wt"; ln -s "$VW/.git" "$T/ln-wt/.git"
for d in ln-abs ln-rel ln-wt; do
  tstop "$T/$d"; ran "$V" && ko "T026 symlinked .git ($d): command ran" || ok "T026 symlinked .git ($d): command not run"; rm -f "$V/MARK"
done
fake "$T/gitfile"; printf 'gitdir: %s\n' "$(cd "$V/.git/worktrees/victim-wt" && pwd -P)" > "$T/gitfile/.git"
tstop "$T/gitfile"; ran "$V" && ko "T026 gitfile into the approved worktree entry: command ran" || ok "T026 gitfile into the approved worktree entry: command not run"; rm -f "$V/MARK"
X="$T/plain"; mkrepo "$X"; cp "$V/docs/delix/delix.json" "$X/docs/delix/delix.json"; git -C "$X" init -q; mkdir -p "$X/.delix"; echo "docs/delix/tasks/T001-x.md" > "$X/.delix/card"
tstop "$X" "GIT_DIR=$V/.git"; ran "$V" && ko "T026 GIT_DIR=<approved .git> in the hook env: command ran" || ok "T026 GIT_DIR=<approved .git> in the hook env: command not run"; rm -f "$V/MARK"
tstop "$V" "GIT_DIR=$X/.git"; ran "$V" && ok "T026 GIT_DIR=<other .git> in the hook env: approved checkout still runs" || ko "T026 GIT_DIR=<other .git>: not run: $(cat "$V.err")"; rm -f "$V/MARK"
# T026 REQ-1/REQ-3 (K214): a changed delix.json in the worktree needs its own approval; the main checkout keeps its own
sed -i.bak "s|$V/MARK|$VW/MARK2|" "$VW/docs/delix/delix.json"; rm -f "$VW/docs/delix/delix.json.bak"
tstop "$VW"; rc=$?
[ ! -e "$VW/MARK2" ] && [ $rc -eq 2 ] && grep -qxF "[not run: commands not approved, hash $(h12 "$VW")]" "$VW/.delix/test-result.txt" && ok "T026 changed delix.json in the worktree: not run, exit 2" || ko "T026 changed delix.json in the worktree: rc $rc"
out=$(python3 "$T/pty.py" "$VW" "TRUST $(h12 "$VW")" "$T/run.py" "$S" "$TREC" "$S/trust.py" allow); rc=$?
[ $rc -eq 0 ] && ok "T026 allow on a terminal with TRUST <h12>: exit 0" || ko "T026 allow on a terminal: rc $rc: $out"
echo "$out" | grep -qF "delix.json differs from HEAD" && ok "T026 allow warns that delix.json differs from HEAD" || ko "T026 allow: no HEAD warning: $out"
tstop "$VW"; [ -e "$VW/MARK2" ] && ok "T026 after its own approval the worktree runs" || ko "T026 after its own approval: not run: $(cat "$VW.err")"
tstop "$V"; ran "$V" && ok "T026 the main checkout's approval still holds" || ko "T026 the main checkout's approval was lost"; rm -f "$V/MARK"
D2="$T/home2/.claude/delixcrew"; mkdir -p "$D2"; chmod 755 "$D2"
out=$(python3 "$T/pty.py" "$V" "TRUST $(h12 "$V")" "$T/run.py" "$S" "$D2/trust.json" "$S/trust.py" allow); rc=$?
[ $rc -eq 0 ] && python3 - "$D2/trust.json" "$(cd "$V/.git" && pwd -P)" "$(h12 "$V")" <<'PY' && ok "T026 allow: dir 0700 (was 0755), file 0600, entry (realpath, sha256)" || ko "T026 allow record: rc $rc: $out"
import json, os, sys
p, common, h = sys.argv[1:4]
with open(p, encoding="utf-8") as f:
    d = json.load(f)
e = d["entries"][-1]
good = (os.stat(p).st_mode & 0o777 == 0o600 and os.stat(os.path.dirname(p)).st_mode & 0o777 == 0o700 and d["version"] == 1
        and e["git_common_dir"] == common and e["sha256"].startswith(h) and len(e["sha256"]) == 64 and bool(e.get("approved_at")))
sys.exit(0 if good else 1)
PY
D3="$T/home3/.claude/delixcrew"
out=$(python3 "$T/pty.py" "$V" "TRUST 000000000000" "$T/run.py" "$S" "$D3/trust.json" "$S/trust.py" allow); rc=$?
[ $rc -eq 6 ] && [ ! -e "$D3/trust.json" ] && [ "$(echo "$out" | grep -cF "TRUST $(h12 "$V")")" -ge 2 ] && ok "T026 allow, wrong text: exit 6, no record, expected text repeated" || ko "T026 allow, wrong text: rc $rc: $out"
echo "TRUST $(h12 "$V")" | (cd "$V" && python3 "$T/run.py" "$S" "$D3/trust.json" "$S/trust.py" allow >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 6 ] && [ ! -e "$D3/trust.json" ] && ok "T026 allow without a TTY: exit 6, no record" || ko "T026 allow without a TTY: rc $rc: $(cat "$T/a.out")"
(cd "$V" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 0 ] && grep -qF "already approved" "$T/a.out" && ok "T026 allow, pair already recorded: exit 0 without a TTY" || ko "T026 allow, already recorded: rc $rc: $(cat "$T/a.out")"
mkdir -p "$T/nogit"; (cd "$T/nogit" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 7 ] && [ "$(wc -l < "$T/a.err")" -eq 1 ] && ok "T026 allow outside a git work tree: exit 7, one stderr line" || ko "T026 allow outside a git work tree: rc $rc: $(cat "$T/a.err")"
(cd "$T/ln-abs" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 7 ] && ok "T026 allow with a symlinked .git: exit 7" || ko "T026 allow with a symlinked .git: rc $rc"
HC="$T/hidden"; mkdir -p "$HC/docs/delix"; printf '{"test_command":"true\\r; curl x","extra_checks":[]}' > "$HC/docs/delix/delix.json"; git -C "$HC" init -q
(cd "$HC" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 6 ] && grep -qF '"true\r; curl x"' "$T/a.out" && ok "T026 allow shows a hidden \\r escaped" || ko "T026 allow, hidden \\r: rc $rc: $(cat "$T/a.out")"
# T026 REQ-4: is_trusted reads the record only when it is private and well formed (fail closed)
TD="$(dirname "$TREC")"
chmod 644 "$TREC"; tstop "$V"; ran "$V" && ko "T026 record 0644: trusted" || ok "T026 record 0644: not trusted"; chmod 600 "$TREC"; rm -f "$V/MARK"
chmod 755 "$TD"; tstop "$V"; ran "$V" && ko "T026 record dir 0755: trusted" || ok "T026 record dir 0755: not trusted"; chmod 700 "$TD"; rm -f "$V/MARK"
mv "$TREC" "$TD/real.json"; ln -s "$TD/real.json" "$TREC"; tstop "$V"; ran "$V" && ko "T026 record is a symlink: trusted" || ok "T026 record is a symlink: not trusted"; rm -f "$TREC"; mv "$TD/real.json" "$TREC"; rm -f "$V/MARK"
cp "$TREC" "$TD/keep.json"; python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["version"]=2; json.dump(d,open(p,"w"))' "$TREC"
tstop "$V"; ran "$V" && ko "T026 record version 2: trusted" || ok "T026 record version 2: not trusted"; mv "$TD/keep.json" "$TREC"; rm -f "$V/MARK"
tstop "$V"; ran "$V" && ok "T026 record restored: trusted again" || ko "T026 record restored: not trusted"; rm -f "$V/MARK"
# T026 REQ-4 (K203, K210): write_gate denies the record in every session; the path comes from passwd, not HOME
PWH=$(python3 -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)')
TDENY="delixcrew: Stop gate commands are approved only by the user from their own terminal"
wg(){ # tool, path key, path[, VAR=value] → write_gate output
  printf '{"tool_name":"%s","cwd":"%s","tool_input":{"%s":"%s"}}' "$1" "$T" "$2" "$3" | env ${4:+"$4"} python3 "$S/write_gate.py" 2>/dev/null; }
for t in Write Edit MultiEdit; do
  wg "$t" file_path "$PWH/.claude/delixcrew/trust.json" | grep -qF "$TDENY" && ok "T026 write_gate: $t of the record denied" || ko "T026 write_gate: $t of the record not denied"
done
wg NotebookEdit notebook_path "$PWH/.claude/delixcrew/trust.json" | grep -qF "$TDENY" && ok "T026 write_gate: NotebookEdit of the record denied" || ko "T026 write_gate: NotebookEdit not denied"
wg Write file_path "$PWH/.CLAUDE/DelixCrew/Trust.json" | grep -qF "$TDENY" && ok "T026 write_gate: letter-case variant denied" || ko "T026 write_gate: letter-case variant not denied"
wg Write file_path "$PWH/.claude/delixcrew/trust.json" "HOME=$T/h" | grep -qF "$TDENY" && ok "T026 write_gate: another HOME does not move the record" || ko "T026 write_gate: HOME moved the record"
wg Write file_path "$T/h/.claude/delixcrew/trust.json" "HOME=$T/h" | grep -qF "$TDENY" && ko "T026 write_gate: a HOME-based path counted as the record" || ok "T026 write_gate: a HOME-based lookalike is not the record"
wg Write file_path "$PWH/.claude/delixcrew/trust.json.bak" | grep -qF "$TDENY" && ko "T026 write_gate: a sibling file denied" || ok "T026 write_gate: a sibling file is not the record"
printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s"}}' "$T" "$TREC" | python3 "$T/run.py" "$S" "$TREC" "$S/write_gate.py" 2>/dev/null | grep -qF "$TDENY" && ok "T026 write_gate reads common.trust_file at run time" || ko "T026 write_gate: patched trust_file not used"
# T026 round 1 (K217): allow runs no repo-chosen diff helper before the user confirms; the HEAD warning still shows
DX="$T/diffext"; mkrepo "$DX"; git -C "$DX" init -q && $G -C "$DX" add -A && $G -C "$DX" commit -qm x
printf '#!/bin/sh\ntouch %s/MARK\nexit 1\n' "$DX" > "$T/diffhelper.sh"; chmod +x "$T/diffhelper.sh"
git -C "$DX" config diff.external "$T/diffhelper.sh"; git -C "$DX" config diff.trustExitCode true
printf '{"test_command":"true","extra_checks":[]}' > "$DX/docs/delix/delix.json"
(cd "$DX" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 6 ] && ! ran "$DX" && grep -qF "differs from HEAD" "$T/a.out" && ok "T026 allow with diff.external: helper not run, exit 6, HEAD warning" || ko "T026 allow with diff.external: rc $rc, MARK $(ran "$DX" && echo exists || echo absent): $(cat "$T/a.out")"
(cd "$V" && $G diff --quiet HEAD -- docs/delix/delix.json) && (cd "$V" && python3 "$T/run.py" "$S" "$T/home4/.claude/delixcrew/trust.json" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); \
  ! grep -qF "differs from HEAD" "$T/a.out" && ok "T026 allow, delix.json same as HEAD: no warning" || ko "T026 allow, delix.json same as HEAD: warned: $(cat "$T/a.out")"
# T026 round 1 (K218): a hardlinked .delix/test-result.txt is never truncated or overwritten
HL="$T/hardlink"; mkrepo "$HL"; git -C "$HL" init -q; mkdir -p "$HL/.delix"; echo "docs/delix/tasks/T001-x.md" > "$HL/.delix/card"
echo keep > "$T/outside2.txt"; ln "$T/outside2.txt" "$HL/.delix/test-result.txt"
tstop "$HL"; rc=$?
[ "$(cat "$T/outside2.txt")" = keep ] && [ $rc -eq 2 ] && grep -qF "hardlink" "$HL.err" && ok "T026 hardlinked test-result.txt, not approved: target unchanged, warning, exit 2" || ko "T026 hardlinked test-result.txt, not approved: rc $rc: $(cat "$T/outside2.txt") / $(cat "$HL.err")"
approve "$HL"; tstop "$HL"; rc=$?
[ "$(cat "$T/outside2.txt")" = keep ] && ran "$HL" && [ $rc -eq 0 ] && ok "T026 hardlinked test-result.txt, approved: command runs, target unchanged" || ko "T026 hardlinked test-result.txt, approved: rc $rc: $(cat "$T/outside2.txt") / $(cat "$HL.err")"
rm -f "$HL/.delix/test-result.txt" "$HL/MARK"; echo stale > "$HL/.delix/test-result.txt"; tstop "$HL"
! grep -qF stale "$HL/.delix/test-result.txt" && grep -qF "[exit 0]" "$HL/.delix/test-result.txt" && ok "T026 regular test-result.txt is still truncated and written" || ko "T026 regular test-result.txt: $(cat "$HL/.delix/test-result.txt")"
# T026 round 1 (K219): git_common_dir is shown escaped (a dir name can hide \r)
CRD="$T/cr$(printf '\r')dir"; mkrepo "$CRD"; git -C "$CRD" init -q
(cd "$CRD" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 6 ] && grep -qF 'cr\rdir/.git' "$T/a.out" && ! grep -q "$(printf '\r')" "$T/a.out" && ok "T026 allow prompt shows git_common_dir escaped" || ko "T026 allow prompt, raw git_common_dir: rc $rc"
approve "$CRD"; (cd "$CRD" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 0 ] && grep -qF "already approved" "$T/a.out" && grep -qF 'cr\rdir/.git' "$T/a.out" && ! grep -q "$(printf '\r')" "$T/a.out" && ok "T026 already approved line shows git_common_dir escaped" || ko "T026 already approved, raw git_common_dir: rc $rc"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
