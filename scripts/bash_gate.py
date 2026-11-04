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

# REQ-7: known feedback send paths, in every session (before the card and agent_type checks); known paths only (K77)
FEEDBACK_DENY = "delixcrew: feedback is sent only by the user from their own terminal"
# (a) and (b) skip a heredoc body only when the whole command is exactly one capture call (allowlist):
# `python3 <path>/feedback.py add <<'DELIM'` (quoted delimiter: no expansion), body, `DELIM` as the last line.
# The path is literal (no `$`, nothing the shell expands); each path part is one repeated character class, so a
# failing fullmatch cannot backtrack exponentially (ReDoS). Any other shape is checked as full text.
_QPATH = r"\"(?!-)(?:[^\"\n$`\\]*/)?feedback\.py\""
_PATH = r"(?!-)(?:[^\s'\"$`\\;&|<>(){}#*?\[\]~^]*/)?feedback\.py"
ADD_HEREDOC = re.compile(r"(python3[ \t]+(?:" + _QPATH + "|" + _PATH + r")[ \t]+add[ \t]+<<(['\"])([A-Za-z_][\w.-]*)\2)"
                         r"\n(.*)\n\3", re.S)
# The same shape for exactly one `python3 <path>/triage.py record <n> <<'DELIM'` call.
_TQPATH = r"\"(?!-)(?:[^\"\n$`\\]*/)?triage\.py\""
_TPATH = r"(?!-)(?:[^\s'\"$`\\;&|<>(){}#*?\[\]~^]*/)?triage\.py"
RECORD_HEREDOC = re.compile(r"(python3[ \t]+(?:" + _TQPATH + "|" + _TPATH + r")[ \t]+record[ \t]+\d+[ \t]+<<(['\"])"
                            r"([A-Za-z_][\w.-]*)\2)\n(.*)\n\3", re.S)
# REQ-3 (#36, K182, K187): no path starts with `-` (`python3 -ic<dir>/feedback.py` runs the body as code); one
# capture match of either script limits the feedback and the triage (a)/(b) rules to its first line (order unchanged).
m = ADD_HEREDOC.fullmatch(cmd.strip()) or RECORD_HEREDOC.fullmatch(cmd.strip())
checked = m.group(1) if m and m.group(3) not in m.group(4).split("\n") else cmd
if re.search(r"\bfeedback\.py['\"]?(?:\s*,\s*|\s+)(?:-\S+\s+)*['\"]?send\b", checked) or (
        re.search(r"\bfeedback\.py\b", checked) and re.search(r"\b(script|expect|unbuffer)\b|\bpty\.spawn\b", checked)):
    deny(FEEDBACK_DENY)
if re.search(r"\bgh\s+issue\s+(create|new|comment|edit)\b", cmd) or (re.search(r"\bgh\s+api\b", cmd)
                                                                 and re.search(r"\bissues\b", cmd)):
    if "delixcrew" in cmd.lower():
        deny(FEEDBACK_DENY)
    try:
        remotes = subprocess.run(["git", "-C", cwd, "remote", "-v"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        remotes = ""
    if re.search(r"[/:]tahircengiz/delixcrew(\.git)?/?\s", remotes, re.I):
        deny(FEEDBACK_DENY)

# REQ-7 (0.6.0): known triage write paths, in every session; (a)/(b) unconditional, (c)/(d) only for delixcrew (K125)
TRIAGE_DENY = "delixcrew: triage decisions are applied only by the user from their own terminal"
# (a) and (b) see `checked` from the feedback block: the first line of one capture call (ADD_HEREDOC or
# RECORD_HEREDOC, defined above), otherwise the full text. (c) and (d) see the full text.
tchecked = checked
if re.search(r"\btriage\.py['\"]?\s+(?:-\S+\s+)*['\"]?apply\b", tchecked) or (
        re.search(r"\btriage\.py\b", tchecked) and re.search(r"\b(script|expect|unbuffer)\b|\bpty\.spawn\b", tchecked)):
    deny(TRIAGE_DENY)
# (d) write flags: -f/-F (also attached, `-fq=x`), --field, --raw-field, --input, -X/--method other than GET
GH_API_WRITE = re.compile(r"\bgraphql\b|(?:^|\s)['\"]?(?:-i*[fF]|--(?:field|raw-field|input)\b)")
GH_API_METHOD = re.compile(r"(?:^|\s)['\"]?(?:-i*X|--method\b)[\s=]*['\"]?([A-Za-z]*)")
if re.search(r"\bgh\s+issue\s+(close|reopen|lock|unlock|delete|transfer|pin|unpin|develop)\b|\bgh\s+label\b", cmd) or (
        re.search(r"\bgh\s+api\b", cmd) and (GH_API_WRITE.search(cmd)
                                            or any(v.upper() != "GET" for v in GH_API_METHOD.findall(cmd)))):
    if "delixcrew" in cmd.lower():
        deny(TRIAGE_DENY)
    try:
        remotes = subprocess.run(["git", "-C", cwd, "remote", "-v"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        remotes = ""
    if re.search(r"[/:]tahircengiz/delixcrew(\.git)?/?\s", remotes, re.I):
        deny(TRIAGE_DENY)

GIT = r"git\s+(?:-C\s+(?:\"[^\"]*\"|'[^']*'|\S+)\s+)?"  # `git -C <worktree>`: the reviewer reads another checkout
WRITING = re.compile(r"(^|[\s;&|(])(rm|mv|cp|tee|sed\s+-i|chmod|chown|truncate|mkdir|touch|dd|" + GIT + r"(add|commit|push|"
                     r"checkout|switch|reset|rebase|merge|stash|apply|cherry-pick|tag|branch\s+-[dD]))\b|>>?\s*[^&\s]|"
                     r"\bpip\s+install\b|\bnpm\s+(i|install|ci)\b|\buv\s+(add|sync|pip)\b|\bbrew\s+install\b")
if agent in REVIEWERS:
    if agent.endswith("security"):
        allowed = re.compile(r"^(gitleaks|semgrep|pip-audit|trivy|osv-scanner|bandit|" + GIT + r"(diff|log|show|status|"
                             r"ls-files|grep)|rg|grep|cat|head|tail|wc|ls|find|jq|python3?\s+-m\s+pip\s+index)\b")
        if WRITING.search(cmd) or not allowed.match(cmd):
            deny("delixcrew: role 'security' may run only read-only scanners and git read commands "
                 "(gitleaks, semgrep, pip-audit, trivy, git [-C <dir>] diff/log/show, rg/grep/cat).")
        sys.exit(0)
    deny(f"delixcrew: role '{agent}' is read-only; it cannot run Bash.")

if not card_path(cwd):
    sys.exit(0)

cfg = delix_json(cwd)
protected = cfg.get("protected_paths") or []

# writing to a protected path via shell redirect / cp / mv / tee
for m in re.finditer(r"(?:>>?|\bcp\b[^|;&]*|\bmv\b[^|;&]*|\btee\b)\s+([^\s;&|]+)", cmd):
    target = m.group(1).strip("'\"")
    d = matches(target, protected, cwd)
    if d:
        deny(f"delixcrew: the command writes to a protected path ('{target}' ~ {d}). Tier 3 path; human approval required.")

if re.search(r"\bgit\s+commit\b", cmd):
    gl = shutil.which("gitleaks")
    if gl:
        r = subprocess.run([gl, "protect", "--staged", "--no-banner", "--redact", "--exit-code", "2"],
                           cwd=cwd, capture_output=True, text=True, timeout=50)
        if r.returncode == 2:
            summary = (r.stdout or r.stderr).strip().splitlines()[-8:]
            deny("delixcrew: gitleaks found a secret in the staged changes; commit blocked.\n" + "\n".join(summary))
        if r.returncode not in (0, 2):
            deny(f"delixcrew: gitleaks failed (code {r.returncode}); commit blocked. Output: {(r.stderr or '')[:300]}")
    else:
        warn = os.path.join(cwd, ".delix", "warnings.log")
        os.makedirs(os.path.dirname(warn), exist_ok=True)
        with open(warn, "a", encoding="utf-8") as f:
            f.write("gitleaks missing: commit passed without secret scan\n")
sys.exit(0)
