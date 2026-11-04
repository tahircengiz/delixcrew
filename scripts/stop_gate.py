#!/usr/bin/env python3
"""Stop: in an implementer worktree (cwd/.delix/card exists) the turn cannot end until the test command passes.
The commands run only when the user approved this repo + command list (trust.py allow, REQ-1); otherwise nothing runs,
the gate exits 2 once and says why. Exits 0 when stop_hook_active. Output goes to .delix/test-result.txt (never through a symlink)."""
import json
import os
import shlex
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import card_path, commands_hash, is_trusted, read_input, stop_commands  # noqa: E402


def open_result(path):
    """K213, K218: test-result.txt opened without following a symlink and never truncated through a hardlink; None
    (one stderr line) when that fails."""
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW, 0o644)
        try:
            if os.fstat(fd).st_nlink != 1:  # a hardlink to a file outside the repo: do not truncate it
                raise OSError("hardlink")
            os.ftruncate(fd, 0)
        except OSError:
            os.close(fd)
            raise
    except OSError:
        sys.stderr.write("delixcrew Stop gate: .delix/test-result.txt is a symlink, a hardlink or cannot be opened; "
                         "the output is not written there\n")
        return None
    return os.fdopen(fd, "w", encoding="utf-8")


g = read_input()
cwd = g.get("cwd") or os.getcwd()
if not card_path(cwd):
    sys.exit(0)
if g.get("stop_hook_active"):
    sys.exit(0)
report = os.path.join(cwd, ".delix", "report.md")
if os.path.isfile(report):
    with open(report, encoding="utf-8") as f:
        head = f.read(600)
    if "NEEDS_CONTEXT" in head or "BLOCKED" in head:
        sys.exit(0)  # the implementer is asking a question or is stuck; let it stop

commands = stop_commands(cwd)  # read once: the hashed list is the list that runs
out = open_result(os.path.join(cwd, ".delix", "test-result.txt"))
if not is_trusted(cwd, commands):  # REQ-2 (K201)
    h12 = commands_hash(commands)[:12]
    if out:
        out.write(f"[not run: commands not approved, hash {h12}]\n")
        out.close()
    trust_py = os.path.join(os.path.dirname(os.path.abspath(__file__)), "trust.py")
    sys.stderr.write(f"delixcrew Stop gate: the commands in docs/delix/delix.json are not approved for this repository "
                     f"(hash {h12}); none was run.\n"
                     f"The user runs, in their own terminal: cd {shlex.quote(cwd)} && python3 {shlex.quote(trust_py)} allow\n"
                     "write BLOCKED in .delix/report.md naming this command, then stop\n")
    sys.exit(2)
failed = []
for c in commands:
    try:
        r = subprocess.run(c, shell=True, cwd=cwd, capture_output=True, text=True, timeout=540)
        output = (r.stdout + r.stderr)
        if out:
            out.write(f"$ {c}\n{output}\n[exit {r.returncode}]\n\n")
        if r.returncode != 0:
            failed.append((c, r.returncode, output.strip().splitlines()[-12:]))
    except subprocess.TimeoutExpired:
        if out:
            out.write(f"$ {c}\n[timeout]\n\n")
        failed.append((c, "timeout", []))
if out:
    out.close()

if failed:
    lines = ["delix Stop gate: the card cannot close, these commands failed:"]
    for c, code, tail in failed:
        lines.append(f"- `{c}` → exit {code}")
        lines += ["    " + s for s in tail]
    lines.append("Fix the code without changing the tests; if a test is wrong, write NEEDS_CONTEXT in .delix/report.md "
                 "and stop. Full output: .delix/test-result.txt")
    sys.stderr.write("\n".join(lines) + "\n")
    sys.exit(2)
sys.exit(0)
