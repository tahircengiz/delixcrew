#!/usr/bin/env bash
# T052 (spec C K296, K331, R-L1): in an implementer worktree a line that pushes holds only git add, commit, status,
# diff, log, show, gh pr create and the push, joined by && || ; | or a newline, with words no shell expands; a push
# may pipe into tail or head, and the line redirects only to /dev/null. The trigger words are assembled at run time; this
# file holds none of them. ASCII only.
# Run: bash tests/push_line_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"
OK="$(printf '\342\234\224')"; NO="$(printf '\342\234\230')"; NL="$(printf '\nx')"; NL="${NL%x}"
T="$(mktemp -d)"; W="$T/w"; L="$T/l"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
mk(){ # <dir> <branch> [card]: a repo with one empty commit on <branch>; with "card", .delix/card and delix.json
  mkdir -p "$1" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD "refs/heads/$2" \
    && $GC -C "$1" commit -q --allow-empty -m init
  if [ "${3:-}" = card ]; then
    mkdir -p "$1/.delix" "$1/docs/delix" "$1/.git/info"; echo "docs/delix/tasks/T052-x.md" > "$1/.delix/card"
    echo ".delix/" >> "$1/.git/info/exclude"; printf '{"default_branch":"main"}' > "$1/docs/delix/delix.json"
  fi
}
mk "$W" claude/t1 card; mk "$L" claude/t1
$G -C "$W" remote add origin "$W.git"; $G -C "$W" update-ref refs/remotes/origin/main HEAD
$G -C "$W" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
LINE_DENY="delixcrew: in an implementer session a $P shares its line only with $G add, commit, status, diff, log, show and gh pr create, pipes only into tail or head and redirects only to /dev/null; run every other command in a separate call"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | python3 "$S/bash_gate.py"; }
allow(){ out=$(run "$2" "$3"); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "$OK $1"; else echo "$NO $1 (expected allow): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3"); if echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$LINE_DENY"; then echo "$OK $1"; else echo "$NO $1 (expected deny: $LINE_DENY): $out"; FAIL=1; fi; }

# Allow: git peers and the push, quoted messages, the listed redirections, other lines with no push
allow "push alone"                          "$W" "$G $P origin HEAD"
allow "-u own branch, 2>&1"                 "$W" "$G $P -u origin claude/t1 2>&1"
allow "> /dev/null"                         "$W" "$G $P origin HEAD > /dev/null"
allow "2>/dev/null"                         "$W" "$G $P origin HEAD 2>/dev/null"
allow "1> /dev/null"                        "$W" "$G $P origin HEAD 1> /dev/null"
allow "&> /dev/null"                        "$W" "$G $P origin HEAD &> /dev/null"
allow "add, commit '...', push"             "$W" "$G add a.py b.py && $G commit -m 'T052: x (K331); y | z \$HOME' && $G $P -u origin HEAD"
allow "commit \"...\" ; push"               "$W" "$G commit -m \"T052: fix, see K331\" ; $G $P origin HEAD"
allow "newlines"                            "$W" "$G status${NL}$G $P origin HEAD${NL}$G log -1 --oneline"
allow "message over two lines"              "$W" "$G commit -m 'a${NL}${NL}b' && $G $P origin HEAD"
allow "|| status"                           "$W" "$G $P origin HEAD || $G status"
allow "then gh pr create"                   "$W" "$G $P -u origin HEAD && gh pr create --title 'T052: x' --body-file b.md"
allow "pipe into tail"                      "$W" "$G $P origin HEAD 2>&1 | tail -3"
allow "pipe into head, then tail"           "$W" "$G $P origin HEAD 2>&1 | head -20 | tail -1"
allow "group of peers"                      "$W" "{ $G add a.py; $G status; } && $G $P origin HEAD"
allow "log --oneline, then push"            "$W" "$G log --oneline -3 && $G $P origin HEAD"
allow "pipe from a peer"                    "$W" "$G status | tail -1; $G $P origin HEAD"
allow "gh pr create into tail"              "$W" "$G $P -u origin HEAD 2>&1 | tail -2 && gh pr create --title x --body-file b.md 2>&1 | tail -2"
allow "commit from a quoted heredoc"        "$W" "$G commit -q -F - <<'E'${NL}T052: x \$(id) \`id\`${NL}${NL}body; | & > f${NL}E${NL}$G $P -u origin HEAD"
allow "two quoted heredocs, push between"   "$W" "$G commit -F - <<\"A\" && $G $P origin HEAD && $G log -1 <<'B'${NL}a${NL}A${NL}b${NL}B"
allow "no card: any line"                   "$L" "bash x.sh && $G $P origin HEAD:main"
allow "no push: other commands"             "$W" "bash tests/x.sh && echo ok > out.txt"

# Deny: anything else on a push line (the two shapes measured on main first)
deny "export GIT_DIR"                       "$W" "export GIT_DIR=/tmp/x/.git; $G $P origin HEAD"
deny "write the HEAD file"                  "$W" "echo 'ref: refs/heads/main' > .git/HEAD; $G $P origin HEAD"
deny "log --output into the git dir"        "$W" "$G log -1 --format='tformat:ref: refs/heads/main' --output=.git/HEAD main; $G $P origin HEAD"
deny "diff --output, separate word"         "$W" "$G diff --output .git/x; $G $P origin HEAD"
deny "a peer redirected to a file"          "$W" "$G status > .git/HEAD; $G $P origin HEAD"
deny "cp into refs"                         "$W" "cp .git/refs/heads/claude/t1 .git/refs/heads/main && $G $P origin HEAD"
deny "assignment before a peer"             "$W" "GIT_DIR=/tmp/x/.git $G status; $G $P origin HEAD"
deny "test run before the push"             "$W" "bash tests/x.sh && $G $P origin HEAD"
deny "pipe into tee"                        "$W" "$G $P origin HEAD | tee .git/HEAD"
deny "pipe into a shell"                    "$W" "$G $P origin HEAD | sh"
deny "reader redirected to a file"          "$W" "$G $P origin HEAD | tail -1 > .git/HEAD"
deny "push output to a file"                "$W" "$G $P origin HEAD >push.log 2>&1"
deny "push output into the git dir"         "$W" "$G $P origin HEAD > .git/HEAD"
deny "1> into the git dir"                  "$W" "$G $P origin HEAD 1> .git/HEAD"
deny "&> into the git dir"                  "$W" "$G $P origin HEAD &> .git/HEAD"
deny "another descriptor"                   "$W" "$G $P origin HEAD 3>&1"
deny "gh pr create redirected to a file"    "$W" "gh pr create --title x > .git/HEAD; $G $P origin HEAD"
deny "echo after the push"                  "$W" "$G $P origin HEAD && echo ok"
deny "background job"                       "$W" "$G $P origin HEAD &"
deny "\$(...) in double quotes"             "$W" "$G commit -m \"\$(echo x)\" && $G $P origin HEAD"
deny "backticks"                            "$W" "$G commit -m \`echo x\` && $G $P origin HEAD"
deny "backslash in double quotes"           "$W" "$G commit -m \"a\\\"b\" && $G $P origin HEAD"
deny "a git at a path"                      "$W" "./$G $P origin HEAD"
deny "glob"                                 "$W" "$G add *.py && $G $P origin HEAD"
deny "zsh EQUALS word"                      "$W" "$G add =x && $G $P origin HEAD"
deny "subshell"                             "$W" "($G status) && $G $P origin HEAD"
deny "group redirected to a file"           "$W" "{ $G log -1; } > .git/HEAD; $G $P origin HEAD"
deny "zsh always block"                     "$W" "{ $G status } always { export GIT_DIR=/tmp/x/.git }; $G $P origin HEAD"
deny "zsh close brace inside a command"     "$W" "{ $G status }; $G $P origin HEAD"
deny "function"                             "$W" "f() { $G status; }; f; $G $P origin HEAD"
deny "heredoc into cat"                     "$W" "cat > .git/HEAD <<'E'${NL}ref: refs/heads/main${NL}E${NL}$G $P origin HEAD"
deny "unquoted heredoc"                     "$W" "$G commit -F - <<E${NL}x${NL}E${NL}$G $P origin HEAD"
deny "<<- heredoc"                          "$W" "$G commit -F - <<-'E'${NL}x${NL}E${NL}$G $P origin HEAD"
deny "heredoc with no end"                  "$W" "$G commit -F - <<'E'${NL}x${NL}$G $P origin HEAD"

# Linear: a long push line is read in one pass (x8 input, under x16 time): many words, many group words
long(){ python3 -c 'import sys; g, n, p, k = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]; print(("{ " * n if k == "group" else "") + g + " add" + (" a" * n if k == "words" else "") + " && " + g + " " + p + " origin HEAD")' "$G" "$1" "$P" "$2"; }
tm(){ c="$(long "$1" "$2")"; s=$(python3 -c 'import time; print(time.time())'); run "$W" "$c" >/dev/null; python3 -c "import time; print(time.time() - $s)"; }
for k in words group; do
  t1=$(tm 4000 $k); t8=$(tm 32000 $k)
  if python3 -c "import sys; sys.exit(0 if $t8 < 2 and $t8 < 16 * max($t1, 0.05) else 1)"; then echo "$OK long line, $k: ${t1}s, x8 ${t8}s"; else echo "$NO long line, $k: ${t1}s, x8 ${t8}s"; FAIL=1; fi
done

rm -rf "$T"
if [ "$FAIL" -eq 0 ]; then echo "ALL PASSED"; else echo "FAILED"; exit 1; fi
