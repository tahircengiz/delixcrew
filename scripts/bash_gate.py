#!/usr/bin/env python3
"""PreToolUse (Bash): reviewer roles may run only read-only commands; in the implementer worktree, gitleaks runs
before commit, shell writes to protected paths are blocked, a push goes only to the card's own branch on origin,
`gh pr merge` is denied, and git commands that write refs or remotes are denied."""
import os
import re
import shutil
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import REVIEWERS, card_path, delix_json, deny, git, matches, read_input  # noqa: E402

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
if not isinstance(cfg, dict):  # R-U4: the rules below read cfg; a list, string, number or null is not a config
    deny("delixcrew: docs/delix/delix.json is not a JSON object; Bash stays blocked in this card worktree until the "
         "user fixes it from their own terminal")
protected = cfg.get("protected_paths") or []

# writing to a protected path via shell redirect / cp / mv / tee
for m in re.finditer(r"(?:>>?|\bcp\b[^|;&]*|\bmv\b[^|;&]*|\btee\b)\s+([^\s;&|]+)", cmd):
    target = m.group(1).strip("'\"")
    d = matches(target, protected, cwd)
    if d:
        deny(f"delixcrew: the command writes to a protected path ('{target}' ~ {d}). Tier 3 path; human approval required.")

# T041 (spec C section 6, K279): in the implementer worktree a push goes only to the card's own branch on origin,
# from a branch other than the default; `gh pr merge` is gate 2, the user's. A pattern check on words over the full
# text (no heredoc exemption), allowlist, fail closed. Every step is a character class or a token comparison
# (linear); command names compare casefolded (`GIT` and `GH` resolve on a case-insensitive file system).
PUSH_DENY = ("delixcrew: an implementer session pushes only its own card branch (git push [-u] origin <branch>); the "
             "default branch and every other push run from the user's own terminal")
MERGE_DENY = "delixcrew: gate 2 (merge) is the user's; an implementer session does not run gh pr merge"
REF_DENY = ("delixcrew: an implementer session does not write git refs or change remotes (update-ref, remote set-head, "
            "set-url, add, remove); those run from the user's own terminal")
ENC_DENY = ("delixcrew: a git setting or ref name holds a byte that is not UTF-8, which this hook cannot read; "
            "the command is denied until the user removes it from their own terminal")
GIT_ARG_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--attr-source",
                "--shallow-file"}  # R-P2: take the next token
GIT_FLAG_OPTS = {"-v", "--version", "-h", "--help", "-p", "--paginate", "-P", "--no-pager", "--no-replace-objects",
                 "--no-lazy-fetch", "--no-optional-locks", "--no-advice", "--bare", "--literal-pathspecs",
                 "--glob-pathspecs", "--noglob-pathspecs", "--icase-pathspecs", "--exec-path", "--html-path",
                 "--man-path", "--info-path"}  # R-P2a: no value; `--name=value` is one token; any other option denies
PUSH_OPTS = {"-u", "--set-upstream", "--force-with-lease"}
CONFIG_KEYS = ("alias.", "remote.", "push.", "url.", "include", "help.")  # R-P5, casefold prefixes
AUTOCORRECT_OFF = {"0", "false", "off", "no", "show", "never"}  # R-P4a: help.autocorrect values that run nothing
PUSH_PEERS = {"add", "commit", "status", "diff", "log", "show"}  # R-P3b: git commands a push may share a line with
CONFIG_READS = {"--get", "--get-all", "--get-regexp", "--get-urlmatch", "--list", "-l", "get", "list"}


def words(text):
    """R-P1: one token list per segment. Quotes and backslashes removed; a redirection token is dropped, and when it
    is only the operator, the next token too."""
    segs = []
    for seg in re.split(r"[;&|(){}\n\r`]", text.translate({34: None, 39: None, 92: None})):
        toks, skip = [], False
        for t in re.split(r"[\s,\[\]]+", seg):
            if not t:
                continue
            if skip:
                skip = False
                continue
            rest = t.lstrip("0123456789")
            if rest[:1] in ("<", ">"):
                skip = not rest.strip("<>")
                continue
            toks.append(t)
        segs.append(toks)
    return segs


def remote_writes(toks, k, n):
    """R-U2: True unless `git remote` has no subcommand or `show` / `get-url`, after any -v / --verbose. `k` is the
    index of the first token after `remote`, `n` the token count."""
    while k < n and toks[k] in ("-v", "--verbose"):
        k += 1
    return k < n and toks[k].casefold() not in ("show", "get-url")


def git_text(*args):
    """R-U5: git(cwd, *args); a byte that is not UTF-8 in its output denies with a message, it does not raise."""
    try:
        return git(cwd, *args)
    except UnicodeDecodeError:
        deny(ENC_DENY)


def git_unset(*args):
    """R-P3a: stdout of a config / symbolic-ref read; "" for exit 1 with empty stdout (not set). Any other result
    (no git, timeout, another exit code, exit 1 with output) denies."""
    r = git_text(*args)
    if r is None or r.returncode not in (0, 1) or (r.returncode == 1 and r.stdout):
        deny(PUSH_DENY)
    return r.stdout if r.returncode == 0 else ""


_branch = []


def push_branch():
    """R-P3: the current branch, read once per command; denies on a detached HEAD, a default branch name, a failed
    git call or a configured remote.origin.push."""
    if not _branch:
        r = git_text("symbolic-ref", "--quiet", "--short", "HEAD")
        b = r.stdout.strip() if r is not None and r.returncode == 0 else ""
        db = cfg.get("default_branch")
        if not b or (db is not None and not isinstance(db, str)):
            deny(PUSH_DENY)
        names = {"main", "master", db or "main"}
        oh = git_unset("symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD").strip()
        if oh:
            names.add(oh[len("origin/"):] if oh.startswith("origin/") else oh)
        if b.casefold() in {x.casefold() for x in names} or git_unset("config", "--get-all", "remote.origin.push"):
            deny(PUSH_DENY)
        _branch.append(b)
    return _branch[0]


_upstream = {}


def own_upstream(b):
    """User addition (2026-11-12): with push.default=upstream git sends the name `<b>` to its upstream branch
    (builtin/push.c, refspec_append_mapped), so the name form needs branch.<b>.merge unset or naming b itself. Read
    once per command: one git call per push segment could run past the hook timeout."""
    if b not in _upstream:
        _upstream[b] = set(git_unset("config", "--get-all", "branch." + b + ".merge").split()) <= {b, "refs/heads/" + b}
    return _upstream[b]


_aliases = []


def alias_check(name):
    """R-P4: follow an alias to the first token of each value, at most 10 names deep; deny on `!`, a push, send-pack
    or http-push token, or a longer chain. The list is read once per command, when a subcommand needs it."""
    if not _aliases:
        amap, last = {}, None
        for line in git_unset("config", "--get-regexp", "^alias\\.").split("\n"):
            if line.casefold().startswith("alias."):
                key, _, val = line.partition(" ")
                last = amap.setdefault(key[len("alias."):].casefold(), [])
                last.append(val)
            elif last:
                last[-1] += "\n" + line  # a value with a newline goes on over the next line
        _aliases.extend([amap, set()])
    amap, ok = _aliases
    if name in ok:
        return
    frontier, depth = {name}, 0
    while frontier & amap.keys():
        depth += 1
        if depth > 10:
            deny(PUSH_DENY)
        nxt = set()
        for a in frontier & amap.keys():
            for v in amap[a]:
                vt = [t.casefold() for s in words(v) for t in s]
                if v.lstrip().startswith("!") or {"push", "send-pack", "http-push"} & set(vt):
                    deny(PUSH_DENY)
                if "update-ref" in vt or (vt[:1] == ["remote"] and remote_writes(vt, 1, len(vt))):  # R-U3
                    deny(REF_DENY)
                nxt.update(vt[:1])
        frontier = nxt
    ok.add(name)


_known = []


def autocorrect_check(name):
    """R-P4a: with help.autocorrect on, git runs the closest command in place of a name it does not know (`psuh`),
    so such a name denies. The setting is read once per command; the command list (builtins, main, others, alias)
    only when the setting is on."""
    if not _known:
        v = git_unset("config", "--get", "help.autocorrect")  # "" only when unset; a key with no value prints "\n"
        on = v != "" and v.strip().casefold() not in AUTOCORRECT_OFF
        _known.append({x.casefold() for x in git_unset("--list-cmds=builtins,main,others,alias").split()} if on
                      else None)
    if _known[0] is not None and name not in _known[0]:
        deny(PUSH_DENY)


segs = words(cmd)
moved = any(t.casefold() in ("cd", "pushd", "popd") for toks in segs for t in toks)
pushed = other = False  # R-P3b
for toks in segs:
    n = len(toks)
    i = 0
    while i < n:  # R-P6: gh pr [-R <repo> | --option]... merge
        t = toks[i].casefold()
        if (t == "gh" or t.endswith("/gh")) and i + 1 < n and toks[i + 1].casefold() == "pr":
            i += 2
            while i < n and toks[i].startswith("-"):
                i += 2 if toks[i] in ("-R", "--repo") else 1
            if i < n and toks[i].casefold() == "merge":
                deny(MERGE_DENY)
        else:
            i += 1
    reads = keys = None  # R-P5: does the rest of the segment from index x hold a read flag / a config key
    i = 0
    while i < n:  # R-P2: one left-to-right pass
        t = toks[i].casefold()
        if t == "git" or t.endswith("/git"):
            j, gopt = i + 1, False
            while j < n and toks[j].startswith("-"):
                gopt = True
                if toks[j] in GIT_ARG_OPTS:
                    if (toks[j] in ("-c", "--config-env") and j + 1 < n
                            and toks[j + 1].casefold().startswith(CONFIG_KEYS)):
                        deny(PUSH_DENY)
                    j += 1
                elif toks[j].startswith("--config-env=") and toks[j][13:].casefold().startswith(CONFIG_KEYS):
                    deny(PUSH_DENY)  # R-P5: --config-env sets a key like -c
                elif toks[j] not in GIT_FLAG_OPTS and not (toks[j].startswith("--") and "=" in toks[j]):
                    deny(PUSH_DENY)  # R-P2a: an option git may take a value for (--attr-source, ...)
                j += 1
            if j >= n:
                break
            sub = toks[j].casefold()
        elif t.rsplit("/", 1)[-1] in ("git-push", "git-send-pack", "git-update-ref", "git-remote"):
            j, gopt, sub = i, False, t.rsplit("/", 1)[-1][len("git-"):]
        else:
            i += 1
            continue
        if sub == "update-ref" or (sub == "remote" and remote_writes(toks, j + 1, n)):  # R-U1, R-U2
            deny(REF_DENY)
        if sub in ("send-pack", "http-push", "subtree"):
            deny(PUSH_DENY)
        if sub == "push":  # R-P3: first token, no global option, no cd; [opts] origin <HEAD|current branch>
            k = j + 1
            while k < n and toks[k] in PUSH_OPTS:
                k += 1
            if (i != 0 or gopt or moved or n - k != 2 or toks[k] != "origin"
                    or toks[k + 1] not in ("HEAD", push_branch())
                    or (toks[k + 1] != "HEAD" and not own_upstream(toks[k + 1]))):
                deny(PUSH_DENY)
            pushed = True
            break
        if gopt or sub not in PUSH_PEERS:
            other = True
        alias_check(sub)
        autocorrect_check(sub)
        if sub == "config":
            if reads is None:
                reads, keys = [False] * (n + 1), [False] * (n + 1)
                for x in range(n - 1, -1, -1):
                    reads[x] = reads[x + 1] or toks[x] in CONFIG_READS
                    keys[x] = keys[x + 1] or toks[x].casefold().startswith(CONFIG_KEYS)
            if keys[j + 1] and not reads[j + 1]:
                deny(PUSH_DENY)
        i = j + 1

if pushed and other:  # R-P3b: another git command on the line may move HEAD or the upstream before the push runs
    deny(PUSH_DENY)

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
