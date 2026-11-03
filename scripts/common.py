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
    Only a local card counts (issue #8): cwd is the root of a git work tree, .delix/card is not reached through a
    symlink, and git knows nothing under .delix in any letter case (no tracked file, no submodule). A card that
    arrives with the repo (clone, archive, symlink) would make the Stop gate run the repo's commands."""
    p = os.path.join(cwd, ".delix", "card")
    if not os.path.isfile(p):
        return None

    def git(*args):  # stdout of a read-only git command, or None (no git, not a work tree, timeout)
        try:
            r = subprocess.run(["git", "-c", "core.fsmonitor=false", "-C", cwd, *args], stdin=subprocess.DEVNULL,
                               capture_output=True, text=True, timeout=5)
        except (OSError, subprocess.TimeoutExpired):
            return None
        return r.stdout if r.returncode == 0 else None

    local = False
    if os.path.realpath(p) == os.path.join(os.path.realpath(cwd), ".delix", "card"):
        top = (git("rev-parse", "--show-toplevel") or "").strip()
        local = bool(top) and os.path.samefile(top, cwd) and git("ls-files", "--", ":(icase).delix") == ""
    if not local:
        sys.stderr.write("delixcrew: .delix/card is tracked, a symlink or outside a git work tree root; hooks stay "
                         "inactive here. The implementer writes it locally (.git/info/exclude).\n")
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
