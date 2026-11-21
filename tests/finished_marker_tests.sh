#!/usr/bin/env bash
# T069 (intake I002, F033): when the write gate denies a new .delix/card because the old card is not finished on
# origin/HEAD, the message names the cause if it is one of two: H1, the live record at origin/HEAD is finished but has
# no string file; H2, the card is finished on origin/<default_branch of delix.json> and origin/HEAD does not point
# there. The decision is unchanged. The trigger words are assembled at run time; this file holds none of them, and it
# stays ASCII (check marks and the e-acute are octal escapes; in JSON it is a \uXXXX escape).
# Run: bash tests/finished_marker_tests.sh
set -u
unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"
OK=$'\342\234\224'; NO=$'\342\234\230'; BS=$(printf '\134')
$G --version
T="$(mktemp -d)" || exit 1
W="$T/w"; SRC="$T/s"; DJ="$W/docs/delix/delix.json"; RO="refs/${R}s/origin"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
C55="docs/delix/tasks/T055-x.md"; NEXT="docs/delix/tasks/T056-y.md"; FILE='"file": "'"$C55"'"'
MARKER="delixcrew: .delix/card names T055, which is not finished on origin/HEAD; this worktree belongs to that card. Write nothing under .delix; end with BLOCKED in your final message; the lead opens a new worktree."
H1="Cause: the record of T055 in the STATE on origin/HEAD is finished but has no file field; the lead sets file to the card path in .delix/card and ${P}es."
h2(){ printf 'Cause: the card is finished in the STATE on origin/%s, the default_branch in delix.json, but %s/HEAD does not point at it; if %s is the default branch, the user runs %s %s set-head origin %s in the main checkout.' "$1" "$RO" "$1" "$G" "$R" "$1"; }
SL="delixcrew: .delix/card names T055, which is accepted on origin/HEAD; implementer hooks stay inactive here. Move .delix aside before starting a new card."
PROT="is a protected path (scripts/x.py, Tier 3)"
cfg(){ # [<default_branch as JSON>]: the worktree delix.json; without an argument it has no default_branch
  d=""; [ $# -ge 1 ] && d=', "default_branch": '"$1"
  printf '{"test_command": "touch %s/MARK", "protected_paths": ["scripts/x.py"], "test_paths": ["tests/**"]%s}' \
    "$T" "$d" > "$DJ"; }
rec(){ # <status> [<more members>]: a STATE text with one T055 record
  printf '{"cards": {"T055": {"status": "%s"%s}}}' "$1" "${2:+, $2}"; }

# Fixture W, the card worktree (set up by direct calls, never through a hook)
mkdir -p "$W" && $G -C "$W" init -q && $G -C "$W" symbolic-ref HEAD refs/heads/claude/t1 \
  && $GC -C "$W" commit -q --allow-empty -m init || exit 1
mkdir -p "$W/.delix" "$W/docs/delix/tasks" "$W/scripts"
echo ".delix/" >> "$W/.$G/info/exclude"; echo "$C55" > "$W/.delix/card"; echo x > "$W/scripts/x.py"; cfg
printf '# T055 card\n\n## Files\n- Modify: `src/free.py`\n\n## Steps\n1. none\n' > "$W/$C55"
# Fixture S, the source repo: put commits a STATE on S main and fetches that commit into W's origin/<name>
mkdir -p "$SRC" && $G -C "$SRC" init -q && $G -C "$SRC" symbolic-ref HEAD refs/heads/main || exit 1; SN=0
put(){ # <name> <STATE text> [<path> <text>]: the only docs/ content of a new S main commit, fetched into origin/<name>
  rm -rf "$SRC/docs"; mkdir -p "$SRC/docs/delix"; printf '%s' "$2" > "$SRC/docs/delix/STATE.json"
  if [ $# -ge 4 ]; then mkdir -p "$SRC/$(dirname "$3")"; printf '%s' "$4" > "$SRC/$3"; fi
  SN=$((SN + 1)); $G -C "$SRC" add -A && $GC -C "$SRC" commit -q --allow-empty -m "s$SN" \
    && $G -C "$W" fetch -q "$SRC" "+refs/heads/main:$RO/$1"; }
oh(){ $G -C "$W" symbolic-ref "$RO/HEAD" "$RO/$1"; }  # origin/HEAD -> origin/<name>

hj(){ # <tool> <cwd> <path or command> [content]: hook input
  python3 -c 'import json, sys
tool, cwd, path = sys.argv[1], sys.argv[2], sys.argv[3]
ti = {"command": path} if tool == "Bash" else {"notebook_path": path} if tool == "NotebookEdit" else {"file_path": path}
if len(sys.argv) > 4:
    ti["content"] = sys.argv[4]
print(json.dumps({"tool_name": tool, "cwd": cwd, "tool_input": ti}))' "$@"; }
run(){ OUT=$(printf '%s\n' "$2" | python3 "$S/$1" 2>"$T/err"); RC=$?; ERR=$(cat "$T/err"); }
ok(){ echo "$OK $1"; }
ko(){ echo "$NO $1: $2"; FAIL=1; }
isdeny(){ printf '%s' "$OUT" | grep -qF '"permissionDecision": "deny"'; }
clean(){ ! printf '%s' "$ERR" | grep -qF Traceback; }
why(){ printf '%s' "$OUT" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"])
except Exception:
    print("")'; }
mk(){ # <name> <expected reason> [<tool>]: writing another card path into .delix/card is denied with exactly that reason
  run write_gate.py "$(hj "${3:-Write}" "$W" .delix/card "$NEXT")"; got=$(why)
  if [ $RC -eq 0 ] && isdeny && [ "$got" = "$2" ] && clean; then ok "$1"; else ko "$1" "exit $RC, reason: $got $ERR"; fi; }
prot(){ # <name>: the gate is still active: a protected path that is not in Files is denied
  run write_gate.py "$(hj Write "$W" scripts/x.py x)"
  if [ $RC -eq 0 ] && isdeny && printf '%s' "$OUT" | grep -qF -- "$PROT" && clean; then ok "$1"; else ko "$1" "exit $RC: $OUT $ERR"; fi; }
allow(){ run "$2" "$3"; if [ $RC -eq 0 ] && ! isdeny && clean; then ok "$1"; else ko "$1" "expected allow, exit $RC: $OUT $ERR"; fi; }
once(){ n=$(printf '%s\n' "$ERR" | grep -cxF -- "$SL"); if [ "$n" = 1 ]; then ok "$1"; else ko "$1" "stale line $n times: $ERR"; fi; }
stop(){ rm -f "$W/.delix/test-result.txt" "$T/MARK"
  run stop_gate.py "$(python3 -c 'import json, sys; print(json.dumps({"cwd": sys.argv[1], "stop_hook_active": False}))' "$W")"
  if [ $RC -eq 0 ] && clean && [ ! -e "$T/MARK" ] && [ ! -e "$W/.delix/test-result.txt" ]; then ok "$1"
  else ko "$1" "expected exit 0 and nothing run, exit $RC: $ERR"; fi; }
inactive(){ # <name>: the three hooks are inactive, each with the stale line once
  allow "$1: Write docs/delix/SPEC.md" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)"; once "$1: write gate stale line once"
  allow "$1: Bash echo x > scripts/x.py" bash_gate.py "$(hj Bash "$W" "echo x > scripts/x.py")"; once "$1: Bash gate stale line once"
  stop "$1: Stop exits 0, nothing run"; once "$1: Stop gate stale line once"; }

# ---- H1: the live record at origin/HEAD is finished but has no string file (origin/HEAD -> origin/main, no default_branch)
put main "$(rec accepted "$FILE")"; oh main; inactive "1 C1 accepted, file equal"
put main "$(rec accepted)"; mk "2 C2 accepted, no file: H1" "$MARKER $H1"; prot "2 C2: the gate is still active"
for t in Edit MultiEdit NotebookEdit; do mk "2 C2 $t .delix/card: H1" "$MARKER $H1" "$t"; done
put main "$(rec escalated '"merged": {"pr": 7}')"; mk "3 merged an object, no file: H1" "$MARKER $H1"
put main "$(rec accepted '"file": null')"; mk "3 accepted, file null: H1" "$MARKER $H1"
put main "$(rec accepted '"file": "docs/delix/tasks/T055-other.md"')"; mk "4 file a different string: no cause" "$MARKER"
put main "$(rec in_progress)"; mk "4 in_progress, no file: no cause" "$MARKER"
put main '{"cards": {}, "archive": ["docs/delix/archive/old/STATE.json"]}' docs/delix/archive/old/STATE.json "$(rec accepted)"
mk "4 only an archive record, accepted, no file: no cause" "$MARKER"

# ---- H2: finished on origin/<default_branch> only, origin/HEAD elsewhere
put main "$(rec in_progress "$FILE")"; put v01 "$(rec accepted "$FILE")"; oh main; cfg '"v01"'
mk "5 C3 finished on origin/v01, origin/HEAD -> origin/main: H2" "$MARKER $(h2 v01)"; prot "5 C3: the gate is still active"
SHA=$($G -C "$W" rev-parse "$RO/main"); $G -C "$W" symbolic-ref --delete "$RO/HEAD"; $G -C "$W" $U "$RO/HEAD" "$SHA"
mk "5 origin/HEAD a plain ref, not symbolic: H2" "$MARKER $(h2 v01)"
$G -C "$W" $U -d "$RO/HEAD"; oh v01; inactive "6 C4 origin/HEAD -> origin/v01"; oh main
put main "$(rec accepted)"; mk "7 H1 and H2 both: the H1 sentence only" "$MARKER $H1"; put main "$(rec in_progress "$FILE")"

# ---- the default_branch name is a hint: only a safe name is used (these refs exist and hold the card finished)
L100=$(python3 -c 'print("a" * 100)'); L101="${L100}a"; NA=$(printf 'v\303\25101')
put "$L100" "$(rec accepted "$FILE")"; put "$L101" "$(rec accepted "$FILE")"; put "$NA" "$(rec accepted "$FILE")"
cfg "\"$L100\""; mk "8 control: default_branch of 100 characters: H2" "$MARKER $(h2 "$L100")"
cfg "\"$L101\""; mk "8 default_branch of 101 characters: no cause" "$MARKER"
cfg '"v'"$BS"'u00e901"'; mk "8 default_branch v + U+00E9 + 01: no cause" "$MARKER"
for b in '"v 01"' '"-v01"' '"v..01"' 5; do cfg "$b"; mk "8 default_branch $b: no cause" "$MARKER"; done
cfg '"v01"'; $G -C "$W" $U -d "$RO/v01"; mk "9 default_branch v01, origin/v01 missing: no cause" "$MARKER"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
