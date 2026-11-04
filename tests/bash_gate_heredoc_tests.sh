#!/usr/bin/env bash
# T027 (REQ-4 bash rules, REQ-5, REQ-6; K202, K204, K205, K210): trust record rules, the one allowed `cat` heredoc and
# the repo-write message of bash_gate.py. Run: bash tests/bash_gate_heredoc_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"; N="$T/nocard"; R="$T/repo"; O="$T/other"; C="$T/card"
mkdir -p "$N" "$R" "$O" "$C/.delix" "$C/docs/delix" "$C/auth"
git -C "$R" init -q && git -C "$R" remote add origin https://github.com/tahircengiz/delixcrew.git
git -C "$O" init -q && git -C "$O" remote add origin https://example.com/o/other.git
git -C "$C" init -q; echo "docs/delix/tasks/T001-x.md" > "$C/.delix/card"
printf '{"test_command":"true","extra_checks":[],"protected_paths":["auth/**"],"test_paths":["tests/**"]}' > "$C/docs/delix/delix.json"
TRUST_DENY="delixcrew: Stop gate commands are approved only by the user from their own terminal"
REPO_DENY="delixcrew: writes to the delixcrew GitHub repository (settings, rulesets, security) run only from the user's own terminal"
TRIAGE_DENY="delixcrew: triage decisions are applied only by the user from their own terminal"
FEEDBACK_DENY="delixcrew: feedback is sent only by the user from their own terminal"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","agent_type":sys.argv[3],"cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2" "${3:-}"; }
ml(){ printf '%s\n' "$@"; }
allow(){ out=$(echo "$2" | python3 "$S/bash_gate.py"); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "✔ $1"; else echo "✘ $1 (expected allow): $out"; FAIL=1; fi; }
deny(){ out=$(echo "$2" | python3 "$S/bash_gate.py"); if echo "$out" | grep -q '"permissionDecision": "deny"' && { [ -z "${3:-}" ] || echo "$out" | grep -qF "$3"; }; then echo "✔ $1"; else echo "✘ $1 (expected deny${3:+: $3}): $out"; FAIL=1; fi; }
# REQ-4: trust rules in every session (no card; a reviewer too)
for a in "" "delixcrew:qa"; do
  deny "T027 trust.py allow ${a:-no agent}" "$(js "$N" 'python3 /x/scripts/trust.py allow' "$a")" "$TRUST_DENY"
done
deny "T027 trust.py allow, quoted \${VAR} path" "$(js "$N" 'cd /w && python3 "${CLAUDE_PLUGIN_ROOT}/scripts/trust.py" allow')" "$TRUST_DENY"
deny "T027 script + trust.py"    "$(js "$N" 'script -q /dev/null python3 scripts/trust.py')" "$TRUST_DENY"
deny "T027 expect + trust.py"    "$(js "$N" 'expect -c "spawn python3 scripts/trust.py"')" "$TRUST_DENY"
deny "T027 unbuffer + trust.py"  "$(js "$N" 'unbuffer python3 scripts/trust.py')" "$TRUST_DENY"
deny "T027 pty.spawn + trust.py" "$(js "$N" "python3 -c 'import pty; pty.spawn([\"python3\", \"scripts/trust.py\"])'")" "$TRUST_DENY"
deny "T027 pty.fork + trust.py"  "$(js "$N" "python3 -c 'import pty; pty.fork()' scripts/trust.py")" "$TRUST_DENY"
deny "T027 openpty + trust.py"   "$(js "$N" "python3 -c 'import os; os.openpty()' scripts/trust.py")" "$TRUST_DENY"
deny "T027 tmux + trust.py"      "$(js "$N" 'tmux new -d python3 scripts/trust.py')" "$TRUST_DENY"
deny "T027 screen + trust.py"    "$(js "$N" 'screen -dm python3 scripts/trust.py')" "$TRUST_DENY"
deny "T027 socat + trust.py"     "$(js "$N" 'socat - EXEC:"python3 scripts/trust.py"')" "$TRUST_DENY"
deny "T027 zpty + trust.py"      "$(js "$N" 'zpty z python3 scripts/trust.py')" "$TRUST_DENY"
deny "T027 cat > record heredoc" "$(js "$N" "$(ml "cat > /Users/u/.claude/delixcrew/trust.json <<'EOF'" '{"version": 1, "entries": []}' 'EOF')")" "$TRUST_DENY"
deny "T027 echo > record, letter case" "$(js "$N" 'echo {} > ~/.CLAUDE/DelixCrew/Trust.JSON')" "$TRUST_DENY"
deny "T027 cp onto the record"   "$(js "$N" 'cp /tmp/x.json ~/.claude/delixcrew/trust.json')" "$TRUST_DENY"
deny "T027 record named in a capture body (full text)" "$(js "$N" "$(ml "python3 \"/x/scripts/feedback.py\" add <<'EOF'" '{"title": "rm ~/.claude/delixcrew/trust.json fails"}' 'EOF')")" "$TRUST_DENY"
deny "T027 record named in a cat body (full text)" "$(js "$N" "$(ml "cat > notes.md <<'EOF'" 'see ~/.claude/delixcrew/trust.json' 'EOF')")" "$TRUST_DENY"
allow "T027 trust.py without allow or a wrapper" "$(js "$N" 'python3 scripts/trust.py --help')"
allow "T027 the delixcrew dir without trust.json" "$(js "$N" 'ls ~/.claude/delixcrew/')"
# REQ-5 (K202): exactly one `cat >|>> <path> <<'DELIM'` call → the path rules see only its first line
GHC='gh issue close 9 --repo tahircengiz/delixcrew'
for d in "$N" "$R"; do
  allow "T027 cat heredoc, gh issue close in the body [${d##*/}]" "$(js "$d" "$(ml "cat > notes.md <<'EOF'" "$GHC" 'EOF')")"
done
allow "T027 cat >> append, double-quoted delimiter" "$(js "$R" "$(ml 'cat >> notes.md <<"EOF"' "$GHC" 'EOF')")"
allow "T027 cat >path without a space"             "$(js "$R" "$(ml "cat >notes.md <<'EOF'" "$GHC" 'EOF')")"
allow "T027 cat with tabs"                         "$(js "$R" "$(ml "$(printf "cat\t>\tnotes.md\t<<'EOF'")" "$GHC" 'EOF')")"
allow "T027 cat, absolute path, long delimiter"    "$(js "$R" "$(ml "cat > /tmp/x/notes.md <<'NOTE_EOF'" "$GHC" 'NOTE_EOF')")"
allow "T027 cat body with every exempt rule's words" "$(js "$R" "$(ml "cat > notes.md <<'EOF'" \
  'python3 scripts/feedback.py send F001 --confirm abc' 'script -q /dev/null python3 scripts/triage.py apply 12' \
  'gh issue comment 9 -R tahircengiz/delixcrew -b x' 'gh label create bug' 'gh api -X POST repos/tahircengiz/delixcrew/rulesets --input r.json' \
  'python3 scripts/trust.py allow' 'tmux new -d python3 scripts/trust.py' 'EOF')")"
allow "T027 cat heredoc plus a trailing newline"   "$(js "$R" "$(ml "cat > notes.md <<'EOF'" "$GHC" 'EOF')"$'\n')"
deny "T027 chain on the delimiter line"            "$(js "$N" "$(ml "cat > notes.md <<'EOF'" 'x' 'EOF; gh issue close 9 -R tahircengiz/delixcrew')")"
deny "T027 line after the delimiter"               "$(js "$N" "$(ml "cat > notes.md <<'EOF'" 'x' 'EOF' 'gh issue close 9 -R tahircengiz/delixcrew')")"
deny "T027 delimiter line repeated in the body"    "$(js "$N" "$(ml "cat > notes.md <<'EOF'" 'x' 'EOF' 'gh issue close 9 -R tahircengiz/delixcrew' 'EOF')")"
deny "T027 delimiter line ends with \\r"           "$(js "$N" "$(ml "cat > notes.md <<'EOF'" "$GHC" "$(printf 'EOF\r')")")"
deny "T027 delimiter line ends with a space"       "$(js "$N" "$(ml "cat > notes.md <<'EOF'" "$GHC" 'EOF ')")"
deny "T027 <<- is not the allowed shape"           "$(js "$N" "$(ml "cat > notes.md <<-'EOF'" "$GHC" 'EOF')")"
deny "T027 unquoted <<EOF"                         "$(js "$N" "$(ml 'cat > notes.md <<EOF' '$(gh issue close 9 -R tahircengiz/delixcrew)' 'EOF')")"
deny "T027 path starts with -"                     "$(js "$N" "$(ml "cat > -n.md <<'EOF'" "$GHC" 'EOF')")"
deny "T027 path with \$"                           "$(js "$N" "$(ml "cat > \$HOME/n.md <<'EOF'" "$GHC" 'EOF')")"
deny "T027 path with ~"                            "$(js "$N" "$(ml "cat > ~/n.md <<'EOF'" "$GHC" 'EOF')")"
deny "T027 path under .claude/delixcrew/"          "$(js "$N" "$(ml "cat > /Users/u/.claude/delixcrew/feedback/F009.json <<'EOF'" "$GHC" 'EOF')")"
deny "T027 path under .CLAUDE/DelixCrew/ (case)"   "$(js "$N" "$(ml "cat > /Users/u/.CLAUDE/DelixCrew/triage/9.json <<'EOF'" "$GHC" 'EOF')")"
deny "T027 two words before <<"                    "$(js "$N" "$(ml "cat > a b <<'EOF'" "$GHC" 'EOF')")"
deny "T027 redirect after the heredoc operator"    "$(js "$N" "$(ml "cat <<'EOF' > notes.md" "$GHC" 'EOF')")"
deny "T027 header suffix | bash"                   "$(js "$N" "$(ml "cat > notes.md <<'EOF' | bash" "$GHC" 'EOF')")"
deny "T027 header suffix && x"                     "$(js "$N" "$(ml "cat > notes.md <<'EOF' && x" "$GHC" 'EOF')")"
deny "T027 cd x && cat heredoc"                    "$(js "$N" "$(ml "cd x && cat > notes.md <<'EOF'" "$GHC" 'EOF')")"
deny "T027 cat heredoc; echo x"                    "$(js "$N" "$(ml "cat > notes.md <<'EOF'; echo x" "$GHC" 'EOF')")"
deny "T027 two cat heredocs"                       "$(js "$N" "$(ml "cat > a.md <<'EOF'" 'x' 'EOF' "cat > b.md <<'EOF'" "$GHC" 'EOF')")"
# K204: one capture call (T024) also limits feedback (c) and triage (c)/(d) to its first line
FAH="python3 \"/x/scripts/feedback.py\" add <<'EOF'"; TRH="python3 \"/x/scripts/triage.py\" record 12 <<'EOF'"
for d in "$N" "$R"; do
  allow "T027 add body with gh issue comment delixcrew [${d##*/}]" "$(js "$d" "$(ml "$FAH" '{"title": "gh issue comment 9 -R tahircengiz/delixcrew fails"}' 'EOF')")"
  allow "T027 record body with gh issue close and gh api rulesets [${d##*/}]" "$(js "$d" "$(ml "$TRH" '{"reason": "gh issue close 9 -R tahircengiz/delixcrew; gh api -X POST repos/tahircengiz/delixcrew/rulesets"}' 'EOF')")"
done
allow "T027 add body names trust.py allow" "$(js "$N" "$(ml "$FAH" '{"title": "python3 scripts/trust.py allow asks twice"}' 'EOF')")"
# the protected-path redirect check (bash_gate.py:94) keeps the full text
deny  "T027 cat into a protected path (card worktree)"           "$(js "$C" "$(ml "cat > auth/x.py <<'EOF'" 'x = 1' 'EOF')")"
deny  "T027 protected redirect in a cat body stays full text"    "$(js "$C" "$(ml "cat > notes.md <<'EOF'" 'echo 1 > auth/y.py' 'EOF')")"
allow "T027 cat heredoc to a free path (card worktree)"          "$(js "$C" "$(ml "cat > notes.md <<'EOF'" "$GHC" 'EOF')")"
# REQ-6 (K205): a gh api write naming none of issues/labels/graphql gets REPO_DENY; the deny condition is unchanged
deny "T027 gh api POST rulesets, delixcrew in the text" "$(js "$N" 'gh api -X POST repos/tahircengiz/delixcrew/rulesets --input r.json')" "$REPO_DENY"
deny "T027 gh api PUT vulnerability-alerts"             "$(js "$N" 'gh api -X PUT repos/tahircengiz/delixcrew/vulnerability-alerts')" "$REPO_DENY"
deny "T027 gh api PATCH repo settings with -f"          "$(js "$N" 'gh api -X PATCH repos/tahircengiz/delixcrew -f private=false')" "$REPO_DENY"
deny "T027 gh api POST rulesets, delixcrew remote"      "$(js "$R" 'gh api repos/x/y/rulesets -X POST --input r.json')" "$REPO_DENY"
deny "T027 gh api labels keeps the triage message"      "$(js "$N" 'gh api -X POST repos/tahircengiz/delixcrew/labels -f name=x')" "$TRIAGE_DENY"
deny "T027 gh api graphql keeps the triage message"     "$(js "$R" "gh api graphql -f query='mutation{x}'")" "$TRIAGE_DENY"
deny "T027 gh label and gh api rulesets: triage message" "$(js "$R" 'gh label create x && gh api -X POST repos/x/y/rulesets')" "$TRIAGE_DENY"
deny "T027 gh api issues keeps the feedback message"    "$(js "$N" 'gh api -X PATCH repos/tahircengiz/delixcrew/issues/1 -f state=closed')" "$FEEDBACK_DENY"
allow "T027 gh api GET rulesets"                        "$(js "$R" 'gh api repos/tahircengiz/delixcrew/rulesets')"
allow "T027 gh api POST rulesets, other repo"           "$(js "$O" 'gh api -X POST repos/o/other/rulesets --input r.json')"
# REQ-5 timing: hook time per probe minus hook time for `ls`, best of 3 each, < 0.05 s; ×8 path probes show growth
python3 - "$T" "$N" <<'PY'
import json, sys
t, n = sys.argv[1], sys.argv[2]
gh = "gh issue close 9 --repo tahircengiz/delixcrew "
probes = {
    "body": "cat > notes.md <<'EOF'\n" + (gh * 4 + "\n") * 1100 + "EOF",
    "delim": "cat > notes.md <<'EOF'\n" + "EOF\n" * 5000 + "EOF",
    "path": "cat > " + "/" * 20000 + "x <<'EOF'\nx\nEOF",
    "path8": "cat > " + "/" * 160000 + "x <<'EOF'\nx\nEOF",
    "miss": "cat > " + "/" * 20000 + "x<<'EOF'\nx\nEOF",
    "miss8": "cat > " + "/" * 160000 + "x<<'EOF'\nx\nEOF",
}
for k, c in probes.items():
    with open(f"{t}/probe-{k}.json", "w") as f:
        json.dump({"tool_name": "Bash", "cwd": n, "tool_input": {"command": c}}, f)
PY
rtime(){ # name, probe json file
  d=$(python3 - "$S/bash_gate.py" "$(js "$N" ls)" "$2" <<'PYT'
import subprocess, sys, time
def best(data):
    ts = []
    for _ in range(3):
        t = time.monotonic()
        subprocess.run([sys.executable, sys.argv[1]], input=data, capture_output=True, text=True, timeout=5)
        ts.append(time.monotonic() - t)
    return min(ts)
base = best(sys.argv[2])
d = best(open(sys.argv[3]).read()) - base
print(f"{d:.3f}")
sys.exit(0 if d < 0.05 else 1)
PYT
  ) && echo "✔ $1 (Δ $d s)" || { echo "✘ $1 (Δ ${d:-timeout} s, expected < 0.05)"; FAIL=1; }; }
rtime "T027 ReDoS: 200 KB cat body"                "$T/probe-body.json"
rtime "T027 ReDoS: 5k delimiter lines"             "$T/probe-delim.json"
rtime "T027 ReDoS: 20k / in the path"              "$T/probe-path.json"
rtime "T027 ReDoS: 160k / in the path"             "$T/probe-path8.json"
rtime "T027 ReDoS: 20k / path, no space before <<" "$T/probe-miss.json"
rtime "T027 ReDoS: 160k / path, no space before <<" "$T/probe-miss8.json"
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
