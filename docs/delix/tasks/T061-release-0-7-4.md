# T061 🔐 — Release 0.7.4: version, CHANGELOG heading and PR numbers, site version marks

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T061 | S | 3 | devops | 30 | open |

> 🔐 Tier 3: `.claude-plugin/plugin.json` is protected (`.claude-plugin/**`, `docs/delix/delix.json:16`). The lead adds the Approved line after the user's item-specific yes in chat and commits it to main before dispatch.
> - Filled by the lead at dispatch: `<DATE>` (release day), `<PR59>`, `<PR60>`, base main `<SHA>` (after T059 and T060 merged), line counts and sha256s. The lead also re-checks every line number marked "(T060)" against that base.
> - The only placeholder left after that is `<merge commit>` in Step 4, which the user fills after the merge. If any other placeholder is in this card, stop with `NEEDS_CONTEXT`.

**Goal (1 sentence):** Ship T059 and T060 as **0.7.4** (K363: one deny rule on the existing gate, with no new command, role or gate). That means the plugin version, the CHANGELOG heading in place of `## Unreleased`, the PR numbers in the two items, and the eight version marks and four footer dates of the site. · **Spec:** `docs/delix/specs/E-gitdir-bash-outside.md` REQ-3 (scenario "sürüm"), K362, K363; the CLAUDE.md "Site (GitHub Pages)" rule.

**Docs/site:** this card is the version update that CLAUDE.md asks for.

## Files (base: main `<SHA>`, after T059 and T060 merged)
- Modify: `.claude-plugin/plugin.json` (A1, line 4)
- Modify: `CHANGELOG.md` (A2 to A4, lines 5, 7, 14 as T060 left them)
- Modify: `site/index.html` (A5, A6, lines 29 and 695)
- Modify: `site/tr/index.html` (A7, A8, lines 29 and 695)
- Modify: `site/usage.html` (A9, A10, lines 29 and 245 as T060 left them)
- Modify: `site/tr/usage.html` (A11, A12, lines 29 and 245 as T060 left them)
- Test: none new. `tests/site_tests.sh` checks the version marks.

## Interfaces
- **Consumed:**
  - T060's `## Unreleased` section (T060 A21, two items);
  - the site pages: T060 changed index lines 365, 407, 446, 466 and 475 in place, and inserted one line after usage line 222.
- **Produced:** version `0.7.4`, which the user's tag `v0.7.4` names.

## Lead decisions
- **D1 · Line numbers:** some depend on T060.
  - **Moved:** CHANGELOG lines 5, 7 and 14 (A21 inserts 16 lines above the 0.7.3 heading); usage footers 244 → 245 (A19, A20).
  - **Unchanged:** index lines 29 and 695, and usage line 29.
  - At dispatch, check that every Find below occurs exactly once, at the line given.
- **D2:** delix-board stays 0.1.7, because no card touches `plugins/`.
- **D3:** no Stop gate approval step.
  - The approval hashes only `test_command` and `extra_checks` (`scripts/common.py:178-192`).
  - T059's new test file is picked up by the same glob, and `docs/delix/delix.json` is unchanged.
- **D4:** the footer date is the CHANGELOG date (T058 D4).

## Edit anchors (replace in the line; each "Find" occurs exactly once in its file)
- **A1** `.claude-plugin/plugin.json`: `"version": "0.7.3"` → `"version": "0.7.4"`
- **A2** `CHANGELOG.md` (line 5, T060): `## Unreleased` → `## 0.7.4 — <DATE>`
- **A3** `CHANGELOG.md` (line 7, T060): `(🔐 K358, K359, K360):` → `(🔐 K358, K359, K360; #<PR59>):`
- **A4** `CHANGELOG.md` (line 14, T060): `(K358, K361):` → `(K358, K361; #<PR60>):`
- **A5 / A7 / A9 / A11**, line 29 of each page: `<span class="ver" data-version="0.7.3">delixcrew 0.7.3</span>` → `<span class="ver" data-version="0.7.4">delixcrew 0.7.4</span>`
- **A6** `site/index.html` (line 695) and **A10** `site/usage.html` (line 245, T060): `<span data-version="0.7.3">delixcrew 0.7.3</span> · as of 2026-11-20.` → `<span data-version="0.7.4">delixcrew 0.7.4</span> · as of <DATE>.`
- **A8** `site/tr/index.html` (line 695) and **A12** `site/tr/usage.html` (line 245, T060): `<span data-version="0.7.3">delixcrew 0.7.3</span> · durum 2026-11-20.` → `<span data-version="0.7.4">delixcrew 0.7.4</span> · durum <DATE>.`

## Base and after (`<LEAD: prototype table — file, lines (plugin.json 19, CHANGELOG 307, index 702, usage 252), sha256 base, sha256 after>`)

## Global Constraints
- `plugin.json`: only the version value changes.
- CHANGELOG: only the heading and the two parentheses change. Every line stays at most 120 characters.
- Nothing else changes, including the `Source:` / `Kaynak:` lines and the Umami tag.

## Steps
1. Baseline:
   - `grep -cF 'data-version="0.7.3"'` gives `2` on each page;
   - `grep -n '^## ' CHANGELOG.md | head -1` gives `5:## Unreleased`;
   - `grep -c '"version": "0.7.3"' .claude-plugin/plugin.json` gives `1`.
2. Apply A1 to A12 with the Edit tool. `plugin.json` must use it, because the hook denies shell writes to protected paths.
3. Run Verification and write the output to `.delix/evidence/verification.txt`. Take one screenshot of each page (kicker and footer).
4. Commit, push and open the PR:
   - Run `git add` with the 6 paths.
   - Commit `Sürüm 0.7.4: .git reddi, Bash yazım sınırları belgesi (#<PR59>, #<PR60>)`.
   - Run `git push -u origin HEAD` alone.
   - Open the PR with `--body-file`.
   - The body has `## How I tested`.
   - It also has `## Merge sonrası (kullanıcı, kendi terminali)`:
     - `git fetch origin && git tag -a v0.7.4 -m "delixcrew 0.7.4" <merge commit> && git push origin v0.7.4`
     - `claude plugin marketplace update delixcrew`, then `claude plugin update delixcrew@delixcrew`, then restart Claude.
     - No Stop gate approval step (D3).

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔` (`version 0.7.4 (2 marks)` on each page), no `✘`.
- All suites → exit 0 on Python 3.9.6 and through the 3.13 shim, 19 files, no `✘`.
- `claude plugin validate .` → exit 0.
- `grep -c '"version": "0.7.4"' .claude-plugin/plugin.json` → `1`.
- `grep -cF 'data-version="0.7.4"'` on each page → `2`; the same grep for `0.7.3` → `0`.
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## 0.7.4 — <DATE>` then `21:## 0.7.3 — 2026-11-20`; `grep -c '^## Unreleased' CHANGELOG.md` → `0`.
- `grep -cF '; #<PR59>):' CHANGELOG.md` → `1`; `grep -cF '; #<PR60>):' CHANGELOG.md` → `1`.
- `grep -cF "the worktree's own \`.git\` file or" README.md` → `1` (REQ-3 scenario; README is not changed here).
- `git diff --numstat origin/main...HEAD` → 6 lines: `plugin.json` 1/1, `CHANGELOG.md` 3/3, each site page 2/2.

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

Do not write STATE.json. Read only this card and spec REQ-3, K362, K363.

## Review findings (filled by the lead)
- (none yet)
