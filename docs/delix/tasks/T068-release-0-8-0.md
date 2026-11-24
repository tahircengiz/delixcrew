# T068 🔐 — Release 0.8.0: version, CHANGELOG heading, #96 and two new items, site version marks, two descriptions

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T068 | S | 3 | devops | 36 | open |

> 🔐 Tier 3: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` are protected paths
> (`.claude-plugin/**`, `docs/delix/delix.json:16`). The lead adds the `🔐 Approved` line once the maintainer gives an
> item-specific yes in chat, and commits it to main before the session.
> - Filled by the lead at dispatch (2026-11-24): release day `2026-11-24`, T067 = #96, T069 = #97, T062 = #93, base
>   main `34097d75e07f2a1316205594685d62a953d294ba` (T064's merge; the eight files are byte-identical on `9d1fe28`),
>   line counts, sha256s and the `site_tests.sh` count, from the lead's prototype.
> - The only placeholder left is `<merge commit>` in Step 4. The user fills it after the merge. If any other
>   placeholder is in this card, stop with `NEEDS_CONTEXT`.

**Goal (1 sentence):** Ship Spec F (T065 #95, T066 #94, T067 #96), T063 (#98), T069 (#97) and T062 (#93) as
**0.8.0**. That means:
- the plugin version;
- the CHANGELOG heading in place of `## Unreleased`, with the #96 number and the T069 and T062 items;
- the eight version marks and four footer dates on the site;
- the I032 fix of the intake skill description;
- the marketplace description sentence that K371 made wrong.

**Spec:** `docs/delix/specs/F-intake-decisions.md` §6 (D 🔐 Tier 3), §7 DoD, REQ-7, K413; K386; intake I032; the
CLAUDE.md "Site (GitHub Pages)" rule.

**Docs/site:** this card is the version update that CLAUDE.md asks for. The README and site text for T069 comes in
T070, after this card merges (K452, K457).

## Files (base: main `34097d7`; the eight files are byte-identical on `9d1fe28`)
- Modify: `.claude-plugin/plugin.json` (A1, line 4)
- Modify: `.claude-plugin/marketplace.json` (A14, line 6, in the line)
- Modify: `CHANGELOG.md` (A2 line 5, A3 line 27, A4 insert after line 45)
- Modify: `site/index.html` (A5 line 29, A6 line 695)
- Modify: `site/tr/index.html` (A7 line 29, A8 line 695)
- Modify: `site/usage.html` (A9 line 29, A10 line 247)
- Modify: `site/tr/usage.html` (A11 line 29, A12 line 247)
- Modify: `skills/intake/SKILL.md` (A13, line 3, in the line)
- Test: none new. `tests/site_tests.sh` checks the version marks.

## Interfaces
- **Consumed:**
  - the `## Unreleased` section, lines 5–45: the #95, #94, T067 and T063 (#98) items;
  - T069's merged code (#97, `05989b8`): `scripts/common.py:142-175`, `skills/dispatch/SKILL.md:13-18,41-44`,
    `skills/implement/SKILL.md:25`;
  - T062's merged text (#93, `396bbea`);
  - `scripts/intake.py:243-276`.
- **Produced:** version `0.8.0`, which the user's tag `v0.8.0` names. It is also the advisory's fixed version (K386).

## Lead decisions
- **D0 · Base:** line numbers and Find strings come from `34097d7`. Every Find below occurs exactly once in its file
  there (checked by the lead's applier).
- **D1 · Version (K386):** `0.8.0` (the user: one release for Spec F, T069, T063 and T062; there is no 0.7.5).
  Release day `2026-11-24`. The footer date equals the CHANGELOG date (T061 D4).
- **D2 · T069 item (K439):** the first item in A4, exactly as agreed with the I002 lead. K457 puts it in 0.8.0; T070
  does not repeat it.
- **D3 · T062 item (K440):** T062's D5 left its CHANGELOG entry to the next release card. It is the second item in
  A4 (7 lines, at most 116 characters each). Each claim and its base source:
  - a GitHub install without a version bump: `README.md:45-46`, `README.tr.md:44-45`; the site gives the general rule
    plus the local-folder exception, `site/usage.html:74`, `site/tr/usage.html:74`;
  - the local-folder hooks measurement (Claude Code 2.1.328): `README.md:46-47`, `README.tr.md:45-46`,
    `site/usage.html:74`, `site/tr/usage.html:74`; Known limits `README.md:416-418`, `README.tr.md:418-420`,
    `site/usage.html:225`;
  - the one allowed `cat` heredoc: `README.md:463-465`, `README.tr.md:468-469`;
  - a Bash write outside the worktree is not in the qa diff: `README.md:404-406`, `README.tr.md:406-408`,
    `site/index.html:446`, `site/tr/index.html:446`, `site/usage.html:224`, `site/tr/usage.html:224`;
  - the implement skill: `skills/implement/SKILL.md:16-20`; the deny message is at `scripts/write_gate.py:115-118`;
  - K364 (`docs/delix/specs/E-gitdir-bash-outside.md:169-173`) and K371 (`README.md:47`).
- **D4 · I032 (K441):** `skills/intake/SKILL.md:3` says the skill "records a decision only after the maintainer
  names it with the item id in chat". The body does not: add step 3 (lines 53–56) writes a `duplicate`, `defer` or
  `needs-info` that the table gives with no consent, while add step 2 (lines 50–52) and `scripts/intake.py:269` ask
  for consent on every decision of a `gate_open` item, even the table `duplicate` that `:247-248` gives for
  `covered_by`. A13 adds the one exception to that clause. The line stays one YAML line and gains no `: ` and no `#`.
  No CHANGELOG line: the skill is new in this release and the #94 item (lines 17–26) already states the rule. The
  lead records `work: T068` on I032 on main; that is not part of this card.
- **D5:** no Stop gate approval step. `docs/delix/delix.json` is unchanged since `v0.7.4`; delix-board stays as it
  is, because `plugins/` is unchanged since `v0.7.4`.
- **D6:** CHANGELOG lines over 120 characters in old sections stay as they are (intake I027, `defer`). Do not rewrap.
- **D7 · Post-merge (PR body):** the tag, the marketplace update, the plugin update and a restart. Nothing else.
- **D8 · Marketplace description (K442):** `.claude-plugin/marketplace.json:6` says a local-path install "is a
  cached copy too and updates the same way (claude plugin update after a version bump)". Since T062 (K371,
  `README.md:46-47`) the README says its hooks ran from the folder itself, so a change there reaches them at once.
  A14 makes the sentence say the same; the rest of the line and the file stay byte for byte. No CHANGELOG line: the
  T062 item states the behaviour.

## Edit anchors (base `34097d7`; no Find or Replace starts or ends with a space)
- **A1** `.claude-plugin/plugin.json` line 4: `"version": "0.7.4"` → `"version": "0.8.0"`
- **A2** `CHANGELOG.md` line 5: `## Unreleased` → `## 0.8.0 — 2026-11-24` (the dash is U+2014, as in the other
  headings)
- **A3** `CHANGELOG.md` line 27: `(K408, K415):` → `(K408, K415; #96):` (the line becomes 112 characters)
- **A4** `CHANGELOG.md`: insert 14 lines after line 45. Line 45 is the last line of the T063 item and reads
  `  release.` (two leading spaces). The blank line 46 stays. Edit with this Find (the end of line 44 and line 45;
  `security advisory follows the` occurs once):
```text
a security advisory follows the
  release.
```
Replace with:
```text
a security advisory follows the
  release.
- **A finished card's marker that blocks the next card now names the cause** (🔐 K453, K455, K456; #97): when the
  write gate denies a new `.delix/card` because the old marker still stands, the message adds one `Cause:`
  sentence if the old card is in fact finished but its record in the STATE on origin/HEAD has no string `file`
  field, or if it is finished on `origin/<default_branch>`, the `default_branch` in the worktree's `delix.json`,
  while `refs/remotes/origin/HEAD` points elsewhere. What counts as finished does not change.
  `/delixcrew:dispatch` now writes `file` in every card record and, before the first session, checks that
  origin/HEAD points at `origin/<default_branch>`; `/delixcrew:implement` quotes the deny message above `BLOCKED`.
- **The docs say where the hooks run from and what a Bash write can reach** (K364, K371; #93): README, README.tr and
  the site say that with a GitHub install a change without a version bump does not reach the installed copy, while
  the hooks of a local-folder install ran from the folder itself in a measurement with Claude Code 2.1.328, so a
  change or a `git pull` there reaches them at once. The one allowed `cat` heredoc can write the worktree's `.git`
  and a target outside the worktree, and a Bash write outside the worktree, such as into the main checkout, is not
  in the diff that qa reviews. `/delixcrew:implement` says that Write and Edit never write the worktree's `.git` and
  gives the `info/exclude` command of the deny message as the one Bash write there.
```
- **A5 / A7 / A9 / A11**, line 29 of each page: `<span class="ver" data-version="0.7.4">delixcrew 0.7.4</span>` →
  `<span class="ver" data-version="0.8.0">delixcrew 0.8.0</span>`
- **A6** `site/index.html` line 695 and **A10** `site/usage.html` line 247:
  `<span data-version="0.7.4">delixcrew 0.7.4</span> · as of 2026-11-20.` →
  `<span data-version="0.8.0">delixcrew 0.8.0</span> · as of 2026-11-24.`
- **A8** `site/tr/index.html` line 695 and **A12** `site/tr/usage.html` line 247:
  `<span data-version="0.7.4">delixcrew 0.7.4</span> · durum 2026-11-20.` →
  `<span data-version="0.8.0">delixcrew 0.8.0</span> · durum 2026-11-24.`
- **A13** `skills/intake/SKILL.md` line 3, in the line. Find:
```text
and records a decision only after the maintainer names it with the item id in chat.
```
Replace with:
```text
and records a decision only after the maintainer names it with the item id in chat, except a duplicate, defer or needs-info that the table gives for an item that is not gate_open.
```
- **A14** `.claude-plugin/marketplace.json` line 6, in the line. Find:
```text
A local-path install is a cached copy too and updates the same way (claude plugin update after a version bump); claude --plugin-dir reads a folder in place.
```
Replace with:
```text
A local-path install gets a cached copy too, but its hooks ran from the folder itself in a measurement with Claude Code 2.1.328, so a change there reaches them at once; claude --plugin-dir reads a folder in place.
```

## Base and after (lead prototype, 2026-11-24, base `34097d7`)
An independent applier of A1 to A14 on a copy of the base gave these sha256 prefixes (16 hex). Compare yours with
`shasum -a 256 <file>`. If one differs, find the anchor before you go on.

| file | lines (base → after) | base | after |
|---|---|---|---|
| `.claude-plugin/plugin.json` | 19 → 19 | `3d12a7ec6af2bdfa` | `9a9b421b216fa0a6` |
| `.claude-plugin/marketplace.json` | 19 → 19 | `bb4af5920901ed31` | `578abbf5f21f455a` |
| `CHANGELOG.md` | 349 → 363 | `27d93a5301815a3d` | `76daca1c6f1fddda` |
| `site/index.html` | 702 → 702 | `ed50a80591fc4a07` | `724cd474e5e2e3bb` |
| `site/tr/index.html` | 702 → 702 | `d1da2018b021c9ca` | `0f57d0ee6a0f8520` |
| `site/usage.html` | 254 → 254 | `e756c0ea32a29a90` | `5059b926138e127a` |
| `site/tr/usage.html` | 254 → 254 | `1edeee0f32ea1d6b` | `9cf4214cab72e9f1` |
| `skills/intake/SKILL.md` | 76 → 76 | `9cd27c5e0e77bf04` | `0b277c1b7e89af8c` |

The applier found every Find once, at the line given, and gave the same output twice. On the after copy:
`tests/site_tests.sh` 23 `✔`, 0 `✘`; every grep in Verification as written; numstat as listed; no added line with a
trailing space; no added CHANGELOG line over 120 characters (line 27: 112). All suites exit 0 on Python 3.9.6 and
3.13.13 (22 files each). `claude plugin validate .` passes with the two warnings the base also gives (root
`CLAUDE.md`, no icon).

## Global Constraints
- Spec §6: "D sürüm 🔐 Tier 3 (`.claude-plugin/plugin.json`)". §7: "tüm suite Python 3.9.6 ve 3.13'te geçer";
  "`claude plugin validate .` geçer (yeni skill); `bash tests/site_tests.sh` geçer (C, D)"; "D: `qa` + `security` +
  insan onayı 🔐; PR gövdesinde "How I tested"".
- CLAUDE.md: every `data-version` mark and its `delixcrew <version>` text change. There are no "coming in" /
  "ile gelecek" labels on the base pages. No `Source:` / `Kaynak:` line, Umami tag or other page text changes.
- `plugin.json`: only the version value changes. `marketplace.json`: only the A14 sentence changes; the file stays
  valid JSON.
- CHANGELOG: only the heading, one parenthesis and the two inserted items change. Added lines are at most 120
  characters, with a two-space continuation indent and no trailing space.
- Skill line 3: only the A13 clause changes. It stays one line, with no added `: ` or `#` and no trailing space.
- Public repository: no folder name, user path, host or personal data in the added text, and no raw invisible
  character.

## Steps
1. Baseline:
   - `grep -cF 'data-version="0.7.4"'` on each page → `2`;
   - `grep -n '^## ' CHANGELOG.md | head -2` → `5:## Unreleased`, `47:## 0.7.4 — 2026-11-20`;
   - `grep -c '"version": "0.7.4"' .claude-plugin/plugin.json` → `1`;
   - `grep -cF 'names it with the item id in chat. Only' skills/intake/SKILL.md` → `1`;
   - `grep -cF 'is a cached copy too and updates the same way' .claude-plugin/marketplace.json` → `1`;
   - the base sha256s and `wc -l` match the table.
2. Apply A1 to A14 with the **Edit tool** only, because the hook denies shell writes to protected paths. Change
   nothing else.
3. Compare the after sha256s. Run Verification and write the output to `.delix/evidence/verification.txt`. Take one
   screenshot of each page (kicker and footer) and save it in `.delix/evidence/`.
4. Commit, push and open the PR:
   - Run `git add` with the 8 paths by name.
   - Commit `Sürüm 0.8.0: intake kaydı, bitmiş kart nedeni, Bash yazım biçimleri (#93–#98)`.
   - Run `git push -u origin HEAD` alone.
   - Write the body to `.delix/pr-body.md` with the **Write tool**, not a heredoc.
   - Run `gh pr create --title "<commit subject>" --body-file .delix/pr-body.md`.
   - The body has `## How I tested` (commands, outputs, both Python versions).
   - It also has `## Merge sonrası (kullanıcı, kendi terminali)`:
     - `git fetch origin && git tag -a v0.8.0 -m "delixcrew 0.8.0" <merge commit> && git push origin v0.8.0`
     - `claude plugin marketplace update delixcrew`, then `claude plugin update delixcrew@delixcrew`, then restart
       Claude.
     - No Stop gate approval step (D5).

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔`, `version 0.8.0 (2 marks)` on each of the 4 pages, no `✘`.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0 on `python3` 3.9.6, 22 files, no `✘`.
- The same on 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in
  tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done` → exit 0. If the binary is missing, say so.
- `claude plugin validate .` → exit 0. A warning that the base also gives is fine; report it.
- `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('.claude-plugin/plugin.json')); print('ok')"` → `ok`.
- `grep -c '"version": "0.8.0"' .claude-plugin/plugin.json` → `1`.
- `grep -cF 'data-version="0.8.0"'` on each page → `2`; the same grep for `0.7.4` → `0`.
- `grep -cF '· as of 2026-11-24.' site/index.html site/usage.html` → `1` each;
  `grep -cF '· durum 2026-11-24.' site/tr/index.html site/tr/usage.html` → `1` each.
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## 0.8.0 — 2026-11-24` then `61:## 0.7.4 — 2026-11-20`;
  `grep -c '^## Unreleased' CHANGELOG.md` → `0`.
- `grep -cF '; #96):' CHANGELOG.md` → `1`; the same for `'; #97):'` → `1` and `'; #93):'` → `1`.
- `grep -cF 'The docs say where the hooks run from and what a Bash write can reach' CHANGELOG.md` → `1`.
- `grep -cF 'in chat, except a duplicate, defer or needs-info that the table gives for an item that is not gate_open.' skills/intake/SKILL.md` → `1`.
- `grep -cF 'with the item id in chat. Only' skills/intake/SKILL.md` → `0`.
- `grep -cF 'but its hooks ran from the folder itself in a measurement with Claude Code 2.1.328' .claude-plugin/marketplace.json` → `1`; `grep -cF 'updates the same way' .claude-plugin/marketplace.json` → `0`.
- `python3 -c "l=open('skills/intake/SKILL.md',encoding='utf-8').read().split(chr(10))[2]; print(l.startswith('description: Keeps the intake record'), l.count(': '), l.count('#'), l.endswith(' '))"` → `True 1 0 False`.
- `git diff -U0 origin/main...HEAD -- CHANGELOG.md skills/intake/SKILL.md .claude-plugin | LC_ALL=C awk '/^\+/ && !/^\+\+\+/ && / $/'` → no output.
- `git diff -U0 origin/main...HEAD -- CHANGELOG.md | LC_ALL=C awk '/^\+/ && !/^\+\+\+/ && length($0) > 121'` → no
  output. This counts bytes, and bytes ≥ characters.
- `wc -l CHANGELOG.md` → `363`.
- `git diff --numstat origin/main...HEAD` → exactly:
```text
1	1	.claude-plugin/marketplace.json
1	1	.claude-plugin/plugin.json
16	2	CHANGELOG.md
2	2	site/index.html
2	2	site/tr/index.html
2	2	site/tr/usage.html
2	2	site/usage.html
1	1	skills/intake/SKILL.md
```

## Review Focus
- Only the version, the dates, `#96`, the two items, the A13 clause and the A14 sentence change. TR/EN parity holds.
  The footer date equals the CHANGELOG date.
- The T069 item is byte-identical to D2. Check the T062 item against the D3 sources.
- A13 against `scripts/intake.py:247-252,267-270` and skill lines 50–56 and 63–70. YAML: one plain scalar, no new
  `: ` or `#`.
- A14 against `README.md:43-48` and K371.

## Don'ts
- No tag, no `gh release`, no `gh api` writes, no push to main, no merge.
- Touch no path outside Files: nothing under `docs/delix/**`, `README.md`, `README.tr.md` or `plugins/**`.
- Do not rewrap old CHANGELOG lines (D6) and do not reword D2.
- If a Find is not unique, or a sha256 still differs after you re-checked the anchor, stop with `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` holds:
- the status token;
- the Verification outputs (also in `.delix/evidence/verification.txt`);
- `python3 --version` and the 3.13 version;
- the screenshot paths;
- the PR number in the `**PR:**` line, and the branch;
- assumptions.

Do not write STATE.json. Read only this card and spec §6, §7, K413.

## Review findings (filled by the lead)
- Round 1: …
