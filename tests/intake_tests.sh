#!/usr/bin/env bash
# T065 (Spec F REQ-1 to REQ-4, REQ-6): scripts/intake.py, the read-only intake record checker (check, list, show,
# table()). Every fixture is written by Python with json.dumps(..., ensure_ascii=True); invisible and other special
# characters appear only as Python \uXXXX escapes and the check marks are octal escapes, so this file stays ASCII
# (K429). The feedback queue is an empty temp dir, so the result does not depend on this machine's queue (K426).
# Run: bash tests/intake_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"; S="$ROOT/scripts"; FAIL=0
T="$(cd "$(mktemp -d)" && pwd -P)"
unset DELIXCREW_TRIAGE_DIR
export DELIXCREW_FEEDBACK_DIR="$T/fb"
mkdir -p "$T/fb" "$T/fx" "$T/empty"
OK=$'\342\234\224'; NO=$'\342\234\230'
F="$T/fx/r.json"
NULLS="set decision, basis, reason and consent to null"
START="only an accepted, unstarted item can be started (/delixcrew:intake decide)"
# guard kills the command after 5 s (rc 124): a FIFO that blocks open() fails the test instead of hanging the suite.
guard(){ python3 -c 'import subprocess, sys
try:
    sys.exit(subprocess.run(sys.argv[1:], timeout=5).returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)' "$@"; }

# One label per case: begin, any number of checks (miss marks the case failed and says why), end.
CUR=""; CF=0
begin(){ CUR="$1"; CF=0; }
miss(){ CF=1; echo "  - $CUR: $1"; }
end(){ if [ "$CF" -eq 0 ]; then echo "$OK $CUR"; else echo "$NO $CUR"; FAIL=1; fi; }
run(){ guard python3 "$S/intake.py" "$@" > "$T/out" 2> "$T/err"; RC=$?
  if grep -q Traceback "$T/err"; then miss "Traceback in stderr: $*"; fi; }
# want RC ARGS...: the exit code; a failing run prints only delixcrew lines on stderr; check prints nothing on exit 0.
want(){ local w="$1"; shift; run "$@"
  [ "$RC" -eq "$w" ] || miss "exit $RC, want $w: $*"
  if [ "$w" -ne 0 ]; then
    if [ ! -s "$T/err" ] || grep -qv '^delixcrew: ' "$T/err"; then miss "stderr is not delixcrew lines: $*"; fi
  elif [ "$1" = check ] && { [ -s "$T/out" ] || [ -s "$T/err" ]; }; then
    miss "check printed something on exit 0"
  fi; }
mk(){ python3 "$T/mk.py" "$1" "$2" || miss "fixture not written: $2"; }
c0(){ mk "$F" "$1"; want 0 check --file "$F"; }
c2(){ mk "$F" "$1"; want 2 check --file "$F"; }
c8(){ mk "$F" "$1"; want 8 check --file "$F"; }
erris(){ [ "$(cat "$T/err")" = "$1" ] || miss "stderr is not exactly [$1]: [$(head -3 "$T/err" | tr '\n' '|')]"; }
outis(){ [ "$(cat "$T/out")" = "$1" ] || miss "stdout is not exactly [$1]: [$(head -3 "$T/out" | tr '\n' '|')]"; }
noout(){ [ ! -s "$T/out" ] || miss "stdout is not empty"; }

# mk.py OUT EXPR: writes the value of EXPR to OUT; bytes as they are, a str as ASCII text, anything else as JSON.
cat > "$T/mk.py" <<'PY'
import copy, json, sys

BASE = {"id": "I001", "title": "Start skill misses a step", "refs": ["F012"],
        "evidence": {"gate_open": False, "misleading_doc": False, "blocks_flow": False, "against_principle": False,
                     "reproduced": "main@2464805", "covered_by": None},
        "decision": "defer", "basis": "table", "reason": "One event so far.", "consent": None, "work": None}


def item(id="I001", ev=None, drop=(), extra=None, evdrop=(), **kw):
    it = copy.deepcopy(BASE)
    it["id"] = id
    it["evidence"].update(ev or {})
    it.update(kw)
    for k in drop:
        del it[k]
    for k in evdrop:
        del it["evidence"][k]
    it.update(extra or {})
    return it


def undecided(id="I001", **kw):
    args = {"decision": None, "basis": None, "reason": None}
    args.update(kw)
    return item(id, **args)


def consent(d, t, e=1, at="2026-11-21T10:00:00Z"):
    return {"decision": d, "table": t, "events": e, "at": at}


def doc(*items):
    return {"version": 1, "items": list(items)}


def with_byte(d, mark, b):
    """The JSON of d with the ASCII mark replaced by the raw bytes b."""
    return json.dumps(d, ensure_ascii=True).encode("ascii").replace(mark.encode("ascii"), b)


RAW = {"big": json.dumps(doc(), ensure_ascii=True).encode("ascii") + b" " * (1 << 20),
       "bad": b'{"version": 1, "items": [}',
       "dup": b'{"version": 1, "items": [], "items": []}',
       "nan": b'{"version": NaN, "items": []}',
       "deep": b"[" * 100000 + b"]" * 100000}
v = eval(sys.argv[2], {"item": item, "undecided": undecided, "consent": consent, "doc": doc, "with_byte": with_byte,
                       "RAW": RAW})
if not isinstance(v, bytes):
    v = (v if isinstance(v, str) else json.dumps(v, ensure_ascii=True)).encode("ascii")
with open(sys.argv[1], "wb") as f:
    f.write(v)
PY

# snap.py DIR: every path under DIR with its mode, size, mtime and sha256 (L7).
cat > "$T/snap.py" <<'PY'
import hashlib, os, sys

top = sys.argv[1]
for root, dirs, files in os.walk(top):
    dirs.sort()
    for n in sorted(dirs + files):
        p = os.path.join(root, n)
        st = os.lstat(p)
        h = "-"
        if os.path.isfile(p):
            with open(p, "rb") as f:
                h = hashlib.sha256(f.read()).hexdigest()
        print(os.path.relpath(p, top), oct(st.st_mode), st.st_size, st.st_mtime_ns, h)
PY

# t1.py SCRIPTS: intake.table() through a Python import (T1).
cat > "$T/t1.py" <<'PY'
import sys

sys.path.insert(0, sys.argv[1])
import intake  # noqa: E402


def it(refs=1, **ev):
    e = {"gate_open": False, "misleading_doc": False, "blocks_flow": False, "against_principle": False,
         "reproduced": "main@2464805", "covered_by": None}
    e.update(ev)
    return {"refs": ["F%03d" % (100 + n) for n in range(refs)], "evidence": e}


CASES = [
    ("row 1 covered_by", it(covered_by="K5"), "duplicate"),
    ("row 2 reproduced no", it(reproduced="no"), "needs-info"),
    ("row 2 reproduced not-tried", it(reproduced="not-tried"), "needs-info"),
    ("row 3 gate_open", it(gate_open=True), "accept"),
    ("row 3 misleading_doc", it(misleading_doc=True), "accept"),
    ("row 4 against_principle", it(against_principle=True), "wontfix"),
    ("row 5 blocks_flow, 2 refs", it(2, blocks_flow=True), "accept"),
    ("row 6 3 refs", it(3), "accept"),
    ("row 7 the rest, 2 refs", it(2), "defer"),
    ("order covered_by + gate_open", it(covered_by="K5", gate_open=True), "duplicate"),
    ("order no + gate_open", it(reproduced="no", gate_open=True), "needs-info"),
    ("order misleading_doc + against_principle", it(misleading_doc=True, against_principle=True), "accept"),
    ("count blocks_flow, 1 ref", it(1, blocks_flow=True), "defer"),
    ("count blocks_flow, 2 refs", it(2, blocks_flow=True), "accept"),
    ("count blocks_flow, 3 refs", it(3, blocks_flow=True), "accept"),
]
bad = 0
for name, case, want in CASES:
    got = intake.table(case)
    if got != want:
        bad += 1
        print("  - T1: %s: %s, want %s" % (name, got, want))
sys.exit(1 if bad else 0)
PY

begin "S1 a ref in two items names the first holder"
c2 'doc(item(), item("I004", refs=["F012"]))'
erris "delixcrew: intake: I001: ref F012 is also in I004"
end

begin "S2 a title with a path, e-mail, host, Cc, invisible or NFKC-changed character"
for t in 'Fails on /srv/data/x' 'Mail ops@acme.io' 'Breaks on build.acme.io' 'Bell \u0007 here' 'Zero\u200bwidth' \
         'Full \uff21 width'; do
  c2 "doc(item(title=\"$t\"))"
done
c0 'doc(item(title="Start skill reads ~/.claude"))'
end

begin "S3 #36 as a ref"
c2 'doc(item(refs=["#36"]))'
end

begin "S4 no file is an empty record"
cd "$T/empty" || miss "cd"
want 0 check
want 0 list; outis "no intake items"
want 0 list --pending; outis "no pending intake items"
want 2 show I001; erris "delixcrew: intake: I001: no such item"
cd "$ROOT" || miss "cd"
want 0 check --file "$T/missing.json"
want 0 check --file "$ROOT/templates/intake.json"
want 0 list --file "$ROOT/templates/intake.json"; outis "no intake items"
end

begin "S5 an unreadable file: over 1 MiB, bad byte, bad JSON, repeated key, NaN, deep, directory, FIFO"
for e in 'RAW["big"]' 'with_byte(doc(item(title="Bad X byte")), "X", b"\xff")' 'RAW["bad"]' 'RAW["dup"]' \
         'RAW["nan"]' 'RAW["deep"]'; do
  c2 "$e"
done
want 2 check --file "$T/fx"
mkfifo "$T/fifo" && want 2 check --file "$T/fifo"
mk "$F" 'RAW["dup"]'
want 2 list --file "$F"; noout
want 2 show I001 --file "$F"; noout
end

begin "S6 missing and extra keys at every level, version 2 and \"1\""
c2 '{"version": 1}'
c2 '{"version": 1, "items": [], "x": 1}'
c2 'doc(item(drop=["work"]))'
c2 'doc(item(extra={"x": 1}))'
c2 'doc(item(evdrop=["covered_by"]))'
c2 'doc(item(ev={"x": True}))'
c2 'doc(item(decision="wontfix", basis="maintainer", consent={"decision": "wontfix", "table": "defer", "events": 1}))'
c2 'doc(item(decision="wontfix", basis="maintainer", consent=dict(consent("wontfix", "defer"), x=1)))'
c2 '{"version": 2, "items": []}'
c2 '{"version": "1", "items": []}'
end

begin "S7 gate_open 1, consent.events true, title 5"
c2 'doc(item(ev={"gate_open": 1}))'
c2 'doc(item(decision="wontfix", basis="maintainer", consent=consent("wontfix", "defer", True)))'
c2 'doc(item(title=5))'
end

begin "S8 patterns: bad id, ref, reproduced, covered_by, work, at; the five ref forms"
c2 'doc(item("I0001"))'
c2 'doc(item("I00\u0661"))'
c2 'doc(item(refs=["F12"]))'
c2 'doc(item(refs=["F012\n"]))'
c2 'doc(item(refs=["T001.R"]))'
c2 'doc(item(refs=["lead.2026-11-21.x"]))'
c2 'doc(item(refs=["k5"]))'
c2 'doc(item(ev={"reproduced": "main@ABC1234"}))'
c2 'doc(item(ev={"reproduced": "main@abc123"}))'
c2 'doc(item(ev={"covered_by": "F012"}))'
c2 'doc(item(work="T1"))'
c2 'doc(item(work="spec AB"))'
c2 'doc(item(decision="wontfix", basis="maintainer", consent=consent("wontfix", "defer", 1, "2026-11-21 10:00:00Z")))'
c0 'doc(item(refs=["F0123"]), item("I002", refs=["K5"]), item("I003", refs=["T001.R2.1"]),
        item("I004", refs=["C.close"]), item("I005", refs=["lead.2026-11-21.2"]))'
end

begin "S9 title 0, 121 and 120 characters; reason 301 and 300"
c2 'doc(item(title=""))'
c2 'doc(item(title="A" * 121))'
c0 'doc(item(title="A" * 120))'
c2 'doc(item(reason="B" * 301))'
c0 'doc(item(reason="B" * 300))'
end

begin "S10 decision null with basis; decision set with reason null"
c2 'doc(undecided(basis="table"))'
c2 'doc(item(reason=None))'
end

begin "S11 a reason with an e-mail"
c2 'doc(item(reason="Mail ops@acme.io about it."))'
end

begin "S12 extra_terms and origin_terms from a feedback queue (K417, K426)"
mkdir -p "$T/fb2" "$T/fb3"
mk "$T/fb2/config.json" '{"enabled": False, "extra_terms": ["zorblat"]}'
mk "$T/fb3/F001.json" '{"origin_terms": ["quuxcorp"]}'
export DELIXCREW_FEEDBACK_DIR="$T/fb2"; c2 'doc(item(title="Zorblat build breaks"))'
export DELIXCREW_FEEDBACK_DIR="$T/fb"; c0 'doc(item(title="Zorblat build breaks"))'
export DELIXCREW_FEEDBACK_DIR="$T/fb3"; c2 'doc(item(title="Quuxcorp build breaks"))'
export DELIXCREW_FEEDBACK_DIR="$T/fb"; c0 'doc(item(title="Quuxcorp build breaks"))'
end

begin "S13 a shape error and a rule error: exit 2, no rule line"
c2 'doc(item(title=5), item("I002", refs=["F013"], decision="accept", ev={"misleading_doc": True}))'
[ "$(wc -l < "$T/err" | tr -d ' ')" = 1 ] || miss "want one stderr line"
grep -q '^delixcrew: intake: I001: ' "$T/err" || miss "the line is not for I001"
end

begin "S14 a ref and a title of 500 000 characters, inside the guard"
c2 'doc(item(refs=["F" + "1" * 499999]))'
c2 'doc(item(title="A" * 500000))'
end

begin "T1 table() rows 1 to 7, row order and event counts"
guard python3 "$T/t1.py" "$S" > "$T/out" 2> "$T/err"; rc=$?
cat "$T/out"
[ "$rc" -eq 0 ] || miss "t1.py exit $rc: $(head -3 "$T/err" | tr '\n' '|')"
end

begin "T2 a deferred item with a third ref differs from the table"
c0 'doc(item(refs=["F012", "F013"]))'
c8 'doc(item(refs=["F012", "F013", "F014"]))'
erris "delixcrew: intake: I001: decision defer differs from the table (accept); $NULLS"
end

begin "T3 basis maintainer, decision off the table, matching consent"
c0 'doc(item(decision="wontfix", basis="maintainer", consent=consent("wontfix", "defer")))'
end

begin "C1 accept without consent"
c8 'doc(item(decision="accept", ev={"misleading_doc": True}))'
erris "delixcrew: intake: I001: needs the maintainer's \"accept I001\" in chat"
end

begin "C2 wontfix without consent"
c8 'doc(item(decision="wontfix", ev={"against_principle": True}))'
erris "delixcrew: intake: I001: needs the maintainer's \"wontfix I001\" in chat"
end

begin "C3 gate_open duplicate by the table without consent"
c8 'doc(item(decision="duplicate", ev={"gate_open": True, "covered_by": "K5"}))'
erris "delixcrew: intake: I001: needs the maintainer's \"duplicate I001\" in chat"
end

begin "C4 basis maintainer without consent"
c8 'doc(item(basis="maintainer"))'
erris "delixcrew: intake: I001: needs the maintainer's \"defer I001\" in chat"
end

begin "C5 consent for wontfix, decision accept"
c8 'doc(item(decision="accept", ev={"misleading_doc": True}, consent=consent("wontfix", "accept")))'
erris "delixcrew: intake: I001: consent is for wontfix/accept/1, the item is now accept/accept/1; $NULLS"
end

begin "C6 consent.table differs from the table"
c8 'doc(item(decision="accept", ev={"misleading_doc": True}, consent=consent("accept", "defer")))'
erris "delixcrew: intake: I001: consent is for accept/defer/1, the item is now accept/accept/1; $NULLS"
end

begin "C7 a second ref after the maintainer's consent"
c8 'doc(item(decision="wontfix", basis="maintainer", refs=["F012", "F013"], consent=consent("wontfix", "defer")))'
erris "delixcrew: intake: I001: consent is for wontfix/defer/1, the item is now wontfix/defer/2; $NULLS"
end

begin "C8 gate_open accept without work or covered_by; control with work"
c8 'doc(item(decision="accept", ev={"gate_open": True}, consent=consent("accept", "accept")))'
erris "delixcrew: intake: I001: a gate_open item needs work or covered_by (K418)"
c0 'doc(item(decision="accept", ev={"gate_open": True}, consent=consent("accept", "accept"), work="T070"))'
end

begin "C9 duplicate, defer and needs-info by the table pass without consent"
c0 'doc(item(decision="duplicate", ev={"covered_by": "K5"}), item("I002", refs=["F013"]),
        item("I003", refs=["F014"], decision="needs-info", ev={"reproduced": "no"}))'
end

begin "L1 list is sorted by id"
mk "$F" 'doc(undecided("I003", refs=["F014"], title="Third title"), item(),
             item("I002", refs=["F013", "F015"], title="Second title", decision="accept", ev={"misleading_doc": True},
                  consent=consent("accept", "accept", 2), work="T070"))'
want 0 list --file "$F"
outis "$(printf '%s\n' 'I001  defer  1  -  Start skill misses a step' 'I002  accept  2  T070  Second title' \
                      'I003  -  1  -  Third title')"
end

begin "L2 list --pending: undecided, needs-info, unstarted accept"
mk "$F" 'doc(undecided(title="Undecided item"),
             item("I002", refs=["F013"], title="Needs info item", decision="needs-info", ev={"reproduced": "no"}),
             item("I003", refs=["F014"], title="Accepted item", decision="accept", ev={"misleading_doc": True},
                  consent=consent("accept", "accept")),
             item("I004", refs=["F015"], title="Started item", decision="accept", ev={"misleading_doc": True},
                  consent=consent("accept", "accept"), work="T070"),
             item("I005", refs=["F016"], title="Deferred item"),
             item("I006", refs=["F017"], title="Duplicate item", decision="duplicate", ev={"covered_by": "K5"}),
             item("I007", refs=["F018"], title="Wontfix item", decision="wontfix", basis="maintainer",
                  consent=consent("wontfix", "defer")))'
want 0 list --pending --file "$F"
outis "$(printf '%s\n' 'I001  -  1  -  Undecided item' 'I002  needs-info  1  -  Needs info item' \
                      'I003  accept  1  -  Accepted item')"
end

begin "L3 show prints the 18 lines"
mk "$F" 'doc(item(), item("I002", refs=["F013", "F014"], title="Two refs now", decision="wontfix", basis="maintainer",
                       reason="Against a principle.", ev={"blocks_flow": True}, consent=consent("wontfix", "accept", 2),
                       work="T070"))'
want 0 show I001 --file "$F"
outis "$(printf '%s\n' 'id: I001' 'title: Start skill misses a step' 'refs: F012' 'evidence.gate_open: false' \
  'evidence.misleading_doc: false' 'evidence.blocks_flow: false' 'evidence.against_principle: false' \
  'evidence.reproduced: main@2464805' 'evidence.covered_by: -' 'decision: defer' 'basis: table' \
  'reason: One event so far.' 'consent.decision: -' 'consent.table: -' 'consent.events: -' 'consent.at: -' 'work: -' \
  'table: defer')"
[ "$(wc -l < "$T/out" | tr -d ' ')" = 18 ] || miss "I001 is not 18 lines"
want 0 show I002 --file "$F"
outis "$(printf '%s\n' 'id: I002' 'title: Two refs now' 'refs: F013, F014' 'evidence.gate_open: false' \
  'evidence.misleading_doc: false' 'evidence.blocks_flow: true' 'evidence.against_principle: false' \
  'evidence.reproduced: main@2464805' 'evidence.covered_by: -' 'decision: wontfix' 'basis: maintainer' \
  'reason: Against a principle.' 'consent.decision: wontfix' 'consent.table: accept' 'consent.events: 2' \
  'consent.at: 2026-11-21T10:00:00Z' 'work: T070' 'table: accept')"
end

begin "L4 show: a bad id, a path, an unknown id, a shape error elsewhere"
mk "$F" 'doc(item())'
want 2 show I1 --file "$F"; erris "delixcrew: intake: show needs an id like I001"
want 2 show ../x --file "$F"; erris "delixcrew: intake: show needs an id like I001"
if grep -qF '../x' "$T/err"; then miss "the argument is echoed"; fi
want 2 show I009 --file "$F"; erris "delixcrew: intake: I009: no such item"
mk "$F" 'doc(item(), item("I002", refs=["F013"], title=5))'
want 2 show I001 --file "$F"; noout
want 2 list --file "$F"; noout
end

begin "L5 show --require accepted"
mk "$F" 'doc(undecided(), undecided("I002", refs=["F013"], work="T070"),
             item("I003", refs=["F014"], decision="accept", ev={"misleading_doc": True}),
             item("I004", refs=["F015"]),
             item("I005", refs=["F016"], decision="accept", ev={"misleading_doc": True},
                  consent=consent("accept", "accept")),
             item("I006", refs=["F017"], decision="accept", ev={"misleading_doc": True},
                  consent=consent("accept", "accept"), work="T071"))'
want 8 show I004 --require accepted --file "$F"; erris "delixcrew: I004 is defer; $START"; noout
want 8 show I001 --require accepted --file "$F"; erris "delixcrew: I001 is undecided; $START"; noout
want 8 show I002 --require accepted --file "$F"; erris "delixcrew: I002 is already started as T070; $START"
want 8 show I003 --require accepted --file "$F"; erris "delixcrew: I003 is accept; $START"
want 8 show I006 --require accepted --file "$F"; erris "delixcrew: I006 is already started as T071; $START"
want 0 show I005 --file "$F"; cp "$T/out" "$T/show"
want 0 show I005 --require accepted --file "$F"
cmp -s "$T/out" "$T/show" || miss "stdout is not the show output"
[ -s "$T/show" ] || miss "empty show output"
[ ! -s "$T/err" ] || miss "stderr on exit 0"
end

begin "L6 two rule errors: two lines, exit 8"
c8 'doc(item(decision="accept", ev={"misleading_doc": True}),
        item("I002", refs=["F013"], decision="accept", ev={"gate_open": True}, consent=consent("accept", "accept")))'
erris "$(printf '%s\n' "delixcrew: intake: I001: needs the maintainer's \"accept I001\" in chat" \
                      'delixcrew: intake: I002: a gate_open item needs work or covered_by (K418)')"
end

begin "L7 no forbidden names; every command leaves the fixture directory unchanged"
n="$(grep -cE 'subprocess|socket|urllib|eval\(|exec\(|os\.replace|write_json' "$S/intake.py")"
[ "$n" = 0 ] || miss "forbidden names: [$n]"
D="$T/l7"; mkdir -p "$D/docs/delix"
mk "$D/docs/delix/intake.json" 'doc(item(), item("I002", refs=["F013"], decision="accept", ev={"misleading_doc": True},
                                                 consent=consent("accept", "accept")))'
mk "$D/rule.json" 'doc(item(decision="accept", ev={"misleading_doc": True}))'
mk "$D/shape.json" 'doc(item(title=5))'
python3 "$T/snap.py" "$D" > "$T/before"
cd "$D" || miss "cd"
for a in check list "list --pending" "show I002" "show I002 --require accepted"; do
  # shellcheck disable=SC2086
  run $a; run $a --file rule.json; run $a --file shape.json
done
cd "$ROOT" || miss "cd"
python3 "$T/snap.py" "$D" > "$T/after"
cmp -s "$T/before" "$T/after" || miss "the fixture directory changed"
[ "$(wc -l < "$T/before" | tr -d ' ')" = 5 ] || miss "the snapshot does not list the 5 paths"
end

if [ -e "$ROOT/docs/delix/intake.json" ]; then
  begin "R1 live record: check exits 0"
  want 0 check --file "$ROOT/docs/delix/intake.json"
  end
else
  echo "$OK R1 live record: none yet"
fi

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
