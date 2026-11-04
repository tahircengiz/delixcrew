#!/usr/bin/env bash
# Deterministic tests for feedback.sanitize() and list/add escaping (SPEC docs/delix/SPEC.md REQ-1…5, REQ-7; card T016).
# Run: bash tests/sanitize_tests.sh. No network: gitleaks and claude are stubs on PATH.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"; S="$ROOT/scripts"; FAIL=0
T="$(cd "$(mktemp -d)" && pwd -P)"
export DELIXCREW_FEEDBACK_DIR="$T/q" HOME="$T/home" USER="alice-test" FBT="$T" FBS="$S"
Q="$DELIXCREW_FEEDBACK_DIR"; mkdir -p "$HOME" "$T/stub" "$T/proj"
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
fb(){ python3 "$S/feedback.py" "$@"; }
printf '#!/bin/sh\ncat >/dev/null\nexit 0\n' > "$T/stub/gitleaks"
printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$T/stub/claude"
chmod +x "$T/stub/"*; export PATH="$T/stub:$PATH"

# --- cases: one input per line; a case set is a heredoc -----------------------
cat > "$T/req1_denied.txt" <<'EOF'
smb://nas/volume1/acme	smb://<redacted:url>
http://jenkins:8080/job/x	http://<redacted:url>
//fileserver/share	<redacted:url>
file:///etc/passwd	file://<redacted:url>
redis://cache:6379	redis://<redacted:url>
postgres://user@db/x	postgres://<redacted:url>
http://intranet/	http://<redacted:url>
https://build.example-corp.dev/acme/x	https://<redacted:url>
build.example-corp.dev/job/x	<redacted:url>
https://github.com/acme-corp/private/issues/1	https://<redacted:url>
https://bücher.example-corp.de/a	https://<redacted:url>
(http://intranet/x).	(http://<redacted:url>).
jenkins:8080/job/acme-build	<redacted:url>
EOF
cat > "$T/req1_authority.txt" <<'EOF'
https://deploy:Hunter2pass@github.com/tahircengiz/delixcrew.git
https://jenkins.acme-corp.internal\@github.com/tahircengiz/delixcrew
https://intranet.acme#@github.com/
https://intranet.acme?@github.com/
https://acme-crm.test/admin
http://billing.acme.localhost/api
EOF
cat > "$T/req1_numeric.txt" <<'EOF'
http://167838211/x
http://0x0A010203/
http://012.01.02.03/
http://10.1.3/
http://10.1.2.3/x
EOF
cat > "$T/req1_inner.txt" <<'EOF'
https://docs.example.com/p?u=bob@example-corp.dev
https://github.com/tahircengiz/delixcrew/issues?q=acme
http://localhost:8080/cb?redirect_uri=https%3A%2F%2Fsso.corp.internal%2Fauth
https://github.com/tahircengiz/delixcrew/../../acme-corp/private-repo
https://github.com/anthropics/claude-code/issues?q=jenkins.corp.internal
https://code.claude.com/docs?from=/srv/x
http://localhost:3000/x?db=postgres://u@db.corp.internal/prod
EOF
cat > "$T/req1_kept.txt" <<'EOF'
https://github.com/tahircengiz/delixcrew/issues/3
https://GitHub.com/TahirCengiz/DelixCrew
https://github.com/anthropics/claude-code/issues/1
https://code.claude.com/docs/en/hooks#pretooluse-input
https://github.com/tahircengiz/delixcrew/blob/main/scripts/feedback.py#L60
http://localhost:8080/a
localhost:8080/a
http://127.0.0.1:3000/
http://[2001:db8::1]/x
https://docs.example.com/p
github.com/tahircengiz/delixcrew
(https://github.com/tahircengiz/delixcrew).
smb://<redacted:url>
http://
// TODO
scripts/feedback.py:342
EOF
cat > "$T/req2_redirect.txt" <<'EOF'
cmd >/srv/acme/out.log	cmd >
x 2>/var/lib/acme/x	x 2>
{"p":"\/srv\/acme"}	{"p":"
run --/srv/acme	run --
foo./srv/acme	foo.
a|/opt/acme	a|
\\fileserver\share\acme
EOF
cat > "$T/req2_kept.txt" <<'EOF'
skills/feedback/SKILL.md
./scripts/feedback.py
`./scripts/feedback.py`
"../skills/x"
(./x)
../skills/x
~/x
a/b
w/o
bug / feature
/delixcrew:spec
/compact
EOF
cat > "$T/req3.txt" <<'EOF'
bücher.example-corp.de	<redacted:host>
xn--bcher-kva.example-corp.de	<redacted:host>
notlar.md	notlar.md
EOF
# Card "Review Focus" edges.
cat > "$T/edges.txt" <<'EOF'
(https://github.com/tahircengiz/delixcrew)/srv/x	(https://github.com/tahircengiz/delixcrew)<redacted:path>
https://github.com/tahircengiz/delixcrew./srv	https://<redacted:url>
http://[fe80::1%en0]/	http://<redacted:url>
http://[::1]:8080/	http://[::1]:8080/
https://github.com//tahircengiz/delixcrew	https://<redacted:url>
https://github.com\tahircengiz\delixcrew	https://<redacted:url>
EOF
# Review round 1 (F1 scheme, F2 Unicode TLD, F3 host after a dot, F4 long e-mail local part).
cat > "$T/r1_absent.txt" <<'EOF'
jenkins.acme-corp.internal://github.com/tahircengiz/delixcrew
acme-corp.dev+https://github.com/anthropics/x
ip-10-1-2-3.ec2.internal://code.claude.com/docs
bücher.example-corp.de+https://github.com/tahircengiz/delixcrew
see .jenkins.acme-corp.internal
a..jenkins.acme-corp.internal
EOF
cat > "$T/r1_exact.txt" <<'EOF'
intranet.corp.рф	<redacted:host>
foo.рф/x	<redacted:url>
notlar.md	notlar.md
https://code.claude.com/.jenkins.acme-corp.internal	https://<redacted:url>
EOF
# Review round 2 (G1 "_" suffix and URL tail allowlist, G2 host after "@").
cat > "$T/r2_exact.txt" <<'EOF'
_jenkins.acme-corp.internal_	<redacted:host>
https://code.claude.com/docs/jenkins.acme-corp.internal_	https://<redacted:url>
https://github.com/tahircengiz/delixcrew/blob/main/jenkins.acme-corp.internal_	https://<redacted:url>
admin@bücher.example-corp.de	<redacted:email>
jürgen.schmidt@acme-corp.de	<redacted:email>
https://github.com/tahircengiz/delixcrew/releases/tag/v0.6.1	https://github.com/tahircengiz/delixcrew/releases/tag/v0.6.1
https://code.claude.com/docs/a.tar.gz	https://code.claude.com/docs/a.tar.gz
https://github.com/anthropics/claude-code/blob/main/README.md	https://github.com/anthropics/claude-code/blob/main/README.md
https://code.claude.com/docs/x_y	https://code.claude.com/docs/x_y
EOF
cat > "$T/r2_absent.txt" <<'EOF'
jenkins.acme-corp.internal_https://github.com/anthropics/x
@jenkins.acme-corp.internal
@.jenkins.acme-corp.internal
EOF
# Review round 3 (H1 trailing non-letter label, H2 IPv4 after "_" or ".").
cat > "$T/r3_exact.txt" <<'EOF'
jenkins.acme-corp._internal	<redacted:host>
notlar.md._	notlar.md._
v0.6.1	v0.6.1
__init__.py	__init__.py
x._	x._
https://code.claude.com/docs/_10.20.30.40	https://<redacted:url>
https://code.claude.com/docs/x.10.20.30.40	https://<redacted:url>
_10.20.30.40	_<redacted:ip>
v1.2.3.4	v1.2.3.4
EOF
cat > "$T/r3_absent.txt" <<'EOF'
_The build runs on jenkins.acme-corp.internal._
on jenkins.acme-corp.internal.__
EOF

cat > "$T/cases.py" <<'PY'
import os, sys, time
sys.path.insert(0, os.environ["FBS"])
import feedback as f
T = os.environ["FBT"]
FAIL = 0
ACME = f.term_regex({"acme"})
seen = []  # every input, for REQ-4


def res(ok, msg):
    global FAIL
    print(("✔ " if ok else "✘ ") + msg)
    FAIL |= not ok


def lines(name):
    with open(os.path.join(T, name), encoding="utf-8") as fh:
        return [l.rstrip("\n") for l in fh if l.rstrip("\n")]


def pairs(name):
    return [tuple((l.split("\t", 1) + [""])[:2]) for l in lines(name)]  # an empty second column may lose its tab


def s(x, term_re=None):
    seen.append((x, term_re))
    return f.sanitize(x, term_re)


for x, want in pairs("req1_denied.txt"):
    got = s(x)
    res(got == want, "REQ-1 denied %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x in lines("req1_authority.txt"):
    got = s(x)
    leak = [w for w in ("Hunter2pass", "deploy", "jenkins", "intranet", "acme") if w in got]
    pre = got.startswith(("https://<redacted:url>", "http://<redacted:url>"))
    res(pre and not leak, "REQ-1 authority trick %s → %s" % (x, got))
for x in lines("req1_numeric.txt"):
    got = s(x)
    res(got == "http://<redacted:url>", "REQ-1 numeric host %s → %s" % (x, got))
for x in lines("req1_inner.txt"):
    got = s(x, ACME)
    want = x.split("://", 1)[0] + "://<redacted:url>"
    res(got == want, "REQ-1 inner info on allowed host %s → %s" % (x, got))
for x in lines("req1_kept.txt"):
    got = s(x)
    res(got == x, "REQ-1 unchanged %s%s" % (x, "" if got == x else " (got %s)" % got))
for x, keep in pairs("req2_redirect.txt"):
    got = s(x)
    leak = [w for w in ("acme", "srv", "var/lib", "opt", "fileserver") if w in got]
    res(not leak and got.startswith(keep) and "<redacted:path>" in got, "REQ-2 path context %s → %s" % (x, got))
for x in lines("req2_kept.txt"):
    got = s(x)
    res(got == x, "REQ-2 unchanged %s%s" % (x, "" if got == x else " (got %s)" % got))
for x, want in pairs("req3.txt"):
    got = s(x)
    res(got == want, "REQ-3 %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x, want in pairs("edges.txt"):
    got = s(x)
    res(got == want, "edge %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x in lines("r1_absent.txt"):
    got = s(x)
    leak = [w for w in ("jenkins", "acme", "ec2.internal", "example-corp", "bücher") if w in got]
    res(not leak, "round 1 %s → %s" % (x, got))
for x, want in pairs("r1_exact.txt") + [("a" * 70 + "@corp.com", "<redacted:email>")]:
    got = s(x)
    res(got == want, "round 1 %s → %s%s" % (x[:40], want, "" if got == want else " (got %s)" % got))
for x, want in pairs("r2_exact.txt"):
    got = s(x)
    res(got == want, "round 2 %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x in lines("r2_absent.txt"):
    got = s(x)
    res("jenkins" not in got and "acme" not in got, "round 2 %s → %s" % (x, got))
for x, want in pairs("r3_exact.txt"):
    got = s(x)
    res(got == want, "round 3 %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x in lines("r3_absent.txt"):
    got = s(x)
    res("jenkins" not in got and "acme" not in got, "round 3 %s → %s" % (x, got))
res(f.SANITIZER_VERSION == "3", "REQ-4 SANITIZER_VERSION is 3")

once = [(x, r, f.sanitize(x, r)) for x, r in seen]
bad = [x for x, r, a in once if f.sanitize(a, r) != a]
res(not bad, "REQ-4 sanitize(sanitize(x)) == sanitize(x) for %d inputs%s" % (len(once), "" if not bad else " (not for %r)" % bad))

redos = [("slash", "/" * 50000), ("a-slash", "a/" * 25000), ("json-slash", "\\/" * 25000),
         ("http", ("http://" * 7143)[:50000]), ("backslash", "\\" * 50000), ("dot", "." * 50000),
         ("scheme-a", "x://" + "a" * 50000), ("github-a-slash", "https://github.com/" + "a/" * 25000),
         ("query-amp", "http://x/?" + "a&" * 25000), ("u-dot", "ü." * 25000), ("a-dot-slash", "a." * 25000 + "/"),
         ("email-a-at", "a" * 50000 + "@"), ("email-dot", "." * 50000),
         ("ab-at", "ab@" * 16000), ("underscore-dot", "_." * 25000),
         ("a-dot-underscore", "a" + "._" * 25000), ("underscore-ipv4", "_1.2.3.4" * 6000)]
for name, x in redos:
    t0 = time.perf_counter()
    f.sanitize(x, None)
    dt_ = time.perf_counter() - t0
    res(dt_ < 0.5, "REQ-5 %s %.3f s" % (name, dt_))
sys.exit(FAIL)
PY
python3 "$T/cases.py" || FAIL=1

# --- REQ-4: a draft built from the REQ-1 inputs is not BLOCKED for residual matches
fb enable --terms acme >/dev/null
J=$(python3 - "$T" <<'PY'
import json, os, sys
T = sys.argv[1]
xs = []
for n in ("req1_denied.txt", "req1_authority.txt", "req1_numeric.txt", "req1_inner.txt", "req1_kept.txt"):
    xs += [l.rstrip("\n").split("\t")[0] for l in open(os.path.join(T, n), encoding="utf-8") if l.strip()]
print(json.dumps({"kind": "bug", "component": "feedback", "title": "URL inputs", "actual": "\n".join(xs),
                  "expected": "clean", "repro": ["preview"]}))
PY
)
out=$(cd "$T/proj" && echo "$J" | fb add); id=${out%% *}
pv=$(fb preview "$id" 2>&1); v=$(printf '%s\n' "$pv" | head -1)
[ "$out" = "$id new" ] && printf '%s' "$v" | grep -q '^VERDICT:' && ! printf '%s' "$v" | grep -q 'residual match' \
  && ok "REQ-4 preview of the REQ-1 inputs: no residual match ($v)" || bad "REQ-4 preview residual ($out; $v)"

# --- REQ-7: list and duplicate add escape values read from disk -----------------
export DELIXCREW_FEEDBACK_DIR="$T/q7"; Q="$DELIXCREW_FEEDBACK_DIR"; fb enable >/dev/null
D1='{"kind":"bug","component":"feedback","title":"Escape one","actual":"a","expected":"b","repro":["c"]}'
D2='{"kind":"bug","component":"feedback","title":"Escape two","actual":"a","expected":"b","repro":["c"]}'
id1=$(cd "$T/proj" && echo "$D1" | fb add); id1=${id1%% *}
id2=$(cd "$T/proj" && echo "$D2" | fb add); id2=${id2%% *}
python3 - "$Q/$id1.json" "$Q/$id2.json" <<'PY'
import json, sys
p1, p2 = sys.argv[1:]
d = json.load(open(p1)); d["title"] = "\u001b]8;;http://x\u0007click\u001b]8;;\u0007"; d["status"] = "draft\u001b[2J"
d["component"] = "a\u2028b"; json.dump(d, open(p1, "w"))
d = json.load(open(p2)); d["title"] = "x\ud800"; json.dump(d, open(p2, "w"))
PY
python3 - "$S/feedback.py" "$T/proj" "$D1" "$Q/$id1.json" <<'PY' || FAIL=1
import json, subprocess, sys
fb, cwd, d1, p1 = sys.argv[1:]
FAIL = 0
def res(ok, msg):
    global FAIL
    print(("✔ " if ok else "✘ ") + msg)
    FAIL |= not ok
def clean(b):
    return b"\x1b" not in b and b"\x07" not in b and "\u2028".encode() not in b
lst = subprocess.run([sys.executable, fb, "list"], capture_output=True)
res(lst.returncode == 0 and clean(lst.stdout) and all(t in lst.stdout for t in (b"\\x1b]8;;", b"\\u2028", b"\\ud800", b"draft\\x1b[2J")),
    "REQ-7 list: exit %d, no ESC/BEL/U+2028 bytes, escapes visible" % lst.returncode)
add = subprocess.run([sys.executable, fb, "add"], input=d1.encode(), capture_output=True, cwd=cwd)
res(add.returncode == 0 and clean(add.stdout) and b"duplicate (count 2, draft\\x1b[2J)" in add.stdout,
    "REQ-7 duplicate add: exit %d, %r" % (add.returncode, add.stdout))
res(json.load(open(p1, encoding="utf-8"))["status"] == "draft\u001b[2J", "REQ-7 status on disk still raw")
sys.exit(FAIL)
PY

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
