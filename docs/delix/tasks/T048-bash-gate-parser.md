# T048 🔐 — bash_gate: `bash_argv` reads a command in one pass the way bash reads it (substitutions, comments, heredoc bodies, `$'…'`, brace groups); an alias value is split the way git splits it

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T048 | M | 3 | backend | 18 | open |

**🔐 Approved:** 2026-11-13 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`; `scripts/common.py` `matches` returns that entry for it). `tests/parse_gate_tests.sh` matches `test_paths` (`tests/**`) and no protected entry, and it is a new file. `tests/argv_gate_tests.sh` matches `test_paths` too and is in Files for its line 148 only (K310).
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-13 ("Evet, B ile", said in the lead session; K310). The lead commits it to main before dispatch; the session branches from that commit.
> - The session is interactive and the user opens it, as for T041, T044 and T047.
> - It closes what K304 and K305 send to T048, all open on main (`408d166`, which holds the merged T047 head): the round-4 Medium of T047 (a `#` glued to a closing backtick or to the `)` of `$(...)` starts a comment, and the comment's re-read drops the rest after a quote that is never closed), a command word glued to a quoted substitution, an apostrophe in double quotes or in a heredoc body before a `$(...)`, double quotes nested in `"$(...)"`, and the alias values that git splits with `split_cmdline` (K302). It also removes the false positive K304 names: `{ git push origin HEAD; }` denies on main.
> - The card writer measured every form with the real hook and with bash 3.2.57 and git 2.54 in a throwaway card repository with a local bare `origin`: 25 forms push `main`, write a ref or change the URL of `origin` and pass main; the prototype denies all 25 (Decisions D10).
> - It is defence in depth, not a boundary: the rules are a check on the command's words (see Out of scope).

**Goal (1 sentence):** In an implementer worktree `bash_argv` reads a command in one left-to-right pass with the contexts bash has (command list, double quotes, backticks, `$(...)`, heredoc bodies), so that a `#` inside a word, a word glued to a substitution, an apostrophe before a substitution in double quotes or in a heredoc body, nested double quotes in `"$(...)"`, `$'\''`, a brace group and nesting too deep to read no longer hide a push to the default branch, a ref write or a remote write from the rules; and the alias check reads an alias value the way git splits it, from `git config -z`. · **Spec:** `docs/delix/specs/C-board-visibility.md` K301 to K305 (lines 429–507); T047 Review findings, Round 4 and Merged (`docs/delix/tasks/T047-bash-gate-argv.md` lines 472–517); T047 Out of scope O1 and O2; `STATUS.md` §13 (lines 634–645)

**Docs/site:** none in this card, the same exception as T044 and T047 (K298): T046 writes the README, README.tr and site sentences from the `## Docs handover (T046)` section at the end of this card. Do not touch `README.md`, `README.tr.md` or `site/**`. Order (K309): this card, then T046, then the 🔐 release card T042; this card is wave 18 (K308), and T046 takes H0's branch "T048 is merged first".

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (eight edits, see Edit anchors)
- Create: `tests/parse_gate_tests.sh`
- Modify: `tests/argv_gate_tests.sh` (line 148 only, see the test file anchor; D4)

## Edit anchors (base origin/main 408d166, full SHA 408d1666fb3ef6088cd9d1829fe9563639e42dd8)
Line numbers are from that commit (`scripts/bash_gate.py` there has 477 lines and sha256 `60317dffaf96e283edf4841321edc921989dd8e4d6913e57fb935aeebb625b49`). Match the quoted content before you edit each place. If it differs, stop with `NEEDS_CONTEXT`. Edit bottom-up (anchor 8 first, anchor 1 last) so the line numbers above you hold. Every new line is at most 120 characters. After each edit run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output: if this repo's plugin loads from your worktree, a syntax error would block your own Bash.

Python is indentation-sensitive. The code blocks below sit inside list items, so every code line carries exactly 3 extra leading spaces that belong to the list: remove those 3 and keep the rest (a blank line in a block is empty). Each anchor says how deep its first line sits in the file.

1. **After line 138, insert two lines (no indentation on the first).** Lines 137–138 are `QUOTE_DENY` (line 138 is `              "close the quote or put the text in a file, then run the command again")`); line 139 `GIT_ARG_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--attr-source",` stays below.
   ```text
   DEEP_DENY = ("delixcrew: the command nests quotes or substitutions deeper than this hook reads; split it or put the "
                "text in a file, then run the command again")
   ```
2. **Lines 154–157, replace** the four lines `_TOK = re.compile(...` (three lines, 154–156) and `` _CMEND = (re.compile(r"\n"), re.compile(r"[\n`]"))  # R-W1: a comment ends at a newline, inside `...` also at ` `` (157) with the eight lines below (no indentation). Lines 152–153 (`_MARKS`, `_SPLIT`) stay above and do not change; line 158 `` _DQ = re.compile(r"\\([\\\"$`]|\n)")  # inside double quotes a backslash escapes only these `` stays below.
   ```text
   _RUN = re.compile(r"[^ \t\n;&|()<>'\"\\`$#]+")  # R-W1: characters bash adds to a word as they are
   _DQRUN = re.compile(r"[^\"\\$`]+")  # the same inside double quotes
   _HDRUN = re.compile(r"[^\\$`]+")  # the same in a heredoc body whose delimiter has no quote
   _BQRUN = re.compile(r"[^`\\]+")  # the same inside `...`
   _OP = re.compile(r"&>>?|[<>]+(?:&-?|\|)?")  # a redirection operator (the `op` group of T047's tokenizer)
   _ANSI = re.compile(r"\$'((?:[^'\\]|\\.)*)'", re.S)  # R-W10: in $'...' a backslash escapes the next character
   _ESC = re.compile(r"\\([\\'\"?])")  # the escapes of $'...' that the value keeps as one character
   _QR = re.compile(r"\\(.)|'([^']*)'|\"((?:[^\"\\]|\\.)*)\"", re.S)  # R-H1: quote removal of a heredoc delimiter
   ```
3. **After line 159, insert 19 lines.** Line 159 is `` _CODE = re.compile(r"[ \t;&|(){}\n\r`'\"\\]")  # a quoted token with one of these may be code (`sh -c "..."`, `$(...)`) ``; lines 160–161 (blank) and line 162 `def gitword(t):` stay below. The block starts with two blank lines, then `class _Open` (no indentation) and `def delim` (no indentation; its body 4 and 8 spaces).
   ```text


   class _Open(Exception):
       """R-W3: a quote or a backtick that is never closed, at index args[0] of the text being read."""


   def delim(raw):
       """R-H1: a heredoc delimiter word as bash reads it: (its text with quotes removed and nothing expanded, whether a
       part of it is quoted). A backslash-newline vanishes and quotes nothing."""
       q = []

       def unq(x):
           if x.group(1) == "\n":
               return ""
           q.append(x)
           if x.group(3) is None:
               return x.group(1) if x.group(2) is None else x.group(2)
           return _DQ.sub(lambda y: "" if y.group(1) == "\n" else y.group(1), x.group(3))
       return _QR.sub(unq, raw), bool(q)
   ```
4. **Lines 176–238, replace** the whole T047 `bash_argv`, from line 176 `def bash_argv(text, depth=0, cm=True):` to line 238 `    return segs, rest`, with the block below (219 lines; `def bash_argv(text):` has no indentation, its helpers `bq`, `dq`, `hd`, `bodies` and `cmds` sit at 4 spaces, `flush` at 8). Lines 239–240 (blank) and line 241 `def words(text, top=False):` stay below.
   ```text
   def bash_argv(text):
       """R-W1 (T048): the argv bash builds from `text`, as segments of tokens, read in one pass the way bash reads it.
       A word is made of parts: characters, a quoted string (a quote pairs with the next one of its kind; in double
       quotes a backslash escapes only \\ " $ ` and a newline), an escaped character (a backslash-newline, or a lone
       backslash at the end, vanishes), and R-W10 `$'...'` (a backslash escapes the next character) and `$"..."`.
       R-W7: the commands of `$(...)` and `...` are segments of their own wherever the substitution stands (in double
       quotes, in a redirection target, in a heredoc body); its output counts as no text, so `"$(true)"git` is the word
       `git` and an unquoted word of substitutions only is no argument. `$(...)` ends at the `)` that closes it outside
       quotes and comments; `...` ends at the first backtick no backslash escapes, and its text is read on its own.
       R-W8: a `#` starts a comment only where no part of a word has been read; the comment ends at a newline. An
       unquoted `<` or `>` starts a redirection: operator, file descriptor number and target word are no arguments.
       R-H1: `<<` and `<<-` take a delimiter word (`delim`); the body starts after the next newline and ends at a line
       equal to the delimiter (`<<-` strips leading tabs; with no quote in the delimiter a backslash-newline joins lines
       first and the body's substitutions run). R-W9: an unquoted `{` or `}` as the first word of a command is a
       reserved word, no argument. R-W2: a quoted token that holds a blank, a separator or a quote, and every heredoc
       body, is read again the same way (`sh -c "..."`, `bash <<EOF`); each such text is shorter than its source, so
       the recursion ends. Returns (segments, tail): R-W3, the tail is the text from a quote or a backtick that is never
       closed, and the tails of the heredoc bodies that have one (the text after a body is read as commands)."""
       segs, hdt = [], []

       def bq(s, i, indq):  # `...` from index i: read as a text of its own, as bash does
           out, j, n = [], i + 1, len(s)
           while True:
               m = _BQRUN.match(s, j)
               if m:
                   out.append(m.group())
                   j = m.end()
               if j >= n or (s[j] == "\\" and j + 1 >= n):
                   raise _Open(i)
               if s[j] == "`":
                   segs.extend(bash_argv("".join(out))[0])
                   return j + 1
               c = s[j + 1]
               out.append(c if c in "$`\\" or (indq and c == '"') else "\\" + c)
               j += 2

       def dq(s, i):  # "..." from index i; returns (index after the closing quote, value)
           out, j, n = [], i + 1, len(s)
           while True:
               m = _DQRUN.match(s, j)
               if m:
                   out.append(m.group())
                   j = m.end()
               if j >= n:
                   raise _Open(i)
               c = s[j]
               if c == '"':
                   return j + 1, "".join(out)
               if c == "`":
                   j = bq(s, j, True)
               elif s.startswith("$(", j):
                   j = cmds(s, j + 2, True)
               elif c == "$":
                   out.append(c)
                   j += 1
               elif j + 1 >= n:
                   raise _Open(i)
               else:
                   c = s[j + 1]
                   if c != "\n":
                       out.append(c if c in '\\"$`' else "\\" + c)
                   j += 2

       def hd(b):  # the body of a heredoc whose delimiter has no quote: its substitutions run, quotes are characters
           out, j, n = [], 0, len(b)
           try:
               while j < n:
                   m = _HDRUN.match(b, j)
                   if m:
                       out.append(m.group())
                       j = m.end()
                   elif b[j] == "`":
                       j = bq(b, j, False)
                   elif b.startswith("$(", j):
                       j = cmds(b, j + 2, True)
                   elif b[j] == "$" or j + 1 >= n or b[j + 1] not in "\\$`":
                       out.append(b[j])
                       j += 1
                   else:
                       out.append(b[j + 1])
                       j += 2
           except _Open as e:
               out.append(b[e.args[0]:])
           return "".join(out)

       def bodies(s, i, pend):  # the heredoc bodies that start at index i, in order; returns the index after them
           n = len(s)
           for d, quoted, strip in pend:
               lines = []
               while i < n:
                   e = s.find("\n", i)
                   e = n if e < 0 else e
                   line, more = s[i:e], []
                   while not quoted and e < n and (len(line) - len(line.rstrip("\\"))) % 2:  # a backslash-newline
                       more.append(line[:-1])
                       i = e + 1
                       e = s.find("\n", i)
                       e = n if e < 0 else e
                       line = s[i:e]
                   line = "".join(more) + line
                   i = e + 1
                   if strip:
                       line = line.lstrip("\t")
                   if line == d:
                       break
                   lines.append(line + "\n")
               i = min(i, n)
               more, t = bash_argv("".join(lines) if quoted else hd("".join(lines)))
               segs.extend(more)
               if t:  # R-W3: the tail of this body only; the text after the body is read as commands
                   hdt.append(t)
           return i

       def cmds(s, i, sub):  # a command list from index i, up to the `)` that closes `$(` when `sub` is true
           n, toks, parts, pend = len(s), [], [], []
           skip, nest, wbeg = False, 0, i

           def flush(cut=False, op=False):
               nonlocal skip
               if parts:
                   w, q = "".join(v for _, v in parts), any(f for f, _ in parts)
                   del parts[:]
                   if q and _CODE.search(w):
                       segs.extend(bash_argv(w)[0])
                   if skip:
                       if skip is not True:
                           pend.append(delim(s[wbeg:i]) + (skip == "<<-",))
                   elif (op or not w) and not q and not w.strip("0123456789"):
                       pass  # a file descriptor before `>`, or an unquoted word of substitutions only
                   elif q or toks or w not in ("{", "}"):
                       toks.append(w)
                   skip = False
               if cut:
                   skip = False
                   segs.append(toks[:])
                   del toks[:]

           try:
               while i < n:
                   if not parts:
                       wbeg = i
                   m = _RUN.match(s, i)
                   if m:
                       parts.append((False, m.group()))
                       i = m.end()
                       continue
                   c = s[i]
                   if c in " \t":
                       flush()
                       i += 1
                   elif c == "\n":
                       flush(True)
                       i += 1
                       if pend:
                           i = bodies(s, i, pend)
                           del pend[:]
                   elif c in "<>" or s.startswith("&>", i):
                       v = _OP.match(s, i).group()
                       flush(op=True)
                       i += len(v)
                       skip = not v.endswith("-")
                       if v == "<<":
                           skip = "<<-" if s.startswith("-", i) else "<<"
                           i += skip == "<<-"
                   elif c in ";&|()":
                       flush(True)
                       i += 1
                       if c == "(":
                           nest += 1
                       elif c == ")" and sub and not nest:
                           return i
                       elif c == ")":
                           nest -= nest > 0
                   elif c == "'":
                       j = s.find("'", i + 1)
                       if j < 0:
                           raise _Open(i)
                       parts.append((True, s[i + 1:j]))
                       i = j + 1
                   elif c == '"':
                       i, v = dq(s, i)
                       parts.append((True, v))
                   elif c == "`":
                       i = bq(s, i, False)
                       parts.append((False, ""))
                   elif s.startswith("$(", i):
                       i = cmds(s, i + 2, True)
                       parts.append((False, ""))
                   elif s.startswith("$'", i):
                       m = _ANSI.match(s, i)
                       if not m:
                           raise _Open(i + 1)
                       parts.append((True, _ESC.sub(r"\1", m.group(1))))
                       i = m.end()
                   elif c == "$":
                       if not s.startswith('$"', i):
                           parts.append((False, c))
                       i += 1
                   elif c == "#" and not parts:
                       j = s.find("\n", i)
                       i = n if j < 0 else j
                   elif c == "#":
                       parts.append((False, c))
                       i += 1
                   else:  # a backslash: escapes the next character; a backslash-newline, or one at the end, vanishes
                       if i + 1 < n and s[i + 1] != "\n":
                           parts.append((True, s[i + 1]))
                       i += 2
           except _Open:
               flush(True)
               raise
           flush(True)
           return n

       try:
           cmds(text, 0, False)
       except _Open as e:
           hdt.insert(0, text[e.args[0]:])
       return segs, "\n".join(hdt)
   ```
5. **Line 262, replace** `        more, rest = bash_argv(text)` with four lines (8, 12, 8 and 12 spaces of indentation in the file). Line 261 `    if _MARKS.search(text):` stays above; line 263 `        segs += more` stays below.
   ```text
           try:
               more, rest = bash_argv(text)
           except RecursionError:
               deny(DEEP_DENY)  # R-W6: a crash is no decision
   ```
6. **After line 277, insert 29 lines.** Line 275 is `    return k < n and toks[k].casefold() not in ("show", "get-url")` (the end of `remote_writes`), lines 276–277 are blank, line 278 `def git_text(*args):` stays below. The block is `def git_split` (no indentation) and ends with two blank lines.
   ```text
   def git_split(v):
       """R-A1: the argv git builds from an alias value (split_cmdline in alias.c; measured with git 2.54): a run of
       space, tab, newline or carriage return ends an argument (leading or trailing, it gives an empty one); a quote pairs
       with the next one of its kind and is removed; a backslash outside single quotes escapes the next character. None
       for a quote that is never closed or a backslash at the end, which git refuses."""
       out, cur, q, i, n = [], [], "", 0, len(v)
       while i < n:
           c = v[i]
           if not q and c in " \t\n\r":
               out.append("".join(cur))
               cur = []
               while i < n and v[i] in " \t\n\r":
                   i += 1
               continue
           if not q and c in "'\"":
               q = c
           elif c == q:
               q = ""
           elif c == "\\" and q != "'":
               if i + 1 >= n:
                   return None
               i += 1
               cur.append(v[i])
           else:
               cur.append(c)
           i += 1
       return None if q else out + ["".join(cur)]


   ```
7. **Lines 336–343, replace** these eight lines in `alias_check` (from `        amap, last = {}, None` to `                last[-1] += "\n" + line  # a value with a newline goes on over the next line`) with five lines (8, 8, 12, 12 and 16 spaces of indentation in the file). Line 335 `    if not _aliases:` stays above; line 344 `        _aliases.extend([amap, set()])` stays below.
   ```text
           amap = {}
           for item in git_unset("config", "-z", "--get-regexp", "^alias\\.").split("\0"):  # R-A2: key, newline, value
               key, _, val = item.partition("\n")
               if key.casefold().startswith("alias."):
                   amap.setdefault(key[len("alias."):].casefold(), []).append(val)
   ```
8. **After line 368, insert 12 lines (16 spaces of indentation on the first).** Line 368 is `                    nxt.update(st[k:k + 1])` (the last line of the T047 per-segment loop); line 369 `        frontier = nxt` stays below. The block sits in the `for v in amap[a]:` loop, after the T047 lines, which stay.
   ```text
                   gv = git_split(v)  # R-A1: the argv git builds from the value
                   if gv is None:
                       deny(PUSH_DENY)  # git refuses the alias; fail closed
                   gt, k = [t.casefold() for t in gv], lead(gv)
                   if {"push", "send-pack", "http-push"} & set(gt) or any(
                           (gv[x] in ("-c", "--config-env") and x + 1 < len(gt) and gt[x + 1].startswith(CONFIG_KEYS))
                           or (gt[x].startswith("--config-env=") and gt[x][13:].startswith(CONFIG_KEYS))
                           for x in range(min(k, len(gt)))):
                       deny(PUSH_DENY)  # R-A3: R-P5 for the global options at the head of the value
                   if "update-ref" in gt or (gt[k:k + 1] == ["remote"] and remote_writes(gt, k + 1, len(gt))):
                       deny(REF_DENY)
                   nxt.update(gt[k:k + 1])
   ```

Expected diff of `scripts/bash_gate.py` against the base (git's default diff): 7 hunks, 74 lines removed and 296 added; without blank lines `grep -c '^-[^-]'` counts 72 and `grep -c '^+[^+]'` counts 281. The file has 699 lines after the edits. `git diff origin/main -- scripts/common.py` is empty. `words` (lines 241–267 but for anchor 5), the legacy loop in it, `_MARKS`, `_SPLIT`, `_DQ`, `_CODE`, `gitword`, `lead`, `remote_writes` and the T047 lines of `alias_check` do not change. Applied bottom-up to the base, the eight blocks give the card writer's prototype byte for byte (checked by a script that reads this card).

**Test file anchor, `tests/argv_gate_tests.sh` line 148** (the same base commit; the file has 199 lines and sha256 `2c17c165626a794bd7ec46255d7527525231089343989733e3df2401dc5fe673`). Line 148 is T047 case 85:
```text
deny "85 heredoc quote, then gi backslash-newline t" "$W" "cat <<'EOF'${NL}don't${NL}EOF${NL}gi\\${NL}t -c \"user.name=A B\" $U x y" "$QUOTE_DENY"
```
Replace its last argument `"$QUOTE_DENY"` with `"$REF_DENY"`, so the line becomes:
```text
deny "85 heredoc quote, then gi backslash-newline t" "$W" "cat <<'EOF'${NL}don't${NL}EOF${NL}gi\\${NL}t -c \"user.name=A B\" $U x y" "$REF_DENY"
```
Nothing else in the file changes. Expected diff: 1 hunk, 1 line removed and 1 added. This is the one existing test line this card changes (D4; K310, the user's choice).

## Rules (allowlist, fail closed)
- **R-W0, scope:** every rule sits behind `card_path(cwd)`: a session with no `.delix/card` is unchanged (cases 62 to 64). `bash_argv` has one caller, `words` (anchor 5); the union of T047 R-W1 does not change: `words` keeps the loose scan and appends `bash_argv`'s segments when `_MARKS` matches, and a deny in either view wins.
- **R-W1 (T048), one pass:** `bash_argv(text)` replaces T047's tokenizer (`_TOK`, `_CMEND`, the `depth` and `cm` arguments) with one left-to-right pass that keeps the contexts bash keeps: a command list (`cmds`), double quotes (`dq`), backticks (`bq`) and heredoc bodies (`bodies`, `hd`). Everything T047 R-W1 says about words still holds: a quote pairs with the next one of its kind; in double quotes a backslash escapes only `\` `"` `$` a backtick and a newline; outside quotes a backslash escapes the next character, a backslash-newline vanishes, a lone backslash at the end is dropped; `,` `[` `]` and a glued `{` `}` are word characters; an unquoted `<` or `>` starts a redirection, and the operator, a file descriptor number glued before it and the target word are no arguments. New: a `$` followed by neither `(` nor `'` nor `"` is a character, and `$"..."` is a double-quoted string.
- **R-W7, substitutions:** `$(...)` and `` `...` `` are read wherever they stand: unquoted, in double quotes, in an assignment value, in a redirection or here-string target, and in the body of a heredoc whose delimiter has no quote. The commands inside are segments of their own. The output counts as no text: `"$(true)"git` and `git"$(true)"` are the word `git`, and a word made only of unquoted substitutions is no argument (it can expand to no word), so in `$(true) git …` the command is `git`. `$(` ends at the `)` that closes it outside quotes and comments, counting `(` `)` pairs; a backtick string ends at the first backtick no backslash escapes, and its text is read on its own with `\$`, `` \` ``, `\\` (and `\"` in double quotes) unescaped, as bash does.
- **R-W8, comments:** an unquoted `#` starts a comment only where no part of a word has been read (at the start, after a blank, a separator or a newline); inside a word (`` `true`# ``, `$(true)#`, `a'b'#c`) it is a character. A comment ends at the next newline. This replaces T047's comment rule with its re-read (F7 to F9).
- **R-H1, heredocs:** `<<` and `<<-` take the next word as the delimiter (`delim`: quotes and backslashes removed, nothing expanded; a quoted part anywhere makes the body literal). The bodies start after the next newline, in the order of their operators, and each ends at the first line equal to its delimiter (`<<-` strips leading tabs from each line first); with no quote in the delimiter a backslash-newline joins body lines first, `$(...)` and backticks in the body run (`hd`), and quotes are plain characters. A body with no delimiter line runs to the end of the text. The pass goes on after the delimiter line.
- **R-W2, nested text:** T047's rule, now also for every heredoc body: a quoted token that holds a blank, a separator, a quote or a backslash is read again by `bash_argv`, and so is every heredoc body (it is often fed to `bash` or `sh`). Each text read again is shorter than its source, so the recursion ends.
- **R-W3, a quote that is never closed:** the pass stops at a quote, a `$'` or a backtick that is never closed and returns the text from it as the tail. Each heredoc body that has such a tail adds that body's tail only, joined with a newline; the text after a body is read as commands, not added to the tail (D4). `words(cmd, True)` denies with `QUOTE_DENY` when a word of the tail names git, as in T047.
- **R-W6, too deep:** a `RecursionError` from `bash_argv` (nesting deeper than Python's recursion limit: the card writer measured 496 levels of `"$(` as the deepest that passes on Python 3.9.6, 497 on 3.13.13) denies with `DEEP_DENY`; the hook does not crash. 100 levels pass (case 37).
- **R-W9, brace groups:** an unquoted `{` or `}` that is a whole word at the start of a command is a reserved word, no argument, so `{ git push origin HEAD; }` and a function body `f() { …; }` read as the command inside (cases 30 to 35). A `{` or `}` glued to other characters stays a word character (T047 F5).
- **R-W10, `$'...'`:** a backslash escapes the next character, so `$'\''` is one quote and does not open a string. The value keeps `\\` `\'` `\"` `\?` as one character and every other escape as written (D6).
- **R-A1, an alias value as git splits it:** `git_split(v)` builds the argv git builds from an alias value (`split_cmdline` in git's `alias.c`, measured with git 2.54): a run of space, tab, newline or carriage return separates, a quote pairs with the next one of its kind and is removed, a backslash outside single quotes escapes the next character; `;` `&` `|` `#` are ordinary characters. The alias check reads that list in addition to T047's `words(v)` segments (R-P4, R-W5 unchanged): a `push`, `send-pack` or `http-push` token denies with `PUSH_DENY`; `update-ref` anywhere, or `remote` at `lead` with `remote_writes`, denies with `REF_DENY`; the token at `lead` joins the chain. A value git refuses (a quote never closed, a backslash at the end) denies with `PUSH_DENY`.
- **R-A2, the alias list:** read with `git config -z --get-regexp '^alias\.'`: a NUL ends an entry and its first newline ends the key, so a value with a newline whose next line starts with `alias.` is one value, not a second key (T047 read the output line by line).
- **R-A3, config keys in an alias value:** among the global options at the head of the list (before `lead`), `-c` or `--config-env` followed by a key that starts with one of `CONFIG_KEYS` (`alias.`, `remote.`, `push.`, `url.`, `include`, `help.`, casefolded), or `--config-env=<such a key>`, denies with `PUSH_DENY`, as R-P5 does on the command line: such a value defines the alias or the remote its own command uses.
- **Messages (exact):**
  - `DEEP_DENY` = `delixcrew: the command nests quotes or substitutions deeper than this hook reads; split it or put the text in a file, then run the command again`
  - `PUSH_DENY`, `REF_DENY`, `QUOTE_DENY`, `ENC_DENY` and the R-U4 message do not change.
- **Regex discipline:** eight new patterns (anchor 2), none built from user input. `_RUN`, `_DQRUN`, `_HDRUN` and `_BQRUN` are one negated character class under `+`; `_OP` is T047's `op` group as a pattern of its own; `_ESC` is a backslash and a class. `_ANSI` and `_QR` have one starred group with two branches that start with different characters (`[^'\\]` or `\\.`, `[^"\\]` or `\\.`), the shape of T047's `dq` group; `_QR`'s three alternatives start with `\`, `'` and `"`. The pass calls `match` at a known index; `sub` runs only on a delimiter word and on a `$'...'` value. No pattern is used with `search` over the whole text.
- **Known false positives (fail closed):**
  - a quote that is never closed in a heredoc body, followed by a git command later in the same body, denies with `QUOTE_DENY` (D3, D4; T047 case 33; 1 of 3,000 sampled real commands); close the quote, or write the text to a file with the Write tool;
  - a quoted heredoc body is read as commands even when it is only written to a file (`cat > f <<'EOF'` with the words `git` and `push` on one line): the loose view denied it already (T047 Known false positives);
  - an alias value git refuses (case 43), and nesting deeper than about 500 levels (case 36).
  - No longer false positives: a brace group or a function body around an allowed command (cases 30 to 33; main denies 30 to 32), and `$'it\'s'` in front of a git command (case 55; main denies it with `QUOTE_DENY`).

## Decisions (card writer, 2026-11-13; the lead records the K-numbers in the spec)
- **D1, one pass instead of a fourth fix to the tokenizer.** T047's regex tokenizer reads a command as a flat stream of tokens and re-reads quoted text; each round of T047 patched one context (comments, backticks, re-reads) and each patch opened the next gap (K304: "Yorum işleme her turda yeni bir boşluk açtı"). Bash reads a command left to right and keeps a stack of contexts; the pass does the same, so the contexts nest by construction: a substitution inside double quotes inside a substitution is read as bash reads it, and a `#` is a comment only where bash would start one. Alternatives: a fifth patch of the comment rule (the round-4 Medium) leaves the glued-word and heredoc classes open; a full bash grammar (`case`, arithmetic, `coproc`) is a bash reimplementation (O3). The union with the loose view (T047 D1) stays, so everything the loose view denies still denies.
- **D2, a substitution's output counts as no text.** The command runs in bash and its output becomes part of the word, which the hook cannot know. Reading it as empty is what bash does when the command prints nothing (`true`), and it is the reading that makes `"$(true)"git` the word `git`. A command that prints a command name (`$(echo gi)t`) is the variable class and stays a Known limit (O2; the card writer measured that it writes a ref on main and on the prototype). An unquoted word of substitutions only is no argument, because bash drops an empty unquoted word; a quoted one (`"$(true)"`) stays an empty argument.
- **D3, every heredoc body is read as command text.** A body is often fed to a shell (`bash <<'EOF'`, T047 case 31). The pass reads an unquoted body with its substitutions run (`hd`) and a quoted body as it is, then reads both again as commands (R-W2). Reading only unquoted bodies would leave `bash <<'EOF'` to the loose view alone; reading neither is the round-4 state. The cost is the known false positive of a quoted body that only goes to a file, which the loose view had already.
- **D4, the tail of a heredoc body is that body's text only (B, K310).** The outer pass reads the text after a body as commands, so an apostrophe in a body does not make a git command after the body deny with `QUOTE_DENY`: that command is read exactly and denies with its own message. T047 cases 33 and 85 expect `QUOTE_DENY` for an apostrophe in a heredoc body followed by a git command. Case 33's git command is in the body (`bash <<'EOF'`), so it keeps `QUOTE_DENY`. Case 85's comes after the body (`cat <<'EOF'⏎don't⏎EOF⏎gi\⏎t -c "user.name=A B" update-ref x y`) and now denies with `REF_DENY`, as its comment twin case 84 does; its test line changes (the test file anchor), the one existing test line this card changes. Alternative A, the first body's tail plus all the text after the body, keeps every test line but on the card writer's sample of 3,000 real commands from this project's Claude Code transcripts (`corpus2.py` in `T048-proto/`) it gave 13 new denies (heredocs with an apostrophe in the body, often Turkish file writes and commit messages, and a git command later in the call) and kept the 23 that main denies; B gives 1 new deny (a git word later in the same body, D3) and passes the 23, none of which pushes, writes a ref or changes a remote (their git commands are `add`, `commit`, `log`, `diff`, `archive`, `status`, `fetch`, `merge-base`, `rev-list`, `pull --ff-only` and `remote -v`; `bcheck.py` reads each one's git argv from B's pass). Each body adds only its own tail, so the tail is never longer than the bodies (growth "quoted heredocs with a quote").
- **D5, `{` `}` are reserved only as a whole unquoted first word** (R-W9). That is where bash reads them as a group; a glued `{x` or `x}` stays a word character, which T047 F5 needs (`git -c x.y={b push origin HEAD:main`). This removes the false positive K304 names without touching brace expansion (D9).
- **D6, `$'...'`: pairing only.** Bash 3.2.57 reads `$'\''` as one quote; T047 treated the `'` after the backslash as a closing quote, so `echo $'\''; git -c 'user.name=A B' push origin HEAD:main` pushed `main` past the hook, and `echo $'it\'s'; git status` denied with `QUOTE_DENY`. The pass pairs the quote the way bash does. It does not expand `\x67`, `\147` or `\u0067`: `$'\x67it' -c 'user.name=A B' update-ref …` writes a ref on main and on the prototype (O2, ANSI-C quoting, already a Known limit).
- **D7, too deep denies with a message.** Main's flat tokenizer does not recurse per level (the card writer's 60,000-level `"$(` and `$(` nestings around a harmless command exit 0 and pass on main). The pass recurses once per level of `"$(`, `$(` or backticks, and Python stops it at about 500 levels with a `RecursionError`, which would crash the hook: `onFailure: block` would block the command with no message. R-W6 turns that into `DEEP_DENY`, which tells the user how to go on. Alternatives: raise the recursion limit (moves the limit, and the thread stack can overflow before it) or an explicit stack (more code than this card). No daily command nests 500 levels; it is a new false positive in the safe direction.
- **D8, the alias check reads both splits.** T047's per-segment reading of `words(v)` stays (its cases 38 to 49 in `tests/argv_gate_tests.sh` pass unchanged), and `git_split(v)` adds the list git really builds, so a `;` or a quoted blank in a value no longer moves the command token (cases 38 to 40). `git config -z` replaces the line-by-line read (R-A2): the T047 read took a value line that starts with `alias.` as a new key (case 40). R-A3 extends R-P5 to the head of a value, because `-c alias.b=push b origin HEAD:main` in a value defines the alias it runs (case 41). A value git refuses denies with the existing `PUSH_DENY` rather than a new message: git would not run it.
- **D9, brace expansion stays out (O1, K306).** `git {push,origin,HEAD:main}` pushes `main` and `git {update-ref,refs/heads/zz,HEAD}` writes the ref with real bash 3.2.57 and git 2.54; both pass main and the prototype. Expanding braces changes one word into several, a different change from reading contexts, with false positives of its own (`--format={a,b}` in a log command). It stays a Known limit with no narrow deny (K306, as K300 decided; T046's H3 already adds it).
- **D10, evidence: coverage fuzz and the differential test, not repo content.** The card writer ran the prototype (the eight blocks applied to the base; the counts below are B's, and A gave the same) against real bash with the lead's T047 round-4 scripts (`fuzz_bt.py`, `fuzz_argv.py`, unchanged) and two of its own (`fuzz_t048.py`, the coverage generator with heredocs, nested double quotes, `$'...'`, `$"..."`, brace groups and variables added; `fuzz_nest.py`, D9 with nesting):
  - bash 3.2.57 (Mac, Python 3.9.6): `fuzz_bt.py` 16,000 cases (4,000 each with seeds 13, 29, 61, 97), 0 misses and 0 glued-word misses (main, T047 Round 4: 3 misses, the round-4 Medium, and 15 glued-word misses on 16,000); `fuzz_t048.py` 16,000 cases (seeds 7, 11, 23, 41), 0 misses outside the variable class (12 misses, all in commands with `$x` or `${`, O2; main with seed 7: 227 misses and 39 of the variable class on 4,000); `fuzz_argv.py` and `fuzz_nest.py` 32,000 cases (8,000 each with seeds 31 and 47), 0 mismatches;
  - bash 5.2.21 (GTR9): `fuzz_bt.py` 8,000 cases (seeds 13, 29), 0 misses and 0 glued-word misses; `fuzz_t048.py` 8,000 cases (seeds 7, 11), 0 misses outside the variable class (7); `fuzz_argv.py` and `fuzz_nest.py` 16,000 cases (seed 31), 0 mismatches (Python 3.12.3 there);
  - probes with the real hook, then bash 3.2.57 and git 2.54 in a throwaway card repository with a local bare `origin` (`t048_probe.sh` and the lead's four round-4 probe scripts): 25 forms pass main and push `main` (10), write a ref (11) or change the URL of `origin` (4); the prototype denies all 25. `"$x"git …` (variables) passes both and writes the ref (O2). The everyday forms (a heredoc commit message with an apostrophe, a push of the own branch after a heredoc file write or with `2>&1 | tail`, `commit -m "it's"`, `{ git status; }`, `( git status )`) pass both; `{ git push origin HEAD; }` and `f() { git push origin HEAD; }; f` deny on main and pass on the prototype;
  - the scripts are in the shared notes folder of the card-writing session (`T048-proto/`), not in the repo; the lead runs them again on the PR head (K307).
- **D11, a new test file and the T047 growth sizes.** `tests/parse_gate_tests.sh` is a new file; of the existing test files only line 148 of `tests/argv_gate_tests.sh` changes (D4). The growth test runs 8 shapes at k = 5000 and k = 40000 (the least of 3 runs per size; t(40000) < 3 s, ratio < 20), as T047 D8.

## Lead decisions (all decided)
1. **The tail of a heredoc body (D4), decided (K310, the user in chat, 2026-11-13): B.** The tail of each body only; the text after a body is read as commands. It changes one existing test line, `tests/argv_gate_tests.sh` line 148 (the test file anchor), the only exception to "the existing tests are not changed" (Global Constraints). D4 keeps the A/B measurements as its reason; on B the D10 fuzz and probes give the same counts as on A.
2. **Brace expansion (D9, O1), decided (K306):** it stays a Known limit with no narrow deny, as K300 decided.
3. **Acceptance fuzz, decided (K307):** the lead runs the four scripts of D10 on the PR head, as in T047 round 4; no seeded fuzz test goes into the repo.
4. **Wave and order, decided (K308, K309):** wave 18 (K308); the order is this card, then T046, then the 🔐 release card T042 (K309), so T046 takes H0's branch "T048 is merged first".

## Out of scope (each with the reason; T046 keeps the matching Known limits sentences)
- **O1, brace expansion:** D9 and K306.
- **O2, variables, globs, `eval`, ANSI-C escapes and command output:** `"$x"git`, `$'\x67it'` and `$(echo gi)t` write a ref on main and on the prototype (measured by the card writer). They are the Known limit "variables, `eval`, globs and ANSI-C quoting"; H2 below gives T046 the words for the ANSI-C escapes and the substitution output.
- **O3, bash grammar the pass does not model:** `case` patterns inside `$(...)` (a `)` of a pattern ends the substitution in the hook's view; the text after it is still read as commands, and the card writer's probes with `case` deny on main and on the prototype), arithmetic `$((…))` (its `$(` is read as a substitution), process substitution `<(…)` (read as a redirection and a subshell), `coproc`, bash aliases and functions defined in the same command (a function body is read, its call by name is not followed). zsh is not modelled (T047 O5).
- **O4, the other items of T044 and T047 Out of scope:** unchanged (the push line as a whole allowlist, the `gh` alias for `pr merge`, `git symbolic-ref`, `git fast-import`, `git fetch` into `refs/remotes/`, `git branch -f`).

## Interfaces
- Consumed: `GIT_ARG_OPTS`, `CONFIG_KEYS`, `PUSH_DENY`, `REF_DENY`, `QUOTE_DENY`, `deny`, `lead`, `gitword`, `remote_writes(toks, k, n)`, `git_unset`, `_aliases`, `_MARKS`, `_SPLIT`, `_DQ`, `_CODE`, the loose loop of `words`.
- Produced: `DEEP_DENY`; the patterns `_RUN`, `_DQRUN`, `_HDRUN`, `_BQRUN`, `_OP`, `_ANSI`, `_ESC`, `_QR`; `class _Open(Exception)`; `delim(raw)` returning `(text, quoted)`; `bash_argv(text)` returning `(segments, tail)`, the same shape as T047's; `git_split(v)` returning a list or `None`.
- Removed: `_TOK`, `_CMEND`, the `depth` and `cm` arguments of `bash_argv` (only `bash_argv` used them).

## Global Constraints (verbatim)
- K304: "Yorum işleme her turda yeni bir boşluk açtı. T048 bunu tek tasarımda, kapsama fuzz'unu kabul testi yaparak çözer."
- K305: "Tur 4'ün Medium'u (K304) ve O2 sınıfı T048'e gider. T048 sürümden önce gelir (K301) ve kabul testi kapsama fuzz'udur."
- K302: "alias değerini git'in `split_cmdline`'ı gibi bölmek (`;` ve tırnaklı boşluk; önceden kurulmuş alias ister, R-P5 alias yazmayı reddeder), alias'ı `git config -z` ile okumak (iki satırlık değer) ve çift tırnak içindeki `$(...)` (K301)."
- Repo hook rules: no new regex with overlapping alternation; a growth test at two sizes; the test driver lives in the test file with the trigger words assembled at run time; the existing tests are not changed.
- The only exception to the line above (K310, the user's yes in chat on 2026-11-13): line 148 of `tests/argv_gate_tests.sh` changes its expected message (the test file anchor); no other existing test line changes.
- Python 3.9 stdlib; no version-dependent behaviour (the Mac runs 3.9.6, CI 3.12; run the new file on 3.13 as well). ASCII only in the code and the test; no invisible character; the check marks in the test are octal escapes in bash and `chr(0x2714)` / `chr(0x2718)` in Python.

## Steps
1. Write `tests/parse_gate_tests.sh` (cases below) and change line 148 of `tests/argv_gate_tests.sh` per the test file anchor. Run `bash tests/argv_gate_tests.sh` and see **red**: 1 `✘` line (case 85: main denies it with `QUOTE_DENY`), 109 `✔` lines, `FAILED`, exit 1. Run `bash tests/parse_gate_tests.sh` and see **red**: 37 `✘` lines, 35 `✔` lines (the 8 growth lines and the cases 14, 20, 26, 33 to 35, 37, 44 to 54 and 56 to 64, which main already gets right), `FAILED`, exit 1 (the card writer's prototype of the test on the base; a different count means a case differs from the list, so say so in the report).
2. Edit `scripts/bash_gate.py` bottom-up per Edit anchors 8 to 1; run the `ast.parse` one-liner after each.
3. Run `bash tests/parse_gate_tests.sh` and see **green**: 72 `✔` lines (64 cases and 8 growth lines), `ALL PASSED`; `bash tests/argv_gate_tests.sh`: 110 `✔` lines, `ALL PASSED`. Run it again on Python 3.13 through a PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 3 paths by name. Commit `T048: bash_gate reads a command in one pass the way bash reads it (T047 round 4)`. No command of yours, and no commit message, holds `git` followed by `push`, `update-ref` or `remote` as words on one line, except the one push below. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd`. Open a PR with `--body-file` and a `## How I tested` section.
6. After step 2 your own session may run the edited hook (if the plugin loads from this worktree). It denies a quote that is never closed in a heredoc body when a git command follows later in the same body, and nesting about 500 levels deep: write the PR body and the report to a file with the Write tool, and keep apostrophes out of heredocs in Bash text that also holds a git command. Keep to commands the rules allow: no `git remote` form beyond the read forms, no `update-ref`.

## Tests (`tests/parse_gate_tests.sh`, a new file; `ALL PASSED` at the end)
- **Words:** `G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"; UR=set; UR="${UR}-url"`, `NL=$'\n'`, `TAB=$'\t'`, `OK=$'\342\234\224'`, `NO=$'\342\234\230'`, `Q="-c 'user.name=A B'"`, `QQ="-c \"user.name=A B\""`. The file holds none of the trigger words as one literal. The four messages are built from them:
  ```text
  PUSH_DENY="delixcrew: an implementer session pushes only its own card branch ($G $P [-u] origin <branch>); the default branch and every other $P run from the user's own terminal"
  REF_DENY="delixcrew: an implementer session does not write $G refs or change ${R}s ($U, $R set-head, $UR, add, remove); those run from the user's own terminal"
  QUOTE_DENY="delixcrew: a quote that is never closed stands in front of a $G command, which this hook cannot read; close the quote or put the text in a file, then run the command again"
  DEEP_DENY="delixcrew: the command nests quotes or substitutions deeper than this hook reads; split it or put the text in a file, then run the command again"
  ```
- **Input and helpers:** as in `tests/argv_gate_tests.sh`: the hook input is built with Python `json.dumps` and piped to `python3 "$S/bash_gate.py"`; `allow` = exit code 0 and no `"permissionDecision": "deny"`; `deny` = exit code 0, that string, and `grep -qF` of the message. A hook that raises exits 1, so a crash is red for both helpers. Each case prints `$OK <label>` or `$NO <label> …`.
- **Setup** (no network, no push, direct calls not through the hook): `W` is a repo on `claude/t1` with one empty commit, `.delix/card` = `docs/delix/tasks/T048-x.md`, `.delix/` in `.git/info/exclude`, `docs/delix/delix.json` = `{"default_branch":"main"}`, `remote add origin "$W.$G"` (never contacted), `refs/remotes/origin/main` made by an update-ref call in the setup and `symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main`. `L` is a repo on `claude/t1` with no card. Commits in the setup use `-c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null`. `DEEP` and `NEST` are built with Python: `"echo " + "\"$(" * k + "$G status" + ")\"" * k` with k = 3000 and k = 100.
- **Cases** (number, label as printed, the command as a bash string with its variables, the expected result; cwd `W` except cases 62 to 64). `\$` and `` \` `` are a literal `$` and backtick in the bash string; `\\` is one backslash.
  - *R-W8, a `#` glued to a substitution is part of the word (T047 round 4)*
    - 1 backticks then #, then ref update: ``echo \`true\`# \`# it's\`; $G $Q $U x y`` → `REF_DENY`
    - 2 backticks then #, then send to main: ``echo \`true\`# \`# it's\`; $G $Q $P origin HEAD:main`` → `PUSH_DENY`
    - 3 substitution then #, then ref update: ``echo \$(true)# \`# it's\`; $G $Q $U x y`` → `REF_DENY`
    - 4 substitution then #, then $R url: ``echo \$(true)# \`# it's\`; $G $Q $R $UR origin /tmp/x`` → `REF_DENY`
    - 5 dq: # it's, backticks #z then #, ref update: ``echo \"# it's \`#z\`# \`$G $Q $U x y\` \"`` → `REF_DENY`
    - 6 dq: backtick quote mix, then send to main: ``echo \"\`\"'\`'; \\\` # a \`b\` c \"; $G $Q $P origin HEAD:main`` → `PUSH_DENY`
    - 7 dq: # it's then substitution, ref update: `echo \"# it's \$($G $Q $U x y)\"` → `REF_DENY`
  - *R-W7, the output of a substitution counts as no text*
    - 8 quoted substitution glued, send to main: `\"\$(true)\"$G $Q $P origin HEAD:main` → `PUSH_DENY`
    - 9 quoted substitution glued, ref update: `\"\$(true)\"$G $Q $U x y` → `REF_DENY`
    - 10 quoted backticks glued, send to main: ``\"\`true\`\"$G $Q $P origin HEAD:main`` → `PUSH_DENY`
    - 11 quoted backticks glued, ref update: ``\"\`true\`\"$G $Q $U x y`` → `REF_DENY`
    - 12 quoted substitution glued, $R url: `\"\$(true)\"$G $Q $R $UR origin /tmp/x` → `REF_DENY`
    - 13 substitution glued after the word: `$G\"\$(true)\" $Q $U x y` → `REF_DENY`
    - 14 unquoted substitution glued, send to main: `\$(true)$G $Q $P origin HEAD:main` → `PUSH_DENY`
  - *R-W7, R-H1, an apostrophe in double quotes or in a heredoc body, then a substitution or a command*
    - 15 dq: it's then substitution, ref update: `echo \"it's \$($G $Q $U x y)\"` → `REF_DENY`
    - 16 dq: it's then backticks, send to main: ``echo \"it's \`$G $Q $P origin HEAD:main\`\"`` → `PUSH_DENY`
    - 17 assignment: it's then substitution, url: `X=\"it's \$($G $Q $R $UR origin /tmp/x)\"` → `REF_DENY`
    - 18 heredoc: # it's then substitution: `cat <<EOF${NL}# it's \$($G $Q $U x y)${NL}EOF` → `REF_DENY`
    - 19 heredoc: it's then backticks, send: ``cat <<EOF${NL}it's \`$G $Q $P origin HEAD:main\`${NL}EOF`` → `PUSH_DENY`
    - 20 heredoc: backslash-newline joins the lines: `cat <<EOF${NL}a \\${NL}\$($G $Q $U x y)${NL}EOF` → `REF_DENY`
    - 21 heredoc don't, then send to main: `cat <<EOF${NL}don't${NL}EOF${NL}$G $Q $P origin HEAD:main` → `PUSH_DENY`
    - 22 quoted heredoc don't, then ref update: `cat <<'EOF'${NL}don't${NL}EOF${NL}$G $Q $U x y` → `REF_DENY`
    - 23 heredoc <<- tab don't, then send: `cat <<-EOF${NL}${TAB}don't${NL}${TAB}EOF${NL}$G $Q $P origin HEAD:main` → `PUSH_DENY`
  - *R-W7, double quotes nested in a substitution in double quotes*
    - 24 assignment: nested dq, ref update: `X=\"\$($G $QQ $U x y)\"` → `REF_DENY`
    - 25 echo: nested dq, send to main: `echo \"\$($G $QQ $P origin HEAD:main)\"` → `PUSH_DENY`
    - 26 two deep: nested dq, $R url: `echo \"\$(echo \"\$($G $QQ $R $UR origin /tmp/x)\")\"` → `REF_DENY`
    - 27 a quoted blank, then nested dq, ref update: `echo \"\$(echo \"a b\") \$($G $QQ $U x y)\"` → `REF_DENY`
  - *R-W10, in `$'...'` a backslash escapes the quote*
    - 28 ansi-c quote, then send to main: `echo \$'\\''; $G $Q $P origin HEAD:main` → `PUSH_DENY`
    - 29 ansi-c quote, then ref update: `echo \$'\\''; $G $Q $U x y` → `REF_DENY`
  - *R-W9, `{` and `}` are reserved words at the start of a command*
    - 30 brace group, own branch send: `{ $G $P origin HEAD; }` → `allow`
    - 31 brace group, own branch send with -u: `{ $G $P -u origin claude/t1; }` → `allow`
    - 32 function body, own branch send: `f() { $G $P origin HEAD; }; f` → `allow`
    - 33 brace group, status, redirection: `{ $G status; } 2>&1` → `allow`
    - 34 brace group, send to main: `{ $G $P origin HEAD:main; }` → `PUSH_DENY`
    - 35 brace group, ref update: `{ $G $Q $U x y; }` → `REF_DENY`
  - *R-W6, nesting deeper than the hook reads*
    - 36 3000 nested substitutions in dq: `$DEEP` → `DEEP_DENY`
    - 37 100 nested substitutions in dq, status: `$NEST` → `allow`
- **Aliases** (written to `W`'s `.git/config` with `$G -C "$W" config alias.<name> "<value>"` before case 38, unset after case 47):
  - alias.sa = `-c x.y=a;b $R $UR origin /tmp/x`
  - alias.sb = `-c \"user.name=A B\" $R${NL}$UR origin /tmp/x`
  - alias.sc = `-c${NL}alias.zz $R $UR origin /tmp/x`
  - alias.sd = `-c alias.b=$P b origin HEAD:main`
  - alias.se = `-c core.pager=cat -c alias.q=$R q $UR origin /tmp/x`
  - alias.sq = `log \"x`
  - alias.oa = `-c \"user.name=A B\" log --oneline -1`
  - alias.ob = `-c x.y=a;b status`
  - alias.oc = `log --format=\"%h %s\" -1`
  - alias.od = `-c${NL}core.pager=cat log -1`
- **Cases 38 to 47** (aliases set; deny / allow):
  - 38 alias: -c value with ;, then $R url: `$G sa` → `REF_DENY`
  - 39 alias: quoted blank, $R newline $UR: `$G sb` → `REF_DENY`
  - 40 alias: -c newline, a line that looks a key: `$G sc` → `REF_DENY`
  - 41 alias: -c defines an alias, then send: `$G sd` → `PUSH_DENY`
  - 42 alias: second -c defines an alias: `$G se` → `PUSH_DENY`
  - 43 alias: a quote never closed: `$G sq` → `PUSH_DENY`
  - 44 alias: quoted blank, then log: `$G oa` → `allow`
  - 45 alias: -c value with ;, then status: `$G ob` → `allow`
  - 46 alias: log with a quoted format: `$G oc` → `allow`
  - 47 alias: -c newline value, then log: `$G od` → `allow`
- **Allow, everyday commands the one pass must keep passing (cases 48 to 61):**
  - 48 heredoc commit message with an apostrophe: `$G commit -q --allow-empty -F - <<'EOF'${NL}it's done${NL}EOF` → `allow`
  - 49 own branch send after a heredoc file write: `cat > /dev/null <<'EOF'${NL}note${NL}EOF${NL}$G $P origin HEAD` → `allow`
  - 50 commit -m it's in dq, then status: `$G commit -q --allow-empty -m \"it's\" && $G status -s` → `allow`
  - 51 own branch send, 2>&1 | tail: `$G $P origin HEAD 2>&1 | tail -1` → `allow`
  - 52 substitution in dq, rev-parse: `echo \"\$($G rev-parse HEAD)\"` → `allow`
  - 53 assignment from a substitution, status: `X=\"\$($G -C \"$W\" status -s)\"; echo \"\$X\"` → `allow`
  - 54 log with a quoted format: `$G log --format='%h %s' -1` → `allow`
  - 55 ansi-c it's, then status: `echo \$'it\\'s'; $G status` → `allow`
  - 56 test loop: `for t in tests/*_tests.sh; do bash \"\$t\" || exit 1; done` → `allow`
  - 57 heredoc with a substitution, log: `cat <<EOF${NL}\$($G log -1 --format=%s)${NL}EOF` → `allow`
  - 58 # glued to substitutions, then status: ``echo \`true\`#x \$(true)#y; $G status`` → `allow`
  - 59 gh pr create, it's in the title: `gh pr create --title \"T048: it's done\" --body-file /tmp/b.md` → `allow`
  - 60 quoted heredoc write, it's, a substitution: `cat > notes.md <<'EOF'${NL}it's \$(here)${NL}EOF` → `allow`
  - 61 diff against a merge-base substitution: `$G diff --stat \"\$($G merge-base HEAD origin/main)\"` → `allow`
- **Allow with no card (cwd `L`; cases 62 to 64):**
  - 62 no card: quoted substitution glued, send: `\"\$(true)\"$G $Q $P origin HEAD:main` → `allow`
  - 63 no card: brace group, send to main: `{ $G $P origin HEAD:main; }` → `allow`
  - 64 no card: 3000 nested substitutions: `$DEEP` → `allow`
- **Growth** (8 `✔` lines; for each input k = 5000 and k = 40000, the least of 3 runs per size; expect t(40000) < 3 s and t(40000) / t(5000) < 20; print both times and the ratio; the Python block prints the marks with `chr(0x2714)` and `chr(0x2718)`), with `g` = `$G`:
  - heredocs with a substitution: `("cat <<EOF\nit's $(echo x)\nEOF\n" * k) + g + " status"`
  - quoted heredocs with a quote: `("cat <<'EOF'\ndon't\nEOF\n" * k) + g + " status"`
  - continued heredoc lines: `"cat <<EOF\n" + ("a\\\n" * k) + "EOF\n" + g + " status"`
  - nested quotes in substitutions: `("echo \"$(echo \"a b\")\"; " * k) + g + " status"`
  - hash after a substitution: ``("echo `true`#x $(true)#y; " * k) + g + " status"``
  - ansi-c quotes: `("echo $'it\\'s'; " * k) + g + " status"`
  - brace groups: `("{ " + g + " status; }; ") * k`
  - heredoc delimiters: `("cat <<\"E F\"\nx\nE F\n" * k) + g + " status"`

## Verification command → expected output
- `bash tests/parse_gate_tests.sh` → last line `ALL PASSED` · `bash tests/parse_gate_tests.sh | grep -c '^✔'` → `72`
- `bash tests/parse_gate_tests.sh | grep growth` → 8 lines, each `ratio` below 20 and `t(40000)` below 3 s (card writer's prototype: Python 3.9.6 ratios 1.9 to 5.6, at most 1.3 s; Python 3.13.13 ratios 1.5 to 5.0, at most 0.9 s)
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/parse_gate_tests.sh | tail -1` → `ALL PASSED`
- `bash tests/argv_gate_tests.sh` → `ALL PASSED`, and `| grep -c '^✔'` → `110` (case 85 expects `REF_DENY`)
- `bash tests/push_gate_tests.sh`, `bash tests/ref_gate_tests.sh`, `bash tests/hook_tests.sh`, `bash tests/bash_gate_heredoc_tests.sh`, `bash tests/trust_tests.sh`, `bash tests/write_gate_case_tests.sh` → each `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `bash tests/site_tests.sh` → exit 0 (site files are untouched)
- `claude plugin validate .` → passes
- `git diff origin/main -- tests | grep -c '^-[^-]'` → `1` · `git diff origin/main -- tests/argv_gate_tests.sh | grep -c '^+[^+]'` → `1` (line 148)
- `git diff origin/main -- scripts/bash_gate.py | grep -c '^-[^-]'` → `72` · `git diff origin/main -- scripts/bash_gate.py | grep -c '^+[^+]'` → `281`
- `git diff origin/main -- scripts/common.py | wc -l` → `0`
- `git diff -U0 origin/main -- scripts/bash_gate.py | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and (len(l) > 121 or any(ord(c) > 126 for c in l))]"` → no output
- `python3 -c "open('tests/parse_gate_tests.sh', 'rb').read().decode('ascii')"` → exit 0 (the test file is ASCII)
- `git diff --stat origin/main` → exactly the 3 Files
- **Lead, on the PR head (not the implementer's; D10):** the four fuzz scripts of `T048-proto/` with the seeds of D10 → 0 misses outside the variable class, 0 mismatches; `t048_probe.sh` and the lead's round-4 probes → every form of D10 denies and the allow forms pass.

## Review Focus
- The union (T047 D1) stays: the loose loop in `words` is untouched; every rule reads both views; a deny in either wins. No existing message or rule order changes, and of the existing test lines only line 148 of `tests/argv_gate_tests.sh` changes (case 85 expects `REF_DENY`); `tests/argv_gate_tests.sh` (110 `✔`), `tests/push_gate_tests.sh`, `tests/ref_gate_tests.sh`, `tests/bash_gate_heredoc_tests.sh` and the other suites pass without other edits.
- The pass against real bash: the lead runs the D10 scripts on the PR head (K307), and security may run them too (`T048-proto/` in the card-writing session's notes) or try forms on the hook and on real bash 3.2.57 and git 2.54 over a `git archive` of the head. A form that passes is a Known limit or a follow-up card; it is not a reason to widen this card (O1 to O3 are the known ones).
- The tail of a heredoc body (D4): each body with an unclosed quote adds its own tail only, and the text after a body is read as commands; T047 case 33 keeps `QUOTE_DENY`, case 85 denies with `REF_DENY`.
- R-W7's empty output (D2) and R-W9's reserved words (D5): `"$(true)"git` is `git`, `"$(true)" git` keeps an empty first word, `{x` stays a word character.
- The alias check (D8): T047's `words(v)` lines stay, `git_split` adds a list, `PUSH_DENY` still wins over `REF_DENY`, the chain depth stays 10, and the alias list is read once per command (`-z`).
- Regex discipline: the card writer timed the 8 growth shapes (ratios 1.5 to 5.6, at most 1.3 s, on Python 3.9.6 and 3.13.13) and found no pattern used with `search` over the text.
- Daily commands still pass: cases 48 to 61, the 3,000 sampled real commands of D4 (1 new deny, a git word later in the same heredoc body; 23 commands that main denies pass here, none a push, a ref write or a remote change), and the card writer's probes of everyday implementer commands (a heredoc commit message with an apostrophe, a push of the own branch after a heredoc file write, `commit -m "it's"`, `2>&1 | tail`) on main and on the prototype with identical results.

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `README.md`, `README.tr.md`, `site/**`, every other existing test file and every existing test line except line 148 of `tests/argv_gate_tests.sh` (K310, the only exception).
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a regex, a dependency, an option or a rule beyond R-W1 to R-W10, R-H1 and R-A1 to R-A3 and the eight patterns of anchor 2. Do not model brace expansion, variables, globs, ANSI-C escapes, command output or the bash grammar of O3. If a case in Out of scope looks easy, write it in the report instead.
- No raw non-ASCII or invisible character in code or tests.
- Verification commands never put `git` followed by `update-ref`, `remote` or `push` as words in the command text, except the one push in Step 5.
- No ruleset, `.github/**` or settings change: those are the user's, from their own terminal (K279).

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`, `bash --version`;
- the eight growth lines;
- PR number and branch;
- assumptions;
- every pre-existing slow path or crash seen and not fixed.

Read only this card, spec K301 to K305 and the T047 card's Review findings.

## Docs handover (T046)
For T046. K298 moves the README and site sentences out of this card. Copy the words as given. On the site a backticked word is a `<code>` element, `<`, `>` and `&` are HTML-escaped, and the release label is T046's. Every sentence below describes what this card makes true; the lead checks them against the merged code before T046 is dispatched. T046 uses the same places as T047's H1 and H3 (README Bash paragraph, README Known limits, README.tr's twins, the site index bash_gate Implementer cell and the site usage Known limits).

**H0, order.** K305 says T046's H3 adds this card's forms as Known limits until this card is merged. If T046 runs first (T048 not merged): T046 does what K305 says and skips H1 to H3 below; a later docs pass (or the release card T042) applies them. If T048 is merged first: T046 does not add the forms this card closes (the round-4 `#` forms, a word glued to a quoted substitution, an apostrophe before a substitution, nested double quotes, `$'\''`, the alias forms), and applies H1 to H3. The lead confirms the merge before T046 applies them. K309 sets the order T048, T046, T042, so T046 takes this second branch.

**H1, the one-pass sentence** (README Bash paragraph, after T047's H1 sentence; the same words in the site index bash_gate Implementer cell):
- EN: `The bash view reads a command in one pass the way bash does: it follows command substitutions in double quotes, in heredoc bodies and glued to a word, takes a `#` as a comment only at the start of a word, ends a heredoc body at its delimiter, and reads `$'…'` and brace groups as bash does; an alias value is split the way git splits it. A command nested too deep for the hook to read is denied with a message (T048).`
- TR: `bash görünümü bir komutu bash gibi tek geçişte okur: komut ikamesini çift tırnak içinde, heredoc gövdesinde ve bir kelimeye bitişikken de izler, `#`'i yalnız kelime başında yorum sayar, heredoc gövdesini sınırlayıcısında bitirir, `$'…'`'yu ve süslü parantez gruplarını bash gibi okur; alias değeri git'in böldüğü gibi bölünür. Hook'un okuyamayacağı kadar derin iç içe bir komut mesajla reddedilir (T048).`

**H2, the push-rule out-of-reach list** (README Known limits "The implementer push rule (T041, K279) …", README.tr's twin, site usage EN and TR). The item that T047's H3 wrote as "variables, `eval`, globs, ANSI-C quoting and brace expansion (…)" becomes:
- EN: `variables, `eval`, globs, ANSI-C escapes such as `$'\x67it'`, a command whose output spells a word (`$(echo gi)t`), and brace expansion (`git {push,origin,HEAD:main}` runs as a push)`
- TR: `değişkenler, `eval`, glob'lar, `$'\x67it'` gibi ANSI-C kaçışları, çıktısı bir kelimeyi yazan komut (`$(echo gi)t`) ve süslü parantez genişletme (`git {push,origin,HEAD:main}` bir push olarak çalışır)`

**H3, the false-positive clause** (same places). The clause T047's H3 added ("a quote that is never closed in front of a `git` word (…)") becomes:
- EN: `a quote that is never closed in front of a `git` word, also in a heredoc body (close the quote or put the text in a file), and a command nested too deep for the hook to read`
- TR: `bir `git` kelimesinin önünde, heredoc gövdesinde de, hiç kapanmayan tırnak (tırnağı kapat ya da metni bir dosyaya yaz) ve hook'un okuyamayacağı kadar derin iç içe bir komut`
- If T046 had written the brace-group false positive (`{ git push origin HEAD; }` denies), it goes: this card makes it pass.

## Review findings (filled by the lead)
- Round 1 (PR #76, head `75b12de2c71608b4e7d6e9d4855f214ceb81b010`, 2026-11-13): qa `ACCEPT` (0 P0, 0 P1), security
  `🔐 HUMAN_APPROVAL` twice (run 1 was stopped by a model safeguard; one narrow retry on exceptions, running time and
  lead decision B gave 1 Low, 2 unsure notes and no FIX). Lead gates on the clean `git archive` of the head:
  `scripts/bash_gate.py` and `tests/argv_gate_tests.sh` equal the card's anchors applied to 7d868fa byte for byte;
  16 suites exit 0 on Python 3.9.6 and 3.13.13 (`parse_gate_tests.sh` 72 `✔`, `argv_gate_tests.sh` 110 `✔`); the new
  tests on the base give 37 `✘` / 35 `✔` and 1 `✘` / 109 `✔`; CI `check` and `test` green. K307 acceptance fuzz on
  the head against bash 3.2.57: `fuzz_bt` 16,000 cases and `fuzz_t048` 16,000 cases, 0 missed (12 variable-class
  misses, O2); `fuzz_argv` and `fuzz_nest` 32,000 cases, 0 mismatches; the T047 and T048 probes: 0 crashes, 5 forms
  pass with an effect, all Known limits (O1, O2). Lead checks: 30,000 random inputs raise no exception other than a deny; 8
  probes (a quote-hidden ref write or push in front of an unclosed construct, inside an unclosed brace group and
  600 levels deep) deny.
  - Low (security, no fix): a heredoc body that opens another heredoc is re-read once per level, up to about 330
    levels (then `DEEP_DENY`). Lead measurement above the cap: linear (×4 input gives ×4.1 time), about 24 µs per
    byte on Python 3.9.6 (192 KB in 4.7 s), so the 60 s hook timeout comes at about 2.5 MB (extrapolated, not
    measured); the hook then blocks (`hooks/hooks.json` `"onFailure": "block"`) with no message. A depth cap for
    body re-reads would remove it; not needed for this card.
  - Note (security unsure): a top-level `(( x << N ))` makes the pass read `N` as a heredoc delimiter, which bash
    does not do (O3). Lead probe with real bash and git on temp repos (no network): 37 forms (plain, quote-hidden,
    glued-quote, backslash and quoted-subcommand ref writes and pushes, open and closed fake bodies) after 6
    arithmetic shapes deny on the head and on 7d868fa; bash ran 36 of them (ref written or `main` pushed).
  - Note (security unsure): 8 repeat units of the lead's growth check had no character that starts the pass. Lead
    re-measured all 8 with a quote added (2,000 to 32,000 repeats, up to 192 KB): at most 0.11 s, ×4 ratio at most
    4.5.
  - Lead decision B (security Q3): only one shape loses a deny that 7d868fa gave: a heredoc body with a quote that
    is never closed, then, after the delimiter line, a git command in a Known-limit form (O1, O2); the same forms
    without the heredoc already pass on 7d868fa. This is the trade-off K310 accepted.
  - Evidence: `rev76/` files in the lead's scratchpad (not in the repo).
