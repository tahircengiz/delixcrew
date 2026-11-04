"""Shared helpers for delix hooks. Stdlib only."""
import fnmatch
import hashlib
import json
import os
import pwd
import stat
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


def git(cwd, *args):
    """CompletedProcess of `git -c core.fsmonitor=false -C <cwd> <args>`, or None (no git, timeout). stdin DEVNULL,
    5 s, and every GIT_* variable removed from env (K212: a GIT_DIR in the hook env must not choose the repo)."""
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    env["GIT_NO_LAZY_FETCH"] = "1"  # git >= 2.44: a promisor remote in the repo config must not run a program
    try:
        return subprocess.run(["git", "-c", "core.fsmonitor=false", "-C", cwd, *args], stdin=subprocess.DEVNULL,
                              capture_output=True, text=True, timeout=5, env=env)
    except (OSError, subprocess.TimeoutExpired):
        return None


def card_path(cwd):
    """Returns the card path if the implementer worktree has .delix/card; otherwise None (hook inactive).
    Only a local card counts (issue #8): cwd is the root of a git work tree, .delix/card is not reached through a
    symlink, and git knows nothing under .delix in any letter case (no tracked file, no submodule). A card that
    arrives with the repo (clone, archive, symlink) would make the Stop gate run the repo's commands."""
    p = os.path.join(cwd, ".delix", "card")
    if not os.path.isfile(p):
        return None

    def git_out(*args):  # stdout of a read-only git command, or None (no git, not a work tree, timeout)
        r = git(cwd, *args)
        return r.stdout if r is not None and r.returncode == 0 else None

    local = False
    if os.path.realpath(p) == os.path.join(os.path.realpath(cwd), ".delix", "card"):
        top = (git_out("rev-parse", "--show-toplevel") or "").strip()
        local = bool(top) and os.path.samefile(top, cwd) and git_out("ls-files", "--", ":(icase).delix") == ""
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


def stop_commands(cwd):
    """REQ-1 list, read once: [test_command or "pytest -q"] + extra_checks. A missing, broken or non-object delix.json
    gives ["pytest -q"]; an extra_checks that is not a list (a string too) counts as one non-str element, so trust_key
    refuses it and nothing runs (REQ-1)."""
    cfg = delix_json(cwd)
    if not isinstance(cfg, dict):
        cfg = {}
    extra = cfg.get("extra_checks") or []
    return [cfg.get("test_command") or "pytest -q"] + (extra if isinstance(extra, list) else [[extra]])


def commands_hash(commands):
    """REQ-1: sha256 hex of the canonical JSON of the list."""
    return hashlib.sha256(json.dumps(commands, ensure_ascii=False, separators=(",", ":"))
                          .encode("utf-8", "surrogatepass")).hexdigest()


def _read_small(path, limit=4096):
    """Text of a regular file of at most `limit` bytes, opened without following a symlink; else None."""
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0))
    except OSError:
        return None
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            return None
        data = os.read(fd, limit + 1)
    except OSError:
        return None
    finally:
        os.close(fd)
    if len(data) > limit:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return None


def trust_key(cwd, commands=None):
    """REQ-1 (K199, K211): (git_common_dir, sha256), or None. The repo identity is checked on the file system with
    lstat; a symlinked .git (directory or gitfile) never counts. `commands` defaults to stop_commands(cwd)."""
    cmds = stop_commands(cwd) if commands is None else commands
    if not all(isinstance(c, str) for c in cmds):
        return None
    r = git(cwd, "rev-parse", "--git-common-dir")
    out = r.stdout.rstrip("\n") if r is not None and r.returncode == 0 else ""
    if not out:
        return None
    root = os.path.realpath(cwd)
    common = os.path.realpath(os.path.join(root, out))
    dotgit = root + "/.git"
    try:
        st = os.lstat(dotgit)
    except OSError:
        return None
    if stat.S_ISDIR(st.st_mode):  # main worktree
        ok = common == dotgit
    elif stat.S_ISREG(st.st_mode):  # linked worktree: gitfile → <common>/worktrees/<name>, whose gitdir points back
        text = _read_small(dotgit)
        lines = text.rstrip("\n").split("\n") if text is not None else []
        ok = len(lines) == 1 and lines[0].startswith("gitdir: ")
        if ok:
            entry = os.path.realpath(os.path.join(root, lines[0][len("gitdir: "):]))
            back = _read_small(os.path.join(entry, "gitdir"))
            ok = (os.path.dirname(entry) == os.path.join(common, "worktrees") and back is not None
                  and back.strip() == dotgit)
    else:
        ok = False
    return (common, commands_hash(cmds)) if ok else None


def trust_file():
    """REQ-4 (K203): <passwd home>/.claude/delixcrew/trust.json; HOME and other env are never read. KeyError when the
    uid has no passwd entry. Tests replace this module attribute (runpy), not env."""
    return os.path.join(pwd.getpwuid(os.getuid()).pw_dir, ".claude", "delixcrew", "trust.json")


def load_trust():
    """REQ-4: the record dict, or None (fail closed). Directory and file: owned by getuid(), mode & 0o077 == 0, not a
    symlink; the file is a regular file of at most 1 MiB, opened with O_NOFOLLOW; version is the int 1; entries a list."""
    try:
        path = trust_file()
        dst = os.lstat(os.path.dirname(path))
        if not stat.S_ISDIR(dst.st_mode) or dst.st_uid != os.getuid() or dst.st_mode & 0o077:
            return None
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0))
        try:
            st = os.fstat(fd)
            if (not stat.S_ISREG(st.st_mode) or st.st_uid != os.getuid() or st.st_mode & 0o077
                    or st.st_size > 1 << 20):
                return None
            chunks, left = [], (1 << 20) + 1
            while left > 0:
                chunk = os.read(fd, left)
                if not chunk:
                    break
                chunks.append(chunk)
                left -= len(chunk)
            data = b"".join(chunks)
        finally:
            os.close(fd)
        if len(data) > 1 << 20:
            return None
        rec = json.loads(data.decode("utf-8"))
    except Exception:
        return None
    if (not isinstance(rec, dict) or type(rec.get("version")) is not int or rec["version"] != 1
            or not isinstance(rec.get("entries"), list)):
        return None
    return rec


def is_trusted(cwd, commands=None):
    """REQ-1/REQ-4: is (git_common_dir, sha256) of `commands` in the record? Reads the record on every call; any
    error is False."""
    try:
        key = trust_key(cwd, commands)
        rec = load_trust() if key else None
        return bool(rec) and any(isinstance(e, dict) and e.get("git_common_dir") == key[0]
                                 and e.get("sha256") == key[1] for e in rec["entries"])
    except Exception:
        return False


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
