#!/usr/bin/env python3
"""Approve the Stop gate commands of this repository, from your own terminal (REQ-3, K200). Stdlib only.
Run at the root of the main checkout (or of a worktree whose delix.json commands changed):
    python3 <plugin dir>/scripts/trust.py allow
Exit 0 approved or already approved · 6 not confirmed (no TTY, wrong text) · 7 precondition (K210)."""
import datetime
import json
import os
import stat
import sys
import tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import git, is_trusted, load_trust, stop_commands, trust_file, trust_key  # noqa: E402


def err(msg):
    sys.stderr.write(msg + "\n")


def main(argv):
    if argv != ["allow"]:
        err("usage: python3 <plugin dir>/scripts/trust.py allow")
        return 7
    cwd = os.getcwd()
    commands = stop_commands(cwd)
    if not all(isinstance(c, str) for c in commands):
        err("delixcrew trust: a test_command or extra_checks entry in docs/delix/delix.json is not a string; "
            "nothing approved")
        return 7
    key = trust_key(cwd, commands)
    if key is None:
        err("delixcrew trust: run this at the root of a git checkout or worktree whose .git is not a symlink; "
            "nothing approved")
        return 7
    common_dir, sha = key
    h = sha[:12]
    if is_trusted(cwd, commands):
        print("delixcrew trust: already approved for %s (hash %s)" % (common_dir, h))
        return 0
    print("Stop gate commands from docs/delix/delix.json:")
    for c in commands:
        print("  " + json.dumps(c))  # K214: escaped (\r, ‮ ...), one per line
    r = git(cwd, "diff", "--quiet", "HEAD", "--", "docs/delix/delix.json")
    if r is None or r.returncode != 0:
        print("warning: docs/delix/delix.json differs from HEAD (or there is no HEAD); these are not the committed commands")
    sys.stdout.write("Type TRUST %s to approve these commands for %s (the word TRUST, a space, then the hash): "
                     % (h, common_dir))
    sys.stdout.flush()
    if not sys.stdin.isatty():
        err("delixcrew trust: allow needs your own terminal (stdin is not a TTY); nothing approved")
        return 6
    if sys.stdin.readline().strip() != "TRUST " + h:
        err("not confirmed: type exactly TRUST %s (the word TRUST, a space, then the hash); nothing approved" % h)
        return 6
    try:
        path = trust_file()
        d = os.path.dirname(path)
        os.makedirs(d, mode=0o700, exist_ok=True)
        st = os.lstat(d)
        if not stat.S_ISDIR(st.st_mode) or st.st_uid != os.getuid():
            err("delixcrew trust: %s is not a directory you own; nothing approved" % d)
            return 7
        os.chmod(d, 0o700)  # the feedback/triage setup may have left it 0755
        rec = load_trust()
        if rec is None:
            if os.path.lexists(path):
                print("note: the existing record was not private or not valid; it is replaced")
            rec = {"version": 1, "entries": []}
        rec["entries"].append({"git_common_dir": common_dir, "sha256": sha, "approved_at":
                               datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")})
        fd, tmp = tempfile.mkstemp(dir=d, prefix=".trust-", suffix=".tmp")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(rec, f, ensure_ascii=False, indent=2)
                f.write("\n")
            os.chmod(tmp, 0o600)
            os.replace(tmp, path)
        except BaseException:
            if os.path.exists(tmp):
                os.unlink(tmp)
            raise
    except (KeyError, OSError) as e:
        err("delixcrew trust: cannot write the record (%s); nothing approved" % e)
        return 7
    print("delixcrew trust: approved for %s (hash %s); record %s" % (common_dir, h, path))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
