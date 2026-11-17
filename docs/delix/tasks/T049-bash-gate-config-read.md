# T049 🔐 — bash_gate: R-P5 counts a `git config` read only at its action position, and the bash view also reads a command with `#`, `(` or a backtick

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T049 | S | 3 | backend | 19 | open |

**🔐 Approved:** 2026-11-17 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`). `tests/push_gate_tests.sh` matches `test_paths` (`tests/**`) and no protected entry; it is in Files for one insertion after its line 102, and none of its existing lines changes.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-17 ("Evet, T049 onaylı", said in the lead session; K316). The lead commits it to main before dispatch; the session branches from that commit.
> - Order (K316, the user, replacing K314): T046, then this card, then the release card T042. The lead checked the anchors below on main `bdde464`, where `scripts/` and `tests/` are unchanged since `f37e896`; T046 and T042 do not touch `scripts/bash_gate.py` or `tests/push_gate_tests.sh`.
> - It closes the R-P5 gap of K313 and the substitution gap found while writing this card (D4). The card writer measured every form with the real hook, then bash 3.2.57 and git 2.54 in a throwaway card repository with a local bare `origin` and a second local bare repository (no network): 17 forms pass main and write `origin`'s URL keys or push `main`; the prototype denies all 17 (D9).
> - Publication (K313): the forms that pass main are in this card and its tests only. README and site text names none of them (Docs handover).
> - It is defence in depth, not a boundary: the rules are a check on the command's words (Out of scope).

**Goal (1 sentence):** In an implementer worktree a `git config` call with an R-P5 key passes only when git reads it as a read (`get` or `list` as its first argument, or a read option among the options before the first other argument), and a command that holds a `#`, a `(` or a backtick is also read by the bash view, so that a read word after the key, in a comment or as an option's value, and a substitution between `git` and its words, no longer hide a write of `origin`'s URL keys or a push from the rules. · **Spec:** `docs/delix/specs/C-board-visibility.md` K313, K316 and K317; K317 records this card's decisions (the same text as the section at the end of this card)

**Docs/site:** none in this card, the same exception as T044, T047 and T048 (K298): the release card T042 writes the README, README.tr and site sentences from the `## Docs handover` section at the end of this card (K316). Do not touch `README.md`, `README.tr.md` or `site/**`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (five edits, see Edit anchors)
- Modify: `tests/push_gate_tests.sh` (one insertion after line 102, see the test file anchor; no existing line changes)

## Edit anchors (base main f37e896, full SHA f37e8968d5ed0a52e03a1ea86a9585fa0c8fd5ce)
Line numbers are from that commit (`scripts/bash_gate.py` there has 699 lines and sha256 `4da15bf82d19cb10147cc3a3a7920b6cf2026becb2d866716e0b762ebbf37af1`; `bdde464` does not change it, nor `tests/push_gate_tests.sh`; the lead checked this at dispatch, K316). Match the quoted content before you edit each place. If it differs, stop with `NEEDS_CONTEXT`. Edit bottom-up (anchor 5 first, anchor 1 last) so the line numbers above you hold. Every new line is at most 120 characters and ASCII. After each edit run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output: if this repo's plugin loads from your worktree, a syntax error would block your own Bash.

Python is indentation-sensitive. The code blocks below sit inside list items, so every code line carries exactly 3 extra leading spaces that belong to the list: remove those 3 and keep the rest (a blank line in a block is empty). Each anchor says how deep its first line sits in the file.

1. **After line 151, insert three lines (no indentation on the first).** Line 151 is `CONFIG_READS = {"--get", "--get-all", "--get-regexp", "--get-urlmatch", "--list", "-l", "get", "list"}`; lines 152–153 (blank) stay below.
   ```text
   CONFIG_FLAGS = {"--global", "--system", "--local", "--worktree", "--includes", "--no-includes", "-z", "--null",
                   "--name-only", "--show-origin", "--show-scope", "--show-names", "--bool", "--int", "--bool-or-int",
                   "--bool-or-str", "--path", "--expiry-date", "--fixed-value"}  # R-C1: git config options with no value
   ```
2. **Line 154, replace** `_MARKS = re.compile(r"['\"\\,\[\]<>{}]|[^\S \t\n]")  # R-W1: where the quote-blind view and bash's argv can differ` with the line below (no indentation). It adds a backtick, `(` and `#` to the first character class; the comment does not change. Line 155 `` _SPLIT = re.compile(r"[\s;&|(){}`'\"\\,\[\]<>]+") `` stays below.
   ```text
   _MARKS = re.compile(r"['\"\\,\[\]<>{}`(#]|[^\S \t\n]")  # R-W1: where the quote-blind view and bash's argv can differ
   ```
3. **After line 461, insert 18 lines.** Line 459 is `    return k < n and toks[k].casefold() not in ("show", "get-url")` (the end of `remote_writes`), lines 460–461 are blank, line 462 `def git_split(v):` stays below. The block is `def config_read` (no indentation; its body 4 and 8 spaces) and ends with two blank lines.
   ```text
   def config_read(toks, k):
       """R-C1 (T049): True when the `git config` call whose first argument is toks[k] only reads. git 2.54 takes a
       subcommand only as that first argument and stops reading options at the first argument that is not an option, so
       a read counts only there: `get` or `list` at toks[k], or a CONFIG_READS option among the options from toks[k] on
       when each of the others is in CONFIG_FLAGS or is one `--name=value` token. Any other option may take the next
       argument as its value (`--comment --get`) or write, so it ends the exemption (fail closed)."""
       if toks[k:k + 1] in (["get"], ["list"]):
           return True
       read = False
       while k < len(toks) and toks[k].startswith("-"):
           if toks[k] in CONFIG_READS:
               read = True
           elif toks[k] not in CONFIG_FLAGS and not (toks[k].startswith("--") and "=" in toks[k]):
               return False
           k += 1
       return read


   ```
4. **Line 627, replace** `    reads = keys = None  # R-P5: does the rest of the segment from index x hold a read flag / a config key` with the line below (4 spaces of indentation). Line 626 `            i += 1` stays above; line 628 `    i = 0` stays below.
   ```text
       keys = None  # R-P5: does the rest of the segment from index x hold a config key
   ```
5. **Lines 671–678, replace** these eight lines (from `        if sub == "config":` to `                deny(PUSH_DENY)`; line 675 is `                    reads[x] = reads[x + 1] or toks[x] in CONFIG_READS`, line 677 `            if keys[j + 1] and not reads[j + 1]:`) with the seven lines below (8, 12, 16, 16, 20, 12 and 16 spaces of indentation in the file). Line 670 `        autocorrect_check(sub)` stays above; line 679 `        i = j + 1` stays below.
   ```text
           if sub == "config":
               if keys is None:
                   keys = [False] * (n + 1)
                   for x in range(n - 1, -1, -1):
                       keys[x] = keys[x + 1] or toks[x].casefold().startswith(CONFIG_KEYS)
               if keys[j + 1] and not config_read(toks, j + 1):
                   deny(PUSH_DENY)  # R-C1: a read counts only at git config's action position, from each view
   ```

Expected diff of `scripts/bash_gate.py` against the base (git's default diff): 4 hunks (anchors 1 and 2 share one), 7 lines removed and 27 added; without blank lines `grep -c '^-[^-]'` counts 7 and `grep -c '^+[^+]'` counts 25. The file has 719 lines after the edits and sha256 `7f5be7593f4213b0f39ac2c105ee08c6682589187d22bea6c7f8375a76f5db4a`. `CONFIG_READS`, `words`, `bash_argv`, `remote_writes`, `alias_check` and every rule but R-P5 do not change. Applied bottom-up to the base, the five blocks give the card writer's prototype byte for byte (checked by a script that reads this card).

**Test file anchor, `tests/push_gate_tests.sh`, after line 102, insert 51 lines** (the same base commit; the file has 222 lines and sha256 `0d4f7b823dd9d58b49490b197e97bc9cd961ab678918a289fbef9c3f215a1678`). Line 102 is the last R-P5 case:
```text
deny "config include.path"                  "$W" "$G config include.path /tmp/x"
```
Line 103 `# Deny: gh merge (R-P6)` stays below. The block has no indentation of its own (the Python lines of the growth check keep theirs):
   ```text
   # T049 R-C1: a read word counts only at git config's action position; the bash view also reads `#`, `(`, backticks
   TAB=$'\t'
   deny "config <push>url, then # get"         "$W" "$G config remote.origin.${P}url /tmp/x # get"
   deny "config insteadOf, then # get"         "$W" "$G config url./tmp/x.insteadOf $W.git # get"
   deny "config <push>url, value-pattern get"  "$W" "$G config remote.origin.${P}url /tmp/x get"
   deny "config url, then # --list"            "$W" "$G config remote.origin.url /tmp/x # --list"
   deny "config url, --get after the key"      "$W" "$G config remote.origin.url /tmp/x --get"
   deny "config url, -l after the key"         "$W" "$G config remote.origin.url /tmp/x -l"
   deny "--comment takes --get as its value"   "$W" "$G config --comment --get remote.origin.url /tmp/x"
   deny "--com (abbreviation) takes --get"     "$W" "$G config --com --get remote.origin.url /tmp/x"
   deny "config set, then # get"               "$W" "$G config set remote.origin.url /tmp/x # get"
   deny "config --add, then # --get"           "$W" "$G config --add remote.origin.${P}url /tmp/x # --get"
   deny "config <push>url, tab, # get"         "$W" "$G config remote.origin.${P}url /tmp/x${TAB}# get"
   deny "config, substitution, <push>url"      "$W" "$G config \$(true) remote.origin.${P}url /tmp/x"
   deny "config, backticks, <push>url"         "$W" "$G config \`true\` remote.origin.${P}url /tmp/x"
   deny "substitution before the <push>, main" "$W" "$G \$(true) $P origin HEAD:main"
   deny "backticks before the <push>, main"    "$W" "$G \`true\` $P origin HEAD:main"
   deny "config <push>url; a later --get"      "$W" "$G config remote.origin.${P}url /tmp/x; $G config --get user.name"
   allow "config --local --get"                "$W" "$G config --local --get remote.origin.url"
   allow "config --show-origin --get"          "$W" "$G config --show-origin --get $P.default"
   allow "config --type=bool --get"            "$W" "$G config --type=bool --get $P.autoSetupRemote"
   allow "config get, then a comment"          "$W" "$G config get remote.origin.url # read"
   allow "config --get-all, 2>/dev/null"       "$W" "$G config --get-all remote.origin.$P 2>/dev/null"
   allow "log, then a comment"                 "$W" "$G log -1 # last"
   allow "rev-parse in backticks"              "$W" "echo \`$G rev-parse HEAD\`"
   # T049 growth: config_read walks the options once; `#`, `(` and backticks now send the text to the bash view
   python3 - "$S/bash_gate.py" "$W" "$G" <<'PYC' || FAIL=1
   import json, subprocess, sys, time
   hook, w, g = sys.argv[1:4]
   cases = [("config options", lambda k: g + " config" + " -z" * k + " --get remote.origin.url"),
            ("config reads", lambda k: (g + " config --get remote.origin.url; ") * k),
            ("comments", lambda k: (g + " status # x\n") * k),
            ("substitutions", lambda k: "echo `true` $(true); " * k + g + " status")]
   bad = 0
   for name, make in cases:
       t = {}
       for k in (5000, 40000):
           data = json.dumps({"tool_name": "Bash", "cwd": w, "tool_input": {"command": make(k)}})
           runs = []
           for _ in range(3):
               s = time.perf_counter()
               subprocess.run([sys.executable, hook], input=data, capture_output=True, text=True, timeout=60)
               runs.append(time.perf_counter() - s)
           t[k] = min(runs)
       ratio = t[40000] / t[5000]
       ok = t[40000] < 3 and ratio < 20
       bad |= not ok
       print(chr(0x2714 if ok else 0x2718) + " growth %s: t(5000)=%.3fs t(40000)=%.3fs ratio=%.2f"
             % (name, t[5000], t[40000], ratio))
   sys.exit(1 if bad else 0)
   PYC
   ```
Nothing else in the file changes. Expected diff: 1 hunk, 0 lines removed and 51 added; the file has 273 lines after the edit and sha256 `c9fc235d84ba85360aa40d0ed6d8e64141a829d29bc9413a67d223f577b18273`.

## Rules (allowlist, fail closed)
- **R-W0, scope:** every rule sits behind `card_path(cwd)`: a session with no `.delix/card` is unchanged. Both views still feed every rule and a deny in either wins (T047 D1).
- **R-C1, a `git config` read counts only at its action position (T049, replaces R-P5's "a read flag anywhere after `config`"):** `config_read(toks, k)` is True only when `toks[k]`, the first argument after `config`, is `get` or `list`, or when the run of options that starts at `toks[k]` holds a `CONFIG_READS` option and each of its other options is in `CONFIG_FLAGS` or is one `--name=value` token. The run ends at the first argument that does not start with `-`. Any other option ends the exemption: it may take the next argument as its value (`--comment`, `-f`, `--blob`, `-t`, `--default`, and their abbreviations) or write (`--add`, `--replace-all`, `--unset`). R-P5 denies with `PUSH_DENY` when a token from `toks[j + 1]` on starts with one of `CONFIG_KEYS` (unchanged) and `config_read` is False. A word after the key is never a read: git takes it as the value or the value pattern of a write (the third positional argument is a write). The rule is the same in both views; it reads exact positions, so it relies on the bash view for every text where the loose view's positions can differ (R-W1).
- **R-W1, where the views can differ (`_MARKS`, T047; T049 adds three characters):** the bash view runs when the text holds a quote, a backslash, `,`, `[`, `]`, `<`, `>`, `{`, `}`, a blank other than space, tab or newline, and now also a backtick, `(` or `#`. The loose view keeps the words of a comment, and it cuts a segment at a backtick or at `(` and `)`, so `git X $(...) Y` reaches the rules as `git X $` and `Y`; the bash view reads a comment as no words and a substitution as its own segment, and an unquoted word of substitutions only is no argument (T048 R-W7). The loose view is unchanged.
- **Messages:** `PUSH_DENY` and every other message do not change.
- **Regex discipline:** no new pattern. `_MARKS` keeps its two alternatives, a character class and `[^\S \t\n]`; they share no character (the first class holds no blank), and the hook calls `_MARKS.search` once per text. `config_read` is a loop with no regex; it visits each option of the run once, and the outer R-P2 loop goes on after `config`, so a segment is walked in linear time.
- **Known false positives (fail closed):**
  - a `git config` read with an R-P5 key whose run of options holds an option outside `CONFIG_FLAGS` before the read option, such as `git config -f <file> --get remote.origin.url`, a short-option bundle (`-zl`) or an abbreviation (`--glob`): main allowed these, this card denies them; use `--file=<file>`, the full flag, or `git remote get-url origin`;
  - `git config remote.origin.url` with one argument (git's legacy read) denies on main and here (O1);
  - unquoted `$(` nested deeper than about 500 levels now denies with `DEEP_DENY` (main passed it: the bash view did not run without a mark; T048 R-W6, D7). 600 levels pass.

## Decisions (card writer, 2026-11-14; the lead records the K-number in the spec)
- **D1, git's own reading of `git config` (measured, git 2.54, temp repos).** The subcommand is only the first argument: `git config --local get <key>` and `git config -f .git/config get <key>` take `get` as a key and fail. In the legacy form option parsing stops at the first argument that is not an option: `git config <key> <url> --get`, `… -l` and `… get` write `<url>` (the last word is the value pattern). An option that takes a value takes the next argument, also when it looks like an action: `git config --comment --get <key> <url>`, `--com --get` and `--comm --get` write, with `--get` as the comment; `--default --get --get <key>` reads. `--get`, `--get-all`, `--get-regexp`, `--local --get`, `--show-origin --get`, `-z --get`, `--type bool --get`, `get --all <key>` read; `--list`, `-l`, `get` and `list` with too many arguments fail with exit 129 and write nothing. A read option together with a write option fails ("cannot be used together"). So a read counts only before the first argument that is not an option, or as the first argument.
- **D2, a flag allowlist, not a list of the options that take a value.** parse-options takes any unambiguous abbreviation of a long option, so the options that can swallow `--get` are open-ended (`--com`, `--comm`, …). `CONFIG_FLAGS` lists the 19 options of `git config -h` (git 2.54) that take no value and are not actions: the four file locations, `--includes` and `--no-includes`, the six display options, the six type flags and `--fixed-value`. A one-token `--name=value` cannot take the next argument, so it stays in the run. Everything else ends the exemption, which fails closed (memory rule: an allowlist first). The card writer's count of `git config` calls with an R-P5 key in this user's local Claude Code transcripts: 15 calls; the read shapes were `--get`, `--get-all` and `--show-origin --get`, all allowed here.
- **D3, "read from the bash view, no allow exception for the loose view".** The brief asks that a read word count only where bash puts it and that the loose view grant no exception of its own. Both views now apply the same position rule, and a deny in either wins, so the loose view can only make the hook deny, never allow, where the bash view runs. The bash view now runs for every text where the loose view's positions can differ at `git config` (comments, substitutions, besides T047's marks). Without one of those characters the two views give the same words before the key (the loose view differs only by splitting on `,`, `[`, `]`, `{`, `}` and quotes, all marks). Alternative: tag each segment with its view and skip R-P5's read check in the loose view; that changes what `words` returns for its two callers (`alias_check` too), and on the card writer's probes it denies nothing more.
- **D4, `(` and the backtick in `_MARKS` (found while writing this card).** Without a mark the loose view alone reads a command, and it splits a segment at a substitution: `git config $(true) <key> <url>` reaches R-P5 as `git config $` (no key) and passed main, and so did `git $(true) <push> origin HEAD:main` and the backtick forms, which pushed `main` in the probe (D9). With `(` and the backtick as marks the bash view reads those commands as `git config <key> <url>` and `git <push> origin HEAD:main`. `#` is a mark for the same reason: the loose view keeps a comment's words. `$` alone is not added: a variable is a word in both views (O2). This widens the brief from R-P5 to every rule; it is one line and the same mechanism (Lead decision 1).
- **D5, a later command on the same line does not count (measured).** `git config <key> <url>; git config --get user.name` (also with `&&`, `|` or a newline) denies on main and here: `reads` was computed per segment, and `;`, `&`, `|` and a newline end a segment in both views. One regression case keeps it (case 16).
- **D6, the third positional argument is a write** (D1): `git config <key> <url> get` writes, so a word after the key never counts as a read.
- **D7, no new allow.** `git config <key>` with one argument is git's legacy read and still denies (O1): allowing it is outside the brief. The card adds no allow that main did not have.
- **D8, the test file.** `tests/push_gate_tests.sh` holds the R-P5 cases (lines 95–102) and `PUSH_DENY`; the new block goes right after them, as one insertion. It uses the file's helpers and words (`$G`, `$P`, `$W`) and one new word, `TAB`. Its growth check is a block of its own (4 shapes, k = 5000 and 40000, the least of 3 runs, t(40000) < 3 s and ratio < 20); the file's ReDoS block (lines 196–221) does not change. The new lines are ASCII: the Python block prints the marks with `chr(0x2714)` and `chr(0x2718)`.
- **D9, evidence (card writer, Python 3.9.6, bash 3.2.57, git 2.54, Mac).**
  - Probes with the real hook, then real bash and git in a throwaway card repository with a local bare `origin` and a second local bare repository (`probe.sh` and `forms1.txt` in `T049-proto/` of the shared notes folder): 32 forms. 17 pass main and write `remote.origin.url`, `remote.origin.pushurl` or `url.<x>.insteadOf` (the own-branch push then lands in the second repository) or push `main`; the prototype denies all 17. 3 controls (a plain write, `-f .git/config`, a quoted URL before the comment) and the 4 later-command forms deny on both. The 7 read forms (`--get`, `get`, `--get-all`, `--local --get`, `-l`, `--get-regexp`, `get --all`) pass on both; `git config <key>` denies on both.
  - Everyday commands with `#`, `(`, a backtick or `$(` (`daily.py`): 24 commands, the same verdict on main and on the prototype (22 allow; `git config remote.origin.url` and `git <push> origin HEAD # own branch` deny on both).
  - Timing (`redos.py`): `_MARKS.search` on 250,000 and 2,000,000 characters with no match, then one: ×8 input gives ×7.8 to ×8.3 time on Python 3.9.6 and 3.13.13, the same as the old pattern. The whole hook on 6 shapes built from the new marks and the option run (k = 5000 and 40000): ratios 1.05 to 3.44, at most 0.38 s, verdicts unchanged.
  - Tests: the new block on the base gives 15 `✘` / 145 `✔` (Steps 1); on the prototype `tests/push_gate_tests.sh` gives 160 `✔`, and all 16 `tests/*_tests.sh` exit 0 on Python 3.9.6 and on 3.13.13 through a PATH shim (`suites.txt` in `T049-proto/`).

## Lead decisions
1. **Scope of `_MARKS` (D4), decided (K316):** the backtick, `(` and `#`, as written; cases 12 to 15 stay.
2. **Order and anchors, decided (K316, the user):** before T042; the lead checked the anchors on `bdde464`.
3. **Acceptance:** the lead runs `probe.sh` with `forms1.txt` and `daily.py` from `T049-proto/` on the PR head, as in T048 (K307).
4. **Publication of the card, decided (K313, K316):** it enters main at dispatch, so the window is dispatch to merge.

## Out of scope (each with the reason)
- **O1, `git config <key>` with one argument:** a read that denies on main and here (D7).
- **O2, the T048 Out of scope:** brace expansion, variables (a key held in a variable), globs, `eval`, ANSI-C escapes, command output and the bash grammar of T048 O3, unchanged.
- **O3, a git config file written by a command other than git** (`printf … >>`, `sed -i`): K312, a Known limit; not a word rule.
- **O4, a comment after the own-branch push** (`git <push> origin HEAD # x`) denies in the loose view (more than two words after the options), on main and here.

## Interfaces
- Consumed: `CONFIG_KEYS`, `CONFIG_READS`, `PUSH_DENY`, `deny`, `words`, `bash_argv` (through `words`), the R-P2 loop.
- Produced: `CONFIG_FLAGS`; `config_read(toks, k)` returning a bool.
- Removed: the `reads` list of the R-P2 loop.

## Global Constraints (verbatim)
- K313: "Kod düzeltmesi (R-P5) ayrı bir 🔐 Tier 3 kartıdır; tasarımı o kartla yayımlanır."
- K316: "T049, 0.7.0 sürümünden (T042) önce gelir; sıra T046, T049, T042. K314'teki sırayı değiştirir."
- Repo hook rules: no new regex with overlapping alternation; a growth test at two sizes; the test driver lives in the test file with the trigger words assembled at run time; the existing tests are not changed.
- Python 3.9 stdlib; no version-dependent behaviour (the Mac runs 3.9.6, CI 3.12; run the suites on 3.13 as well). ASCII only in the new code and test lines; no invisible character.

## Steps
1. Insert the test block per the test file anchor. Run `bash tests/push_gate_tests.sh` and see **red**: 15 `✘` lines (cases 1 to 15, which main allows), 145 `✔` lines (the file's 133, cases 16 to 23 and the 4 growth lines), `FAILED`, exit 1 (the card writer's run on the base; a different count means a case differs from the list, so say so in the report).
2. Edit `scripts/bash_gate.py` bottom-up per Edit anchors 5 to 1; run the `ast.parse` one-liner after each.
3. Run `bash tests/push_gate_tests.sh` and see **green**: 160 `✔` lines, no `✘`, `ALL PASSED`. Run it again on Python 3.13 through a PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 2 paths by name. Commit `T049: R-P5 counts a git config read only at its action position; the bash view reads #, ( and backticks`. No command of yours, and no commit message, holds `git` followed by `push`, `update-ref` or `remote` as words on one line, except the one push below. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd`. Open a PR with `--body-file` and a `## How I tested` section.
6. After step 2 your own session may run the edited hook (if the plugin loads from this worktree): a `git config` read with an R-P5 key passes only as `get`/`list` first or with a read option in the leading options; a command with `#`, `(` or a backtick is read by the bash view too. Keep to commands the rules allow.

## Tests (`tests/push_gate_tests.sh`, inserted after line 102; `ALL PASSED` at the end)
- **Words and helpers:** the file's own (`G`, `P`, `W`, `PUSH_DENY`, `allow`, `deny`; `deny` without a fourth argument expects `PUSH_DENY`); `TAB=$'\t'` is new. `/tmp/x` is a URL that is never contacted; `$W.git` is `origin`'s URL in the setup.
- **Cases** (number, label as printed, the command as in the bash string, the expected result; cwd `W`). `\$` and `` \` `` are a literal `$` and backtick in the bash string.
  - *R-C1, a read word after the key, in a comment or as an option's value (main allows 1 to 11)*
    - 1 config <push>url, then # get: `$G config remote.origin.${P}url /tmp/x # get` → `PUSH_DENY`
    - 2 config insteadOf, then # get: `$G config url./tmp/x.insteadOf $W.git # get` → `PUSH_DENY`
    - 3 config <push>url, value-pattern get: `$G config remote.origin.${P}url /tmp/x get` → `PUSH_DENY`
    - 4 config url, then # --list: `$G config remote.origin.url /tmp/x # --list` → `PUSH_DENY`
    - 5 config url, --get after the key: `$G config remote.origin.url /tmp/x --get` → `PUSH_DENY`
    - 6 config url, -l after the key: `$G config remote.origin.url /tmp/x -l` → `PUSH_DENY`
    - 7 --comment takes --get as its value: `$G config --comment --get remote.origin.url /tmp/x` → `PUSH_DENY`
    - 8 --com (abbreviation) takes --get: `$G config --com --get remote.origin.url /tmp/x` → `PUSH_DENY`
    - 9 config set, then # get: `$G config set remote.origin.url /tmp/x # get` → `PUSH_DENY`
    - 10 config --add, then # --get: `$G config --add remote.origin.${P}url /tmp/x # --get` → `PUSH_DENY`
    - 11 config <push>url, tab, # get: `$G config remote.origin.${P}url /tmp/x${TAB}# get` → `PUSH_DENY`
  - *R-W1, a substitution between `git` and its words (main allows 12 to 15)*
    - 12 config, substitution, <push>url: `$G config \$(true) remote.origin.${P}url /tmp/x` → `PUSH_DENY`
    - 13 config, backticks, <push>url: ``$G config \`true\` remote.origin.${P}url /tmp/x`` → `PUSH_DENY`
    - 14 substitution before the <push>, main: `$G \$(true) $P origin HEAD:main` → `PUSH_DENY`
    - 15 backticks before the <push>, main: ``$G \`true\` $P origin HEAD:main`` → `PUSH_DENY`
  - *Regression cases (main and the prototype give the same result)*
    - 16 config <push>url; a later --get: `$G config remote.origin.${P}url /tmp/x; $G config --get user.name` → `PUSH_DENY` (D5)
    - 17 config --local --get: `$G config --local --get remote.origin.url` → `allow`
    - 18 config --show-origin --get: `$G config --show-origin --get $P.default` → `allow`
    - 19 config --type=bool --get: `$G config --type=bool --get $P.autoSetupRemote` → `allow`
    - 20 config get, then a comment: `$G config get remote.origin.url # read` → `allow`
    - 21 config --get-all, 2>/dev/null: `$G config --get-all remote.origin.$P 2>/dev/null` → `allow`
    - 22 log, then a comment: `$G log -1 # last` → `allow`
    - 23 rev-parse in backticks: ``echo \`$G rev-parse HEAD\` `` → `allow`
- **Growth** (4 `✔` lines; for each input k = 5000 and k = 40000, the least of 3 runs per size; expect t(40000) < 3 s and t(40000) / t(5000) < 20; print both times and the ratio), with `g` = `$G`:
  - config options: `g + " config" + " -z" * k + " --get remote.origin.url"`
  - config reads: `(g + " config --get remote.origin.url; ") * k`
  - comments: `(g + " status # x\n") * k`
  - substitutions: ``"echo `true` $(true); " * k + g + " status"``

## Verification command → expected output
- `bash tests/push_gate_tests.sh` → last line `ALL PASSED` · `bash tests/push_gate_tests.sh | grep -c '^✔'` → `160`
- `bash tests/push_gate_tests.sh | grep growth` → 4 lines, each `ratio` below 20 and `t(40000)` below 3 s (card writer's prototype: Python 3.9.6 ratios 1.8 to 5.5, at most 0.95 s; Python 3.13.13 ratios 1.4 to 4.6, at most 0.68 s)
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/push_gate_tests.sh | tail -1` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, on Python 3.9.6 and through the 3.13 shim
- `bash tests/site_tests.sh` → exit 0 (site files are untouched)
- `claude plugin validate .` → passes
- `git diff origin/main -- tests | grep -c '^-[^-]'` → `0` · `git diff origin/main -- tests/push_gate_tests.sh | grep -c '^+[^+]'` → `51`
- `git diff origin/main -- scripts/bash_gate.py | grep -c '^-[^-]'` → `7` · `git diff origin/main -- scripts/bash_gate.py | grep -c '^+[^+]'` → `25`
- `git diff -U0 origin/main | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and (len(l) > 121 or any(ord(c) > 126 for c in l))]"` → no output
- `git diff --stat origin/main` → exactly the 2 Files
- **Lead, on the PR head (not the implementer's):** `probe.sh` with `forms1.txt` → the 17 forms deny, the 7 reads pass; `daily.py` → 0 verdicts changed against main.

## Review Focus
- R-C1 against git's parser (D1): `get`/`list` count only as the first argument; a read option counts only in the leading run of options and only when every other option there is in `CONFIG_FLAGS` or `--name=value`; a word after the key never counts.
- `CONFIG_FLAGS` (D2): each entry is a `git config -h` option of git 2.54 that takes no value and is not an action; an abbreviation or an option that takes a value ends the exemption.
- `_MARKS` (D3, D4): the three added characters send a command to the bash view; the loose view, `words`, `bash_argv` and every other rule are unchanged; a deny in either view still wins.
- No existing test line changes; the 16 suites pass on Python 3.9.6 and 3.13; no new allow beyond main's (D7); the new false positives are the ones in Rules.
- Daily commands still pass: cases 17 to 23 and the 24 commands of D9.

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `README.md`, `README.tr.md`, `site/**`, every other test file and every existing line of `tests/push_gate_tests.sh`.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a regex, a dependency, an option or a rule beyond R-C1, the `_MARKS` line and `CONFIG_FLAGS`. Do not allow `git config <key>` with one argument (O1). If a case in Out of scope looks easy, write it in the report instead.
- Do not name a form that passes main in the PR title, the PR body or the commit message; refer to "this card's cases" (K313).
- No raw non-ASCII or invisible character in code or tests.
- Verification commands never put `git` followed by `update-ref`, `remote` or `push` as words in the command text, except the one push in Step 5.

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`, `bash --version`;
- the four growth lines;
- PR number and branch;
- assumptions;
- every pre-existing slow path or crash seen and not fixed.

Read only this card and spec K313, K316 and K317.

## Spec K entry (K317 in the spec)
```text
- **K317** (lead, 2026-11-17, geri alınır) T049 kartı (🔐 Tier 3, `scripts/bash_gate.py`; kart yazarı oturumu).
  - **R-C1:** R-P5'te bir okuma kelimesi yalnız `git config`'in eylem konumunda sayılır: ilk argüman `get` ya da
    `list`, ya da ilk seçenek dışı argümandan önceki seçeneklerde bir `CONFIG_READS` seçeneği; oradaki diğer her
    seçenek `CONFIG_FLAGS`'te (git 2.54'te değer almayan 19 seçenek) ya da tek parça `--ad=değer` olmalı. Başka bir
    seçenek muafiyeti bitirir (`--comment` ve kısaltmaları sonraki argümanı değer olarak alır). Anahtardan sonraki
    kelime hiç okuma sayılmaz; üçüncü konumsal argüman yazmadır (git 2.54'te ölçüldü).
  - **Görünümler:** kural iki görünümde aynıdır, birindeki ret kazanır. `_MARKS`'a ters tırnak, `(` ve `#` eklenir:
    bunları içeren metni bash görünümü de okur. Gevşek görünüm yorum kelimelerini tutar ve bir ikamede segmenti
    böler; bu karakterlerle kendi başına izin veremez. Görünümleri etiketlemek daha çok kod ister, daha çok reddetmez.
  - **Kapsam (lead kararı 1, K316):** ters tırnak ve `(` R-P5'in ötesine geçer: komut ile kelimeleri arasındaki ikame
    tabanda kuralların hepsinden geçiyordu. Üçü birden eklenir.
  - **Sıra ve onay (K316):** T046, T049, T042; Approved 2026-11-17 tahircengiz; lead çapaları `bdde464`'te
    doğruladı (iki dosya kartın sha256'larını verir; kırmızı 15 ✘ / 145 ✔, yeşil 160 ✔; 16 test dosyası iki Python
    sürümünde geçer). Kabul probu (`probe.sh`, `forms1.txt`, `daily.py`) lead'de PR ucunda koşar.
  - **Ölçüm:** 17 biçim main'den geçip `origin`'in URL anahtarlarını yazar ya da `main`'i gönderir; prototip 17'sini
    reddeder. 7 okuma biçimi ve 24 günlük komut iki tarafta aynı sonucu verir. Yeni test tabanda 15 ✘ / 145 ✔,
    prototipte 160 ✔; 16 test dosyası Python 3.9.6 ve 3.13.13'te geçer. `_MARKS` doğrusal (×8 girdi, ×7,8–8,3 süre).
  - **Yanlış pozitif (yeni, güvenli yön):** okumadan önce `CONFIG_FLAGS` dışı bir seçenek (`-f <dosya> --get`, `-zl`,
    kısaltma) R-P5 anahtarında reddedilir; 500 düzeyden derin tırnaksız `$(` artık `DEEP_DENY` alır.
  - **Yayın:** geçen biçimler yalnız kartta ve testte durur (K313); kart main'e dispatch'te girer (lead kararı 4).
```

## Docs handover
For the release card T042, after this card is merged (K316). K298 keeps README and site sentences out of this card. Copy the words as given. On the site a backticked word is a `<code>` element and `<`, `>` and `&` are HTML-escaped. The sentences describe what this card makes true and name no form that passed before it (K313); the lead checks them against the merged code first.

**H1, the R-P5 sentence** (README Bash paragraph, right after the sentence that ends "while `help.autocorrect` is on."; README.tr's twin after its `help.autocorrect` sentence; the same words in the site index bash_gate Implementer cell, EN and TR):
- EN: `A `git config` call that names an `alias.`, `remote.`, `push.`, `url.`, `include` or `help.` key is denied there unless git reads it as a read: `get` or `list` as its first argument, or a read option such as `--get` among the options before the key; a word after the key and a comment do not count (T049).`
- TR: `Orada `alias.`, `remote.`, `push.`, `url.`, `include` ya da `help.` anahtarını anan bir `git config` çağrısı, git onu okuma olarak okumuyorsa reddedilir: ilk argümanı `get` ya da `list` olmalı ya da anahtardan önceki seçeneklerde `--get` gibi bir okuma seçeneği bulunmalı; anahtardan sonraki kelime ve yorum sayılmaz (T049).`

**H2, the bash view sentence** (right after T048's sentence "A command nested too deep for the hook to read is denied with a message (T048)." and its twins, the same places):
- EN: `A command that holds a `#`, a `(` or a backtick is read by the bash view as well (T049).`
- TR: `İçinde `#`, `(` ya da ters tırnak geçen bir komutu bash görünümü de okur (T049).`

**H3, Known limits:** the `origin` URL item (K313, F5: "a URL for `origin` … written into the git config file in the same or an earlier call") widens as K315 says, because a command other than git still writes it (K312, O3) and the lead reproduced the `pushInsteadOf` and global-file routes:
- EN, replacing ``a URL for `origin` (`url`, `pushurl` or `url.*.insteadOf`) written into the git config file in the same or an earlier call``: ``a URL for `origin` (`url`, `pushurl`, `url.*.insteadOf` or `url.*.pushInsteadOf`) written into a git config file (the repository's, the global one or an included one) in the same or an earlier call``
- TR, replacing ``aynı ya da önceki bir çağrıda git ayar dosyasına yazılan bir `origin` URL'si (`url`, `pushurl` ya da `url.*.insteadOf`;``: ``aynı ya da önceki bir çağrıda bir git ayar dosyasına (reponun, global ya da include edilen) yazılan bir `origin` URL'si (`url`, `pushurl`, `url.*.insteadOf` ya da `url.*.pushInsteadOf`;``

The false-positive clause adds:
- EN: `a `git config` read of one of these keys with another option before the read option (use `--file=<file>` or `git remote get-url origin`)`
- TR: `bu anahtarlardan birini okuyan ve okuma seçeneğinden önce başka bir seçenek taşıyan `git config` çağrısı (`--file=<dosya>` ya da `git remote get-url origin` kullan)`

## Review findings (filled by the lead)
- Round 1 (PR #78, head `ef0860668718cba0ab28cb0a70b14fb167f79b8a`, 2026-11-17): qa `ACCEPT` (0 P0, 0 P1), security
  `🔐 HUMAN_APPROVAL` (1 Low, already on main; 2 unsure notes). Lead gates on the clean `git archive` of the head:
  both files equal the lead's prototype byte for byte and carry the card's sha256s; exactly the 2 Files, 0 removed
  and 51 added test lines; 16 suites exit 0 with no `✘` on Python 3.9.6 and 3.13.13; `tests/push_gate_tests.sh` 160
  `✔`, 8 growth lines pass; `claude plugin validate .` passes; the Stop gate gives `[exit 0]` twice; CI `check` and
  `test` green. Acceptance (K317): `probe.sh` with `forms1.txt`, main against the head, real git 2.54 and bash
  3.2.57 on temp repos (no network): the 17 forms that pass main deny on the head, the 7 reads pass on both, the
  controls deny on both; `daily.py` 0 of 24 verdicts changed.
  - Low (security, reproduced by the lead, already on main, no fix here, K318): a name of git's config command
    that R-P5 does not read (the class T044 closed for `update-ref` and `remote`) still writes `origin`'s URL keys
    on main and on the head, and the own-branch push lands in the other repository. The diff does not add it; the
    card's Don'ts keep the fix out. Details with the lead; follow-up card.
  - Note (security unsure, reproduced by the lead, no change): an option value built from a variable or from
    command output can still hide a write in front of a read option, on main and on the head. Out of scope O2
    (variables, command output), a Known limit.
  - Note (P2, no change): the `words()` docstring still lists the old marks.
  - Evidence: `rev78/` files in the lead's scratchpad (not in the repo).
