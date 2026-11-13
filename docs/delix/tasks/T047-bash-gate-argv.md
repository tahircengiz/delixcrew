# T047 🔐 — bash_gate: `words()` reads a command the way bash builds its argv; an alias value that starts with a global option is followed to its command

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T047 | M | 3 | backend | 17 | open |

**🔐 Approved:** 2026-11-13 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`; `scripts/common.py` `matches` returns that entry for it). `tests/argv_gate_tests.sh` matches `test_paths` (`tests/**`) and no protected entry, and it is a new file.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-13 ("Evet, T047'yi onaylıyorum", said in the lead session). The lead commits it to main before dispatch; the session branches from that commit.
> - The session is interactive and the user opens it, as for T041 and T044.
> - It closes the two findings of T044 round 1 that both hold on main for the T041 push rule (`docs/delix/tasks/T044-bash-gate-ref-writes.md`, Review findings): the Medium (`words()` does not build bash's argv) and the Low (an alias value that starts with a global option), and the security note on `git fast-import` (docs only, see Docs handover). The card writer's differential test against real bash found more of the Medium's class (redirections, an `sh -c` string, a quote that is never closed); they are in scope because the same function is wrong (D3).
> - It is defence in depth, not a boundary: the rules are a check on the command's words (see Out of scope).

**Goal (1 sentence):** In an implementer worktree `bash_gate.py` reads a command the way bash builds its argv, in addition to the loose word scan it has today, so that an option value with `,` `[` `]`, a quoted blank, a backslash-newline, a redirection and the text of an `sh -c` string no longer hide the subcommand from the push rule (R-P2, R-P3) and the ref and remote rules (R-U1, R-U2); a quote that is never closed in front of a `git` word denies with a message; and the alias check (R-P4, R-U3) follows an alias value that starts with global options to its command. · **Spec:** `docs/delix/specs/C-board-visibility.md` §6 (lines 187–214), K279, K283, K296, K299; T044 Review findings Round 1 (`docs/delix/tasks/T044-bash-gate-ref-writes.md` lines 272–285); T041 card R-P1 to R-P6

**Docs/site:** none in this card, the same exception as T044 (K298): T046 writes the README, README.tr and site sentences from the `## Docs handover (T046)` section at the end of this card. Do not touch `README.md`, `README.tr.md` or `site/**`. Order: the plan lists T046 as wave 16 and this card as wave 17; the section's H0 says what T046 does in each order, and the lead picks one before dispatch.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (seven edits, see Edit anchors)
- Create: `tests/argv_gate_tests.sh`

## Edit anchors (base origin/main 906eb3d, full SHA 906eb3d813fb6da91c8227db46e6b17d8d846278)
Line numbers are from that commit. Match the quoted content before you edit each place. If it differs, stop with `NEEDS_CONTEXT`. Edit bottom-up (anchor 7 first, anchor 1 last) so the line numbers above you hold. Every new line is at most 120 characters. After each edit run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output: if this repo's plugin loads from your worktree, a syntax error would block your own Bash.

Python is indentation-sensitive. The code blocks below sit inside list items, so every code line carries exactly 3 extra leading spaces that belong to the list: remove those 3 and keep the rest (a blank line in a block is empty). Anchors 4, 5 and 6 say how deep the lines sit in the file.

1. **After line 136, insert two lines (no indentation on the first).** Line 136 is `            "the command is denied until the user removes it from their own terminal")` (the end of `ENC_DENY`); line 137 `GIT_ARG_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--attr-source",` stays below.
   ```text
   QUOTE_DENY = ("delixcrew: a quote that is never closed stands in front of a git command, which this hook cannot read; "
                 "close the quote or put the text in a file, then run the command again")
   ```
2. **Line 150, replace.** `def words(text):` becomes the block below. Lines 148–149 (blank) stay above it; the block ends with the new `def words` line, and line 151 (`    """R-P1: one token list per segment. Quotes and backslashes removed; a redirection token is dropped, and when it`) stays under it. The block holds five patterns, `gitword`, `lead` and `bash_argv` (R-W1 to R-W5), and ends with two blank lines before `def words`.
   ```text
   _MARKS = re.compile(r"['\"\\,\[\]<>]")  # R-W1: the characters where the quote-blind view and bash's argv can differ
   _SPLIT = re.compile(r"[\s;&|(){}`'\"\\,\[\]]+")
   _TOK = re.compile(r"(?P<sp>[ \t]+)|(?P<op>&>>?|[<>]+(?:&-?|\|)?)|(?P<sep>[;&|(){}\n\r`]+)|\\(?P<esc>.)|(?P<end>\\)"
                     r"|'(?P<sq>[^']*)'|\"(?P<dq>(?:[^\"\\]|\\.)*)\"|(?P<run>[^ \t;&|(){}\n\r`'\"\\<>]+)"
                     r"|(?P<bad>['\"])", re.S)
   _DQ = re.compile(r"\\([\\\"$`]|\n)")  # inside double quotes a backslash escapes only these
   _CODE = re.compile(r"[ \t;&|(){}\n\r`'\"\\]")  # a quoted token with one of these may be code (`sh -c "..."`, `$(...)`)


   def gitword(t):
       """R-W4: True for a token that names git (`git`, `/usr/bin/git`, `git-push`), casefolded."""
       t = t.casefold().rsplit("/", 1)[-1]
       return t == "git" or t.startswith("git-")


   def lead(toks):
       """R-W5: the index of the first token that is not a leading global option or its value (R-P2: -C, -c, ...)."""
       j = 0
       while j < len(toks) and toks[j].startswith("-"):
           j += 2 if toks[j] in GIT_ARG_OPTS else 1
       return j


   def bash_argv(text, depth=0):
       """R-W1: the argv bash builds from `text`, as segments of tokens. A quote pairs with the next one of its kind and
       its text stays in one token; a backslash escapes one character; a backslash-newline vanishes; `,` `[` `]` are word
       characters; an unquoted `<` or `>` ends the word and starts a redirection (operator, file descriptor number and
       target word are no arguments), a quoted or escaped one is an argument. R-W2: a quoted token that holds a blank,
       a separator or a quote is read again the same way (`sh -c "..."`, `"$(...)"`); each such token is shorter than
       its text, so the recursion ends. Returns (segments, tail): the tail is the text from a quote that is never
       closed, set by the outermost call only."""
       segs, toks, parts, rest = [], [], [], ""
       skip = False

       def flush(cut=False, op=False):
           nonlocal skip
           if parts:
               w, q = "".join(v for _, v in parts), any(f for f, _ in parts)
               parts.clear()
               if q and _CODE.search(w):
                   segs.extend(bash_argv(w, depth + 1)[0])
               if skip:
                   skip = False
               elif not (op and not q and not w.strip("0123456789")):  # an unquoted number before `>` is a file descriptor
                   toks.append(w)
           if cut:
               skip = False
               segs.append(toks[:])
               toks.clear()

       for m in _TOK.finditer(text):
           k = m.lastgroup
           v = m.group(k)
           if k == "sp":
               flush()
           elif k == "op":
               flush(op=True)
               skip = not v.endswith("-")  # the word after an operator is its target, except after `>&-`
           elif k == "sep":
               flush(True)
           elif k == "bad":
               if depth == 0:
                   rest = text[m.start():]
               break
           elif k == "dq":
               parts.append((True, _DQ.sub(lambda x: "" if x.group(1) == "\n" else x.group(1), v)))
           elif k != "end" and (k != "esc" or v != "\n"):  # a backslash-newline, or a backslash at the end, vanishes
               parts.append((k != "run", v))
       flush(True)
       return segs, rest


   def words(text, top=False):
   ```
3. **Line 152, replace** `    is only the operator, the next token too."""` with two lines:
   ```text
       is only the operator, the next token too. R-W1: when the text holds a quote, a backslash, `,`, `[`, `]`, `<` or
       `>`, the segments of `bash_argv` follow, so a rule reads both views. R-W3: `top` is the command itself."""
   ```
4. **After line 167, insert five lines (4, 8, 8, 8 and 12 spaces of indentation in the file).** Line 167 is `        segs.append(toks)` (the last line of the loop in `words`); line 168 `    return segs` stays below.
   ```text
       if _MARKS.search(text):
           more, rest = bash_argv(text)
           segs += more
           if top and any(gitword(t) for t in _SPLIT.split(rest)):
               deny(QUOTE_DENY)  # R-W3: bash fails on a quote that is never closed, except in a heredoc body or a comment
   ```
5. **Line 257, replace** `                vt = [t.casefold() for s in words(v) for t in s]` with two lines (16 spaces of indentation in the file). Lines 258–259 (the `PUSH_DENY` check) stay below.
   ```text
                   vs = words(v)
                   vt = [t.casefold() for s in vs for t in s]
   ```
6. **Lines 260–262, replace** these three lines (`if "update-ref" in vt or (vt[:1] == ["remote"] and remote_writes(vt, 1, len(vt))):  # R-U3`, `deny(REF_DENY)`, `nxt.update(vt[:1])`) with five lines (16, 20, 20, 24 and 20 spaces of indentation in the file). Line 263 `        frontier = nxt` stays below.
   ```text
                   for s in vs:  # R-W5: the command token comes after the leading global options of each segment
                       st, k = [t.casefold() for t in s], lead(s)
                       if "update-ref" in st or (st[k:k + 1] == ["remote"] and remote_writes(st, k + 1, len(st))):  # R-U3
                           deny(REF_DENY)
                       nxt.update(st[k:k + 1])
   ```
7. **Line 283, replace.** `segs = words(cmd)` becomes `segs = words(cmd, True)`.

Expected diff of `scripts/bash_gate.py` against the base: 7 lines removed (anchors 2, 3, 5, 6 and 7) and 90 added, of which 10 are blank, so `grep -c '^+[^+]'` counts 80 and `grep -c '^-[^-]'` counts 7. `git diff origin/main -- scripts/common.py` is empty. The legacy loop in `words` (lines 153–167) does not change.

## Rules (allowlist, fail closed)
- **R-W0, scope:** every rule sits behind `card_path(cwd)` (line 110): a session with no `.delix/card` is unchanged (cases 65 to 67). `words()` has two callers, the alias check (line 257) and the command itself (line 283); both read the new view.
- **R-W1, the bash view and the union:** `words(text)` keeps the R-P1 scan as it is (quotes and backslashes removed first, split on `;&|(){}` newline and backtick, tokens split on blanks, `,` `[` `]`; a redirection token dropped). That scan is deliberately loose: it reads quoted text as code and splits a Python list literal such as `subprocess.run(["git","push","origin","main"])` into words (test "python list of words", `tests/push_gate_tests.sh` line 87), so it stays. When the text holds one of `'` `"` `\` `,` `[` `]` `<` `>` (pattern `_MARKS`), `words` appends the segments of `bash_argv(text)`, the argv bash builds. Every rule that reads `segs` (R-P2 to R-P6, R-U1, R-U2) therefore reads both views, and a deny from either view wins. Text with none of those characters costs what it cost before. `bash_argv` follows bash:
  - a quote pairs with the next one of its kind and its text stays in one token, also across blanks, `;` and `|`; inside double quotes a backslash escapes only `\`, `"`, `$`, a backtick and a newline;
  - outside quotes a backslash escapes the next character, and a backslash-newline vanishes (the word goes on over the line break);
  - `,` `[` `]` are word characters, so `-c x.y=a,b` is two tokens;
  - an unquoted `<` or `>` ends the word and starts a redirection: the operator (`>`, `>>`, `<`, `<<`, `<<<`, `<&`, `>&`, `>|`, `<>`, `&>`, `&>>`, `>&-`), an unquoted all-digit word glued before it (a file descriptor), and the word after it (the target, except after `>&-`) are not arguments. A quoted or escaped `<` `>` is an ordinary character;
  - a lone backslash at the very end of the text is dropped (D5).
- **R-W2, nested text:** a token with a quoted part that holds a blank, one of `;&|(){}`, a newline, a backtick, a quote or a backslash (pattern `_CODE`) is read again by `bash_argv` and its segments are added, so `sh -c "git -c 'a b' <send> origin HEAD:main"`, `"$(git -c 'a b' <ref update>)"`, a backtick substitution in double quotes and a substitution in a redirection target are seen. The text read again is the token's value, shorter than its source, so the recursion ends. A heredoc body is plain text to both views, as before (no heredoc exemption).
- **R-W3, a quote that is never closed:** bash stops on a quote with no partner, except where the text is a heredoc body or a comment, which `bash_argv` does not know. When the tokenizer meets such a quote at the top level it stops and returns the text from that quote on. If any word of that text (split on blanks, separators, quotes, backslash, `,` `[` `]`) names git (`gitword`: `git`, a path ending in `/git`, or `git-…`, casefolded), `words(cmd, True)` denies with `QUOTE_DENY`. Otherwise it does not deny; the loose scan still reads the whole text, so nothing is checked less than before. Alias values are not subject to this deny (`top` is false there).
- **R-W4, `gitword`:** the helper of R-W3; it is not used by any other rule.
- **R-W5, aliases:** `lead(toks)` returns the index of the first token that is not a leading global option or its value, with the options R-P2 reads (`GIT_ARG_OPTS` take the next token, any other token that starts with `-` is a flag). The alias check reads each segment of `words(value)`: the token at `lead` is the next alias name for the chain (R-P4, depth 10 as before), and R-U3 looks for `update-ref` anywhere in the segment, or `remote` at `lead` with `remote_writes` from the token after it. `PUSH_DENY` for a `!` value or a push token is unchanged and still wins. So `-c core.pager=cat remote set-url origin <url>`, `-C . update-ref …` and a chain `-C . -c x=y other-alias` deny.
- **Messages (exact):**
  - `QUOTE_DENY` = `delixcrew: a quote that is never closed stands in front of a git command, which this hook cannot read; close the quote or put the text in a file, then run the command again`
  - `PUSH_DENY`, `REF_DENY`, `ENC_DENY` and the R-U4 message do not change.
- **Regex discipline:** five new patterns; none is built from user input. `_MARKS`, `_SPLIT`, `_DQ` and `_CODE` are single character classes (or a class with one backslash pair). `_TOK` has nine alternatives that each start with a different character set, except that `&` starts both the redirection `&>` and the separator class: the redirection comes first and fails after one character when no `>` follows. No alternative sits under a quantifier except `(?:[^"\\]|\\.)*`, whose two branches start with different characters. The tokenizer is one `finditer` pass; the only recursion is R-W2.
- **Known false positives (fail closed):**
  - a quote that is never closed in front of a `git` word, such as `echo don't; git status`, or an apostrophe in a heredoc body or a comment followed by a git command (D4); close the quote or write the text to a file;
  - everything R-P1 already denies by reading quoted text as code (the words `git` and `push` on one line of a heredoc body, an `echo`, a commit message).

## Decisions (card writer, 2026-11-13; the lead records the K-numbers in the spec)
- **D1, a union of two views, not a replacement of R-P1.** The T044 note asks for an R-P1 that matches bash's argv. Replacing the scan would drop its loose reading of quoted text (a Python list, an `sh -c '…'` string with the words inside) and fail existing tests. Both views are read, and a deny in either wins. The cost is that the loose scan's own gaps stay (they are the reason the second view exists), the gain is that no existing test or message changes.
- **D2, the `,` `[` `]` split stays in the loose view only.** The split of R-P1 on those three characters is what makes `["git","push"]` and `sh -c 'git push'` readable (purpose kept); in the bash view those three are word characters, because bash does not split on them.
- **D3, redirections are in scope.** The finding names `,[]`, quoted whitespace and backslash-newline. The card writer compared `bash_argv` with the argv real bash builds (differential test, D9) and found that a glued `>` or `<`, `>&2`, `2>&1`, `>|`, `&>`, and a quoted or escaped `>` also hide a second refspec from the push rule on main today (cases 15 to 24; for instance a push of the own branch followed by `>&2 HEAD:main` passes the T041 rule because `&` splits the segment). A fix that leaves them would be the same bug one token later.
- **D4, R-W3 denies only when a git word follows the unclosed quote.** Alternatives: deny every unclosed quote (stops a plain `echo don't` and every apostrophe in a heredoc: too many false positives), or ignore it (a comment `# it's` followed by a git command on the next line hides that command from the bash view, cases 32 and 33). The narrow deny keeps the loose view as the net for everything else.
- **D5, a lone backslash at the end of the text is dropped.** Bash 3.2.57 on this Mac drops it (`echo a\` gives `a`); bash 5.2.21 on GTR9 keeps it as a literal `\`. The loose view drops it too, and the dropped reading denies everything the literal reading would (it reads `git\` as `git` and `main\` as `main`). Cases 25 and 64 pin that the hook neither raises nor loops on it (an earlier prototype recursed without end).
- **D6, `lead()` uses the R-P2 option set,** not a new list: `-C`, `-c`, `--git-dir`, `--work-tree`, `--namespace`, `--config-env`, `--attr-source`, `--shallow-file` take the next token; `--config-env=x` is one flag token, as git reads it.
- **D7, `words(text, top=False)`:** the R-W3 deny lives inside `words` because the unclosed tail is only known there; `top` is true only for the command itself (anchor 7), so an alias value read by R-P4 does not deny with `QUOTE_DENY`. Changing the return type would touch both callers.
- **D8, a new test file and smaller growth sizes.** `tests/argv_gate_tests.sh` leaves every existing test file untouched. The growth test runs 6 shapes at k = 5000 and k = 40000 (the least of 3 runs per size; t(40000) < 3 s, ratio < 20). T044 used 20000 and 160000, but the heaviest shape here (`sh -c` strings) took over 3 s at 160000 while staying linear (ratio 7 to 8); 40000 repetitions are already a command of about 1 MB.
- **D9, differential evidence, not repo content.** The card writer checked `bash_argv` against the argv of real bash (a stub command printing its arguments) on random mixes of quotes, escapes, `,` `[` `]`, backslash-newlines and redirections, also nested in `sh -c "…"`: 41,000 cases on bash 3.2.57 (Mac) with 0 mismatches, and 13,000 on bash 5.2.21 (GTR9) with 0 mismatches once the lone trailing backslash of D5 is left out. The scripts are in the shared notes folder of the card-writing session, not in the repo; the reviewer may ask the lead for them.
- **D10, two things stay out of the bash view on purpose:** brace expansion and `$'…'` (O1, O2). Modelling them is a bash reimplementation; the Known limits name them (H3).

## Out of scope (each with the reason; T046 keeps the matching Known limits sentences)
- **O1, brace expansion:** `git {push,origin,HEAD:main}` and `git {update-ref,x,y}` expand to a push and a ref write in bash and pass the hook on main and on this card's prototype (measured by the card writer with the real hook: both allowed). `{` and `}` split segments in both views. A follow-up card could deny an unquoted `{` that holds a `,` or `..` in a segment that has a git word. It changes what `{` means to the tokenizer, so it is not in this card; the lead decides whether it becomes T048. T046 adds the words "brace expansion" to the Known limits list (H3).
- **O2, `$'…'` ANSI-C quoting, variables, globs, `eval` of a built string:** already Known limits in README and the site; unchanged.
- **O3, the other items of T044 Out of scope (O1 to O7):** unchanged. O4 gains `git fast-import` (the T044 round-1 security note: it writes any ref in one command) next to the write form of `git symbolic-ref`; the sentence is in the Docs handover.
- **O4, the push line as a whole allowlist (T044 O2),** the `gh` alias for `pr merge`, `scripts/common.py` `delix_json`, `scripts/write_gate.py` on a non-object `delix.json`: separate cards, as T044 says.
- **O5, bash versions:** the one difference the card writer found between bash 3.2 and 5.2 is the lone trailing backslash (D5, D9). zsh is not modelled.

## Interfaces
- Consumed: `GIT_ARG_OPTS`, `remote_writes(toks, k, n)`, `deny`, `alias_check`'s chain walk, the R-P2 pass and the other rules that read `segs`.
- Produced: `QUOTE_DENY`; the patterns `_MARKS`, `_SPLIT`, `_TOK`, `_DQ`, `_CODE`; `gitword(t)`, `lead(toks)`, `bash_argv(text, depth=0)` returning `(segments, tail)`; `words(text, top=False)`.

## Global Constraints (verbatim)
- T044 round 1, Medium: "R-P1 that matches bash's argv (join backslash-newline, keep quoted whitespace and an option value with `,[]` as one token, deny on unbalanced quotes)."
- T044 round 1, Low: "skip leading global options and their values before the first command token."
- T044 round 1, note: "`git fast-import` also writes any ref in one command; add it to H2's list."
- K283: "Satırın tamamını izin listesine bağlamak takip işidir."
- Repo hook rules: no new regex with overlapping alternation; a growth test at two sizes; the test driver lives in the test file with the trigger words assembled at run time; the existing tests are not changed.
- Python 3.9 stdlib; no version-dependent behaviour (the Mac runs 3.9.6, CI 3.12; run the new file on 3.13 as well). ASCII only in the code and the test; no invisible character; the check marks in the test are octal escapes in bash and `chr(0x2714)` / `chr(0x2718)` in Python.

## Steps
1. Write `tests/argv_gate_tests.sh` (cases below). Run `bash tests/argv_gate_tests.sh` and see **red**: 36 `✘` lines, 37 `✔` lines (the 6 growth lines and the cases 14, 25, 35, 36, 37, 39, 41 and 44 to 67, which the loose view already gets right), `FAILED`, exit 1 (the card writer's prototype on the base; a different count means a case differs from the list, so say so in the report).
2. Edit `scripts/bash_gate.py` bottom-up per Edit anchors 7 to 1; run the `ast.parse` one-liner after each.
3. Run `bash tests/argv_gate_tests.sh` and see **green**: 73 `✔` lines (67 cases and 6 growth lines), `ALL PASSED`. Run it again on Python 3.13 through a PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 2 paths by name. Commit `T047: bash_gate reads a command the way bash builds its argv (T044 round 1)`. No command of yours, and no commit message, holds `git` followed by `push`, `update-ref` or `remote` as words on one line, except the one push below. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd`. Open a PR with `--body-file` and a `## How I tested` section.
6. After step 2 your own session may run the edited hook (if the plugin loads from this worktree). The new rule denies a quote that is never closed in front of a `git` word: write the PR body and the report to a file with the Write tool, and keep apostrophes out of Bash text that also holds a git command. Keep to commands the rules allow: no `git remote` form beyond the read forms, no `update-ref`.

## Tests (`tests/argv_gate_tests.sh`, a new file; `ALL PASSED` at the end)
- **Words:** `G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"; UR=set; UR="${UR}-url"`, `NL=$'\n'`, `OK=$'\342\234\224'`, `NO=$'\342\234\230'`. The file holds none of those words as one literal. The three messages are built from them:
  ```text
  PUSH_DENY="delixcrew: an implementer session pushes only its own card branch ($G $P [-u] origin <branch>); the default branch and every other $P run from the user's own terminal"
  REF_DENY="delixcrew: an implementer session does not write $G refs or change ${R}s ($U, $R set-head, $UR, add, remove); those run from the user's own terminal"
  QUOTE_DENY="delixcrew: a quote that is never closed stands in front of a $G command, which this hook cannot read; close the quote or put the text in a file, then run the command again"
  ```
- **Input:** build the hook input with Python `json.dumps` (never by string concatenation) and pipe it to `python3 "$S/bash_gate.py"` (`S` = `scripts/`). `allow` = exit code 0 and no `"permissionDecision": "deny"`; `deny` = exit code 0, that string, and `grep -qF` of the message. A hook that raises exits 1, so a crash is red for both helpers. Each case prints `$OK <label>` or `$NO <label> …`.
- **Setup** (no network, no push in the setup, direct calls not through the hook): `W` is a repo on `claude/t1` with one empty commit, `.delix/card` = `docs/delix/tasks/T047-x.md`, `.delix/` in `.git/info/exclude`, `docs/delix/delix.json` = `{"default_branch":"main"}`, a directory `$W/a b`, `remote add origin "$W.$G"` (never contacted), `refs/remotes/origin/main` made by an update-ref call in the setup and `symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main`. `L` is a repo on `claude/t1` with no card. Commits in the setup use `-c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null`.
- **Cases** (number, label as printed, the command as a bash string with its variables, the expected result; cwd `W` except cases 65 to 67). `NL` is a newline: `\${NL}` is a backslash then a newline. `$W/a b` is the directory with a blank. Cases 1 to 37 first:
  - *R-W1, an option value with a comma or a bracket, a quoted blank, a backslash-newline*
    - 1 -c value with a comma, ref update: `$G -c x.y=a,b $U x y` → `REF_DENY`
    - 2 -c value with a comma, remote url: `$G -c x.y=a,b $R $UR origin /tmp/x` → `REF_DENY`
    - 3 -c value with a comma, send to main: `$G -c x.y=a,b $P origin HEAD:main` → `PUSH_DENY`
    - 4 -c value with brackets, ref update: `$G -c x.y=[a] $U x y` → `REF_DENY`
    - 5 -C dir with a blank, ref update: `$G -C "$W/a b" $U x y` → `REF_DENY`
    - 6 -C dir with a blank, remote url: `$G -C "$W/a b" $R $UR origin /tmp/x` → `REF_DENY`
    - 7 -c value with a blank, ref update: `$G -c "user.name=A B" $U x y` → `REF_DENY`
    - 8 -c value with a blank, send to main: `$G -c "user.name=A B" $P origin HEAD:main` → `PUSH_DENY`
    - 9 --git-dir with a blank, ref update: `$G --git-dir "$W/a b" $U x y` → `REF_DENY`
    - 10 backslash-newline before the subcommand: `$G \${NL}$U x y` → `REF_DENY`
    - 11 backslash-newline, send to main: `$G \${NL}$P origin main` → `PUSH_DENY`
    - 12 -C . then backslash-newline: `$G -C . \${NL}$U x y` → `REF_DENY`
    - 13 backslash-newline inside remote: `$G $R \${NL}$UR origin x` → `REF_DENY`
    - 14 backslash-newline after the send: `$G $P \${NL}origin main` → `PUSH_DENY`
  - *R-W1, a redirection ends the word and takes no argument; a quoted or escaped `>` is an argument; a lone backslash at the end*
    - 15 glued > after the subcommand: `$G $U>/dev/null x y` → `REF_DENY`
    - 16 glued > after the send: `$G $P>/dev/null origin HEAD:main` → `PUSH_DENY`
    - 17 glued < after the send: `$G $P</dev/null origin HEAD:main` → `PUSH_DENY`
    - 18 glued > after remote: `$G $R>/dev/null $UR origin x` → `REF_DENY`
    - 19 >&2 before a second name: `$G $P origin claude/t1 >&2 HEAD:main` → `PUSH_DENY`
    - 20 2>&1 before a second name: `$G $P origin claude/t1 2>&1 HEAD:main` → `PUSH_DENY`
    - 21 >| f before a second name: `$G $P origin claude/t1 >| f HEAD:main` → `PUSH_DENY`
    - 22 &>f before a second name: `$G $P origin claude/t1 &>f HEAD:main` → `PUSH_DENY`
    - 23 quoted > before a second name: `$G $P origin claude/t1 ">" HEAD:main` → `PUSH_DENY`
    - 24 escaped > before a second name: `$G $P origin claude/t1 \> HEAD:main` → `PUSH_DENY`
    - 25 backslash at the end, ref update: `$G $U x y \` → `REF_DENY`
  - *R-W2, the text of a quoted token is read again*
    - 26 sh -c string, send to main: `sh -c "$G -c 'a b' $P origin HEAD:main"` → `PUSH_DENY`
    - 27 sh -c string, ref update: `sh -c "$G -c 'a b' $U x y"` → `REF_DENY`
    - 28 substitution in double quotes: `echo "$($G -c 'a b' $U x y)"` → `REF_DENY`
    - 29 substitution in a redirection target: `echo hi > "$($G -c 'a b' $U x y)"` → `REF_DENY`
    - 30 backticks in double quotes: `` echo "`$G -c 'a b' $U x y`" `` → `REF_DENY`
    - 31 heredoc body, ref update: `bash <<'EOF'${NL}$G -c "a b" $U x y${NL}EOF` → `REF_DENY`
  - *R-W3, a quote that is never closed (deny), and what must pass (allow)*
    - 32 comment with a quote, then a command: `echo x # it's${NL}$G -c "a b" $P origin HEAD:main` → `QUOTE_DENY`
    - 33 heredoc body with a quote, then git: `bash <<'EOF'${NL}echo don't${NL}$G -c "a b" $U x y${NL}EOF` → `QUOTE_DENY`
    - 34 quote, then git on the line (known false positive): `echo don't; $G status` → `QUOTE_DENY`
    - 35 quote with no git word after it: `echo don't >> notes.txt` → `allow`
    - 36 heredoc file write, apostrophe, no git: `cat > notes.md <<'EOF'${NL}it's here${NL}EOF` → `allow`
    - 37 comment with a quote, no git word: `$G status # it's fine` → `allow`
- **Aliases** (written to `W`'s `.git/config` by the test before case 38, unset after case 49):
  - alias.lc = `-c core.pager=cat $R $UR origin /tmp/x`
  - alias.lu = `-C . $U x y`
  - alias.lq = `-c "user.name=A B" $R $UR origin /tmp/x`
  - alias.lm = `-c x.y=a,b $U x y`
  - alias.lx = `-c core.pager=cat lc`
  - alias.ly = `-C . -c core.pager=cat lx`
  - alias.le = `--config-env=x.y=Z $U x y`
  - alias.lp = `-c core.pager=cat $P origin main`
  - alias.lg = `-c color.ui=always log --oneline`
  - alias.lv = `-c core.pager=cat $R -v`
  - alias.lr = `-c core.pager=cat $R show`
  - alias.ln = `-c`
- **Cases 38 to 49** (aliases set; deny / allow):
  - 38 alias -c, then remote url: `$G lc` → `REF_DENY`
  - 39 alias -C, then ref update: `$G lu` → `REF_DENY`
  - 40 alias -c with a blank value: `$G lq` → `REF_DENY`
  - 41 alias -c with a comma value: `$G lm` → `REF_DENY`
  - 42 alias chain lx = -c .. lc: `$G lx` → `REF_DENY`
  - 43 alias chain ly = -C . -c .. lx: `$G ly` → `REF_DENY`
  - 44 alias --config-env=.., ref update: `$G le` → `REF_DENY`
  - 45 alias -c, then a send (PUSH_DENY wins): `$G lp` → `PUSH_DENY`
  - 46 alias -c, then log: `$G lg` → `allow`
  - 47 alias -c, then remote -v: `$G lv` → `allow`
  - 48 alias -c, then remote show: `$G lr origin` → `allow`
  - 49 alias that is only an option: `$G ln` → `allow`
- **Allow, commands the new reading must keep passing (cases 50 to 64):**
  - 50 -C dir, status: `$G -C "$W" status` → `allow`
  - 51 -c value with a blank, status: `$G -c "user.name=A B" status` → `allow`
  - 52 -c value with a comma, status: `$G -c user.name=A,B status` → `allow`
  - 53 log --grep with a quote and brackets: `$G log --grep "it's a, b [c]" -1` → `allow`
  - 54 log --grep with double quotes: `$G log --grep 'say "hi", then go' -1` → `allow`
  - 55 backslash-newline before status: `$G \${NL}status` → `allow`
  - 56 backslash-newline inside status args: `$G status \${NL}-s` → `allow`
  - 57 own branch send, 2>&1: `$G $P origin claude/t1 2>&1` → `allow`
  - 58 own branch send, >f: `$G $P origin claude/t1 >f` → `allow`
  - 59 own branch send, &>f: `$G $P origin claude/t1 &>f` → `allow`
  - 60 own branch send, quoted name: `$G $P origin "claude/t1"` → `allow`
  - 61 -C dir with a blank, remote show: `$G -C "$W/a b" $R show origin` → `allow`
  - 62 substitution in double quotes, status: `echo "$($G status)"` → `allow`
  - 63 sh -c string, status: `sh -c "$G -C '$W' status"` → `allow`
  - 64 backslash at the end of the command: `echo a\` → `allow`
- **Allow with no card (cwd `L`; cases 65 to 67):**
  - 65 no card: comma value, ref update: `$G -c x.y=a,b $U x y` → `allow`
  - 66 no card: glued >, send: `$G $P>/dev/null origin HEAD:main` → `allow`
  - 67 no card: quote, then git: `echo don't; $G status` → `allow`
- **Growth** (6 `✔` lines; for each input k = 5000 and k = 40000, the least of 3 runs per size; expect t(40000) < 3 s and t(40000) / t(5000) < 20; print both times and the ratio; the Python block prints the marks with `chr(0x2714)` and `chr(0x2718)`), with `g` = `$G`:
  - comma values: `("$G -c a,b status; " * k)`
  - quoted blanks: `("$G -C \"a b\" status; " * k)`
  - `sh -c` strings: `("sh -c \"$G -c 'a b' status\"; " * k)`
  - backslash-newlines: `"$G " + ("\\\n" * k) + " status"` (a backslash and a newline, k times)
  - redirections: `("$G status 2>&1; " * k)`
  - one quote never closed: `"'" + ("$G status; " * k)`

## Verification command → expected output
- `bash tests/argv_gate_tests.sh` → last line `ALL PASSED` · `bash tests/argv_gate_tests.sh | grep -c '^✔'` → `73`
- `bash tests/argv_gate_tests.sh | grep growth` → 6 lines, each `ratio` below 20 and `t(40000)` below 3 s (card writer's prototype, several runs: ratios 1.7 to 6.0, at most 1.5 s)
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/argv_gate_tests.sh | tail -1` → `ALL PASSED`
- `bash tests/push_gate_tests.sh`, `bash tests/ref_gate_tests.sh`, `bash tests/hook_tests.sh`, `bash tests/bash_gate_heredoc_tests.sh`, `bash tests/trust_tests.sh`, `bash tests/write_gate_case_tests.sh` → each `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `bash tests/site_tests.sh` → exit 0 (site files are untouched)
- `claude plugin validate .` → passes
- `git diff origin/main -- tests | grep -c '^-[^-]'` → `0`
- `git diff origin/main -- scripts/bash_gate.py | grep -c '^-[^-]'` → `7` · `git diff origin/main -- scripts/bash_gate.py | grep -c '^+[^+]'` → `80`
- `git diff origin/main -- scripts/common.py | wc -l` → `0`
- `git diff -U0 origin/main -- scripts/bash_gate.py | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and (len(l) > 121 or any(ord(c) > 126 for c in l))]"` → no output
- `python3 -c "open('tests/argv_gate_tests.sh', 'rb').read().decode('ascii')"` → exit 0 (the test file is ASCII)
- `git diff --stat origin/main` → exactly the 2 Files

## Review Focus
- The union (D1): the legacy loop in `words` is untouched; every rule reads both views; a deny in either wins. No existing message, rule order or test line changes; `tests/push_gate_tests.sh`, `tests/ref_gate_tests.sh` and the other suites pass without edits.
- `bash_argv` against real bash: security and the lead may run the differential test of D9 again (ask the lead for the scripts) or try the forms of T044 round 1 on the hook and real git 2.54 over a `git archive` of the head: `-c x.y=a,b`, `-C "<dir with a blank>"`, `-c "user.name=A B"`, a backslash-newline before the subcommand, and an alias that starts with `-c core.pager=cat`. A form that passes is a Known limit or a follow-up card; it is not a reason to widen this card (O1 is the known one).
- R-W3 is narrow (D4): `echo don't >> notes.txt` and a heredoc file write with an apostrophe and no git word pass (cases 35 and 36); `echo don't; git status` denies (case 34, the stated false positive).
- Regex discipline (Rules): the card writer also timed seven shapes outside the test (runs of `&`, `&>f;` pairs, `&&>f` runs, `<>` runs, alternating quotes, escapes in a double quote, `"` inside `'`) at 5000 and 40000: ratios 1.1 to 2.1, at most 0.11 s. `sh -c` strings are the heaviest shape (t(40000) up to 1.5 s, ratio up to 6.0) and linear.
- `lead()` (R-W5) uses `GIT_ARG_OPTS` as R-P2 does and the alias chain keeps its depth limit 10 and its `PUSH_DENY` precedence.
- Daily commands still pass: the card writer ran 15 everyday implementer commands (commit with an apostrophe in double quotes, `for t in tests/*_tests.sh`, `gh pr create --body-file`, a heredoc commit message, `2>&1 | tee`) on the base hook and the prototype with identical results.
- Not covered by a case of its own: the heredoc marker `<<'EOF'` is a redirection operator and its delimiter word is dropped from the argv, as in bash (case 31 covers a body that holds a command).

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `README.md`, `README.tr.md`, `site/**`, every existing test file and every existing test line.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a regex, a dependency, an option or a rule beyond R-W1 to R-W5 and the five patterns of anchor 2. Do not model brace expansion, `$'…'`, variables or globs (O1, O2). If a case in Out of scope looks easy, write it in the report instead.
- No raw non-ASCII or invisible character in code or tests.
- Verification commands never put `git` followed by `update-ref`, `remote` or `push` as words in the command text, except the one push in Step 5.
- No ruleset, `.github/**` or settings change: those are the user's, from their own terminal (K279).

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`, `bash --version`;
- the six growth lines;
- PR number and branch;
- assumptions;
- every pre-existing slow path or crash seen and not fixed.

Read only this card, spec §6 and K296.

## Docs handover (T046)
For T046. K298 moves the README and site sentences out of this card. Copy the words as given. On the site a backticked word is a `<code>` element, `<`, `>` and `&` are HTML-escaped, and the release label is T046's. Every sentence below describes what this card makes true; the lead checks them against the merged code before T046 is dispatched. T046 uses the same places as the T044 sentences it extends (README Bash paragraph, README Known limits, README.tr's twins, the site index bash_gate Implementer cell and the site usage Known limits).

**H0, order.** This card lands in wave 17 and T046 is wave 16. If T046 runs first (T047 not merged): keep the item that T044's H3 removes (``another URL for `origin` set with `git remote` ``, in the four places), because the forms that change a remote URL through a quoted value, a comma value or a backslash-newline still pass until this card is merged; use T044's H2 with `git fast-import` added (H2 below); skip H1, H3 and H4. If T047 is merged first, or the lead schedules a docs pass after it: apply T044's H1 to H3 as written, with the changes below, and H1, H3 and H4.

**H1, the argv sentence** (README Bash paragraph, after T044's H1 sentence; the same words in the site index bash_gate Implementer cell):
- EN: `The rules read a command both by the loose word scan and the way bash builds its argv, so a quoted blank, an option value with a comma or a bracket, a backslash-newline, a redirection and the text of an `sh -c` string do not hide the subcommand, and an alias that starts with a global option such as `-c` is followed to its command. A quote that is never closed in front of a `git` word is denied with a message (T047).`
- TR: `Kurallar bir komutu hem gevşek kelime taramasıyla hem de bash'in kurduğu argv gibi okur; bu yüzden tırnak içindeki boşluk, virgüllü ya da köşeli parantezli bir seçenek değeri, satır sonundan önceki ters bölü, bir yönlendirme ve bir `sh -c` dizgesinin metni alt komutu gizlemez, `-c` gibi bir genel seçenekle başlayan alias da komutuna kadar izlenir. Bir `git` kelimesinin önünde hiç kapanmayan tırnak mesajla reddedilir (T047).`

**H2, the Known limits list in T044's H2 sentence** gains `git fast-import` next to `git symbolic-ref`:
- EN: `(such as `git symbolic-ref`, `git fast-import`, `git fetch` with a refspec into `refs/remotes/`, or `git branch -f`)`
- TR: `(`git symbolic-ref`, `git fast-import`, `refs/remotes/` içine refspec'li `git fetch` ya da `git branch -f` gibi)`
- Why: `git fast-import` writes any ref in one command (the card writer made it write `refs/remotes/origin/main` in a throwaway repository with git 2.54.0).

**H3, the push-rule out-of-reach list** (README Known limits "The implementer push rule (T041, K279) …", README.tr's twin, site usage EN and TR):
- The item "variables, `eval`, globs and ANSI-C quoting" becomes:
  - EN: `variables, `eval`, globs, ANSI-C quoting and brace expansion (`git {push,origin,HEAD:main}` runs as a push)`
  - TR: `değişkenler, `eval`, glob'lar, ANSI-C tırnaklama ve süslü parantez genişletme (`git {push,origin,HEAD:main}` bir push olarak çalışır)`
- The false-positive clause (after T044's addition, "… `update-ref` on one line there, and a `git remote` form outside its read forms …") gains:
  - EN: `a quote that is never closed in front of a `git` word (an apostrophe in a comment or a heredoc, then a git command; close the quote or put the text in a file)`
  - TR: ``bir `git` kelimesinin önünde hiç kapanmayan tırnak (yorumda ya da heredoc'ta bir kesme işareti, ardından bir git komutu; tırnağı kapat ya da metni bir dosyaya yaz)``
- Every other item stays.

**H4, the removed item.** With this card merged, T044's removal of the `git remote` URL item stands: the forms that passed (a `-c` value with a comma, `-C` or `-c` with a blank, a backslash-newline before the subcommand, an alias that starts with `-c core.pager=cat`) now deny. The lead confirms the merge before T046 applies it.

## Review findings (filled by the lead)
- Round 1 (PR #75, head `5930256d4775212fb0b25d5e41d482232d335ab6`, 2026-11-13): qa `REJECT` (0 P0, 1 P1), security
  `🔐 HUMAN_APPROVAL` twice (run 1 was stopped by a model safeguard at checklist item 3; one narrow retry of item 3
  gave 2 Medium and 1 Low). Lead gates on the clean `git archive` of the head: `bash_gate.py` equals the card's
  anchors applied to 906eb3d byte for byte; 15 suites exit 0 on Python 3.9.6 and 3.13.13; `argv_gate_tests.sh`
  73 `✔`; D9 re-run on the head: 24,000 cases (3 seeds, flat and inside `sh -c`) against bash 3.2.57, 0 mismatches;
  CI `check` and `test` green. Lead probe with real git 2.54 on temp repos (no network): the T044 round-1 forms and
  the redirection forms (cases 16, 19, 20, 22) deny on the head and pass on main, where the push to `main` landed.
  Every finding below was reproduced by the lead with real git (hook allows, git writes the ref or pushes `main`);
  all but the last also hold on main.
  - P1 (qa): R-W3 splits the tail on quotes, so after an apostrophe in a comment a command word written `g""it`
    or `g\it` is no git word; with `-c "user.name=A B"` the ref write passes. Fix F3. `g'i't` still passes after
    F3 (its first quote pairs with the comment's apostrophe): Known limit, the class of variables (K301).
  - Medium (security): a `-c` value that holds a vertical tab, a form feed, a carriage return or U+00A0 hides the
    subcommand: the loose view splits on Python `\s`, `_MARKS` does not start the bash view and `_TOK` reads a
    carriage return as a separator. Ref write and push to `main` pass. The whitespace D9 variant gives 419
    mismatches in 4,000 cases on the head. Fix F1.
  - Medium (security): double quotes inside `"$(...)"` (`X="$(git -c "user.name=A B" ...)"`) end the outer token at
    the inner quote; ref write and push to `main` pass. Not in this card: reading `$(` inside double quotes is a
    parser change; follow-up 🔐 card T048, Known limit until it lands (K301).
  - Low (security): the R-W3 tail split does not end a word at `<` `>`, so `git>f ...` after a comment apostrophe
    passes. Fix F2.
  - P1 (lead, regression against main): R-W5 reads the alias value per segment, but git splits an alias value on
    any blank; an alias `remote<newline>set-url origin <url>` passes on the head, main's hook denies it, and git
    runs it (the URL changed in the probe). Fix F4: the flat check with `lead()` as well.
  - Notes (security unsure, no fix): R-W2 has no depth cap, but a crash blocks (`hooks/hooks.json`
    `"onFailure": "block"`) and the depth grows only with escapes; an all-digit word before `&>` is dropped as a
    file descriptor (no passing command found); the Regex discipline text is slightly inexact (`esc` and `end`
    both start with a backslash; bounded).
  - Fix round 2: F1 to F4 and cases 68 to 76, prototyped by the lead on the head: 82 `✔`; the new cases give
    8 `✘` on the round-1 head; growth ratios up to 5.9; D9 with whitespace fragments 32,000 cases, 0 mismatches;
    15 suites on 3.9.6 and 3.13.13 exit 0. For T046 H3: also name double quotes inside `"$(...)"` (until T048)
    and a command word split by quotes after an apostrophe in a comment.
  - Evidence: `T047.*` files and `t047_*` scripts in the lead's scratchpad (not in the repo).
- Round 2 (PR #75, head `5206098421b5d7d4a4e9c23a57f4b614fce4bd6c`, 2026-11-13): qa `ACCEPT_WITH_NOTES` (0 P0,
  0 P1), security `🔐 HUMAN_APPROVAL` (2 Medium, 2 Low, 1 unsure). The head equals the lead's round-2 prototype
  byte for byte. Lead gates on the clean `git archive` of the head: 15 suites exit 0 on Python 3.9.6 and 3.13.13;
  `argv_gate_tests.sh` 82 `✔`; D9 32,000 cases (seeds 31 and 47, flat and inside `sh -c`, with and without
  whitespace fragments) against bash 3.2.57, 0 mismatches; CI `check` and `test` green. Every round-1 form denies
  on the head and F4 removed the alias regression. Every finding below was reproduced by the lead with real git
  2.54 (hook allows; git writes the ref, changes the URL or pushes `main`); each also holds on main, so none is a
  regression.
  - Medium (security): `{` or `}` glued to a word (`git -c x.y={b push origin HEAD:main`, `-c x.y=}`): the loose
    view splits there, bash does not, and `_MARKS` does not start the bash view. Push to `main` and ref write
    pass. Fix F5.
  - Medium (security; the lead's round-1 probe and qa's unsure note): an apostrophe in a comment pairs with a later
    single quote, so `# don't do this⏎git -c 'user.name=A B' push origin HEAD:main` passes, inside an `sh -c`
    string too. Fix F7: an unquoted `#` that starts a word starts a comment, which ends at a newline or a backtick.
    Measured on bash 3.2.57: `a#b`, `'a'#b` and `a\ #b` are words; `#` after a blank, `;`, `|`, `&&` or `>` starts a
    comment; a comment inside backticks ends at the closing one; a backslash-newline does not continue a comment.
    The heredoc half (`cat <<EOF⏎don't⏎EOF⏎git -c 'user.name=A B' push origin HEAD:main`) needs heredoc reading:
    T048, Known limit until then (K302).
  - Low (security): the R-W3 tail keeps a backslash-newline, so `gi\⏎t` after a quote that is never closed is no
    git word; after an apostrophe in a heredoc the ref write passes. Fix F6.
  - Low (security): R-W5 builds the alias value's flat list with `words()`, not the way git's `split_cmdline`
    splits it (blanks and newline only, quotes, backslash). The alias values `-c x.y=a;b remote set-url ...`,
    `-c "user.name=A B" remote⏎set-url ...` and `-c x.y=a;b <alias that pushes main>` pass. Each needs an alias
    already in the repo config (R-P5 denies writing one). T048 (K302).
  - Unsure (security), reproduced: an alias value of two lines whose second line starts with `alias.`
    (`-c⏎alias.zz remote set-url origin /x`) is read by the hook as two keys; git runs `remote set-url`. Reading the
    config with `-z` fixes it. T048 (K302).
  - Notes (qa, no fix): the Verification counts are now 6 removed and 83 added non-blank lines (the card says 7 and
    80; round 3 changes them again, below); R-W2 has no depth cap (fails closed, depth about log2 of the input).
  - Fix round 3 (the last, `max_review_rounds` 3): F5 to F7; cases 32 and 69 to 71 now expect the rule the command
    breaks (the hook reads past the comment instead of refusing); cases 77 to 93 and two growth lines added.
    Prototyped by the lead on the head: 101 `✔` (93 cases, 8 growth lines); the new tests give 14 `✘` on the
    round-2 head; growth ratios up to 6.1 (at most 1.4 s); D9 32,000 cases and the comment and brace generator 24,000 cases (16,000 flat, 8,000 inside `sh -c`) against bash 3.2.57, 0 mismatches (the round-2 head: 1,356 and 1,347 in 4,000 each); 15 suites exit 0 on 3.9.6 and 3.13.13.
    `bash_gate.py` against main: 6 removed and 98 added non-blank lines, no added line over 121 characters or
    outside ASCII. For T046 H3: the false-positive clause keeps the heredoc and drops the comment (an apostrophe in a
    comment no longer denies); name the heredoc form and the alias split forms above as Known limits until T048.
