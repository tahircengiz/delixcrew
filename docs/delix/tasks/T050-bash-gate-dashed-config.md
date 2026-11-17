# T050 🔐 — bash_gate: the dashed `git-config` name follows R-P5 and R-C1

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T050 | S | 3 | backend | 20 | open |

**🔐 Approved:** 2026-11-17 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`). `tests/push_gate_tests.sh` matches `test_paths` (`tests/**`) and no protected entry; it is in Files for one insertion after its line 153, and none of its existing lines changes.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-17 ("Evet, T050 onaylı", said in the lead session). The lead commits it to main before dispatch; the session branches from that commit.
> - It closes the Low of T049 round 1 (K318). git runs `git-config` (the dashed name, bare, with a path or through `git --exec-path`) as `git config`, but the R-P2 loop knows only `git-push`, `git-send-pack`, `git-update-ref` and `git-remote` as dashed names, so R-P5 and R-C1 never see it. On main with T049 the lead measured 6 forms that write `origin`'s URL keys this way; the own-branch push then lands in a second repository (D1).
> - Order (K319, the user): T046, T049, this card, then the release card T042.
> - Publication (K313): the forms that pass main are in this card and its tests only; the card enters main at dispatch. README and site text names none of them (D4).
> - It is defence in depth, not a boundary: the rules are a check on the command's words (Out of scope).

**Goal (1 sentence):** In an implementer worktree the dashed name `git-config`, bare, with a path or through `$(git --exec-path)`, reaches R-P5 and R-C1 the way `git config` does, so it no longer writes `origin`'s URL keys, `url.*.insteadOf` or `url.*.pushInsteadOf`, or an `alias.`, `include` or `help.` key, while its reads still pass. · **Spec:** `docs/delix/specs/C-board-visibility.md` K313, K318, K319 and K320; K320 records this card's decisions (the same text as the section at the end of this card)

**Docs/site:** none in this card, the same exception as T044 to T049 (K298), and no Docs handover (D4). Do not touch `README.md`, `README.tr.md` or `site/**`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (one line, Edit anchor 1)
- Modify: `tests/push_gate_tests.sh` (one insertion after line 153, see the test file anchor; no existing line changes)

## Edit anchors (base main bbb9ff2, full SHA bbb9ff235b6b837d6043ec273b102c70f39a9dab, the merge of PR #78)
On the base `scripts/bash_gate.py` has 719 lines and sha256 `7f5be7593f4213b0f39ac2c105ee08c6682589187d22bea6c7f8375a76f5db4a`, and `tests/push_gate_tests.sh` has 273 lines and sha256 `c9fc235d84ba85360aa40d0ed6d8e64141a829d29bc9413a67d223f577b18273` (both as on PR #78's head `ef0860668718cba0ab28cb0a70b14fb167f79b8a`). Match the quoted content before you edit. If it differs, stop with `NEEDS_CONTEXT`. The new line is at most 120 characters and ASCII. After the edit run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output: if this repo's plugin loads from your worktree, a syntax error would block your own Bash.

1. **Line 669, replace** the line below (8 spaces of indentation in the file):
   ```text
           elif t.rsplit("/", 1)[-1] in ("git-push", "git-send-pack", "git-update-ref", "git-remote"):
   ```
   with this line (8 spaces of indentation in the file, 113 characters):
   ```text
           elif t.rsplit("/", 1)[-1] in ("git-push", "git-send-pack", "git-update-ref", "git-remote", "git-config"):
   ```
   The code blocks sit inside a list item, so each code line carries exactly 3 extra leading spaces that belong to the list: remove those 3 and keep the rest. Line 668 `            sub = toks[j].casefold()` stays above; line 670 `            j, gopt, sub = i, False, t.rsplit("/", 1)[-1][len("git-"):]` stays below.

Expected diff of `scripts/bash_gate.py` against the base: 1 hunk, 1 line removed and 1 added. The file has 719 lines after the edit and sha256 `87e4e322db9959caac33d5130dd2dd8d9dbc9561d067a0d034c3fc108f618bbd`.

**Test file anchor, `tests/push_gate_tests.sh`, after line 153, insert 8 lines.** Line 153 is `PYC`, the end of T049's growth block; line 154 `# Deny: gh merge (R-P6)` stays below. The block has no indentation of its own (remove the list's 3 spaces):
   ```text
   # T050: the dashed git-config name follows R-P5 and R-C1 like `git config` (T044's class of dashed names)
   deny "dashed config, <push>url"             "$W" "$G-config remote.origin.${P}url /tmp/x"
   deny "dashed config with a path, url"       "$W" "/x/$G-config remote.origin.url /tmp/x"
   deny "dashed config, insteadOf"             "$W" "$G-config url./tmp/x.insteadOf $W.git"
   deny "exec-path, dashed config, <push>url"  "$W" "\$($G --exec-path)/$G-config remote.origin.${P}url /tmp/x"
   deny "dashed config, alias"                 "$W" "$G-config alias.p $P"
   allow "dashed config --get"                 "$W" "$G-config --get remote.origin.url"
   allow "dashed config, user.name"            "$W" "$G-config user.name t"
   ```
Nothing else in the file changes. Expected diff: 1 hunk, 0 lines removed and 8 added; the file has 281 lines after the edit and sha256 `e49d55b357f6e396254c4647322e8a862b3c97881d059156d51e470cbfdfc7dd`. Applied to the base, the two anchors give the lead's prototype byte for byte.

## Rules (allowlist, fail closed)
- **R-W0, scope:** every rule sits behind `card_path(cwd)`: a session with no `.delix/card` is unchanged. Both views still feed every rule and a deny in either wins (T047 D1).
- **R-D1, the dashed config name (T050):** the R-P2 loop takes a token whose last path part, casefolded, is `git-config` as git with the subcommand `config` and no global option, as it does for the four dashed names of T041 and T044. R-P5 and R-C1 then apply unchanged, in both views: a token from the next one on that starts with one of `CONFIG_KEYS` denies with `PUSH_DENY` unless `config_read` is True. `alias_check`, `autocorrect_check` and R-P3b see the name as `config`, so it counts as another git command for R-P3b, as `git config` does.
- **Messages:** `PUSH_DENY` and every other message do not change.
- **Regex discipline:** no new pattern and no new loop; the change adds one string to a tuple that each token is compared with once.
- **Known false positives (fail closed), the same as for `git config`:**
  - a dashed config call on the same line as the own-branch push denies (R-P3b);
  - a dashed read of an R-P5 key with an option outside `CONFIG_FLAGS` before the read option denies (R-C1).

## Decisions (lead, 2026-11-17)
- **D1, evidence (lead, Python 3.9.6, bash 3.2.57, git 2.54, Mac).** `probe.sh` with `forms3.txt` (`T050-proto/` in the lead's notes): the real hook, then real bash and git in a throwaway card repository with a local bare `origin` and a second local bare repository, no network.
  - 6 forms pass main with T049: the absolute exec-path name and `$(git --exec-path)/git-config` for `pushurl`, `url`, `insteadOf` and `pushInsteadOf`, and a path held in a variable (`"$X/git-config"`). Each writes the key, and the own-branch push then lands in the second repository. The prototype denies all 6.
  - 3 dashed reads (`--get`, `get`, `--show-origin --get`) pass on both; the control `git config <pushurl key> <url>` denies on both.
  - `daily.py`, 24 everyday commands: 0 verdicts changed.
  - Tests: the new block on the base gives 5 `✘` / 162 `✔`; on the prototype `tests/push_gate_tests.sh` gives 167 `✔`, and all 16 `tests/*_tests.sh` exit 0 on Python 3.9.6 and on 3.13 through a PATH shim.
- **D2, only `git-config`.** R-P5's keys in the current repository are written by `git config` and `git remote`; R-U2 already reads `git-remote`. The other dashed names stay as they are: the brief is the K318 Low, and the card adds no rule beyond it.
- **D3, the test cases.** 7 cases after T049's block, with the file's words (`$G`, `$P`, `$W`): 5 deny cases that main allows (a bare name, a path, `insteadOf`, the exec-path substitution, an `alias.` key) and 2 allow cases (a `--get` read, a key outside R-P5). `/tmp/x` is a URL that is never contacted.
- **D4, no docs sentence.** README, README.tr and the site never name the dashed names (T044's neither); T049's Docs handover sentence on `git config` (H1) is true for the dashed name once this card is in. The release card T042's CHANGELOG item for T049 adds "also through the dashed name (T050)", the words T044's item uses.
- **D5, no growth test.** No new regex or loop (Rules); T049's growth block and the file's ReDoS block run unchanged and must pass.

## Lead decisions
1. **Order (K319, the user):** before T042; the base is main after PR #78 is merged.
2. **Acceptance:** the lead runs `probe.sh` with `forms3.txt` and `daily.py` on the PR head, as in T049 (K317).
3. **Publication (K313):** the card enters main at dispatch, so the window is dispatch to merge.

## Out of scope (each with the reason)
- **O1, git under another name:** git takes any program name that is not `git-<command>` as `git` (the lead measured it with git 2.54: a link to the git binary named `foo` ran `foo config x.y 1` and wrote the key). The hook reads command words, not files; like T049 O2 (variables, command output), a Known limit.
- **O2, other dashed names** (D2).
- **O3, T049's Out of scope (O1 to O4):** unchanged.

## Interfaces
- Consumed: the R-P2 loop, `CONFIG_KEYS`, `config_read`, `PUSH_DENY`, `alias_check`, `autocorrect_check`.
- Produced: none. Changed: the dashed-name tuple of the R-P2 loop.

## Global Constraints (verbatim)
- K313: "Kod düzeltmesi (R-P5) ayrı bir 🔐 Tier 3 kartıdır; tasarımı o kartla yayımlanır."
- K319: "T050, 0.7.0 sürümünden (T042) önce gelir; sıra T046, T049, T050, T042."
- Repo hook rules: no new regex with overlapping alternation; the test driver lives in the test file with the trigger words assembled at run time; the existing tests are not changed.
- Python 3.9 stdlib; no version-dependent behaviour (the Mac runs 3.9.6, CI 3.12; run the suites on 3.13 as well). ASCII only in the new code and test lines; no invisible character.

## Steps
1. Insert the test block per the test file anchor. Run `bash tests/push_gate_tests.sh` and see **red**: 5 `✘` lines (the 5 deny cases), 162 `✔` lines (the file's 160 and the 2 allow cases), `FAILED`, exit 1. A different count means a case differs from the list: say so in the report.
2. Edit `scripts/bash_gate.py` per Edit anchor 1; run the `ast.parse` one-liner.
3. Run `bash tests/push_gate_tests.sh` and see **green**: 167 `✔` lines, no `✘`, `ALL PASSED`. Run it again on Python 3.13 through a PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 2 paths by name. Commit `T050: R-P5 and R-C1 read the dashed config name (this card's cases)`. No command of yours, and no commit message, holds `git` followed by `push`, `update-ref` or `remote` as words on one line, except the one push below. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd`. Open a PR with `--body-file` and a `## How I tested` section.
6. After step 2 your own session may run the edited hook (if the plugin loads from this worktree): a dashed config call that writes an R-P5 key denies, as `git config` does. Keep to commands the rules allow.

## Tests (`tests/push_gate_tests.sh`, inserted after line 153; `ALL PASSED` at the end)
- **Words and helpers:** the file's own (`G`, `P`, `W`, `PUSH_DENY`, `allow`, `deny`; `deny` without a fourth argument expects `PUSH_DENY`). `\$(` is a literal `$(` in the bash string.
- **Cases** (number, label as printed, the command as in the bash string, the expected result; cwd `W`):
  - *R-D1, the dashed config name (main allows 1 to 5)*
    - 1 dashed config, <push>url: `$G-config remote.origin.${P}url /tmp/x` → `PUSH_DENY`
    - 2 dashed config with a path, url: `/x/$G-config remote.origin.url /tmp/x` → `PUSH_DENY`
    - 3 dashed config, insteadOf: `$G-config url./tmp/x.insteadOf $W.git` → `PUSH_DENY`
    - 4 exec-path, dashed config, <push>url: `\$($G --exec-path)/$G-config remote.origin.${P}url /tmp/x` → `PUSH_DENY`
    - 5 dashed config, alias: `$G-config alias.p $P` → `PUSH_DENY`
  - *Regression cases (main and the prototype give the same result)*
    - 6 dashed config --get: `$G-config --get remote.origin.url` → `allow`
    - 7 dashed config, user.name: `$G-config user.name t` → `allow`

## Verification command → expected output
- `bash tests/push_gate_tests.sh` → last line `ALL PASSED` · `bash tests/push_gate_tests.sh | grep -c '^✔'` → `167`
- `bash tests/push_gate_tests.sh | grep growth` → 4 lines, each `ratio` below 20 and `t(40000)` below 3 s (T049's block, unchanged)
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/push_gate_tests.sh | tail -1` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, on Python 3.9.6 and through the 3.13 shim
- `bash tests/site_tests.sh` → exit 0 (site files are untouched)
- `claude plugin validate .` → passes
- `git diff origin/main -- tests | grep -c '^-[^-]'` → `0` · `git diff origin/main -- tests/push_gate_tests.sh | grep -c '^+[^+]'` → `8`
- `git diff origin/main -- scripts/bash_gate.py | grep -c '^-[^-]'` → `1` · `git diff origin/main -- scripts/bash_gate.py | grep -c '^+[^+]'` → `1`
- `git diff -U0 origin/main | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and (len(l) > 121 or any(ord(c) > 126 for c in l))]"` → no output
- `git diff --stat origin/main` → exactly the 2 Files
- **Lead, on the PR head (not the implementer's):** `probe.sh` with `forms3.txt` → the 6 forms deny, the 3 reads pass, the control denies; `daily.py` → 0 verdicts changed against main.

## Review Focus
- R-D1: the dashed name gives `sub == "config"` with `j = i` and `gopt` False, so R-P5 and R-C1 read the arguments from the next token on, as for `git config`; the four existing dashed names keep their behaviour.
- No existing test line changes; the 16 suites pass on Python 3.9.6 and 3.13; no new allow; the new false positives are the ones in Rules.
- Daily commands still pass: cases 6 and 7 and the 24 commands of D1.

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `README.md`, `README.tr.md`, `site/**`, every other test file and every existing line of `tests/push_gate_tests.sh`.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a regex, a dependency, an option, another dashed name or a rule beyond R-D1. If a case in Out of scope looks easy, write it in the report instead.
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
- every pre-existing slow path or crash seen and not fixed.

Read only this card and spec K313, K318, K319 and K320.

## Spec K entry (K320 in the spec)
```text
- **K320** (lead, 2026-11-17, geri alınır) T050 kartı (🔐 Tier 3, `scripts/bash_gate.py`; lead yazdı).
  - **R-D1:** R-P2 döngüsü son yol parçası (küçük harfe çevrilmiş) `git-config` olan bir kelimeyi, T041 ve T044'ün
    dört tireli adı gibi, global seçeneksiz `git config` sayar; R-P5 ve R-C1 iki görünümde değişmeden uygulanır.
    Kapanan: K318'deki Low.
  - **Kapsam:** yalnız `git-config`; R-P5 anahtarlarını reponun kendisinde `git config` ve `git remote` yazar,
    `git-remote`'u R-U2 zaten okur. Git'in başka adla (bağlantı ya da kopya) çalışması Bilinen sınır (O1; lead
    git 2.54'te ölçtü).
  - **Ölçüm:** 6 biçim main'den (T049 ile) geçip `origin`'in URL anahtarlarını yazar, kendi dal push'u başka repoya
    gider; prototip 6'sını reddeder. 3 tireli okuma ve 24 günlük komut iki tarafta aynı sonucu verir. Yeni test
    tabanda 5 ✘ / 162 ✔, prototipte 167 ✔; 16 test dosyası Python 3.9.6 ve 3.13'te geçer.
  - **Belge:** README ve site tireli adları anmaz; yeni cümle yok. T042'nin T049 CHANGELOG maddesine "also through
    the dashed name (T050)" eklenir.
  - **Yayın:** geçen biçimler yalnız kartta ve testte durur (K313); kart main'e dispatch'te girer.
```

## Review findings (filled by the lead)
