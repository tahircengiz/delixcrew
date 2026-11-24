# T064 — Docs: T063's CHANGELOG item and two Known limits sentences (K386, K387)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T064 | S | 2 | docs | 33 | open |

**Tier:** 2. Three documentation files with public text about a security rule, so the card gets a security review;
no file is protected and none matches `test_paths` (`docs/delix/delix.json`), so it is not Tier 3. The site does not
change: it does not carry these sentences, and the version marks go with the release card T068.

**Goal (1 sentence):** `CHANGELOG.md` `## Unreleased` gets the item for T063 (#98) and the Known limits of `README.md`
and `README.tr.md` get the two limits the T063 review settled, so the next release (0.8.0, T068) ships with accurate
notes. · **Spec:** none (size S; gate 1 is this card's approval). Sources: `STATUS.md` §15 K374, K384, K385, K386,
K387; card `docs/delix/tasks/T063-hooks-bash-protected-write-forms.md` (Review findings, rounds 1–4).

**Docs/site:** this card is the docs update. No version change (K386: one release, 0.8.0, by T068).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `CHANGELOG.md` (C1, line 32, the last line of `## Unreleased`).
- Modify: `README.md` (R1, line 433, Known limits).
- Modify: `README.tr.md` (R2, line 434, Bilinen sınırlar).
- Test: none. The change is text; `tests/site_tests.sh` and `tests/sanitize_tests.sh` run unchanged.

## Interfaces
- Consumed: none. Produced: the CHANGELOG item whose first line T068 anchors on (`- **The Bash hook sees the
  protected-path writes its check missed**`).

## Edit anchors (base main `a12c899`, full SHA `a12c89932e9b16469f861c2b8276b3f1934d37b1`)
Use the Edit tool; each current text occurs exactly once. Copy each line as it stands; no new line ends in a blank.

**C1 · `CHANGELOG.md` line 32 · replace.** The line stays as the first line of New; the item follows it, and the blank line and `## 0.7.4 — 2026-11-20` after it do not change.
Current (1 line):
````text
  the drafts of one problem joined in one intake item. The index lists the record among what the lead writes.
````
New (11 lines):
````text
  the drafts of one problem joined in one intake item. The index lists the record among what the lead writes.
- **The Bash hook sees the protected-path writes its check missed** (🔐 K374, K376, K380, K382, K384; #98): in a card
  worktree the Bash write rule (`scripts/bash_gate.py`) now reads the target of every redirect operator spelling
  (such as `>`, `>>`, `>|`, `N>`, `&>`, `&>>`, `>&word`, `<>` and zsh `>!`, `>>!` or `>&|`), with or without a blank
  and after a backslash newline, and every word after `cp`, `mv` or `tee` in any letter case, up to a `;`, `&` or `|`
  outside quotes, one-level substitutions and redirect operators. It used to need a blank after the operator and read
  one word after `cp`, `mv` or `tee`, so with `auth/**` protected a write such as `echo x >auth/x.py`,
  `tee -a auth/x.py` or `cp a auth/x.py -f` reached a protected path without a denial. Every word the old check read
  is still read, the command is scanned in linear time, each distinct word is matched once, and a protected path used
  as a `cp` source is denied too (fail closed). Two limits remain and are in Known limits (K384, K387).
  `tests/redirect_gate_tests.sh` holds the cases and 14 growth checks; a security advisory follows the release.
````

**R1 · `README.md` line 433 · replace.** The line is split; the sentence that starts with `The implementer push rule` goes on as before.
Current (1 line):
````text
substring match (K220); the boundary is Claude Code's Bash permission prompt (K77). The implementer push rule (T041,
````
New (5 lines):
````text
substring match (K220); the boundary is Claude Code's Bash permission prompt (K77). After `cp`, `mv` or `tee` the
Bash write rule reads a one-level `$( )`, `<( )` or `>( )` only up to its first `)`: after a `(` or a quoted or
escaped `)` inside one, the words that follow a `;`, `&` or `|` may not be read; earlier versions did not read them
either (K384). A target with very many path parts costs more than linear time in the path match the hooks share
(`scripts/common.py`); past the 60 s timeout the Bash hook fails closed (K387). The implementer push rule (T041,
````

**R2 · `README.tr.md` line 434 · replace.** The same in Turkish; the sentence that starts with `Uygulayıcının push kuralı` goes on as before.
Current (1 line):
````text
bir alt dize eşleşmesidir (K220); sınır Claude Code'un Bash izin istemidir (K77). Uygulayıcının push kuralı (T041, K279)
````
New (6 lines):
````text
bir alt dize eşleşmesidir (K220); sınır Claude Code'un Bash izin istemidir (K77). `cp`, `mv` ya da `tee`'den sonra
Bash yazma kuralı tek düzeyli bir `$( )`, `<( )` ya da `>( )`'yi yalnız ilk `)`'ye kadar okur: içinde bir `(` ya da
tırnaklı veya kaçışlı bir `)` varsa, ardından gelen `;`, `&` ya da `|`'den sonraki kelimeler okunmayabilir; önceki
sürümler de okumuyordu (K384). Çok sayıda parçası olan bir hedef yolun, hook'ların ortak yol eşlemesindeki
(`scripts/common.py`) süresi doğrusaldan hızlı büyür; 60 s zaman aşımını geçerse Bash hook'u komutu reddeder (K387).
Uygulayıcının push kuralı (T041, K279)
````

**Lead prototype (2026-11-24; a copy of main `93f2718`, where the three files are as on `a12c899`; Python 3.9.6 and
3.13.13):** the three edits applied to that copy give these sha256 prefixes (16 hex) and line counts; compare yours with `shasum -a 256 <file>`.

| file | base | after |
|---|---|---|
| `CHANGELOG.md` | `8cb2f1ccbac3d548` (336 lines) | `c029e5cdb77cace4` (346 lines) |
| `README.md` | `bab0c59c06deb58b` (483 lines) | `7e8f4f93ea5f9252` (487 lines) |
| `README.tr.md` | `17f329eac099e3f2` (486 lines) | `c1c3ef8b447b4198` (491 lines) |

On that copy all 22 test files exit 0 on 3.9.6 and on the 3.13 shim (1790 `✔`, 0 `✘`).

## Global Constraints
- Docs only: no code, no test file, no site page, no `plugin.json`, no version mark.
- Every sentence matches the merged code (`scripts/bash_gate.py` at `4623f51`) and the K decisions it cites.
- The text names no host, path of the maintainer's machine or secret; the examples use `auth/**`, the first
  `protected_paths` entry of `templates/delix.json`.

## Steps
1. Baseline: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → 22 files, exit 0.
2. Apply C1, R1 and R2 with the Edit tool.
3. `shasum -a 256 CHANGELOG.md README.md README.tr.md` gives the "after" prefixes above; if one differs, find the
   anchor before you go on.
4. Run the Verification commands; write their output to `.delix/evidence/verification.txt`, one block per command
   (`$ <command>`, output, `[exit <code>]`). That file stays local.
5. Commit and push:
   - Run `git add CHANGELOG.md README.md README.tr.md` in a call of its own.
   - Commit `T064: T063'ün CHANGELOG maddesi ve iki Bilinen sınır cümlesi (K386, K387)` in a call of its own.
   - Run `git push -u origin HEAD` alone, from the worktree root.
   - Write the PR body below with the Write tool to `.delix/pr-body.md` and open the PR with
     `gh pr create --title "<commit subject>" --body-file .delix/pr-body.md`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, no `✘`, last line `✔ analytics tag: all 4 pages use the same website id`.
- `bash tests/sanitize_tests.sh` → last line `ALL PASSED`, exit 0.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, 22 files, no `✘`, on 3.9.6 and through
  `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`.
- `claude plugin validate .` → exit 0.
- `shasum -a 256 CHANGELOG.md README.md README.tr.md` → the three "after" prefixes of the table above.
- `git diff --numstat origin/main...HEAD` → exactly `10	0	CHANGELOG.md`, `5	1	README.md` and `6	1	README.tr.md`.
- Line length and invisible characters on the added lines (no output):
```text
git diff -U0 origin/main...HEAD -- CHANGELOG.md README.md README.tr.md | python3 -c "import sys,unicodedata as u; [print(l.rstrip()) for l in sys.stdin if l.startswith('+') and not l.startswith('+++') and (len(l.rstrip(chr(10)))>118 or any(u.category(c)=='Cf' for c in l))]"
```

## Review Focus
- Each claim against the merged code and the T063 card: the operator list, where the word list ends, "every word
  the old check read is still read", the `cp` source denial, the 14 growth checks, and the two limits (K384, K387).
- The English and Turkish Known limits sentences say the same thing, and both name the rule as the rest of Known
  limits does (the Bash write rule, Bash yazma kuralı).
- T068 anchors on the first line of C1's item; it must stay one line as written.

## Don'ts
- Untouchable: everything outside the three files, `docs/delix/**`, the site, `.claude-plugin/**`.
- If a test goes red, do not change it: stop with `NEEDS_CONTEXT` in the report.

## Out of scope (each with the reason)
- The version, the CHANGELOG heading and the site's version marks: the release card T068 (K386).
- The security advisory: written by the lead outside the repository, published by the maintainer after the release
  (K377).

## Report contract
At the end, `.delix/report.md` (≤ 1–2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · evidence
(command, output; the Verification outputs are also in `.delix/evidence/verification.txt`) · `python3 --version` on
both runs · PR number and branch · assumptions · remaining work. Read only this card, and the T063 card or
`scripts/bash_gate.py` only where the dispatch allows it.

### PR body (Write tool, then `--body-file`; fill the `<…>` fields from your own run)
````markdown
Kart: [`docs/delix/tasks/T064-docs-t063-changelog-limits.md`](docs/delix/tasks/T064-docs-t063-changelog-limits.md) · STATUS §15 K386, K387 · Tier 2

## Ne değişti
- `CHANGELOG.md`: `## Unreleased` altına T063 (#98) maddesi; sürüm başlığı T068'de (K386).
- `README.md`, `README.tr.md`: Known limits / Bilinen sınırlar paragrafına iki cümle (K384, K387).
- Kod, test, site ve sürüm değişmedi.

## How I tested
- sha256 önekleri kartın prototipiyle aynı: `CHANGELOG.md` `c029e5cdb77cace4`, `README.md` `7e8f4f93ea5f9252`, `README.tr.md` `c1c3ef8b447b4198`.
- `bash tests/site_tests.sh` → exit 0, ✘ yok; `bash tests/sanitize_tests.sh` → `ALL PASSED`, exit 0.
- Tüm suite, <n> dosya: Python 3.9.6 → exit 0, <total> ✔, 0 ✘; 3.13 shim → exit 0, <total> ✔, 0 ✘.
- `claude plugin validate .` → exit 0; numstat `10 0`, `5 1`, `6 1`; 117 karakteri aşan ya da görünmez karakter taşıyan eklenen satır yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
````

## Review findings (filled by the lead)
