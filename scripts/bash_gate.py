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
# REQ-5 (K202, K211b): exactly one `cat >|>> <path> <<'DELIM'` call. The path is one repeated class (the _PATH
# exclusions, no optional directory group: ReDoS); `<<-` and an unquoted delimiter do not match. Group numbers match
# ADD_HEREDOC (1 header, 2 quote, 3 delimiter, 4 body). Matched against the raw command with only trailing newlines
# removed, so a delimiter line ending in `\r` or a space never matches (fail closed).
_CPATH = r"(?!-)[^\s'\"$`\\;&|<>(){}#*?\[\]~^]+"
CAT_HEREDOC = re.compile(r"(cat[ \t]+>>?[ \t]*" + _CPATH + r"[ \t]+<<(['\"])([A-Za-z_][\w.-]*)\2)\n(.*)\n\3", re.S)
# REQ-3 (#36, K182, K187): no path starts with `-` (`python3 -ic<dir>/feedback.py` runs the body as code).
# REQ-5 (K202, K204): one match of ADD_HEREDOC, RECORD_HEREDOC or CAT_HEREDOC without an early delimiter limits
# every rule below to its first line, except trust (c) and the protected-path redirect check (full text).
_raw = (g.get("tool_input") or {}).get("command") or ""
cm = CAT_HEREDOC.fullmatch(_raw.rstrip("\n"))
if cm and ".claude/delixcrew/" in cm.group(1).casefold():
    cm = None  # REQ-5: a path into the plugin's own record dirs gets no exemption (the delimiter cannot hold `/`)
m = ADD_HEREDOC.fullmatch(cmd.strip()) or RECORD_HEREDOC.fullmatch(cmd.strip()) or cm
checked = m.group(1) if m and m.group(3) not in m.group(4).split("\n") else cmd
if re.search(r"\bfeedback\.py['\"]?(?:\s*,\s*|\s+)(?:-\S+\s+)*['\"]?send\b", checked) or (
        re.search(r"\bfeedback\.py\b", checked) and re.search(r"\b(script|expect|unbuffer)\b|\bpty\.spawn\b", checked)):
    deny(FEEDBACK_DENY)
if re.search(r"\bgh\s+issue\s+(create|new|comment|edit)\b", checked) or (re.search(r"\bgh\s+api\b", checked)
                                                                 and re.search(r"\bissues\b", checked)):
    if "delixcrew" in checked.lower():
        deny(FEEDBACK_DENY)
    try:
        remotes = subprocess.run(["git", "-C", cwd, "remote", "-v"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        remotes = ""
    if re.search(r"[/:]tahircengiz/delixcrew(\.git)?/?\s", remotes, re.I):
        deny(FEEDBACK_DENY)

# REQ-7 (0.6.0): known triage write paths, in every session; (a)/(b) unconditional, (c)/(d) only for delixcrew (K125)
TRIAGE_DENY = "delixcrew: triage decisions are applied only by the user from their own terminal"
REPO_DENY = "delixcrew: writes to the delixcrew GitHub repository (settings, rulesets, security) run only from the user's own terminal"
# (a)-(d) see `checked` from the feedback block: the first line of one allowed heredoc call (ADD_HEREDOC,
# RECORD_HEREDOC or CAT_HEREDOC, K204), otherwise the full text.
tchecked = checked
if re.search(r"\btriage\.py['\"]?\s+(?:-\S+\s+)*['\"]?apply\b", tchecked) or (
        re.search(r"\btriage\.py\b", tchecked) and re.search(r"\b(script|expect|unbuffer)\b|\bpty\.spawn\b", tchecked)):
    deny(TRIAGE_DENY)
# (d) write flags: -f/-F (also attached, `-fq=x`), --field, --raw-field, --input, -X/--method other than GET
GH_API_WRITE = re.compile(r"\bgraphql\b|(?:^|\s)['\"]?(?:-i*[fF]|--(?:field|raw-field|input)\b)")
GH_API_METHOD = re.compile(r"(?:^|\s)['\"]?(?:-i*X|--method\b)[\s=]*['\"]?([A-Za-z]*)")
gh_c = re.search(r"\bgh\s+issue\s+(close|reopen|lock|unlock|delete|transfer|pin|unpin|develop)\b|\bgh\s+label\b", checked)
if gh_c or (re.search(r"\bgh\s+api\b", checked) and (GH_API_WRITE.search(checked)
                                                  or any(v.upper() != "GET" for v in GH_API_METHOD.findall(checked)))):
    # REQ-6 (K205): same deny condition; a gh api write naming none of issues/labels/graphql is a repo settings write
    msg = TRIAGE_DENY if gh_c or re.search(r"\b(?:issues|labels|graphql)\b", checked) else REPO_DENY
    if "delixcrew" in checked.lower():
        deny(msg)
    try:
        remotes = subprocess.run(["git", "-C", cwd, "remote", "-v"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        remotes = ""
    if re.search(r"[/:]tahircengiz/delixcrew(\.git)?/?\s", remotes, re.I):
        deny(msg)

# REQ-4 (K200, K210): the Stop gate approval, in every session, unconditional (like feedback (a)/(b)).
# (a) and (b) see `checked`; (c) sees the full text, so no heredoc exemption reaches it.
TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"
if (re.search(r"\btrust\.py\b", checked) and (re.search(r"\ballow\b", checked) or re.search(
        r"\b(?:script|expect|unbuffer|openpty|tmux|screen|socat|zpty)\b|\bpty\.(?:spawn|fork)\b", checked))) \
        or "delixcrew/trust.json" in cmd.casefold():
    deny(TRUST_DENY)

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
