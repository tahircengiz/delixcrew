#!/usr/bin/env bash
# T056 (Spec D REQ-1, REQ-2, REQ-5): a finished card's .delix/card leaves the three hooks inactive (the card state is
# read from origin/HEAD only), a delix.json the hooks cannot read keeps a card worktree blocked, and protected and
# test paths also match by real path and folded case. The trigger words are assembled at run time; this file holds
# none of them, and it stays ASCII (check marks, the lock sign and the bad byte are octal escapes; other non-ASCII
# text is a JSON \uXXXX escape).
# Run: bash tests/stale_card_tests.sh
set -u
unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; U=update; U="${U}-ref"; R=rem; R="${R}ote"; GU=$(echo "$G" | tr a-z A-Z)
OK=$'\342\234\224'; NO=$'\342\234\230'; LOCK=$(printf '\360\237\224\220'); BS=$(printf '\134')
$G --version
T="$(mktemp -d)"; W="$T/w"; SRC="$T/s"; DJ="$W/docs/delix/delix.json"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
C55="docs/delix/tasks/T055-release-0-7-2.md"
sl(){ printf 'delixcrew: .delix/card names %s, which is accepted on origin/HEAD; implementer hooks stay inactive here. Move .delix aside before starting a new card.' "$1"; }
MARKER="delixcrew: .delix/card names T055, which is not finished on origin/HEAD; this worktree belongs to that card. Write nothing under .delix; end with BLOCKED in your final message; the lead opens a new worktree."
CONFIG="delixcrew: docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; this card worktree stays blocked until the user fixes it from their own terminal"
DOCS="is the card or under docs/delix; the implementer cannot change these"
PROT="is a protected path (scripts/x.py, Tier 3)"
BPROT="the command writes to a protected path"
TEST="cannot be modified (no test weakening)"
VALID='{"test_command": "touch '"$T"'/MARK", "protected_paths": ["scripts/x.py", "scripts/common.py", "scripts/caf'"${BS}"'u00e9.py"], "test_paths": ["tests/**"]}'

# Fixture W, the card worktree (setup by direct calls, never through a hook)
mkdir -p "$W" && $G -C "$W" init -q && $G -C "$W" symbolic-ref HEAD refs/heads/claude/t1 \
  && $GC -C "$W" commit -q --allow-empty -m init
mkdir -p "$W/.delix" "$W/docs/delix/tasks" "$W/scripts" "$W/tests" "$W/src"
echo ".delix/" >> "$W/.$G/info/exclude"; echo "$C55" > "$W/.delix/card"; printf '%s' "$VALID" > "$DJ"
echo x > "$W/scripts/x.py"; echo x > "$W/scripts/common.py"; echo x > "$W/tests/a_tests.sh"
ln -s scripts "$W/lnk"; ln -s tests "$W/tlink"; ln -s ../scripts/common.py "$W/docs/a.md"
ln -s ../tests/a_tests.sh "$W/src/a.py"
card(){ # <yes|no> <path>...: the T055 card file, with the lock line when $1 is yes, and these paths under Files
  a=$1; shift
  { printf '# T055 card\n\n| id | tier |\n|---|---|\n| T055 | 3 |\n\n'
    [ "$a" = yes ] && printf '**%s Approved:** 2026-11-19 t\n\n' "$LOCK"
    printf '## Files\n'; for f in "$@"; do printf -- '- Modify: `%s`\n' "$f"; done
    printf '\n## Steps\n1. none\n'; } > "$W/$C55"
}
card no src/free.py
# Fixture S, the source repo: STATE commits on its main are fetched into W's origin/main; origin/HEAD -> origin/main
mkdir -p "$SRC" && $G -C "$SRC" init -q && $G -C "$SRC" symbolic-ref HEAD refs/heads/main; SN=0
statef(){ # <STATE file> [<path> <file>]...: the only docs/ content of a new S main commit, then fetched into W
  rm -rf "$SRC/docs"; mkdir -p "$SRC/docs/delix"; cp "$1" "$SRC/docs/delix/STATE.json"; shift
  while [ $# -ge 2 ]; do mkdir -p "$SRC/$(dirname "$1")"; cp "$2" "$SRC/$1"; shift 2; done
  SN=$((SN + 1)); $G -C "$SRC" add -A && $GC -C "$SRC" commit -q --allow-empty -m "s$SN"
  $G -C "$W" fetch -q "$SRC" "+refs/heads/main:refs/${R}s/origin/main"
  $G -C "$W" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
}
state(){ printf '%s' "$1" > "$T/state.json"; statef "$T/state.json"; }
one(){ # <id> <file> <status> [<merged JSON>]: a STATE text with one card record
  m=""; [ $# -ge 4 ] && m=', "merged": '"$4"
  printf '{"cards": {"%s": {"file": "%s", "status": "%s"%s}}}' "$1" "$2" "$3" "$m"; }

hj(){ # <tool> <cwd> <path or command> [content]: hook input; \uXXXX in the path or the content decodes as in JSON
  python3 -c 'import json, sys
d = lambda s: json.loads("\"" + s + "\"") if "\\u" in s else s
tool, cwd, path = sys.argv[1], sys.argv[2], d(sys.argv[3])
ti = {"command": path} if tool == "Bash" else {"notebook_path": path} if tool == "NotebookEdit" else {"file_path": path}
if len(sys.argv) > 4:
    ti["content"] = d(sys.argv[4])
print(json.dumps({"tool_name": tool, "cwd": cwd, "tool_input": ti}))' "$@"; }
run(){ OUT=$(printf '%s\n' "$2" | python3 "$S/$1" 2>"$T/err"); RC=$?; ERR=$(cat "$T/err"); }
ok(){ echo "$OK $1"; }
ko(){ echo "$NO $1: $2"; FAIL=1; }
isdeny(){ printf '%s' "$OUT" | grep -qF '"permissionDecision": "deny"'; }
clean(){ ! printf '%s' "$ERR" | grep -qF Traceback; }
# allow = exit 0, no deny decision, no Traceback; deny = exit 0, the deny decision, the message, no Traceback
allow(){ run "$2" "$3"; if [ $RC -eq 0 ] && ! isdeny && clean; then ok "$1"; else ko "$1" "expected allow, exit $RC: $OUT $ERR"; fi; }
deny(){ run "$2" "$3"; if [ $RC -eq 0 ] && isdeny && printf '%s' "$OUT" | grep -qF -- "$4" && clean; then ok "$1"; else ko "$1" "expected deny ($4), exit $RC: $OUT $ERR"; fi; }
once(){ # <name> <id>: the stale line of the last run is on stderr exactly once
  n=$(printf '%s\n' "$ERR" | grep -cxF -- "$(sl "$2")"); if [ "$n" = 1 ]; then ok "$1"; else ko "$1" "stale line $n times: $ERR"; fi; }
stop(){ # <name> <exit>: the Stop gate in W; exit 0 also means no test-result.txt; never the MARK of a command run
  rm -f "$W/.delix/test-result.txt" "$T/MARK"
  run stop_gate.py "$(python3 -c 'import json, sys; print(json.dumps({"cwd": sys.argv[1], "stop_hook_active": False}))' "$W")"
  if [ $RC -eq "$2" ] && clean && [ ! -e "$T/MARK" ] && { [ "$2" != 0 ] || [ ! -e "$W/.delix/test-result.txt" ]; }; then
    ok "$1"; else ko "$1" "expected exit $2, exit $RC: $ERR"; fi; }
spec(){ deny "$1: Write docs/delix/SPEC.md" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)" "$DOCS"; }
inactive(){ # <name> <id>: all three hooks inactive, each with the stale line once
  allow "$1: Write docs/delix/SPEC.md" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)"; once "$1: write gate stale line once" "$2"
  allow "$1: Bash echo x > scripts/x.py" bash_gate.py "$(hj Bash "$W" "echo x > scripts/x.py")"; once "$1: Bash gate stale line once" "$2"
  stop "$1: Stop exits 0, nothing run" 0; once "$1: Stop gate stale line once" "$2"; }
active(){ # <name>: the implementer rules apply in all three hooks
  spec "$1"
  deny "$1: Bash echo x > scripts/x.py" bash_gate.py "$(hj Bash "$W" "echo x > scripts/x.py")" "$BPROT"
  stop "$1: Stop exits 2" 2; }

# ---- REQ-1: a finished card's marker leaves the hooks inactive (K344, K345, K352, K353)
state "$(one T055 "$C55" accepted)"; inactive "1 accepted" T055
state "$(one T055 "$C55" escalated '{"pr": 7}')"; inactive "2 escalated, merged an object" T055
for v in open in_progress in_review fixing rejected escalated; do state "$(one T055 "$C55" "$v")"; active "3 $v"; done
state "$(one T055 "$C55" escalated null)"; active "3 escalated, merged null"
state "$(one T055 "$C55" escalated '"x"')"; active "3 escalated, merged a string"

state '{"cards": {}}'; spec "4 card in no STATE"
state "$(one T055 docs/delix/tasks/T055-other.md accepted)"; spec "4 file differs"
state "$(one T055 "$C55" accepted)"
echo docs/delix/tasks/x.md > "$W/.delix/card"; spec "4 marker without an id"
echo docs/delix/tasks/t055-x.md > "$W/.delix/card"; spec "4 marker with a lower-case t"
echo "$C55" > "$W/.delix/card"
allow "4 control: marker restored, accepted" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)"
$G -C "$W" symbolic-ref --delete "refs/${R}s/origin/HEAD"; spec "4 origin/HEAD deleted"
state 'not json'; spec "4 STATE not JSON"
state '[]'; spec "4 STATE []"
state '{"cards": [{"file": "'"$C55"'", "status": "accepted"}]}'; spec "4 cards a list"
big(){ python3 -c 'import json, sys
head = json.dumps({"cards": {"T055": {"file": sys.argv[1], "status": "accepted"}}, "pad": ""})
sys.stdout.write(head[:-2] + "a" * (int(sys.argv[2]) - len(head)) + "\"}")' "$C55" "$1" > "$T/state.json"; }
big $(( (1 << 20) + 1 )); statef "$T/state.json"; spec "4 STATE over 1 MiB"
big $(( 1 << 20 )); statef "$T/state.json"
allow "4 control: STATE of exactly 1 MiB, accepted" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)"
printf '{"cards": {"T055": {"file": "%s", "status": "accepted"}}, "x": "\377"}' "$C55" > "$T/state.json"
statef "$T/state.json"; spec "4 STATE holds byte 377"

# Spoofed anchors: an exact-name read only, no replace objects (K352)
state "$(one T055 "$C55" accepted)"; A=$($G -C "$W" rev-parse "refs/${R}s/origin/main")
$G -C "$W" symbolic-ref --delete "refs/${R}s/origin/HEAD"
$G -C "$W" $U "refs/tags/refs/${R}s/origin/HEAD" "$A"; spec "5 origin/HEAD deleted, a tag of that name accepted"
$G -C "$W" $U -d "refs/tags/refs/${R}s/origin/HEAD"
$G -C "$W" $U "refs/heads/refs/${R}s/origin/HEAD" "$A"; spec "5 origin/HEAD deleted, a branch of that name accepted"
$G -C "$W" $U -d "refs/heads/refs/${R}s/origin/HEAD"
state "$(one T055 "$C55" in_progress)"
OB=$($G -C "$W" rev-parse "refs/${R}s/origin/HEAD:docs/delix/STATE.json")
one T055 "$C55" accepted > "$T/acc.json"; NB=$($G -C "$W" hash-object -w "$T/acc.json")
$G -C "$W" replace -f "$OB" "$NB"
if $G -C "$W" cat-file blob "refs/${R}s/origin/HEAD:docs/delix/STATE.json" | grep -qF accepted; then
  ok "5 control: a plain read sees the replaced blob"; else ko "5 control: a plain read sees the replaced blob" "fixture"; fi
spec "5 STATE blob replaced by an accepted blob"
$G -C "$W" replace -d "$OB" > /dev/null

# Id and copy (K353)
echo docs/delix/tasks/T1000-x.md > "$W/.delix/card"
state "$(one T100 docs/delix/tasks/T1000-x.md accepted)"; spec "6 marker T1000, T100 accepted with that file"
state "$(one T1000 docs/delix/tasks/T1000-x.md accepted)"
allow "6 control: marker T1000, T1000 accepted" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)"
echo "$C55" > "$W/.delix/card"
state "$(one T055 "$C55" in_progress)"; one T055 "$C55" accepted > "$W/docs/delix/STATE.json"
spec "6 the worktree STATE copy says accepted, origin/HEAD in_progress"; rm "$W/docs/delix/STATE.json"

# Archive (K345): read only when the id is missing from cards; at most 20 items, docs/delix/archive/<name>/STATE.json
M21=docs/delix/tasks/T021-x.md; echo "$M21" > "$W/.delix/card"
one T021 "$M21" in_progress > "$T/ip21.json"; one T021 "$M21" accepted > "$T/acc21.json"
one T021 docs/delix/tasks/T021-other.md accepted > "$T/other21.json"
CUR55='{"T055": {"file": "'"$C55"'", "status": "accepted"}}'
cur(){ printf '{"cards": %s, "archive": %s}' "${2:-$CUR55}" "$1" > "$T/cur.json"; }  # <archive JSON> [<cards JSON>]
ARCH='[5, "../x/STATE.json", "docs/delix/archive/a/../b/STATE.json", "docs/delix/archive/a/b/STATE.json", "docs/delix/archive/missing/STATE.json", "docs/delix/archive/old/STATE.json"]'
cur "$ARCH"
statef "$T/cur.json" docs/delix/archive/b/STATE.json "$T/ip21.json" docs/delix/archive/a/b/STATE.json "$T/ip21.json" \
  docs/delix/archive/old/STATE.json "$T/acc21.json"
inactive "7 archived card accepted, bad items skipped" T021
L20=$(python3 -c 'import json; print(json.dumps(["docs/delix/archive/missing/STATE.json"] * 20 + ["docs/delix/archive/old/STATE.json"]))')
cur "$L20"; statef "$T/cur.json" docs/delix/archive/old/STATE.json "$T/acc21.json"; spec "7 the archive as item 21"
cur '["docs/delix/archive/old/STATE.json"]'; statef "$T/cur.json" docs/delix/archive/old/STATE.json "$T/other21.json"
spec "7 archive record with the same id and another file"
cur '["docs/delix/archive/old/STATE.json"]' '{"T021": {"file": "docs/delix/tasks/T021-other.md", "status": "accepted"}}'
statef "$T/cur.json" docs/delix/archive/old/STATE.json "$T/acc21.json"
spec "7 id in cards with another file: the archive is not read"
echo "$C55" > "$W/.delix/card"

# Live marker (K348, K356)
state "$(one T055 "$C55" in_progress)"
deny "8 live: Write .delix/card, another card" write_gate.py "$(hj Write "$W" .delix/card docs/delix/tasks/T056-x.md)" "$MARKER"
deny "8 live: Write absolute .delix/card, another card" write_gate.py "$(hj Write "$W" "$W/.delix/card" docs/delix/tasks/T056-x.md)" "$MARKER"
deny "8 live: Write .DELIX/card, another text" write_gate.py "$(hj Write "$W" .DELIX/card other)" "$MARKER"
for t in Edit MultiEdit NotebookEdit; do deny "8 live: $t .delix/card" write_gate.py "$(hj $t "$W" .delix/card)" "$MARKER"; done
allow "8 live: Write .delix/card, same text and a newline" write_gate.py "$(hj Write "$W" .delix/card "$C55\\u000a")"
allow "8 live: Write .delix/card, two leading spaces" write_gate.py "$(hj Write "$W" .delix/card "  $C55")"
allow "8 live: Write .delix/report.md" write_gate.py "$(hj Write "$W" .delix/report.md x)"
state "$(one T055 "$C55" accepted)"
allow "9 stale: Write .delix/card, a new card" write_gate.py "$(hj Write "$W" .delix/card docs/delix/tasks/T056-x.md)"

# ---- REQ-2: a delix.json the hooks cannot read keeps the card worktree blocked (K346); live marker
state "$(one T055 "$C55" in_progress)"
cfgw(){ printf '%s' "$1" > "$DJ"; }
both(){ deny "$1: Write scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)" "$CONFIG"
        deny "$1: Bash ls" bash_gate.py "$(hj Bash "$W" ls)" "$CONFIG"; }
cfgw '{"protected_paths": ['; both "10 broken JSON"
for b in '[]' '{"protected_paths": 5}' '{"test_paths": [1]}' '{"protected_paths": null}'; do cfgw "$b"; both "11 delix.json $b"; done
rm "$DJ"; both "12 delix.json removed"
cfgw '{"protected_paths": ['
allow "13 broken: Write .delix/report.md" write_gate.py "$(hj Write "$W" .delix/report.md x)"
allow "13 broken: Write .delix/evidence/v.txt" write_gate.py "$(hj Write "$W" .delix/evidence/v.txt x)"
deny "13 broken: Write .delix/card, another card" write_gate.py "$(hj Write "$W" .delix/card docs/delix/tasks/T056-x.md)" "$MARKER"
deny "14 broken: Write .delix/../scripts/common.py" write_gate.py "$(hj Write "$W" .delix/../scripts/common.py x)" "$CONFIG"
ln -s ../scripts "$W/.delix/x"
deny "14 broken: Write .delix/x/common.py, .delix/x -> ../scripts" write_gate.py "$(hj Write "$W" .delix/x/common.py x)" "$CONFIG"
rm "$W/.delix/x"
deny "14 broken: Write .delix itself" write_gate.py "$(hj Write "$W" .delix x)" "$CONFIG"
mv "$W/.delix/card" "$W/.delix/card.off"
allow "15 broken, no marker: Write scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)"
allow "15 broken, no marker: Bash ls" bash_gate.py "$(hj Bash "$W" ls)"
mv "$W/.delix/card.off" "$W/.delix/card"
state "$(one T055 "$C55" accepted)"
allow "15 broken, stale marker: Write scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)"
allow "15 broken, stale marker: Bash ls" bash_gate.py "$(hj Bash "$W" ls)"
stop "15 broken, stale marker: Stop exits 0" 0
sc(){ v=$(python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); import common; print(common.stop_commands(sys.argv[2]))' "$S" "$W" 2>&1)
      if [ "$v" = "['pytest -q']" ]; then ok "$1"; else ko "$1" "$v"; fi; }
sc "16 broken JSON: stop_commands is pytest -q"
cfgw '[]'; sc "16 delix.json []: stop_commands is pytest -q"
rm "$DJ"; sc "16 delix.json removed: stop_commands is pytest -q"
cfgw "$VALID"

# ---- REQ-5: real path and folded case (K355, K356, K357); live marker, valid config
state "$(one T055 "$C55" in_progress)"; card no src/free.py
deny "17 Write lnk/x.py, lnk -> scripts" write_gate.py "$(hj Write "$W" lnk/x.py x)" "$PROT"
deny "17 Bash cp a lnk/x.py" bash_gate.py "$(hj Bash "$W" "cp a lnk/x.py")" "$BPROT"
deny "17 Write scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)" "$PROT"
deny "18 Edit tlink/a_tests.sh, tlink -> tests" write_gate.py "$(hj Edit "$W" tlink/a_tests.sh)" "$TEST"
deny "19 Write Scripts/x.py" write_gate.py "$(hj Write "$W" Scripts/x.py x)" "$PROT"
deny "19 Write SCRIPTS/x.py" write_gate.py "$(hj Write "$W" SCRIPTS/x.py x)" "$PROT"
deny "19 Write DOCS/delix/STATE.json" write_gate.py "$(hj Write "$W" DOCS/delix/STATE.json x)" "$DOCS"
deny "19 Bash echo x > SCRIPTS/x.py" bash_gate.py "$(hj Bash "$W" "echo x > SCRIPTS/x.py")" "$BPROT"
deny "20 Write scripts/cafe + U+0301 .py (NFD)" write_gate.py "$(hj Write "$W" "scripts/cafe${BS}u0301.py" x)" "is a protected path (scripts/caf"
deny "20 Write SCRIPTS/CAF + U+00C9 .PY" write_gate.py "$(hj Write "$W" "SCRIPTS/CAF${BS}u00c9.PY" x)" "is a protected path (scripts/caf"
card yes docs/a.md
deny "21 listed and approved docs/a.md -> ../scripts/common.py" write_gate.py "$(hj Write "$W" docs/a.md x)" "is a protected path (scripts/common.py, Tier 3)"
card no src/a.py
deny "21 listed src/a.py -> ../tests/a_tests.sh" write_gate.py "$(hj Write "$W" src/a.py x)" "$TEST"
card yes scripts/x.py
allow "22 listed and approved: Write scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)"
deny "22 listed scripts/x.py: Write lnk/x.py" write_gate.py "$(hj Write "$W" lnk/x.py x)" "$PROT"
card no src/free.py
allow "22 new tests/b_tests.sh" write_gate.py "$(hj Write "$W" tests/b_tests.sh x)"
allow "22 src/free.py" write_gate.py "$(hj Write "$W" src/free.py x)"

# ---- Network (K284): a treeless clone; the hook reads with --no-lazy-fetch and fetches nothing
NS="$T/ns"; C="$T/c"
mkdir -p "$NS" && $G -C "$NS" init -q && $G -C "$NS" symbolic-ref HEAD refs/heads/main
$GC -C "$NS" commit -q --allow-empty -m old && $G -C "$NS" branch old
mkdir -p "$NS/docs/delix"; one T900 docs/delix/tasks/T900-x.md accepted > "$NS/docs/delix/STATE.json"
$G -C "$NS" add docs/delix/STATE.json && $GC -C "$NS" commit -q -m main
$G -C "$NS" config uploadpack.allowFilter true; $G -C "$NS" config uploadpack.allowAnySHA1InWant true
$G clone -q --filter=tree:0 --branch old "file://$NS" "$C"
$G -C "$C" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
mkdir -p "$C/.delix" "$C/docs/delix"; echo docs/delix/tasks/T900-x.md > "$C/.delix/card"
echo ".delix/" >> "$C/.$G/info/exclude"; printf '%s' "$VALID" > "$C/docs/delix/delix.json"
packs(){ ls "$C/.$G/objects/pack/" | grep -c '\.pack$'; }
p0=$(packs)
deny "23 treeless clone: Write docs/delix/SPEC.md" write_gate.py "$(hj Write "$C" docs/delix/SPEC.md x)" "$DOCS"
p1=$(packs)
env -u "${GU}_NO_LAZY_FETCH" $G -C "$C" cat-file blob "refs/${R}s/origin/HEAD:docs/delix/STATE.json" > /dev/null 2>&1
p2=$(packs)
if [ "$p0" = "$p1" ]; then ok "23 no pack added by the hook ($p0 -> $p1)"; else ko "23 no pack added by the hook" "$p0 -> $p1"; fi
if [ "$p2" -gt "$p1" ]; then ok "23 control: a lazy read adds a pack ($p1 -> $p2)"; else ko "23 control: a lazy read adds a pack" "$p1 -> $p2"; fi

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
