#!/usr/bin/env python3
"""PreToolUse (Write|Edit|MultiEdit|NotebookEdit): reviewer roles cannot write; the implementer cannot write the card
file or docs/delix/**; a protected path is writable only if it is in the card's Files list and the card carries a
🔐 Approved line; an existing test file is writable only if it is in the Files list (new test files are free); nothing
outside cwd (the worktree) is writable (A13). The implementer gate is active only when cwd/.delix/card exists."""
import os
import re
import sys
import unicodedata
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import (CONFIG_DENY, REVIEWERS, card_id, card_path, deny, gate_config, matches,  # noqa: E402
                    matches_both, read_input, trust_file)


def _fold(p):
    """REQ-6 (K129): APFS ignores letter case and Unicode normalization; realpath keeps both as given."""
    return unicodedata.normalize("NFD", os.path.realpath(p)).casefold()

TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"  # K210: literal here and in bash_gate.py
MARKER_DENY = ("delixcrew: .delix/card names {}, "  # Spec D REQ-1 (K348): str.format with the card id
               "which is not finished on origin/HEAD; this worktree belongs to that card. "
               "Write nothing under .delix; end with BLOCKED in your final message; the lead opens a new worktree.")


g = read_input()

# REQ-7: no direct write into the feedback queue dir, in every session (feedback.py add via Bash is the only writer)
_ti = g.get("tool_input") or {}
_path = _ti.get("file_path") or _ti.get("notebook_path") or ""
if _path:
    queue = _fold(os.path.expanduser(os.environ.get("DELIXCREW_FEEDBACK_DIR") or "~/.claude/delixcrew/feedback"))
    target = _fold(os.path.join(g.get("cwd") or os.getcwd(), os.path.expanduser(_path)))
    if os.path.commonpath([queue, target]) == queue:
        deny("delixcrew: feedback is sent only by the user from their own terminal")
    # REQ-7 (0.6.0): same for the triage record dir (triage.py record via Bash is the only writer)
    triage = _fold(os.path.expanduser(os.environ.get("DELIXCREW_TRIAGE_DIR") or "~/.claude/delixcrew/triage"))
    if os.path.commonpath([triage, target]) == triage:
        deny("delixcrew: triage decisions are applied only by the user from their own terminal")
    # REQ-4 (K203): the Stop gate trust record, in every session; its path comes from the passwd entry, never env
    try:
        record = _fold(trust_file())
    except (KeyError, OSError):
        record = None  # no passwd entry: there is no record to protect
    if record and target == record:
        deny(TRUST_DENY)

agent = (g.get("agent_type") or "").strip()
if agent in REVIEWERS:
    deny(f"delixcrew: role '{agent}' is read-only; it cannot write files. Put the finding in your report, the lead applies it.")

cwd = g.get("cwd") or os.getcwd()
card = card_path(cwd)  # REQ-1: called once; None for no card, a non-local card or a finished card
if not card:
    sys.exit(0)  # not an implementer session, inactive
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


ti = g.get("tool_input") or {}
path = ti.get("file_path") or ti.get("notebook_path") or ""

if path and outside_cwd(path):
    deny(f"delixcrew: '{path}' is outside the worktree ({cwd}); the implementer writes only inside its own worktree (A13). "
         f"Build the path relative to cwd; if the file really lives elsewhere, write NEEDS_CONTEXT in the report.")

# Spec D REQ-1 (K348, K356): the live marker is rewritten only by Write with the same text
if path and _fold(os.path.join(cwd, path)) == _fold(os.path.join(cwd, ".delix", "card")):
    content = ti.get("content")
    if g.get("tool_name") == "Write" and isinstance(content, str) and content.strip() == card:
        sys.exit(0)  # the same card's marker (a fix round in its own worktree)
    deny(MARKER_DENY.format(card_id(card) or "unknown"))

# Spec D REQ-2 (K346): a delix.json the gate cannot read blocks every write except under realpath(cwd)/.delix/
cfg = gate_config(cwd)
if cfg is None:
    dot = os.path.join(os.path.realpath(cwd), ".delix")
    target = os.path.realpath(os.path.join(cwd, path))
    if target != dot and os.path.commonpath([dot, target]) == dot:
        sys.exit(0)  # the implementer can still write its BLOCKED report
    deny(CONFIG_DENY)
protected = cfg.get("protected_paths") or []
test_paths = cfg.get("test_paths") or ["tests/**"]

if matches(path, ["docs/delix/**", card], cwd):
    deny(f"delixcrew: '{path}' is the card or under docs/delix; the implementer cannot change these. If needed, explain "
         f"with NEEDS_CONTEXT in the report, the lead updates them.")

files, approved = read_card()
listed = bool(matches_both(path, files, cwd))  # K357: given and real path both listed

d = matches(path, protected, cwd)
if d:
    if listed and approved:
        sys.exit(0)  # Tier 3: listed in the card and human-approved
    reason = "" if listed else " The path is not in the card's Files list."
    if not approved:
        reason += " The card has no 🔐 Approved line."
    deny(f"delixcrew: '{path}' is a protected path ({d}, Tier 3). This card cannot touch it;{reason} Explain with "
         f"BLOCKED/NEEDS_CONTEXT in the report, the lead obtains human approval.")

if matches(path, test_paths, cwd) and not listed:
    full = os.path.abspath(os.path.join(cwd, path))
    tool = g.get("tool_name") or ""
    if tool == "Write" and not os.path.exists(full):
        sys.exit(0)  # new test file is free
    deny(f"delixcrew: existing test file '{path}' cannot be modified (no test weakening). Add a new file or a new function "
         f"for new tests; if the test looks wrong, stop and write NEEDS_CONTEXT in the report.")
sys.exit(0)
