#!/usr/bin/env bash
# Unreadable feedback config.json in scripts/triage.py (PR #51 verification, Low). Run: bash tests/triage_config_tests.sh
# preview and apply stop with a BLOCKED reason instead of building the comment without the user's extra_terms; a
# missing config.json still means no extra terms. No network: gh (one read-only issue) and gitleaks are stubs on PATH.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"; S="$ROOT/scripts"; FAIL=0
T="$(cd "$(mktemp -d)" && pwd -P)"
unset DELIXCREW_FEEDBACK_DIR
export DELIXCREW_TRIAGE_DIR="$T/tri" HOME="$T/home" USER="alice-test" TRT="$T"
mkdir -p "$HOME/.claude/delixcrew/feedback" "$T/stub"; : > "$T/gh.log"
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
field(){ printf '%s\n' "$1" | tr -d '\r' | sed -n "s/^$2: //p" | head -1; }
# guard kills the command after 5 s (rc 124): a FIFO that blocks open() fails the test instead of hanging the suite.
guard(){ python3 -c 'import subprocess, sys
try:
    sys.exit(subprocess.run(sys.argv[1:], timeout=5).returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)' "$@"; }
tg(){ guard python3 "$S/triage.py" "$@"; }
others(){ grep -vc '^ARGS: issue view ' "$T/gh.log"; }  # gh calls other than the read

cat > "$T/stub/gitleaks" <<'SH'
#!/bin/sh
cat >/dev/null
exit 0
SH
cat > "$T/stub/gh" <<'PY'
#!/usr/bin/env python3
import json, os, sys
a = sys.argv[1:]
with open(os.path.join(os.environ["TRT"], "gh.log"), "a") as f:
    f.write("ARGS: " + " ".join(a) + "\n")
if a[:3] != ["issue", "view", "-R"] or a[4:5] != ["17"] or "--json" not in a:
    sys.stderr.write("stub: unsupported " + " ".join(a) + "\n"); sys.exit(1)
full = {"title": "Copy the marker", "body": "Body.", "state": "OPEN",
        "url": "https://github.com/tahircengiz/delixcrew/issues/17", "author": {"login": "someone-else"},
        "labels": [], "comments": []}
print(json.dumps({k: full[k] for k in a[a.index("--json") + 1].split(",")}))
PY
chmod +x "$T/stub/"*; export PATH="$T/stub:$PATH"

CFG="$HOME/.claude/delixcrew/feedback/config.json"
printf '{"enabled":false,"extra_terms":["acme"]}' > "$CFG"; cp "$CFG" "$T/cfg.bak"
ISHA=$(python3 -c 'import hashlib; print(hashlib.sha256(b"Copy the marker\nBody.").hexdigest()[:12])')
J="{\"issue_sha\":\"$ISHA\",\"decision\":\"defer\",\"reason\":\"Ship it to the acme team; mail bob@example.com.\"}"
out=$(printf '%s' "$J" | python3 "$S/triage.py" record 17 2>&1) || bad "setup: record 17 ($out)"
CFGB="VERDICT: BLOCKED: feedback config.json unreadable; fix it so its extra_terms apply"

pv=$(tg preview 17); rc=$?; H=$(field "$pv" HASH)
[ $rc -eq 0 ] && echo "$pv" | grep -q "^VERDICT: CLEAN" && echo "$pv" | grep -qF "Ship it to the <redacted:term> team;" \
  && ok "config.json readable: preview CLEAN, acme redacted" || bad "config.json readable: preview (rc=$rc, $(echo "$pv" | grep VERDICT))"

badcfg(){ # name, kind (broken / fifo / big / deep / array); config.json is made that way, then restored
  rm -f "$CFG"
  case "$2" in
    broken) printf '{"enabled":false,"extra_terms":["acme"]' > "$CFG";;
    fifo) mkfifo "$CFG";;
    big) python3 -c 'import sys; open(sys.argv[1], "w").write(open(sys.argv[2]).read() + " " * (1 << 20))' "$CFG" "$T/cfg.bak";;
    deep) python3 -c 'import json, sys
x = 1
for _ in range(40):
    x = [x]
open(sys.argv[1], "w").write(json.dumps({"enabled": False, "extra_terms": ["acme"], "x": x}))' "$CFG";;
    array) printf '["acme"]' > "$CFG";;
  esac
  pv=$(tg preview 17 2>&1); rc=$?
  [ $rc -eq 4 ] && [ "$(echo "$pv" | grep '^VERDICT')" = "$CFGB" ] && ! echo "$pv" | grep -qE '^(HASH:|---$)|Triage:|acme' \
    && ok "config.json $1: preview BLOCKED, exit 4, no comment" || bad "config.json $1: preview (rc=$rc, $(echo "$pv" | tail -1))"
  : > "$T/gh.log"; out=$(tg apply 17 --confirm "$H" </dev/null 2>&1); rc=$?
  [ $rc -eq 4 ] && [ "$(echo "$out" | grep '^VERDICT')" = "$CFGB" ] && ! echo "$out" | grep -q acme && [ "$(others)" = 0 ] \
    && ok "config.json $1: apply with the earlier HASH stops, exit 4, no gh write" || bad "config.json $1: apply (rc=$rc, $(echo "$out" | tail -1))"
  rm -f "$CFG"; cp "$T/cfg.bak" "$CFG"; }
badcfg "malformed JSON"                   broken
badcfg "FIFO at the config path"          fifo
badcfg "valid config padded past 1 MiB"   big
badcfg "valid config 41 levels deep"      deep
badcfg "valid JSON that is not an object" array

rm -f "$CFG"; pv=$(tg preview 17); rc=$?
[ $rc -eq 0 ] && echo "$pv" | grep -q "^VERDICT: CLEAN" && echo "$pv" | grep -qF "Ship it to the acme team;" \
  && ok "no config.json: preview CLEAN without extra terms (unchanged)" || bad "no config.json: preview (rc=$rc, $(echo "$pv" | grep VERDICT))"
cp "$T/cfg.bak" "$CFG"; [ "$(field "$(tg preview 17)" HASH)" = "$H" ] && ok "config.json restored: preview HASH as before" \
  || bad "config.json restored: HASH changed"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
