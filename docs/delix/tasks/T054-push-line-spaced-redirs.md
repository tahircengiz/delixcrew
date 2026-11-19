# T054 🔐 — bash_gate: the spaced `/dev/null` redirections on a push line (R-L1)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T054 | S | 3 | backend | 25 | open |

**🔐 Approved:** 2026-11-18 tahircengiz

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path (`docs/delix/delix.json:11`). `tests/push_line_tests.sh` matches `test_paths` (`tests/**`) and no protected entry; it gets 5 inserted lines and no existing line changes.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-18 (said in the lead session). The lead commits it to main before dispatch; the session branches from that commit.
> - It closes the Low that security found on T053's PR #84 (K336): the release docs say a push line may redirect to `/dev/null`, but R-L1 denies `1> /dev/null` and `&> /dev/null` with a space. At gate 2 the user chose a follow-up card over a docs round ("Merge, takip kartı", K337), then this scope ("Evet, ikisi birlikte").
> - The same yes covers the lead's own change to `docs/delix/delix.json` (D3). The implementer cannot write under `docs/delix/**` (`scripts/write_gate.py:91`), so that change is not in this card's Files.
> - Publication (K313): every deny case in this card already denies on main; the card names no form that passes main.

**Goal (1 sentence):** In an implementer worktree a push line may also redirect with `1> /dev/null` and `&> /dev/null` (a space after the operator), the same as the forms with no space that R-L1 already allows; every other R-L1 verdict and message stays. · **Spec:** `docs/delix/specs/C-board-visibility.md` K313, K331, K336, K337 and K338; K338 records this card's decisions (the same text as the section at the end of this card)

**Docs/site:** none in this card (K298); the release card after this one carries the text (D4). Do not touch `README.md`, `README.tr.md`, `CHANGELOG.md` or `site/**`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/bash_gate.py` (A1: lines 154 and 155, the `LINE_REDIRS` tuple, become 2 new lines)
- Modify: `tests/push_line_tests.sh` (A2: 2 lines inserted after line 34; A3: 3 lines inserted after line 65; no existing line changes)

## Interfaces
- Consumed: `LINE_REDIRS`, `simple_line`, `LINE_DENY` (R-L1, T052); none of them changes shape.
- Produced: none new; `LINE_REDIRS` holds 11 entries instead of 9.

## Lead decisions
- **D1, evidence (lead, Python 3.9.6 and 3.13.13, bash 3.2.57, zsh 5.9, Mac).** On main `6d174dc` both files are byte-equal to `55b542f`, where security reproduced the Low:
  - after a push, `1> /dev/null` and `&> /dev/null` deny with `LINE_DENY`, while `1>/dev/null`, `&>/dev/null`, `> /dev/null` and `2> /dev/null` pass;
  - bash and zsh read the word after the operator as the target with or without the space: `1> /dev/null` and `&> /dev/null` write no file, and `1> f1` and `&> f2` write `f1` and `f2` (measured in both shells);
  - the test file with A2 and A3 on the base code gives 56 `✔` / 2 `✘` (the two allow cases); with A1 it gives 58 `✔`, and all 17 `tests/*_tests.sh` exit 0 with no `✘` on Python 3.9.6 and 3.13.13 (1436 `✔` lines on each, every file exit 0);
  - real use: the 308 Bash lines with the push word from this repo's worktree sessions (T052 D1) give the same verdict on main and on the prototype (308 the same);
  - edge probes (11, real hook in a throwaway card worktree): a new entry matches only before the end or a separator (`scripts/bash_gate.py:692`), so `1> /dev/nullx`, `&> /dev/null.x`, `1> /dev/null/x`, two spaces after `1>`, a trailing `&` and a file target after a `/dev/null` form deny on main and on the prototype; only the two forms alone, with `2>&1` and piped into `tail` go from deny to allow.
- **D2, only the two spaced forms.** `> /dev/null` and `2> /dev/null` are already on the list. With these two, every `/dev/null` form on it is allowed with and without a space. The descriptor copies stay `2>&1`, `1>&2` and `>&2`: the 308 real lines hold no other copy. `3>&1` and `2>&-` keep denying, and the new case "another descriptor" fixes that boundary. A file target keeps denying with a space too (the two "into the git dir" cases).
- **D3, the pane's manifest and hook list are protected (the lead's change, not this card).** In its dispatch commit the lead adds `plugins/*/.claude-plugin/**` and `plugins/*/hooks/hooks.json` to `docs/delix/delix.json` `protected_paths`, after `.claude-plugin/**`, the same way 3728ea8 added `scripts/trust.py`.
  - Measured with `scripts/common.py` `matches` over the 309 tracked files: protected files go from 17 to 19. The two added are `plugins/delix-board/.claude-plugin/plugin.json` and `plugins/delix-board/hooks/hooks.json`, and none is removed.
  - The pane's module code (`plugins/delix-board/hooks/*.ts`, `*.tsx`) stays unprotected, the same as the root scripts that are not gates.
  - The Stop gate approval hashes only `test_command` and `extra_checks` (`scripts/common.py:86`), so it does not change.
- **D4, docs in the release card (K298).** The README Hooks sentence and the Known limits false-positive clause (README, README.tr and both usage pages) should then name the redirections the way `LINE_REDIRS` does. A redirection to `/dev/null` is allowed with or without a space. The only descriptor copies allowed are `2>&1`, `1>&2` and `>&2`. The lead writes that card after this merge.
- **D5, order:** after T053 (merged, `v0.7.1`); this card is the only one in wave 25.

## Out of scope (each with the reason)
- **O1, other redirections:** a file target, `<` and other descriptor forms keep denying; no real line needs them (D2).
- **O2, the pane's module code:** the user chose the manifest and the hook list (D3); protecting the code would make every pane card Tier 3.
- **O3, the README text:** the release card (D4).

## Edit anchors (base main 6d174dc, full SHA 6d174dc9a200fbec28f044ff91b523db8347f716)
Line numbers are from that commit. The dispatch commit changes no file of this card. Each file lists its line count and sha256 on the base and after the card. Match the quoted content before you edit; if it differs, stop with `NEEDS_CONTEXT`. Apply every anchor with the Edit tool; `scripts/bash_gate.py` must use it, because the hook denies shell writes to protected paths.
- **replace:** the "Current" lines occur once in the file. They are `old_string`, and the new lines are `new_string`.
- For A2 and A3 the current line stays first in "Replace with"; only the lines after it are new.
- The code blocks are not indented: copy each line as it stands, with its inner spaces (the test labels are padded to one column). Every new line is ASCII and at most 120 characters.
- Applied to the base in any order, the anchors give the lead's prototype byte for byte. A script read this card, applied the blocks two ways (the Edit tool's string order and line numbers bottom-up) and got both "after" sha256s below.

### `scripts/bash_gate.py`
Base: 821 lines, sha256 `3aac7c26614524a8fc847ceeb323f3e95893a7ae6a3e28cce650830ed3373f3e`. After the card: 821 lines, sha256 `64ed73c98e5148dae2d5713c281118feef3d412227235c4e951dbfde2e547265`.

**A1 · lines 154 to 155 · replace · `LINE_REDIRS` gains `1> /dev/null` and `&> /dev/null`.** Current (lines 154 to 155):
```text
LINE_REDIRS = (">/dev/null", "> /dev/null", "1>/dev/null", "2>/dev/null", "2> /dev/null", "&>/dev/null", "2>&1",
               "1>&2", ">&2")  # R-L1: the only redirections a push line may hold
```
Replace with (2 lines).
```text
LINE_REDIRS = (">/dev/null", "> /dev/null", "1>/dev/null", "1> /dev/null", "2>/dev/null", "2> /dev/null",
               "&>/dev/null", "&> /dev/null", "2>&1", "1>&2", ">&2")  # R-L1: the only redirections a push line may hold
```

### `tests/push_line_tests.sh`
Base: 94 lines, sha256 `c7a1aa2538600c900e05fd7924f2473c8ac31f009e6a2d990e1b5e029a1617c4`. After the card: 99 lines, sha256 `78514aa258d058db3b2f6dab4ae01129453e742f9c311d4da1f98fef0e28fb76`.

**A2 · line 34 · replace · two allow cases after the `2>/dev/null` case.** Current (line 34):
```text
allow "2>/dev/null"                         "$W" "$G $P origin HEAD 2>/dev/null"
```
Replace with (3 lines). The current line stays first; the new lines follow it.
```text
allow "2>/dev/null"                         "$W" "$G $P origin HEAD 2>/dev/null"
allow "1> /dev/null"                        "$W" "$G $P origin HEAD 1> /dev/null"
allow "&> /dev/null"                        "$W" "$G $P origin HEAD &> /dev/null"
```

**A3 · line 65 · replace · three deny cases after the "push output into the git dir" case.** Current (line 65):
```text
deny "push output into the git dir"         "$W" "$G $P origin HEAD > .git/HEAD"
```
Replace with (4 lines). The current line stays first; the new lines follow it.
```text
deny "push output into the git dir"         "$W" "$G $P origin HEAD > .git/HEAD"
deny "1> into the git dir"                  "$W" "$G $P origin HEAD 1> .git/HEAD"
deny "&> into the git dir"                  "$W" "$G $P origin HEAD &> .git/HEAD"
deny "another descriptor"                   "$W" "$G $P origin HEAD 3>&1"
```

## Global Constraints
- K313: "Kod düzeltmesi (R-P5) ayrı bir 🔐 Tier 3 kartıdır; tasarımı o kartla yayımlanır."
- Repo hook rules: no new regex (this card adds none); the test driver lives in the test file with the trigger words assembled at run time; existing tests do not change.
- Python 3.9 stdlib; no version-dependent behaviour (the Mac runs 3.9.6, CI 3.12; run the suites on 3.13 as well). ASCII only in the new lines; no invisible character.

## Steps
1. Apply A2 and A3 to `tests/push_line_tests.sh`. Run `bash tests/push_line_tests.sh` and see **red**: 56 `✔`, 2 `✘` (`1> /dev/null` and `&> /dev/null`, expected allow), last line `FAILED`. A different count means a case differs from the card: say so in the report.
2. Apply A1 to `scripts/bash_gate.py` with the Edit tool. Run `python3 -c "import ast; ast.parse(open('scripts/bash_gate.py').read())"` and see no output.
3. Run `bash tests/push_line_tests.sh` and see **green**: 58 `✔`, no `✘`, `ALL PASSED`. Run it again on Python 3.13 through the PATH shim (see Verification). If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Run `git add scripts/bash_gate.py tests/push_line_tests.sh` in a call of its own. Commit `T054: R-L1 allows the spaced /dev/null redirections (this card's cases)` in a call of its own. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd` and nothing else in the command. No other command of yours holds `git` followed by `push`, `update-ref` or `remote` as words on one line. Write the PR body with the Write tool and open the PR with `--body-file`; the body has a `## How I tested` section.

## Tests (`tests/push_line_tests.sh`; `ALL PASSED` at the end)
- **New allow cases (A2):** `1> /dev/null` and `&> /dev/null` after the push.
- **New deny cases (A3), each with exactly `LINE_DENY`:** `1> .git/HEAD` and `&> .git/HEAD` after the push (a file target with a space), and `3>&1` (a descriptor copy not on the list). All three already deny on the base code.

## Verification command → expected output
- `bash tests/push_line_tests.sh` → last line `ALL PASSED` · `bash tests/push_line_tests.sh | grep -c '^✔'` → `58`
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/push_line_tests.sh | tail -1` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, on Python 3.9.6 and through the 3.13 shim: 17 files, no `✘`
- `claude plugin validate .` → passes, exit 0
- `git diff --numstat origin/main...HEAD` → exactly `2	2	scripts/bash_gate.py` and `5	0	tests/push_line_tests.sh`
- `shasum -a 256 scripts/bash_gate.py tests/push_line_tests.sh` → the two "after" sha256s in Edit anchors
- `git diff -U0 origin/main...HEAD | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and (len(l) > 121 or any(ord(c) > 126 or (ord(c) < 32 and c != '\t') for c in l))]"` → no output
- **Lead, on the PR head (not the implementer's):** the real-use comparison → 308 the same; the 11 edge probes → the same verdicts as D1; the D1 shell measurement does not depend on the code.

## Review Focus
- `LINE_REDIRS` gains exactly `1> /dev/null` and `&> /dev/null`; nothing else in `scripts/bash_gate.py` changes.
- `simple_line` reads the two new entries as redirections: the push output still cannot reach a file, with or without a space.
- No existing test line changes; the 17 suites pass on Python 3.9.6 and 3.13.

## Don'ts
- Untouchable: `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**`, `plugins/**`, `README.md`, `README.tr.md`, `CHANGELOG.md`, `site/**`, every other test file and every existing line of `tests/push_line_tests.sh`.
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- Do not add a dependency, an option, another entry to `LINE_REDIRS` or a rule. If a case in Out of scope looks easy, write it in the report instead.
- Do not name a form that passes main in the PR title, the PR body or the commit message; refer to "this card's cases" (K313).
- Verification commands never put `git` followed by `update-ref`, `remote` or `push` as words in the command text, except the one push in Step 5.

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`, `bash --version`;
- the red and green counts;
- PR number and branch;
- assumptions;
- every denial of your own commands by the hook, with the command shape.

Read only this card and spec K313, K331, K336, K337 and K338.

## Spec K entry (K338 in the spec)
```text
- **K338** (lead, 2026-11-18, geri alınır) T054 kartı (🔐 Tier 3, `scripts/bash_gate.py`; lead yazdı). Kullanıcı kapı
  2'de "Merge, takip kartı", kapsamda "Evet, ikisi birlikte" dedi; 🔐 onayı sohbette verdi ("Evet, T054 onaylı").
  - **R-L1:** `LINE_REDIRS`'e boşluklu `1> /dev/null` ve `&> /dev/null` girer; listedeki her `/dev/null` biçimi
    boşluklu da boşluksuz da geçer. Tanımlayıcı kopyası yalnız `2>&1`, `1>&2` ve `>&2` kalır; dosya hedefi boşlukla
    da reddedilir. Kapanan: K336'daki Low.
  - **Ölçüm:** bash 3.2.57 ve zsh 5.9 boşluklu biçimde de hedefi sonraki kelimeden okur. Push satırı testi tabanda
    56 ✔ / 2 ✘, prototipte 58 ✔; 17 test dosyası Python 3.9.6 ve 3.13.13'te geçer; 308 gerçek satırın 308'i aynı
    sonucu verir.
  - **Korunan yol (lead, kart dışı):** `delix.json` `protected_paths`'e `plugins/*/.claude-plugin/**` ve
    `plugins/*/hooks/hooks.json` girer (3728ea8 emsali; uygulayıcı `docs/delix/**`'e yazamaz). Korunan izlenen dosya
    17'den 19'a çıkar: panelin manifesti ve `hooks.json`'ı. Modül kodu korunmaz; Stop gate onayı değişmez.
  - **Belge:** README, README.tr ve site metni sonraki sürüm kartında `LINE_REDIRS`'i anar (K298).
```

## Review findings (filled by the lead)
- Round 1 (PR #85, head `f68d43a4585a9a4f35a120254bb8c96f9b275c3c`, 2026-11-18): qa `ACCEPT` (0 P0, 0 P1, 0 P2), security
  `🔐 HUMAN_APPROVAL` (Tier 3, no finding; gitleaks on the diff: no leaks). Lead gates on the clean `git archive` of the
  head: exactly the 2 Files, numstat 2/2 and 5/0; both files equal the lead's prototype byte for byte (the card's
  "after" sha256s); the Stop gate gives `[exit 0]` for both commands, no `✘`; CI `check` and `test` green; 17 suites exit 0 on Python 3.9.6 and 3.13.13 on the archive (1436 `✔` each, 0 `✘`); the
  real-use comparison gives 308 the same; the 11 edge probes give the card's D1 verdicts (4 deny to allow, 7 deny on
  both).
  - Note (security unsure): under a POSIX `sh` (dash) `&> /dev/null` reads as a background `&` and an empty
    redirection, the same as the existing `&>/dev/null`; it writes no file. Claude Code runs zsh on this Mac.
  - Note (qa unsure): the Stop gate output has 16 `ALL PASSED` lines for 17 files; `site_tests.sh` prints no summary
    line (the lead checked).
- Gate 2 (the user, 2026-11-19): merged (K340). The user merged head `f68d43a4585a9a4f35a120254bb8c96f9b275c3c` as it is (merge commit `7f448984a62b1892f3d8047d10296061a116086c`, 2026-11-19T06:51:59Z).
  The merge commit changes only the 2 Files, and they equal the reviewed head byte for byte. Status `accepted`.
