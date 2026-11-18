# T052 🔐 — bash_gate: a push line holds only the push and its git peers (R-L1)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T052 | M | 3 | backend | 23 | open |

**🔐 Approved:** 2026-11-18 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`). The three test files match `test_paths` (`tests/**`) and no protected entry: one is new, and two get one inserted line each and two changed lines each, named in the test file anchors with the reason (D3).
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-18 ("Evet, T052 onaylı", said in the lead session). The lead commits it to main before dispatch; the session branches from that commit.
> - It is the "whole push line on an allowlist" follow-up that K283 and K296 name and T044 left out (its O2). R-P3b already denies a push that shares its line with another git command outside `PUSH_PEERS`, but every non-git command and every redirection on the line still runs before the push, after the hook has read HEAD and the git dir. On main the lead measured 4 forms that move the push onto `main` this way (D1).
> - The user chose this card on 2026-11-18 ("bash_gate sertleştirme", then "Satır izin listesi").
> - Publication (K313): the forms that pass main are in this card and its tests only; the card enters main at dispatch. README and site text names none of them (D4).
> - It is defence in depth, not a boundary: the rule reads the command's words (Out of scope).

**Goal (1 sentence):** In an implementer worktree a Bash line that holds the own-branch push is allowed only when every command on it is the push, `git add`, `commit`, `status`, `diff`, `log` or `show` (no `--output`), `gh pr create`, or `tail` / `head` reading a pipe, joined by `&&`, `||`, `;`, `|` or a newline, with words that neither bash nor zsh expands, quoted heredocs, and no redirection but `/dev/null` and descriptor copies; any other push line denies with a new message. · **Spec:** `docs/delix/specs/C-board-visibility.md` K283, K296, K313 and K331; K331 records this card's decisions (the same text as the section at the end of this card)

**Docs/site:** none in this card, the same exception as T044 to T050 (K298); the release card after this one carries the text (D4). Do not touch `README.md`, `README.tr.md`, `CHANGELOG.md` or `site/**`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (four insertions, Edit anchors 1 to 4; no existing line changes)
- Create: `tests/push_line_tests.sh` (the full content below)
- Modify: `tests/parse_gate_tests.sh` (one insertion after line 30; lines 76 and 109 change, D3)
- Modify: `tests/argv_gate_tests.sh` (one insertion after line 29; lines 114 and 115 change, D3)

## Edit anchors (base main 0f121e4, full SHA 0f121e4ca082434cb06f0a11c1f9cba92c79deae)
On the base `scripts/bash_gate.py` has 719 lines and sha256 `87e4e322db9959caac33d5130dd2dd8d9dbc9561d067a0d034c3fc108f618bbd`, `tests/parse_gate_tests.sh` has 157 lines and sha256 `3411acc6650cd2df85abcb782b75f01c80c50421de75952a4ad0ac90c71da5fe`, and `tests/argv_gate_tests.sh` has 199 lines and sha256 `ace1d68bcf740a5f162722153cde86406b8cf5de412207ab9c6ac26403738242`. Match the quoted content before you edit. If it differs, stop with `NEEDS_CONTEXT`. Every new code line is at most 120 characters, and every new line is ASCII. The code blocks below sit at the top level: copy each line as it stands. The backslash sequences in them (`\t`, `\n`, `\\`) are two characters in the file, as written. After the edits run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output: if this repo's plugin loads from your worktree, a syntax error would block your own Bash.

**1. `scripts/bash_gate.py`, after line 140, insert 3 lines.** Lines 139 and 140 are `DEEP_DENY = (...)` (its second line is `             "text in a file, then run the command again")`); line 141 `GIT_ARG_OPTS = {"-C", "-c", "--git-dir", ...` stays below.

```python
LINE_DENY = ("delixcrew: in an implementer session a push shares its line only with git add, commit, status, diff, "
             "log, show and gh pr create, pipes only into tail or head and redirects only to /dev/null; run every "
             "other command in a separate call")
```

**2. `scripts/bash_gate.py`, after line 150, insert 5 lines.** Line 150 is `PUSH_PEERS = {"add", "commit", "status", "diff", "log", "show"}  # R-P3b: git commands a push may share a line with`; line 151 `CONFIG_READS = {...` stays below.

```python
LINE_REDIRS = (">/dev/null", "> /dev/null", "1>/dev/null", "2>/dev/null", "2> /dev/null", "&>/dev/null", "2>&1",
               "1>&2", ">&2")  # R-L1: the only redirections a push line may hold
_PLAIN = re.compile(r"[A-Za-z0-9_./:@%+=,-]+")  # R-L1: characters neither bash nor zsh expands in an unquoted word
_DQPLAIN = re.compile(r'"[^"$`\\]*"')  # R-L1: double quotes with no `$`, backtick or backslash: no expansion
_HDWORD = re.compile(r"[A-Za-z_][A-Za-z0-9_.-]*")  # R-L1: the quoted delimiter word of a heredoc on a push line
```

**3. `scripts/bash_gate.py`, after line 631, insert 89 lines: the 87 lines below, then 2 empty lines.** Line 629 is `        deny(PUSH_DENY)`, the last line of `autocorrect_check`; lines 630 and 631 are empty; line 632 `segs = words(cmd, True)` stays below. After the edits, `def line_ok` is line 640, `def simple_line` line 653, and 2 empty lines stand before and after the two functions.

```python
def line_ok(c, piped):
    """R-L1: one command of a push line, its leading `{` words removed: `git push ...`, nothing, a `}`,
    `gh pr create ...`, a PUSH_PEERS git command with no `--output` word (`log`, `diff` and `show` write a file with
    it), or `tail` / `head` read from a pipe."""
    if c[:2] == ["git", "push"] and not piped:
        return True
    if piped:
        return c[:1] in (["tail"], ["head"])
    if not c or c == ["}"] or c[:3] == ["gh", "pr", "create"]:
        return True
    return c[:1] == ["git"] and c[1:2] != [] and c[1] in PUSH_PEERS and not any(w.startswith("--output") for w in c)


def simple_line(s):
    """R-L1 (K331): True when every command of `s` passes `line_ok`. Commands are joined by `&&`, `||`, `;`, a
    newline or a pipe `|`; a word is unquoted runs of _PLAIN characters (not starting with `=`, zsh's EQUALS),
    '...', and "..." with no `$`, backtick or backslash, so neither bash nor zsh expands it; `{` and `}` alone are
    words. Any command may hold the redirections of LINE_REDIRS and a heredoc whose delimiter is one quoted word
    (its body is data on stdin, ending at the line equal to the delimiter). One left-to-right pass; anything else is
    not simple (fail closed): a substitution, `&`, a subshell, a function, an assignment, `export`, `cd`, a script,
    an unquoted or `<<-` heredoc, a redirection to a file (even the push's own: truncating a git file before the
    push runs can send it to another repository), a comment, a glob."""
    cmds, cur, piped, pend, i, n = [], [], False, [], 0, len(s)
    while i < n:
        c = s[i]
        if c in " \t":
            i += 1
        elif c in ";\n|" or s.startswith("&&", i):
            cmds.append((cur, piped))
            two = s.startswith(("&&", "||"), i)
            cur, piped = [], c == "|" and not two
            i += 2 if two else 1
            if c == "\n":
                for d in pend:  # the heredoc bodies, in order, after this newline
                    while True:
                        e = s.find("\n", i)
                        line, i = (s[i:], n) if e < 0 else (s[i:e], e + 1)
                        if line == d:
                            break
                        if e < 0:
                            return False
                pend = []
        elif s.startswith("<<", i):
            i += 2
            while i < n and s[i] in " \t":
                i += 1
            j = s.find(s[i], i + 1) if i < n and s[i] in "'\"" else -1
            if j < 0 or not _HDWORD.fullmatch(s, i + 1, j) or (j + 1 < n and s[j + 1] not in " \t;\n&|"):
                return False  # `<<-`, `<<<`, an unquoted or unusual delimiter
            pend.append(s[i + 1:j])
            i = j + 1
        else:
            r = [x for x in LINE_REDIRS if s.startswith(x, i) and (i + len(x) == n or s[i + len(x)] in " \t;\n&|")]
            if r:
                i += len(r[0])
                continue
            if c in "{}" and (i + 1 == n or s[i + 1] in " \t;\n&|"):  # a group word, or a plain argument
                cur.append(c)
                i += 1
                continue
            w = []
            while i < n and s[i] not in " \t;\n&|":
                if s[i] == "'":
                    j = s.find("'", i + 1)
                    if j < 0:
                        return False
                    w.append(s[i + 1:j])
                    i = j + 1
                    continue
                m = _DQPLAIN.match(s, i) or _PLAIN.match(s, i)
                if not m or (not w and s[i] == "="):
                    return False
                w.append(m.group()[1:-1] if s[i] == '"' else m.group())
                i = m.end()
            if not w:
                return False  # a lone `&`: a background job
            cur.append("".join(w))
    cmds.append((cur, piped))
    if pend:
        return False  # a heredoc with no body
    for c, piped in cmds:
        k = 0
        while k < len(c) and c[k] == "{":  # bash's and zsh's group word: runs the list in this shell
            k += 1
        if not line_ok(c[k:], piped):
            return False
    return True
```

**4. `scripts/bash_gate.py`, after line 702, insert 2 lines.** Line 701 is `if pushed and other:  # R-P3b: another git command on the line may move HEAD or the upstream before the push runs`, line 702 `    deny(PUSH_DENY)`; line 703 (empty) and line 704 `if re.search(r"\bgit\s+commit\b", cmd):` stay below.

```python
if pushed and not simple_line(cmd):  # R-L1 (K331): another command or a redirection may move HEAD or the git dir
    deny(LINE_DENY)
```

Expected diff of `scripts/bash_gate.py` against the base: 4 hunks, 0 lines removed and 99 added (`git diff --numstat` gives `99	0`). The file has 818 lines after the edits and sha256 `6ee900fffa44b10282bef20b2fa6a4683245526380580a134d422911613f73b8`.

**Test file anchors.**
- **`tests/parse_gate_tests.sh`:** after line 30 (`DEEP_DENY="delixcrew: the command nests quotes ...`; line 31 `nest(){ ...` stays below), insert this line:
  ```text
  LINE_DENY="delixcrew: in an implementer session a $P shares its line only with $G add, commit, status, diff, log, show and gh pr create, pipes only into tail or head and redirects only to /dev/null; run every other command in a separate call"
  ```
  Line 76 (before the insertion) changes from `allow "32 function body, own branch send"            "$W" "f() { $G $P origin HEAD; }; f"` to:
  ```text
  deny "32 function body, own branch send"             "$W" "f() { $G $P origin HEAD; }; f" "$LINE_DENY"
  ```
  Line 109 (before the insertion) changes from `allow "49 own branch send after a heredoc file write" "$W" "cat > /dev/null <<'EOF'${NL}note${NL}EOF${NL}$G $P origin HEAD"` to:
  ```text
  deny "49 own branch send after a heredoc file write"  "$W" "cat > /dev/null <<'EOF'${NL}note${NL}EOF${NL}$G $P origin HEAD" "$LINE_DENY"
  ```
  Expected: 3 lines added and 2 removed; 158 lines and sha256 `ee9065bacec2f71aaa0b1aa3af7893292d9d6f8dfcd4c846c14500c3c82fc490` after the edit.
- **`tests/argv_gate_tests.sh`:** after line 29 (`QUOTE_DENY="delixcrew: a quote that is never closed ...`; line 30 `js(){ ...` stays below), insert the same `LINE_DENY=...` line as above. Line 114 (before the insertion) changes from `allow "58 own branch send, >f"                    "$W" "$G $P origin claude/t1 >f"` to:
  ```text
  deny "58 own branch send, >f"                     "$W" "$G $P origin claude/t1 >f" "$LINE_DENY"
  ```
  Line 115 (before the insertion) changes from `allow "59 own branch send, &>f"                   "$W" "$G $P origin claude/t1 &>f"` to:
  ```text
  deny "59 own branch send, &>f"                    "$W" "$G $P origin claude/t1 &>f" "$LINE_DENY"
  ```
  Expected: 3 lines added and 2 removed; 200 lines and sha256 `94e6261b0e056060e7d86155ba44d10a3487a4efe22ab5526feec34984d3a40d` after the edit.
- In these list items each code line carries exactly 2 leading spaces that belong to the list: remove those 2 and keep the rest (the lines start at column 1 in the file). The four changed lines keep the file's own `deny` helper, which takes the expected message as the fourth argument.
- **`tests/push_line_tests.sh`, new, 92 lines, sha256 `18051bb4181e9ff3a228baa3de8d6e4586dff74c1fe78f3bc59819edc7f962f4`** (ASCII; mode as the other test files, run with `bash`):

```bash
#!/usr/bin/env bash
# T052 (spec C K296, K331, R-L1): in an implementer worktree a line that pushes holds only git add, commit, status,
# diff, log, show, gh pr create and the push, joined by && || ; | or a newline, with words no shell expands; a push
# may pipe into tail or head, and the line redirects only to /dev/null. The trigger words are assembled at run time; this
# file holds none of them. ASCII only.
# Run: bash tests/push_line_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"
OK="$(printf '\342\234\224')"; NO="$(printf '\342\234\230')"; NL="$(printf '\nx')"; NL="${NL%x}"
T="$(mktemp -d)"; W="$T/w"; L="$T/l"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
mk(){ # <dir> <branch> [card]: a repo with one empty commit on <branch>; with "card", .delix/card and delix.json
  mkdir -p "$1" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD "refs/heads/$2" \
    && $GC -C "$1" commit -q --allow-empty -m init
  if [ "${3:-}" = card ]; then
    mkdir -p "$1/.delix" "$1/docs/delix" "$1/.git/info"; echo "docs/delix/tasks/T052-x.md" > "$1/.delix/card"
    echo ".delix/" >> "$1/.git/info/exclude"; printf '{"default_branch":"main"}' > "$1/docs/delix/delix.json"
  fi
}
mk "$W" claude/t1 card; mk "$L" claude/t1
$G -C "$W" remote add origin "$W.git"; $G -C "$W" update-ref refs/remotes/origin/main HEAD
$G -C "$W" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
LINE_DENY="delixcrew: in an implementer session a $P shares its line only with $G add, commit, status, diff, log, show and gh pr create, pipes only into tail or head and redirects only to /dev/null; run every other command in a separate call"
js(){ python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"; }
run(){ js "$1" "$2" | python3 "$S/bash_gate.py"; }
allow(){ out=$(run "$2" "$3"); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "$OK $1"; else echo "$NO $1 (expected allow): $out"; FAIL=1; fi; }
deny(){ out=$(run "$2" "$3"); if echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$LINE_DENY"; then echo "$OK $1"; else echo "$NO $1 (expected deny: $LINE_DENY): $out"; FAIL=1; fi; }

# Allow: git peers and the push, quoted messages, the listed redirections, other lines with no push
allow "push alone"                          "$W" "$G $P origin HEAD"
allow "-u own branch, 2>&1"                 "$W" "$G $P -u origin claude/t1 2>&1"
allow "> /dev/null"                         "$W" "$G $P origin HEAD > /dev/null"
allow "2>/dev/null"                         "$W" "$G $P origin HEAD 2>/dev/null"
allow "add, commit '...', push"             "$W" "$G add a.py b.py && $G commit -m 'T052: x (K331); y | z \$HOME' && $G $P -u origin HEAD"
allow "commit \"...\" ; push"               "$W" "$G commit -m \"T052: fix, see K331\" ; $G $P origin HEAD"
allow "newlines"                            "$W" "$G status${NL}$G $P origin HEAD${NL}$G log -1 --oneline"
allow "message over two lines"              "$W" "$G commit -m 'a${NL}${NL}b' && $G $P origin HEAD"
allow "|| status"                           "$W" "$G $P origin HEAD || $G status"
allow "then gh pr create"                   "$W" "$G $P -u origin HEAD && gh pr create --title 'T052: x' --body-file b.md"
allow "pipe into tail"                      "$W" "$G $P origin HEAD 2>&1 | tail -3"
allow "pipe into head, then tail"           "$W" "$G $P origin HEAD 2>&1 | head -20 | tail -1"
allow "group of peers"                      "$W" "{ $G add a.py; $G status; } && $G $P origin HEAD"
allow "log --oneline, then push"            "$W" "$G log --oneline -3 && $G $P origin HEAD"
allow "pipe from a peer"                    "$W" "$G status | tail -1; $G $P origin HEAD"
allow "gh pr create into tail"              "$W" "$G $P -u origin HEAD 2>&1 | tail -2 && gh pr create --title x --body-file b.md 2>&1 | tail -2"
allow "commit from a quoted heredoc"        "$W" "$G commit -q -F - <<'E'${NL}T052: x \$(id) \`id\`${NL}${NL}body; | & > f${NL}E${NL}$G $P -u origin HEAD"
allow "two quoted heredocs, push between"   "$W" "$G commit -F - <<\"A\" && $G $P origin HEAD && $G log -1 <<'B'${NL}a${NL}A${NL}b${NL}B"
allow "no card: any line"                   "$L" "bash x.sh && $G $P origin HEAD:main"
allow "no push: other commands"             "$W" "bash tests/x.sh && echo ok > out.txt"

# Deny: anything else on a push line (the two shapes measured on main first)
deny "export GIT_DIR"                       "$W" "export GIT_DIR=/tmp/x/.git; $G $P origin HEAD"
deny "write the HEAD file"                  "$W" "echo 'ref: refs/heads/main' > .git/HEAD; $G $P origin HEAD"
deny "log --output into the git dir"        "$W" "$G log -1 --format='tformat:ref: refs/heads/main' --output=.git/HEAD main; $G $P origin HEAD"
deny "diff --output, separate word"         "$W" "$G diff --output .git/x; $G $P origin HEAD"
deny "a peer redirected to a file"          "$W" "$G status > .git/HEAD; $G $P origin HEAD"
deny "cp into refs"                         "$W" "cp .git/refs/heads/claude/t1 .git/refs/heads/main && $G $P origin HEAD"
deny "assignment before a peer"             "$W" "GIT_DIR=/tmp/x/.git $G status; $G $P origin HEAD"
deny "test run before the push"             "$W" "bash tests/x.sh && $G $P origin HEAD"
deny "pipe into tee"                        "$W" "$G $P origin HEAD | tee .git/HEAD"
deny "pipe into a shell"                    "$W" "$G $P origin HEAD | sh"
deny "reader redirected to a file"          "$W" "$G $P origin HEAD | tail -1 > .git/HEAD"
deny "push output to a file"                "$W" "$G $P origin HEAD >push.log 2>&1"
deny "push output into the git dir"         "$W" "$G $P origin HEAD > .git/HEAD"
deny "gh pr create redirected to a file"    "$W" "gh pr create --title x > .git/HEAD; $G $P origin HEAD"
deny "echo after the push"                  "$W" "$G $P origin HEAD && echo ok"
deny "background job"                       "$W" "$G $P origin HEAD &"
deny "\$(...) in double quotes"             "$W" "$G commit -m \"\$(echo x)\" && $G $P origin HEAD"
deny "backticks"                            "$W" "$G commit -m \`echo x\` && $G $P origin HEAD"
deny "backslash in double quotes"           "$W" "$G commit -m \"a\\\"b\" && $G $P origin HEAD"
deny "a git at a path"                      "$W" "./$G $P origin HEAD"
deny "glob"                                 "$W" "$G add *.py && $G $P origin HEAD"
deny "zsh EQUALS word"                      "$W" "$G add =x && $G $P origin HEAD"
deny "subshell"                             "$W" "($G status) && $G $P origin HEAD"
deny "group redirected to a file"           "$W" "{ $G log -1; } > .git/HEAD; $G $P origin HEAD"
deny "function"                             "$W" "f() { $G status; }; f; $G $P origin HEAD"
deny "heredoc into cat"                     "$W" "cat > .git/HEAD <<'E'${NL}ref: refs/heads/main${NL}E${NL}$G $P origin HEAD"
deny "unquoted heredoc"                     "$W" "$G commit -F - <<E${NL}x${NL}E${NL}$G $P origin HEAD"
deny "<<- heredoc"                          "$W" "$G commit -F - <<-'E'${NL}x${NL}E${NL}$G $P origin HEAD"
deny "heredoc with no end"                  "$W" "$G commit -F - <<'E'${NL}x${NL}$G $P origin HEAD"

# Linear: a long push line is read in one pass (x8 input, under x16 time): many words, many group words
long(){ python3 -c 'import sys; g, n, p, k = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]; print(("{ " * n if k == "group" else "") + g + " add" + (" a" * n if k == "words" else "") + " && " + g + " " + p + " origin HEAD")' "$G" "$1" "$P" "$2"; }
tm(){ c="$(long "$1" "$2")"; s=$(python3 -c 'import time; print(time.time())'); run "$W" "$c" >/dev/null; python3 -c "import time; print(time.time() - $s)"; }
for k in words group; do
  t1=$(tm 4000 $k); t8=$(tm 32000 $k)
  if python3 -c "import sys; sys.exit(0 if $t8 < 2 and $t8 < 16 * max($t1, 0.05) else 1)"; then echo "$OK long line, $k: ${t1}s, x8 ${t8}s"; else echo "$NO long line, $k: ${t1}s, x8 ${t8}s"; FAIL=1; fi
done

rm -rf "$T"
if [ "$FAIL" -eq 0 ]; then echo "ALL PASSED"; else echo "FAILED"; exit 1; fi
```

Applied to the base, the anchors give the lead's prototype byte for byte.

## Rules (allowlist, fail closed)
- **R-W0, scope:** every rule sits behind `card_path(cwd)`: a session with no `.delix/card` (the user's terminal, the lead) is unchanged.
- **R-L1, the push line (K331):** after R-P3b, when `pushed` is True (the line holds an own-branch push that R-P1 to R-P3b allowed), `simple_line(cmd)` must be True, otherwise the hook denies with `LINE_DENY`. `simple_line` reads the stripped command once, left to right:
  - commands are joined by `&&`, `||`, `;`, a newline or `|`; a `|` makes the next command a pipe reader;
  - a word is made of unquoted runs of `_PLAIN` characters, `'...'`, and `"..."` with no `$`, backtick or backslash; a word does not start with an unquoted `=` (zsh's EQUALS expansion); `{` and `}` alone are words, and leading `{` words are dropped from a command (a group runs in the same shell);
  - any command may hold the redirections in `LINE_REDIRS` (`/dev/null` and descriptor copies) and heredocs whose delimiter is one quoted `_HDWORD`; the bodies follow the next newline in order and each ends at the line equal to its delimiter;
  - `line_ok` then accepts per command: `git push ...` (not a pipe reader), nothing, `}`, `gh pr create ...`, `git <PUSH_PEERS>` with no word that starts with `--output`, and `tail` or `head` as a pipe reader;
  - anything else returns False: another command, an assignment, `export`, `cd`, a script, a substitution, `&`, a subshell, a function, a comment, a glob, a backslash, `$'...'`, an unquoted, `<<-` or `<<<` heredoc, a heredoc with no end, and a redirection to a file (the push's own too).
- **Messages:** `LINE_DENY` is new (anchor 1); `PUSH_DENY` and every other message do not change.
- **Regex discipline:** 3 new patterns, each one character class with a quantifier (no alternation, no nesting); `simple_line` moves forward on every step or returns, so it is linear (the two growth cases in the new test file, many words and many group words: ×8 input under ×16 time and under 2 s; the lead's prototype first dropped the group words one list slice at a time and took 2.3 s at 32000, which the second case catches).
- **Known false positives (fail closed):**
  - a push line with any command outside the list, a test run or an `echo` included: run it in a separate call;
  - a push whose output goes to a file, and `git -C` or `git -c` on a push line;
  - a `$`, backtick or backslash in a double-quoted commit message on a push line (use single quotes or `-F -` with a quoted heredoc);
  - a line with other commands whose quoted text mentions a push (R-P3 reads quoted words; T048).

## Decisions (lead, 2026-11-18)
- **D1, evidence (lead, Python 3.9.6, bash 3.2.57, zsh 5.9, git 2.54, Mac).** Probes in the lead's scratchpad (`T052-proto/`): the real hook, then real bash and git in a throwaway card repository with a local bare `origin`, no network.
  - 4 forms pass main and land the push on `main` of the remote (or of a second repository): an exported `GIT_DIR` before the push; writing the `HEAD` file; `git log --output` into the `HEAD` file (with the explicit revision); and, in a full clone nested in another repository, the push's own output redirected into `.git/HEAD` (git then finds the outer repository and pushes its branch). The prototype denies all 4 (`tests/push_line_tests.sh` holds each).
  - Real use: 308 unique Bash lines that hold the push word, taken from the transcripts of this repo's worktree sessions, run through main and the prototype in a card worktree: 303 give the same verdict, 5 go from allow to deny, and each of the 5 mixes the push with other commands (`sed`, `chmod`, `ls`, `head`, `cat`, a variable assignment). None of them sends the push output to a file.
  - Tests: the three edited and new test files on the base code give `tests/push_line_tests.sh` 22 `✔` / 29 `✘`, `tests/parse_gate_tests.sh` 70 `✔` / 2 `✘`, `tests/argv_gate_tests.sh` 108 `✔` / 2 `✘`; on the prototype 51, 72 and 110 `✔`, and all 17 `tests/*_tests.sh` exit 0 on Python 3.9.6 and on 3.13 through a PATH shim (Python 3.13.13; 34 runs, 0 `✘`).
- **D2, the allowlist.** Each entry is on it because it cannot move HEAD, the upstream or the git dir before the push runs:
  - the peers are R-P3b's own `PUSH_PEERS`; `log`, `diff` and `show` write a file with `--output` (git 2.54 rejects the abbreviations `--outp`, `--outpu`, `--ou`, `--o` for all three, measured), so a word that starts with `--output` denies, `--output-indicator-*` included;
  - `gh pr create` is the PR step of the implement protocol and was allowed after the push (push_gate test "HEAD, then gh pr create");
  - `tail` and `head` only read; only as a pipe reader, so the push output can be cut;
  - `/dev/null` and descriptor copies write no file; a quoted heredoc is literal stdin data in bash and zsh;
  - words with no expansion: no variable, substitution, glob, brace, tilde or EQUALS can turn into a path or a command.
- **D3, four existing test lines change (K255 and K273 precedent).** Each was an allow case of a shape R-L1 now denies:
  - `tests/parse_gate_tests.sh` line 76 (case 32): a function definition on a push line is code the parser does not follow;
  - line 109 (case 49): `cat` with a heredoc is a command outside the list, and the same shape with a file other than `/dev/null` writes the git dir (push_line case "heredoc into cat");
  - `tests/argv_gate_tests.sh` lines 114 and 115 (cases 58, 59): the push's own output to a file; D1's fourth form is this shape. The cases keep their labels and commands and now expect `LINE_DENY`.
- **D4, docs in the release card (K298).** README "Known limits" (and README.tr, `site/usage.html`, `site/tr/usage.html`) then drop "a git config file written by another command on the same line" and add the R-L1 false positives; the lead writes that card after the merge.
- **D5, zsh.** Claude Code's Bash tool on this Mac runs zsh 5.9; `_PLAIN` and `_DQPLAIN` hold only characters that bash and zsh read the same way, and the EQUALS word (`=cmd`) denies.
- **D6, no change to R-P1 to R-P3b.** R-L1 is a new check after them on the raw text, so every earlier verdict and message stays (the 16 existing suites pass with only the 4 lines of D3 changed).

## Lead decisions
1. **Order:** after T051 (merged); the release card that carries T051's panel version and this card's docs comes after the merge.
2. **Acceptance:** the lead runs the D1 probes and the real-use comparison on the PR head.
3. **Publication (K313):** the card enters main at dispatch, so the window is dispatch to merge.

## Out of scope (each with the reason)
- **O1, a write in an earlier call:** the hook reads HEAD and the upstream when the push call starts (R-P3 `push_branch`), so an earlier call's write is seen; the shell's variables do not carry over between calls.
- **O2, programs git runs:** hooks, `diff.external`, textconv and filters, scripts: the README's "a script" Known limit.
- **O3, the inherited environment:** `GIT_DIR` and other git variables set before the session starts; a Known limit.
- **O4, a push the hook does not see:** R-L1 runs only when R-P3 found the push; the R-P rules and their Known limits do not change.

## Interfaces
- Consumed: `pushed` (R-P3), `PUSH_PEERS`, `deny`, `cmd`.
- Produced: `LINE_DENY`, `LINE_REDIRS`, `_PLAIN`, `_DQPLAIN`, `_HDWORD`, `line_ok`, `simple_line`, R-L1.

## Global Constraints (verbatim)
- K313: "Kod düzeltmesi (R-P5) ayrı bir 🔐 Tier 3 kartıdır; tasarımı o kartla yayımlanır."
- Repo hook rules: no new regex with overlapping alternation; the test driver lives in the test file with the trigger words assembled at run time; existing tests change only where the card names the line and the reason.
- Python 3.9 stdlib; no version-dependent behaviour (the Mac runs 3.9.6, CI 3.12; run the suites on 3.13 as well). ASCII only in the new code and test lines; no invisible character.

## Steps
1. Create `tests/push_line_tests.sh` and edit the two other test files per the test file anchors. Run the three files and see **red**: `tests/push_line_tests.sh` 22 `✔` and 29 `✘`; `tests/parse_gate_tests.sh` 70 `✔` and 2 `✘` (cases 32 and 49); `tests/argv_gate_tests.sh` 108 `✔` and 2 `✘` (cases 58 and 59); each ends with `FAILED`. A different count means a case differs from the card: say so in the report.
2. Edit `scripts/bash_gate.py` per Edit anchors 1 to 4, in any order (each anchor names base line numbers; apply them from the bottom up, or find each by its quoted content); run the `ast.parse` one-liner.
3. Run the three files and see **green**: 51, 72 and 110 `✔`, no `✘`, `ALL PASSED`. Run them again on Python 3.13 through a PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 4 paths by name, in a call of its own. Commit `T052: a push line holds only the push and its git peers (this card's cases)` in a call of its own. No command of yours, and no commit message, holds `git` followed by `push`, `update-ref` or `remote` as words on one line, except the one push below. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd` and nothing else on the line. Open a PR with `--body-file` and a `## How I tested` section.
6. After step 2 your own session may run the edited hook (if the plugin loads from this worktree): a push line with any other command denies with `LINE_DENY`. Keep every push on a line of its own.

## Tests (`tests/push_line_tests.sh`, new; `ALL PASSED` at the end)
- **Words and helpers:** `G`, `P` (the trigger words, built at run time), `W` (a card worktree on `claude/t1` with `origin/HEAD` set), `L` (no card), `NL` (a newline), `LINE_DENY`; `allow` (exit 0, no deny) and `deny` (the deny decision and exactly `LINE_DENY`).
- **Cases:** 20 allow cases (the push alone and with each listed redirection; peers with single- and double-quoted messages, newlines, `||`; `gh pr create`; pipes into `tail` and `head`; a group of peers; quoted heredocs; a line with no card; a line with no push), 29 deny cases (the 4 D1 forms; `diff --output` as two words; a peer, a reader, a group and `gh pr create` redirected to a file; `cp`; an assignment; a test run; `tee` and `sh` as readers; `echo`; `&`; `$(...)`, backticks and a backslash in double quotes; a git at a path; a glob; the EQUALS word; a subshell; a function; a heredoc into `cat`; an unquoted, a `<<-` and an unended heredoc; the push output to a file), and 2 growth cases. The labels are in the file.

## Verification command → expected output
- `bash tests/push_line_tests.sh` → last line `ALL PASSED` · `bash tests/push_line_tests.sh | grep -c '^✔'` → `51`
- `bash tests/parse_gate_tests.sh | grep -c '^✔'` → `72` · `bash tests/argv_gate_tests.sh | grep -c '^✔'` → `110`
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/push_line_tests.sh | tail -1` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, on Python 3.9.6 and through the 3.13 shim
- `bash tests/site_tests.sh` → exit 0 (site files are untouched)
- `claude plugin validate .` → passes
- `git diff --numstat origin/main` → exactly `99	0	scripts/bash_gate.py`, `3	2	tests/argv_gate_tests.sh`, `3	2	tests/parse_gate_tests.sh`, `92	0	tests/push_line_tests.sh`
- `shasum -a 256 scripts/bash_gate.py tests/push_line_tests.sh tests/parse_gate_tests.sh tests/argv_gate_tests.sh` → the four "after" sha256s of the anchors
- `git diff -U0 origin/main -- scripts | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"` → no output
- `git diff -U0 origin/main | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and any(ord(c) > 126 or (ord(c) < 32 and c != '\t') for c in l)]"` → no output
- **Lead, on the PR head (not the implementer's):** the D1 probes → the 4 forms deny; the real-use comparison → 303 same, 5 allow to deny.

## Review Focus
- `simple_line` moves forward on every branch or returns, and fails closed on every character it does not know.
- No word the shell would expand is read as plain text; the heredoc bodies end where bash and zsh end them.
- No existing test line changes beyond the 4 of D3; the 17 suites pass on Python 3.9.6 and 3.13.
- The allow cases still pass: the implement protocol's add, commit, push and PR lines.

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `README.md`, `README.tr.md`, `CHANGELOG.md`, `site/**`, every other test file and every existing line of the two edited test files beyond the 4 of D3.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a dependency, an option, an entry to the allowlist or a rule beyond R-L1. If a case in Out of scope looks easy, write it in the report instead.
- Do not name a form that passes main in the PR title, the PR body or the commit message; refer to "this card's cases" (K313).
- No raw non-ASCII or invisible character in code or tests.
- Verification commands never put `git` followed by `update-ref`, `remote` or `push` as words in the command text, except the one push in Step 5.

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`, `bash --version`;
- the red and green counts;
- PR number and branch;
- assumptions;
- every denial of your own commands by the edited hook, with the command shape (not the words of a form that passes main);
- every pre-existing slow path or crash seen and not fixed.

Read only this card and spec K283, K296, K313 and K331.

## Spec K entry (K331 in the spec)
```text
- **K331** (lead, 2026-11-18, geri alınır) T052 kartı (🔐 Tier 3, `scripts/bash_gate.py`; lead yazdı). Kullanıcı
  "bash_gate sertleştirme", sonra "Satır izin listesi" dedi.
  - **R-L1:** kart worktree'sinde kendi dal push'unu taşıyan satırda her komut push, `git add`, `commit`, `status`,
    `diff`, `log` ya da `show` (`--output` yok), `gh pr create` ya da borudan okuyan `tail` / `head` olur. Ayırıcı
    `&&`, `||`, `;`, `|` ya da yeni satır; kelimeleri bash ve zsh genişletmez; tırnaklı heredoc serbest; yönlendirme
    yalnız `/dev/null` ve tanımlayıcı kopyası. Başka her push satırı yeni `LINE_DENY` ile reddedilir. Kapanan: K283
    ve K296'daki "push satırının tamamına izin listesi" takip işi (T044 O2).
  - **Ölçüm:** 4 biçim main'den geçip push'u `main`'e götürür (satırdaki komut ya da yönlendirme, hook HEAD'i
    okuduktan sonra HEAD'i ya da git dizinini değiştirir); prototip 4'ünü reddeder. Worktree oturumlarından 308 gerçek
    satırın 303'ü aynı sonucu verir, 5'i izinden redde döner (hepsi push'u başka komutla karıştırır). 17 test dosyası
    Python 3.9.6 ve 3.13'te geçer.
  - **Mevcut test:** 4 satır değişir (parse 32 ve 49, argv 58 ve 59); kart her birini satır numarası ve nedeniyle
    anar (K255, K273 emsali).
  - **Belge:** README, README.tr ve site "Known limits" metni sonraki sürüm kartında güncellenir (K298).
  - **Yayın:** geçen biçimler yalnız kartta ve testte durur (K313); kart main'e dispatch'te girer.
```

## Review findings (filled by the lead)
- Round 1 (PR #83, head `901c88eb41c359cfed50a7a93f6553de29dac1f6`, base `b9b3906`, 2026-11-18): qa `ACCEPT` (0 P0,
  0 P1), security `FIX` (1 High). Lead gates on the clean `git archive` of the head: exactly the 4 Files, numstat 99/0,
  3/2, 3/2, 92/0; the 4 sha256s equal the card's "after" values and the lead's prototype; 17 suites exit 0 with no `✘`
  on Python 3.9.6 and 3.13.13 (`push_line_tests.sh` 51 `✔`); the real-use comparison gives 303 same and 5 allow to
  deny; the Stop gate gives `[exit 0]`; CI `check` and `test` green.
  - High (security, reproduced by the lead): zsh, the Bash tool's shell, ends a brace group at a `}` anywhere on the
    command line and runs `{ list } always { list }`; `simple_line` took the `}`, `always` and `{` as words of one peer
    command. `{ git status } always { export GIT_DIR=<main checkout>/.git }; git push origin HEAD` passes main and the
    head; in zsh 5.9 (no brace option set, no global alias) the push moved the remote's `main` to the main checkout's
    local commit. Not a regression against main (D1 form 1 passes there), but it breaks R-L1 and D5.
    Fix (round 2): after a command's leading `{` words, a `{` or `}` word denies unless the command is a lone `}`; two
    deny cases in `tests/push_line_tests.sh`. Known false positives (fail closed): zsh's `{ git status }` with no `;`
    before the `}`, and a peer argument that is exactly `{` or `}`, quoted too. Lead prototype: the head with the two
    cases gives 51 `✔` / 2 `✘`, the fix 53 `✔`; 17 suites exit 0 with no `✘` on Python 3.9.6 and 3.13.13, and the real-use comparison is unchanged
    (303 same, 5 allow to deny).
  - Note (security unsure, checked by the lead): zsh global aliases would expand any plain word; the tool shell has
    none (`alias -g` lists 0); a shell snapshot that defines them is the O3 class.
  - Note (security unsure, no change): `gh pr create` before the push may run git itself; out of scope like O2.
  - Note (implementer): the session's own hook was the installed plugin from the main checkout (the base
    `bash_gate.py`); the write gate refused two Write calls to the session scratchpad, so helper files went to
    `.delix/`.
- Round 2 (PR #83, head `3e385a524d0d41555abde95403bad22ca54e26e9`, base `b9b3906`, 2026-11-18): qa `ACCEPT` (0 P0,
  0 P1), security `🔐 HUMAN_APPROVAL` (no finding). Lead gates on the clean `git archive` of the head: exactly the 4
  Files, numstat 102/0, 3/2, 3/2, 94/0 against the base; the 4 files equal the lead's round-2 prototype byte for byte
  (`scripts/bash_gate.py` `3aac7c26614524a8fc847ceeb323f3e95893a7ae6a3e28cce650830ed3373f3e`, 821 lines;
  `tests/push_line_tests.sh` `c7a1aa2538600c900e05fd7924f2473c8ac31f009e6a2d990e1b5e029a1617c4`, 94 lines; the two
  other test files as in round 1); 17 suites exit 0 with no `✘` on Python 3.9.6 and 3.13.13 (`push_line_tests.sh` 53
  `✔`); the round-1 zsh lines deny on the head and pass main; the real-use comparison gives 303 same and 5 allow to
  deny; the Stop gate gives `[exit 0]` twice; CI `check` and `test` green. Round 1's High is closed.
  - Note (qa and security): the card's Edit anchors and Verification values are round 1's (`99 0`, `6ee900ff...`,
    51 `✔`); this record and round 1's fix line hold round 2's.
  - Note (security unsure, checked by the lead): zsh options outside the defaults (`MAGIC_EQUAL_SUBST`, `RC_QUOTES`,
    `IGNORE_BRACES`, `IGNORE_CLOSE_BRACES`) change how words are read; the tool shell sets none of them (`setopt`, 0
    hits); a shell snapshot that sets them is the O3 class.
  - Note (security, pre-existing, not in this PR): `claude plugin validate .` warns about a loopback
    `documentationUrl` it reads from README text; for the release card, which touches README.
- Merged (K334): the user merged head `3e385a524d0d41555abde95403bad22ca54e26e9` as it is (merge commit
  `64c1325562601884c03e1b06520c636952150584`, 2026-11-18T08:26:11Z). The merge commit changes only the 4 Files, and
  they equal the reviewed head byte for byte (round 2's sha256s). Status `accepted`.
