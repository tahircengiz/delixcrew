#!/usr/bin/env python3
"""delixcrew feedback: local queue of plugin findings → sanitized GitHub issue (SPEC docs/delix/SPEC.md REQ-1…6, REQ-8).

Usage:
    python3 feedback.py enable [--terms a,b] | disable | status
    python3 feedback.py add                      # draft JSON on stdin
    python3 feedback.py list
    python3 feedback.py preview <id>
    python3 feedback.py send <id> --confirm <hash>   # only from your own terminal; asks for SEND <hash>
    python3 feedback.py drop <id>

Queue: $DELIXCREW_FEEDBACK_DIR (default ~/.claude/delixcrew/feedback). Stdlib only (K71).
Exit codes: 0 ok · 2 usage/schema · 3 opt-in off · 4 BLOCKED · 5 hash mismatch · 6 not confirmed on a TTY · 7 repo/gh error.
"""
import argparse
import datetime as dt
import getpass
import hashlib
import ipaddress
import json
import os
import platform
import re
import socket
import subprocess
import sys
import tempfile
import unicodedata
from urllib.parse import urlsplit

REPO = "tahircengiz/delixcrew"
REPO_URL = "https://github.com/" + REPO
GH_REPO_ARG = "github.com/" + REPO
SANITIZER_VERSION = "2"
LABELS = {"bug": "bug", "feature": "enhancement"}
GH_SCRUB = ("GH_HOST", "GH_REPO", "GH_ENTERPRISE_TOKEN", "GITHUB_ENTERPRISE_TOKEN")
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
PLUGIN_JSON = os.path.join(SCRIPT_DIR, "..", ".claude-plugin", "plugin.json")
ID_RE = re.compile(r"^F\d{3,}$")
RECORD_RE = re.compile(r"^F(\d{3,})\.json$")

FIELDS = ("kind", "component", "title", "actual", "expected", "repro", "context")
REQUIRED = ("kind", "component", "title", "actual", "expected", "repro")
TITLE_MAX, TEXT_MAX, STEPS_MAX = 120, 2000, 10
BODY_MAX, CODE_LINES_MAX = 8192, 15

# --- REQ-3 sanitizer ----------------------------------------------------------
ALLOWED_HOSTS = {"github.com", "code.claude.com", "docs.anthropic.com", "anthropic.com", "localhost"}
RESERVED_TLDS = {"example", "test", "invalid", "localhost"}  # RFC 2606
FILE_EXTS = set("""md markdown txt rst py pyc sh bash zsh fish js mjs cjs ts tsx jsx json jsonl yml yaml toml ini cfg conf
env lock log csv tsv xml html htm css scss sass less svg png jpg jpeg gif webp ico pdf zip tar gz tgz bz2 xz go rs rb java
kt kts swift c h cc cpp hpp cs php pl lua sql db sqlite ipynb plist patch diff out bak tmp pem crt pub mk gradle vue svelte
j2 jinja tpl tf hcl wasm so dylib dll exe bin iso img dmg pkg deb rpm whl""".split())
PLUGIN_TERMS = {"delixcrew", "tahircengiz/delixcrew", "delix", "tahircengiz"}  # the plugin owner is never a project term

PLACEHOLDER_RE = re.compile(r"(<redacted:[a-z]+>)")
_SEG = r"[^\s/`'\"<>()\[\],;]"
HOME_RE = re.compile(r"(?<![\w.~/:<>\]\\-])/(?:Users|home)/[^/\s,;:'\"`()<>]+(?=/|\s|$|[,;:'\"`()<>])")
WIN_HOME_RE = re.compile(r"(?<![\w])[A-Za-z]:\\Users\\[^\\\s]+", re.IGNORECASE)
_PATH_LB = r"(?<![\w.~/<>\]\\-])"  # K101: no ':' here, so name:/path is a path; '//' in a URL still is not
ABS_PATH_RE = re.compile(_PATH_LB + "/" + _SEG + r"+(?:/" + _SEG + r"*)+")
SINGLE_SEG_RE = re.compile(_PATH_LB + "/" + _SEG + r"+(?!/|" + _SEG + ")")  # REQ-12: /srv, /acme:builds
SKILLS_DIR = os.path.join(SCRIPT_DIR, "..", "skills")
BUILTIN_COMMANDS = set("""/agents /clear /compact /config /context /cost /doctor /exit /export /help /hooks /init /login
/logout /mcp /memory /model /permissions /plugin /resume /review /status""".split())
WIN_ABS_RE = re.compile(r"(?<![\w])[A-Za-z]:\\[^\s]+")
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+")
MAC_RE = re.compile(r"(?<![\w:-])[0-9A-Fa-f]{2}([:-])[0-9A-Fa-f]{2}(?:\1[0-9A-Fa-f]{2}){4}(?![\w:-])")
IPV4_RE = re.compile(r"(?<![\w.])\d{1,3}(?:\.\d{1,3}){3}(?!\w|\.\d)")
IPV6_RE = re.compile(r"(?<![\w:.])[0-9A-Fa-f]*:[0-9A-Fa-f:]*:[0-9A-Fa-f]*(?![\w:])")
TOKEN_RE = re.compile(r"(?<![\w.@-])[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+(?![\w-])")
LAST_LABEL_RE = re.compile(r"[A-Za-z][A-Za-z0-9-]*")
DOC_NETS = [ipaddress.ip_network(n) for n in ("192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24", "2001:db8::/32")]

# --- REQ-4 blockers -----------------------------------------------------------
OPAQUE_RE = re.compile(r"[A-Za-z0-9+=_-]{32,}")  # K81: no '/' or '.'
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
RULE_RE = re.compile(r"RuleID:\s*([\w.-]+)")


def err(msg):
    print(msg, file=sys.stderr)


def queue_dir():
    return os.path.expanduser(os.environ.get("DELIXCREW_FEEDBACK_DIR") or "~/.claude/delixcrew/feedback")


def now():
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def write_json(path, data):
    """Atomic write (tmp + rename), owner-only."""
    d = os.path.dirname(path)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def ensure_queue():
    os.makedirs(queue_dir(), mode=0o700, exist_ok=True)


def load_config():
    c = read_json(os.path.join(queue_dir(), "config.json"))
    if not isinstance(c, dict):
        return {"enabled": False, "extra_terms": []}
    terms = c.get("extra_terms")
    return {"enabled": c.get("enabled") is True,
            "extra_terms": [t for t in terms if isinstance(t, str)] if isinstance(terms, list) else []}


def load_records():
    """Returns (records sorted by number, ids of unreadable record files)."""
    out, bad = [], []
    try:
        names = os.listdir(queue_dir())
    except OSError:
        return [], []
    for name in names:
        m = RECORD_RE.match(name)
        if not m:
            continue
        r = read_json(os.path.join(queue_dir(), name))
        if isinstance(r, dict):
            out.append((int(m.group(1)), r))
        else:
            bad.append(name[:-5])
    return [r for _, r in sorted(out, key=lambda x: x[0])], sorted(bad)


def record_path(rid):
    return os.path.join(queue_dir(), rid + ".json")


def plugin_meta():
    p = read_json(PLUGIN_JSON)
    return p if isinstance(p, dict) else {}


def fingerprint(kind, component, title):
    t = unicodedata.normalize("NFKC", title).lower()
    t = "".join(" " if (unicodedata.category(c).startswith("P") or c.isdigit()) else c for c in t)
    t = " ".join(t.split())
    return hashlib.sha256(f"{kind}|{component}|{t}".encode("utf-8")).hexdigest()[:16]


# --- sanitizer ----------------------------------------------------------------
def is_allowed_host(host):
    h = host.lower().rstrip(".")
    labels = h.split(".")
    if h in ALLOWED_HOSTS or labels[-1] in RESERVED_TLDS:
        return True
    return len(labels) >= 2 and labels[-2] == "example" and labels[-1] in ("com", "net", "org")


def _host_repl(m):
    tok = m.group(0)
    last = tok.rsplit(".", 1)[-1]
    if len(last) < 2 or not LAST_LABEL_RE.fullmatch(last) or last.lower() in FILE_EXTS or is_allowed_host(tok):
        return tok
    return "<redacted:host>"


def _ip_allowed(ip):
    return ip.is_loopback or any(ip.version == n.version and ip in n for n in DOC_NETS)


def _ipv4_repl(m):
    try:
        ip = ipaddress.IPv4Address(m.group(0))
    except ValueError:
        return m.group(0)
    return m.group(0) if _ip_allowed(ip) else "<redacted:ip>"


def _ipv6_repl(m):
    try:
        ip = ipaddress.IPv6Address(m.group(0))
    except ValueError:
        return m.group(0)
    return m.group(0) if _ip_allowed(ip) else "<redacted:ip>"


def _sub_outside(regex, repl, text):
    """Applies regex only outside <redacted:…> placeholders."""
    parts = PLACEHOLDER_RE.split(text)
    return "".join(p if i % 2 else regex.sub(repl, p) for i, p in enumerate(parts))


def local_terms():
    names = set()
    user = os.environ.get("USER")
    if not user:
        try:
            user = getpass.getuser()
        except Exception:
            user = ""
    names.add(user)
    try:
        host = socket.gethostname()
    except OSError:
        host = ""
    names.update({host, host.split(".")[0]})
    return {n for n in names if n and not is_allowed_host(n)}


def term_regex(terms):
    # K82: case-insensitive substring; terms shorter than 3 characters are ignored. Longest first.
    ts = sorted({t.strip().lower() for t in terms if len(t.strip()) >= 3}, key=lambda t: (-len(t), t))
    return re.compile("|".join(re.escape(t) for t in ts), re.IGNORECASE) if ts else None


def _single_seg_repl(m):
    """REQ-12 allowlist: only /delixcrew:<skill> and the built-in commands stay (K94, K100); trailing .,;:) is kept."""
    tok = m.group(0)
    core = tok.rstrip(".,;:)")
    if core.isascii() and (core in BUILTIN_COMMANDS or
                           (core.startswith("/delixcrew:") and core[len("/delixcrew:"):] in plugin_skills())):
        return tok
    return "<redacted:path>" + tok[len(core):]


def plugin_skills():
    """Directory names under the plugin's skills/, read at run time; empty if unreadable (fail-closed)."""
    try:
        return {n for n in os.listdir(SKILLS_DIR) if os.path.isdir(os.path.join(SKILLS_DIR, n))}
    except OSError:
        return set()


def sanitize(text, term_re):
    t = unicodedata.normalize("NFKC", text)
    t = HOME_RE.sub("~", t)
    t = WIN_HOME_RE.sub("~", t)
    for regex, repl in ((ABS_PATH_RE, "<redacted:path>"), (SINGLE_SEG_RE, _single_seg_repl), (WIN_ABS_RE, "<redacted:path>"),
                        (EMAIL_RE, "<redacted:email>"), (MAC_RE, "<redacted:mac>"),
                        (IPV4_RE, _ipv4_repl), (IPV6_RE, _ipv6_repl), (TOKEN_RE, _host_repl)):
        t = _sub_outside(regex, repl, t)
    if term_re:
        t = _sub_outside(term_re, "<redacted:term>", t)
    return t


# --- REQ-4 checks -------------------------------------------------------------
def gitleaks(text):
    try:
        p = subprocess.run(["gitleaks", "stdin", "--no-banner", "--redact", "--exit-code", "2", "-v"],
                           input=text, capture_output=True, text=True, timeout=30)
    except FileNotFoundError:
        return "gitleaks not found"
    except subprocess.TimeoutExpired:
        return "gitleaks failed (timeout)"
    except OSError:
        return "gitleaks failed (not runnable)"
    if p.returncode == 0:
        return None
    if p.returncode == 2:
        m = RULE_RE.search(ANSI_RE.sub("", p.stdout + "\n" + p.stderr))
        return "gitleaks (rule %s)" % (m.group(1) if m else "unknown")
    return "gitleaks failed (rc %d)" % p.returncode


def code_lines(body):
    n, fence = 0, False
    for line in body.splitlines():
        if line.lstrip().startswith(("```", "~~~")):
            fence = not fence
        elif fence or line.startswith(("    ", "\t")):
            n += 1
    return n


def bad_char(c):
    """Cc (except newline and tab), Cf and Co can make the terminal show other text than is sent."""
    return c not in "\n\t" and unicodedata.category(c) in ("Cc", "Cf", "Co")


def build(rec, records, config, bad_ids=()):
    """Builds the issue content in memory. Returns (content dict, BLOCKED reasons, 12-hex hash)."""
    terms = set(config["extra_terms"]) | local_terms()
    for r in records:
        terms.update(t for t in (r.get("origin_terms") or []) if isinstance(t, str))
    term_re = term_regex(terms)
    s = lambda v: sanitize(v, term_re)  # noqa: E731
    repro = [x for x in rec.get("repro") or [] if isinstance(x, str)]
    raw_vals = [rec.get("title", ""), rec.get("component", ""), rec.get("actual", ""), rec.get("expected", ""),
                *repro, rec.get("context") or "", str(rec.get("plugin_version", "")),
                str(rec.get("claude_version", "")), str(rec.get("os", ""))]
    v = {k: s(str(rec.get(k) or "")) for k in ("title", "component", "actual", "expected", "context")}
    v.update({k: s(str(rec.get(k) or "unknown")) for k in ("plugin_version", "claude_version", "os")})
    steps = [s(x) for x in repro]
    title = v["title"]
    main = "\n".join([
        "### Component", v["component"], "",
        "### Version", "plugin %s, Claude Code %s, %s" % (v["plugin_version"], v["claude_version"], v["os"]), "",
        "### What happened", v["actual"], "",
        "### Expected", v["expected"], "",
        "### Steps to reproduce", "\n".join("%d. %s" % (i, x) for i, x in enumerate(steps, 1)) or "(none)", "",
        "### Context", v["context"] or "(none)",
    ])
    body = main + "\n\ndelixcrew-fp: " + rec.get("fingerprint", "")
    content = {"repo": REPO, "label": LABELS.get(rec.get("kind"), "bug"), "title": title, "body": body}

    raw = unicodedata.normalize("NFKC", "\n".join(raw_vals))
    clean = title + "\n" + main
    reasons = []
    for r in (gitleaks(raw), gitleaks(clean)):
        if r and r not in reasons:
            reasons.append(r)
    if any(bad_char(c) for c in "\n".join(raw_vals) + clean):
        reasons.append("unicode control character (Cc/Cf/Co)")
    try:
        fp_ok = rec.get("fingerprint") == fingerprint(rec.get("kind"), rec.get("component"), rec.get("title"))
    except (TypeError, AttributeError):
        fp_ok = False
    if not fp_ok:
        reasons.append("fingerprint mismatch (record changed on disk)")
    if OPAQUE_RE.search(raw) or OPAQUE_RE.search(clean):
        reasons.append("opaque string of 32+ characters")
    if code_lines(main) > CODE_LINES_MAX:
        reasons.append("more than %d code lines" % CODE_LINES_MAX)
    if len(body.encode("utf-8")) > BODY_MAX:
        reasons.append("body > 8 KB")
    if any(s(x) != x for x in list(v.values()) + steps):
        reasons.append("residual match after sanitizing")
    if bad_ids:
        reasons.append("unreadable queue record %s" % ", ".join(bad_ids))
    canon = json.dumps(dict(content, sanitizer_version=SANITIZER_VERSION), sort_keys=True,
                       ensure_ascii=False, separators=(",", ":"))
    return content, reasons, hashlib.sha256(canon.encode("utf-8")).hexdigest()[:12]


# --- add ----------------------------------------------------------------------
def validate(d):
    if not isinstance(d, dict):
        return "draft: must be a JSON object"
    for k in d:
        if k not in FIELDS:
            return "%s: unknown field" % k
    for k in REQUIRED:
        if k not in d:
            return "%s: missing required field" % k
    if not isinstance(d["kind"], str) or d["kind"] not in LABELS:
        return "kind: must be bug or feature"
    for k in ("component", "title", "actual", "expected", "context"):
        if k in d and not isinstance(d[k], str):
            return "%s: must be a string" % k
    if not isinstance(d["repro"], list) or not all(isinstance(x, str) for x in d["repro"]):
        return "repro: must be a list of strings"
    for k in ("component", "title", "actual", "expected", "context", "repro"):
        vals = d.get(k) if k == "repro" else [d.get(k) or ""]
        if any(unicodedata.category(c) == "Cc" and c not in "\n\t" for x in vals for c in x):
            return "%s: control character (only newline and tab allowed)" % k
    for k in ("component", "title"):
        if not d[k].strip():
            return "%s: must not be empty" % k
    if len(d["title"]) > TITLE_MAX:
        return "title: longer than %d characters" % TITLE_MAX
    for k in ("component", "actual", "expected", "context"):
        if k in d and len(d[k]) > TEXT_MAX:
            return "%s: longer than %d characters" % (k, TEXT_MAX)
    if len(d["repro"]) > STEPS_MAX:
        return "repro: more than %d steps" % STEPS_MAX
    if any(len(x) > TEXT_MAX for x in d["repro"]):
        return "repro: a step is longer than %d characters" % TEXT_MAX
    return None


def remote_parts(url):
    """git remote URL → (host, [path segments])."""
    if "://" in url:
        u = urlsplit(url)
        host, path = u.hostname or "", u.path
    else:
        m = re.match(r"^(?:[^@/]+@)?([^:/]+):(.+)$", url)
        if not m:
            return "", []
        host, path = m.group(1), m.group(2)
    path = path.strip("/")
    if path.endswith(".git"):
        path = path[:-4]
    return host, [p for p in path.split("/") if p]


def origin_terms(cwd):
    terms = [os.path.basename(cwd.rstrip(os.sep))]
    try:
        p = subprocess.run(["git", "remote", "-v"], cwd=cwd, capture_output=True, text=True, timeout=10)
        lines = p.stdout.splitlines() if p.returncode == 0 else []
    except (OSError, subprocess.TimeoutExpired):
        lines = []
    for line in lines:
        f = line.split()
        if len(f) < 2:
            continue
        host, segs = remote_parts(f[1])
        terms.append(host)
        if "/".join(segs[-2:]).lower() != REPO:  # the plugin's own repo is not a project secret
            terms.extend(segs)
    out = []
    for t in terms:
        if t and t.lower() not in PLUGIN_TERMS and not is_allowed_host(t) and t not in out:
            out.append(t)
    return out


def claude_version():
    try:
        p = subprocess.run(["claude", "--version"], capture_output=True, text=True, timeout=10)
        m = re.search(r"\d+\.\d+[\w.+-]*", p.stdout)
        if p.returncode == 0 and m:
            return m.group(0)
    except (OSError, subprocess.TimeoutExpired):
        pass
    return "unknown"


def cmd_add(_args):
    if not load_config()["enabled"]:
        err("delixcrew feedback is off; enable: python3 %s/feedback.py enable" % SCRIPT_DIR)
        return 3
    try:
        d = json.loads(sys.stdin.read())
    except ValueError:
        err("error: stdin: invalid JSON")
        return 2
    problem = validate(d)
    if problem:
        err("error: " + problem)
        return 2
    ensure_queue()
    fp = fingerprint(d["kind"], d["component"], d["title"])
    terms = origin_terms(os.getcwd())
    records, _ = load_records()
    for r in records:
        if r.get("fingerprint") == fp:
            r["count"] = int(r.get("count", 1)) + 1
            r["last_seen"] = now()
            r["origin_terms"] = list(r.get("origin_terms") or []) + [t for t in terms if t not in (r.get("origin_terms") or [])]
            write_json(record_path(r["id"]), r)
            print("%s duplicate (count %d, %s)" % (r["id"], r["count"], r.get("status")))
            return 0
    n = max([int(RECORD_RE.match(r["id"] + ".json").group(1)) for r in records if ID_RE.match(str(r.get("id", "")))] or [0]) + 1
    ts = now()
    meta = plugin_meta()
    while True:
        rid = "F%03d" % n
        rec = dict(d, id=rid, fingerprint=fp, status="draft", count=1, first_seen=ts, last_seen=ts,
                   plugin_version=str(meta.get("version", "unknown")), claude_version=claude_version(),
                   os=platform.system() or "unknown", origin_terms=terms, issue_url=None)
        try:
            fd = os.open(record_path(rid), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            n += 1
            continue
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(rec, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print("%s new" % rid)
        return 0


# --- other commands -----------------------------------------------------------
def cmd_enable(args):
    ensure_queue()
    c = load_config()
    c["enabled"] = True
    if args.terms is not None:
        c["extra_terms"] = [t.strip() for t in args.terms.split(",") if t.strip()]
    write_json(os.path.join(queue_dir(), "config.json"), c)
    print("delixcrew feedback enabled (queue %s)" % queue_dir())
    return 0


def cmd_disable(_args):
    ensure_queue()
    c = load_config()
    c["enabled"] = False
    write_json(os.path.join(queue_dir(), "config.json"), c)
    print("delixcrew feedback disabled")
    return 0


def cmd_status(_args):
    records, _ = load_records()
    print("enabled: %s" % ("yes" if load_config()["enabled"] else "no"))
    print("queue: %s" % queue_dir())
    print("drafts: %d" % sum(1 for r in records if r.get("status") == "draft"))
    return 0


def cmd_list(_args):
    records, bad = load_records()
    rows = [("id", "kind", "component", "count", "status", "title")]
    rows += [(str(r.get("id", "")), str(r.get("kind", "")), str(r.get("component", "")), str(r.get("count", "")),
              str(r.get("status", "")), str(r.get("title", ""))) for r in records]
    w = [max(len(row[i]) for row in rows) for i in range(5)]
    for row in rows:
        print("  ".join(row[i].ljust(w[i]) for i in range(5)) + "  " + row[5])
    for b in bad:
        err("warning: unreadable record %s" % b)
    return 0


def get_record(rid, records):
    if not ID_RE.match(rid):
        return None
    return next((r for r in records if r.get("id") == rid), None)


def cmd_preview(args):
    records, bad = load_records()
    rec = get_record(args.id, records)
    if rec is None:
        err("error: unknown id %s" % args.id)
        return 2
    content, reasons, h = build(rec, records, load_config(), bad)
    if reasons:
        # Title and body are withheld: they may contain the very value that blocked them.
        print("VERDICT: BLOCKED: " + "; ".join(reasons))
        print("REPO: %s\nLABEL: %s" % (content["repo"], content["label"]))
        return 4
    print("VERDICT: CLEAN\nHASH: %s\nREPO: %s\nLABEL: %s\nTITLE: %s\n---\n%s"
          % (h, content["repo"], content["label"], content["title"], content["body"]))
    return 0


def cmd_drop(args):
    records, _ = load_records()
    rec = get_record(args.id, records)
    if rec is None:
        err("error: unknown id %s" % args.id)
        return 2
    rec["status"] = "dropped"
    write_json(record_path(rec["id"]), rec)
    print("%s status: dropped" % rec["id"])
    return 0


def repo_ok():
    repo = plugin_meta().get("repository")
    if isinstance(repo, dict):
        repo = repo.get("url")
    if not isinstance(repo, str):
        return False
    repo = repo.strip().rstrip("/")
    return (repo[:-4] if repo.endswith(".git") else repo) == REPO_URL


def gh(args, env):
    """Runs gh against the fixed repo. Returns (stdout, None) or (None, one-line error)."""
    try:
        p = subprocess.run(["gh", args[0], args[1], "-R", GH_REPO_ARG] + args[2:], env=env,
                           capture_output=True, text=True, timeout=60)
    except FileNotFoundError:
        return None, "gh not found"
    except (OSError, subprocess.TimeoutExpired) as e:
        return None, type(e).__name__
    if p.returncode != 0:
        lines = [x for x in p.stderr.splitlines() if x.strip()]
        return None, "rc %d: %s" % (p.returncode, lines[0].strip() if lines else "no output")
    return p.stdout, None


def cmd_send(args):
    # 1. fixed target repo
    if not repo_ok():
        err("delixcrew feedback: plugin.json repository is not %s; refusing to send" % REPO_URL)
        return 7
    # 2. build in memory; nothing is read from disk after this point
    records, bad = load_records()
    rec = get_record(args.id, records)
    if rec is None:
        err("error: unknown id %s" % args.id)
        return 2
    # REQ-13: only a draft is sent; a value read from disk is never printed
    status = rec.get("status")
    if status != "draft":
        err("error: %s is %s; nothing sent" % (args.id, status if status in ("sent", "duplicate", "dropped") else "unknown"))
        return 2
    content, reasons, h = build(rec, records, load_config(), bad)
    if reasons:
        print("VERDICT: BLOCKED: " + "; ".join(reasons))
        return 4
    # 3. hash binding
    if h != args.confirm:
        err("content changed since preview; run preview again")
        return 5
    # 4–5. the user's own terminal
    if not sys.stdin.isatty():
        err("delixcrew feedback: send needs your own terminal (stdin is not a TTY); nothing sent")
        return 6
    print("QUEUE: %s\nREPO: %s\nLABEL: %s\nTITLE: %s\n---\n%s\n---"
          % (queue_dir(), content["repo"], content["label"], content["title"], content["body"]))
    sys.stdout.write("Type SEND %s to send it: " % h)
    sys.stdout.flush()
    if sys.stdin.readline().strip() != "SEND " + h:
        err("not confirmed; nothing sent")
        return 6
    env = {k: v for k, v in os.environ.items() if k not in GH_SCRUB}
    fp_line = "delixcrew-fp: " + rec.get("fingerprint", "")
    # 6. remote duplicate
    out, e = gh(["issue", "list", "--state", "all", "--search", fp_line, "--json", "url,body"], env)
    if e:
        err("delixcrew feedback: gh failed: " + e)
        return 7
    try:
        found = [i for i in json.loads(out) if fp_line in (i.get("body") or "").replace("\r", "").split("\n")]
    except (ValueError, AttributeError, TypeError):
        err("delixcrew feedback: gh failed: unexpected issue list output")
        return 7
    if found:
        url = found[0].get("url", "")
        print(url)
        return finish(rec, "duplicate", url)
    # 7. create
    fd, tmp = tempfile.mkstemp(prefix="delixcrew-feedback-", suffix=".md")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content["body"])
        out, e = gh(["issue", "create", "--title", content["title"], "--body-file", tmp, "--label", content["label"]], env)
    finally:
        os.unlink(tmp)
    if e:
        err("delixcrew feedback: gh failed: " + e)
        return 7
    url = next((x.strip() for x in reversed(out.splitlines()) if x.strip()), "")
    print(url)
    return finish(rec, "sent", url)


def finish(rec, status, url):
    rec["status"], rec["issue_url"] = status, url
    try:
        write_json(record_path(rec["id"]), rec)
    except OSError as e:
        err("warning: issue is on GitHub but the local record was not updated (%s)" % type(e).__name__)
    print("status: %s" % status)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(prog="feedback.py", description="delixcrew feedback queue")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("enable")
    p.add_argument("--terms", help="comma-separated extra terms to redact")
    sub.add_parser("disable")
    sub.add_parser("status")
    sub.add_parser("add")
    sub.add_parser("list")
    for name in ("preview", "drop"):
        sub.add_parser(name).add_argument("id")
    p = sub.add_parser("send")
    p.add_argument("id")
    p.add_argument("--confirm", required=True)
    args = ap.parse_args(argv)
    return {"enable": cmd_enable, "disable": cmd_disable, "status": cmd_status, "add": cmd_add, "list": cmd_list,
            "preview": cmd_preview, "send": cmd_send, "drop": cmd_drop}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main())
