# T044 🔐 — bash_gate: an implementer session writes no git ref and no remote; a `delix.json` that is not an object and a non-UTF-8 byte deny with a message

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T044 | M | 3 | backend | 15 | open |

**🔐 Approved:** 2026-11-13 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`; `scripts/common.py` `matches` returns that entry for it). `tests/ref_gate_tests.sh` matches `test_paths` (`tests/**`) and no protected entry, and it is a new file.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-13 ("Evet, T044 için onay veriyorum", said in the card-writing session). The lead commits it to main before dispatch; the session branches from that commit.
> - The session is interactive and the user opens it, as for T041.
> - It closes the part of spec §6 "Kalan risk" that K296 names: a card session rewriting the local tracking refs that the board trusts. The lead session has no `.delix/card`, so the lead's own `git remote set-head origin -a` (spec §6) keeps working.
> - It is defence in depth, not a boundary: the rule is a check on the command's words (see Out of scope).

**Goal (1 sentence):** In an implementer worktree `bash_gate.py` denies `git update-ref` and every `git remote` form except plain `git remote`, `-v`/`--verbose`, `show` and `get-url` (so no `set-head`, `set-url`, `add`, `remove`, `rename`, `update`, `prune`), also through an alias or the dashed `git-update-ref` / `git-remote` name, and it decides with a message, instead of raising, when `docs/delix/delix.json` is not a JSON object or a git setting holds a byte that is not UTF-8. · **Spec:** `docs/delix/specs/C-board-visibility.md` §6 (lines 187–214), K296, K298; T041 Review findings (`docs/delix/tasks/T041-bash-gate-card-push.md` lines 216–221, 252–254, 263–267)

**Docs/site:** none in this card. K298 makes this an exception to CLAUDE.md's "same change" rule: T046 (wave 16) writes the README, README.tr and site sentences from the `## Docs handover (T046)` section at the end of this card. Do not touch `README.md`, `README.tr.md` or `site/**`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (nine edits, see Edit anchors)
- Create: `tests/ref_gate_tests.sh`

## Edit anchors (base origin/main 4246815, full SHA 42468157937a94a7aeb85b6aa451ba99175fe12a)
Line numbers are from that commit. Match the quoted content before you edit each place. If it differs, stop with `NEEDS_CONTEXT`. Edit bottom-up (anchor 9 first, anchor 1 last) so the line numbers above you hold. Every new line is at most 120 characters. After each edit run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output: if this repo's plugin loads from your worktree, a syntax error would block your own Bash.

Python is indentation-sensitive. The code blocks below sit inside list items, so every code line carries exactly 3 extra leading spaces that belong to the list: remove those 3 and keep the rest. The text for anchors 5, 6 and 8 gives the whole line.

1. **Lines 3–4, replace the end of the docstring.** Line 2 (`"""PreToolUse (Bash): reviewer roles may run only read-only commands; in the implementer worktree, gitleaks runs`) stays. Current lines 3–4:
   ```text
   before commit, shell writes to protected paths are blocked, a push goes only to the card's own branch on origin and
   `gh pr merge` is denied."""
   ```
   New lines 3–4:
   ```text
   before commit, shell writes to protected paths are blocked, a push goes only to the card's own branch on origin,
   `gh pr merge` is denied, and git commands that write refs or remotes are denied."""
   ```
2. **After line 113, insert three lines (no indentation on the first).** Line 113 is `cfg = delix_json(cwd)`; line 114 `protected = cfg.get("protected_paths") or []` stays below the insert.
   ```text
   if not isinstance(cfg, dict):  # R-U4: the rules below read cfg; a list, string, number or null is not a config
       deny("delixcrew: docs/delix/delix.json is not a JSON object; Bash stays blocked in this card worktree until the "
            "user fixes it from their own terminal")
   ```
3. **After line 129, insert four lines.** Line 129 is `MERGE_DENY = "delixcrew: gate 2 (merge) is the user's; an implementer session does not run gh pr merge"`; line 130 `GIT_ARG_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--attr-source",` stays below.
   ```text
   REF_DENY = ("delixcrew: an implementer session does not write git refs or change remotes (update-ref, remote set-head, "
               "set-url, add, remove); those run from the user's own terminal")
   ENC_DENY = ("delixcrew: a git setting or ref name holds a byte that is not UTF-8, which this hook cannot read; "
               "the command is denied until the user removes it from their own terminal")
   ```
4. **After line 163, insert two functions.** Line 161 is `    return segs` (end of `words`); lines 162–163 are blank; line 164 is `def git_unset(*args):`. Insert between line 163 and line 164, ending with two blank lines:
   ```text
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


   ```
5. **Line 167, replace.** In `git_unset`, `    r = git(cwd, *args)` becomes `    r = git_text(*args)`. Line 168 (`    if r is None or r.returncode not in (0, 1) or (r.returncode == 1 and r.stdout):`) stays.
6. **Line 180, replace.** In `push_branch`, `        r = git(cwd, "symbolic-ref", "--quiet", "--short", "HEAD")` becomes `        r = git_text("symbolic-ref", "--quiet", "--short", "HEAD")`. No other `git(cwd, …)` call in this file stays: `git` itself is still imported on line 11 and used only by `git_text`.
7. **After line 236, insert two lines (16 and 20 spaces of indentation in the file).** Lines 235–236 are `                if v.lstrip().startswith("!") or {"push", "send-pack", "http-push"} & set(vt):` and `                    deny(PUSH_DENY)`; line 237 `                nxt.update(vt[:1])` stays below.
   ```text
                   if "update-ref" in vt or (vt[:1] == ["remote"] and remote_writes(vt, 1, len(vt))):  # R-U3
                       deny(REF_DENY)
   ```
8. **Line 295, replace.** `        elif t.rsplit("/", 1)[-1] in ("git-push", "git-send-pack"):` becomes `        elif t.rsplit("/", 1)[-1] in ("git-push", "git-send-pack", "git-update-ref", "git-remote"):`. Line 296 (`            j, gopt, sub = i, False, t.rsplit("/", 1)[-1][len("git-"):]`) stays.
9. **After line 299, insert two lines (8 and 12 spaces of indentation in the file).** Line 299 is `            continue` (end of the `else:` of the command-name chain); line 300 `        if sub in ("send-pack", "http-push", "subtree"):` stays below.
   ```text
           if sub == "update-ref" or (sub == "remote" and remote_writes(toks, j + 1, n)):  # R-U1, R-U2
               deny(REF_DENY)
   ```

Expected diff of `scripts/bash_gate.py` against the base: 5 lines removed (anchors 1, 5, 6, 8) and 32 added, of which 4 are blank (the two blank lines either side of the new functions), so `grep -c '^+[^+]'` counts 28. `git diff origin/main -- scripts/common.py` is empty.

## Rules (allowlist, fail closed)
- **R-U0, scope:** every rule sits after `card_path(cwd)` (line 110): a session with no `.delix/card` is unchanged. R-U1 to R-U3 run in the R-P2 pass, so the same token rules apply: `git` or a token ending in `/git`, `-C`, `-c` and the other global options as R-P2 reads them, command names and subcommands compared casefolded, quotes and backslashes removed, the dashed names handled like `git-push`.
- **R-U1, ref update:** subcommand `update-ref` (also the dashed name `git-update-ref`, with or without a path) is denied with `REF_DENY`, whatever its arguments.
- **R-U2, remote:** subcommand `remote` is allowed only when, after any run of `-v` / `--verbose` tokens, no token follows or the next token is `show` or `get-url`. Anything else is denied with `REF_DENY`: `set-head`, `set-url`, `add`, `remove`, `rm`, `rename`, `update`, `prune`, `set-branches`, `-h` and every name git may add later (fail closed). The dashed name `git-remote` follows the same rule. A `git remote` command still counts as "another git command" for R-P3b, so it cannot share a line with a push.
- **R-U3, aliases:** the alias list that R-P4 reads once per command is checked for these two words too. A value that holds the token `update-ref`, or whose first token is `remote` and fails R-U2, denies with `REF_DENY` when the alias is used, also through a chain (`u2 = ur`, `ur = update-ref -d`). `PUSH_DENY` still wins for a `!` value or a push token.
- **R-U4, `delix.json`:** after `card_path` and before `cfg.get`, a `docs/delix/delix.json` that parses to something other than a JSON object (a list, string, number, `true`, `null`) denies every Bash command in that worktree with the message in anchor 2. The hook decides itself, so the result does not depend on how Claude Code treats a crashing hook. A missing file, `{}`, and a file that does not parse are not covered (see Out of scope).
- **R-U5, non-UTF-8 byte:** the two git reads of the push rule (`git_unset`, `push_branch`) go through `git_text`. A `UnicodeDecodeError` denies with `ENC_DENY`. These reads are the alias list, `remote.origin.push`, `branch.<b>.merge`, `help.autocorrect`, the command list and the two `symbolic-ref` calls. A command that reads none of them (no git word, or a push, which reads only `symbolic-ref`, `remote.origin.push` and `branch.<b>.merge`) is unaffected unless one of those holds the byte. `scripts/common.py` is not changed.
- **Messages (exact):**
  - `REF_DENY` = `delixcrew: an implementer session does not write git refs or change remotes (update-ref, remote set-head, set-url, add, remove); those run from the user's own terminal`
  - `ENC_DENY` = `delixcrew: a git setting or ref name holds a byte that is not UTF-8, which this hook cannot read; the command is denied until the user removes it from their own terminal`
  - R-U4 message = `delixcrew: docs/delix/delix.json is not a JSON object; Bash stays blocked in this card worktree until the user fixes it from their own terminal`
- **No new regex.** Every new step is a token comparison or a loop over tokens. `remote_writes` skips one run of `-v` tokens and returns; runs of two `git remote` commands cannot overlap because a `-v` run ends at the next non-`-v` token.
- **Known false positives (fail closed):**
  - the words `git` then `update-ref` on one line of a heredoc body, an `echo` or a commit message (the same class as the push words);
  - a `git remote` form outside the read forms, including `git remote update` and `git remote prune` (to refresh refs run `git fetch`);
  - a non-UTF-8 byte in a git setting stops every git subcommand that reads the alias list (all but a push) until the user removes it; a `delix.json` that is not an object stops all Bash in the card worktree.

## Decisions (card writer, 2026-11-13; the lead records the K-numbers in the spec)
- **D1, allowlist for `git remote`:** K296 names `set-head`, the T041 notes name `set-url`. `remove` plus `add`, or `rename`, re-point `origin` the same way `set-url` does, and a denylist of two words would lose a review round (the repo's filter lesson). So the read forms are listed and the rest denies.
- **D2, `set-url` is in scope** because it undermines T041's own guarantee: the push rule lets `origin <branch>` through, and `origin` is only the user's repository while `remote.origin.url` is. T041's R-P5 already denies `git config remote.…` writes; this closes the porcelain.
- **D3, `common.py` stays unchanged.** The T041 round-4 note asked for a message instead of a traceback. Decoding with `errors="replace"` inside `common.git` would do it, but `scripts/trust.py:45–48` catches the `UnicodeDecodeError` from the same helper to treat a non-UTF-8 blob as different, and that branch would turn dead. The catch sits in `bash_gate.py` instead.
- **D4, a non-object `delix.json` denies all Bash** rather than reading it as `{}`: `{}` has no `protected_paths`, so the protected-path check would be silently off. Deny matches the fail-closed rule of the push rule. `docs/delix/delix.json` is the user's file, fixed from their own terminal.
- **D5, a new test file** (`tests/ref_gate_tests.sh`) instead of lines in `tests/push_gate_tests.sh`: no existing test file is touched, and the new file stays small.
- **D6, growth test with the least of 3 runs per size**, ratio limit 20 at ×8 input (linear is about ×4–×8, quadratic ×16–×64). No regex is added, but the repo rule asks for the measurement and the loop in `remote_writes` is new.

## Out of scope (each with the reason; T046 keeps the matching Known limits sentences)
- **O1, a git setting written to a config file by another command on the same line (such as `>>`):** K283 decided this is a known limit, not code. R-P1 drops redirection tokens, and the path can be built from a variable or `$(…)`, which is already out of reach ("words built from variables").
- **O2, the whole push line on an allowlist (K283 "takip işidir"):** a new rule class. Every non-git segment and every redirection on a push line would need an allowlist, which changes R-P1 (redirections are dropped today) and so every existing rule, and it denies common shapes such as a test run before a push. T041 needed four review rounds for a smaller change. A cross-call sequence is not a gap: the hook reads the branch when the push runs (T041 test "card on main"). It deserves its own card.
- **O3, a `gh` alias for `pr merge`:** `gh api` merge writes in any repository other than delixcrew's own, and an alias the user already has, stay open too. Denying `gh alias set` alone would not change what the rule can promise (K279: defence in depth; the merge click is the user's).
- **O4, other ways to write a ref or a file under the git directory:** not named in K296 or the T041 notes. For example the write form of `git symbolic-ref`, `git fetch` with a refspec into `refs/remotes/`, `git branch -f`, a shell write to a file under the git directory, a script. `git fetch` cannot be denied as a whole. The write form of `git symbolic-ref` is the closest sibling (the board reads `refs/remotes/origin/HEAD` with `symbolic-ref`): the lead may add it to this card before dispatch or open a follow-up.
- **O5, a `delix.json` that does not parse is read as `{}` by `common.delix_json`,** so `protected_paths` is empty and the Bash protected-path check does nothing. Measured by the card writer on base 4246815 with git 2.54.0 and Python 3.9.6: with the repo's `delix.json`, a redirect into the hook script is denied; with that file truncated, it is allowed. The fix has to tell a missing file from a broken one inside `common.delix_json`, which every hook uses, so it is a separate card. Same area: an object whose `protected_paths` is not a list.
- **O6, `scripts/write_gate.py` (lines 81–84) calls `cfg.get` on the same non-object value,** so the Write/Edit hook raises there. It is another protected file and its own card.
- **O7, the two `remote -v` reads at `scripts/bash_gate.py:56` and `:82`** decode with `text=True` and catch only `OSError` and `SubprocessError`. They run in every session, not in the card gate, and only inside the `gh issue` / `gh api` branches.

## Interfaces
- Consumed: `common.git(cwd, *args)` (no `GIT_*` env, `core.fsmonitor=false`, 5 s; raises `UnicodeDecodeError` on non-UTF-8 output because it decodes with `text=True`), `card_path`, `delix_json`, `deny`, and in `bash_gate.py`: `words`, `alias_check`, `git_unset`, `push_branch`, the R-P2 pass.
- Produced: `REF_DENY`, `ENC_DENY`, the R-U4 message; `remote_writes(toks, k, n)`; `git_text(*args)`.

## Global Constraints (verbatim)
- K296: "Kart oturumunda bu yazmaları `bash_gate` reddeder: 🔐 Tier 3 kart (`scripts/bash_gate.py` korunan yol), dispatch'ten önce kullanıcının o işe özel evet'i ve kartta `**🔐 Approved:**` satırı gerekir."
- K296: "(`scripts/bash_gate.py`, gerekirse `scripts/common.py`); kapsamı architect kartla sınırlar."
- §6: "Kalan risk: bir oturum yerel izleme ref'ini commit + `update-ref` ile yeniden yazabilir (kart oturumunda bunu ve `git remote set-head`'i rev 12'nin 🔐 ref yazma kartı reddeder; K296)".
- K283: "Satırın tamamını izin listesine bağlamak takip işidir."
- K298: "T044'ün README ve site cümleleri CLAUDE.md'nin "aynı değişiklik" kuralının istisnası olarak T046'da iner (T044 kartının `## Docs handover (T046)` bölümü)."
- Repo hook rules: no overlapping alternation (this design adds no regex); a timing check at two sizes; the test driver lives in the test file with the trigger words assembled at run time; the existing tests are not changed.
- Python 3.9 stdlib; no version-dependent behaviour. The one stdlib behaviour the rule relies on is that `subprocess.run(text=True)` raises `UnicodeDecodeError` on invalid bytes; the card writer saw that on 3.9.6 and 3.13.13. CI runs 3.12.
- No invisible or raw non-ASCII character in the new code or the test: the non-UTF-8 byte is written as the `printf` octal escape `\377`, never as a raw byte.

## Steps
1. Write `tests/ref_gate_tests.sh` (cases below). Run `bash tests/ref_gate_tests.sh` and see **red**: 39 `✘` lines, `FAILED`, exit 1 (the card writer's prototype on the base; a different count means a case differs from the table, so say so in the report).
2. Edit `scripts/bash_gate.py` bottom-up per Edit anchors 9 to 1; run the `ast.parse` one-liner after each.
3. Run `bash tests/ref_gate_tests.sh` and see **green**: 67 `✔` lines (63 cases and 4 growth lines), `ALL PASSED`. Run it again on Python 3.13 through a PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 2 paths by name. Commit `T044: bash_gate denies ref and remote writes in a card worktree (K296)`. No command of yours, and no commit message, holds `git` followed by `push`, `update-ref` or `remote` as words on one line, except the one push below. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd`. Open a PR with `--body-file` and a `## How I tested` section.
6. After step 2 your own session may run the edited hook (if the plugin loads from this worktree). Keep to commands the new rule allows: no `git remote` form beyond the read forms, no `update-ref`.

## Tests (`tests/ref_gate_tests.sh`, a new file; `ALL PASSED` at the end)
- **Words:** `G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"; HD=set; HD="${HD}-head"; UR=set; UR="${UR}-url"`. The file holds none of those words as one literal. The messages in the file are built from them.
- **Input:** build the hook input with Python `json.dumps` (never by string concatenation) and pipe it to `python3 "$S/bash_gate.py"` (`S` = `scripts/`). `allow` = exit code 0 and no `"permissionDecision": "deny"`; `deny` = exit code 0, that string, and `grep -qF` of the message. A hook that raises exits 1, so a crash is red for both helpers. The messages are the three in Rules; `PUSH_DENY` is the T041 text built from the words (`tests/push_gate_tests.sh` line 25).
- **Setup** (no network, no push in the setup): `W` is a repo on `claude/t1` with one empty commit, `.delix/card`, `.delix/` in `.git/info/exclude`, `docs/delix/delix.json` = `{"default_branch":"main"}`, `remote add origin "$W.git"` (never contacted), `refs/remotes/origin/main` made by a direct call in the setup (not through the hook) and `symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main`. `L` is a repo on `claude/t1` with no card. A test that changes `W`'s config or `delix.json` restores it before the next case; back up `.git/config` to a temp file and copy it back.
- **Deny with `REF_DENY` (cwd `W`):**
  1. `$G $U refs/remotes/origin/main HEAD`
  2. `$G $U -d refs/remotes/origin/main`
  3. `$G -C "$W" $U refs/remotes/origin/main HEAD`
  4. `$G --no-pager $U x y`
  5. `$G -c core.pager=cat $U x y`
  6. the word `$G` upper-cased (`tr a-z A-Z`), then `$U x y`
  7. `$G`, then `$U` upper-cased, then `x y`
  8. `/x/$G-$U x y`
  9. `echo ok && $G $U x y`
  10. `echo $($G $U x y)`
  11. `X=1 $G $U x y`
  12. `$G $R $HD origin -a`
  13. `$G $R $HD origin main`
  14. `$G $R -v $HD origin -a`
  15. `$G $R $UR origin /tmp/x`
  16. `$G $R add o u`
  17. `$G $R remove origin`
  18. `$G $R rm origin`
  19. `$G $R rename origin x`
  20. `$G $R update`
  21. `$G $R prune origin`
  22. `$G $R set-branches origin x`
  23. `/x/$G-$R add o u`
  24. `$G $R`, then `$UR` upper-cased, then `origin x`
  25. `$G -c core.pager=cat $R $UR origin x`
- **Deny with `PUSH_DENY`:** 26. `$G $R -v && $G $P origin HEAD` (a `git remote` command is another git command for R-P3b; unchanged behaviour).
- **Allow (cwd `W`):** 27. `$G $R` · 28. `$G $R -v` · 29. `$G $R --verbose` · 30. `$G $R show origin` · 31. `$G $R -v show origin` · 32. `$G $R get-url origin` · 33. `$G $R get-url --push origin` · 34. `$G config --get remote.origin.url` · 35. `$G log --grep $U -1` · 36. `grep -rn $U src` · 37. `$G commit -m 'T044: $U'` · 38. `$G $P origin claude/t1` (the own-branch push still passes).
- **Allow (cwd `L`, no card):** 39. `$G $U x y` · 40. `$G $R $UR o u`.
- **Aliases** (written to `W`'s `.git/config` by the test, then unset): `ur` = `$U -d`, `sh` = `$R $HD origin -a`, `ra` = `$R add`, `u2` = `ur`, `rv` = `$R -v`, `rs` = `$R show`.
  - deny `REF_DENY`: 41. `$G ur x` · 42. `$G sh` · 43. `$G ra o u` · 44. `$G u2 x`;
  - allow: 45. `$G rv` · 46. `$G rs origin`.
- **`delix.json`:**
  - 47–51. for each body `[]`, `"x"`, `null`, `3`, `true` written to `W`'s file: `ls` is denied with the R-U4 message;
  - 52. body `[]`: `$G status` is denied with the R-U4 message;
  - 53. `L` gets `docs/delix/delix.json` = `[]`: `ls` in `L` is allowed (no card);
  - 54. body `{}`: `ls` is allowed · 55. `{}`: `$G $P origin claude/t1` is allowed · 56. `{}`: `$G $U x y` is denied with `REF_DENY`;
  - 57. file removed: `ls` is allowed. Restore `{"default_branch":"main"}` after.
- **Non-UTF-8 byte** (written with `printf` and the octal escape `\377`, appended to `W`'s `.git/config`; restore the backup after each group):
  - with `[alias]` and `bad = log ` plus the byte: 58. `$G status` is denied with `ENC_DENY` · 59. `$G bad` is denied with `ENC_DENY` · 60. `ls` is allowed · 61. `$G $P origin claude/t1` is allowed (a push reads no alias list);
  - with `[remote "origin"]` and `$P = ` plus the byte: 62. `$G $P origin claude/t1` is denied with `ENC_DENY`;
  - 63. config restored: `$G status` is allowed.
- **Growth** (4 `✔` lines; for each input k = 20000 and k = 160000, the least of 3 runs per size; expect t(160000) < 3 s and t(160000) / t(20000) < 20; print both times and the ratio):
  - `("$G $R -v; " * k) + "$G $U x y"`
  - `("$G $R show origin " * k)`
  - `"$G $R " + "-v " * k + "show origin"`
  - `("$G $R get-url origin; " * k) + "$G status"`

## Verification command → expected output
- `bash tests/ref_gate_tests.sh` → last line `ALL PASSED` · `bash tests/ref_gate_tests.sh | grep -c '^✔'` → `67`
- `bash tests/ref_gate_tests.sh | grep growth` → 4 lines, each `ratio` below 20 and `t(160000)` below 3 s (card writer's prototype: ratios 2.8 to 6.4, at most 1.7 s)
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/ref_gate_tests.sh | tail -1` → `ALL PASSED`
- `bash tests/push_gate_tests.sh`, `bash tests/hook_tests.sh`, `bash tests/bash_gate_heredoc_tests.sh`, `bash tests/trust_tests.sh`, `bash tests/write_gate_case_tests.sh` → each `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `bash tests/site_tests.sh` → exit 0 (site files are untouched)
- `claude plugin validate .` → passes
- `git diff origin/main -- tests | grep -c '^-[^-]'` → `0`
- `git diff origin/main -- scripts/bash_gate.py | grep -c '^-[^-]'` → `5` · `git diff origin/main -- scripts/bash_gate.py | grep -c '^+[^+]'` → `28`
- `git diff origin/main -- scripts/common.py | wc -l` → `0`
- `git diff -U0 origin/main -- scripts/bash_gate.py | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and (len(l) > 121 or any(ord(c) > 126 for c in l))]"` → no output
- `python3 -c "open('tests/ref_gate_tests.sh', 'rb').read().decode('utf-8')"` → exit 0 (no raw invalid byte in the test file)
- `git diff --stat origin/main` → exactly the 2 Files

## Review Focus
- Every new step is a token comparison; no regex was added. The growth lines are linear (ratio far below 20).
- R-U1 and R-U2 sit after `card_path`, so a session with no card is unchanged (cases 39, 40, 53).
- `git remote` is an allowlist: only the read forms pass, and a name git adds later denies (fail closed).
- The alias check (R-U3) uses the same chain walk as R-P4; `PUSH_DENY` still wins for a `!` value or a push token.
- `scripts/common.py` is untouched (D3): `scripts/trust.py:45–48` still gets its `UnicodeDecodeError`.
- Existing rules, messages and their order are unchanged; `tests/push_gate_tests.sh` and the other suites pass without edits.
- The messages are byte for byte the three in Rules (the tests compare them).
- Security and the lead try the rule with real git (hook and git 2.54 on a `git archive` of the head): which `git remote` and `update-ref` forms it lets through. A form that passes is a Known limit or a follow-up card; it is not a reason to widen this card.
- Input the spec implies but does not test: a `git remote` whose option comes before the subcommand, for example `git remote --verbose`. Covering tests: 28 to 31.

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `README.md`, `README.tr.md`, `site/**`, every existing test file and every existing test line.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a regex, a dependency, an option or a rule beyond R-U1 to R-U5. If a case in Out of scope looks easy, write it in the report instead.
- No raw non-ASCII or invisible character in code or tests; the non-UTF-8 byte is the `printf` escape `\377`.
- Verification commands never put `git` followed by `update-ref`, `remote` or `push` as words in the command text, except the one push in Step 5.
- No ruleset, `.github/**` or settings change: those are the user's, from their own terminal (K279).

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`;
- the four growth lines;
- PR number and branch;
- assumptions;
- every pre-existing slow path or crash seen and not fixed.

Read only this card, spec §6 and K296.

## Docs handover (T046)
For T046 (wave 16). K298 moves the README and site sentences out of this card. Copy the words as given. On the site a backticked word is a `<code>` element, `<`, `>` and `&` are HTML-escaped, and the release label is T046's. Every sentence below describes what this card makes true; the lead checks them against the merged code before T046 is dispatched.

**H1, the implementer rule sentence** (README Bash paragraph after "`gh pr merge` is denied there: gate 2 is the user's (T041, K279)."; the same words in the site index bash_gate Implementer cell):
- EN: `It also denies `git update-ref` and every `git remote` form except plain `git remote`, `-v` / `--verbose`, `show` and `get-url`, so a card session does not rewrite refs or remotes (T044, K296). A `docs/delix/delix.json` that is not a JSON object, or a byte that is not UTF-8 in a git setting the rule reads, makes it deny the command with a message instead of failing.`
- TR: `Ayrıca `git update-ref`'i ve düz `git remote`, `-v` / `--verbose`, `show` ve `get-url` dışındaki her `git remote` biçimini reddeder; kart oturumu ref ya da remote yazmaz (T044, K296). JSON nesnesi olmayan bir `docs/delix/delix.json` ya da kuralın okuduğu bir git ayarındaki UTF-8 olmayan bayt, komutun hata vermek yerine bir mesajla reddedilmesini sağlar.`

**H2, the Known limits sentence** (README Known limits, README.tr Bilinen sınırlar, site usage Known limits li, EN and TR):
- EN: `The ref-write rule (T044, K296) is a check on the command's words too. It does not see a ref written by another command (such as `git symbolic-ref`, `git fetch` with a refspec into `refs/remotes/`, or `git branch -f`), a file written under the git directory, or a command that a script or another program runs. delix-board reads its trusted state from `refs/remotes/origin/HEAD`, so a card session can still make the board show a card as ready to merge by those routes; the merge click (gate 2) stays yours.`
- TR: `Ref yazma kuralı (T044, K296) da komutun kelimeleri üzerinde bir denetimdir. Başka bir komutun yazdığı ref'i (`git symbolic-ref`, `refs/remotes/` içine refspec'li `git fetch` ya da `git branch -f` gibi), git dizininin altına yazılan bir dosyayı ve bir betiğin ya da başka bir programın çalıştırdığı komutu görmez. delix-board güvenilir durumunu `refs/remotes/origin/HEAD`'ten okur; bu yüzden bir kart oturumu o yollarla board'a bir kartı merge'e hazır gösterebilir; merge tıklaması (kapı 2) yine senindir.`

**H3, changes to the push-rule out-of-reach list** (README Known limits "The implementer push rule (T041, K279) …", README.tr's twin, site usage line 225 EN and TR; the phrase may wrap over two lines in the README):
- Remove this item, now denied by R-U2:
  - README EN: ``another URL for `origin` set with `git remote` ``;
  - README TR: ``` `git remote` ile `origin`'e verilen başka bir URL ```;
  - site EN: `another URL for <code>origin</code> set with <code>git remote</code>`;
  - site TR: `<code>git remote</code> ile <code>origin</code>'e verilen başka bir URL`.
  Mind the comma and the "and" around the removed item.
- Add to the false-positive clause (after "… an `echo` or a commit message"):
  - EN: `the words `git` and `update-ref` on one line there, and a `git remote` form outside its read forms (run `git fetch` to refresh refs)`;
  - TR: ``aynı satırda `git` ve `update-ref` kelimeleri ve okuma biçimleri dışındaki bir `git remote` biçimi (ref'leri tazelemek için `git fetch` çalıştır)``.
- Every other item in the list stays: variables, `eval`, globs and ANSI-C quoting; git settings from the environment; a git config file written by another command on the same line (`>>`); a script or another program's own git calls; a `gh` alias for `pr merge`; `gh api` writes in other repositories; deleting `.delix/card`; a cwd below the worktree root; the owner bypass on `main-review`. The push line is still not an allowlist as a whole (O2).

## Review findings (filled by the lead)
- Round 1 (PR #74, head `d00fa6f44507825624b22ea0c35a87223b34fa14`, 2026-11-13): qa `ACCEPT` (0 P0, 0 P1), security
  `🔐 HUMAN_APPROVAL` (protected path; 1 Medium, 1 Low, both inherited or Known-limit class per Review Focus).
  Lead gates on the clean `git archive` of the head: the 14 shell suites exit 0 on Python 3.9.6 and 3.13.13,
  `tests/ref_gate_tests.sh` gives 67 `✔` (growth ratios 2.75 to 6.86, at most 1.7 s); `bash_gate.py` equals the card
  writer's prototype byte for byte; 5 lines removed and 28 non-blank added; no test line removed; `common.py`
  untouched; CI `check` and `test` green. Lead probe with real git 2.54 on temp repos (no network): every form in the
  card denies, the read forms and the no-card session pass, and the O4 forms pass as the card says. No fix round:
  the card's Review Focus sends a passing form to a Known limit or a follow-up card, and both findings below also
  hold on main for the T041 push rule.
  - Medium (security, lead reproduced on the T044 head and on main): `words()` (`scripts/bash_gate.py:154-156`)
    does not build bash's argv. It splits on `,`, `[` and `]`, splits quoted whitespace and does not join a
    backslash-newline, so the R-P2 option walk takes the wrong token as an option value and never sees the real
    subcommand. Passing on both hooks: `-c x.y=a,b` before a ref update, a remote URL change or a push (main's hook
    let `push origin HEAD:main` through and the push reached the test remote), `-C "<dir with space>"`,
    `-c "user.name=A B"`, and `git` then a backslash-newline before the subcommand. Follow-up 🔐 card before the
    release: R-P1 that matches bash's argv (join backslash-newline, keep quoted whitespace and an option value with
    `,[]` as one token, deny on unbalanced quotes). T046: H3 must not remove the `git remote` URL item while these
    forms pass, and H2 names them.
  - Low (security, lead reproduced): R-U3 and R-P4 take the alias value's first token, so an alias that starts with a
    global option (`-c core.pager=cat remote set-url origin <url>`) passes and git runs it (the URL changed in the
    probe). It needs an alias already in a config file (the card session cannot write one: R-P5). Same follow-up
    card: skip leading global options and their values before the first command token.
  - Note (security unsure): `git fast-import` also writes any ref in one command; add it to H2's list.
  - Evidence: `T044.lead-probe.txt` and `t044_probe*.sh` in the lead's scratchpad (not in the repo).
