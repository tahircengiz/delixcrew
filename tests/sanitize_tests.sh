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
# T020 (SPEC REQ-1, REQ-2, REQ-6): path after a host, IP edge forms, pinned path cases.
cat > "$T/t020_req1_exact.txt" <<'EOF'
key:ci.acme-corp.net/api/x	key:<redacted:url>
ref:github.com/acme/private	ref:<redacted:url>
x\ci.acme-corp.net/api/x	x\<redacted:url>
user@ci.acme-corp.net/api/x	<redacted:email><redacted:path>
see 10.1.2.3/api/x	see <redacted:ip><redacted:path>
a/ci.acme-corp.net:8080/api/x	a/<redacted:host><redacted:path>
ci.acme-corp.net:acme/private	<redacted:host><redacted:path>
git@github.com:acme/private	<redacted:email><redacted:path>
vendor/github.com/acme/private-lib/x.go	vendor/github.com<redacted:path>
~/src/github.com/acme/private	~/src/github.com<redacted:path>
(@github.com/acme/private)	(@github.com<redacted:path>)
see x.acme-corp.net: ok	see <redacted:host>: ok
nas:/volume1/x	nas:<redacted:path>
de:ad:be:ef:00:11/x	<redacted:mac><redacted:path>
see 10.1.2.3/api/x.	see <redacted:ip><redacted:path>.
vendor/github.com/acme/x,	vendor/github.com<redacted:path>,
10.1.2.0/24	<redacted:ip><redacted:path>
fd00::/64	<redacted:ip><redacted:path>
10.1.2.3:8080	<redacted:ip><redacted:path>
fd12:3456:789a:1:2:3:4:5/64	<redacted:ip><redacted:path>
EOF
cat > "$T/t020_req1_kept.txt" <<'EOF'
see github.com/tahircengiz/delixcrew/issues/1.
go github.com/anthropics/x
github.com/
a/b
w/o
a:b:8080/x
EOF
cat > "$T/t020_req2_exact.txt" <<'EOF'
10.20.30.40_	<redacted:ip>_
fd00:1:2::3_	<redacted:ip>_
_fd00:1:2::3	_<redacted:ip>
host 010.001.002.003	host <redacted:ip>
v1.2.3.4	v1.2.3.4
1.2.3.4a	1.2.3.4a
999.1.1.1	999.1.1.1
EOF
cat > "$T/t020_req6_exact.txt" <<'EOF'
a//b	a/<redacted:path>
>/Users/alice/x	><redacted:path>
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
for x, want in pairs("t020_req1_exact.txt"):
    got = s(x)
    res(got == want, "T020 REQ-1 %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x in lines("t020_req1_kept.txt"):
    got = s(x)
    res(got == x, "T020 REQ-1 unchanged %s%s" % (x, "" if got == x else " (got %s)" % got))
for x, want in pairs("t020_req2_exact.txt"):
    got = s(x)
    res(got == want, "T020 REQ-2 %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
for x, want in pairs("t020_req6_exact.txt"):
    got = s(x)
    res(got == want, "REQ-6 %s → %s%s" % (x, want, "" if got == want else " (got %s)" % got))
inv = getattr(f, "invisible", None)
for want, args in ((True, ("ok" + "︀" * 8,)), (True, ("aㅤb",)), (True, ("a b",)), (True, ("a b",)),
                   (False, ("I ❤️ it", "\t")), (False, ("a\tb\nc", "\t")), (True, ("a\tb",))):
    try:
        got = inv(*args)
    except Exception as e:  # red stage: feedback.invisible does not exist yet
        got = type(e).__name__
    res(got is want, "T020 REQ-3 invisible(%s) is %s%s" % (", ".join(ascii(a) for a in args), want,
                                                          "" if got is want else " (got %s)" % got))
try:
    import triage
    same = triage.invisible is f.invisible and triage.visible is f.visible
except Exception as e:
    same = False
res(same, "T020 REQ-3 triage.invisible/visible are feedback.invisible/visible")
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


def best(x):
    """K163: the smallest of 3 runs."""
    runs = []
    for _ in range(3):
        t0 = time.perf_counter()
        f.sanitize(x, None)
        runs.append(time.perf_counter() - t0)
    return min(runs)


N = 50000
t020 = [("a-space-slashes", ("a //b " * 8334)[:N]),
        ("github-allowed-1dot", ("http://github.com/tahircengiz/delixcrew/" + "1." * 25000)[:N]),
        ("key-host-slash", ("key:a.bc/" * 5556)[:N]), ("ph-host-slash", "<redacted:host>/" * 3125),
        ("ph-host-colon", "<redacted:host>:" * 3125), ("colon", ":" * N), ("backslash", "\\" * N),
        ("underscore-a-colon", ("_a:" * 16667)[:N]), ("github-slash", ("github.com/" * 4546)[:N]),
        ("zero-octet", "010." * 12500)]
for name, x in t020:
    dt_ = best(x)
    res(dt_ < 0.5, "REQ-5 t020-%s %.3f s" % (name, dt_))
b50, b200 = best(("a //b " * 8334)[:N]), best(("a //b " * 33334)[:200000])
res(b200 <= 6 * b50, "REQ-5 t020-growth a //b 50K %.3f s, 200K %.3f s, ratio %.2f (≤ 6)" % (b50, b200, b200 / b50))
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

# --- T020 REQ-6: a second draft from the path and IP inputs is not BLOCKED for residual matches
J6=$(python3 - "$T" <<'PY'
import json, os, sys
T = sys.argv[1]
xs = []
for n in ("req2_redirect.txt", "req2_kept.txt", "req3.txt", "t020_req1_exact.txt", "t020_req1_kept.txt",
          "t020_req2_exact.txt"):
    xs += [l.rstrip("\n").split("\t")[0] for l in open(os.path.join(T, n), encoding="utf-8") if l.strip()]
actual, context = [], []
for x in xs:  # TEXT_MAX is 2000 per field: the rest goes to context
    (actual if len("\n".join(actual + [x])) <= 2000 else context).append(x)
print(json.dumps({"kind": "bug", "component": "feedback", "title": "Path and IP inputs", "actual": "\n".join(actual),
                  "context": "\n".join(context), "expected": "clean", "repro": ["preview"]}))
PY
)
out6=$(cd "$T/proj" && echo "$J6" | fb add); id6=${out6%% *}
pv6=$(fb preview "$id6" 2>&1); v6=$(printf '%s\n' "$pv6" | head -1)
[ "$out6" = "$id6 new" ] && printf '%s' "$v6" | grep -q '^VERDICT:' && ! printf '%s' "$v6" | grep -q 'residual match' \
  && ok "REQ-6 preview of the path and IP inputs: no residual match ($v6)" || bad "REQ-6 preview residual ($out6; $v6)"

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

# --- T020 REQ-3 / REQ-4 through the CLI: invisible characters, lone surrogates, broken record ids
python3 - "$S/feedback.py" "$T" <<'PY' || FAIL=1
import json, os, subprocess, sys
fb, T = sys.argv[1:]
FAIL = 0
QN = [0]
def res(ok, msg):
    global FAIL
    print(("✔ " if ok else "✘ ") + msg)
    FAIL |= not ok
def run(q, *args, inp=None):
    return subprocess.run([sys.executable, fb, *args], input=inp, capture_output=True, cwd=os.path.join(T, "proj"),
                          env=dict(os.environ, DELIXCREW_FEEDBACK_DIR=q))
def queue():
    q = os.path.join(T, "q3b%d" % QN[0])
    QN[0] += 1
    run(q, "enable")
    return q
def draft(**kw):
    d = {"kind": "bug", "component": "feedback", "title": "Invisible check", "actual": "a", "expected": "b",
         "repro": ["c"]}
    d.update(kw)
    return d
def add(q, d):
    return run(q, "add", inp=json.dumps(d).encode())  # ensure_ascii: a lone surrogate travels as \ud800
def rid(a):
    return (a.stdout.decode("utf-8", "replace").split() or ["F001"])[0]
def edit(q, r, **kw):
    p = os.path.join(q, r + ".json")
    with open(p, encoding="utf-8") as fh:
        d = json.load(fh)
    d.update(kw)
    with open(p, "w") as fh:
        json.dump(d, fh)  # default ensure_ascii, as a hand edit would
def first(p):
    return p.stdout.split(b"\n")[0].decode("utf-8", "replace")

for name, kw in (("title U+FE00 x8", {"title": "ok" + "︀" * 8}), ("title U+3164", {"title": "aㅤb"}),
                 ("actual U+2028", {"actual": "x y"}), ("actual U+2029", {"actual": "x y"})):
    q = queue()
    a = add(q, draft(**kw))
    p = run(q, "preview", rid(a))
    v = first(p)
    res(a.returncode == 0 and p.returncode == 4 and v.startswith("VERDICT: BLOCKED: ") and "invisible character" in v
        and " ".encode() not in p.stdout and " ".encode() not in p.stdout,
        "REQ-3 %s: add exit %d, preview exit %d, %s" % (name, a.returncode, p.returncode, ascii(v)))
q = queue()
a = add(q, draft(title="I ❤️ it", actual="a\tb\nc"))
p = run(q, "preview", rid(a))
res(a.returncode == 0 and b"invisible character" not in p.stdout,
    "REQ-3 emoji, tab and newline are allowed: add exit %d, %s" % (a.returncode, ascii(first(p))))

for field in ("title", "fingerprint"):
    q = queue()
    a = add(q, draft(title="Surrogate on disk"))
    edit(q, rid(a), **{field: "x\ud800" if field == "title" else "\ud800"})
    p = run(q, "preview", rid(a))
    ok_first = first(p) == "VERDICT: BLOCKED: invisible character" if field == "title" else True
    res(p.returncode == 4 and ok_first and b"Traceback" not in p.stderr,
        "REQ-3 %s with a lone surrogate on disk: preview exit %d, %s, Traceback %s"
        % (field, p.returncode, ascii(first(p)), b"Traceback" in p.stderr))
    if field == "title":
        lst = run(q, "list")
        res(lst.returncode == 0 and b"Traceback" not in lst.stderr,
            "REQ-3 list with a lone surrogate on disk: exit %d, Traceback %s" % (lst.returncode, b"Traceback" in lst.stderr))
q = queue()
before = sorted(os.listdir(q))
a = add(q, draft(title="x\ud800"))
res(a.returncode == 2 and b"title: lone surrogate" in a.stderr and b"Traceback" not in a.stderr
    and sorted(os.listdir(q)) == before,
    "REQ-3 add with a lone surrogate: exit %d, %s, queue unchanged %s"
    % (a.returncode, ascii(a.stderr.decode("utf-8", "replace").strip()[-80:]), sorted(os.listdir(q)) == before))

for badid in ("../x", "F001\n"):
    q = queue()
    a = add(q, draft(title="Duplicate check"))
    edit(q, "F001", id=badid)
    before, parent = sorted(os.listdir(q)), sorted(os.listdir(T))
    b = add(q, draft(title="Duplicate check"))
    res(a.stdout == b"F001 new\n" and b.returncode == 0 and b.stdout == b"F002 new\n"
        and sorted(os.listdir(q)) == sorted(before + ["F002.json"]) and sorted(os.listdir(T)) == parent,
        "REQ-4 id %s: second add exit %d, %s, queue %s" % (ascii(badid), b.returncode, ascii(b.stdout), sorted(os.listdir(q))))
    if badid == "F001\n":
        p = run(q, "preview", "F001\n")
        res(p.returncode == 2, "REQ-4 preview %s: exit %d" % (ascii(badid), p.returncode))
sys.exit(FAIL)
PY

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
