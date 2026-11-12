#!/usr/bin/env bash
# T041 (spec C §6, K279): in an implementer worktree bash_gate.py lets a session send only its own card branch to
# origin and denies the gh merge command. The trigger words are assembled at run time; this file holds none of them.
# Run: bash tests/push_gate_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"; M=mer; M="${M}ge"
T="$(mktemp -d)"; W="$T/w"; MN="$T/mn"; L="$T/l"; DT="$T/dt"; SH="$T/shim"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
mk(){ # <dir> <branch> [card]: a repo with one empty commit on <branch>; with "card", .delix/card and delix.json
  mkdir -p "$1" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD "refs/heads/$2" \
    && $GC -C "$1" commit -q --allow-empty -m init
  if [ "${3:-}" = card ]; then
    mkdir -p "$1/.delix" "$1/docs/delix" "$1/.git/info"; echo "docs/delix/tasks/T041-x.md" > "$1/.delix/card"
    echo ".delix/" >> "$1/.git/info/exclude"; printf '{"default_branch":"main"}' > "$1/docs/delix/delix.json"
  fi
}
mk "$W" claude/t1 card; mk "$MN" main card; mk "$L" claude/t1; mk "$DT" claude/t1 card
$G -C "$W" remote add origin "$W.git"; $G -C "$W" update-ref refs/remotes/origin/main HEAD
$G -C "$W" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
$G -C "$DT" checkout -q --detach
# a git shim for R-P3a: exits 128 when one argument equals $FA, otherwise runs the real git ($RG)
mkdir -p "$SH"; RG="$(command -v "$G")"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = "$FA" ] && exit 128; done\nexec "$RG" "$@"\n' > "$SH/$G"; chmod +x "$SH/$G"
PUSH_DENY="delixcrew: an implementer session pushes only its own card branch ($G $P [-u] origin <branch>); the default branch and every other $P run from the user's own terminal"
MERGE_DENY="delixcrew: gate 2 ($M) is the user's; an implementer session does not run gh pr $M"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | FA="${FA:-}" RG="$RG" PATH="${XP:-}$PATH" python3 "$S/bash_gate.py"; }
allow(){ out=$(run "$2" "$3"); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "✔ $1"; else echo "✘ $1 (expected allow): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3"); if echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "${4:-$PUSH_DENY}"; then echo "✔ $1"; else echo "✘ $1 (expected deny: ${4:-$PUSH_DENY}): $out"; FAIL=1; fi; }

# Allow: the card branch on origin, read commands, a session without a card
allow "own branch"                          "$W" "$G $P origin claude/t1"
allow "-u, own branch"                      "$W" "$G $P -u origin claude/t1"
allow "--set-upstream HEAD"                 "$W" "$G $P --set-upstream origin HEAD"
allow "--force-with-lease, 2>&1"            "$W" "$G $P --force-with-lease origin claude/t1 2>&1"
allow "log --grep the word"                 "$W" "$G log --grep $P -1"
allow "grep for the word"                   "$W" "grep -rn $P src"
allow "config --get"                        "$W" "$G config --get remote.origin.url"
allow "HEAD"                                "$W" "$G $P origin HEAD"
allow "-u --force-with-lease HEAD"          "$W" "$G $P -u --force-with-lease origin HEAD"
allow "redirect to /dev/null"               "$W" "$G $P origin claude/t1 > /dev/null"
allow "after add && commit"                 "$W" "$G add a.py && $G commit -m 'T041: x' && $G $P -u origin HEAD"
allow "config --list, config get"           "$W" "$G config --list; $G config get remote.origin.url"
allow "-c of another key"                   "$W" "$G -c core.pager=cat log -1"
allow "gh pr view"                          "$W" "gh pr view 7"
allow "gh pr create, the word in the title" "$W" "gh pr create --title 'T041 no $M here' --body-file b.md"
allow "no card: default branch"             "$L" "$G $P origin HEAD:main"
allow "no card: gh merge"                   "$L" "gh pr $M 7 --squash"
$G -C "$W" symbolic-ref --delete refs/remotes/origin/HEAD
allow "no origin/HEAD (R-P3a)"              "$W" "$G $P origin claude/t1"
$G -C "$W" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
XP="$SH:" FA="no-such-argument" allow "git shim passes through"  "$W" "$G $P origin claude/t1"

# Deny: another target, ref or remote
deny "HEAD:main"                            "$W" "$G $P origin HEAD:main"
deny "main"                                 "$W" "$G $P origin main"
deny "+own branch"                          "$W" "$G $P origin +claude/t1"
deny "refs/heads/main"                      "$W" "$G $P origin refs/heads/main"
deny "own:main"                             "$W" "$G $P origin claude/t1:main"
deny "--all"                                "$W" "$G $P --all origin"
deny "--mirror"                             "$W" "$G $P --mirror origin"
deny "no remote, no name"                   "$W" "$G $P"
deny "remote only"                          "$W" "$G $P origin"
deny "two names"                            "$W" "$G $P origin claude/t1 main"
deny ":main (delete)"                       "$W" "$G $P origin :main"
deny "another remote"                       "$W" "$G $P upstream claude/t1"
deny "--force"                              "$W" "$G $P --force origin claude/t1"
deny "--force-with-lease=ref"               "$W" "$G $P --force-with-lease=main origin claude/t1"
deny "own branch, letter case"              "$W" "$G $P origin CLAUDE/T1"
# Deny: the git command is not plain, or the shell hides it
deny "-C dir"                               "$W" "$G -C \"$W\" $P origin claude/t1"
deny "-c remote.origin.<push>"              "$W" "$G -c remote.origin.$P=x $P origin claude/t1"
deny "--no-pager (global option)"           "$W" "$G --no-pager $P origin claude/t1"
deny "quotes inside the words (literal)"    "$W" "g''it pu\"\"sh origin main"
deny "backslash before the command"         "$W" "\\$G $P origin main"
deny "bash -c"                              "$W" "bash -c \"$G $P origin main\""
deny "echo ok &&"                           "$W" "echo ok && $G $P origin main"
deny "command substitution"                 "$W" "echo \$($G $P origin main)"
deny "backticks"                            "$W" "echo \`$G $P origin main\`"
deny "env X=1"                              "$W" "env X=1 $G $P origin claude/t1"
deny "VAR=x prefix"                         "$W" "X=1 $G $P origin claude/t1"
deny "absolute path to git"                 "$W" "/usr/bin/$G $P origin main"
deny "upper-case command name"              "$W" "$(printf %s "$G" | tr a-z A-Z) $P origin main"
deny "dashed form, main"                    "$W" "/x/$G-$P origin main"
deny "dashed send-pack"                     "$W" "$G-send-pack $W.git main"
deny "python list of words"                 "$W" "python3 -c 'import subprocess; subprocess.run([\"$G\",\"$P\",\"origin\",\"main\"])'"
deny "send-pack"                            "$W" "$G send-pack $W.git main"
deny "http-<push>"                          "$W" "$G http-$P x main"
deny "subtree"                              "$W" "$G subtree $P --prefix=x origin main"
deny "cd .. &&"                             "$W" "cd .. && $G $P origin HEAD"
deny "cd worktree &&"                       "$W" "cd \"$W\" && $G $P origin claude/t1"
deny "pushd"                                "$W" "pushd /tmp; $G $P origin HEAD; popd"
deny "heredoc body (known false positive)"  "$W" "$(printf '%s\n' "cat > notes.md <<'EOF'" "$G $P origin main" 'EOF')"
# Deny: config writes (R-P5)
deny "config alias"                         "$W" "$G config alias.p \"$P origin HEAD:main\""
deny "-c alias"                             "$W" "$G -c alias.x=y status"
deny "-c url."                              "$W" "$G -c url.a.insteadOf=b status"
deny "-c includeIf (letter case)"           "$W" "$G -c IncludeIf.x.path=y status"
deny "config --global remote."              "$W" "$G config --global remote.origin.url x"
deny "config set push."                     "$W" "$G config set push.default current"
deny "config include.path"                  "$W" "$G config include.path /tmp/x"
# Deny: gh merge (R-P6)
deny "gh merge"                             "$W" "gh pr $M 7 --squash" "$MERGE_DENY"
deny "/usr/bin/gh merge"                    "$W" "/usr/bin/gh pr $M 7" "$MERGE_DENY"
deny "gh pr -R repo merge"                  "$W" "gh pr -R o/r $M 7" "$MERGE_DENY"
deny "gh pr --repo=repo merge"              "$W" "gh pr --repo=o/r $M 7" "$MERGE_DENY"
deny "gh merge after &&"                    "$W" "gh pr checks 7 && gh pr $M 7" "$MERGE_DENY"
deny "upper-case gh merge"                  "$W" "GH PR $(printf %s "$M" | tr a-z A-Z) 7" "$MERGE_DENY"
# Deny: repository state (branch, default branch, origin/HEAD, remote.origin.push)
deny "card on main"                         "$MN" "$G $P origin HEAD"
deny "card on main, by name"                "$MN" "$G $P origin main"
deny "detached HEAD (R-P3a)"                "$DT" "$G $P origin HEAD"
$G -C "$W" config remote.origin.$P HEAD:refs/heads/main
deny "remote.origin.<push> set"             "$W" "$G $P origin claude/t1"
$G -C "$W" config --unset remote.origin.$P
printf '{"default_branch":"claude/t1"}' > "$W/docs/delix/delix.json"
deny "default_branch is the card branch"    "$W" "$G $P origin claude/t1"
printf '{"default_branch":"main"}' > "$W/docs/delix/delix.json"
$G -C "$W" update-ref refs/remotes/origin/claude/t1 HEAD
$G -C "$W" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/claude/t1
deny "origin/HEAD names the card branch"    "$W" "$G $P origin HEAD"
$G -C "$W" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
# User addition (2026-11-12): with push.default=upstream a branch name goes to its upstream, so the name form needs
# branch.<b>.merge unset or naming the branch itself; HEAD is not mapped
$G -C "$W" config branch.claude/t1.merge refs/heads/main
deny "branch name, upstream is main"        "$W" "$G $P origin claude/t1"
allow "HEAD, upstream is main"              "$W" "$G $P origin HEAD"
allow "-u HEAD, upstream is main"           "$W" "$G $P -u origin HEAD"
$G -C "$W" config branch.claude/t1.merge refs/heads/claude/t1
allow "branch name, upstream is itself"     "$W" "$G $P origin claude/t1"
$G -C "$W" config branch.claude/t1.merge claude/t1
allow "branch name, short upstream itself"  "$W" "$G $P origin claude/t1"
$G -C "$W" config --unset branch.claude/t1.merge
# Deny: a failed git call (R-P3a): the shim exits 128 for one argument
XP="$SH:" FA="HEAD"                        deny "branch lookup fails"       "$W" "$G $P origin claude/t1"
XP="$SH:" FA="refs/remotes/origin/HEAD"    deny "origin/HEAD lookup fails"  "$W" "$G $P origin claude/t1"
XP="$SH:" FA="remote.origin.$P"            deny "push config lookup fails"  "$W" "$G $P origin claude/t1"
XP="$SH:" FA="branch.claude/t1.merge"      deny "upstream lookup fails"     "$W" "$G $P origin claude/t1"
XP="$SH:" FA="--get-regexp"                deny "alias lookup fails"        "$W" "$G status"
# Deny: aliases (R-P4), written to .git/config by the test
$G -C "$W" config alias.q "$P origin HEAD:main"; $G -C "$W" config alias.r '!sh'
$G -C "$W" config alias.a b; $G -C "$W" config alias.b "$P origin main"; $G -C "$W" config alias.lg "log --oneline"
for i in 0 1 2 3 4 5 6 7 8 9 10; do $G -C "$W" config "alias.c$i" "c$((i + 1))"; done; $G -C "$W" config alias.c11 status
deny "alias to the push"                    "$W" "$G q"
deny "alias, letter case"                   "$W" "$G Q"
deny "! alias"                              "$W" "$G r"
deny "alias chain a, b, push"               "$W" "$G a"
deny "alias chain of 11"                   "$W" "$G c1"
allow "alias chain of 10"                   "$W" "$G c2"
allow "alias without the push"              "$W" "$G lg"
for a in q r a b lg c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11; do $G -C "$W" config --unset "alias.$a"; done
allow "aliases removed"                     "$W" "$G status"

# R-P3b (lead, round 1): a push shares its line only with git add, commit, status, diff, log or show (no global option)
deny "checkout main, then HEAD"             "$W" "$G checkout main && $G $P origin HEAD"
deny "switch main; HEAD"                    "$W" "$G switch main; $G $P -u origin HEAD"
deny "alias co, then HEAD"                  "$W" "$G co main && $G $P origin HEAD"
deny "set-upstream-to, then the name"       "$W" "$G branch --set-upstream-to=origin/main && $G $P origin claude/t1"
deny "symbolic-ref HEAD, then HEAD"         "$W" "$G symbolic-ref HEAD refs/heads/main; $G $P origin HEAD"
deny "push, then checkout in background"    "$W" "$G $P origin HEAD & $G checkout main"
deny "sh -c checkout, then HEAD"            "$W" "sh -c '$G checkout main' && $G $P origin HEAD"
deny "-C on add, then HEAD"                 "$W" "$G -C .. add a.py && $G $P origin HEAD"
deny "-c on commit, then HEAD"              "$W" "$G -c core.hooksPath=/tmp/h commit -m x && $G $P origin HEAD"
allow "status, diff, log, show, then HEAD"  "$W" "$G status; $G diff; $G log -1; $G show -s; $G $P origin HEAD"
allow "HEAD, then gh pr create"             "$W" "$G $P -u origin HEAD && gh pr create --title x --body-file b.md"
allow "switch without a push"               "$W" "$G switch -c claude/t2"

# R-P2a, R-P4a (lead, round 2): an unknown global option denies; with help.autocorrect on, an unlisted name denies
deny "--attr-source takes a value"          "$W" "$G --attr-source HEAD $P origin main"
deny "--shallow-file takes a value"         "$W" "$G --shallow-file x $P origin main"
deny "unknown global option"                "$W" "$G --frobnicate status"
allow "--no-pager log"                      "$W" "$G --no-pager log -1"
allow "--git-dir=value status"              "$W" "$G --git-dir=.git status"
deny "--config-env=alias."                  "$W" "X=v $G --config-env=alias.x=X x"
deny "--config-env alias. (two tokens)"     "$W" "$G --config-env alias.x=X x"
allow "--config-env of another key"         "$W" "$G --config-env=core.pager=X log -1"
deny "-c help.autocorrect"                  "$W" "$G -c help.autocorrect=immediate psuh origin main"
deny "config help.autocorrect"              "$W" "$G config help.autocorrect 1"
allow "autocorrect unset, typo"             "$W" "$G psuh origin main"
$G -C "$W" config help.autocorrect immediate
deny "autocorrect on, typo of the push"     "$W" "$G psuh origin main"
allow "autocorrect on, status"              "$W" "$G status"
allow "autocorrect on, own branch"          "$W" "$G $P origin claude/t1"
XP="$SH:" FA="--list-cmds=builtins,main,others,alias" deny "command list fails" "$W" "$G status"
$G -C "$W" config help.autocorrect never
allow "autocorrect never, typo"             "$W" "$G psuh origin main"
$G -C "$W" config --unset help.autocorrect
XP="$SH:" FA="help.autocorrect"            deny "autocorrect lookup fails"  "$W" "$G status"

# ReDoS (repo hook rule): linear time; t(160000) < 3 s and t(160000)/t(20000) < 20
python3 - "$S/bash_gate.py" "$W" "$G" "$P" <<'PYT' || FAIL=1
import json, subprocess, sys, time
hook, w, g, p = sys.argv[1:5]
cases = [("-c pairs", lambda k: (g + " -c " + g + " ") * k + p),
         ("quotes", lambda k: "'" * k + " " + g + " " + p),
         ("separators", lambda k: "; " * k + g + " " + p + " origin main"),
         ("backslashes", lambda k: "\\" * k),
         ("git words", lambda k: (g + " ") * k + p),
         ("git commands, then a push", lambda k: (g + " status; ") * k + g + " " + p + " origin HEAD"),
         ("global flags", lambda k: g + " --no-pager" * k + " status"),
         ("own pushes, then main", lambda k: (g + " " + p + " origin claude/t1; ") * k + g + " " + p + " origin main")]
bad = 0
for name, make in cases:
    t = {}
    for k in (20000, 160000):
        data = json.dumps({"tool_name": "Bash", "cwd": w, "tool_input": {"command": make(k)}})
        s = time.perf_counter()
        subprocess.run([sys.executable, hook], input=data, capture_output=True, text=True, timeout=60)
        t[k] = time.perf_counter() - s
    ratio = t[160000] / t[20000]
    ok = t[160000] < 3 and ratio < 20
    bad |= not ok
    print(("✔" if ok else "✘") + " ReDoS %s: t(20000)=%.3fs t(160000)=%.3fs ratio=%.2f" % (name, t[20000], t[160000], ratio))
sys.exit(1 if bad else 0)
PYT
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
