# T026 — 🔐 Stop gate trust anchor: approved (git_common_dir, sha256) pair, trust.py allow, record guard (#17)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T026 | L | 3 | backend | 1 | open |

> 🔐 Tier 3: `scripts/common.py`, `scripts/stop_gate.py`, `scripts/write_gate.py` and the new `scripts/trust.py` are protected paths (SPEC §6), and this card decides when the Stop gate runs shell commands. The lead adds the Approved line after the user's explicit yes in chat and commits it to main before dispatch.

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** The Stop gate runs the `delix.json` command list only when the pair `(git_common_dir, sha256)` is in a private record under the passwd home. The repo identity is checked on the file system with `lstat`, and git runs without `GIT_*`. `trust.py allow` is the only writer, and it needs a TTY and a typed `TRUST <h12>`. Unapproved means nothing runs, the gate exits 2 once and prints three stderr lines. `test-result.txt` is never written through a symlink, and write_gate denies the record. · **Spec:** `docs/delix/SPEC.md#REQ-1`, `#REQ-2`, `#REQ-3`, `#REQ-4` (record and write_gate part); §4, §5, §6; K199–K203, K206, K210–K214

**Docs/site:** none in this card. T028 updates README, skills, CHANGELOG and site (REQ-7).

## Files
- Create: `scripts/trust.py` (new CLI, stdlib only)
- Modify: `scripts/common.py` (imports lines 2 to 6; inner git helper lines 36 to 47; new git helper before line 27; new functions after line 64)
- Modify: `scripts/stop_gate.py` (docstring lines 2 to 3; import line 9; lines 24 to 49)
- Modify: `scripts/write_gate.py` (import line 11; insert after line 17 and after line 32)
- Test: `tests/trust_tests.sh` (K206: lines 37 and 48 change; insert after line 13 and after line 72)
- Test: `tests/hook_tests.sh` (K206: lines 69 and 73 change; insert after line 68 and after line 73)

## Edit anchors (base origin/main 63e8440; the lead's protected_paths commit does not touch these files; match the content, not only the number)
`scripts/common.py`:
1. Lines 2–6 become `import fnmatch`, `import hashlib`, `import json`, `import os`, `import pwd`, `import stat`, `import subprocess`, `import sys`.
2. Insert after line 25 (the blank line after `deny`), before line 27 `def card_path(cwd):`:
```python
def git(cwd, *args):
    """CompletedProcess of `git -c core.fsmonitor=false -C <cwd> <args>`, or None (no git, timeout). stdin DEVNULL,
    5 s, and every GIT_* variable removed from env (K212: a GIT_DIR in the hook env must not choose the repo)."""
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    try:
        return subprocess.run(["git", "-c", "core.fsmonitor=false", "-C", cwd, *args], stdin=subprocess.DEVNULL,
                              capture_output=True, text=True, timeout=5, env=env)
    except (OSError, subprocess.TimeoutExpired):
        return None
```
3. Lines 36–42 (the inner `def git(*args):` block) become:
```python
    def git_out(*args):  # stdout of a read-only git command, or None (no git, not a work tree, timeout)
        r = git(cwd, *args)
        return r.stdout if r is not None and r.returncode == 0 else None
```
   In lines 46–47, `git("rev-parse", …)` → `git_out("rev-parse", …)` and `git("ls-files", …)` → `git_out("ls-files", …)`. Nothing else in `card_path` changes.
4. Insert after line 64 (`return {}` of `delix_json`), before `def matches`:
```python
def stop_commands(cwd):
    """REQ-1 list, read once: [test_command or "pytest -q"] + extra_checks. A missing, broken or non-object delix.json
    gives ["pytest -q"]; an extra_checks that is not a list counts as one element. trust_key refuses non-str elements."""
    cfg = delix_json(cwd)
    if not isinstance(cfg, dict):
        cfg = {}
    extra = cfg.get("extra_checks") or []
    return [cfg.get("test_command") or "pytest -q"] + (extra if isinstance(extra, list) else [extra])


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
            data = os.read(fd, (1 << 20) + 1)
        finally:
            os.close(fd)
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
```
   A single `os.read` of a regular file can return fewer bytes than asked only at EOF. Loop with `b"".join` if you prefer, but keep the 1 MiB cap.

`scripts/stop_gate.py`:
5. Lines 2–3 (docstring) become: `"""Stop: in an implementer worktree (cwd/.delix/card exists) the turn cannot end until the test command passes.` / `The commands run only when the user approved this repo + command list (trust.py allow, REQ-1); otherwise nothing runs,` / `the gate exits 2 once and says why. Exits 0 when stop_hook_active. Output goes to .delix/test-result.txt (never through a symlink)."""`
6. Line 9 → `from common import card_path, commands_hash, is_trusted, read_input, stop_commands  # noqa: E402` and add `import shlex` to the imports (lines 4–7, alphabetical).
7. Insert after line 9:
```python


def open_result(path):
    """K213: test-result.txt opened without following a symlink; None (one stderr line) when that fails."""
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o644)
    except OSError:
        sys.stderr.write("delixcrew Stop gate: .delix/test-result.txt is a symlink or cannot be opened; "
                         "the output is not written there\n")
        return None
    return os.fdopen(fd, "w", encoding="utf-8")
```
8. Lines 10–23 stay byte-identical. Lines 24–49 become:
```python
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
```
   followed by the old lines 40–49 (`if failed:` … `sys.exit(0)`), byte-identical. `delix_json` is no longer imported here.

`scripts/write_gate.py`:
9. Line 11 → `from common import REVIEWERS, card_path, delix_json, deny, matches, read_input, trust_file  # noqa: E402`
10. Insert after line 17 (end of `_fold`): a blank line, then `TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"  # K210: literal here and in bash_gate.py`
11. Insert after line 32 (`deny("delixcrew: triage decisions …")`), inside `if _path:`:
```python
    # REQ-4 (K203): the Stop gate trust record, in every session; its path comes from the passwd entry, never env
    try:
        record = _fold(trust_file())
    except (KeyError, OSError):
        record = None  # no passwd entry: there is no record to protect
    if record and target == record:
        deny(TRUST_DENY)
```

`scripts/trust.py` (new):
```python
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
        print("  " + json.dumps(c))  # K214: escaped (\r, ‮ …), one per line
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
```

`tests/hook_tests.sh` (K206). Insert after line 68 `# Stop`:
```bash
# T026 (K206): the Stop gate runs only an approved (git_common_dir, sha256) pair. The test record replaces
# common.trust_file through runpy (K203); each case approves its command list first; expected results are unchanged.
TREC="$T/trusthome/.claude/delixcrew/trust.json"
cat > "$T/run.py" <<'PY'
import runpy, sys
scripts, record, script = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, scripts)
import common
common.trust_file = lambda: record
sys.argv = [script] + sys.argv[4:]
runpy.run_path(script, run_name="__main__")
PY
tapprove(){ python3 - "$T" "$TREC" <<'PY'
import hashlib, json, os, subprocess, sys
cwd, rec = sys.argv[1], sys.argv[2]
with open(os.path.join(cwd, "docs", "delix", "delix.json"), encoding="utf-8") as f:
    cfg = json.load(f)
cmds = [cfg.get("test_command") or "pytest -q"] + list(cfg.get("extra_checks") or [])
sha = hashlib.sha256(json.dumps(cmds, ensure_ascii=False, separators=(",", ":")).encode("utf-8")).hexdigest()
out = subprocess.run(["git", "-C", cwd, "rev-parse", "--git-common-dir"], capture_output=True, text=True).stdout.rstrip("\n")
os.makedirs(os.path.dirname(rec), exist_ok=True); os.chmod(os.path.dirname(rec), 0o700)
data = {"version": 1, "entries": []}
if os.path.exists(rec):
    with open(rec, encoding="utf-8") as f:
        data = json.load(f)
data["entries"].append({"git_common_dir": os.path.realpath(os.path.join(cwd, out)), "sha256": sha, "approved_at": "2026-11-04T00:00:00+00:00"})
with open(rec, "w", encoding="utf-8") as f:
    json.dump(data, f)
os.chmod(rec, 0o600)
PY
}
tstop(){ printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$T/run.py" "$S" "$TREC" "$S/stop_gate.py" 2>/dev/null; }
```
   Line 69 → `tapprove; tstop; [ $? -eq 0 ] && echo "✔ stop: tests pass, stops" || { echo "✘ stop: should stop when tests pass"; FAIL=1; }`
   Line 73 → `tapprove; tstop; [ $? -eq 2 ] && echo "✔ stop: tests broken, blocks (exit 2)" || { echo "✘ stop: expected exit 2 on broken tests"; FAIL=1; }`
   Insert after line 73: `grep -qF '[exit 1]' "$T/.delix/test-result.txt" && ! grep -qF '[not run:' "$T/.delix/test-result.txt" && echo "✔ stop: broken test ran ([exit 1], no [not run:)" || { echo "✘ stop: broken test did not run: $(cat "$T/.delix/test-result.txt")"; FAIL=1; }`
   Lines 70–72 and 74–76 stay byte-identical. They exit before the trust check.

`tests/trust_tests.sh` (K206). Insert after line 13 (`ok(){ … }; ko(){ … }`):
```bash
# T026 (REQ-1–REQ-4, K203, K206): the record path is replaced through the common module attribute (runpy), never env;
# key.py recomputes the REQ-1 pair independently of common.py; pty.py types the answer on a pseudo-terminal
TREC="$T/trusthome/.claude/delixcrew/trust.json"
cat > "$T/run.py" <<'PY'
import runpy, sys
scripts, record, script = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, scripts)
import common
common.trust_file = lambda: record
sys.argv = [script] + sys.argv[4:]
runpy.run_path(script, run_name="__main__")
PY
cat > "$T/key.py" <<'PY'
import hashlib, json, os, subprocess, sys
mode, cwd = sys.argv[1], sys.argv[2]
try:
    with open(os.path.join(cwd, "docs", "delix", "delix.json"), encoding="utf-8") as f:
        cfg = json.load(f)
except Exception:
    cfg = {}
cfg = cfg if isinstance(cfg, dict) else {}
extra = cfg.get("extra_checks") or []
cmds = [cfg.get("test_command") or "pytest -q"] + (extra if isinstance(extra, list) else [extra])
sha = hashlib.sha256(json.dumps(cmds, ensure_ascii=False, separators=(",", ":")).encode("utf-8")).hexdigest()
if mode == "h12":
    print(sha[:12]); sys.exit(0)
rec = sys.argv[3]
out = subprocess.run(["git", "-C", cwd, "rev-parse", "--git-common-dir"], capture_output=True, text=True).stdout.rstrip("\n")
os.makedirs(os.path.dirname(rec), exist_ok=True); os.chmod(os.path.dirname(rec), 0o700)
data = {"version": 1, "entries": []}
if os.path.exists(rec):
    with open(rec, encoding="utf-8") as f:
        data = json.load(f)
data["entries"].append({"git_common_dir": os.path.realpath(os.path.join(cwd, out)), "sha256": sha, "approved_at": "2026-11-04T00:00:00+00:00"})
with open(rec, "w", encoding="utf-8") as f:
    json.dump(data, f)
os.chmod(rec, 0o600)
PY
cat > "$T/pty.py" <<'PY'
import os, select, subprocess, sys, time
cwd, answer, args = sys.argv[1], sys.argv[2], sys.argv[3:]
m, s = os.openpty()
p = subprocess.Popen([sys.executable] + args, cwd=cwd, stdin=s, stdout=s, stderr=s)
os.close(s)
buf, sent, end = b"", False, time.monotonic() + 20
while time.monotonic() < end:
    if select.select([m], [], [], 0.1)[0]:
        try:
            chunk = os.read(m, 4096)
        except OSError:
            break
        if not chunk:
            break
        buf += chunk
        if not sent and b"then the hash): " in buf:
            os.write(m, answer.encode() + b"\n"); sent = True
    elif p.poll() is not None:
        break
rc = p.wait(timeout=20); os.close(m)
sys.stdout.write(buf.decode("utf-8", "replace")); sys.exit(rc)
PY
tstop(){ # dir[, VAR=value] → Stop gate with the test record; stderr in $1.err
  printf '{"cwd":"%s","stop_hook_active":false}' "$1" | env ${2:+"$2"} python3 "$T/run.py" "$S" "$TREC" "$S/stop_gate.py" 2>"$1.err"; }
approve(){ python3 "$T/key.py" approve "$1" "$TREC"; }
h12(){ python3 "$T/key.py" h12 "$1"; }
```
   Line 37 `stop "$R"; rc=$?` → `approve "$R"; tstop "$R"; rc=$?`
   Line 48 → `approve "$W"; tstop "$W"; ran "$W" && ok "linked worktree: Stop gate runs the test command" || ko "linked worktree: test command not run"`
   Insert after line 72 (end of case 7), before line 74 `rm -rf "$T"; …`:
```bash
# T026 REQ-1/REQ-2 (K201, K213): an archive with its own .git and an empty record → nothing runs, exit 2, three lines
A="$T/own-git"; mkrepo "$A"; git -C "$A" init -q; mkdir -p "$A/.delix"; echo "docs/delix/tasks/T001-x.md" > "$A/.delix/card"
tstop "$A"; rc=$?
ran "$A" && ko "T026 archive with its own .git: command ran" || ok "T026 archive with its own .git: command not run"
[ $rc -eq 2 ] && ok "T026 archive with its own .git: exit 2" || ko "T026 archive with its own .git: exit $rc"
[ "$(wc -l < "$A.err")" -eq 3 ] && grep -qF "trust.py allow" "$A.err" && grep -qF "write BLOCKED in .delix/report.md naming this command, then stop" "$A.err" \
  && ok "T026 not approved: three stderr lines, trust.py allow, the BLOCKED step" || ko "T026 not approved: stderr: $(cat "$A.err")"
grep -qxF "[not run: commands not approved, hash $(h12 "$A")]" "$A/.delix/test-result.txt" && ok "T026 not approved: hash line in test-result.txt" || ko "T026 not approved: test-result: $(cat "$A/.delix/test-result.txt" 2>&1)"
echo "BLOCKED: Stop gate commands not approved" > "$A/.delix/report.md"; tstop "$A"; rc=$?
[ $rc -eq 0 ] && ! ran "$A" && ok "T026 not approved + BLOCKED report: exit 0" || ko "T026 not approved + BLOCKED report: exit $rc"
rm -f "$A/.delix/report.md" "$A/.delix/test-result.txt"; echo keep > "$T/outside.txt"; ln -s "$T/outside.txt" "$A/.delix/test-result.txt"
tstop "$A"; [ "$(cat "$T/outside.txt")" = keep ] && grep -qF "test-result.txt is a symlink" "$A.err" && ok "T026 symlinked test-result.txt, not approved: target unchanged, warning" || ko "T026 symlinked test-result.txt, not approved: $(cat "$T/outside.txt") / $(cat "$A.err")"
approve "$A"; tstop "$A"; [ "$(cat "$T/outside.txt")" = keep ] && ran "$A" && ok "T026 symlinked test-result.txt, approved: command runs, target unchanged" || ko "T026 symlinked test-result.txt, approved: $(cat "$A.err")"
NS="$T/nonstr"; mkrepo "$NS"; printf '{"test_command":"touch %s/MARK","extra_checks":"echo x"}' "$NS" > "$NS/docs/delix/delix.json"
git -C "$NS" init -q; mkdir -p "$NS/.delix"; echo "docs/delix/tasks/T001-x.md" > "$NS/.delix/card"
tstop "$NS"; rc=$?
! ran "$NS" && [ $rc -eq 2 ] && grep -qF "[not run: commands not approved, hash " "$NS/.delix/test-result.txt" && ok "T026 extra_checks not a list: nothing runs, exit 2" || ko "T026 extra_checks not a list: rc $rc"
(cd "$NS" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 7 ] && [ "$(wc -l < "$T/a.err")" -eq 1 ] && ok "T026 allow with a non-string command: exit 7, one stderr line" || ko "T026 allow with a non-string command: rc $rc: $(cat "$T/a.err")"
# T026 REQ-1 (K199, K211, K212): the approved checkout and its worktrees run; a symlinked or faked .git and GIT_* env do not
V="$T/victim"; mkrepo "$V"; git -C "$V" init -q && $G -C "$V" add -A && $G -C "$V" commit -qm x
echo ".delix/" >> "$V/.git/info/exclude"; mkdir -p "$V/.delix"; echo "docs/delix/tasks/T001-x.md" > "$V/.delix/card"
approve "$V"; tstop "$V"; ran "$V" && ok "T026 approved main checkout: command runs" || ko "T026 approved main checkout: not run: $(cat "$V.err")"; rm -f "$V/MARK"
VW="$T/victim-wt"; git -C "$V" worktree add -q --detach "$VW"; mkdir -p "$VW/.delix"; echo "docs/delix/tasks/T001-x.md" > "$VW/.delix/card"
tstop "$VW"; rc=$?; ran "$V" && [ $rc -eq 0 ] && ok "T026 worktree of the approved checkout: runs, exit 0" || ko "T026 worktree of the approved checkout: rc $rc: $(cat "$VW.err")"; rm -f "$V/MARK"
fake(){ mkdir -p "$1/docs/delix" "$1/.delix"; cp "$V/docs/delix/delix.json" "$1/docs/delix/"; echo "docs/delix/tasks/T001-x.md" > "$1/.delix/card"; }
fake "$T/ln-abs"; ln -s "$V/.git" "$T/ln-abs/.git"
fake "$T/ln-rel"; ln -s ../victim/.git "$T/ln-rel/.git"
fake "$T/ln-wt"; ln -s "$VW/.git" "$T/ln-wt/.git"
for d in ln-abs ln-rel ln-wt; do
  tstop "$T/$d"; ran "$V" && ko "T026 symlinked .git ($d): command ran" || ok "T026 symlinked .git ($d): command not run"; rm -f "$V/MARK"
done
fake "$T/gitfile"; printf 'gitdir: %s\n' "$(cd "$V/.git/worktrees/victim-wt" && pwd -P)" > "$T/gitfile/.git"
tstop "$T/gitfile"; ran "$V" && ko "T026 gitfile into the approved worktree entry: command ran" || ok "T026 gitfile into the approved worktree entry: command not run"; rm -f "$V/MARK"
X="$T/plain"; mkrepo "$X"; cp "$V/docs/delix/delix.json" "$X/docs/delix/delix.json"; git -C "$X" init -q; mkdir -p "$X/.delix"; echo "docs/delix/tasks/T001-x.md" > "$X/.delix/card"
tstop "$X" "GIT_DIR=$V/.git"; ran "$V" && ko "T026 GIT_DIR=<approved .git> in the hook env: command ran" || ok "T026 GIT_DIR=<approved .git> in the hook env: command not run"; rm -f "$V/MARK"
tstop "$V" "GIT_DIR=$X/.git"; ran "$V" && ok "T026 GIT_DIR=<other .git> in the hook env: approved checkout still runs" || ko "T026 GIT_DIR=<other .git>: not run: $(cat "$V.err")"; rm -f "$V/MARK"
# T026 REQ-1/REQ-3 (K214): a changed delix.json in the worktree needs its own approval; the main checkout keeps its own
sed -i.bak "s|$V/MARK|$VW/MARK2|" "$VW/docs/delix/delix.json"; rm -f "$VW/docs/delix/delix.json.bak"
tstop "$VW"; rc=$?
[ ! -e "$VW/MARK2" ] && [ $rc -eq 2 ] && grep -qxF "[not run: commands not approved, hash $(h12 "$VW")]" "$VW/.delix/test-result.txt" && ok "T026 changed delix.json in the worktree: not run, exit 2" || ko "T026 changed delix.json in the worktree: rc $rc"
out=$(python3 "$T/pty.py" "$VW" "TRUST $(h12 "$VW")" "$T/run.py" "$S" "$TREC" "$S/trust.py" allow); rc=$?
[ $rc -eq 0 ] && ok "T026 allow on a terminal with TRUST <h12>: exit 0" || ko "T026 allow on a terminal: rc $rc: $out"
echo "$out" | grep -qF "delix.json differs from HEAD" && ok "T026 allow warns that delix.json differs from HEAD" || ko "T026 allow: no HEAD warning: $out"
tstop "$VW"; [ -e "$VW/MARK2" ] && ok "T026 after its own approval the worktree runs" || ko "T026 after its own approval: not run: $(cat "$VW.err")"
tstop "$V"; ran "$V" && ok "T026 the main checkout's approval still holds" || ko "T026 the main checkout's approval was lost"; rm -f "$V/MARK"
D2="$T/home2/.claude/delixcrew"; mkdir -p "$D2"; chmod 755 "$D2"
out=$(python3 "$T/pty.py" "$V" "TRUST $(h12 "$V")" "$T/run.py" "$S" "$D2/trust.json" "$S/trust.py" allow); rc=$?
[ $rc -eq 0 ] && python3 - "$D2/trust.json" "$(cd "$V/.git" && pwd -P)" "$(h12 "$V")" <<'PY' && ok "T026 allow: dir 0700 (was 0755), file 0600, entry (realpath, sha256)" || ko "T026 allow record: rc $rc: $out"
import json, os, sys
p, common, h = sys.argv[1:4]
with open(p, encoding="utf-8") as f:
    d = json.load(f)
e = d["entries"][-1]
good = (os.stat(p).st_mode & 0o777 == 0o600 and os.stat(os.path.dirname(p)).st_mode & 0o777 == 0o700 and d["version"] == 1
        and e["git_common_dir"] == common and e["sha256"].startswith(h) and len(e["sha256"]) == 64 and bool(e.get("approved_at")))
sys.exit(0 if good else 1)
PY
D3="$T/home3/.claude/delixcrew"
out=$(python3 "$T/pty.py" "$V" "TRUST 000000000000" "$T/run.py" "$S" "$D3/trust.json" "$S/trust.py" allow); rc=$?
[ $rc -eq 6 ] && [ ! -e "$D3/trust.json" ] && [ "$(echo "$out" | grep -cF "TRUST $(h12 "$V")")" -ge 2 ] && ok "T026 allow, wrong text: exit 6, no record, expected text repeated" || ko "T026 allow, wrong text: rc $rc: $out"
echo "TRUST $(h12 "$V")" | (cd "$V" && python3 "$T/run.py" "$S" "$D3/trust.json" "$S/trust.py" allow >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 6 ] && [ ! -e "$D3/trust.json" ] && ok "T026 allow without a TTY: exit 6, no record" || ko "T026 allow without a TTY: rc $rc: $(cat "$T/a.out")"
(cd "$V" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 0 ] && grep -qF "already approved" "$T/a.out" && ok "T026 allow, pair already recorded: exit 0 without a TTY" || ko "T026 allow, already recorded: rc $rc: $(cat "$T/a.out")"
mkdir -p "$T/nogit"; (cd "$T/nogit" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 7 ] && [ "$(wc -l < "$T/a.err")" -eq 1 ] && ok "T026 allow outside a git work tree: exit 7, one stderr line" || ko "T026 allow outside a git work tree: rc $rc: $(cat "$T/a.err")"
(cd "$T/ln-abs" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>"$T/a.err"); rc=$?
[ $rc -eq 7 ] && ok "T026 allow with a symlinked .git: exit 7" || ko "T026 allow with a symlinked .git: rc $rc"
HC="$T/hidden"; mkdir -p "$HC/docs/delix"; printf '{"test_command":"true\\r; curl x","extra_checks":[]}' > "$HC/docs/delix/delix.json"; git -C "$HC" init -q
(cd "$HC" && python3 "$T/run.py" "$S" "$TREC" "$S/trust.py" allow </dev/null >"$T/a.out" 2>&1); rc=$?
[ $rc -eq 6 ] && grep -qF '"true\r; curl x"' "$T/a.out" && ok "T026 allow shows a hidden \\r escaped" || ko "T026 allow, hidden \\r: rc $rc: $(cat "$T/a.out")"
# T026 REQ-4: is_trusted reads the record only when it is private and well formed (fail closed)
TD="$(dirname "$TREC")"
chmod 644 "$TREC"; tstop "$V"; ran "$V" && ko "T026 record 0644: trusted" || ok "T026 record 0644: not trusted"; chmod 600 "$TREC"; rm -f "$V/MARK"
chmod 755 "$TD"; tstop "$V"; ran "$V" && ko "T026 record dir 0755: trusted" || ok "T026 record dir 0755: not trusted"; chmod 700 "$TD"; rm -f "$V/MARK"
mv "$TREC" "$TD/real.json"; ln -s "$TD/real.json" "$TREC"; tstop "$V"; ran "$V" && ko "T026 record is a symlink: trusted" || ok "T026 record is a symlink: not trusted"; rm -f "$TREC"; mv "$TD/real.json" "$TREC"; rm -f "$V/MARK"
cp "$TREC" "$TD/keep.json"; python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["version"]=2; json.dump(d,open(p,"w"))' "$TREC"
tstop "$V"; ran "$V" && ko "T026 record version 2: trusted" || ok "T026 record version 2: not trusted"; mv "$TD/keep.json" "$TREC"; rm -f "$V/MARK"
tstop "$V"; ran "$V" && ok "T026 record restored: trusted again" || ko "T026 record restored: not trusted"; rm -f "$V/MARK"
# T026 REQ-4 (K203, K210): write_gate denies the record in every session; the path comes from passwd, not HOME
PWH=$(python3 -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)')
TDENY="delixcrew: Stop gate commands are approved only by the user from their own terminal"
wg(){ # tool, path key, path[, VAR=value] → write_gate output
  printf '{"tool_name":"%s","cwd":"%s","tool_input":{"%s":"%s"}}' "$1" "$T" "$2" "$3" | env ${4:+"$4"} python3 "$S/write_gate.py" 2>/dev/null; }
for t in Write Edit MultiEdit; do
  wg "$t" file_path "$PWH/.claude/delixcrew/trust.json" | grep -qF "$TDENY" && ok "T026 write_gate: $t of the record denied" || ko "T026 write_gate: $t of the record not denied"
done
wg NotebookEdit notebook_path "$PWH/.claude/delixcrew/trust.json" | grep -qF "$TDENY" && ok "T026 write_gate: NotebookEdit of the record denied" || ko "T026 write_gate: NotebookEdit not denied"
wg Write file_path "$PWH/.CLAUDE/DelixCrew/Trust.json" | grep -qF "$TDENY" && ok "T026 write_gate: letter-case variant denied" || ko "T026 write_gate: letter-case variant not denied"
wg Write file_path "$PWH/.claude/delixcrew/trust.json" "HOME=$T/h" | grep -qF "$TDENY" && ok "T026 write_gate: another HOME does not move the record" || ko "T026 write_gate: HOME moved the record"
wg Write file_path "$T/h/.claude/delixcrew/trust.json" "HOME=$T/h" | grep -qF "$TDENY" && ko "T026 write_gate: a HOME-based path counted as the record" || ok "T026 write_gate: a HOME-based lookalike is not the record"
wg Write file_path "$PWH/.claude/delixcrew/trust.json.bak" | grep -qF "$TDENY" && ko "T026 write_gate: a sibling file denied" || ok "T026 write_gate: a sibling file is not the record"
printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s"}}' "$T" "$TREC" | python3 "$T/run.py" "$S" "$TREC" "$S/write_gate.py" 2>/dev/null | grep -qF "$TDENY" && ok "T026 write_gate reads common.trust_file at run time" || ko "T026 write_gate: patched trust_file not used"
```

## Interfaces
- Produced (SPEC §4):
  - `common.trust_key(cwd, commands=None)` → `(git_common_dir, sha256)` or `None`;
  - `common.is_trusted(cwd, commands=None) -> bool`;
  - `common.trust_file() -> str`;
  - CLI `trust.py allow` → exit 0 / 6 / 7;
  - file `~/.claude/delixcrew/trust.json` `{"version": 1, "entries": [{"git_common_dir", "sha256", "approved_at"}]}`;
  - `TRUST_DENY` literal in `write_gate.py`.
- Card decision: the optional `commands` argument. With it stop_gate reads `delix.json` once, so the list it hashes is the list it runs. The one-argument call in §4 still works.
- Produced helpers in `common.py`, used by `stop_gate.py` and `trust.py` (no new public contract beyond these): `git(cwd, *args) -> CompletedProcess | None`, `stop_commands(cwd) -> list`, `commands_hash(list) -> str`, `load_trust() -> dict | None`.
- Stop gate output (consumed by T028 docs and by the implement skill): the `test-result.txt` line `[not run: commands not approved, hash <h12>]` and three stderr lines (Edit anchor 8). The third line is exactly `write BLOCKED in .delix/report.md naming this command, then stop`.
- Unchanged: `card_path` decisions (only its git env changes), `delix_json`, `matches`, `deny`, `read_input`, the feedback/triage queue checks, the implementer gates and `bash_gate.py`. bash_gate.py belongs to T027 and has its own literal `TRUST_DENY` (K210).

## Global Constraints (verbatim from the spec)
- REQ-1: "Komut listesi `[test_command or "pytest -q"] + extra_checks`. `delix.json` yok ya da bozuksa liste `["pytest -q"]` olur. Bir öğe `str` değilse … Stop gate hiçbir komutu çalıştırmaz ve REQ-2 yoluna girer." · "`sha256` = listenin kanonik JSON'unun (`json.dumps(list, ensure_ascii=False, separators=(",", ":"))`) özeti." · "`git_common_dir` = `git rev-parse --git-common-dir` çıktısının gerçek yolu (realpath)."
- K211: "doğrulamada `os.lstat` kullanılır ve sembolik bağlantı izlenmez"; main worktree "`<cwd>/.git` sembolik bağlantı olmayan gerçek bir dizindir ve `git_common_dir` == `R + "/.git"`". For a linked worktree, `.git` is a regular file with one line `gitdir: <yol>`. Then `realpath(<yol>) == <git_common_dir>/worktrees/<ad>` and the stripped `<…>/worktrees/<ad>/gitdir` equals `R + "/.git"`. "Başka her durumda `trust_key` `None` döner".
- K212: "Bütün git çağrıları `card_path` ile aynı biçimdedir: `-c core.fsmonitor=false`, stdin DEVNULL, 5 sn timeout. Ek olarak env'den `GIT_*` ile başlayan bütün değişkenler çıkarılır (K212). Bu kural `card_path`'in git çağrılarına da uygulanır."
- REQ-2: nothing runs. `.delix/test-result.txt` gets `[not run: commands not approved, hash <h12>]`, stderr gets three lines and the exit code is 2. "`stop_hook_active` ya da raporda `BLOCKED`/`NEEDS_CONTEXT` varken bugünkü exit 0 yolu değişmez." K213: "`.delix/test-result.txt` her yolda sembolik bağlantı izlenmeden yazılır … Hedef sembolik bağlantıysa dosyaya yazılmaz ve stderr'de bir satır uyarı çıkar."
- REQ-3 steps 1–6 in order. Exit 7 is a precondition failure (not a work tree, the FS check fails, a non-str element). "already approved" exits 0 and needs no TTY. The commands are shown with `json.dumps`, and a "delix.json differs from HEAD" warning is printed. The prompt is `Type TRUST <h12> to approve these commands for <git_common_dir> (the word TRUST, a space, then the hash): `. No TTY or a mismatch gives exit 6 and no record, and a mismatch repeats the expected text. The write is atomic (tmp + `os.replace`), with the file 0600 and the directory 0700. "Yalnız stdlib kullanılır."
- REQ-4: "`<home>` = `pwd.getpwuid(os.getuid()).pw_dir`; `HOME` ya da herhangi bir env değişkeni okunmaz (K203)." Reads use `O_NOFOLLOW`; owner `getuid()` and `mode & 0o077 == 0` for the file and the directory; `version` 1; anything else is empty (fail closed). write_gate: "Write/Edit/MultiEdit/NotebookEdit ile bu dosyaya yazmayı reddeder; mevcut casefold kalıbı kullanılır." K210: `TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"`, written literally in the gate.
- K206: "Değişen tek şey, komut çalışmadan önce test kaydına onay eklemektir; beklenen sonuçlar aynı kalır. Kırık test vakasına yeni bir doğrulama eklenir: `test-result.txt` `[exit 1]` içerir ve `[not run:` içermez."
- Python 3.9 compatible (Mac python3 is 3.9.6, CI 3.12): no `X | None` or `tuple[...]` annotations, no `match`. Stdlib only. In tests, write invisible characters as escapes (`\\r` in printf), never raw.

## Steps
1. **Failing tests first.** Make the four test edits above (the two helper inserts, the K206 line changes and the appended block) with the Write/Edit tools. Run `bash tests/trust_tests.sh` and `bash tests/hook_tests.sh` and see **red** in trust_tests. Expected ✘ lines on the unchanged scripts:
   - the archive line;
   - `symlinked .git (ln-abs)` and `(ln-rel)`; `(ln-wt)` only if git accepts the card there;
   - the gitfile line;
   - `GIT_DIR=<approved .git>`;
   - every `allow`/`trust.py` line (the file is missing);
   - the write_gate deny lines;
   - the REQ-2 lines.

   hook_tests stays green at this point: on main the patched attribute is unused. Report the names of all ✘ lines.
2. **Implement** edits 1–11 and `scripts/trust.py`. Touch only the paths in Files.
3. **Green:** `bash tests/trust_tests.sh`, `bash tests/hook_tests.sh`, then the full loop and `claude plugin validate .`. If an existing line goes ✘ (other than the four K206 lines), do not edit it: report `NEEDS_CONTEXT` with the output. If `linked worktree` (4b) or `worktree of the approved checkout` fails because `<common>/worktrees/<name>/gitdir` holds a non-real path, report `NEEDS_CONTEXT` with that file's content. Do not loosen the comparison.
4. **Commit** `T026: Stop gate trust anchor (approved repo + command hash, trust.py allow, record guard)`. Open the PR with `--body-file`. `## How I tested` lists the commands, the ✔/✘ counts and the step 1 ✘ names.

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0; `claude plugin validate .` → passes
- `bash tests/trust_tests.sh | grep -c '^✔ T026'` → `43`; `bash tests/trust_tests.sh | grep -c '^✘'` → `0`; last line `ALL PASSED`
- `bash tests/hook_tests.sh | grep -c '^✔ stop:'` → `5`; `bash tests/hook_tests.sh | grep -c '^✘'` → `0`
- `git diff origin/main -- tests/hook_tests.sh | grep -c '^-[^-]'` → `2` (old lines 69, 73); the same for `tests/trust_tests.sh` → `2` (old lines 37, 48)
- `grep -cF 'TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"' scripts/write_gate.py` → `1`
- `grep -nE 'HOME|expanduser|environ' scripts/trust.py` → no output; in `scripts/common.py` the only `environ` use is the GIT_* filter in `git()`
- `python3 -c 'import ast,sys; [ast.parse(open(f).read(), feature_version=(3, 9)) for f in sys.argv[1:]]' scripts/common.py scripts/stop_gate.py scripts/trust.py scripts/write_gate.py` → no output
- `git diff --stat origin/main` → only the 6 files in Files

## Review Focus
- The hashed list is the run list: `stop_commands` is called once and passed to `is_trusted`. There is no second read of `delix.json`.
- `os.lstat` with `S_ISDIR`/`S_ISREG`: a symlinked `.git`, to a directory or to a gitfile, falls through to `None`. The back-pointer is compared as a string to `realpath(cwd) + "/.git"`, and `.git` on the cwd side is never resolved.
- Every git call in `common.py`, `card_path` included, goes through `git()` without `GIT_*`.
- `load_trust` fails closed on every branch: no passwd entry, a symlinked or foreign or group/world-accessible directory or file, a FIFO (`O_NONBLOCK`), more than 1 MiB, bad JSON, `version` that is `True` or `"1"`.
- `trust.py` writes nothing before the exact match. mkstemp sits in the record directory, then `os.replace`. A 0755 directory left by the feedback setup is tightened to 0700.
- `test-result.txt`: `O_NOFOLLOW` on both paths. The run path still writes when the file is regular.
- Inputs the spec implies but the tests do not cover:
  - owner checks (`st_uid`) need a second user;
  - relative gitdir paths (`worktree.useRelativePaths`, git ≥ 2.48) fail closed;
  - `trust_file()` raising `KeyError` in write_gate and trust.py;
  - a lone surrogate in `delix.json` (`surrogatepass`).
- Not a target:
  - `bash_gate.py`'s own `git remote -v` calls. That file is T027's, and REQ-1 scopes K212 to the trust and `card_path` calls.
  - Hashing the files the commands run (§2).

## Don'ts
- Do not touch anything outside the 6 files, in particular:
  - `scripts/bash_gate.py`, which is T027's;
  - `hooks/hooks.json`, `docs/delix/**`, `README*`, `skills/**`, `site/**`, `CHANGELOG.md`, which belong to T028 or the lead.
- Change no existing test line except hook_tests 69 and 73 and trust_tests 37 and 48 (K206). Only insert elsewhere. If a test looks wrong, stop: `NEEDS_CONTEXT`.
- Never read or write your real `~/.claude/delixcrew/` from a test or by hand. The write_gate tests only ask for a decision.
- Do not run `trust.py allow` ad hoc in the session. Exercise it only through `bash tests/trust_tests.sh`.
- Create and edit files with Write/Edit, not `cat > … <<'EOF'` through Bash.
- No new dependency, no new exit code, no revoke or list subcommand (K208).

## Report contract
`.delix/report.md` (≤ 1.5K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output: ✔/✘ counts per suite and the names of the step 1 red lines;
- the PR number;
- assumptions, including what `git worktree add` wrote into `worktrees/<name>/gitdir` on your machine (real path or not).

Read only this card and SPEC REQ-1–REQ-4, §4–§6 and §9.

## Review findings (filled by the lead)
- Round 0 (71777fe, PR #57): deterministic gates green.
  - CI `test` and `check` pass.
  - The lead re-ran all suites from `git archive 71777fe`: 9/9 pass. The merge tree with T027 (d81c27a) passes 10/10, and also under Python 3.13.
  - Only the four K206 test lines changed. The internal-host scan finds 0.
  - qa: ACCEPT_WITH_NOTES (0 P0, 0 P1).
  - security: 🔐 HUMAN_APPROVAL with one High, which needs a fix.
- **[High, fix] `scripts/trust.py:43`.** `git diff --quiet HEAD -- docs/delix/delix.json` runs before the user types the confirmation. A repo's own `.git/config` with `diff.external=<helper>` and `diff.trustExitCode=true` runs the helper.
  - The lead reproduced this on 71777fe: `allow` with stdin `/dev/null` exited 6 and the helper still ran.
  - Fix (K217): replace the call with `git cat-file blob HEAD:docs/delix/delix.json` and compare its stdout with the worktree file, read with `O_NOFOLLOW` in Python. No HEAD, a read error or a mismatch gives the same warning.
  - Test: a repo with that config and a changed `delix.json`. After `allow </dev/null` (exit 6), MARK does not exist and the warning is still printed.
- **[Low, fix] `scripts/stop_gate.py:17`.** A hardlinked `.delix/test-result.txt` is truncated and overwritten.
  - Fix (K218): open without `O_TRUNC`. If `os.fstat(fd).st_nlink != 1`, close it and take the existing warning path, with the message reading "is a symlink, a hardlink or cannot be opened". Otherwise call `os.ftruncate(fd, 0)`.
  - Test: `.delix/test-result.txt` hardlinked to an outside file. That file keeps its content.
- **[Low, fix] `scripts/trust.py:38,46`.** `git_common_dir` is printed raw. Fix (K219): print it with `json.dumps` in the prompt and in the "already approved" line.
- Accepted, no fix: the `[[extra]]` deviation from anchor 4 (K221, matches REQ-1).
- P2 notes, no fix: one blank line before `TRUST_DENY` in `write_gate.py`. The untested owner, relative-gitdir, `KeyError` and surrogate cases are on the Review Focus list.
- Merge order: T027 first, then T026 (K222).
- The lead prototyped all three fixes on a copy of 71777fe. The PoC no longer creates MARK, the warning is still printed, and the hardlink target is unchanged. `trust_tests.sh`, `hook_tests.sh` and `write_gate_case_tests.sh` pass.

