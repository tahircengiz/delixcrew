#!/usr/bin/env python3
"""delix board: docs/delix/STATE.json + cards + worktree .delix/report.md → one Markdown table
(+ a "Verifications" table when STATE.json.verifications exists: card-less /delix:verify records, K43).

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
import subprocess
import sys

STATUS_RE = re.compile(r"\*\*Status:\*\*\s*([A-Z_]+)")
PR_RE = re.compile(r"\*\*PR:\*\*\s*#?(\d+)")
REPORT_STATUSES = ("DONE_WITH_CONCERNS", "DONE", "NEEDS_CONTEXT", "BLOCKED")
OPEN_STATUSES = {"open", "in_progress", "in_review", "fixing"}


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
    """`git worktree list --porcelain` → [(path, branch)]. Empty list without git or outside a repo."""
    try:
        cp = subprocess.run(["git", "worktree", "list", "--porcelain"], cwd=root,
                            capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return []
    if cp.returncode != 0:
        return []
    result, path, branch = [], None, ""
    for line in cp.stdout.splitlines() + [""]:
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
        pr = int(m.group(1))
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
    if not cards:
        return {"project": root, "spec": state.get("spec"), "size": state.get("size"),
                "updated": state.get("updated"), "cards": [], "worktree_count": 0,
                "verifications": verifications}

    wave_no = {}
    for i, w in enumerate(state.get("waves") or [], 1):
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
        if status == "accepted" and pr:
            gates.append("merge")
        if status == "escalated":
            gates.append("escalated")
        if rstatus in ("NEEDS_CONTEXT", "BLOCKED") and status in OPEN_STATUSES:
            gates.append(rstatus.lower())
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
            "verifications": verifications}


def verifications_table(records):
    """STATE.json.verifications → Markdown table rows (/delix:verify, card-less work). [] when empty."""
    if not records:
        return []
    def h(x):
        return str(x if x not in (None, "") else "-").replace("|", "/").replace("\n", " ")
    out = ["", "## Verifications (card-less, `/delix:verify`)", "",
           "| date | name | sha | tier | gitleaks | local | remote unit | full | qa | security | verdict | cost | report |",
           "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for v in records:
        gates = v.get("gates") or {}
        m = v.get("cost_usd")
        cost = f"${m:.2f}" if isinstance(m, (int, float)) else "not measured"
        sha = h(v.get("sha"))[:7]
        report = f"`{v['report']}`" if v.get("report") else "-"
        out.append(f"| {h(v.get('date'))} | {h(v.get('name'))} | {sha} | {h(v.get('tier'))} | {h(gates.get('gitleaks'))} | "
                   f"{h(gates.get('local'))} | {h(gates.get('remote_unit'))} | {h(gates.get('full'))} | {h(v.get('qa'))} | "
                   f"{h(v.get('security'))} | {h(v.get('verdict'))} | {cost} | {report} |")
    pending = [v.get("name") for v in records if str(v.get("verdict", "")).startswith("FIX")]
    out.append("")
    out.append("**Pending fixes:** " + (", ".join(map(str, pending)) if pending else "none") +
               " · verdict ACCEPT/FIX; fixing and merging are the user's; 🔐 = a protected path was touched, asks for approval in chat.")
    return out


def table(data):
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    out = [f"# delix board — {os.path.basename(data['project'].rstrip('/'))}", "",
           f"Generated: {now} · spec: `{data.get('spec') or '-'}` · size: {data.get('size') or '-'} · "
           f"STATE updated: {data.get('updated') or '-'}  ",
           "Read-only; `/delix:status` regenerates it. Sources: `docs/delix/STATE.json`, `docs/delix/tasks/`, "
           "worktree `.delix/report.md`.", ""]
    if not data["cards"]:
        out += ["**No cards.** `docs/delix/STATE.json` or `docs/delix/tasks/` is missing or empty. "
                "Start with `/delix:start <request>`, create cards with `/delix:dispatch`.", ""]
        out += verifications_table(data.get("verifications"))
        return "\n".join(out)
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
    out.append("**Pending gates:** " + ("; ".join(pending) if pending else "none") +
               "  \n🔐 = Tier 3, interactive session + security approval · merge = gate 2, a human merges.")
    out += verifications_table(data.get("verifications"))
    return "\n".join(out) + "\n"


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
