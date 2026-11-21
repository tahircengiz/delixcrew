#!/usr/bin/env python3
"""delixcrew intake record checker (Spec F REQ-1 to REQ-4). Read-only: it reads the record and, for the text filter,
the feedback queue (K426); it writes no file.

    python3 scripts/intake.py check | list [--pending] | show I<nnn> [--require accepted]   (each takes --file P)

The record is docs/delix/intake.json (relative to the current directory); a missing file is an empty record.
Exit 0 ok, 2 shape or usage, 8 rule. stderr: one line per error, `delixcrew: intake: <id|file>: <reason>`.
"""
import json
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import feedback  # noqa: E402

DEFAULT = os.path.join("docs", "delix", "intake.json")
EMPTY = {"version": 1, "items": []}
P = "delixcrew: intake: "
NULLS = "set decision, basis, reason and consent to null"
START = "only an accepted, unstarted item can be started (/delixcrew:intake decide)"

TOP_KEYS = ("version", "items")
ITEM_KEYS = ("id", "title", "refs", "evidence", "decision", "basis", "reason", "consent", "work")
EV_BOOLS = ("gate_open", "misleading_doc", "blocks_flow", "against_principle")
EV_KEYS = EV_BOOLS + ("reproduced", "covered_by")
CONSENT_KEYS = ("decision", "table", "events", "at")
DECISIONS = ("accept", "needs-info", "duplicate", "wontfix", "defer")  # scripts/triage.py:32-33
BASES = ("table", "maintainer")
TITLE_MAX, REASON_MAX, REF_MAX = 120, 300, 40

# Spec F section 4. One compiled pattern per form; no alternation inside one pattern and no nested quantifier.
ID_RE = re.compile(r"I[0-9]{3}", re.ASCII)
REF_RES = (re.compile(r"F[0-9]{3,}", re.ASCII), re.compile(r"K[0-9]+", re.ASCII),
           re.compile(r"T[0-9]{3}\.R[0-9]+(\.[0-9]+)?", re.ASCII), re.compile(r"[A-Z]\.close(\.[0-9]+)?", re.ASCII),
           re.compile(r"lead\.[0-9]{4}-[0-9]{2}-[0-9]{2}(\.[0-9]+)?", re.ASCII))
REPRODUCED_RES = (re.compile(r"main@[0-9a-f]{7,40}", re.ASCII), re.compile(r"no", re.ASCII),
                  re.compile(r"not-tried", re.ASCII))
COVERED_RES = (re.compile(r"K[0-9]+", re.ASCII), re.compile(r"T[0-9]{3}", re.ASCII), re.compile(r"#[0-9]+", re.ASCII))
WORK_RES = (re.compile(r"T[0-9]{3}", re.ASCII), re.compile(r"spec [A-Z]", re.ASCII))
AT_RE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z", re.ASCII)
NAME_RE = re.compile(r"[a-z_]{1,40}", re.ASCII)  # a key name safe to print


class Reject(ValueError):
    pass


def _pairs(pairs):
    out = {}
    for k, v in pairs:
        if k in out:
            raise Reject("a key is repeated in one object")
        out[k] = v
    return out


def _constant(name):
    raise Reject("NaN and Infinity are not JSON")


def read_record(path):
    """(record, None) or (None, reason). Like feedback.read_json: O_NONBLOCK, a regular file of at most JSON_MAX bytes,
    then strict UTF-8, no repeated key, no NaN, at most JSON_DEPTH levels. A missing file is the empty record."""
    try:
        fd = os.open(path, os.O_RDONLY | getattr(os, "O_NONBLOCK", 0))
    except FileNotFoundError:
        return dict(EMPTY, items=[]), None
    except (OSError, ValueError):
        return None, "cannot open the record"
    try:
        st = os.fstat(fd)
        if st.st_mode & 0o170000 != 0o100000:  # stat.S_ISREG
            return None, "not a regular file"
        if st.st_size > feedback.JSON_MAX:
            return None, "larger than 1 MiB"
        with os.fdopen(fd, "rb", closefd=False) as f:
            data = f.read(feedback.JSON_MAX + 1)
        if len(data) > feedback.JSON_MAX:
            return None, "larger than 1 MiB"
        text = data.decode("utf-8")
        obj = json.loads(text, object_pairs_hook=_pairs, parse_constant=_constant)
        if not feedback._shallow(obj):
            return None, "nested deeper than %d levels" % feedback.JSON_DEPTH
        return obj, None
    except UnicodeDecodeError:
        return None, "not UTF-8"
    except Reject as e:
        return None, str(e)
    except (OSError, ValueError, RecursionError, MemoryError):
        return None, "not valid JSON"
    finally:
        os.close(fd)


def term_re():
    """K426: the feedback module's term set when its queue holds config.json or an F<n>.json, else None (as in CI)."""
    try:
        names = os.listdir(feedback.queue_dir())
    except OSError:
        return None
    records, bad = feedback.load_records()
    if "config.json" not in names and not records and not bad:
        return None
    terms = set(feedback.load_config()["extra_terms"]) | feedback.local_terms()
    for r in records:
        terms.update(t for t in (r.get("origin_terms") or []) if isinstance(t, str))
    return feedback.term_regex(terms)


def public(t, tre):
    """K417: t passes the public text filter unchanged."""
    return (unicodedata.normalize("NFKC", t) == t and feedback.sanitize(t, tre) == t and not feedback.invisible(t)
            and not any(unicodedata.category(c) == "Cc" for c in t))


def text_ok(s, lo, hi, res):
    """A string of lo..hi characters that fullmatches one of the patterns."""
    return type(s) is str and lo <= len(s) <= hi and any(r.fullmatch(s) for r in res)


def one_of(s, values):
    return type(s) is str and s in values


def keys(obj, want, where, out):
    for k in want:
        if k not in obj:
            out.append(where + "missing key " + k)
    extra = [k for k in obj if k not in want]
    if extra:
        shown = [k for k in extra if type(k) is str and NAME_RE.fullmatch(k)]
        out.append(where + "unknown key" + (" " + ", ".join(shown) if len(shown) == len(extra) else ""))


def shape(rec, tre):
    """REQ-1: every shape error of the whole record, in file order, as stderr lines."""
    out = []
    if type(rec) is not dict:
        return [P + "file: the record is not a JSON object"]
    keys(rec, TOP_KEYS, P + "file: ", out)
    if "version" in rec and not (type(rec["version"]) is int and rec["version"] == 1):
        out.append(P + "file: version is not the integer 1")
    items = rec.get("items")
    if "items" in rec and type(items) is not list:
        out.append(P + "file: items is not a list")
    if type(items) is not list:
        return out
    ids, holders = {}, {}
    for n, it in enumerate(items, 1):
        if type(it) is not dict:
            out.append(P + "file: item %d: not a JSON object" % n)
            continue
        iid = it.get("id")
        valid = text_ok(iid, 4, 4, (ID_RE,))
        label = iid if valid else "item %d" % n
        w = P + (iid + ": " if valid else "file: item %d: " % n)
        keys(it, ITEM_KEYS, w, out)
        if "id" in it and not valid:
            out.append(w + "id is not like I001")
        if valid and iid in ids:
            out.append(w + "id is also used by item %d" % ids[iid])
        elif valid:
            ids[iid] = n
        if "title" in it and not (type(it["title"]) is str and 1 <= len(it["title"]) <= TITLE_MAX):
            out.append(w + "title is not a string of 1 to %d characters" % TITLE_MAX)
        elif "title" in it and not public(it["title"], tre):
            out.append(w + "title has a path, e-mail, host, term, invisible or control character, or is not NFKC")
        refs = it.get("refs")
        if "refs" in it and not (type(refs) is list and refs):
            out.append(w + "refs is not a non-empty list")
        elif "refs" in it:
            for m, ref in enumerate(refs, 1):
                if not text_ok(ref, 1, REF_MAX, REF_RES):
                    out.append(w + "ref %d is not F<nnn>, K<n>, T<nnn>.R<n>, <X>.close or lead.<date> (K416)" % m)
                elif ref in holders and holders[ref] == (w, label):
                    out.append(w + "ref %s is repeated" % ref)
                elif ref in holders:
                    out.append(holders[ref][0] + "ref %s is also in %s" % (ref, label))
                else:
                    holders[ref] = (w, label)
        ev = it.get("evidence")
        if "evidence" in it and type(ev) is not dict:
            out.append(w + "evidence is not a JSON object")
        elif "evidence" in it:
            keys(ev, EV_KEYS, w + "evidence: ", out)
            for k in EV_BOOLS:
                if k in ev and type(ev[k]) is not bool:
                    out.append(w + "evidence.%s is not true or false" % k)
            if "reproduced" in ev and not text_ok(ev["reproduced"], 2, 45, REPRODUCED_RES):
                out.append(w + "evidence.reproduced is not main@<hex>, no or not-tried")
            cov = ev.get("covered_by")
            if cov is not None and not text_ok(cov, 2, REF_MAX, COVERED_RES):
                out.append(w + "evidence.covered_by is not null, K<n>, T<nnn> or #<n>")
        decision = it.get("decision")
        if "decision" in it and decision is not None and not one_of(decision, DECISIONS):
            out.append(w + "decision is not null or one of " + ", ".join(DECISIONS))
        if "basis" in it and it["basis"] is not None and not one_of(it["basis"], BASES):
            out.append(w + "basis is not null, table or maintainer")
        reason = it.get("reason")
        if reason is not None and not (type(reason) is str and 1 <= len(reason) <= REASON_MAX):
            out.append(w + "reason is not null or a string of 1 to %d characters" % REASON_MAX)
        elif reason is not None and not public(reason, tre):
            out.append(w + "reason has a path, e-mail, host, term, invisible or control character, or is not NFKC")
        c = it.get("consent")
        if c is not None and type(c) is not dict:
            out.append(w + "consent is not null or a JSON object")
        elif c is not None:
            keys(c, CONSENT_KEYS, w + "consent: ", out)
            for k in ("decision", "table"):
                if k in c and not one_of(c[k], DECISIONS):
                    out.append(w + "consent.%s is not one of %s" % (k, ", ".join(DECISIONS)))
            if "events" in c and not (type(c["events"]) is int and c["events"] >= 1):
                out.append(w + "consent.events is not an integer of at least 1")
            if "at" in c and not text_ok(c["at"], 20, 20, (AT_RE,)):
                out.append(w + "consent.at is not YYYY-MM-DDTHH:MM:SSZ")
        if "work" in it and it["work"] is not None and not text_ok(it["work"], 4, 6, WORK_RES):
            out.append(w + "work is not null, T<nnn> or spec <X>")
        if "decision" in it and decision is None:
            for k in ("basis", "reason", "consent"):
                if it.get(k) is not None:
                    out.append(w + "decision is null, so %s must be null too" % k)
        elif "decision" in it:
            for k in ("basis", "reason"):
                if k in it and it[k] is None:
                    out.append(w + "decision is set, so %s must be set too" % k)
    return out


def table(item):
    """REQ-2: the decision the table gives (the first matching row); events = len(item["refs"])."""
    ev = item["evidence"]
    events = len(item["refs"])
    if ev["covered_by"] is not None:
        return "duplicate"
    if not ev["reproduced"].startswith("main@"):
        return "needs-info"
    if ev["gate_open"] or ev["misleading_doc"]:
        return "accept"
    if ev["against_principle"]:
        return "wontfix"
    if ev["blocks_flow"] and events >= 2:
        return "accept"
    if events >= 3:
        return "accept"
    return "defer"


def item_rules(it):
    """REQ-2 and REQ-3 errors of one item of a clean record."""
    out, w = [], P + it["id"] + ": "
    d, t, e, c = it["decision"], table(it), len(it["refs"]), it["consent"]
    if d is not None:
        if it["basis"] == "table" and d != t:
            out.append(w + "decision %s differs from the table (%s); %s" % (d, t, NULLS))
        if c is None and (d in ("accept", "wontfix") or it["evidence"]["gate_open"] or it["basis"] == "maintainer"):
            out.append(w + "needs the maintainer's \"%s %s\" in chat" % (d, it["id"]))
        if c is not None and (c["decision"] != d or c["table"] != t or c["events"] != e):
            out.append(w + "consent is for %s/%s/%d, the item is now %s/%s/%d; %s"
                       % (c["decision"], c["table"], c["events"], d, t, e, NULLS))
    if it["evidence"]["gate_open"] and it["work"] is None and it["evidence"]["covered_by"] is None:
        out.append(w + "a gate_open item needs work or covered_by (K418)")
    return out


def val(v):
    if v is None:
        return "-"
    if type(v) is bool:
        return "true" if v else "false"
    return str(v)


def show_lines(it):
    c = it["consent"] or {}
    return (["id: " + it["id"], "title: " + it["title"], "refs: " + ", ".join(it["refs"])]
            + ["evidence.%s: %s" % (k, val(it["evidence"][k])) for k in EV_KEYS]
            + ["%s: %s" % (k, val(it[k])) for k in ("decision", "basis", "reason")]
            + ["consent.%s: %s" % (k, val(c.get(k))) for k in CONSENT_KEYS]
            + ["work: " + val(it["work"]), "table: " + table(it)])


def pending(it):
    return it["decision"] in (None, "needs-info") or (it["decision"] == "accept" and it["work"] is None)


def parse(argv):
    """(command, path, id, pending, require) or None for a usage error."""
    path, pos, pend, req = DEFAULT, [], False, False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("--file", "--require"):
            if i + 1 >= len(argv):
                return None
            if a == "--file":
                path = argv[i + 1]
            elif argv[i + 1] == "accepted":
                req = True
            else:
                return None
            i += 2
            continue
        if a == "--pending":
            pend = True
        else:
            pos.append(a)
        i += 1
    if pos == ["check"] and not pend and not req:
        return "check", path, None, False, False
    if pos == ["list"] and not req:
        return "list", path, None, pend, False
    if pos[:1] == ["show"] and len(pos) <= 2 and not pend:
        return "show", path, (pos[1] if len(pos) == 2 else None), False, req
    return None


def main(argv):
    args = parse(argv)
    if args is None:
        print(P + "usage: intake.py check | list [--pending] | show I<nnn> [--require accepted]; each takes --file P",
              file=sys.stderr)
        return 2
    cmd, path, iid, pend, req = args
    if cmd == "show" and not text_ok(iid, 4, 4, (ID_RE,)):
        print(P + "show needs an id like I001", file=sys.stderr)  # the argument is never echoed
        return 2
    rec, why = read_record(path)
    if rec is None:
        print(P + "file: " + why, file=sys.stderr)
        return 2
    errors = shape(rec, term_re() if type(rec) is dict and rec.get("items") else None)
    if errors:
        for line in errors:
            print(line, file=sys.stderr)
        return 2
    items = sorted(rec["items"], key=lambda it: it["id"])
    if cmd == "check":
        errors = [line for it in rec["items"] for line in item_rules(it)]
        for line in errors:
            print(line, file=sys.stderr)
        return 8 if errors else 0
    if cmd == "list":
        rows = [it for it in items if pending(it)] if pend else items
        for it in rows:
            print("  ".join((it["id"], val(it["decision"]), str(len(it["refs"])), val(it["work"]), it["title"])))
        if not rows:
            print("no pending intake items" if pend else "no intake items")
        return 0
    found = [it for it in items if it["id"] == iid]
    if not found:
        print(P + iid + ": no such item", file=sys.stderr)
        return 2
    it = found[0]
    if req and (it["work"] is not None or it["decision"] != "accept" or item_rules(it)):
        x = ("already started as " + it["work"] if it["work"] is not None else
             "undecided" if it["decision"] is None else it["decision"])
        print("delixcrew: %s is %s; %s" % (iid, x, START), file=sys.stderr)
        return 8
    print("\n".join(show_lines(it)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
