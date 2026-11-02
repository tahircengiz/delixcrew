#!/usr/bin/env python3
"""Stop: in an implementer worktree (cwd/.delix/card exists) the turn cannot end until the test command passes.
Exits 0 when stop_hook_active to avoid a loop. Command output goes to .delix/test-result.txt (reviewers read it)."""
import json
import os
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import card_path, delix_json, read_input  # noqa: E402

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

cfg = delix_json(cwd)
commands = [cfg.get("test_command") or "pytest -q"] + list(cfg.get("extra_checks") or [])
result_path = os.path.join(cwd, ".delix", "test-result.txt")
failed = []
with open(result_path, "w", encoding="utf-8") as out:
    for c in commands:
        try:
            r = subprocess.run(c, shell=True, cwd=cwd, capture_output=True, text=True, timeout=540)
            output = (r.stdout + r.stderr)
            out.write(f"$ {c}\n{output}\n[exit {r.returncode}]\n\n")
            if r.returncode != 0:
                failed.append((c, r.returncode, output.strip().splitlines()[-12:]))
        except subprocess.TimeoutExpired:
            out.write(f"$ {c}\n[timeout]\n\n")
            failed.append((c, "timeout", []))

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
