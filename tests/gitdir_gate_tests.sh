#!/usr/bin/env bash
# T059 (Spec E REQ-1, K358-K360): in a card worktree the write gate denies Write, Edit, MultiEdit and NotebookEdit on
# the worktree's own repository entry (a gitfile or a directory) and everything under it, in any letter case and
# through a symlink, even for a listed and approved card; the other write gate rules keep their messages. The trigger
# words are assembled at run time; this file holds none of them, and it stays ASCII (the check marks and the lock
# sign are octal escapes).
# Run: bash tests/gitdir_gate_tests.sh
set -u
unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; GUP=GI; GUP="${GUP}T"; GCAP=Gi; GCAP="${GCAP}t"; R=rem; R="${R}ote"
OK=$'\342\234\224'; NO=$'\342\234\230'; LOCK=$(printf '\360\237\224\220')
$G --version
T="$(mktemp -d)"; M="$T/m"; W="$M/.claude/worktrees/x"; P="$T/p"; SRC="$T/s"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
C59="docs/delix/tasks/T059-x.md"
VALID='{"protected_paths": ["scripts/x.py"], "test_paths": ["tests/**"]}'
CONFIG="delixcrew: docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; this card worktree stays blocked until the user fixes it from their own terminal"
DOCS="is the card or under docs/delix; the implementer cannot change these"
PROT="is a protected path (scripts/x.py, Tier 3)"
TEST="cannot be modified (no test weakening)"
gmsg(){ # <path>: the REQ-1 deny text, letter for letter
  printf '%s' "delixcrew: '$1' is the worktree's .$G; the implementer cannot change it with this tool (the hooks find the card through it). .delix/ is excluded with: echo .delix/ >> \"\$($G rev-parse --$G-path info/exclude)\"; for anything else, explain with NEEDS_CONTEXT in the report."; }
card(){ # <dir> <yes|no> <path>...: the T059 card file in <dir>, with the lock line when $2 is yes, these paths under Files
  dir=$1; a=$2; shift 2
  { printf '# T059 card\n\n| id | tier |\n|---|---|\n| T059 | 3 |\n\n'
    [ "$a" = yes ] && printf '**%s Approved:** 2026-11-20 t\n\n' "$LOCK"
    printf '## Files\n'; for f in "$@"; do printf -- '- Modify: `%s`\n' "$f"; done
    printf '\n## Steps\n1. none\n'; } > "$dir/$C59"; }
mkrepo(){ # <dir>: one commit on main with delix.json, the card, scripts/x.py, tests/a_tests.sh and the symlinks l, d
  mkdir -p "$1/docs/delix/tasks" "$1/scripts" "$1/tests" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD refs/heads/main
  printf '%s' "$VALID" > "$1/docs/delix/delix.json"; card "$1" no src/free.py
  echo x > "$1/scripts/x.py"; echo x > "$1/tests/a_tests.sh"; ln -s ".$G" "$1/l"; ln -s . "$1/d"
  $G -C "$1" add -A && $GC -C "$1" commit -q -m init; }
# Fixtures (setup by direct calls, never through a hook): W is a linked card worktree under M/.claude/worktrees/x,
# P is a main checkout that is itself the card worktree; both hold the T059 marker, untracked and excluded
mkrepo "$M"; echo ".delix/" >> "$M/.$G/info/exclude"; $GC -C "$M" worktree add -q -b claude/t1 "$W"
mkrepo "$P"; echo ".delix/" >> "$P/.$G/info/exclude"
for c in "$W" "$P"; do mkdir -p "$c/.delix" "$c/src"; echo "$C59" > "$c/.delix/card"; done
mkdir -p "$SRC/docs/delix" && $G -C "$SRC" init -q && $G -C "$SRC" symbolic-ref HEAD refs/heads/main
printf '{"cards": {"T059": {"file": "%s", "status": "accepted"}}}' "$C59" > "$SRC/docs/delix/STATE.json"
$G -C "$SRC" add -A && $GC -C "$SRC" commit -q -m s1

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
why(){ printf '%s' "$OUT" | python3 -c 'import json, sys
try:
    sys.stdout.write(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"])
except Exception:
    pass'; }
gdeny(){ # <name> <tool> <cwd> <path>: exit 0, the deny decision with exactly gmsg <path>, no Traceback
  if [ "$2" = Write ]; then j=$(hj Write "$3" "$4" x); else j=$(hj "$2" "$3" "$4"); fi
  run write_gate.py "$j"
  if [ $RC -eq 0 ] && isdeny && [ "$(why)" = "$(gmsg "$4")" ] && clean; then ok "$1"; else ko "$1" "expected the REQ-1 deny, exit $RC: $OUT $ERR"; fi; }

# ---- A. Scenario: the linked worktree's gitfile (6 forms x 4 tools), then the docs/delix rule still applies
for t in Write Edit MultiEdit NotebookEdit; do
  for p in ".$G" "./.$G" ".$GUP" ".$GCAP" "$W/.$G" "src/../.$G"; do gdeny "A $t $p" "$t" "$W" "$p"; done
done
deny "A then Write docs/delix/STATE.json" write_gate.py "$(hj Write "$W" docs/delix/STATE.json x)" "$DOCS"

# ---- B. Scenario: through a tracked symlink (l -> .G, d -> .), in both fixtures
for c in "$W" "$P"; do n=linked; [ "$c" = "$P" ] && n=main
  for p in l "d/.$G" "d/d/.$G"; do gdeny "B $n: Write $p" Write "$c" "$p"; done
done

# ---- C. Scenario: the main checkout is the card worktree (.G is a directory)
gdeny "C Write .$G/HEAD" Write "$P" ".$G/HEAD"
gdeny "C Write .$G/refs/${R}s/origin/HEAD" Write "$P" ".$G/refs/${R}s/origin/HEAD"
gdeny "C Edit .$GUP/config" Edit "$P" ".$GUP/config"
gdeny "C Edit l/info/exclude" Edit "$P" "l/info/exclude"

# ---- D. Scenario: controls in both fixtures; the last allow is an extra over-denial check (.G + hub)
for c in "$W" "$P"; do n=linked; [ "$c" = "$P" ] && n=main
  for p in ".${G}ignore" ".${G}attributes" ".${G}keep" "src/.$G" src/x.py .delix/report.md ".${G}hub/x.yml"; do
    allow "D $n: Write $p" write_gate.py "$(hj Write "$c" "$p" x)"
  done
  deny "D $n: Write docs/delix/STATE.json" write_gate.py "$(hj Write "$c" docs/delix/STATE.json x)" "$DOCS"
  deny "D $n: Write scripts/x.py" write_gate.py "$(hj Write "$c" scripts/x.py x)" "$PROT"
  deny "D $n: Edit tests/a_tests.sh" write_gate.py "$(hj Edit "$c" tests/a_tests.sh)" "$TEST"
done

# ---- E. Scenario: the gate is not active (no marker; the card accepted on origin/HEAD)
mv "$P/.delix/card" "$P/.delix/card.off"
allow "E no marker: Write .$G/HEAD" write_gate.py "$(hj Write "$P" ".$G/HEAD" x)"
mv "$P/.delix/card.off" "$P/.delix/card"
mv "$W/.delix/card" "$W/.delix/card.off"
allow "E no marker: Write .$G" write_gate.py "$(hj Write "$W" ".$G" x)"
mv "$W/.delix/card.off" "$W/.delix/card"
$G -C "$P" fetch -q "$SRC" "+refs/heads/main:refs/${R}s/origin/main"
$G -C "$P" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
allow "E card accepted on origin/HEAD: Write .$G/HEAD" write_gate.py "$(hj Write "$P" ".$G/HEAD" x)"
$G -C "$P" symbolic-ref --delete "refs/${R}s/origin/HEAD"

# ---- F. Scenario: a listed and approved .G
card "$W" yes ".$G" scripts/x.py
gdeny "F listed and approved: Write .$G" Write "$W" ".$G"
allow "F control: listed and approved scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)"
card "$P" yes ".$G/HEAD"
gdeny "F listed and approved: Write .$G/HEAD" Write "$P" ".$G/HEAD"
card "$W" no src/free.py; card "$P" no src/free.py

# ---- G. Scenario: a delix.json the gate cannot read (Spec D REQ-2 message)
cp "$W/docs/delix/delix.json" "$T/dj.bak"; printf '{"protected_paths": [' > "$W/docs/delix/delix.json"
deny "G broken delix.json: Write .$G" write_gate.py "$(hj Write "$W" ".$G" x)" "$CONFIG"
cp "$T/dj.bak" "$W/docs/delix/delix.json"

# ---- H. Extra (K364): the exclude command that the deny text gives passes the Bash gate
allow "H Bash: the exclude command of the deny text" bash_gate.py "$(hj Bash "$W" "echo .delix/ >> \"\$($G rev-parse --$G-path info/exclude)\"")"

# ---- I. The lead's repro (spec section 7): Write junk to .G, then Write docs/delix/STATE.json
run write_gate.py "$(hj Write "$W" ".$G" junk)"
if [ $RC -eq 0 ] && isdeny && [ "$(why)" = "$(gmsg ".$G")" ] && clean; then ok "I repro: Write .$G is denied"
else
  ko "I repro: Write .$G is denied" "exit $RC: $OUT $ERR"
  if [ $RC -eq 0 ] && ! isdeny; then cp "$W/.$G" "$T/gitfile.bak"; printf junk > "$W/.$G"; fi  # what the Write tool does
fi
deny "I repro: then Write docs/delix/STATE.json is still denied" write_gate.py "$(hj Write "$W" docs/delix/STATE.json x)" "$DOCS"
[ -f "$T/gitfile.bak" ] && cp "$T/gitfile.bak" "$W/.$G"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
