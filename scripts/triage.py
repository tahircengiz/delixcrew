#!/usr/bin/env python3
"""delixcrew triage: clean read of GitHub issues → recorded decision → applied from the user's own terminal
(SPEC docs/delix/SPEC.md REQ-1, REQ-2, REQ-5, REQ-6, REQ-8).

Usage:
    python3 triage.py show <n> [--require accepted]
    python3 triage.py index
    python3 triage.py record <n>                   # decision JSON on stdin
    python3 triage.py preview <n>
    python3 triage.py apply <n> --confirm <hash>   # only from your own terminal; asks for APPLY <hash>

Records: $DELIXCREW_TRIAGE_DIR (default ~/.claude/delixcrew/triage). Stdlib only; helpers come from feedback.py (K115).
Exit codes: 0 ok · 2 usage/schema/no record · 4 BLOCKED · 5 hash mismatch · 6 not confirmed on a TTY · 7 repo/gh error ·
8 not accepted / changed since accepted.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import feedback  # noqa: E402
from feedback import (GH_SCRUB, OPAQUE_RE, REPO, SANITIZER_VERSION, bad_char, err, gh, gitleaks,  # noqa: E402
                      load_config, local_terms, now, read_json, repo_ok, sanitize, term_regex, write_json)

OWNER = REPO.split("/")[0]
DECISIONS = {"accept": "accepted", "needs-info": "needs-info", "duplicate": "duplicate", "wontfix": "wontfix",
             "defer": "deferred"}
LABEL_ORDER = ("accepted", "needs-info", "duplicate", "wontfix", "deferred")
LABEL_DEFS = {"accepted": ("0e8a16", "Triaged: accepted"), "needs-info": ("fbca04", "Triaged: more information needed"),
              "deferred": ("c5def5", "Triaged: deferred"),
              "duplicate": ("cfd3d7", "This issue or pull request already exists"),
              "wontfix": ("ffffff", "This will not be worked on")}
CLOSES = ("duplicate", "wontfix")  # K116
MAINTAINER = ("OWNER", "MEMBER", "COLLABORATOR")
INPUT_FIELDS = ("issue_sha", "decision", "reason", "duplicate_of", "questions")
RECORD_FIELDS = INPUT_FIELDS + ("issue", "recorded_at", "status", "applied_at")
REASON_MAX, QUESTIONS_MAX, QUESTION_MAX = 1500, 5, 300
ISSUE_JSON = "title,body,state,url,author,labels,comments"  # K126: no top-level authorAssociation

MARKER_RE = re.compile(r"delixcrew-triage: (accept|needs-info|duplicate|wontfix|defer) ([0-9a-f]{12}) ([0-9a-f]{12})")
SHA_RE = re.compile(r"[0-9a-f]{12}")
HTML_COMMENT_RE = re.compile(r"<!--.*?(?:-->|\Z)", re.S)
HTML_RE = re.compile(r"<[A-Za-z/!]")
MENTION_RE = re.compile(r"(?<![\w.])@[A-Za-z0-9]")
COMMENT_MENTION_RE = re.compile(r"@[A-Za-z0-9]")
# K133: allowlist. Every character is a newline, L*, N*, P*, S* or Zs; minus these invisible ones (Hangul fillers,
# blank Braille). One emoji selector (U+FE0E/U+FE0F) may follow a visible So symbol (emoji such as U+2764).
INVISIBLE_IN_ALLOWED = {chr(c) for c in (0x115F, 0x1160, 0x3164, 0xFFA0, 0x2800)}
SELECTORS = (chr(0xFE0E), chr(0xFE0F))
CHAR_REF_RE = re.compile(r"&(#[0-9]+|#[xX][0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]*);")
VERSION_RE = re.compile(r"\bplugin[ \t]+([^\s,]+)")
SEMVER_RE = re.compile(r"\d+\.\d+\.\d+")


def triage_dir():
    return os.path.expanduser(os.environ.get("DELIXCREW_TRIAGE_DIR") or "~/.claude/delixcrew/triage")


def record_path(n):
    return os.path.join(triage_dir(), "%d.json" % n)


def gh_env():
    return {k: v for k, v in os.environ.items() if k not in GH_SCRUB}


class Cleaner:
    """REQ-1: first Cc (except newline and tab), Cf and Co, then HTML comments; counts both over every string."""

    def __init__(self):
        self.html = self.ctrl = 0

    def __call__(self, s):
        s = s if isinstance(s, str) else ""
        out = "".join(c for c in s if not bad_char(c))
        self.ctrl += len(s) - len(out)
        out, k = HTML_COMMENT_RE.subn("", out)
        self.html += k
        return out


def issue_sha(title, body):
    return hashlib.sha256((title + "\n" + body).encode("utf-8")).hexdigest()[:12]


def login(x):
    return str(x.get("login") or "") if isinstance(x, dict) else ""


def label_names(issue):
    return [str(x.get("name") or "") for x in issue.get("labels") or [] if isinstance(x, dict)]


def comments_of(issue):
    cs = issue.get("comments")
    return [c for c in cs if isinstance(c, dict)] if isinstance(cs, list) else []


def decision_of(names):
    return ",".join(x for x in LABEL_ORDER if x in names) or "none"


def last_line(body):
    return (body if isinstance(body, str) else "").replace("\r", "").rstrip("\n").split("\n")[-1]


def maintainer(c):
    return c.get("authorAssociation") in MAINTAINER


def triage_comment(comments):
    """REQ-8: the last maintainer comment whose last line is a marker → (index, match) or (-1, None)."""
    for i in range(len(comments) - 1, -1, -1):
        m = MARKER_RE.fullmatch(last_line(comments[i].get("body")))
        if m and maintainer(comments[i]):
            return i, m
    return -1, None


def view(n, fields):
    out, e = gh(["issue", "view", str(n), "--json", fields], gh_env())
    if e:
        return None, e
    try:
        d = json.loads(out)
    except ValueError:
        d = None
    return (d, None) if isinstance(d, dict) else (None, "unexpected issue view output")


def gh_failed(e):
    err("delixcrew triage: gh failed: " + e)
    return 7


# --- show / index ---------------------------------------------------------------
def cmd_show(args):
    n = args.n
    issue, e = view(n, ISSUE_JSON)
    if e:
        return gh_failed(e)
    cl = Cleaner()
    raw_labels = label_names(issue)
    url, state, author = cl(issue.get("url")), cl(issue.get("state")).lower(), cl(login(issue.get("author")))
    labels = [cl(x) for x in raw_labels]
    title, body = cl(issue.get("title")), cl(issue.get("body"))
    comments = comments_of(issue)
    shown = [(cl(login(c.get("author"))), cl(c.get("authorAssociation")), cl(c.get("body"))) for c in comments]
    sha = issue_sha(title, body)
    ti, m = triage_comment(comments)
    if args.require == "accepted":
        if "accepted" not in raw_labels or m is None or m.group(1) != "accept":
            err("issue #%d is not triaged as accepted; run /delixcrew:triage #%d" % (n, n))
            return 8
        if m.group(3) != sha:
            err("issue #%d changed since it was accepted; run /delixcrew:triage #%d" % (n, n))
            return 8
    v = VERSION_RE.search(body)
    version = v.group(1) if v and SEMVER_RE.fullmatch(v.group(1)) else "unknown"
    lines = ["url: " + url, "state: " + state, "author: " + author,
             "source: " + ("maintainer" if login(issue.get("author")) == OWNER else "external"),
             "labels: " + (",".join(labels) or "none"), "decision: " + decision_of(raw_labels),
             "reported-version: " + version, "issue-sha: " + sha,
             "removed: %d HTML comment(s), %d control character(s)" % (cl.html, cl.ctrl),
             "title: " + title, "---", body]
    for i, (who, assoc, text) in enumerate(shown):
        lines += ["--- comment by %s | %s%s" % (who, assoc, " (after triage, not reviewed)" if 0 <= ti < i else ""), text]
    print("\n".join(lines))
    return 0


def cmd_index(_args):
    out, e = gh(["issue", "list", "--state", "all", "--limit", "300", "--json", "number,state,labels,author,title"],
                gh_env())
    if e:
        return gh_failed(e)
    try:
        items = json.loads(out)
        rows = [(int(i["number"]), str(i.get("state") or "").lower(), decision_of(label_names(i)),
                 "maintainer" if login(i.get("author")) == OWNER else "external", i.get("title")) for i in items]
    except (ValueError, TypeError, KeyError, AttributeError):
        return gh_failed("unexpected issue list output")
    for n, state, decision, source, title in rows:
        cl = Cleaner()
        print("#%d %s %s %s %s" % (n, cl(state), decision, source, json.dumps(cl(title), ensure_ascii=False)))
    return 0


# --- record ---------------------------------------------------------------------
def is_int(x):
    return isinstance(x, int) and not isinstance(x, bool)


def validate(d, n, stored=False):
    """REQ-5 schema. stored=True also checks the fields record adds (read-back in preview/apply)."""
    if not isinstance(d, dict):
        return "record: must be a JSON object"
    for k in d:
        if k not in (RECORD_FIELDS if stored else INPUT_FIELDS):
            return "%s: unknown field" % k
    for k in ("issue_sha", "decision", "reason") + (("issue", "recorded_at", "status") if stored else ()):
        if k not in d:
            return "%s: missing required field" % k
    if not isinstance(d["issue_sha"], str) or not SHA_RE.fullmatch(d["issue_sha"]):
        return "issue_sha: must be 12 hex characters"
    if not isinstance(d["decision"], str) or d["decision"] not in DECISIONS:
        return "decision: must be one of %s" % ", ".join(DECISIONS)
    if not isinstance(d["reason"], str) or not d["reason"].strip():
        return "reason: must be a non-empty string"
    if len(d["reason"]) > REASON_MAX:
        return "reason: longer than %d characters" % REASON_MAX
    if d["decision"] == "duplicate":
        dup = d.get("duplicate_of")
        if not is_int(dup) or dup <= 0 or dup == n:
            return "duplicate_of: must be a positive issue number other than #%d" % n
    elif "duplicate_of" in d:
        return "duplicate_of: only for duplicate"
    if "questions" in d:
        q = d["questions"]
        if d["decision"] != "needs-info":
            return "questions: only for needs-info"
        if not isinstance(q, list) or not all(isinstance(x, str) for x in q):
            return "questions: must be a list of strings"
        if len(q) > QUESTIONS_MAX:
            return "questions: more than %d" % QUESTIONS_MAX
        if any(len(x) > QUESTION_MAX for x in q):
            return "questions: one is longer than %d characters" % QUESTION_MAX
    if stored:
        if not is_int(d["issue"]) or d["issue"] != n:
            return "issue: not #%d" % n
        if not isinstance(d["recorded_at"], str):
            return "recorded_at: must be a string"
        if d["status"] not in ("recorded", "applied"):
            return "status: must be recorded or applied"
        if "applied_at" in d and not isinstance(d["applied_at"], str):
            return "applied_at: must be a string"
    return None


def cmd_record(args):
    n = args.n
    try:
        d = json.loads(sys.stdin.read())
    except ValueError:
        err("error: stdin: invalid JSON")
        return 2
    problem = validate(d, n)
    if problem:
        err("error: " + problem)
        return 2
    issue, e = view(n, "title,body,state")
    if e:
        return gh_failed(e)
    if issue.get("state") != "OPEN":
        err("error: issue #%d is closed; nothing recorded" % n)
        return 2
    cl = Cleaner()
    if issue_sha(cl(issue.get("title")), cl(issue.get("body"))) != d["issue_sha"]:
        err("issue changed since show; triage again")
        return 2
    rec = {"issue": n}
    rec.update((k, d[k]) for k in INPUT_FIELDS if k in d)
    rec.update(recorded_at=now(), status="recorded")
    os.makedirs(triage_dir(), mode=0o700, exist_ok=True)
    write_json(record_path(n), rec)
    print("#%d recorded %s" % (n, d["decision"]))
    return 0


# --- preview / apply ------------------------------------------------------------
def load_record(n):
    """Returns (record or None if invalid, whether the file exists)."""
    path = record_path(n)
    if not os.path.exists(path):
        return None, False
    rec = read_json(path)
    return (rec if validate(rec, n, stored=True) is None else None), True


def visible(c):
    cat = unicodedata.category(c)
    return c == "\n" or cat == "Zs" or (cat[0] in "LNPS" and c not in INVISIBLE_IN_ALLOWED)


def invisible(text):
    """K133: True if text has a character outside the allowlist (one emoji selector after a visible So symbol passes)."""
    prev = None
    for c in text:
        if c in SELECTORS:
            if prev is None or unicodedata.category(prev) != "So" or not visible(prev):  # else a hidden-data channel
                return True
        elif not visible(c):
            return True
        prev = c
    return False


def actions(decision):
    label = DECISIONS[decision]
    return "ensure-label %s; comment; add-label %s; remove-labels %s; close %s" % (
        label, label, ",".join(x for x in LABEL_ORDER if x != label), "not-planned" if decision in CLOSES else "no")


def build(n, rec, live_sha):
    """Builds the comment in memory. Returns (comment without marker, marker line, BLOCKED reasons, 12-hex hash)."""
    decision, reason, questions = rec["decision"], rec["reason"], rec.get("questions") or []
    parts = ["**Triage: %s**" % decision, "", reason]
    if questions:
        parts += ["", "Questions:"] + ["%d. %s" % (i, q) for i, q in enumerate(questions, 1)]
    if decision == "duplicate":
        parts += ["", "Duplicate of #%d" % rec["duplicate_of"]]
    raw = "\n".join(parts)
    term_re = term_regex(set(load_config()["extra_terms"]) | local_terms())
    comment = sanitize(raw, term_re)
    reasons = []
    if live_sha != rec["issue_sha"]:
        reasons.append("issue changed since triage; triage again")
    for r in (gitleaks(unicodedata.normalize("NFKC", raw)), gitleaks(comment)):
        if r and r not in reasons:
            reasons.append(r)
    if any(bad_char(c) for c in raw + comment):
        reasons.append("unicode control character (Cc/Cf/Co)")
    if any(invisible(t) for t in (unicodedata.normalize("NFKC", raw), comment)):
        reasons.append("invisible character")
    if OPAQUE_RE.search(raw) or OPAQUE_RE.search(comment):
        reasons.append("opaque string of 32+ characters")
    if sanitize(comment, term_re) != comment:
        reasons.append("residual match after sanitizing")
    # K122: checked on the raw text (sanitize adds <redacted:…> placeholders) and on its NFKC form, which sanitize
    # publishes: fullwidth / small-form characters become @ and <.
    user = [y for x in [reason] + questions for y in (x, unicodedata.normalize("NFKC", x))]
    if any(HTML_RE.search(x) or "<!--" in x for x in user) or CHAR_REF_RE.search(comment):
        reasons.append("HTML in reason or questions")
    # K131: any "@" + ASCII alnum in the published comment, no lookbehind; emails are already <redacted:email> and no
    # placeholder contains "@" or "&".
    if any(MENTION_RE.search(x) for x in user) or COMMENT_MENTION_RE.search(comment):
        reasons.append("@mention in reason or questions")
    canon = json.dumps({"repo": REPO, "issue": n, "issue_sha": rec["issue_sha"], "decision": decision, "comment": comment,
                        "sanitizer_version": SANITIZER_VERSION}, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    h = hashlib.sha256(canon.encode("utf-8")).hexdigest()[:12]
    return comment, "delixcrew-triage: %s %s %s" % (decision, h, rec["issue_sha"]), reasons, h


def prepare(n):
    """Shared by preview and apply. Returns (exit code or None, record, url, comment, marker, hash)."""
    rec, exists = load_record(n)
    if not exists:
        err("error: no triage record for #%d; run record first" % n)
        return 2, None, None, None, None, None
    if rec is None:
        print("REPO: %s\nVERDICT: BLOCKED: invalid record" % REPO)
        return 4, None, None, None, None, None
    issue, e = view(n, "title,body,url")
    if e:
        return gh_failed(e), None, None, None, None, None
    cl = Cleaner()
    live = issue_sha(cl(issue.get("title")), cl(issue.get("body")))
    url = cl(issue.get("url"))
    comment, marker, reasons, h = build(n, rec, live)
    if reasons:
        # The comment is withheld: it may contain the very value that blocked it.
        print("REPO: %s\nISSUE: #%d %s\nACTIONS: %s\nVERDICT: BLOCKED: %s"
              % (REPO, n, url, actions(rec["decision"]), "; ".join(reasons)))
        return 4, None, None, None, None, None
    return None, rec, url, comment, marker, h


def cmd_preview(args):
    code, rec, url, comment, marker, h = prepare(args.n)
    if code is not None:
        return code
    print("REPO: %s\nISSUE: #%d %s\nACTIONS: %s\n---\n%s\n\n%s\n---\nVERDICT: CLEAN\nHASH: %s"
          % (REPO, args.n, url, actions(rec["decision"]), comment, marker, h))
    return 0


def cmd_apply(args):
    n = args.n
    # 1. fixed target repo
    if not repo_ok():
        err("delixcrew triage: plugin.json repository is not %s; refusing to apply" % feedback.REPO_URL)
        return 7
    # 2. build in memory; nothing is read from disk after this point
    code, rec, url, comment, marker, h = prepare(n)
    if code is not None:
        return code
    # 3. hash binding
    if h != args.confirm:
        err("content changed since preview; run preview again")
        return 5
    # 4. the user's own terminal
    if not sys.stdin.isatty():
        err("delixcrew triage: apply needs your own terminal (stdin is not a TTY); nothing applied")
        return 6
    decision = rec["decision"]
    label = DECISIONS[decision]
    published = comment + "\n\n" + marker
    print("REPO: %s\nISSUE: #%d %s\nACTIONS: %s\n---\n%s\n---" % (REPO, n, url, actions(decision), published))
    sys.stdout.write("Type APPLY %s to apply it: " % h)
    sys.stdout.flush()
    if sys.stdin.readline().strip() != "APPLY " + h:
        err("not confirmed; nothing applied")
        return 6
    # 5. one read, then each step writes only if needed (K112)
    env = gh_env()
    cur, e = view(n, "state,labels,comments")
    if e:
        return gh_failed(e)
    names = label_names(cur)

    def failed(k, name, e):
        err("delixcrew triage: step %d (%s) failed: %s" % (k, name, e))
        return 7

    if label not in names:
        out, e = gh(["label", "list", "--json", "name", "--limit", "1000"], env)
        if e:
            return failed(1, "ensure-label", e)
        try:
            existing = {x.get("name") for x in json.loads(out)}
        except (ValueError, TypeError, AttributeError):
            return failed(1, "ensure-label", "unexpected label list output")
        if label not in existing:
            color, desc = LABEL_DEFS[label]
            _, e = gh(["label", "create", label, "--color", color, "--description", desc], env)
            if e:
                return failed(1, "ensure-label", e)
    if not any(maintainer(c) and last_line(c.get("body")) == marker for c in comments_of(cur)):
        fd, tmp = tempfile.mkstemp(prefix="delixcrew-triage-", suffix=".md")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(published)
            _, e = gh(["issue", "comment", str(n), "--body-file", tmp], env)
        finally:
            os.unlink(tmp)
        if e:
            return failed(2, "comment", e)
    add = [] if label in names else ["--add-label", label]
    remove = [x for x in LABEL_ORDER if x != label and x in names]
    if add or remove:
        _, e = gh(["issue", "edit", str(n)] + add + (["--remove-label", ",".join(remove)] if remove else []), env)
        if e:
            return failed(3, "labels", e)
    if decision in CLOSES and cur.get("state") == "OPEN":
        _, e = gh(["issue", "close", str(n), "--reason", "not planned"], env)
        if e:
            return failed(4, "close", e)
    rec["status"], rec["applied_at"] = "applied", now()
    try:
        write_json(record_path(n), rec)
    except OSError as e:
        err("warning: triage is on GitHub but the local record was not updated (%s)" % type(e).__name__)
    print("#%d applied %s" % (n, decision))
    return 0


def issue_number(s):
    if not s.isdigit() or int(s) <= 0:
        raise argparse.ArgumentTypeError("must be a positive issue number")
    return int(s)


def main(argv=None):
    ap = argparse.ArgumentParser(prog="triage.py", description="delixcrew issue triage")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("show")
    p.add_argument("n", type=issue_number)
    p.add_argument("--require", choices=["accepted"])
    sub.add_parser("index")
    for name in ("record", "preview"):
        sub.add_parser(name).add_argument("n", type=issue_number)
    p = sub.add_parser("apply")
    p.add_argument("n", type=issue_number)
    p.add_argument("--confirm", required=True)
    args = ap.parse_args(argv)
    return {"show": cmd_show, "index": cmd_index, "record": cmd_record, "preview": cmd_preview,
            "apply": cmd_apply}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main())
