# T027 — 🔐 bash_gate: trust record rules, the one allowed `cat` heredoc, the repo-write message

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T027 | M | 3 | backend | 1 | open |

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path. REQ-5 changes which heredoc bodies the gh and publish rules skip, and REQ-4 adds the agent-side guard for the Stop gate approval (SPEC §6). The lead adds the Approved line after the user's explicit yes in chat and commits it to main before dispatch.

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** bash_gate gets three changes:
- In every session it denies `trust.py` + `allow`, `trust.py` under a terminal wrapper, and any command naming `delixcrew/trust.json` (full text).
- Exactly one `cat >|>> <path> <<'DELIM'` call, like one T024 capture call, limits every other path rule to its first line (feedback (c) and triage (c)/(d) included, K204).
- A `gh api` write that names none of issues/labels/graphql gets `REPO_DENY`.

The rest of bash_gate is unchanged. · **Spec:** `docs/delix/SPEC.md#REQ-4` (bash part), `#REQ-5`, `#REQ-6`; §4, §6, §8; K202, K204, K205, K210, K211b

**Docs/site:** none in this card. T028 updates README, skills, CHANGELOG and site (REQ-7).

## Files
- Modify: `scripts/bash_gate.py` (insert after lines 31, 51 and 71; lines 32 to 34, 39 to 41, 52 to 53, 61 to 65 and 71 change)
- Test: `tests/bash_gate_heredoc_tests.sh` (new file)

## Edit anchors (base origin/main 63e8440; match the content, not only the number)
1. Insert after line 31 (`r"([A-Za-z_][\w.-]*)\2)\n(.*)\n\3", re.S)`, end of `RECORD_HEREDOC`):
```python
# REQ-5 (K202, K211b): exactly one `cat >|>> <path> <<'DELIM'` call. The path is one repeated class (the _PATH
# exclusions, no optional directory group: ReDoS); `<<-` and an unquoted delimiter do not match. Group numbers match
# ADD_HEREDOC (1 header, 2 quote, 3 delimiter, 4 body). Matched against the raw command with only trailing newlines
# removed, so a delimiter line ending in `\r` or a space never matches (fail closed).
_CPATH = r"(?!-)[^\s'\"$`\\;&|<>(){}#*?\[\]~^]+"
CAT_HEREDOC = re.compile(r"(cat[ \t]+>>?[ \t]*" + _CPATH + r"[ \t]+<<(['\"])([A-Za-z_][\w.-]*)\2)\n(.*)\n\3", re.S)
```
2. Lines 32–33 (the `# REQ-3 (#36, K182, K187): …` comment) become:
```python
# REQ-3 (#36, K182, K187): no path starts with `-` (`python3 -ic<dir>/feedback.py` runs the body as code).
# REQ-5 (K202, K204): one match of ADD_HEREDOC, RECORD_HEREDOC or CAT_HEREDOC without an early delimiter limits
# every rule below to its first line, except trust (c) and the protected-path redirect check (full text).
```
3. Line 34 (`m = ADD_HEREDOC.fullmatch(cmd.strip()) or RECORD_HEREDOC.fullmatch(cmd.strip())`) becomes:
```python
_raw = (g.get("tool_input") or {}).get("command") or ""
cm = CAT_HEREDOC.fullmatch(_raw.rstrip("\n"))
if cm and ".claude/delixcrew/" in cm.group(1).casefold():
    cm = None  # REQ-5: a path into the plugin's own record dirs gets no exemption (the delimiter cannot hold `/`)
m = ADD_HEREDOC.fullmatch(cmd.strip()) or RECORD_HEREDOC.fullmatch(cmd.strip()) or cm
```
   Line 35 (`checked = …`) and lines 36–38 stay byte-identical.
4. Lines 39–41: replace `cmd` with `checked` in the three places: the `gh issue (create|new|comment|edit)` search, the `gh api` search with its `issues` search, and `"delixcrew" in cmd.lower()` → `"delixcrew" in checked.lower()`. Lines 42–48 stay unchanged.
5. Insert after line 51 (`TRIAGE_DENY = …`): `REPO_DENY = "delixcrew: writes to the delixcrew GitHub repository (settings, rulesets, security) run only from the user's own terminal"`
6. Lines 52–53 become `# (a)-(d) see `checked` from the feedback block: the first line of one allowed heredoc call (ADD_HEREDOC,` / `# RECORD_HEREDOC or CAT_HEREDOC, K204), otherwise the full text.`
7. Lines 61–65 become:
```python
gh_c = re.search(r"\bgh\s+issue\s+(close|reopen|lock|unlock|delete|transfer|pin|unpin|develop)\b|\bgh\s+label\b", checked)
if gh_c or (re.search(r"\bgh\s+api\b", checked) and (GH_API_WRITE.search(checked)
                                                  or any(v.upper() != "GET" for v in GH_API_METHOD.findall(checked)))):
    # REQ-6 (K205): same deny condition; a gh api write naming none of issues/labels/graphql is a repo settings write
    msg = TRIAGE_DENY if gh_c or re.search(r"\b(?:issues|labels|graphql)\b", checked) else REPO_DENY
    if "delixcrew" in checked.lower():
        deny(msg)
```
   Lines 66–70 stay unchanged, and line 71 `deny(TRIAGE_DENY)` → `deny(msg)`.
8. Insert after line 71, before line 73 `GIT = …`:
```python

# REQ-4 (K200, K210): the Stop gate approval, in every session, unconditional (like feedback (a)/(b)).
# (a) and (b) see `checked`; (c) sees the full text, so no heredoc exemption reaches it.
TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"
if (re.search(r"\btrust\.py\b", checked) and (re.search(r"\ballow\b", checked) or re.search(
        r"\b(?:script|expect|unbuffer|openpty|tmux|screen|socat|zpty)\b|\bpty\.(?:spawn|fork)\b", checked))) \
        or "delixcrew/trust.json" in cmd.casefold():
    deny(TRUST_DENY)
```
   Everything from line 73 on (reviewer block, card check, protected-path redirect check at `:94`, gitleaks) stays byte-identical.

## Interfaces
- Produced:
  - `TRUST_DENY` and `REPO_DENY`, literal in `bash_gate.py` (K210; write_gate gets its own literal in T026);
  - `CAT_HEREDOC` with the same group layout as `ADD_HEREDOC`/`RECORD_HEREDOC`.
- Card decision (K204, "tek ve tutarlı"): trust (a)/(b) also see `checked`. A feedback or record draft that names `trust.py allow` is allowed; its body is stdin data, not code.
- Unchanged: `FEEDBACK_DENY`, `TRIAGE_DENY`, `ADD_HEREDOC`, `RECORD_HEREDOC`, `_QPATH`/`_PATH`/`_TQPATH`/`_TPATH`, `GH_API_WRITE`, `GH_API_METHOD`, `GIT`, `WRITING`, the reviewer block, the redirect check, gitleaks; `tests/hook_tests.sh` passes unedited.
- Consumed: nothing from T026 (no shared file).

## Global Constraints (verbatim from the spec)
- REQ-4: "`bash_gate.py`: şu üç komutu reddeder; kurallar koşulsuzdur, feedback (a)/(b) gibi: (a) `trust.py` + `allow` geçen komut; (b) `trust.py` ile `script|expect|unbuffer|pty.spawn|pty.fork|openpty|tmux|screen|socat|zpty` birlikte geçen komut; (c) casefold edilmiş metninde `delixcrew/trust.json` geçen komut. (c) tam metne uygulanır, REQ-5 ve capture muafiyetleri ona dokunmaz." · `TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"`.
- REQ-5: "biçim: `cat[ \t]+>>?[ \t]*<yol>[ \t]+<<'DELIM'` (ya da `"DELIM"`), ardından gövde, son satır `DELIM`; kapsanan kurallar: feedback (a)/(b)/(c), triage (a)/(b)/(c)/(d), trust (a)/(b). Trust (c) tam metinde kalır." · "`<yol>` tek karakter sınıfıdır: `(?!-)[^X]+`; `X` = `_PATH`'in dışlanan karakterleri. İsteğe bağlı dizin grubu yoktur (ReDoS, K211b). `<<-` desteklenmez. `<yol>` casefold edildiğinde `.claude/delixcrew/` içeriyorsa muafiyet uygulanmaz. Gövdede `DELIM` satırı tekrar ederse, delimiter satırı `\r` ya da sondaki boşlukla bitiyorsa ya da biçim tutmazsa tam metin kontrol edilir (fail closed)."
- K204: "capture eşleşmesinde feedback (c) ile triage (c)/(d) de yalnız ilk satıra bakar. Korunan yola shell yazımı kontrolü (`bash_gate.py:94`) tam metinde kalır."
- REQ-6/K205: "`gh api` yazma çağrısında bugünkü deny koşulu aynen kalır. Değişen yalnız mesajdır … `issues`, `labels` ve `graphql` kelimelerinden hiçbiri yoksa … `REPO_DENY` … Issues, labels ve graphql yolları bugünkü mesajlarını korur; mevcut test satırları değişmez." Card decision: when rule (c) itself matches (`gh issue close…`, `gh label`), the message stays `TRIAGE_DENY`.
- Timing (REQ-5 scenario): "200 KB gövde, 5k `EOF` satırı, 20k `/` içeren yol → her biri < 0.05 sn". Measured as Δ against `ls`, best of 3. ×8 path probes are added so that a superlinear pattern shows.
- Stdlib only. Write a tab as `printf '\t'` and a CR as `printf 'EOF\r'` (escape sequences, never raw characters).

## Steps
1. **Failing tests first.** Create `tests/bash_gate_heredoc_tests.sh` with the Write tool, with exactly this content:
```bash
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
```
   Run `bash tests/bash_gate_heredoc_tests.sh` and see **red**. Expected ✘ lines on the unchanged gate:
   - every `TRUST_DENY` line;
   - every REQ-5 `allow`;
   - the four K204 capture allows;
   - `cat heredoc to a free path (card worktree)`;
   - the four `REPO_DENY` lines.

   Report the ✘ names.
2. **Implement** edits 1–8. Touch only the paths in Files.
3. **Green:** the new file, `bash tests/hook_tests.sh` (unedited, must stay `ALL PASSED`), the full loop, `claude plugin validate .`. If an existing line goes ✘, do not edit it: `NEEDS_CONTEXT` with the output.
4. **Live check (SPEC §8)**, in your real session, with harmless text only. Run `cat > .delix/live-heredoc.txt <<'EOF'` with the body line `$(echo expanded) and backticks` and the line `EOF`, then `cat .delix/live-heredoc.txt`. Expect the body literally, nothing expanded. Then run the same shape with an extra line `echo after-delimiter` after `EOF`; expect `after-delimiter` printed, because that line runs as a command. Paste both outputs in the report.
5. **Commit** `T027: bash_gate trust rules, one allowed cat heredoc, repo-write message`. Open the PR with `--body-file`. `## How I tested` lists the commands, the ✔/✘ counts, the step 1 ✘ names, all six `ReDoS:` Δ values and the live check output.

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0; `claude plugin validate .` → passes
- `bash tests/bash_gate_heredoc_tests.sh | grep -c '^✔ T027'` → `71`; `… | grep -c '^✘'` → `0`; last line `ALL PASSED`
- `bash tests/bash_gate_heredoc_tests.sh | grep '^✔ T027 ReDoS'` → 6 lines, each Δ < 0.05 s
- `git diff --stat origin/main -- tests/hook_tests.sh` → no output
- `grep -cF 'TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"' scripts/bash_gate.py` → `1`; the same for the `REPO_DENY = "…"` text → `1`
- `git diff -U0 origin/main -- scripts/bash_gate.py | grep -E '^-.*(FEEDBACK_DENY =|TRIAGE_DENY =|_QPATH =|_PATH =|ADD_HEREDOC =|GH_API_WRITE =|WRITING =|finditer)'` → no output
- `git diff --stat origin/main` → only the 2 files in Files

## Review Focus
- `CAT_HEREDOC` keeps groups 1–4 in the same roles as the capture patterns, so line 35 serves all three. `_CPATH`'s class is byte-identical to `_PATH`'s, and the only addition is `+` after it. Check with `git diff --color-moved=zebra`.
- The cat match uses the raw command minus trailing `\n` only. `cmd` (stripped) stays the fallback text and the input to the capture patterns. Tests: `\r` and trailing space on the delimiter line.
- Trust (c) and the redirect check read `cmd`. Everything else reads `checked`, including both `"delixcrew" in … .lower()` checks.
- REQ-6: `msg` is chosen once and used for both deny calls (text and remote). When rule (c) matches, the message stays `TRIAGE_DENY`.
- Card decision: trust (a)/(b) reading `checked` for capture bodies too (K204 consistency). Test: `add body names trust.py allow`.
- Inputs the spec implies but the tests do not cover:
  - `cat > a//.claude/delixcrew/x` or `/./` gets past the substring check and only gains the body exemption. Writing that directory through Bash was never blocked; this is denylist friction (K77, §6).
  - `cat >> notes.md <<"EOF"` with CRLF body lines.
  - A NUL in the command.
- Not a target:
  - K212 for bash_gate's own `git remote -v` calls (`:44`, `:67`); REQ-1 scopes K212 to the trust and `card_path` calls;
  - new heredoc shapes (§2);
  - `DELIXCREW_*_DIR` overrides (§8).

## Don'ts
- Do not touch anything outside the 2 files, in particular:
  - `scripts/common.py`, `scripts/stop_gate.py`, `scripts/write_gate.py`, `scripts/trust.py`, `tests/hook_tests.sh`, `tests/trust_tests.sh`, which are T026's;
  - `hooks/hooks.json`, `docs/delix/**`, `README*`, `skills/**`, `site/**`, `CHANGELOG.md`.
- Do not change `FEEDBACK_DENY` or `TRIAGE_DENY`, the order of the feedback, triage and protected-path blocks, the reviewer block, the redirect check or gitleaks.
- Add no regex beyond `CAT_HEREDOC`, the trust searches, `gh_c` and the REQ-6 word search. Add no exemption for `<<-`, unquoted delimiters, `cd … &&`, `; echo`, `${…}` or a second command.
- Do not run ad-hoc Bash commands with the gates' trigger words (`trust.py allow`, `delixcrew/trust.json`, `gh issue close … delixcrew`). Exercise the gate only through the test files. Write test files with the Write tool, never `cat > … <<'EOF'` through Bash.

## Report contract
`.delix/report.md` (≤ 1.5K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output: ✔/✘ counts, the step 1 ✘ names, the six ReDoS Δ and the live check output;
- the PR number;
- assumptions.

Read only this card and SPEC REQ-4–REQ-6, §4, §6, §8 and §9.

## Review findings (filled by the lead)
- Round 0 (d81c27a, PR #56): deterministic gates green.
  - CI `test` and `check` pass.
  - The lead re-ran all suites from `git archive d81c27a`: 10/10 pass. The merge tree with T026 passes 10/10, and also under Python 3.13.
  - The internal-host scan finds 0.
  - qa: ACCEPT (0 P0, 0 P1).
  - security: 🔐 HUMAN_APPROVAL, with no Critical, High or Medium finding. gitleaks reports none.
- [Low, docs, T028] Trust (c) is a substring rule. These forms of the path get past it: `cd` and then a relative path, `//`, `/./`, and a symlinked directory. They go to Known limits (K220). No code change.
- The lead probed the "unsure" cases on d81c27a:
  - a CRLF delimiter is denied (fail closed);
  - a NUL in the path or the body is allowed, but the body is a quoted heredoc fed to `cat`, so it is data only.
- Merge order: T027 first, then T026 (K222).

