"""Shared helpers for delix hooks. Stdlib only."""
import fnmatch
import json
import os
import subprocess
import sys

REVIEWERS = {"delixcrew:architect", "delixcrew:qa", "delixcrew:security", "delixcrew:scout",
             "architect", "qa", "security", "scout"}


def read_input():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason}}))
    sys.exit(0)


def card_path(cwd):
    """Returns the card path if the implementer worktree has .delix/card; otherwise None (hook inactive).
    Only a local card counts (issue #8): cwd is a git work tree and .delix/card is a plain file git does not track.
    A card that arrives with the repo (clone, archive, symlink) would make the Stop gate run the repo's commands."""
    p = os.path.join(cwd, ".delix", "card")
    if not os.path.isfile(p):
        return None
    rc = None
    if os.path.realpath(p) == os.path.join(os.path.realpath(cwd), ".delix", "card"):
        try:
            rc = subprocess.run(["git", "-c", "core.fsmonitor=false", "-C", cwd, "ls-files", "--error-unmatch", "--",
                                 ".delix/card"], stdin=subprocess.DEVNULL, capture_output=True, timeout=5).returncode
        except (OSError, subprocess.TimeoutExpired):
            pass
    if rc != 1:  # 0: tracked, came with the repo; 128/None: not a git work tree or no git; symlink: never checked
        sys.stderr.write("delixcrew: .delix/card is tracked, a symlink or outside a git work tree; hooks stay inactive "
                         "here. The implementer writes it locally (.git/info/exclude).\n")
        return None
    with open(p, encoding="utf-8") as f:
        return f.read().strip() or None


def delix_json(cwd):
    for candidate in (os.path.join(cwd, "docs", "delix", "delix.json"),):
        if os.path.isfile(candidate):
            try:
                with open(candidate, encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return {}
    return {}


def matches(path, patterns, cwd):
    """Normalizes a relative/absolute path against cwd and compares it with glob patterns ('**' supported)."""
    if not path:
        return None
    rel = os.path.relpath(os.path.abspath(os.path.join(cwd, path)), cwd)
    rel = rel.replace(os.sep, "/")
    for d in patterns:
        d2 = d.replace("**/", "").replace("/**", "")
        if fnmatch.fnmatch(rel, d) or fnmatch.fnmatch(rel, d2) or rel.startswith(d2.rstrip("*").rstrip("/") + "/") \
                or fnmatch.fnmatch(os.path.basename(rel), d):
            return d
    return None
