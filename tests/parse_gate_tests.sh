#!/usr/bin/env bash
# T048 (spec C section 6, K304, K305, K310): in an implementer worktree bash_gate.py reads a command in one pass the
# way bash reads it (command substitutions, comments, heredoc bodies, $'...', brace groups; R-W1 to R-W10, R-H1), and
# the alias check splits an alias value the way the version tool splits it (R-A1 to R-A3). The trigger words are
# assembled at run time; this file holds none of them, and it stays ASCII (the check marks are octal escapes here and
# chr() in the Python block).
# Run: bash tests/parse_gate_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"; UR=set; UR="${UR}-url"
NL=$'\n'; TAB=$'\t'; OK=$'\342\234\224'; NO=$'\342\234\230'
Q="-c 'user.name=A B'"; QQ="-c \"user.name=A B\""
T="$(mktemp -d)"; W="$T/w"; L="$T/l"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
mk(){ # <dir> [card]: a repo with one empty commit on claude/t1; with "card", .delix/card and delix.json
  mkdir -p "$1" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD refs/heads/claude/t1 \
    && $GC -C "$1" commit -q --allow-empty -m init
  if [ "${2:-}" = card ]; then
    mkdir -p "$1/.delix" "$1/docs/delix" "$1/.$G/info"; echo "docs/delix/tasks/T048-x.md" > "$1/.delix/card"
    echo ".delix/" >> "$1/.$G/info/exclude"; printf '{"default_branch":"main"}' > "$1/docs/delix/delix.json"
  fi
}
# setup by direct calls (not through the hook); origin is never contacted
mk "$W" card; mk "$L"
$G -C "$W" $R add origin "$W.$G"; $G -C "$W" $U "refs/${R}s/origin/main" HEAD
$G -C "$W" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
PUSH_DENY="delixcrew: an implementer session pushes only its own card branch ($G $P [-u] origin <branch>); the default branch and every other $P run from the user's own terminal"
REF_DENY="delixcrew: an implementer session does not write $G refs or change ${R}s ($U, $R set-head, $UR, add, remove); those run from the user's own terminal"
QUOTE_DENY="delixcrew: a quote that is never closed stands in front of a $G command, which this hook cannot read; close the quote or put the text in a file, then run the command again"
DEEP_DENY="delixcrew: the command nests quotes or substitutions deeper than this hook reads; split it or put the text in a file, then run the command again"
nest(){ python3 -c 'import sys; k = int(sys.argv[2]); print("echo " + "\"$(" * k + sys.argv[1] + " status" + ")\"" * k)' "$G" "$1"; }
DEEP="$(nest 3000)"; NEST="$(nest 100)"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | python3 "$S/bash_gate.py"; }
# allow = exit 0 and no deny; deny = exit 0, the deny decision and the exact message. A hook that raises exits 1.
allow(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "$OK $1"; else echo "$NO $1 (expected allow, exit $rc): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$4"; then echo "$OK $1"; else echo "$NO $1 (expected deny, exit $rc: $4): $out"; FAIL=1; fi; }

# R-W8: a # glued to a substitution is part of the word (T047 round 4)
deny "1 backticks then #, then ref update"           "$W" "echo \`true\`# \`# it's\`; $G $Q $U x y"                    "$REF_DENY"
deny "2 backticks then #, then send to main"         "$W" "echo \`true\`# \`# it's\`; $G $Q $P origin HEAD:main"       "$PUSH_DENY"
deny "3 substitution then #, then ref update"        "$W" "echo \$(true)# \`# it's\`; $G $Q $U x y"                    "$REF_DENY"
deny "4 substitution then #, then $R url"            "$W" "echo \$(true)# \`# it's\`; $G $Q $R $UR origin /tmp/x"      "$REF_DENY"
deny "5 dq: # it's, backticks #z then #, ref update" "$W" "echo \"# it's \`#z\`# \`$G $Q $U x y\` \""                  "$REF_DENY"
deny "6 dq: backtick quote mix, then send to main"   "$W" "echo \"\`\"'\`'; \\\` # a \`b\` c \"; $G $Q $P origin HEAD:main" "$PUSH_DENY"
deny "7 dq: # it's then substitution, ref update"    "$W" "echo \"# it's \$($G $Q $U x y)\""                            "$REF_DENY"
# R-W7: the output of a substitution counts as no text
deny "8 quoted substitution glued, send to main"     "$W" "\"\$(true)\"$G $Q $P origin HEAD:main"                       "$PUSH_DENY"
deny "9 quoted substitution glued, ref update"       "$W" "\"\$(true)\"$G $Q $U x y"                                    "$REF_DENY"
deny "10 quoted backticks glued, send to main"       "$W" "\"\`true\`\"$G $Q $P origin HEAD:main"                       "$PUSH_DENY"
deny "11 quoted backticks glued, ref update"         "$W" "\"\`true\`\"$G $Q $U x y"                                    "$REF_DENY"
deny "12 quoted substitution glued, $R url"          "$W" "\"\$(true)\"$G $Q $R $UR origin /tmp/x"                      "$REF_DENY"
deny "13 substitution glued after the word"          "$W" "$G\"\$(true)\" $Q $U x y"                                    "$REF_DENY"
deny "14 unquoted substitution glued, send to main"  "$W" "\$(true)$G $Q $P origin HEAD:main"                           "$PUSH_DENY"
# R-W7, R-H1: an apostrophe in double quotes or in a heredoc body, then a substitution or a command
deny "15 dq: it's then substitution, ref update"     "$W" "echo \"it's \$($G $Q $U x y)\""                              "$REF_DENY"
deny "16 dq: it's then backticks, send to main"      "$W" "echo \"it's \`$G $Q $P origin HEAD:main\`\""                 "$PUSH_DENY"
deny "17 assignment: it's then substitution, url"    "$W" "X=\"it's \$($G $Q $R $UR origin /tmp/x)\""                   "$REF_DENY"
deny "18 heredoc: # it's then substitution"          "$W" "cat <<EOF${NL}# it's \$($G $Q $U x y)${NL}EOF"               "$REF_DENY"
deny "19 heredoc: it's then backticks, send"         "$W" "cat <<EOF${NL}it's \`$G $Q $P origin HEAD:main\`${NL}EOF"    "$PUSH_DENY"
deny "20 heredoc: backslash-newline joins the lines" "$W" "cat <<EOF${NL}a \\${NL}\$($G $Q $U x y)${NL}EOF"             "$REF_DENY"
deny "21 heredoc don't, then send to main"           "$W" "cat <<EOF${NL}don't${NL}EOF${NL}$G $Q $P origin HEAD:main"   "$PUSH_DENY"
deny "22 quoted heredoc don't, then ref update"      "$W" "cat <<'EOF'${NL}don't${NL}EOF${NL}$G $Q $U x y"              "$REF_DENY"
deny "23 heredoc <<- tab don't, then send"           "$W" "cat <<-EOF${NL}${TAB}don't${NL}${TAB}EOF${NL}$G $Q $P origin HEAD:main" "$PUSH_DENY"
# R-W7: double quotes nested in a substitution in double quotes
deny "24 assignment: nested dq, ref update"          "$W" "X=\"\$($G $QQ $U x y)\""                                     "$REF_DENY"
deny "25 echo: nested dq, send to main"              "$W" "echo \"\$($G $QQ $P origin HEAD:main)\""                     "$PUSH_DENY"
deny "26 two deep: nested dq, $R url"                "$W" "echo \"\$(echo \"\$($G $QQ $R $UR origin /tmp/x)\")\""       "$REF_DENY"
deny "27 a quoted blank, then nested dq, ref update" "$W" "echo \"\$(echo \"a b\") \$($G $QQ $U x y)\""                 "$REF_DENY"
# R-W10: in $'...' a backslash escapes the quote
deny "28 ansi-c quote, then send to main"            "$W" "echo \$'\\''; $G $Q $P origin HEAD:main"                     "$PUSH_DENY"
deny "29 ansi-c quote, then ref update"              "$W" "echo \$'\\''; $G $Q $U x y"                                  "$REF_DENY"
# R-W9: { and } are reserved words at the start of a command
allow "30 brace group, own branch send"              "$W" "{ $G $P origin HEAD; }"
allow "31 brace group, own branch send with -u"      "$W" "{ $G $P -u origin claude/t1; }"
allow "32 function body, own branch send"            "$W" "f() { $G $P origin HEAD; }; f"
allow "33 brace group, status, redirection"          "$W" "{ $G status; } 2>&1"
deny "34 brace group, send to main"                  "$W" "{ $G $P origin HEAD:main; }"                                 "$PUSH_DENY"
deny "35 brace group, ref update"                    "$W" "{ $G $Q $U x y; }"                                           "$REF_DENY"
# R-W6: nesting deeper than the hook reads
deny "36 3000 nested substitutions in dq"            "$W" "$DEEP"                                                       "$DEEP_DENY"
allow "37 100 nested substitutions in dq, status"    "$W" "$NEST"

# R-A1 to R-A3: alias values as the version tool splits them (written to W's config, unset after case 47)
$G -C "$W" config alias.sa "-c x.y=a;b $R $UR origin /tmp/x"
$G -C "$W" config alias.sb "-c \"user.name=A B\" $R${NL}$UR origin /tmp/x"
$G -C "$W" config alias.sc "-c${NL}alias.zz $R $UR origin /tmp/x"
$G -C "$W" config alias.sd "-c alias.b=$P b origin HEAD:main"
$G -C "$W" config alias.se "-c core.pager=cat -c alias.q=$R q $UR origin /tmp/x"
$G -C "$W" config alias.sq "log \"x"
$G -C "$W" config alias.oa "-c \"user.name=A B\" log --oneline -1"
$G -C "$W" config alias.ob "-c x.y=a;b status"
$G -C "$W" config alias.oc "log --format=\"%h %s\" -1"
$G -C "$W" config alias.od "-c${NL}core.pager=cat log -1"
deny "38 alias: -c value with ;, then $R url"        "$W" "$G sa"                                                       "$REF_DENY"
deny "39 alias: quoted blank, $R newline $UR"        "$W" "$G sb"                                                       "$REF_DENY"
deny "40 alias: -c newline, a line that looks a key" "$W" "$G sc"                                                       "$REF_DENY"
deny "41 alias: -c defines an alias, then send"      "$W" "$G sd"                                                       "$PUSH_DENY"
deny "42 alias: second -c defines an alias"          "$W" "$G se"                                                       "$PUSH_DENY"
deny "43 alias: a quote never closed"                "$W" "$G sq"                                                       "$PUSH_DENY"
allow "44 alias: quoted blank, then log"             "$W" "$G oa"
allow "45 alias: -c value with ;, then status"       "$W" "$G ob"
allow "46 alias: log with a quoted format"           "$W" "$G oc"
allow "47 alias: -c newline value, then log"         "$W" "$G od"
for a in sa sb sc sd se sq oa ob oc od; do $G -C "$W" config --unset "alias.$a"; done

# Allow (cwd W): everyday commands the one pass must keep passing
allow "48 heredoc commit message with an apostrophe" "$W" "$G commit -q --allow-empty -F - <<'EOF'${NL}it's done${NL}EOF"
allow "49 own branch send after a heredoc file write" "$W" "cat > /dev/null <<'EOF'${NL}note${NL}EOF${NL}$G $P origin HEAD"
allow "50 commit -m it's in dq, then status"         "$W" "$G commit -q --allow-empty -m \"it's\" && $G status -s"
allow "51 own branch send, 2>&1 | tail"              "$W" "$G $P origin HEAD 2>&1 | tail -1"
allow "52 substitution in dq, rev-parse"             "$W" "echo \"\$($G rev-parse HEAD)\""
allow "53 assignment from a substitution, status"    "$W" "X=\"\$($G -C \"$W\" status -s)\"; echo \"\$X\""
allow "54 log with a quoted format"                  "$W" "$G log --format='%h %s' -1"
allow "55 ansi-c it's, then status"                  "$W" "echo \$'it\\'s'; $G status"
allow "56 test loop"                                 "$W" "for t in tests/*_tests.sh; do bash \"\$t\" || exit 1; done"
allow "57 heredoc with a substitution, log"          "$W" "cat <<EOF${NL}\$($G log -1 --format=%s)${NL}EOF"
allow "58 # glued to substitutions, then status"     "$W" "echo \`true\`#x \$(true)#y; $G status"
allow "59 gh pr create, it's in the title"           "$W" "gh pr create --title \"T048: it's done\" --body-file /tmp/b.md"
allow "60 quoted heredoc write, it's, a substitution" "$W" "cat > notes.md <<'EOF'${NL}it's \$(here)${NL}EOF"
allow "61 diff against a merge-base substitution"    "$W" "$G diff --stat \"\$($G merge-base HEAD origin/main)\""
# Allow (cwd L, no card): the rules are not active
allow "62 no card: quoted substitution glued, send"  "$L" "\"\$(true)\"$G $Q $P origin HEAD:main"
allow "63 no card: brace group, send to main"        "$L" "{ $G $P origin HEAD:main; }"
allow "64 no card: 3000 nested substitutions"        "$L" "$DEEP"

# Growth (repo hook rule): the least of 3 runs per size; t(40000) < 3 s and t(40000)/t(5000) < 20
python3 - "$S/bash_gate.py" "$W" "$G" <<'PYT' || FAIL=1
import json, subprocess, sys, time
hook, w, g = sys.argv[1:4]
cases = [("heredocs with a substitution", lambda k: ("cat <<EOF\nit's $(echo x)\nEOF\n" * k) + g + " status"),
         ("quoted heredocs with a quote", lambda k: ("cat <<'EOF'\ndon't\nEOF\n" * k) + g + " status"),
         ("continued heredoc lines", lambda k: "cat <<EOF\n" + ("a\\\n" * k) + "EOF\n" + g + " status"),
         ("nested quotes in substitutions", lambda k: ("echo \"$(echo \"a b\")\"; " * k) + g + " status"),
         ("hash after a substitution", lambda k: ("echo `true`#x $(true)#y; " * k) + g + " status"),
         ("ansi-c quotes", lambda k: ("echo $'it\\'s'; " * k) + g + " status"),
         ("brace groups", lambda k: ("{ " + g + " status; }; ") * k),
         ("heredoc delimiters", lambda k: ("cat <<\"E F\"\nx\nE F\n" * k) + g + " status")]
bad = 0
for name, make in cases:
    t = {}
    for k in (5000, 40000):
        data = json.dumps({"tool_name": "Bash", "cwd": w, "tool_input": {"command": make(k)}})
        runs = []
        for _ in range(3):
            s = time.perf_counter()
            subprocess.run([sys.executable, hook], input=data, capture_output=True, text=True, timeout=60)
            runs.append(time.perf_counter() - s)
        t[k] = min(runs)
    ratio = t[40000] / t[5000]
    ok = t[40000] < 3 and ratio < 20
    bad |= not ok
    print((chr(0x2714) if ok else chr(0x2718)) + " growth %s: t(5000)=%.3fs t(40000)=%.3fs ratio=%.2f"
          % (name, t[5000], t[40000], ratio))
sys.exit(1 if bad else 0)
PYT
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
