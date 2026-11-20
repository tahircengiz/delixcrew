"""Shared helpers for delix hooks. Stdlib only."""
import fnmatch
import hashlib
import json
import os
import pwd
import stat
import subprocess
import sys
import unicodedata

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


def card_id(text):
    """Spec D REQ-1 (K353): "T" plus the whole run of ASCII digits after a leading T in the last path part, or None."""
    name = text.rsplit("/", 1)[-1]
    digits = ""
    for c in name[1:]:
        if c not in "0123456789":  # not str.isdigit: it accepts other scripts' digits
            break
        digits += c
    return "T" + digits if name[:1] == "T" and digits else None


def _trusted_json(cwd, sha, rel):
    """Spec D REQ-1 (K352): the JSON object of blob <sha>:<rel>, at most 1 MiB, without lazy fetch or replace objects;
    None on any other result or error."""
    try:
        r = git(cwd, "--no-lazy-fetch", "--no-replace-objects", "cat-file", "blob", sha + ":" + rel)
        if r is None or r.returncode != 0 or len(r.stdout.encode("utf-8")) > 1 << 20:
            return None
        obj = json.loads(r.stdout)
        return obj if isinstance(obj, dict) else None
    except Exception:
        return None


def _card_finished(cwd, marker):
    """Spec D REQ-1 (K344, K345, K353): the card id when the card the marker names is finished on origin/HEAD (its
    record's file equals the marker; status accepted or merged an object); None in every other case (fail closed)."""
    try:
        cid = card_id(marker)
        if cid is None:
            return None
        r = git(cwd, "--no-lazy-fetch", "show-ref", "--verify", "refs/remotes/origin/HEAD")
        fields = r.stdout.split() if r is not None and r.returncode == 0 else []
        if len(fields) != 2 or fields[1] != "refs/remotes/origin/HEAD" or len(fields[0]) not in (40, 64) \
                or any(c not in "0123456789abcdef" for c in fields[0]):
            return None
        sha = fields[0]

        def decide(state):  # True/False when state's cards hold a record of cid whose file is the marker, else None
            cards = state.get("cards")
            rec = cards.get(cid) if isinstance(cards, dict) else None
            if not (isinstance(rec, dict) and isinstance(rec.get("file"), str) and rec["file"] == marker):
                return None
            return rec.get("status") == "accepted" or isinstance(rec.get("merged"), dict)

        state = _trusted_json(cwd, sha, "docs/delix/STATE.json")  # never the worktree copy
        if state is None:
            return None
        cards = state.get("cards")
        if isinstance(cards, dict) and cid in cards:  # that record alone decides; the archive is not read
            return cid if decide(state) else None
        archive = state.get("archive")
        if not isinstance(archive, list):
            return None
        head, tail = "docs/delix/archive/", "/STATE.json"
        for item in archive[:20]:
            if not isinstance(item, str) or not item.startswith(head) or not item.endswith(tail) or ".." in item:
                continue
            middle = item[len(head):-len(tail)]
            if not middle or "/" in middle:
                continue
            old = _trusted_json(cwd, sha, item)
            done = decide(old) if old is not None else None
            if done is not None:
                return cid if done else None
        return None
    except Exception:
        return None


def card_path(cwd):
    """Returns the card path if the implementer worktree has .delix/card; otherwise None (hook inactive).
    Only a local card counts (issue #8): cwd is the root of a git work tree, .delix/card is not reached through a
    symlink, and git knows nothing under .delix in any letter case (no tracked file, no submodule). A card that
    arrives with the repo (clone, archive, symlink) would make the Stop gate run the repo's commands.
    Spec D REQ-1: a card that is finished on origin/HEAD also gives None, with one stderr line."""
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
        text = f.read().strip()
    if not text:
        return None
    cid = _card_finished(cwd, text)
    if cid is not None:
        sys.stderr.write(f"delixcrew: .delix/card names {cid}, "
                         "which is accepted on origin/HEAD; implementer hooks stay inactive here. "
                         "Move .delix aside before starting a new card.\n")
        return None
    return text


def delix_json(cwd):
    """Spec D REQ-2 (K346): the docs/delix/delix.json object; None when it is missing, not a regular file, unreadable,
    not JSON or not an object."""
    for candidate in (os.path.join(cwd, "docs", "delix", "delix.json"),):
        if os.path.isfile(candidate):
            try:
                with open(candidate, encoding="utf-8") as f:
                    cfg = json.load(f)
            except Exception:
                return None
            return cfg if isinstance(cfg, dict) else None
    return None


CONFIG_DENY = ("delixcrew: docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; "
               "this card worktree stays blocked until the user fixes it from their own terminal")


def gate_config(cwd):
    """Spec D REQ-2 (K346): delix_json(cwd) when protected_paths and test_paths are each absent or a list of str;
    otherwise None (a key present with null too). The write and Bash gates deny with CONFIG_DENY on None."""
    cfg = delix_json(cwd)
    if cfg is None:
        return None
    for key in ("protected_paths", "test_paths"):
        if key in cfg and not (isinstance(cfg[key], list) and all(isinstance(x, str) for x in cfg[key])):
            return None
    return cfg


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


def _fold_text(s):
    """Spec D REQ-5 (K356): NFD, then casefold, in the order of write_gate._fold (K129)."""
    return unicodedata.normalize("NFD", s).casefold()


def _rel_forms(path, cwd):
    """Spec D REQ-5 (K355, K356): (given, real) relative paths, '/' separated, folded before relpath so that a case
    difference in the cwd part counts too. given: against cwd as written; real: realpath of the target against
    realpath(cwd). None when a form cannot be computed (a symlink chain too deep, a bad character)."""
    try:
        given = os.path.relpath(_fold_text(os.path.abspath(os.path.join(cwd, path))), _fold_text(os.path.abspath(cwd)))
        real = os.path.relpath(_fold_text(os.path.realpath(os.path.join(cwd, path))), _fold_text(os.path.realpath(cwd)))
    except (OSError, ValueError, RecursionError):
        return None
    return given.replace(os.sep, "/"), real.replace(os.sep, "/")


def _match_one(rel, patterns):
    """The first pattern (as given, unfolded) whose folded form matches the folded rel ('**' supported), or None."""
    for d in patterns:
        f = _fold_text(d)
        f2 = f.replace("**/", "").replace("/**", "")
        if fnmatch.fnmatch(rel, f) or fnmatch.fnmatch(rel, f2) or rel.startswith(f2.rstrip("*").rstrip("/") + "/") \
                or fnmatch.fnmatch(os.path.basename(rel), f):
            return d
    return None


def matches(path, patterns, cwd):
    """Normalizes a relative/absolute path against cwd and compares it with glob patterns ('**' supported).
    Spec D REQ-5: the folded given path first, then the folded real path; either one matching is a match."""
    if not path:
        return None
    forms = _rel_forms(path, cwd)
    if forms is None:  # fail closed: a path the hook cannot resolve matches the first pattern
        return patterns[0] if patterns else None
    return _match_one(forms[0], patterns) or _match_one(forms[1], patterns)


def matches_both(path, patterns, cwd):
    """Spec D REQ-5 (K357): the given form's pattern only when the given and the real form each match a pattern;
    otherwise None. For the rule that opens the gate (the card's Files list)."""
    if not path:
        return None
    forms = _rel_forms(path, cwd)
    if forms is None:  # fail closed: a path the hook cannot resolve is not listed
        return None
    d = _match_one(forms[0], patterns)
    return d if d and _match_one(forms[1], patterns) else None
