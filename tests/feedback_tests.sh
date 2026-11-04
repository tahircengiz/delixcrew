#!/usr/bin/env bash
# Deterministic tests for scripts/feedback.py (self-feeding feedback CLI). Run: bash tests/feedback_tests.sh
# No network, no real gh: gitleaks, gh and claude are stubs on PATH.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"; S="$ROOT/scripts"; FAIL=0
T="$(cd "$(mktemp -d)" && pwd -P)"
export DELIXCREW_FEEDBACK_DIR="$T/q" HOME="$T/home" USER="alice-test" FBT="$T"
export GH_HOST="evil.example.com" GH_REPO="evil/fork" GH_ENTERPRISE_TOKEN="x" GITHUB_ENTERPRISE_TOKEN="x"
Q="$DELIXCREW_FEEDBACK_DIR"; mkdir -p "$HOME" "$T/stub"
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
fb(){ python3 "$S/feedback.py" "$@"; }
jq_(){ python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2],{},{"d":d}))' "$1" "$2"; }
mk(){ python3 -c 'import json,sys; d=json.loads(sys.argv[1]); exec(sys.argv[2]); print(json.dumps(d))' "$1" "$2"; }
nfiles(){ ls "$Q" 2>/dev/null | grep -c '^F[0-9]*\.json$'; }
hash_of(){ printf '%s\n' "$1" | sed -n 's/^HASH: //p'; }
# TTY: input arrives on a pty; stdin is held open briefly so macOS script does not send EOF first.
tty_run(){ local input="$1"; shift
  if script --version >/dev/null 2>&1; then { printf '%s\n' "$input"; sleep 1; } | script -qec "$(printf '%q ' "$@")" /dev/null
  else { printf '%s\n' "$input"; sleep 1; } | script -q /dev/null "$@"; fi; }

# --- stubs -------------------------------------------------------------------
cat > "$T/stub/gitleaks" <<'SH'
#!/bin/sh
echo "$*" >> "$FBT/gl.log"
in=$(cat)
[ -n "${GL_RC:-}" ] && exit "$GL_RC"
case "$in" in *FAKE_SECRET_MARKER*) echo "RuleID:      generic-api-key"; exit 2;; esac
exit 0
SH
cat > "$T/stub/gh" <<'SH'
#!/bin/sh
{ echo "ARGS: $*"; env | grep -E 'GH_|GITHUB_'; } >> "$FBT/gh.log"
[ "${GH_MODE:-}" = fail ] && { echo "gh: authentication required" >&2; exit 1; }
case "$*" in
  *"issue list"*)
    if [ "${GH_MODE:-}" = found ]; then
      fp=$(for a in "$@"; do echo "$a"; done | sed -n 's/^delixcrew-fp: //p' | head -1)
      printf '[{"url":"https://github.com/tahircengiz/delixcrew/issues/41","body":"x\\ndelixcrew-fp: %s0"},' "$fp"
      printf '{"url":"https://github.com/tahircengiz/delixcrew/issues/42","body":"x\\n\\ndelixcrew-fp: %s"}]\n' "$fp"
    else echo '[]'; fi; exit 0;;
  *"issue create"*)
    prev=""; for a in "$@"; do [ "$prev" = "--body-file" ] && cp "$a" "$FBT/gh_body.txt"; prev="$a"; done
    echo "https://github.com/tahircengiz/delixcrew/issues/99"; exit 0;;
esac
exit 1
SH
printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$T/stub/claude"
chmod +x "$T/stub/"*; export PATH="$T/stub:$PATH"

# Two "projects": A has a git remote on an internal-looking host, B is a plain dir.
A="$T/acme-widgets"; B="$T/beta-tools"; mkdir -p "$A" "$B"
git -C "$A" init -q; git -C "$A" remote add origin git@git.example-corp.dev:widgetco/acme-widgets.git
git -C "$A" remote add up https://github.com/tahircengiz/delixcrew.git

J1='{"kind":"bug","component":"feedback","title":"Preview hangs on large queue","actual":"It hangs.","expected":"It returns.","repro":["run preview"]}'

# --- REQ-1 opt-in ------------------------------------------------------------
(cd "$A" && echo "$J1" | fb add) >"$T/out" 2>"$T/err"; rc=$?
[ $rc -eq 3 ] && [ "$(cat "$T/err")" = "delixcrew feedback is off; enable: python3 $S/feedback.py enable" ] && [ "$(nfiles)" -eq 0 ] \
  && ok "REQ-1 add while off: exit 3, exact message, no file" || bad "REQ-1 add while off (rc=$rc, err=$(cat "$T/err"))"
fb enable --terms acme,zz >/dev/null; st=$(fb status)
[ "$(jq_ "$Q/config.json" 'd=={"enabled":True,"extra_terms":["acme","zz"]}')" = True ] && echo "$st" | grep -q "enabled: yes" \
  && echo "$st" | grep -qF "queue: $Q" && echo "$st" | grep -q "drafts: 0" && ok "REQ-1 enable --terms + status" || bad "REQ-1 enable/status ($st)"
fb disable >/dev/null; st=$(fb status)
[ "$(jq_ "$Q/config.json" 'd["enabled"] is False and d["extra_terms"]==["acme","zz"]')" = True ] && echo "$st" | grep -q "enabled: no" \
  && ok "REQ-1 disable keeps terms" || bad "REQ-1 disable ($st)"
(cd "$A" && echo "$J1" | fb add) >/dev/null 2>&1; [ $? -eq 3 ] && ok "REQ-1 add after disable: exit 3" || bad "REQ-1 add after disable"
fb enable >/dev/null
[ "$(jq_ "$Q/config.json" 'd=={"enabled":True,"extra_terms":["acme","zz"]}')" = True ] && ok "REQ-1 enable without --terms keeps terms" || bad "REQ-1 re-enable"

# --- REQ-2 capture and dedup -------------------------------------------------
out=$(cd "$A" && echo "$J1" | fb add)
PV=$(jq_ "$ROOT/.claude-plugin/plugin.json" 'd["version"]')
[ "$out" = "F001 new" ] && [ "$(jq_ "$Q/F001.json" "d['status']=='draft' and d['count']==1 and len(d['fingerprint'])==16 and all(c in '0123456789abcdef' for c in d['fingerprint']) and bool(d['first_seen']) and bool(d['last_seen']) and d['plugin_version']=='$PV' and d['claude_version']=='9.9.9' and bool(d['os']) and d['id']=='F001' and d['issue_url'] is None")" = True ] \
  && ok "REQ-2 new draft: F001 new + record fields" || bad "REQ-2 new draft ($out)"
[ "$(jq_ "$Q/F001.json" "set(['acme-widgets','git.example-corp.dev','widgetco']) <= set(d['origin_terms']) and not (set(['delixcrew','delix','tahircengiz/delixcrew','github.com']) & set(d['origin_terms']))")" = True ] \
  && ok "REQ-2 origin_terms: cwd + remote parts, plugin names and allowlisted hosts left out" || bad "REQ-2 origin_terms ($(jq_ "$Q/F001.json" "d['origin_terms']"))"
out=$(cd "$B" && mk "$J1" 'd["title"]="preview HANGS on large queue!! 2"' | fb add)
[ "$out" = "F001 duplicate (count 2, draft)" ] && [ "$(nfiles)" -eq 1 ] && [ "$(jq_ "$Q/F001.json" "d['count']==2 and set(['acme-widgets','beta-tools']) <= set(d['origin_terms'])")" = True ] \
  && ok "REQ-2 duplicate: count+1, origin_terms merged, no new file" || bad "REQ-2 duplicate ($out)"
out=$(fb drop F001); [ "$(jq_ "$Q/F001.json" "d['status']")" = dropped ] && [ -f "$Q/F001.json" ] && ok "drop: status dropped, file kept" || bad "drop ($out)"
out=$(cd "$A" && echo "$J1" | fb add)
[ "$out" = "F001 duplicate (count 3, dropped)" ] && [ "$(jq_ "$Q/F001.json" "d['status']")" = dropped ] && ok "REQ-2 duplicate of dropped stays dropped" || bad "REQ-2 dropped revived ($out)"
schema(){ # name, python mutation, field expected in stderr
  out=$(cd "$A" && mk "$J1" "$2" | fb add 2>&1); rc=$?
  [ $rc -eq 2 ] && echo "$out" | grep -q "$3" && [ "$(nfiles)" -eq 1 ] && ok "REQ-2 schema: $1 → exit 2 ($3)" || bad "REQ-2 schema: $1 (rc=$rc, $out)"; }
schema "unknown field"     'd["severity"]="high"'        severity
schema "missing title"     'del d["title"]'              title
schema "title > 120"       'd["title"]="t"*121'          title
schema "repro > 10 steps"  'd["repro"]=["s"]*11'         repro
schema "actual > 2000"     'd["actual"]="a "*1001'       actual
schema "bad kind"          'd["kind"]="question"'        kind
out=$(echo '{not json' | fb add 2>&1); [ $? -eq 2 ] && [ "$(nfiles)" -eq 1 ] && ok "REQ-2 schema: invalid JSON → exit 2" || bad "REQ-2 invalid JSON ($out)"

# --- REQ-3 sanitizing --------------------------------------------------------
J2=$(python3 - <<'PY'
import json
print(json.dumps({"kind":"feature","component":"feedback","title":"Leak check for build.example-corp.dev",
 "actual":"Fails at 10.1.2.3 and build.example-corp.dev, see /Users/alice/x and /srv/app in acme-widgets; ACME too; mail bob@example-corp.dev; user alice-test; mac 00:1a:2b:3c:4d:5e; v6 fd00:1234::5.",
 "expected":"Paths skills/feedback/SKILL.md, scripts/bash_gate.py, feedback.py, plugin.json and github.com/tahircengiz/delixcrew stay; cache ~/.claude/plugins/cache/delixcrew/delixcrew/0.5.0/skills/x stays; fizzbuzz stays.",
 "repro":["open the widgetco dashboard","run /delixcrew:feedback review"],
 "context":"docs at docs.example.com, doc range 192.0.2.10, loopback 127.0.0.1"}))
PY
)
out=$(cd "$A" && echo "$J2" | fb add); [ "$out" = "F002 new" ] && ok "REQ-3 setup: F002 new" || bad "REQ-3 setup ($out)"
pv=$(cd "$B" && fb preview F002); rc=$?
leaks=""; for s in 10.1.2.3 example-corp /Users/alice /srv/app acme-widgets ACME alice-test bob@ 00:1a:2b fd00:1234 widgetco; do echo "$pv" | grep -qF "$s" && leaks="$leaks $s"; done
[ $rc -eq 0 ] && [ -z "$leaks" ] && ok "REQ-3 internal address, IP, paths, email, MAC, user, project names gone (preview from B)" || bad "REQ-3 leaks:$leaks (rc=$rc)"
kept=""; for s in skills/feedback/SKILL.md scripts/bash_gate.py feedback.py plugin.json github.com/tahircengiz/delixcrew "~/x" docs.example.com 192.0.2.10 127.0.0.1 /delixcrew:feedback; do echo "$pv" | grep -qF -- "$s" || kept="$kept $s"; done
[ -z "$kept" ] && ok "REQ-3 plugin paths, file names, github URL, home-relative path, allowlisted host/IP kept" || bad "REQ-3 wrongly redacted:$kept"
echo "$pv" | grep -qF "~/.claude/plugins/cache/delixcrew/delixcrew/0.5.0/skills/x" && echo "$pv" | grep -q "^VERDICT: CLEAN" \
  && ok "K81 plugin cache path kept and not BLOCKED" || bad "K81 plugin cache path"
echo "$pv" | grep -q fizzbuzz && ok "K82 2-char extra term ignored" || bad "K82 short term applied"
echo "$pv" | grep -q "^TITLE: Leak check for <redacted:host>" && echo "$pv" | grep -q "^REPO: tahircengiz/delixcrew" && echo "$pv" | grep -q "^LABEL: enhancement" \
  && echo "$pv" | grep -qE "^HASH: [0-9a-f]{12}$" && echo "$pv" | grep -q "^---$" && ok "REQ-5 preview layout: VERDICT HASH REPO LABEL TITLE --- body" || bad "REQ-5 preview layout"
echo "$pv" | grep -q "^### Steps to reproduce" && [ "$(echo "$pv" | tail -1)" = "delixcrew-fp: $(jq_ "$Q/F002.json" "d['fingerprint']")" ] \
  && ok "body headings, last line delixcrew-fp" || bad "body headings / fp line"
lst=$(fb list); echo "$lst" | head -1 | grep -qE "^id +kind +component +count +status +title" && echo "$lst" | grep -qE "^F002 +feature +feedback +1 +draft" \
  && ok "list table" || bad "list table ($lst)"

# --- REQ-4 fail-closed -------------------------------------------------------
out=$(cd "$A" && mk "$J1" 'd["title"]="Secret in context"; d["context"]="key FAKE_SECRET_MARKER here"' | fb add); id=${out%% *}
: > "$T/gl.log"; pv=$(fb preview "$id" 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: gitleaks (rule generic-api-key)" && ! echo "$pv" | grep -q FAKE_SECRET_MARKER \
  && ok "REQ-4 secret: BLOCKED with rule id, key not printed" || bad "REQ-4 secret (rc=$rc, $pv)"
[ "$(grep -c 'stdin' "$T/gl.log")" -ge 2 ] && grep -q -- "--redact" "$T/gl.log" && grep -q -- "--exit-code 2" "$T/gl.log" \
  && ok "REQ-4 gitleaks run on raw and sanitized text" || bad "REQ-4 gitleaks calls ($(cat "$T/gl.log"))"
out=$(fb send "$id" --confirm 000000000000 </dev/null 2>&1); rc=$?
[ $rc -eq 4 ] && ! echo "$out" | grep -q FAKE_SECRET_MARKER && ok "REQ-4 send of secret: exit 4" || bad "REQ-4 send secret (rc=$rc)"
mkdir -p "$T/minpath"; for b in python3 git script; do ln -s "$(command -v "$b")" "$T/minpath/$b"; done
ln -sf "$(python3 -c 'import sys,os; print(os.path.realpath(sys.executable))')" "$T/minpath/python3"
pv=$(PATH="$T/minpath" python3 "$S/feedback.py" preview F002 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: gitleaks not found" && ok "REQ-4 gitleaks not on PATH: BLOCKED" || bad "REQ-4 no gitleaks (rc=$rc, $pv)"
out=$(PATH="$T/minpath" python3 "$S/feedback.py" send F002 --confirm 000000000000 </dev/null 2>&1); [ $? -eq 4 ] && ok "REQ-4 send without gitleaks: exit 4" || bad "REQ-4 send no gitleaks ($out)"
pv=$(GL_RC=1 fb preview F002 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: gitleaks failed (rc 1)" && ok "REQ-4 gitleaks rc 1: BLOCKED" || bad "REQ-4 gitleaks failed (rc=$rc, $pv)"
blocked(){ # name, python mutation, reason regex
  out=$(cd "$A" && mk "$J1" "$2" | fb add); pv=$(fb preview "${out%% *}" 2>&1); rc=$?
  [ $rc -eq 4 ] && echo "$pv" | grep -qE "^VERDICT: BLOCKED: .*$3" && ok "REQ-4 $1: BLOCKED" || bad "REQ-4 $1 (rc=$rc, $(echo "$pv" | head -1))"; }
blocked "zero-width char"     'd["title"]="Zero width"; d["actual"]="a​b"'                          'unicode'
blocked "bidi control"        'd["title"]="Bidi"; d["actual"]="a‮b"'                                'unicode'
blocked "opaque 32+ string"   'd["title"]="Opaque"; d["actual"]="token "+"Ab1"*14'                       'opaque'
blocked "full git SHA"        'd["title"]="Full sha"; d["actual"]="commit "+"0123456789abcdef"*2+"01234567"' 'opaque'
blocked "> 15 code lines"     'd["title"]="Code"; d["actual"]="```\n"+"\n".join("x = %d" % i for i in range(16))+"\n```"' 'code lines'
blocked "body > 8 KB"         'd["title"]="Big"; d["repro"]=["lorem ipsum dolor "*50]*10'               '8 KB'
out=$(cd "$A" && mk "$J1" 'd["title"]="Code ok"; d["actual"]="```\n"+"\n".join("x = %d" % i for i in range(15))+"\n```"' | fb add)
fb preview "${out%% *}" >/dev/null 2>&1 && ok "REQ-4 15 code lines still CLEAN" || bad "REQ-4 15 code lines blocked"

# --- REQ-5 hash binding ------------------------------------------------------
H=$(hash_of "$(cd "$B" && fb preview F002)")
fb enable --terms acme,zz,dashboard >/dev/null
out=$(fb send F002 --confirm "$H" </dev/null 2>&1); rc=$?
[ $rc -eq 5 ] && echo "$out" | grep -qF "content changed since preview; run preview again" && ok "REQ-5 extra_terms changed: exit 5" || bad "REQ-5 extra_terms (rc=$rc, $out)"
fb enable --terms acme,zz >/dev/null
[ "$(hash_of "$(fb preview F002)")" = "$H" ] && ok "REQ-5 hash is deterministic (independent of cwd)" || bad "REQ-5 hash not stable"
cp "$Q/F002.json" "$T/F002.bak"; python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["expected"]+=" more"; json.dump(d,open(p,"w"))' "$Q/F002.json"
out=$(fb send F002 --confirm "$H" </dev/null 2>&1); [ $? -eq 5 ] && ok "REQ-5 draft changed: exit 5" || bad "REQ-5 draft changed ($out)"
cp "$T/F002.bak" "$Q/F002.json"
mkdir -p "$T/fizzbuzz"; (cd "$T/fizzbuzz" && mk "$J1" 'd["title"]="Other project"' | fb add) >/dev/null
out=$(fb send F002 --confirm "$H" </dev/null 2>&1); [ $? -eq 5 ] && ok "REQ-5 another record's origin_terms changed: exit 5" || bad "REQ-5 origin_terms changed ($out)"
pv=$(fb preview F002); echo "$pv" | grep -q fizzbuzz && bad "REQ-3 union of all records' origin_terms not applied" || ok "REQ-3 union of all records' origin_terms applied"
H=$(hash_of "$pv")

# --- REQ-6 terminal only -----------------------------------------------------
: > "$T/gh.log"
out=$(echo "SEND $H" | fb send F002 --confirm "$H" 2>&1); rc=$?
[ $rc -eq 6 ] && ! grep -q "issue" "$T/gh.log" && ok "REQ-6 no TTY (pipe): exit 6, gh not called" || bad "REQ-6 no TTY (rc=$rc, $out)"
out=$(tty_run "SEND 0123abcd0123" python3 "$S/feedback.py" send F002 --confirm "$H"); rc=$?
[ $rc -eq 6 ] && ! grep -q "issue" "$T/gh.log" && ok "REQ-6 wrong confirmation on TTY: exit 6, gh not called" || bad "REQ-6 wrong text (rc=$rc, $out)"
echo "$out" | grep -qF "$Q" && echo "$out" | grep -q "tahircengiz/delixcrew" && echo "$out" | grep -q "### What happened" \
  && ok "REQ-6 send prints queue dir, repo and body itself" || bad "REQ-6 send display ($out)"
# T023 REQ-1 (#34): the word alone is refused with the expected text (the pty merges stdout and stderr, \r\n)
out=$(tty_run "SEND" python3 "$S/feedback.py" send F002 --confirm "$H"); rc=$?
[ $rc -eq 6 ] && ! grep -q "issue" "$T/gh.log" \
  && printf '%s\n' "$out" | tr -d '\r' | grep -qF "Type SEND $H to send it (the word SEND, a space, then the hash): " \
  && printf '%s\n' "$out" | tr -d '\r' | grep -qF "not confirmed: type exactly SEND $H (the word SEND, a space, then the hash); nothing sent" \
  && ok "T023 REQ-1 SEND alone on a TTY: exit 6, gh not called, exact prompt and refusal" || bad "T023 REQ-1 SEND alone (rc=$rc, $out)"

# --- REQ-8 send and remote duplicate -----------------------------------------
mkdir -p "$T/fake/scripts" "$T/fake/.claude-plugin"; cp "$S/feedback.py" "$T/fake/scripts/"
echo '{"name":"delixcrew","version":"0.0.1","repository":"https://github.com/someone/fork"}' > "$T/fake/.claude-plugin/plugin.json"
out=$(python3 "$T/fake/scripts/feedback.py" send F002 --confirm "$H" </dev/null 2>&1); rc=$?
[ $rc -eq 7 ] && [ ! -s "$T/gh.log" ] && ok "REQ-8 plugin.json repository mismatch: exit 7" || bad "REQ-8 repo mismatch (rc=$rc, $out)"
out=$(GH_MODE=found tty_run "SEND $H" python3 "$S/feedback.py" send F002 --confirm "$H"); rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "issues/42" && [ "$(jq_ "$Q/F002.json" "(d['status'], d['issue_url'])")" = "('duplicate', 'https://github.com/tahircengiz/delixcrew/issues/42')" ] \
  && ! grep -q "issue create" "$T/gh.log" && ok "REQ-8 remote duplicate (exact fp line): no create, status duplicate" || bad "REQ-8 remote duplicate (rc=$rc, $out)"
grep -q -- "-R github.com/tahircengiz/delixcrew" "$T/gh.log" && grep -q -- "--state all" "$T/gh.log" && grep -q -- "--search" "$T/gh.log" \
  && ok "REQ-8 gh called with fixed -R and fp search" || bad "REQ-8 gh args ($(cat "$T/gh.log"))"
grep -qE '^(GH_HOST|GH_REPO|GH_ENTERPRISE_TOKEN|GITHUB_ENTERPRISE_TOKEN)=' "$T/gh.log" && bad "REQ-8 gh env not scrubbed" || ok "REQ-8 GH_HOST/GH_REPO/enterprise tokens removed from gh env"
out=$(cd "$A" && mk "$J1" 'd["title"]="Send works"' | fb add); id=${out%% *}
H=$(hash_of "$(fb preview "$id")"); : > "$T/gh.log"
out=$(GH_MODE=new tty_run "SEND $H" python3 "$S/feedback.py" send "$id" --confirm "$H"); rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "issues/99" && [ "$(jq_ "$Q/$id.json" "(d['status'], d['issue_url'])")" = "('sent', 'https://github.com/tahircengiz/delixcrew/issues/99')" ] \
  && ok "REQ-8 new: issue create, status sent, issue_url" || bad "REQ-8 new (rc=$rc, $out)"
grep "issue create" "$T/gh.log" | grep -q -- "--label bug" && grep "issue create" "$T/gh.log" | grep -q -- "--body-file" \
  && [ "$(tail -1 "$T/gh_body.txt")" = "delixcrew-fp: $(jq_ "$Q/$id.json" "d['fingerprint']")" ] && grep -q "^### Component" "$T/gh_body.txt" \
  && ok "REQ-8 create args: label, body file ending with delixcrew-fp line" || bad "REQ-8 create args ($(cat "$T/gh.log"))"
out=$(cd "$A" && mk "$J1" 'd["title"]="Gh fails"' | fb add); id=${out%% *}
H=$(hash_of "$(fb preview "$id")")
out=$(GH_MODE=fail tty_run "SEND $H" python3 "$S/feedback.py" send "$id" --confirm "$H"); rc=$?
[ $rc -eq 7 ] && [ "$(jq_ "$Q/$id.json" "d['status']")" = draft ] && echo "$out" | grep -q "gh" && ok "REQ-8 gh failure: exit 7, record stays draft" || bad "REQ-8 gh failure (rc=$rc, $out)"

# --- review round 1 ----------------------------------------------------------
# Finding 1: Cc control characters (ESC, CR) are rejected at add and BLOCKED in build.
cc_reject(){ # name, python mutation, field
  n0=$(nfiles); out=$(cd "$A" && mk "$J1" "$2" | fb add 2>&1); rc=$?
  [ $rc -eq 2 ] && echo "$out" | grep -q "$3" && [ "$(nfiles)" -eq "$n0" ] && ok "R1 add rejects $1 (exit 2, $3)" || bad "R1 add $1 (rc=$rc, $out)"; }
cc_reject "ESC [2K in actual" 'd["title"]="Esc erase"; d["actual"]="a\u001b[2Kb"' actual
cc_reject "CR in title"       'd["title"]="Carriage\rreturn"'                     title
cc_reject "ESC in repro step" 'd["title"]="Esc step"; d["repro"]=["x\u001b[8my"]'  repro
out=$(cd "$A" && mk "$J1" 'd["title"]="Tabs and newlines ok"; d["actual"]="a\tb\nc"' | fb add); rc=$?
[ $rc -eq 0 ] && ok "R1 add still accepts \\t and \\n" || bad "R1 tab/newline rejected ($out)"
out=$(cd "$A" && mk "$J1" 'd["title"]="Tampered control"' | fb add); id=${out%% *}
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["actual"]="a\u001b[2Kb\rc"; json.dump(d,open(p,"w"))' "$Q/$id.json"
pv=$(fb preview "$id" 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: .*control character" && ! printf '%s' "$pv" | grep -q $'\x1b' \
  && ok "R1 tampered record with ESC/CR: preview BLOCKED, no raw ESC printed" || bad "R1 tampered control (rc=$rc, $(echo "$pv" | head -1))"
out=$(fb send "$id" --confirm 000000000000 </dev/null 2>&1); [ $? -eq 4 ] && ok "R1 tampered control: send exit 4" || bad "R1 tampered control send ($out)"
# Finding 2: the stored fingerprint is recomputed; a tampered one BLOCKS.
out=$(cd "$A" && mk "$J1" 'd["title"]="Tampered fingerprint"' | fb add); id=${out%% *}
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["fingerprint"]="0123456789abcdef\n### Injected"; json.dump(d,open(p,"w"))' "$Q/$id.json"
pv=$(fb preview "$id" 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: .*fingerprint" && ! echo "$pv" | grep -q Injected \
  && ok "R2 tampered fingerprint (injected text): BLOCKED" || bad "R2 tampered fingerprint (rc=$rc, $pv)"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["fingerprint"]="0123456789abcdef"; json.dump(d,open(p,"w"))' "$Q/$id.json"
pv=$(fb preview "$id" 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: .*fingerprint" && ok "R2 well-formed but wrong fingerprint: BLOCKED" || bad "R2 wrong fingerprint (rc=$rc, $pv)"
: > "$T/gh.log"; out=$(fb send "$id" --confirm 000000000000 </dev/null 2>&1); rc=$?
[ $rc -eq 4 ] && [ ! -s "$T/gh.log" ] && ok "R2 tampered fingerprint: send exit 4, gh not called" || bad "R2 tampered fingerprint send (rc=$rc, $out)"
# Finding 3: the plugin owner is never an origin term, even from another repo of that owner.
C="$T/owner-proj"; mkdir -p "$C"; git -C "$C" init -q; git -C "$C" remote add origin git@github.com:tahircengiz/foo.git
out=$(cd "$C" && mk "$J1" 'd["title"]="Owner remote"' | fb add); id=${out%% *}
[ "$(jq_ "$Q/$id.json" "'tahircengiz' not in [t.lower() for t in d['origin_terms']] and 'foo' in d['origin_terms']")" = True ] \
  && ok "R3 tahircengiz/foo remote: owner left out of origin_terms" || bad "R3 owner in origin_terms ($(jq_ "$Q/$id.json" "d['origin_terms']"))"
fb preview F002 | grep -qF "github.com/tahircengiz/delixcrew" && ok "R3 github.com/tahircengiz/delixcrew still unchanged" || bad "R3 plugin URL redacted"

# --- rev 3 (REQ-11, REQ-12, REQ-13; missing REQ-2/4/8 tests) -----------------
export DELIXCREW_FEEDBACK_DIR="$T/q3"; Q="$DELIXCREW_FEEDBACK_DIR"
fb enable >/dev/null
add3(){ (cd "$B" && mk "$J1" "$1" | fb add); }   # draft from project B; prints "F<nnn> new"
# REQ-11: a non-string kind is rejected without a traceback.
for k in '1' '["bug"]' '{}' 'null'; do
  n0=$(nfiles); out=$(cd "$B" && mk "$J1" "d['kind']=json.loads('$k')" | fb add 2>&1); rc=$?
  [ $rc -eq 2 ] && echo "$out" | grep -q "^error: kind: must be bug or feature" && ! echo "$out" | grep -q Traceback && [ "$(nfiles)" -eq "$n0" ] \
    && ok "REQ-11 kind $k: exit 2, kind message, no traceback, no file" || bad "REQ-11 kind $k (rc=$rc, $(echo "$out" | tail -1))"
done
# REQ-12 single segment: every /<segment> is redacted, also after name: (K101) and /<name>:<name> other than /delixcrew:<skill> (K100).
out=$(add3 'd["title"]="Single segment paths"; d["actual"]="deploy goes to /srv (/acme-builds) /tmp /acme:builds nas:/volume1/acme host:/srv"; d["expected"]="/delixcrew:nosuch and /acme-corp:deploy"'); id=${out%% *}
pv=$(fb preview "$id"); rc=$?
leaks=""; for s in /srv /acme-builds /tmp /acme:builds /volume1 /delixcrew:nosuch /acme-corp:deploy; do echo "$pv" | grep -qF -- "$s" && leaks="$leaks $s"; done
[ $rc -eq 0 ] && echo "$pv" | grep -q "^VERDICT: CLEAN" && [ -z "$leaks" ] && ok "REQ-12 single-segment, name:/path and unknown /x:y paths redacted, CLEAN" || bad "REQ-12 single segment leaks:$leaks (rc=$rc, $(echo "$pv" | head -1))"
echo "$pv" | grep -qxF "deploy goes to <redacted:path> (<redacted:path>) <redacted:path> <redacted:path> nas:<redacted:path> host:<redacted:path>" \
  && ok "REQ-12 placeholders keep the surrounding text (host: and parentheses)" || bad "REQ-12 replacement shape ($(echo "$pv" | grep -F 'deploy goes'))"
# REQ-12 commands: /delixcrew:<skill>, built-in commands, URLs and in-word slashes stay.
ACT='/delixcrew:spec, /delixcrew:spec. /compact run /plugin. (/review) https://github.com/tahircengiz/delixcrew a/b w/o bug / feature'
out=$(add3 "d['title']='Commands stay'; d['actual']='$ACT'"); id=${out%% *}
pv=$(fb preview "$id"); rc=$?
[ $rc -eq 0 ] && echo "$pv" | grep -qxF -- "$ACT" && ok "REQ-12 /delixcrew:spec, /compact, /plugin., URL, a/b, w/o, bug / feature unchanged" || bad "REQ-12 commands changed ($(echo "$pv" | grep -A1 '^### What happened' | tail -1))"
pv=$(python3 "$T/fake/scripts/feedback.py" preview "$id" 2>&1)
echo "$pv" | grep -qF "/delixcrew:spec" && bad "REQ-12 skills dir missing: /delixcrew:spec kept (not fail-closed)" || ok "REQ-12 skills dir missing: /delixcrew:<skill> redacted (fail-closed)"
python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); import feedback; sys.exit(0 if feedback.SANITIZER_VERSION == "3" else 1)' "$S" \
  && ok "REQ-12 SANITIZER_VERSION is 3" || bad "REQ-12 SANITIZER_VERSION not 3"
# REQ-13: send runs only for status == draft; checked before BLOCKED, hash and TTY.
out=$(add3 'd["title"]="Dropped draft send"'); id=${out%% *}
H=$(hash_of "$(fb preview "$id")"); fb drop "$id" >/dev/null; : > "$T/gh.log"
out=$(tty_run "SEND $H" python3 "$S/feedback.py" send "$id" --confirm "$H"); rc=$?
[ $rc -eq 2 ] && echo "$out" | grep -qF "error: $id is dropped; nothing sent" && [ ! -s "$T/gh.log" ] && [ "$(jq_ "$Q/$id.json" "d['status']")" = dropped ] \
  && ok "REQ-13 dropped draft, right hash, SEND on TTY: exit 2, gh not called, stays dropped" || bad "REQ-13 dropped send (rc=$rc, $out)"
out=$(add3 'd["title"]="Status gate"'); id=${out%% *}
st_case(){ # python mutation, expected printed status
  python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); exec(sys.argv[2]); json.dump(d,open(p,"w"))' "$Q/$id.json" "$1"
  cp "$Q/$id.json" "$T/st.bak"; : > "$T/gh.log"
  out=$(fb send "$id" --confirm 000000000000 </dev/null 2>"$T/err"); rc=$?
  [ $rc -eq 2 ] && [ "$(cat "$T/err")" = "error: $id is $2; nothing sent" ] && [ -z "$out" ] && [ ! -s "$T/gh.log" ] && cmp -s "$Q/$id.json" "$T/st.bak" \
    && ok "REQ-13 status ($1): exit 2, prints '$2', record unchanged" || bad "REQ-13 status ($1) (rc=$rc, $(cat -v "$T/err"))"; }
st_case 'd["status"]="sent"'     sent
st_case 'd["status"]=None'       unknown
st_case 'del d["status"]'        unknown
st_case 'd["status"]="x\u001b"'  unknown
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["status"]="sent"; json.dump(d,open(p,"w"))' "$Q/$id.json"
out=$(GL_RC=1 fb send "$id" --confirm 000000000000 </dev/null 2>&1); rc=$?
[ $rc -eq 2 ] && ! echo "$out" | grep -q BLOCKED && ok "REQ-13 status sent + gitleaks failing: exit 2 before BLOCKED (order)" || bad "REQ-13 order (rc=$rc, $out)"
# REQ-4: gitleaks timeout (in process, K102).
out=$(add3 'd["title"]="Gitleaks timeout"'); id=${out%% *}
out=$(python3 -c 'import subprocess, sys
sys.path.insert(0, sys.argv[1]); import feedback
def run(*a, **k): raise subprocess.TimeoutExpired("gitleaks", 30)
feedback.subprocess.run = run
sys.exit(feedback.main(["preview", sys.argv[2]]))' "$S" "$id" 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$out" | grep -q "^VERDICT: BLOCKED: gitleaks failed (timeout)" && ok "REQ-4 gitleaks timeout: BLOCKED, exit 4" || bad "REQ-4 gitleaks timeout (rc=$rc, $out)"
# REQ-8: gh missing from PATH.
out=$(add3 'd["title"]="Gh missing"'); id=${out%% *}; H=$(hash_of "$(fb preview "$id")")
mkdir -p "$T/nogh"; for b in git script sleep cat sh env grep sed; do ln -s "$(command -v "$b")" "$T/nogh/$b"; done
ln -s "$(python3 -c 'import sys,os; print(os.path.realpath(sys.executable))')" "$T/nogh/python3"; cp "$T/stub/gitleaks" "$T/stub/claude" "$T/nogh/"
out=$(PATH="$T/nogh" tty_run "SEND $H" python3 "$S/feedback.py" send "$id" --confirm "$H"); rc=$?
[ $rc -eq 7 ] && echo "$out" | grep -q "gh not found" && [ "$(jq_ "$Q/$id.json" "d['status']")" = draft ] && ok "REQ-8 gh not on PATH: exit 7, stays draft" || bad "REQ-8 gh missing (rc=$rc, $out)"
# REQ-8: issue list works, issue create fails.
mkdir -p "$T/stub2"; cat > "$T/stub2/gh" <<'SH'
#!/bin/sh
echo "ARGS: $*" >> "$FBT/gh.log"
case "$*" in
  *"issue list"*) echo '[]'; exit 0;;
  *"issue create"*) echo "create: HTTP 422" >&2; exit 1;;
esac
exit 1
SH
chmod +x "$T/stub2/gh"
out=$(add3 'd["title"]="Create fails"'); id=${out%% *}; H=$(hash_of "$(fb preview "$id")"); : > "$T/gh.log"
out=$(PATH="$T/stub2:$PATH" tty_run "SEND $H" python3 "$S/feedback.py" send "$id" --confirm "$H"); rc=$?
[ $rc -eq 7 ] && grep -q "issue create" "$T/gh.log" && [ "$(jq_ "$Q/$id.json" "d['status']")" = draft ] && ok "REQ-8 list ok, create fails: exit 7, stays draft" || bad "REQ-8 create fails (rc=$rc, $out)"
# REQ-2: a repeat keeps first_seen and moves last_seen.
out=$(add3 'd["title"]="Seen times"'); id=${out%% *}
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["first_seen"]=d["last_seen"]="2000-01-01T00:00:00Z"; json.dump(d,open(p,"w"))' "$Q/$id.json"
add3 'd["title"]="Seen times"' >/dev/null
[ "$(jq_ "$Q/$id.json" "d['first_seen']=='2000-01-01T00:00:00Z' and d['last_seen']!='2000-01-01T00:00:00Z'")" = True ] \
  && ok "REQ-2 repeat: first_seen kept, last_seen updated" || bad "REQ-2 seen times ($(jq_ "$Q/$id.json" "(d['first_seen'], d['last_seen'])"))"
# REQ-4: residual match after sanitizing (term inside a file-like token).
fb enable --terms acme >/dev/null
out=$(add3 'd["title"]="Residual"; d["actual"]="see x.ioacme.md"'); id=${out%% *}
pv=$(fb preview "$id" 2>&1); rc=$?
[ $rc -eq 4 ] && echo "$pv" | grep -q "^VERDICT: BLOCKED: .*residual match after sanitizing" && ok "REQ-4 residual match: BLOCKED" || bad "REQ-4 residual (rc=$rc, $(echo "$pv" | head -1))"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
