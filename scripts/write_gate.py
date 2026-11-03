#!/usr/bin/env python3
"""PreToolUse (Write|Edit|MultiEdit|NotebookEdit): reviewer roles cannot write; the implementer cannot write the card
file or docs/delix/**; a protected path is writable only if it is in the card's Files list and the card carries a
🔐 Approved line; an existing test file is writable only if it is in the Files list (new test files are free); nothing
outside cwd (the worktree) is writable (A13). The implementer gate is active only when cwd/.delix/card exists."""
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import REVIEWERS, card_path, delix_json, deny, matches, read_input  # noqa: E402

g = read_input()

# REQ-7: no direct write into the feedback queue dir, in every session (feedback.py add via Bash is the only writer)
_ti = g.get("tool_input") or {}
_path = _ti.get("file_path") or _ti.get("notebook_path") or ""
if _path:
    queue = os.path.realpath(os.path.expanduser(os.environ.get("DELIXCREW_FEEDBACK_DIR") or "~/.claude/delixcrew/feedback"))
    target = os.path.realpath(os.path.join(g.get("cwd") or os.getcwd(), os.path.expanduser(_path)))
    if os.path.commonpath([queue, target]) == queue:
        deny("delixcrew: feedback is sent only by the user from their own terminal")
    # REQ-7 (0.6.0): same for the triage record dir (triage.py record via Bash is the only writer); casefold, since
    # realpath keeps the given letter case and a case-insensitive filesystem (APFS default) maps TRIAGE to triage
    triage = os.path.realpath(os.path.expanduser(os.environ.get("DELIXCREW_TRIAGE_DIR") or "~/.claude/delixcrew/triage"))
    triage = triage.casefold()
    if os.path.commonpath([triage, target.casefold()]) == triage:
        deny("delixcrew: triage decisions are applied only by the user from their own terminal")

agent = (g.get("agent_type") or "").strip()
if agent in REVIEWERS:
    deny(f"delixcrew: role '{agent}' is read-only; it cannot write files. Put the finding in your report, the orchestrator applies it.")

cwd = g.get("cwd") or os.getcwd()
if not card_path(cwd):
    sys.exit(0)  # not an implementer session, inactive

card = card_path(cwd)
APPROVED = re.compile(r"^\*\*🔐 Approved:\*\* \d{4}-\d{2}-\d{2} \S+", re.M)


def read_card():
    """(paths in the Files list, approved?). Files: backticked paths after '## Files' up to the next '## ' heading
    (parenthesised notes and ':line' are dropped). Approved: a single line in the header area before the first '## '."""
    try:
        with open(os.path.join(cwd, card), encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return [], False
    head = text.split("\n## ", 1)[0]
    m = re.search(r"^## Files\b.*?$(.*?)(?=^## |\Z)", text, re.M | re.S)
    paths = []
    for line in (m.group(1) if m else "").splitlines():
        for p in re.findall(r"`([^`]+)`", re.sub(r"\([^)]*\)", "", line)):
            p = p.split(":", 1)[0].strip()
            if p:
                paths.append(p)
    return paths, bool(APPROVED.search(head))


def outside_cwd(path):
    """Does the path escape cwd (the worktree)? realpath for symlinks (/tmp → /private/tmp)."""
    root = os.path.realpath(cwd)
    target = os.path.realpath(os.path.join(cwd, path))
    return os.path.commonpath([root, target]) != root


cfg = delix_json(cwd)
ti = g.get("tool_input") or {}
path = ti.get("file_path") or ti.get("notebook_path") or ""
protected = cfg.get("protected_paths") or []
test_paths = cfg.get("test_paths") or ["tests/**"]

if path and outside_cwd(path):
    deny(f"delixcrew: '{path}' is outside the worktree ({cwd}); the implementer writes only inside its own worktree (A13). "
         f"Build the path relative to cwd; if the file really lives elsewhere, write NEEDS_CONTEXT in the report.")

if matches(path, ["docs/delix/**", card], cwd):
    deny(f"delixcrew: '{path}' is the card or under docs/delix; the implementer cannot change these. If needed, explain "
         f"with NEEDS_CONTEXT in the report, the orchestrator updates them.")

files, approved = read_card()
listed = bool(matches(path, files, cwd))

d = matches(path, protected, cwd)
if d:
    if listed and approved:
        sys.exit(0)  # Tier 3: listed in the card and human-approved
    reason = "" if listed else " The path is not in the card's Files list."
    if not approved:
        reason += " The card has no 🔐 Approved line."
    deny(f"delixcrew: '{path}' is a protected path ({d}, Tier 3). This card cannot touch it;{reason} Explain with "
         f"BLOCKED/NEEDS_CONTEXT in the report, the orchestrator obtains human approval.")

if matches(path, test_paths, cwd) and not listed:
    full = os.path.abspath(os.path.join(cwd, path))
    tool = g.get("tool_name") or ""
    if tool == "Write" and not os.path.exists(full):
        sys.exit(0)  # new test file is free
    deny(f"delixcrew: existing test file '{path}' cannot be modified (no test weakening). Add a new file or a new function "
         f"for new tests; if the test looks wrong, stop and write NEEDS_CONTEXT in the report.")
sys.exit(0)
