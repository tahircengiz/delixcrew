# T041 🔐 — bash_gate: an implementer session pushes only its own card branch; no `gh pr merge`

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T041 | M | 3 | backend | 12 | open |

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json`).
> - The lead adds the `**🔐 Approved:**` line after the user's explicit yes in chat and commits it to main before dispatch; the session is interactive and the user opens it.
> - It closes spec §6 "Kart oturumları … `git push origin HEAD:<default>` … T041'de 🔐 kapatılır".
> - The lead session has no `.delix/card`, so its STATE push (review §4) keeps working; the ruleset stays as it is (K279).

**Goal (1 sentence):** In an implementer worktree only `git push [-u|--set-upstream] [--force-with-lease] origin <HEAD|current branch>` runs, from a branch that is not the default branch, and `gh pr merge` is denied. · **Spec:** `docs/delix/specs/C-board-visibility.md` §6 (lines 171–173), K279; T025 K-T025-1.

**Docs/site:** in this card, because CLAUDE.md says a hook rule is added in the same change. T032 refreshes its anchors after this card.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py`
  - line 10 `from common import REVIEWERS, card_path, delix_json, deny, matches, read_input  # noqa: E402`: add `git`;
  - docstring lines 2–3;
  - the new block after line 120 (`        deny(f"delixcrew: the command writes to a protected path ('{target}' ~ {d}). Tier 3 path; human approval required.")`) and before line 122 `if re.search(r"\bgit\s+commit\b", cmd):`.
- Create: `tests/push_gate_tests.sh`
- Modify: `README.md`, lines 121–122 (the implementer sentence of the Bash paragraph), and Known limits line 375 (a new sentence after "(K77).").
- Modify: `README.tr.md`, lines 121–122 and line 376 (after "(K77).").
- Modify: `site/index.html` line 475 and `site/tr/index.html` line 475 (bash_gate's Implementer `dd`; append one sentence).
- Modify: `site/usage.html` and `site/tr/usage.html`: a new `li` after line 224 (Known limits).

## Rules (allowlist, fail closed)
- **R-P0, scope:** only after `card_path(cwd)`, on the full `cmd` (no heredoc first-line exemption).
- **R-P1, words:**
  - `flat` = `cmd` with every `"`, `'` and `\` removed.
  - Segments: split `flat` on one character class: `; & | ( ) { } \n \r` and the backtick.
  - Tokens: split each segment on runs of whitespace, `,`, `[`, `]`.
  - A token matching `^[0-9]*[<>]` is a redirection and is dropped. When it is only the operator, the next token is dropped too.
  - One left-to-right pass per segment.
- **R-P2, git command:**
  - A token `git`, or one ending in `/git`, starts a git command.
  - `-C`, `-c`, `--git-dir`, `--work-tree`, `--namespace` and `--config-env` take the next token. Any other token starting with `-` is one option.
  - The next token is the subcommand; the scan resumes after it.
  - A token `git-push` or `git-send-pack`, or one ending in `/git-push` or `/git-send-pack`, counts as subcommand `push` or `send-pack`.
- **R-P3, push:** the subcommands `send-pack`, `http-push` and `subtree` are denied. Subcommand `push` is allowed only when all of these hold:
  - the git token is the segment's first token, with no global option;
  - after `push` come zero or more of `-u`, `--set-upstream`, `--force-with-lease`, then exactly `origin` and one name N;
  - N is `HEAD`, or equals `git(cwd,"symbolic-ref","--quiet","--short","HEAD")`;
  - that branch is not `cfg["default_branch"]`, `main`, `master`, or the target of `symbolic-ref --quiet --short refs/remotes/origin/HEAD` without `origin/`;
  - `git(cwd,"config","--get-all","remote.origin.push")` prints nothing;
  - no token of the whole command is `cd`, `pushd` or `popd` (lead, K279: after a `cd` the push runs in another checkout, where `HEAD` may be the default branch; fail closed, the message tells the session to push from its worktree).
- **R-P3a, git call results (lead):** a git call fails when `common.git` returns None or its exit code is neither 0 nor 1. Exit 1 with empty stdout means "not set" for `config --get-all remote.origin.push`, `config --get-regexp ^alias\.` and `symbolic-ref --quiet --short refs/remotes/origin/HEAD` (no `origin/HEAD`: the other three names still apply). Exit 1 of `symbolic-ref --quiet --short HEAD` (detached HEAD) means deny. A failed call means deny.
- **R-P4, alias:** the alias list comes from `git(cwd,"config","--get-regexp","^alias\\.")`, read once per command and only when needed; names are compared lowercased. Any other subcommand found in that list is followed to the first token of each value, for up to 10 steps. Deny when a value starts with `!`, holds a `push`, `send-pack` or `http-push` token, or the chain is longer than 10.
- **R-P5, config writes:** deny in either case:
  - subcommand `config` with none of `--get --get-all --get-regexp --get-urlmatch --list -l get list`, and a token starting (casefold) with `alias.`, `remote.`, `push.`, `url.` or `include`;
  - a `-c` value with one of those prefixes.
- **R-P6, merge:** a token `gh` (or ending in `/gh`), followed by `pr` and then `merge`, is denied with `MERGE_DENY`. Reason: the main-review ruleset requires 0 approvals (T025), so a green PR merges itself.
- **Messages:**
  - `PUSH_DENY` = `delixcrew: an implementer session pushes only its own card branch (git push [-u] origin <branch>); the default branch and every other push run from the user's own terminal`
  - `MERGE_DENY` = `delixcrew: gate 2 (merge) is the user's; an implementer session does not run gh pr merge`
- **Out of reach (goes into Known limits):**
  - words built from variables or `eval`;
  - a script file or another program's own git calls;
  - `gh api` ref or merge writes in another repository (this repository's writes are already denied by REPO_DENY);
  - deleting `.delix/card`;
  - a cwd below the worktree root;
  - the GitHub owner bypass.
- **Known false positive (fail closed):** the words `git` then `push` on one line of a heredoc body, an `echo` or a commit message; a push in a command that also has `cd`.

## Interfaces
- Consumed: `common.git(cwd, *args)` (`scripts/common.py:30–39`: no `GIT_*` env, `core.fsmonitor=false`, 5 s), `card_path`, `delix_json`, `deny`.
- Produced: the two messages.

## Global Constraints (verbatim)
- §6: "Kart oturumları kullanıcının kimliğiyle `git push origin HEAD:<default>` çalıştırabilir: `bash_gate` bunu engellemez".
- Review §4: "commit `STATE.json` with this round's records, rebase on `origin/<default_branch>` and push it there".
- README Known limits: "The Bash hook's denylist is friction, not a boundary".
- Repo hook rules:
  - no overlapping alternation (this design uses only character classes and token comparisons);
  - a ReDoS timing check in the test;
  - the test driver lives in the test file, with the trigger words assembled at run time.
- Python 3.9 stdlib; no version-dependent behaviour.
- Site: EN and TR carry the same content; escape `<` and `>` in HTML; each new site claim ends with "(coming in the next release)" / "(sonraki sürümle gelecek)".

## Steps
1. Write `tests/push_gate_tests.sh` (cases below) and see **red**.
2. Implement in `bash_gate.py`.
3. See **green** on 3.9.6 and 3.13, and log the timing ratios.
4. Edit the README and site lines.
5. Run `bash tests/site_tests.sh`.
6. Commit `T041: bash_gate push rule for implementer worktrees, gh pr merge denied`. The message must not contain the words git and push in that order on one line. Open a PR with `## How I tested`.

## Tests (`tests/push_gate_tests.sh`, a new file; `ALL PASSED` at the end)
- **Words:** `G=gi; G="${G}t"; P=pu; P="${P}sh"; M=mer; M="${M}ge"`. The file holds no literal `git push` and no `gh pr merge`.
- **Input:** build the hook input with Python `json.dumps` (never by string concatenation) and pipe it to `python3 "$S/bash_gate.py"`. A case is deny when stdout holds `"permissionDecision": "deny"`.
- **Setup** (no network, no push in the setup):
  1. `W`: a repo on `claude/t1` with `.delix/card` and `.delix/` in `info/exclude`.
  2. `W/docs/delix/delix.json` `{"default_branch":"main"}`.
  3. `remote add origin "$W.git"`; `update-ref refs/remotes/origin/main HEAD`; `symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main`.
  4. `MN`: a repo on `main` with a card.
  5. `L`: a repo without a card.
  6. `DT`: a repo with a card and a detached HEAD.
- **Allow:**
  - `$G $P origin claude/t1`
  - `$G $P -u origin claude/t1`
  - `$G $P --set-upstream origin HEAD`
  - `$G $P --force-with-lease origin claude/t1 2>&1`
  - `$G log --grep $P -1`
  - `grep -rn $P src`
  - `$G config --get remote.origin.url`
  - in `W` with `refs/remotes/origin/HEAD` deleted: `$G $P origin claude/t1` (R-P3a)
  - in `L`: `$G $P origin HEAD:main`
- **Deny (in `W`):**
  - `$G $P origin HEAD:main`
  - `… origin main`
  - `… origin +claude/t1`
  - `… origin refs/heads/main`
  - `… origin claude/t1:main`
  - `… --all origin`
  - `… --mirror origin`
  - `$G $P` alone; `$G $P origin` alone
  - `$G -C "$W" $P origin claude/t1`
  - `$G -c remote.origin.$P=x $P origin claude/t1`
  - `g''it pu""sh origin main` (literal)
  - `\$G $P origin main`
  - `bash -c "$G $P origin main"`
  - `echo ok && $G $P origin main`
  - `echo $($G $P origin main)`
  - `$G $P origin claude/t1 main`
  - `$G $P origin :main`
  - `$G $P upstream claude/t1`
  - `env X=1 $G $P origin claude/t1`
  - `cd .. && $G $P origin HEAD`; `cd "$W" && $G $P origin claude/t1` (R-P3, lead)
  - `$G config alias.p "$P origin HEAD:main"`
  - `$G -c alias.x=y status`
  - aliases written to `.git/config` by the test itself: `q` = a push, `r` = `!sh`, a chain `a`→`b`→push; then `$G q`, `$G r`, `$G a`
  - `remote.origin.push` set by the test: `$G $P origin claude/t1` (then unset)
  - `default_branch` set to `claude/t1`: `$G $P origin claude/t1` (then restored)
  - in `MN`: `$G $P origin HEAD`
  - in `DT`: `$G $P origin HEAD` (R-P3a)
  - `gh pr $M 7 --squash`
  - `/usr/bin/gh pr $M 7`
- **ReDoS:** for each input below, k = 20000 and k = 160000:
  - `("$G -c $G " * k) + "$P"`
  - `"'" * k + " $G $P"`
  - `("; " * k) + "$G $P origin main"`
  - `"\\" * k`
  - `("$G " * k) + "$P"`

  Expect: time at 160000 < 3 s and t(160000)/t(20000) < 20. Print the ratios.

## Verification command → expected output
- `bash tests/push_gate_tests.sh` → `ALL PASSED` (3.9.6 and 3.13)
- `bash tests/hook_tests.sh` and `bash tests/bash_gate_heredoc_tests.sh` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `bash tests/site_tests.sh` → exit 0
- `claude plugin validate .` → passes
- `git diff origin/main -- tests | grep -c '^-[^-]'` → `0`
- `grep -cF 'coming in the next release' site/index.html site/usage.html` equals the `sonraki sürümle gelecek` counts in `site/tr/`
- `git diff --stat origin/main` → only the 8 Files

## Review Focus
- Every new step is linear; there is no regex alternation.
- A failed git call means deny (R-P3a).
- The rule sits after `card_path`.
- The existing rules and their order are unchanged.
- The README describes it as a pattern check and names the bypass and the false positive.

## Don'ts
- Untouchable: `scripts/common.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, the existing tests.
- No ruleset change; that is the user's, from their own terminal (K279).
- Verification commands never put `git` followed by `push` in the command text.

## Report contract
`.delix/report.md`:
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output, `python3 --version` and `git --version`;
- the timing ratios;
- PR number and branch;
- assumptions;
- every pre-existing slow path seen, not fixed.

Read only this card and spec §6.

## Review findings (filled by the lead)
- (none yet)
