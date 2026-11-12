#!/usr/bin/env python3
"""delix board: docs/delix/STATE.json + cards + worktree .delix/report.md → one Markdown table
(+ a "Verifications" table when STATE.json.verifications exists: card-less /delixcrew:verify records, K43)
(+ Spec C: Leads, Agents, Waiting on you, Ready to merge and Git actions from local git facts; no network,
the git actions are printed as commands for the user and never run).

Usage (in the project root):
    python3 board.py             # prints the table to stdout (writes no file)
    python3 board.py --write     # also regenerates docs/delix/BOARD.md (retro A8: off by default)
    python3 board.py --json      # raw data (for tests)
    python3 board.py --project <root>

Stdlib only. Read-only: writes docs/delix/BOARD.md only with --write. Agents take no commands from the board (spec §14).
"""
import argparse
import datetime as dt
import json
import os
import re
import stat
import subprocess
import sys
import time
import unicodedata

STATUS_RE = re.compile(r"\*\*Status:\*\*\s*([A-Z_]+)")
PR_RE = re.compile(r"\*\*PR:\*\*\s*#?(\d+)")
REPORT_STATUSES = ("DONE_WITH_CONCERNS", "DONE", "NEEDS_CONTEXT", "BLOCKED")
OPEN_STATUSES = {"open", "in_progress", "in_review", "fixing"}
# Spec C R10 (K248, K260): a command is printed only when every name in it passes its pattern (used with fullmatch)
BRANCH_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$")
PATH_RE = re.compile(r"^/[A-Za-z0-9_./-]+$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
WEEK = 604800
KIND_ORDER = ("push", "merge", "remove_worktree", "delete_branch")


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None


def read_json(path):
    m = read(path)
    if m is None:
        return None
    try:
        return json.loads(m)
    except ValueError as e:
        print(f"warning: {path} is not JSON ({e})", file=sys.stderr)
        return None


def worktrees(root):
    """`git worktree list --porcelain -z` → [(path, branch)]. Empty list without git, outside a repo or when a field
    holds a line break (K263)."""
    result, path, branch = [], None, ""
    for line in _worktree_text(root, 10).split("\n") + [""]:
        if line.startswith("worktree "):
            path, branch = line[len("worktree "):], ""
        elif line.startswith("branch "):
            branch = line[len("branch "):].replace("refs/heads/", "")
        elif line == "" and path:
            result.append((path, branch))
            path = None
    return result


def report_summary(text):
    """report.md → (status, pr, one-line summary)."""
    status = None
    m = STATUS_RE.search(text)
    if m:
        status = m.group(1)
    else:
        for s in REPORT_STATUSES:  # free form: 'NEEDS_CONTEXT: card unclear'
            if s in text:
                status = s
                break
    pr = None
    m = PR_RE.search(text)
    if m:
        pr = _num(m.group(1))
    # summary: first non-empty bullet under Concerns, else under Evidence, else the first plain line
    summary = ""
    for heading in ("## Concerns", "## Evidence"):
        i = text.find(heading)
        if i < 0:
            continue
        for line in text[i:].splitlines()[1:]:
            s = line.strip()
            if s.startswith("## "):
                break
            if s.startswith("- ") and s[2:].strip() not in ("", "…", "..."):
                summary = s[2:].strip()
                break
        if summary:
            break
    if not summary:
        for line in text.splitlines():
            s = line.strip()
            if s and not s.startswith("#") and not s.startswith("**"):
                summary = s
                break
    summary = re.sub(r"\s+", " ", summary).replace("|", "/")
    if len(summary) > 70:
        summary = summary[:67].rstrip() + "…"
    return status, pr, summary


def from_card_file(text):
    """role/tier/wave/status from the table row at the top of a task card (fallback when STATE lacks them)."""
    for line in text.splitlines():
        if line.startswith("| T") and line.count("|") >= 7:
            h = [x.strip() for x in line.strip("|").split("|")]
            return {"role": h[3], "tier": h[2], "wave": h[4], "status": h[5]}
    return {}


# ---- Spec C: git facts (rules G), derive (rules R), Markdown sections (format F) ----
STATE_REL = "docs/delix/STATE.json"
CARD_ID_RE = re.compile(r"T[0-9]{3}")
REPORT_PR_RE = re.compile(r"\*\*PR:\*\* #([0-9]+)")
PR_TEXT_RE = re.compile(r"^#?[0-9]+$")
DIGITS_RE = re.compile(r"[0-9]+")
APPROVED = "**🔐 Approved:**"
MAX_READ = 1048576  # §6: a spec or card file is read only up to 1 MiB
UNSAFE_BRANCHES = ("reset", "clean")  # REQ-4: never a command token


def _git(argv, cwd, timeout=5, codes=(0,)):
    """One git call (rules G) → (exit code, stdout); None on OSError, timeout, undecodable output or another exit.
    K263: never writes another worktree's index and never runs a core.fsmonitor program from the shared config."""
    argv = ["git", "--no-optional-locks", "-c", "core.fsmonitor=false", *argv[1:]]
    try:
        cp = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return None
    return (cp.returncode, cp.stdout) if cp.returncode in codes else None


def _out(argv, cwd, timeout=5):
    r = _git(argv, cwd, timeout)
    return None if r is None else r[1]


def _worktree_text(root, timeout):
    """§4 call 2: `worktree list --porcelain -z` in today's newline form; "" on failure or when any field holds a
    line break (the whole list is invalid, K263)."""
    fields = (_out(["git", "worktree", "list", "--porcelain", "-z"], root, timeout) or "").split("\0")
    if any("\n" in f or "\r" in f for f in fields):
        return ""
    return "\n".join(fields)


def _mtime(path):
    try:
        return int(os.stat(path).st_mtime)
    except (OSError, ValueError):
        return None


def _add_file(w, wt, rel):
    """files[rel] = text of <wt>/<rel>, only when it resolves inside <wt> to a regular file of at most 1 MiB
    (rules G, §6); a FIFO or a device is never opened."""
    if rel in w["files"]:
        return
    try:
        real = os.path.realpath(os.path.join(wt, rel))
        st = os.stat(real)
        inside = real.startswith(os.path.realpath(wt) + os.sep)
        text = read(real) if inside and stat.S_ISREG(st.st_mode) and st.st_size <= MAX_READ else None
    except (OSError, ValueError):  # missing, a NUL byte in a name taken from STATE.json, or a file that is not UTF-8
        text = None
    if text is not None:
        w["files"][rel] = text


def _add_lead_files(w, wt):
    """A Leads row's STATE.json, the spec it names and the card file of each open Tier 3 card (rules G)."""
    _add_file(w, wt, STATE_REL)
    s = _state(w)
    names = [s.get("spec")] + [c.get("file") for c in _dict(s.get("cards")).values()
                               if isinstance(c, dict) and _int(c.get("tier")) == 3 and c.get("status") == "open"]
    for rel in names:
        if isinstance(rel, str) and rel:
            _add_file(w, wt, rel)


def git_raw(root):
    """Rules G: every local fact derive() needs, gathered once. Reads only: no network, no writes."""
    root = os.path.realpath(root)
    cfg = read_json(os.path.join(root, "docs", "delix", "delix.json"))
    default = cfg.get("default_branch") if isinstance(cfg, dict) else None
    raw = {"default_branch": default if isinstance(default, str) and default else "main",
           "now": int(time.time()), "self": root, "source": root, "common_dir": None,
           "fetch_head_mtimes": {}, "trusted_state": None, "worktree_list": "", "for_each_ref": "", "worktrees": {}}
    common = _out(["git", "rev-parse", "--git-common-dir"], root)
    if common is None:
        return raw  # outside git
    common = os.path.realpath(os.path.join(root, common.strip()))
    raw["common_dir"] = common
    heads = [os.path.join(common, "FETCH_HEAD")]
    try:
        heads += [os.path.join(common, "worktrees", n, "FETCH_HEAD")
                  for n in sorted(os.listdir(os.path.join(common, "worktrees")))]
    except OSError:
        pass
    for p in heads:
        t = _mtime(p)
        if t is not None:
            raw["fetch_head_mtimes"][p] = t
    lines = []
    for line in _worktree_text(root, 10).split("\n"):
        if line.startswith("worktree "):
            line = "worktree " + os.path.realpath(line[len("worktree "):])
        lines.append(line)
    raw["worktree_list"] = "\n".join(lines)
    raw["for_each_ref"] = _out(["git", "for-each-ref", "refs/heads", "refs/remotes",
                                "--format=%(refname)%09%(objectname)%09%(upstream)%09"
                                "%(upstream:track,nobracket)%09%(committerdate:unix)"], root) or ""
    wts = raw["worktrees"]
    blocks = _blocks(raw["worktree_list"])
    for b in blocks:
        p = b["path"]
        w = wts.setdefault(p, {"status": None, "state_diff_exit": None, "state_log_ct": None,
                               "state_mtime": None, "files": {}})
        w["status"] = _out(["git", "status", "--porcelain"], p)
        _add_file(w, p, ".delix/card")
        _add_file(w, p, ".delix/report.md")
        if _card_id(w) is None and not _state_dirty(w["status"]):
            r = _git(["git", "diff", "--no-ext-diff", "--quiet", "origin/%s...HEAD" % raw["default_branch"], "--",
                      STATE_REL], p, codes=(0, 1))
            w["state_diff_exit"] = None if r is None else r[0]
    # the source STATE decides the roles (R4, R5c), so it is read even when the source is not a Leads row
    src = wts.setdefault(root, {"status": None, "state_diff_exit": None, "state_log_ct": None,
                                "state_mtime": None, "files": {}})
    _add_lead_files(src, root)
    by_values = _by_values(_state(src))
    for i, b in enumerate(blocks):
        p, w = b["path"], wts[b["path"]]
        if i and _role(w, b["branch"], by_values)[0] != "lead":
            continue
        _add_lead_files(w, p)
        if _state_dirty(w["status"]):
            w["state_mtime"] = _mtime(os.path.join(p, STATE_REL))
        else:
            w["state_log_ct"] = _num((_out(["git", "log", "-1", "--format=%ct", "--", STATE_REL], p) or "").strip())
    # §4 call 7 (R1, K262, K276): the origin/HEAD STATE, the only one that may make a card ready to merge
    raw["trusted_state"] = _out(["git", "--no-lazy-fetch", "cat-file", "blob",
                                 "refs/remotes/origin/HEAD:%s" % STATE_REL], root)
    return raw


# derive() and its helpers are pure: no subprocess, os, open or clock (Spec C REQ-6; the panel has the same rules).
def _dict(x):
    return x if isinstance(x, dict) else {}


def _list(x):
    return x if isinstance(x, list) else []


def _str(x):
    return x if isinstance(x, str) else ""


def _int(x):
    """A JSON integer (bool is not one); an integral float counts, as in JavaScript."""
    if isinstance(x, bool):
        return None
    if isinstance(x, int):
        return x
    if isinstance(x, float) and x.is_integer():
        return int(x)
    return None


def _num(s):
    """A string of ASCII digits → int, else None."""
    if not isinstance(s, str) or not DIGITS_RE.fullmatch(s):
        return None
    try:
        return int(s)
    except ValueError:  # more digits than int() converts
        return None


def _ok(rx, s):
    return isinstance(s, str) and rx.fullmatch(s) is not None


def _branch_ok(br):
    """R10 (REQ-4): a branch name a command may take; `reset` and `clean` never are."""
    return _ok(BRANCH_RE, br) and br not in UNSAFE_BRANCHES


def _latest(*values):
    known = [v for v in values if v is not None]
    return max(known) if known else None


def _blocks(text):
    """R2: `git worktree list --porcelain` → [{path, head, branch, detached}]; the first is the main checkout."""
    out, cur = [], {}
    for line in _str(text).split("\n") + [""]:
        if line == "":
            if "path" in cur:
                out.append({"path": cur["path"], "head": cur.get("head", ""), "branch": cur.get("branch"),
                            "detached": cur.get("detached", False)})
            cur = {}
        elif line.startswith("worktree "):
            cur["path"] = line[len("worktree "):]
        elif line.startswith("HEAD "):
            cur["head"] = line[len("HEAD "):]
        elif line.startswith("branch "):
            b = line[len("branch "):]
            cur["branch"] = b[len("refs/heads/"):] if b.startswith("refs/heads/") else b
        elif line == "detached":
            cur["detached"] = True
    return out


def _refs(text):
    """R2: for-each-ref lines with exactly 5 TAB fields → {refname: [refname, objectname, upstream, track, time]}."""
    return {f[0]: f for f in (line.split("\t") for line in _str(text).split("\n")) if len(f) == 5}


def _state(w):
    """R2: the STATE in a worktree's files; {} when it is missing or not a JSON object."""
    try:
        s = json.loads(_dict(_dict(w).get("files")).get(STATE_REL))
    except (TypeError, ValueError, RecursionError):
        return {}
    return s if isinstance(s, dict) else {}


def _state_dirty(status):
    """R5a: a status line whose text from index 3 is the STATE path."""
    return any(line[3:] == STATE_REL for line in _str(status).split("\n"))


def _card_id(w):
    m = CARD_ID_RE.search(_str(_dict(_dict(w).get("files")).get(".delix/card")))
    return m.group(0) if m else None


def _by_values(s):
    """R4: every `by` of every agents record."""
    return {a["by"] for c in _dict(s.get("cards")).values() if isinstance(c, dict)
            for a in _list(c.get("agents")) if isinstance(a, dict) and isinstance(a.get("by"), str)}


def _role(w, branch, by_values):
    """R5 → (role, card id or None)."""
    cid = _card_id(w)
    if cid:
        return "implementer " + cid, cid
    if _state_dirty(w.get("status")) or _int(w.get("state_diff_exit")) == 1 or branch in by_values:
        return "lead", None
    return "other", None


def _upstream(b, f):
    """R3: upstream text of a worktree block; f = its refs/heads line or None."""
    if b["branch"] is None:
        return "detached " + b["head"][:7] if b["detached"] else "?"
    if not f:
        return "?"
    if not f[2]:
        return "no upstream"
    t = f[3]
    if t in ("", "gone"):
        return "in sync" if t == "" else "gone"
    m = re.fullmatch(r"(ahead|behind) ([0-9]+)", t)
    if m:
        return "%s %s" % (m.group(2), m.group(1))
    m = re.fullmatch(r"ahead ([0-9]+), behind ([0-9]+)", t)
    return "%s ahead, %s behind" % m.groups() if m else "?"


def _short(upstream):
    return upstream[len("refs/remotes/"):] if upstream.startswith("refs/remotes/") else upstream


def _changed_at(w):
    """R9: state_mtime when the STATE is dirty (R5a), else state_log_ct."""
    return _int(w.get("state_mtime")) if _state_dirty(w.get("status")) else _int(w.get("state_log_ct"))


def _implementers(c):
    return [a for a in _list(c.get("agents")) if isinstance(a, dict) and a.get("role") == "implementer"]


def _review(c):
    """R6/R8: the latest qa/security round → (R, its records in list order, last qa, last security)."""
    recs = [a for a in _list(c.get("agents")) if isinstance(a, dict) and a.get("role") in ("qa", "security")
            and _int(a.get("round")) is not None]
    if not recs:
        return None, [], None, None
    r = max(_int(a.get("round")) for a in recs)
    last = [a for a in recs if _int(a.get("round")) == r]
    qa = [a for a in last if a.get("role") == "qa"]
    sec = [a for a in last if a.get("role") == "security"]
    return r, last, (qa[-1] if qa else None), (sec[-1] if sec else None)


def _pr(v):
    """R7: a positive int, or a string matching ^#?[0-9]+$ → int; else None (`merge <sha>` → None)."""
    n = _int(v)
    if n is not None:
        return n if n > 0 else None
    n = _num(v.lstrip("#")) if isinstance(v, str) and PR_TEXT_RE.fullmatch(v) else None
    return n if n else None


def _facts(cid, c, refs, card_wt):
    """R7: card facts; card_wt = card id → (block, worktree) of the first worktree whose card it is."""
    b, w = card_wt.get(cid, (None, {}))
    report = _str(_dict(w.get("files")).get(".delix/report.md"))
    pr = _pr(c.get("pr"))
    if pr is None:
        m = REPORT_PR_RE.search(report)
        pr = _num(m.group(1)) if m else None
    m = STATUS_RE.search(report)
    impl = _implementers(c)
    branch = impl[-1].get("branch") if impl else None
    if not isinstance(branch, str):
        branch = b["branch"] if b else None
    tip = refs.get("refs/remotes/origin/%s" % branch) if branch is not None else None
    tier = _int(c.get("tier"))
    return {"pr": pr, "report_status": m.group(1) if m else None, "branch": branch,
            "tip": tip[1] if tip else None, "tier": 2 if tier is None else tier}


def _queue(s, files, refs, card_wt, tr=None, default=""):
    """R8: waiting / ready / done of one STATE s; files = the files of that STATE's worktree.
    R8': tr = TR, the (card, pr, sha) that R8 marks Ready on the origin/<default> STATE; a Ready card outside it waits
    as `review not on origin/<default>`. tr is None only when TR itself is computed."""
    waiting, ready, done = [], [], []
    cards = _dict(s.get("cards"))
    for cid in sorted(cards):
        c = cards[cid]
        if not isinstance(c, dict):
            continue
        f = _facts(cid, c, refs, card_wt)
        st = _str(c.get("status"))
        qa, sec = _review(c)[2:]
        sha = qa.get("sha") if qa else None
        reviewed = (st == "in_review" and f["pr"] is not None and qa is not None
                    and qa.get("verdict") in ("ACCEPT", "ACCEPT_WITH_NOTES")
                    and (f["tier"] < 2 or (sec is not None and sec.get("verdict") in ("CLEAN", "🔐 HUMAN_APPROVAL"))))
        same_tip = isinstance(sha, str) and f["tip"] == sha
        reasons = []
        if reviewed and same_tip and (tr is None or (cid, f["pr"], sha) in tr):
            reasons.append("ready to merge")
            ready.append({"card": cid, "pr": f["pr"], "sha": sha})
        elif reviewed and same_tip:
            reasons.append("review not on origin/%s" % default)
        if st == "open" and f["tier"] == 3:
            text = files.get(c.get("file")) if isinstance(c.get("file"), str) else None
            if not isinstance(text, str) or not any(line.startswith(APPROVED) for line in text.split("\n")):
                reasons.append("tier 3 approval")
        if f["report_status"] in ("NEEDS_CONTEXT", "BLOCKED") and st in OPEN_STATUSES:
            reasons.append(f["report_status"].lower())
        if st == "escalated":
            reasons.append("escalated")
        if reviewed and not same_tip:
            reasons.append("changed after review")
        if st == "in_review" and f["pr"] is not None and not _list(c.get("agents")):
            reasons.append("no review record")
        waiting += [{"card": cid, "verification": None, "reason": r} for r in reasons]
        if st == "accepted":
            done.append({"card": cid, "pr": f["pr"]})
    for v in _list(s.get("verifications")):
        if isinstance(v, dict) and _str(v.get("verdict")).startswith("FIX") and not _str(v.get("resolution")):
            waiting.append({"card": None, "verification": v.get("name"), "reason": "verification FIX"})
    return {"waiting": waiting, "ready": ready, "done": done}


def _action(kind, target, card, command, safe, uncommitted=0):
    """R10: one action; a dirty worktree or a name that fails its pattern gets a note instead of a command."""
    if uncommitted != 0:
        command, note = None, "uncommitted %s files: commit or discard in its session" % uncommitted
    elif not safe:
        command, note = None, "unsafe name: run by hand"
    else:
        note = ""
    return {"kind": kind, "target": target, "card": card, "command": command, "note": note}


def derive(raw):
    """Rules R (Spec C REQ-6): raw git facts → {agents, leads, queue, actions, fetched_at}. Pure; never raises.
    tests/fixtures/board_parity.json pins the result for this and for the panel's copy of the rules."""
    raw = _dict(raw)
    default = _str(raw.get("default_branch"))
    now = _int(raw.get("now"))
    self_path, source = _str(raw.get("self")), _str(raw.get("source"))
    wts = _dict(raw.get("worktrees"))
    refs = _refs(raw.get("for_each_ref"))
    blocks = _blocks(raw.get("worktree_list"))
    src = _state(wts.get(source))
    src_cards = _dict(src.get("cards"))
    by_values = _by_values(src)
    trusted = _state({"files": {STATE_REL: raw.get("trusted_state")}})  # R8' T: {} unless a JSON object
    t_cards = _dict(trusted.get("cards"))

    rows, card_wt = [], {}
    for i, b in enumerate(blocks):
        w = _dict(wts.get(b["path"]))
        role, cid = _role(w, b["branch"], by_values)
        if cid and cid not in card_wt:
            card_wt[cid] = (b, w)
        f = refs.get("refs/heads/%s" % b["branch"]) if b["branch"] is not None else None
        status = w.get("status")
        rows.append({"i": i, "b": b, "w": w, "role": role, "cid": cid, "ref": f, "upstream": _upstream(b, f),
                     "uncommitted": len([x for x in status.split("\n") if x]) if isinstance(status, str) else "?",
                     "ctime": _num(f[4]) if f else None})

    agents = []
    for r in rows:
        b, cid, f = r["b"], r["cid"], r["ref"]
        c = _dict(src_cards.get(cid)) if cid else {}
        pr = _facts(cid, c, refs, card_wt)["pr"] if cid else None
        if pr is not None:
            lands = "PR #%d → %s" % (pr, default)
        elif f and f[2]:
            lands = "pushed: " + _short(f[2])
        else:
            lands = "local only"
        impl = _implementers(c)
        last_round = []
        if cid and isinstance(src_cards.get(cid), dict):
            n, last = _review(c)[:2]
            last_round = ["%s r%d @%s %s · by %s" % (a["role"], n, _str(a.get("sha"))[:7] or "-",
                                                      _str(a.get("verdict")) or "-", _str(a.get("by")) or "-")
                          for a in last]
        agents.append({"path": b["path"], "branch": b["branch"], "main": r["i"] == 0, "role": r["role"], "card": cid,
                       "upstream": r["upstream"], "uncommitted": r["uncommitted"], "lands": lands,
                       "opened_by": impl[-1]["by"] if impl and isinstance(impl[-1].get("by"), str) else None,
                       "last_round": last_round})
    rank = {"lead": 0, "implementer": 1}
    agents.sort(key=lambda a: (rank.get(a["role"].split(" ")[0], 2), a["path"]))

    # R8' TR: T alone, no local report or worktree branch
    tr = {(x["card"], x["pr"], x["sha"]) for x in _queue(trusted, {}, refs, {})["ready"]}
    leads = []
    lead_rows = rows[:1] + sorted((r for r in rows[1:] if r["role"] == "lead"), key=lambda r: r["b"]["path"])
    for r in lead_rows:
        b, w = r["b"], r["w"]
        s = _state(w)
        files = _dict(w.get("files"))
        q = _queue(s, files, refs, card_wt, tr, default)
        spec = s.get("spec")
        text = files.get(spec) if isinstance(spec, str) else None
        title = next((line[2:].rstrip() for line in _str(text).split("\n") if line.startswith("# ")), None)
        changed = _changed_at(w)
        last = _latest(r["ctime"], changed)
        leads.append({"path": b["path"], "branch": b["branch"], "main": r["i"] == 0, "source": b["path"] == source,
                      "spec_title": title,
                      "open": len([c for c in _dict(s.get("cards")).values()
                                   if isinstance(c, dict) and _str(c.get("status")) in OPEN_STATUSES]),
                      "waiting": len({x["card"] for x in q["waiting"] if x["card"] is not None}),
                      "ready": len(q["ready"]), "changed_at": changed,
                      "stale": r["i"] != 0 and last is not None and now is not None and now - last > WEEK})

    queue = _queue(src, _dict(_dict(wts.get(source)).get("files")), refs, card_wt, tr, default)
    actions = []
    for r in rows:
        b, cid, f, up, path = r["b"], r["cid"], r["ref"], r["upstream"], r["b"]["path"]
        if r["i"] == 0 or path == self_path:
            continue
        br = b["branch"]
        if br is not None and br != default and up not in ("gone", "?") and (up == "no upstream" or "ahead" in up):
            actions.append(_action("push", path, cid, "git -C %s push -u origin %s" % (path, br),
                                   _branch_ok(br) and _ok(PATH_RE, path), r["uncommitted"]))
        c = t_cards.get(cid) if cid else None  # R10': `merged` only from T
        merged = isinstance(c, dict) and c.get("status") == "accepted" and isinstance(c.get("merged"), dict)
        last = _latest(r["ctime"], _changed_at(r["w"])) if r["role"] == "lead" else r["ctime"]
        aged = (last is not None and now is not None and now - last > WEEK and bool(f and f[2])
                and (up == "in sync" or re.fullmatch(r"[0-9]+ behind", up) is not None))
        if merged or aged:
            actions.append(_action("remove_worktree", path, cid, "git worktree remove %s" % path,
                                   _ok(PATH_RE, path), r["uncommitted"]))
    for x in queue["ready"]:
        actions.append(_action("merge", "#%s" % x["pr"], x["card"],
                               "gh pr merge %s --squash --match-head-commit %s" % (x["pr"], x["sha"]),
                               x["pr"] > 0 and _ok(SHA_RE, x["sha"])))
    checked_out = {b["branch"] for b in blocks if b["branch"] is not None}
    for cid in sorted(src_cards):
        c = t_cards.get(cid)  # R10': merged and the R7 branch from T's card; a card that T lacks gives none
        if not isinstance(c, dict) or not isinstance(c.get("merged"), dict):
            continue
        br = _facts(cid, c, refs, {})["branch"]
        f = refs.get("refs/heads/%s" % br) if br is not None else None
        if f and br not in checked_out and f[1] == c["merged"].get("head"):
            actions.append(_action("delete_branch", br, cid, "git branch -D %s" % br, _branch_ok(br)))
    actions.sort(key=lambda a: (a["card"] if a["card"] is not None else a["target"], KIND_ORDER.index(a["kind"])))

    mtimes = [_int(v) for v in _dict(raw.get("fetch_head_mtimes")).values() if _int(v) is not None]
    return {"agents": agents, "leads": leads, "queue": queue, "actions": actions,
            "fetched_at": max(mtimes) if mtimes else "never fetched"}


def _utc(ts):
    """Format F time: `YYYY-MM-DD HH:MM UTC`; `?` when unknown."""
    if _int(ts) is None:
        return "?"
    try:
        return dt.datetime.fromtimestamp(_int(ts), dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    except (OverflowError, OSError, ValueError):
        return "?"


def git_sections(data):
    """Format F: the Spec C sections under the card table. Every command gets its own one-line bash block."""
    def cell(x):
        return str(x).replace("|", "/").replace("\n", " ")

    def code(x):
        return cell(x).replace("`", "")

    def item(x):  # a value inside a "- " list line: never 4 leading spaces, which open a code block
        return one_line(cell(x)).strip()

    leads = data.get("leads") or []
    source = next((l["path"] for l in leads if l["source"]), data.get("project"))
    fetched = data.get("fetched_at")
    out = ["", "## Leads",
           f"Card table and queue source: `{code(source)}` · remote data as of the last fetch: "
           f"{fetched if isinstance(fetched, str) else _utc(fetched)}", "",
           "| path | branch | spec | open | waiting | ready | STATE changed | stale |",
           "|---|---|---|---|---|---|---|---|"]
    for l in leads:
        tags = (" (main checkout)" if l["main"] else "") + (" (source)" if l["source"] else "")
        out.append(f"| `{code(l['path'])}`{tags} | {cell(l['branch'] or '-')} | {cell(l['spec_title'] or '-')} | "
                   f"{l['open']} | {l['waiting']} | {l['ready']} | {_utc(l['changed_at'])} | "
                   f"{'stale' if l['stale'] else '-'} |")
    out += ["", "## Agents", "| role | path | branch | upstream | uncommitted | lands | opened by | last round |",
            "|---|---|---|---|---|---|---|---|"]
    for a in data.get("agents") or []:
        role = a["role"] + (" (main checkout)" if a["main"] else "")
        branch = a["branch"] if a["branch"] is not None else "detached"
        out.append(f"| {cell(role)} | `{code(a['path'])}` | {cell(branch)} | {cell(a['upstream'])} | "
                   f"{a['uncommitted']} | {cell(a['lands'])} | {cell(a['opened_by'] or '—')} | "
                   f"{cell('; '.join(a['last_round']) or '—')} |")
    queue = data.get("queue") or {}
    out += ["", "## Waiting on you"]
    out += [f"- {item(x['card'])} · {item(x['reason'])}" if x["card"] is not None
            else f"- {item(x['verification'])} (verification) · {item(x['reason'])}"
            for x in queue.get("waiting") or []] or ["none"]
    out += ["", "## Ready to merge"]
    out += [f"- {item(x['card'])} · PR #{item(x['pr'])} · reviewed {item(str(x['sha'])[:7])}"
            for x in queue.get("ready") or []] or ["none"]
    out += ["", "## Git actions", "You run these with Desktop's Run button; the lead never runs them."]
    actions = data.get("actions") or []
    for a in actions:
        head = f"**{a['kind']}** `{code(a['target'])}`"
        out += ["", head, "```bash", a["command"], "```"] if a["command"] else ["", f"{head}: {cell(a['note'])}"]
    if not actions:
        out += ["", "none"]
    return out


def collect(root):
    delix = os.path.join(root, "docs", "delix")
    state = read_json(os.path.join(delix, "STATE.json")) or {}
    cards = dict(state.get("cards") or {})
    tasks = os.path.join(delix, "tasks")
    if os.path.isdir(tasks):
        for name in sorted(os.listdir(tasks)):
            m = re.match(r"(T\d{3})-.*\.md$", name)
            if not m:
                continue
            cid = m.group(1)
            text = read(os.path.join(tasks, name)) or ""
            fallback = from_card_file(text)
            c = cards.setdefault(cid, {})
            c.setdefault("file", os.path.join("docs", "delix", "tasks", name))
            for field in ("role", "tier", "status"):
                if c.get(field) in (None, "") and fallback.get(field):
                    c[field] = fallback[field]
            if c.get("wave") is None and fallback.get("wave", "").isdigit():
                c["wave"] = int(fallback["wave"])
    verifications = [v for v in (state.get("verifications") or []) if isinstance(v, dict)]
    g = derive(git_raw(root))  # Spec C; the source STATE is this root's (K256)
    if not cards:
        return {"project": root, "spec": state.get("spec"), "size": state.get("size"),
                "updated": state.get("updated"), "cards": [], "worktree_count": 0,
                "verifications": verifications, **g}

    wave_no = {}
    for i, w in enumerate(state.get("waves") or [], 1):
        if isinstance(w, dict):  # {"wave": 2, "cards": [...], "note": ...}; the template's shape is [["T001"], ...]
            i = w.get("wave") if isinstance(w.get("wave"), int) else i
            w = w.get("cards") or []
        for cid in w:
            wave_no.setdefault(cid, i)

    # worktree → card mapping: .delix/card content, else T<nnn> in the branch name
    reports = {}
    wts = worktrees(root)
    for path, branch in wts:
        cid = None
        card = read(os.path.join(path, ".delix", "card"))
        if card:
            m = re.search(r"(T\d{3})", card)
            cid = m.group(1) if m else None
        if not cid:
            m = re.search(r"(T\d{3})", branch or os.path.basename(path))
            cid = m.group(1) if m else None
        if not cid:
            continue
        report = read(os.path.join(path, ".delix", "report.md"))
        reports[cid] = {"worktree": path, "branch": branch, "report": report}

    rows = []
    for cid in sorted(cards):
        c = cards[cid]
        r = reports.get(cid, {})
        rstatus, rpr, summary = (None, None, "")
        if r.get("report"):
            rstatus, rpr, summary = report_summary(r["report"])
        status = c.get("status") or "open"
        tier = c.get("tier")
        try:
            tier = int(tier)
        except (TypeError, ValueError):
            pass
        pr = c.get("pr") or rpr
        gates = []
        if tier == 3 and status in OPEN_STATUSES:
            gates.append("🔐")
        if status == "in_review" and pr:  # accepted = merged (review §4), so gate 2 is still open only here
            gates.append("merge")
        if status == "escalated":
            gates.append("escalated")
        if rstatus in ("NEEDS_CONTEXT", "BLOCKED") and status in OPEN_STATUSES:
            gates.append(rstatus.lower())
        if isinstance(c.get("agents"), list) and c["agents"]:  # a card with a ledger follows R8 (K254)
            why = [x["reason"] for x in g["queue"]["waiting"] if x["card"] == cid]
            gates = ((["🔐"] if "tier 3 approval" in why else []) +
                     (["merge"] if any(x["card"] == cid for x in g["queue"]["ready"]) else []) +
                     (["escalated"] if status == "escalated" else []) +
                     [x for x in why if x in ("needs_context", "blocked")])
        rows.append({
            "wave": wave_no.get(cid, c.get("wave")),
            "id": cid, "role": c.get("role") or "?", "tier": tier if tier is not None else "?",
            "status": status, "rounds": c.get("rounds", 0), "pr": pr,
            "cost_usd": c.get("cost_usd"),
            "report_status": rstatus, "report_summary": summary,
            "worktree": r.get("worktree"), "branch": r.get("branch"),
            "gates": gates, "file": c.get("file"),
        })
    rows.sort(key=lambda s: (s["wave"] if isinstance(s["wave"], int) else 99, s["id"]))
    return {"project": root, "spec": state.get("spec"), "size": state.get("size"),
            "updated": state.get("updated"), "cards": rows, "worktree_count": len(wts),
            "verifications": verifications, **g}


def verifications_table(records):
    """STATE.json.verifications → Markdown table rows (/delixcrew:verify, card-less work). [] when empty."""
    if not records:
        return []
    def h(x):
        return str(x if x not in (None, "") else "-").replace("|", "/").replace("\n", " ")
    out = ["", "## Verifications (card-less, `/delixcrew:verify`)", "",
           "| date | name | sha | tier | gitleaks | local | remote unit | full | qa | security | verdict | cost | report |",
           "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for v in records:
        gates = v.get("gates") or {}
        m = v.get("cost_usd")
        cost = f"${m:.2f}" if isinstance(m, (int, float)) else "not measured"
        sha = h(v.get("sha"))[:7]
        report = f"`{v['report']}`" if v.get("report") else "-"
        verdict = h(v.get("verdict")) + (f" · {h(v['resolution'])}" if v.get("resolution") else "")
        out.append(f"| {h(v.get('date'))} | {h(v.get('name'))} | {sha} | {h(v.get('tier'))} | {h(gates.get('gitleaks'))} | "
                   f"{h(gates.get('local'))} | {h(gates.get('remote_unit'))} | {h(gates.get('full'))} | {h(v.get('qa'))} | "
                   f"{h(v.get('security'))} | {verdict} | {cost} | {report} |")
    pending = [v.get("name") for v in records
               if str(v.get("verdict", "")).startswith("FIX") and not v.get("resolution")]
    out.append("")
    out.append("**Pending fixes:** " + (", ".join(map(str, pending)) if pending else "none") +
               " · verdict ACCEPT/FIX; fixing and merging are the user's; 🔐 = a protected path was touched, asks for approval in chat.")
    return out


def one_line(s):
    """One Markdown line: control (C*), line and paragraph separator characters become spaces, so no field opens a new line or block."""
    return "".join(" " if unicodedata.category(c)[0] == "C" or unicodedata.category(c) in ("Zl", "Zp") else c for c in s)


def table(data):
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    out = [f"# delix board — {os.path.basename(data['project'].rstrip('/'))}", "",
           f"Generated: {now} · spec: `{data.get('spec') or '-'}` · size: {data.get('size') or '-'} · "
           f"STATE updated: {data.get('updated') or '-'}  ",
           "Read-only; `/delixcrew:status` regenerates it. Sources: `docs/delix/STATE.json`, `docs/delix/tasks/`, "
           "worktree `.delix/report.md`.", ""]
    if not data["cards"]:
        out += ["**No cards.** `docs/delix/STATE.json` or `docs/delix/tasks/` is missing or empty. "
                "Start with `/delixcrew:start <request>`, create cards with `/delixcrew:dispatch`.", ""]
        out += verifications_table(data.get("verifications"))
        out += git_sections(data)
        return "\n".join(one_line(x) for x in out)
    count = {}
    for s in data["cards"]:
        count[s["status"]] = count.get(s["status"], 0) + 1
    summary = " · ".join(f"{k} {v}" for k, v in sorted(count.items()))
    out.append(f"Cards {len(data['cards'])}: {summary} · worktrees {data['worktree_count']}")
    out.append("")
    out.append("| wave | card | role | tier | status | rounds | PR | cost | last report | pending gate |")
    out.append("|---|---|---|---|---|---|---|---|---|---|")
    for s in data["cards"]:
        pr = f"#{s['pr']}" if s["pr"] else "-"
        cost = f"${s['cost_usd']:.2f}" if isinstance(s["cost_usd"], (int, float)) else "not measured"
        report = "-"
        if s["report_status"] or s["report_summary"]:
            report = " · ".join(x for x in (s["report_status"], s["report_summary"]) if x)
        elif s["worktree"]:
            report = "no report (worktree open)"
        gate = " ".join(s["gates"]) or "-"
        out.append(f"| {s['wave'] if s['wave'] is not None else '-'} | {s['id']} | {s['role']} | {s['tier']} | "
                   f"{s['status']} | {s['rounds']} | {pr} | {cost} | {report} | {gate} |")
    pending = [f"{s['id']} ({', '.join(s['gates'])})" for s in data["cards"] if s["gates"]]
    out.append("")
    out.append("**Pending gates:** " + ("; ".join(pending) if pending else "none") + "  ")
    out.append("🔐 = Tier 3, interactive session + security approval · merge = gate 2, PR in review, a human merges.")
    out += verifications_table(data.get("verifications"))
    out += git_sections(data)
    return "\n".join(one_line(x) for x in out) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--project", default=os.getcwd())
    ap.add_argument("--write", action="store_true", help="also write docs/delix/BOARD.md (default: stdout only)")
    ap.add_argument("--json", action="store_true", help="print raw data instead of the table")
    a = ap.parse_args()
    root = os.path.abspath(a.project)
    data = collect(root)
    if a.json:
        print(json.dumps(data, ensure_ascii=False, indent=1))
        return
    text = table(data)
    print(text, end="")
    delix = os.path.join(root, "docs", "delix")
    if a.write and os.path.isdir(delix):
        board = os.path.join(delix, "BOARD.md")
        with open(board, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"\n(BOARD written: {os.path.relpath(board, root)})")


if __name__ == "__main__":
    main()
