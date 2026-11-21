#!/usr/bin/env bash
# T063 (K374): in a card worktree bash_gate.py denies a shell write to a protected path through every redirect operator
# spelling (no blank after the operator, >>, >|, N>, &>, >&, <>, zsh >! and >&|, a backslash newline) and through
# every word after cp, mv or tee (any letter case, options too), up to the end of the command outside quotes (across
# lines, as before). Free paths, fd duplication and the REQ-5 cat heredoc stay allowed, and the check grows linearly
# (growth ratio). The file stays ASCII (the check marks are octal escapes or chr()).
# Run: bash tests/redirect_gate_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"
OK=$'\342\234\224'; NO=$'\342\234\230'
T="$(mktemp -d)"; C="$T/card"; N="$T/nocard"
mkdir -p "$C/.delix" "$C/docs/delix" "$C/auth" "$N"
$G -C "$C" init -q; $G -C "$N" init -q; echo "docs/delix/tasks/T063-x.md" > "$C/.delix/card"
printf '{"test_command":"true","extra_checks":[],"protected_paths":["auth/**","scripts/x.py",".env*"],"test_paths":["tests/**"]}' \
  > "$C/docs/delix/delix.json"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | python3 "$S/bash_gate.py"; }
ml(){ printf '%s\n' "$@"; }
pm(){ # <target> <pattern>: the deny text, letter for letter
  printf "delixcrew: the command writes to a protected path ('%s' ~ %s). Tier 3 path; human approval required." "$1" "$2"; }
# allow = exit 0 and no deny; deny = exit 0, the deny decision and the exact message. A hook that raises exits 1.
allow(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "$OK $1"; else echo "$NO $1 (expected allow, exit $rc): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3" 2>&1); rc=$?; if [ $rc -eq 0 ] && echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$4"; then echo "$OK $1"; else echo "$NO $1 (expected deny, exit $rc: $4): $out"; FAIL=1; fi; }
A=$(pm auth/x.py 'auth/**'); X=$(pm scripts/x.py scripts/x.py)
A0="delixcrew: the command writes to a protected path ('auth/x.py"  # the base names the word with its ')'
HD="$(ml "cat >auth/x.py <<'EOF'" 'x = 1' 'EOF')"

# ---- 1. Redirect operators without a blank, and the spellings the check did not see
deny "1 >path"                       "$C" 'echo x >auth/x.py'                  "$A"
deny "1 no blank before > either"    "$C" 'echo x>auth/x.py'                   "$A"
deny "1 >>path"                      "$C" 'echo x >>auth/x.py'                 "$A"
deny "1 >|path"                      "$C" 'echo x >|auth/x.py'                 "$A"
deny "1 >| path"                     "$C" 'echo x >| auth/x.py'                "$A"
deny "1 1>path"                      "$C" 'echo x 1>auth/x.py'                 "$A"
deny "1 2>path"                      "$C" 'echo x 2>auth/x.py'                 "$A"
deny "1 2>>path"                     "$C" 'echo x 2>>auth/x.py'                "$A"
deny "1 &>path"                      "$C" 'echo x &>auth/x.py'                 "$A"
deny "1 &>>path"                     "$C" 'echo x &>>auth/x.py'                "$A"
deny "1 >&path"                      "$C" 'echo x >&auth/x.py'                 "$A"
deny "1 1<>path"                     "$C" 'echo x 1<>auth/x.py'                "$A"
deny "1 >\"path\""                   "$C" 'echo x >"auth/x.py"'                "$A"
deny "1 >'path', exact pattern"      "$C" "echo x >'scripts/x.py'"             "$X"
deny "1 in \$( ), exact pattern"     "$C" 'y=$(echo x >scripts/x.py)'          "$X"
deny "1 in a subshell, exact pattern" "$C" '(echo x >scripts/x.py)'            "$X"
deny "1 in backticks, exact pattern" "$C" 'y=`echo x >scripts/x.py`'           "$X"
deny "1 > then a backslash newline"  "$C" "$(ml 'echo x > \' 'auth/x.py')"     "$A"
deny "1 cat >path heredoc (REQ-5 shape)" "$C" "$HD"                            "$A"
deny "1 cat >>path heredoc"          "$C" "$(ml "cat >>auth/x.py <<'EOF'" 'x = 1' 'EOF')" "$A"
deny "1 zsh >!path"                  "$C" 'echo x >!auth/x.py'                 "$A"
deny "1 zsh >>!path"                 "$C" 'echo x >>!auth/x.py'                "$A"
deny "1 zsh >&|path"                 "$C" 'echo x >&|auth/x.py'                "$A"
deny "1 zsh &>! path"                "$C" 'echo x &>! auth/x.py'               "$A"
deny "1 >\$(pwd)/.env, name-only pattern" "$C" 'echo X=1 >$(pwd)/.env'   "$(pm '$(pwd)/.env' '.env*')"

# ---- 2. cp, mv and tee: every word after the command
deny "2 cp, then a redirect"         "$C" 'cp a auth/x.py 2>/dev/null'         "$A"
deny "2 cp, then an option"          "$C" 'cp a auth/x.py -f'                  "$A"
deny "2 cp -t dir"                   "$C" 'cp -t auth a'                       "$(pm auth 'auth/**')"
deny "2 mv, then a redirect"         "$C" 'mv a auth/x.py >/dev/null'          "$A"
deny "2 mv moves a protected file out" "$C" 'mv auth/x.py /tmp/x.py'           "$A"
deny "2 tee -a"                      "$C" 'echo x | tee -a auth/x.py'          "$A"
deny "2 tee, second file"            "$C" 'echo x | tee a auth/x.py'           "$A"
deny "2 tee, after a redirect"       "$C" 'echo x | tee >/dev/null auth/x.py'  "$A"
deny "2 sudo tee -a, exact pattern"  "$C" 'echo x | sudo tee -a scripts/x.py'  "$X"
deny "2 tee in \$( ), exact pattern" "$C" 'y=$(tee scripts/x.py)'              "$X"
deny "2 tee in \"\$( )\", exact pattern" "$C" 'y="$(tee scripts/x.py)"'      "$X"
deny "2 tee, redirect glued to the file" "$C" 'echo x | tee scripts/x.py>/dev/null' "$X"
deny "2 cp, redirect glued to the target" "$C" 'cp a scripts/x.py>&2'         "$X"
deny "2 cp, ; inside a quoted source" "$C" 'cp "a;b" auth/x.py'                 "$A"
deny "2 TEE in upper case"           "$C" 'echo x | TEE scripts/x.py'          "$X"
deny "2 Cp in mixed case"            "$C" 'Cp a auth/x.py'                     "$A"

# ---- 3. The forms the check saw before keep their deny
deny "3 > path"                      "$C" 'echo x > auth/x.py'                 "$A"
deny "3 cp a path"                   "$C" 'cp a auth/x.py'                     "$A"
deny "3 tee path"                    "$C" 'echo x | tee auth/x.py'             "$A"
deny "3 cp, then a backslash newline" "$C" "$(ml 'cp a \' 'auth/x.py')"        "$A"
deny "3 git mv, exact pattern"       "$C" "$G mv a scripts/x.py"               "$X"
deny "3 cp, target from \$( )"       "$C" 'cp a $(echo auth/x.py)'             "$A0"
deny "3 cp, quoted newline before the target" "$C" "$(ml "cp 'a" "b' auth/x.py")" "$A"
deny "3 > \$(pwd)/.env, name-only pattern" "$C" 'echo X=1 > $(pwd)/.env' "$(pm '$(pwd)/.env' '.env*')"
deny "3 > \`pwd\`/.env, name-only pattern" "$C" 'echo X=1 > `pwd`/.env' "$(pm '`pwd`/.env' '.env*')"
deny "3 cp, quoted target with > before /.." "$C" "cp a 'q>/../scripts/x.py'" "$(pm 'q>/../scripts/x.py' scripts/x.py)"
deny "3 cp, quoted target with ( before /.." "$C" "cp a '(/../scripts/x.py'"  "$(pm '(/../scripts/x.py' scripts/x.py)"
deny "3 cp, target ending in a backslash" "$C" 'cp a auth/..\' "$(pm 'auth/..\\' 'auth/**')"  # JSON doubles it
deny "3 cat > path heredoc"          "$C" "$(ml "cat > auth/x.py <<'EOF'" 'x = 1' 'EOF')" "$A"

# ---- 4. Free paths, fd duplication and lookalikes stay allowed
allow "4 >notes.md"                  "$C" 'echo x >notes.md'
allow "4 >>notes.md"                 "$C" 'echo x >>notes.md'
allow "4 >|notes.md"                 "$C" 'echo x >|notes.md'
allow "4 2>&1"                       "$C" 'echo x 2>&1'
allow "4 >&2"                        "$C" 'echo x >&2'
allow "4 2>/dev/null"                "$C" 'ls 2>/dev/null'
allow "4 >/dev/null 2>&1"            "$C" 'ls >/dev/null 2>&1'
allow "4 &>/dev/null"                "$C" 'ls &>/dev/null'
allow "4 > inside a quoted program"  "$C" "python3 -c 'print(1>0)'"
allow "4 >authx.py (prefix lookalike)" "$C" 'echo x >authx.py'
allow "4 >auth.md (name lookalike)"  "$C" 'echo x >auth.md'
allow "4 >scripts/y.py (other file)" "$C" 'echo x >scripts/y.py'
allow "4 cp a b"                     "$C" 'cp a b'
allow "4 cp -r src/ build/"          "$C" 'cp -r src/ build/'
allow "4 mv a b -f"                  "$C" 'mv a b -f'
allow "4 tee -a notes.md"            "$C" 'echo x | tee -a notes.md'
allow "4 cp, then a protected path in the next command" "$C" 'cp a b; cat auth/x.py'

# ---- 5. The REQ-5 cat heredoc allow cases, without a blank too
allow "5 cat >notes.md heredoc"      "$C" "$(ml "cat >notes.md <<'EOF'" 'x = 1' 'EOF')"
allow "5 cat > notes.md heredoc"     "$C" "$(ml "cat > notes.md <<'EOF'" 'x = 1' 'EOF')"
allow "5 cat >>notes.md, double-quoted delimiter" "$C" "$(ml 'cat >>notes.md <<"EOF"' 'x = 1' 'EOF')"
allow "5 cat with tabs"              "$C" "$(ml "$(printf "cat\t>\tnotes.md\t<<'EOF'")" 'x = 1' 'EOF')"
allow "5 cat body with -> and words after tee" "$C" "$(ml "cat >notes.py <<'EOF'" 'def f() -> int:' '    return 1  # tee -a log' 'EOF')"

# ---- 6. Outside a card worktree the check is off
allow "6 no card: >path"             "$N" 'echo x >auth/x.py'
allow "6 no card: tee -a path"       "$N" 'echo x | tee -a auth/x.py'

# ---- 7. Growth (repo hook rule): the least of 3 runs per size; t(160000) < 3 s and t(160000)/t(20000) < 20
python3 - "$S/bash_gate.py" "$C" <<'PYT' || FAIL=1
import json, subprocess, sys, time
hook, c = sys.argv[1:3]
cases = [("> then blanks", lambda k: "echo x >" + " " * k + ";"),
         ("a run of >", lambda k: "echo x " + ">" * k),
         ("> then backslash newlines", lambda k: "echo x >" + "\\\n" * k + ";"),
         ("cp then blanks", lambda k: "cp" + " " * k + ";"),
         ("cp then words", lambda k: "cp" + " a" * k),
         ("tee then options", lambda k: "echo x | tee" + " -a" * k),
         ("a run of zsh >!", lambda k: "echo x " + ">!" * k),
         ("cp then an unclosed quote", lambda k: "cp '" + "a " * k),
         ("cp then quoted words", lambda k: "cp" + " 'a'" * k),
         ("cp then an unclosed double quote", lambda k: 'cp "' + '\\"' * k)]
bad = 0
for name, make in cases:
    t = {}
    for k in (20000, 160000):
        data = json.dumps({"tool_name": "Bash", "cwd": c, "tool_input": {"command": make(k)}})
        runs = []
        for _ in range(3):
            s = time.perf_counter()
            try:
                subprocess.run([sys.executable, hook], input=data, capture_output=True, text=True, timeout=10)
            except subprocess.TimeoutExpired:
                pass
            runs.append(time.perf_counter() - s)
        t[k] = min(runs)
    ratio = t[160000] / t[20000]
    ok = t[160000] < 3 and ratio < 20
    bad |= not ok
    print(chr(0x2714 if ok else 0x2718) + " 7 growth %s: t(20000)=%.3fs t(160000)=%.3fs ratio=%.2f"
          % (name, t[20000], t[160000], ratio))
sys.exit(1 if bad else 0)
PYT
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
