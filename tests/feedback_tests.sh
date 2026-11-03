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

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
