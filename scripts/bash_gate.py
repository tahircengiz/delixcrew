#!/usr/bin/env python3
"""PreToolUse (Bash): reviewer roles may run only read-only commands; in the implementer worktree, gitleaks runs
before commit and shell writes to protected paths are blocked."""
import os
import re
import shutil
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import REVIEWERS, card_path, delix_json, deny, matches, read_input  # noqa: E402

g = read_input()
cmd = ((g.get("tool_input") or {}).get("command") or "").strip()
agent = (g.get("agent_type") or "").strip()
cwd = g.get("cwd") or os.getcwd()

GIT = r"git\s+(?:-C\s+(?:\"[^\"]*\"|'[^']*'|\S+)\s+)?"  # `git -C <worktree>`: the reviewer reads another checkout
WRITING = re.compile(r"(^|[\s;&|(])(rm|mv|cp|tee|sed\s+-i|chmod|chown|truncate|mkdir|touch|dd|" + GIT + r"(add|commit|push|"
                     r"checkout|switch|reset|rebase|merge|stash|apply|cherry-pick|tag|branch\s+-[dD]))\b|>>?\s*[^&\s]|"
                     r"\bpip\s+install\b|\bnpm\s+(i|install|ci)\b|\buv\s+(add|sync|pip)\b|\bbrew\s+install\b")
if agent in REVIEWERS:
    if agent.endswith("security"):
        allowed = re.compile(r"^(gitleaks|semgrep|pip-audit|trivy|osv-scanner|bandit|" + GIT + r"(diff|log|show|status|"
                             r"ls-files|grep)|rg|grep|cat|head|tail|wc|ls|find|jq|python3?\s+-m\s+pip\s+index)\b")
        if WRITING.search(cmd) or not allowed.match(cmd):
            deny("delix: role 'security' may run only read-only scanners and git read commands "
                 "(gitleaks, semgrep, pip-audit, trivy, git [-C <dir>] diff/log/show, rg/grep/cat).")
        sys.exit(0)
    deny(f"delix: role '{agent}' is read-only; it cannot run Bash.")

if not card_path(cwd):
    sys.exit(0)

cfg = delix_json(cwd)
protected = cfg.get("protected_paths") or []

# writing to a protected path via shell redirect / cp / mv / tee
for m in re.finditer(r"(?:>>?|\bcp\b[^|;&]*|\bmv\b[^|;&]*|\btee\b)\s+([^\s;&|]+)", cmd):
    target = m.group(1).strip("'\"")
    d = matches(target, protected, cwd)
    if d:
        deny(f"delix: the command writes to a protected path ('{target}' ~ {d}). Tier 3 path; human approval required.")

if re.search(r"\bgit\s+commit\b", cmd):
    gl = shutil.which("gitleaks")
    if gl:
        r = subprocess.run([gl, "protect", "--staged", "--no-banner", "--redact", "--exit-code", "2"],
                           cwd=cwd, capture_output=True, text=True, timeout=50)
        if r.returncode == 2:
            summary = (r.stdout or r.stderr).strip().splitlines()[-8:]
            deny("delix: gitleaks found a secret in the staged changes; commit blocked.\n" + "\n".join(summary))
        if r.returncode not in (0, 2):
            deny(f"delix: gitleaks failed (code {r.returncode}); commit blocked. Output: {(r.stderr or '')[:300]}")
    else:
        warn = os.path.join(cwd, ".delix", "warnings.log")
        os.makedirs(os.path.dirname(warn), exist_ok=True)
        with open(warn, "a", encoding="utf-8") as f:
            f.write("gitleaks missing: commit passed without secret scan\n")
sys.exit(0)
