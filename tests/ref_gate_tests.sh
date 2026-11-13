#!/usr/bin/env bash
# T044 (spec C section 6, K296): in an implementer worktree bash_gate.py denies the ref-writing subcommands of the card
# (R-U1 to R-U3); a delix.json that is not a JSON object (R-U4) and a byte that is not UTF-8 in a setting the rule
# reads (R-U5) deny with a message instead of a crash. The trigger words are assembled at run time; this file holds
# none of them, and it stays ASCII (the check marks and the bad byte are octal escapes).
# Run: bash tests/ref_gate_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"
HD=set; HD="${HD}-head"; UR=set; UR="${UR}-url"
OK=$'\342\234\224'; NO=$'\342\234\230'
T="$(mktemp -d)"; W="$T/w"; L="$T/l"; BK="$T/config.bak"; DJ="$T/w/docs/delix/delix.json"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
mk(){ # <dir> [card]: a repo with one empty commit on claude/t1; with "card", .delix/card and delix.json
  mkdir -p "$1" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD refs/heads/claude/t1 \
    && $GC -C "$1" commit -q --allow-empty -m init
  if [ "${2:-}" = card ]; then
    mkdir -p "$1/.delix" "$1/docs/delix" "$1/.$G/info"; echo "docs/delix/tasks/T044-x.md" > "$1/.delix/card"
    echo ".delix/" >> "$1/.$G/info/exclude"; printf '{"default_branch":"main"}' > "$1/docs/delix/delix.json"
  fi
}
# setup by direct calls (not through the hook); origin is never contacted
mk "$W" card; mk "$L"
$G -C "$W" $R add origin "$W.$G"; $G -C "$W" $U "refs/${R}s/origin/main" HEAD
$G -C "$W" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
cp "$W/.$G/config" "$BK"
PUSH_DENY="delixcrew: an implementer session pushes only its own card branch ($G $P [-u] origin <branch>); the default branch and every other $P run from the user's own terminal"
REF_DENY="delixcrew: an implementer session does not write $G refs or change ${R}s ($U, $R $HD, $UR, add, remove); those run from the user's own terminal"
ENC_DENY="delixcrew: a $G setting or ref name holds a byte that is not UTF-8, which this hook cannot read; the command is denied until the user removes it from their own terminal"
JSON_DENY="delixcrew: docs/delix/delix.json is not a JSON object; Bash stays blocked in this card worktree until the user fixes it from their own terminal"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | python3 "$S/bash_gate.py"; }
# allow = exit 0 and no deny; deny = exit 0, the deny decision and the exact message. A hook that raises exits 1.
allow(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "$OK $1"; else echo "$NO $1 (expected allow, exit $rc): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$4"; then echo "$OK $1"; else echo "$NO $1 (expected deny, exit $rc: $4): $out"; FAIL=1; fi; }
GU=$(echo "$G" | tr a-z A-Z); UU=$(echo "$U" | tr a-z A-Z); URU=$(echo "$UR" | tr a-z A-Z)

# R-U1: the ref update subcommand, whatever its arguments (cwd W, a card worktree)
deny "1 ref update of a tracking ref"           "$W" "$G $U refs/${R}s/origin/main HEAD"            "$REF_DENY"
deny "2 ref delete"                             "$W" "$G $U -d refs/${R}s/origin/main"              "$REF_DENY"
deny "3 -C dir"                                 "$W" "$G -C \"$W\" $U refs/${R}s/origin/main HEAD"   "$REF_DENY"
deny "4 --no-pager"                             "$W" "$G --no-pager $U x y"                          "$REF_DENY"
deny "5 -c core.pager=cat"                      "$W" "$G -c core.pager=cat $U x y"                   "$REF_DENY"
deny "6 command name upper-cased"               "$W" "$GU $U x y"                                    "$REF_DENY"
deny "7 subcommand upper-cased"                 "$W" "$G $UU x y"                                    "$REF_DENY"
deny "8 dashed name with a path"                "$W" "/x/$G-$U x y"                                  "$REF_DENY"
deny "9 after echo ok &&"                       "$W" "echo ok && $G $U x y"                          "$REF_DENY"
deny "10 command substitution"                  "$W" "echo \$($G $U x y)"                            "$REF_DENY"
deny "11 variable assignment first"             "$W" "X=1 $G $U x y"                                 "$REF_DENY"
# R-U2: the remotes subcommand outside its read forms
deny "12 $HD origin -a"                         "$W" "$G $R $HD origin -a"                           "$REF_DENY"
deny "13 $HD origin main"                       "$W" "$G $R $HD origin main"                         "$REF_DENY"
deny "14 -v, then $HD"                          "$W" "$G $R -v $HD origin -a"                        "$REF_DENY"
deny "15 $UR"                                   "$W" "$G $R $UR origin /tmp/x"                       "$REF_DENY"
deny "16 add"                                   "$W" "$G $R add o u"                                 "$REF_DENY"
deny "17 remove"                                "$W" "$G $R remove origin"                           "$REF_DENY"
deny "18 rm"                                    "$W" "$G $R rm origin"                               "$REF_DENY"
deny "19 rename"                                "$W" "$G $R rename origin x"                         "$REF_DENY"
deny "20 update"                                "$W" "$G $R update"                                  "$REF_DENY"
deny "21 prune"                                 "$W" "$G $R prune origin"                            "$REF_DENY"
deny "22 set-branches"                          "$W" "$G $R set-branches origin x"                   "$REF_DENY"
deny "23 dashed name with a path, add"          "$W" "/x/$G-$R add o u"                              "$REF_DENY"
deny "24 $UR upper-cased"                       "$W" "$G $R $URU origin x"                           "$REF_DENY"
deny "25 -c core.pager=cat, then $UR"           "$W" "$G -c core.pager=cat $R $UR origin x"          "$REF_DENY"
# R-P3b unchanged: a read of the remotes still counts as another command on a line with a send
deny "26 -v read, then a send"                  "$W" "$G $R -v && $G $P origin HEAD"                 "$PUSH_DENY"

# Allow (cwd W): the read forms, read commands that hold the words, the own-branch send
allow "27 no subcommand"                        "$W" "$G $R"
allow "28 -v"                                   "$W" "$G $R -v"
allow "29 --verbose"                            "$W" "$G $R --verbose"
allow "30 show"                                 "$W" "$G $R show origin"
allow "31 -v show"                              "$W" "$G $R -v show origin"
allow "32 get-url"                              "$W" "$G $R get-url origin"
allow "33 get-url with the send flag"           "$W" "$G $R get-url --$P origin"
allow "34 config --get of the origin url"       "$W" "$G config --get $R.origin.url"
allow "35 log --grep the word"                  "$W" "$G log --grep $U -1"
allow "36 grep for the word"                    "$W" "grep -rn $U src"
allow "37 commit message with the word"         "$W" "$G commit -m 'T044: $U'"
allow "38 own branch send"                      "$W" "$G $P origin claude/t1"
# Allow (cwd L, no card): the rule is not active
allow "39 no card: ref update"                  "$L" "$G $U x y"
allow "40 no card: $UR"                         "$L" "$G $R $UR o u"

# R-U3: aliases (written to W's config, then unset)
$G -C "$W" config alias.ur "$U -d"; $G -C "$W" config alias.sh "$R $HD origin -a"
$G -C "$W" config alias.ra "$R add"; $G -C "$W" config alias.u2 ur
$G -C "$W" config alias.rv "$R -v"; $G -C "$W" config alias.rs "$R show"
deny "41 alias ur (ref delete)"                 "$W" "$G ur x"                                       "$REF_DENY"
deny "42 alias sh ($HD)"                        "$W" "$G sh"                                         "$REF_DENY"
deny "43 alias ra (add)"                        "$W" "$G ra o u"                                     "$REF_DENY"
deny "44 alias chain u2 = ur"                   "$W" "$G u2 x"                                       "$REF_DENY"
allow "45 alias rv (-v)"                        "$W" "$G rv"
allow "46 alias rs (show)"                      "$W" "$G rs origin"
for a in ur sh ra u2 rv rs; do $G -C "$W" config --unset "alias.$a"; done

# R-U4: a delix.json that is not a JSON object denies every command in the card worktree
n=47
for b in '[]' '"x"' null 3 true; do
  printf '%s' "$b" > "$DJ"; deny "$n delix.json $b: ls" "$W" "ls" "$JSON_DENY"; n=$((n + 1))
done
printf '[]' > "$DJ"
deny "52 delix.json []: status"                 "$W" "$G status"                                     "$JSON_DENY"
mkdir -p "$L/docs/delix"; printf '[]' > "$L/docs/delix/delix.json"
allow "53 no card, delix.json []: ls"           "$L" "ls"
printf '{}' > "$DJ"
allow "54 delix.json {}: ls"                    "$W" "ls"
allow "55 delix.json {}: own branch send"       "$W" "$G $P origin claude/t1"
deny "56 delix.json {}: ref update"             "$W" "$G $U x y"                                     "$REF_DENY"
rm "$DJ"
allow "57 delix.json removed: ls"               "$W" "ls"
printf '{"default_branch":"main"}' > "$DJ"

# R-U5: a byte that is not UTF-8 (octal escape 377) in a setting the rule reads denies with a message
printf '[alias]\n\tbad = log \377\n' >> "$W/.$G/config"
deny "58 bad byte in an alias: status"          "$W" "$G status"                                     "$ENC_DENY"
deny "59 bad byte in an alias: the alias"       "$W" "$G bad"                                        "$ENC_DENY"
allow "60 bad byte in an alias: ls"             "$W" "ls"
allow "61 bad byte in an alias: own branch send" "$W" "$G $P origin claude/t1"
cp "$BK" "$W/.$G/config"
printf '[%s "origin"]\n\t%s = \377\n' "$R" "$P" >> "$W/.$G/config"
deny "62 bad byte in the origin send setting"   "$W" "$G $P origin claude/t1"                        "$ENC_DENY"
cp "$BK" "$W/.$G/config"
allow "63 config restored: status"              "$W" "$G status"

# Growth (repo hook rule): the least of 3 runs per size; t(160000) < 3 s and t(160000)/t(20000) < 20
python3 - "$S/bash_gate.py" "$W" "$G" "$U" "$R" <<'PYT' || FAIL=1
import json, subprocess, sys, time
hook, w, g, u, r = sys.argv[1:6]
cases = [("-v reads, then a ref update", lambda k: (g + " " + r + " -v; ") * k + g + " " + u + " x y"),
         ("show reads in one segment", lambda k: (g + " " + r + " show origin ") * k),
         ("one run of -v, then show", lambda k: g + " " + r + " " + "-v " * k + "show origin"),
         ("get-url reads, then status", lambda k: (g + " " + r + " get-url origin; ") * k + g + " status")]
bad = 0
for name, make in cases:
    t = {}
    for k in (20000, 160000):
        data = json.dumps({"tool_name": "Bash", "cwd": w, "tool_input": {"command": make(k)}})
        runs = []
        for _ in range(3):
            s = time.perf_counter()
            subprocess.run([sys.executable, hook], input=data, capture_output=True, text=True, timeout=60)
            runs.append(time.perf_counter() - s)
        t[k] = min(runs)
    ratio = t[160000] / t[20000]
    ok = t[160000] < 3 and ratio < 20
    bad |= not ok
    print(("\u2714" if ok else "\u2718") + " growth %s: t(20000)=%.3fs t(160000)=%.3fs ratio=%.2f"
          % (name, t[20000], t[160000], ratio))
sys.exit(1 if bad else 0)
PYT
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
