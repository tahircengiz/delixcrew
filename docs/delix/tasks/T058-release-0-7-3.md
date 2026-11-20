# T058 🔐 — Release 0.7.3: version, CHANGELOG heading and PR numbers, site version marks

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T058 | S | 3 | devops | 28 | open |

> 🔐 Tier 3: `.claude-plugin/plugin.json` is protected (`.claude-plugin/**`, `docs/delix/delix.json:16`). The lead adds the Approved line after the user's item-specific yes in chat and commits it to main before dispatch.
> - Filled by the lead at dispatch: release day 2026-11-20, T056 merged as #88, T057 merged as #87, base main `b338f13` (full SHA under Files), line counts and sha256s.
> - The only placeholder left is `<merge commit>` in Step 4, which the user fills after the merge. If any other placeholder is in this card, stop with `NEEDS_CONTEXT`.

**Goal (1 sentence):** Ship T056 and T057 as **0.7.3** (K350: a fix, with no new command, role or gate). That means the plugin version, the CHANGELOG heading in place of `## Unreleased`, the PR numbers in the four items, and the eight version marks and four footer dates of the site. · **Spec:** `docs/delix/specs/D-stale-card-config.md` REQ-4 (line 137), K349, K350; the CLAUDE.md "Site (GitHub Pages)" rule.

**Docs/site:** this card is the version update that CLAUDE.md asks for.

## Files (base: main `b338f13c685d539f82c8580467c4aee5a53896c7`, after #88 and #87 merged)
- Modify: `.claude-plugin/plugin.json` (A1, line 4)
- Modify: `CHANGELOG.md` (A2 to A6, lines 5, 7, 14, 19, 23 as T057 left them)
- Modify: `site/index.html` (A7, A8, lines 29 and 695)
- Modify: `site/tr/index.html` (A9, A10, lines 29 and 695)
- Modify: `site/usage.html` (A11, A12, lines 29 and 244)
- Modify: `site/tr/usage.html` (A13, A14, lines 29 and 244)
- Test: none new. `tests/site_tests.sh` checks the version marks.

## Interfaces
- Consumed: T057's `## Unreleased` section (T057 A13) and the site files, where T057 changed only lines 221, 226 and 389.
- Produced: version `0.7.3`, which the user's tag `v0.7.3` names.

## Lead decisions
- **D1:** T057 changes the site pages only in place (lines 221, 226, 389), so lines 29, 244 and 695 keep their numbers. The CHANGELOG lines come from T057 A13. Checked at dispatch against `b338f13`: every Find below occurs exactly once, at the line numbers in Files.
- **D2:** delix-board stays 0.1.7, because neither card touches `plugins/`.
- **D3:** no Stop gate approval step. The approval hashes only `test_command` and `extra_checks` (`scripts/common.py:78-92`); T056 changes neither, and `docs/delix/delix.json` is unchanged.
- **D4:** the footer date is the CHANGELOG date.

## Edit anchors (replace in the line; each "Find" occurs exactly once in its file)
- **A1** `.claude-plugin/plugin.json`: `"version": "0.7.2"` → `"version": "0.7.3"`
- **A2** `CHANGELOG.md`: `## Unreleased` → `## 0.7.3 — 2026-11-20`
- **A3** `CHANGELOG.md`: `(🔐 K344, K345, K348, K352, K353):` → `(🔐 K344, K345, K348, K352, K353; #88):`
- **A4** `CHANGELOG.md`: `(🔐 K346):` → `(🔐 K346; #88):`
- **A5** `CHANGELOG.md`: `(🔐 K355, K356, K357):` → `(🔐 K355, K356, K357; #88):`
- **A6** `CHANGELOG.md`: `(K347, K348):` → `(K347, K348; #87):`
- **A7 / A9 / A11 / A13**, line 29 of each page: `<span class="ver" data-version="0.7.2">delixcrew 0.7.2</span>` → `<span class="ver" data-version="0.7.3">delixcrew 0.7.3</span>`
- **A8** `site/index.html` and **A12** `site/usage.html`: `<span data-version="0.7.2">delixcrew 0.7.2</span> · as of 2026-11-19.` → `<span data-version="0.7.3">delixcrew 0.7.3</span> · as of 2026-11-20.`
- **A10** `site/tr/index.html` and **A14** `site/tr/usage.html`: `<span data-version="0.7.2">delixcrew 0.7.2</span> · durum 2026-11-19.` → `<span data-version="0.7.3">delixcrew 0.7.3</span> · durum 2026-11-20.`

## Base and after (lead prototype: A1 to A14 applied to a copy of `b338f13`; `tests/site_tests.sh` 23 `✔`)
| File | Lines | sha256 base | sha256 after |
|---|---|---|---|
| `.claude-plugin/plugin.json` | 19 | `9208335ce2008fb4` | `9aa700e457ebb9c4` |
| `CHANGELOG.md` | 291 | `2631ce59e887d408` | `06b2e77a22c3dffd` |
| `site/index.html` | 702 | `4966b99d2bd1c0f6` | `b67fb00f2f855285` |
| `site/tr/index.html` | 702 | `1e1f94833b08dcc5` | `fa6b6790b05464d9` |
| `site/usage.html` | 251 | `653fb7ebfa5aee44` | `89483d2225b0ee1f` |
| `site/tr/usage.html` | 251 | `365a1fc2d37d966f` | `f3dd136448126a2c` |

## Global Constraints
- `plugin.json`: only the version value changes.
- CHANGELOG: only the heading and the four parentheses change. Every line stays at most 120 characters.
- Nothing else changes, including the `Source:` / `Kaynak:` lines and the Umami tag.

## Steps
1. Baseline: `grep -cF 'data-version="0.7.2"'` gives `2` on each page, and `grep -n '^## ' CHANGELOG.md | head -1` gives `5:## Unreleased`.
2. Apply A1 to A14 with the Edit tool. `plugin.json` must use it, because the hook denies shell writes to protected paths.
3. Run Verification and write the output to `.delix/evidence/verification.txt`. Take one screenshot of each page (kicker and footer).
4. Run `git add` with the 6 paths. Commit `Sürüm 0.7.3: bayat kart işareti, delix.json fail closed (#88, #87)`. Push with `git push -u origin HEAD` alone. Open the PR with `--body-file`.
   - The body has `## How I tested`.
   - It also has `## Merge sonrası (kullanıcı, kendi terminali)`:
     - `git fetch origin && git tag -a v0.7.3 -m "delixcrew 0.7.3" <merge commit> && git push origin v0.7.3`
     - `claude plugin marketplace update delixcrew`, then `claude plugin update delixcrew@delixcrew`, then restart Claude.
     - No Stop gate approval step (D3).

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔` (`version 0.7.3 (2 marks)` on each page), no `✘`
- All suites → exit 0 on Python 3.9.6 and through the 3.13 shim, 18 files, no `✘`
- `claude plugin validate .` → exit 0
- `grep -c '"version": "0.7.3"' .claude-plugin/plugin.json` → `1`
- `grep -cF 'data-version="0.7.3"'` on each page → `2`; the same grep for `0.7.2` → `0`
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## 0.7.3 — 2026-11-20` then `29:## 0.7.2 — 2026-11-19`
- `grep -c '#88' CHANGELOG.md` → `3`; `grep -c '#87' CHANGELOG.md` → `1`
- `git diff --numstat origin/main...HEAD` → 6 lines: `plugin.json` 1/1, `CHANGELOG.md` 5/5, each site page 2/2

## Review Focus
- Only version, date and PR values change. TR/EN parity holds. The footer date equals the CHANGELOG date.

## Don'ts
- Do not create or push a tag. No `gh release`, no `gh api` writes, no push to main.
- Touch no path outside Files, and nothing under `docs/delix/**`.

## Report contract
`.delix/report.md` holds:
- the status token;
- the Verification outputs;
- `python3 --version`;
- the screenshot paths;
- the PR number in the `**PR:**` line, and the branch.

Do not write STATE.json. Read only this card and spec K349, K350.

## Review findings (filled by the lead)
- Round 1: …
