#!/usr/bin/env bash
# T047 (spec C section 6, K296; T044 round 1): in an implementer worktree bash_gate.py reads a command the way bash
# builds its argv as well as by the loose word scan (R-W1, R-W2), denies a quote that is never closed in front of a
# command word of the version tool (R-W3, R-W4), and follows an alias value that starts with global options to its
# command (R-W5). The trigger words are assembled at run time; this file holds none of them, and it stays ASCII (the
# check marks are octal escapes here and chr() in the Python block).
# Run: bash tests/argv_gate_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"; UR=set; UR="${UR}-url"
NL=$'\n'; OK=$'\342\234\224'; NO=$'\342\234\230'
VT=$'\v'; FF=$'\f'; CR=$'\r'; NB=$'\302\240'
T="$(mktemp -d)"; W="$T/w"; L="$T/l"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
mk(){ # <dir> [card]: a repo with one empty commit on claude/t1; with "card", .delix/card and delix.json
  mkdir -p "$1" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD refs/heads/claude/t1 \
    && $GC -C "$1" commit -q --allow-empty -m init
  if [ "${2:-}" = card ]; then
    mkdir -p "$1/.delix" "$1/docs/delix" "$1/.$G/info"; echo "docs/delix/tasks/T047-x.md" > "$1/.delix/card"
    echo ".delix/" >> "$1/.$G/info/exclude"; printf '{"default_branch":"main"}' > "$1/docs/delix/delix.json"
  fi
}
# setup by direct calls (not through the hook); origin is never contacted
mk "$W" card; mk "$L"; mkdir -p "$W/a b"
$G -C "$W" $R add origin "$W.$G"; $G -C "$W" $U "refs/${R}s/origin/main" HEAD
$G -C "$W" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
PUSH_DENY="delixcrew: an implementer session pushes only its own card branch ($G $P [-u] origin <branch>); the default branch and every other $P run from the user's own terminal"
REF_DENY="delixcrew: an implementer session does not write $G refs or change ${R}s ($U, $R set-head, $UR, add, remove); those run from the user's own terminal"
QUOTE_DENY="delixcrew: a quote that is never closed stands in front of a $G command, which this hook cannot read; close the quote or put the text in a file, then run the command again"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | python3 "$S/bash_gate.py"; }
# allow = exit 0 and no deny; deny = exit 0, the deny decision and the exact message. A hook that raises exits 1.
allow(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "$OK $1"; else echo "$NO $1 (expected allow, exit $rc): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$4"; then echo "$OK $1"; else echo "$NO $1 (expected deny, exit $rc: $4): $out"; FAIL=1; fi; }

# R-W1: an option value with a comma or a bracket, a quoted blank, a backslash-newline (cwd W, a card worktree)
deny "1 -c value with a comma, ref update"        "$W" "$G -c x.y=a,b $U x y"                         "$REF_DENY"
deny "2 -c value with a comma, $R url"            "$W" "$G -c x.y=a,b $R $UR origin /tmp/x"           "$REF_DENY"
deny "3 -c value with a comma, send to main"      "$W" "$G -c x.y=a,b $P origin HEAD:main"            "$PUSH_DENY"
deny "4 -c value with brackets, ref update"       "$W" "$G -c x.y=[a] $U x y"                         "$REF_DENY"
deny "5 -C dir with a blank, ref update"          "$W" "$G -C \"$W/a b\" $U x y"                      "$REF_DENY"
deny "6 -C dir with a blank, $R url"              "$W" "$G -C \"$W/a b\" $R $UR origin /tmp/x"        "$REF_DENY"
deny "7 -c value with a blank, ref update"        "$W" "$G -c \"user.name=A B\" $U x y"               "$REF_DENY"
deny "8 -c value with a blank, send to main"      "$W" "$G -c \"user.name=A B\" $P origin HEAD:main"  "$PUSH_DENY"
deny "9 --$G-dir with a blank, ref update"        "$W" "$G --$G-dir \"$W/a b\" $U x y"                "$REF_DENY"
deny "10 backslash-newline before the subcommand" "$W" "$G \\${NL}$U x y"                             "$REF_DENY"
deny "11 backslash-newline, send to main"         "$W" "$G \\${NL}$P origin main"                     "$PUSH_DENY"
deny "12 -C . then backslash-newline"             "$W" "$G -C . \\${NL}$U x y"                        "$REF_DENY"
deny "13 backslash-newline inside $R"             "$W" "$G $R \\${NL}$UR origin x"                    "$REF_DENY"
deny "14 backslash-newline after the send"        "$W" "$G $P \\${NL}origin main"                     "$PUSH_DENY"
# R-W1: a redirection ends the word and takes no argument; a quoted or escaped > is an argument; a lone backslash
deny "15 glued > after the subcommand"            "$W" "$G $U>/dev/null x y"                          "$REF_DENY"
deny "16 glued > after the send"                  "$W" "$G $P>/dev/null origin HEAD:main"             "$PUSH_DENY"
deny "17 glued < after the send"                  "$W" "$G $P</dev/null origin HEAD:main"             "$PUSH_DENY"
deny "18 glued > after $R"                        "$W" "$G $R>/dev/null $UR origin x"                 "$REF_DENY"
deny "19 >&2 before a second name"                "$W" "$G $P origin claude/t1 >&2 HEAD:main"         "$PUSH_DENY"
deny "20 2>&1 before a second name"               "$W" "$G $P origin claude/t1 2>&1 HEAD:main"        "$PUSH_DENY"
deny "21 >| f before a second name"               "$W" "$G $P origin claude/t1 >| f HEAD:main"        "$PUSH_DENY"
deny "22 &>f before a second name"                "$W" "$G $P origin claude/t1 &>f HEAD:main"         "$PUSH_DENY"
deny "23 quoted > before a second name"           "$W" "$G $P origin claude/t1 \">\" HEAD:main"       "$PUSH_DENY"
deny "24 escaped > before a second name"          "$W" "$G $P origin claude/t1 \\> HEAD:main"         "$PUSH_DENY"
deny "25 backslash at the end, ref update"        "$W" "$G $U x y \\"                                 "$REF_DENY"
# R-W2: the text of a quoted token is read again
deny "26 sh -c string, send to main"              "$W" "sh -c \"$G -c 'a b' $P origin HEAD:main\""    "$PUSH_DENY"
deny "27 sh -c string, ref update"                "$W" "sh -c \"$G -c 'a b' $U x y\""                 "$REF_DENY"
deny "28 substitution in double quotes"           "$W" "echo \"\$($G -c 'a b' $U x y)\""              "$REF_DENY"
deny "29 substitution in a redirection target"    "$W" "echo hi > \"\$($G -c 'a b' $U x y)\""         "$REF_DENY"
deny "30 backticks in double quotes"              "$W" "echo \"\`$G -c 'a b' $U x y\`\""              "$REF_DENY"
deny "31 heredoc body, ref update"                "$W" "bash <<'EOF'${NL}$G -c \"a b\" $U x y${NL}EOF" "$REF_DENY"
# R-W3: a quote that is never closed (deny), and what must pass (allow)
deny "32 comment with a quote, then a command"    "$W" "echo x # it's${NL}$G -c \"a b\" $P origin HEAD:main" "$PUSH_DENY"
deny "33 heredoc body with a quote, then $G"      "$W" "bash <<'EOF'${NL}echo don't${NL}$G -c \"a b\" $U x y${NL}EOF" "$QUOTE_DENY"
deny "34 quote, then $G on the line (known false positive)" "$W" "echo don't; $G status"              "$QUOTE_DENY"
allow "35 quote with no $G word after it"         "$W" "echo don't >> notes.txt"
allow "36 heredoc file write, apostrophe, no $G"  "$W" "cat > notes.md <<'EOF'${NL}it's here${NL}EOF"
allow "37 comment with a quote, no $G word"       "$W" "$G status # it's fine"

# R-W5: aliases whose value starts with global options (written to W's config, unset after case 49)
$G -C "$W" config alias.lc "-c core.pager=cat $R $UR origin /tmp/x"
$G -C "$W" config alias.lu "-C . $U x y"
$G -C "$W" config alias.lq "-c \"user.name=A B\" $R $UR origin /tmp/x"
$G -C "$W" config alias.lm "-c x.y=a,b $U x y"
$G -C "$W" config alias.lx "-c core.pager=cat lc"
$G -C "$W" config alias.ly "-C . -c core.pager=cat lx"
$G -C "$W" config alias.le "--config-env=x.y=Z $U x y"
$G -C "$W" config alias.lp "-c core.pager=cat $P origin main"
$G -C "$W" config alias.lg "-c color.ui=always log --oneline"
$G -C "$W" config alias.lv "-c core.pager=cat $R -v"
$G -C "$W" config alias.lr "-c core.pager=cat $R show"
$G -C "$W" config alias.ln "-c"
deny "38 alias -c, then $R url"                   "$W" "$G lc"                                        "$REF_DENY"
deny "39 alias -C, then ref update"               "$W" "$G lu"                                        "$REF_DENY"
deny "40 alias -c with a blank value"             "$W" "$G lq"                                        "$REF_DENY"
deny "41 alias -c with a comma value"             "$W" "$G lm"                                        "$REF_DENY"
deny "42 alias chain lx = -c .. lc"               "$W" "$G lx"                                        "$REF_DENY"
deny "43 alias chain ly = -C . -c .. lx"          "$W" "$G ly"                                        "$REF_DENY"
deny "44 alias --config-env=.., ref update"       "$W" "$G le"                                        "$REF_DENY"
deny "45 alias -c, then a send (PUSH_DENY wins)"  "$W" "$G lp"                                        "$PUSH_DENY"
allow "46 alias -c, then log"                     "$W" "$G lg"
allow "47 alias -c, then $R -v"                   "$W" "$G lv"
allow "48 alias -c, then $R show"                 "$W" "$G lr origin"
allow "49 alias that is only an option"           "$W" "$G ln"
for a in lc lu lq lm lx ly le lp lg lv lr ln; do $G -C "$W" config --unset "alias.$a"; done

# Allow (cwd W): commands the new reading must keep passing
allow "50 -C dir, status"                         "$W" "$G -C \"$W\" status"
allow "51 -c value with a blank, status"          "$W" "$G -c \"user.name=A B\" status"
allow "52 -c value with a comma, status"          "$W" "$G -c user.name=A,B status"
allow "53 log --grep with a quote and brackets"   "$W" "$G log --grep \"it's a, b [c]\" -1"
allow "54 log --grep with double quotes"          "$W" "$G log --grep 'say \"hi\", then go' -1"
allow "55 backslash-newline before status"        "$W" "$G \\${NL}status"
allow "56 backslash-newline inside status args"   "$W" "$G status \\${NL}-s"
allow "57 own branch send, 2>&1"                  "$W" "$G $P origin claude/t1 2>&1"
allow "58 own branch send, >f"                    "$W" "$G $P origin claude/t1 >f"
allow "59 own branch send, &>f"                   "$W" "$G $P origin claude/t1 &>f"
allow "60 own branch send, quoted name"           "$W" "$G $P origin \"claude/t1\""
allow "61 -C dir with a blank, $R show"           "$W" "$G -C \"$W/a b\" $R show origin"
allow "62 substitution in double quotes, status"  "$W" "echo \"\$($G status)\""
allow "63 sh -c string, status"                   "$W" "sh -c \"$G -C '$W' status\""
allow "64 backslash at the end of the command"    "$W" "echo a\\"
# Allow (cwd L, no card): the rules are not active
allow "65 no card: comma value, ref update"       "$L" "$G -c x.y=a,b $U x y"
allow "66 no card: glued >, send"                 "$L" "$G $P>/dev/null origin HEAD:main"
allow "67 no card: quote, then $G"                "$L" "echo don't; $G status"

# Review round 1 (T047): forms qa and security found, and the alias value that git splits on any blank
$G -C "$W" config alias.lz "$R${NL}$UR origin /tmp/x"
deny "68 alias with a newline between $R and $UR"   "$W" "$G lz"                                       "$REF_DENY"
$G -C "$W" config --unset alias.lz
deny "69 comment quote, then a quoted command word" "$W" "echo x # it's${NL}g\"\"it -c \"user.name=A B\" $U x y" "$REF_DENY"
deny "70 comment quote, then an escaped command word" "$W" "echo x # it's${NL}g\\it -c \"user.name=A B\" $U x y" "$REF_DENY"
deny "71 comment quote, then a command word glued to >" "$W" "echo x # it's${NL}$G>f -c \"user.name=A B\" $P origin HEAD:main" "$PUSH_DENY"
deny "72 vertical tab in a -c value, ref update"    "$W" "$G -c user.name=A${VT}B $U x y"              "$REF_DENY"
deny "73 carriage return in a -c value, send to main" "$W" "$G -c user.name=A${CR}B $P origin HEAD:main" "$PUSH_DENY"
deny "74 no-break space in a -c value, ref update"  "$W" "$G -c user.name=A${NB}B $U x y"              "$REF_DENY"
deny "75 form feed in a -c value, $R url"           "$W" "$G -c user.name=A${FF}B $R $UR origin /tmp/x" "$REF_DENY"
allow "76 vertical tab in a -c value, status"       "$W" "$G -c user.name=A${VT}B status"

# Review round 2 (T047): `{` `}` inside a word, comments, a backslash-newline after a quote that is never closed
deny "77 -c value with {, send to main"            "$W" "$G -c x.y={b $P origin HEAD:main"            "$PUSH_DENY"
deny "78 -c value with }, ref update"              "$W" "$G -c x.y=} $U x y"                          "$REF_DENY"
deny "79 { } group around a -c value with {"       "$W" "{ $G -c x.y={b $P origin HEAD:main; }"       "$PUSH_DENY"
deny "80 comment quote, then a single-quoted value" "$W" "echo x # it's${NL}$G -c 'user.name=A B' $U x y" "$REF_DENY"
deny "81 comment line with a quote, then a send"   "$W" "# don't do this${NL}$G -c 'user.name=A B' $P origin HEAD:main" "$PUSH_DENY"
deny "82 comment quote, then g'i't"                "$W" "echo x # it's${NL}g'i't -c \"user.name=A B\" $U x y" "$REF_DENY"
deny "83 sh -c: comment quote, then a send"         "$W" "sh -c \"echo x # it's${NL}$G -c 'user.name=A B' $P origin HEAD:main\"" "$PUSH_DENY"
deny "84 comment quote, then gi backslash-newline t" "$W" "echo x # it's${NL}gi\\${NL}t -c \"user.name=A B\" $U x y" "$REF_DENY"
deny "85 heredoc quote, then gi backslash-newline t" "$W" "cat <<'EOF'${NL}don't${NL}EOF${NL}gi\\${NL}t -c \"user.name=A B\" $U x y" "$QUOTE_DENY"
deny "86 comment inside backticks, then a value"   "$W" "\`#x\`$G -c 'user.name=A B' $U x y"          "$REF_DENY"
deny "87 # after a quote is a word character"      "$W" "$G -c 'x.y=a b'#c $U x y"                    "$REF_DENY"
deny "88 # after an escaped blank is a word character" "$W" "$G -c x.y=a\\ #b $U x y"                  "$REF_DENY"
allow "89 comment quote, then status"              "$W" "echo x # it's${NL}$G status"
allow "90 { } group around status"                 "$W" "{ $G status; }"
allow "91 log --format with braces"                "$W" "$G log -1 --format='{%H}'"
allow "92 -c value with {, status"                 "$W" "$G -c x.y={b status"
allow "93 sh -c: comment quote, then status"        "$W" "sh -c \"echo x # it's${NL}$G status\""

# Review round 3 (T047): `#` in double quotes or a heredoc body is no comment; a backtick ends a comment only in `...`
deny "94 # in double quotes, then \$(...)"          "$W" "echo \"# \$($G -c 'user.name=A B' $U x y)\""   "$REF_DENY"
deny "95 # inside a double-quoted string, send"     "$W" "echo \"x # \$($G -c 'user.name=A B' $P origin HEAD:main)\"" "$PUSH_DENY"
deny "96 heredoc body line # \$(...)"               "$W" "cat <<EOF${NL}# \$($G -c 'user.name=A B' $U x y)${NL}EOF" "$REF_DENY"
deny "97 backticks in a comment, then a send"       "$W" "# run \`make\` first, it's needed${NL}$G -c 'user.name=A B' $P origin HEAD:main" "$PUSH_DENY"
deny "98 backticks in a comment, then a ref update" "$W" "echo x # \`x\` it's${NL}$G -c 'user.name=A B' $U x y" "$REF_DENY"
allow "99 # and a quote in double quotes, then status" "$W" "echo \"# it's a note\"; $G status"
allow "100 backticks and a quote in a comment, then status" "$W" "# run \`make\`, it's fine${NL}$G status"

# Growth (repo hook rule): the least of 3 runs per size; t(40000) < 3 s and t(40000)/t(5000) < 20
python3 - "$S/bash_gate.py" "$W" "$G" <<'PYT' || FAIL=1
import json, subprocess, sys, time
hook, w, g = sys.argv[1:4]
cases = [("comma values", lambda k: (g + " -c a,b status; ") * k),
         ("quoted blanks", lambda k: (g + " -C \"a b\" status; ") * k),
         ("sh -c strings", lambda k: ("sh -c \"" + g + " -c 'a b' status\"; ") * k),
         ("backslash-newlines", lambda k: g + " " + ("\\\n" * k) + " status"),
         ("redirections", lambda k: (g + " status 2>&1; ") * k),
         ("one quote never closed", lambda k: "'" + (g + " status; ") * k),
         ("comments with a quote", lambda k: ("echo x # it's\n" * k) + g + " status"),
         ("braces in values", lambda k: (g + " -c x.y={b status; ") * k),
         ("hashes in double quotes", lambda k: ("echo \"# it's\"; " * k) + g + " status"),
         ("backticks in comments", lambda k: ("# a `b` it's\n" * k) + g + " status")]
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
