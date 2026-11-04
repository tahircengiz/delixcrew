# T033 — 🔐 Release 0.6.3: version, CHANGELOG heading, site version marks and labels

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T033 | S | 3 | docs | 8 | open |

> 🔐 Tier 3: `.claude-plugin/plugin.json` is protected (`.claude-plugin/**` in docs/delix/delix.json). The lead adds the Approved line after the user says "yes" in chat.

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** Ship what `CHANGELOG.md` `## Unreleased` holds (#34–#36, T023–T024; #17, T026–T028) as **0.6.3**. The plugin version, the CHANGELOG heading and the four site pages then name 0.6.3, and the site no longer marks the spec B behaviour as coming. · **Spec:** none (size S; gate 1 is this card). The CLAUDE.md "Site (GitHub Pages)" rule covers a version change. The earlier release PR #45 (0.6.2) is the pattern.

## Files (base origin/main 9be13ad; these 6 files are unchanged since 48384fa)
- Modify: `.claude-plugin/plugin.json` (line 4, `"version": "0.6.2"`)
- Modify: `CHANGELOG.md` (line 5, `## Unreleased`)
- Modify: `site/index.html` (lines 29 and 695; labels on lines 449, 464, 473, 483)
- Modify: `site/tr/index.html` (lines 29 and 695; labels on lines 449, 464, 473, 483)
- Modify: `site/usage.html` (lines 29 and 242; labels on lines 95, 233)
- Modify: `site/tr/usage.html` (lines 29 and 242; labels on lines 95, 233)
- Test: none new. `tests/site_tests.sh` already fails when a page's version differs from `plugin.json`.

## Interfaces
- Consumed: `tests/site_tests.sh` version check (every `data-version` mark equals `plugin.json` `version`).
- Produced: version string `0.6.3`, which the user's tag `v0.6.3` will name after the merge.

## Global Constraints
- `plugin.json`: change only the value `0.6.2` → `0.6.3`. No other key and no reformatting.
- `CHANGELOG.md`: line 5 `## Unreleased` → `## 0.6.3 — 2026-11-04`. Every bullet under it stays byte for byte. Add no new `## Unreleased` heading (PR #45 pattern).
- Site, on all four pages:
  - every `data-version="0.6.2"` → `data-version="0.6.3"`, and its text `delixcrew 0.6.2` → `delixcrew 0.6.3` (2 marks per page, 8 in all);
  - the footer date stays `2026-11-04`;
  - remove each label ` (coming in the next release)` (EN, 6 in all: index 4, usage 2) and ` (sonraki sürümle gelecek)` (TR, 6 in all: index 4, usage 2), including the space before it. The sentence around each label stays as it is, and its final punctuation stays in place.
- Change nothing else on the site. The `Source:` / `Kaynak:` lines, the Umami tag and every other sentence stay.
- No README, `SECURITY.md`, `scripts/**`, `hooks/**`, `tests/**`, `docs/delix/**` or `STATUS.md` change. The lead records the release in STATUS after the merge.

## Steps
1. Baseline: run the verification commands and record the counts (labels 12, `data-version="0.6.2"` 8).
2. Edit the 6 files per Files and Global Constraints. Use the Edit tool for `plugin.json`, because the hook denies shell writes to protected paths.
3. Run the verification commands again and see the expected output.
4. Open each of the four pages from `site/` in a browser and check the kicker and the footer show `delixcrew 0.6.3`. Check that the former label sentences read cleanly. Save one screenshot per page to `.delix/evidence/`.
5. Commit `Sürüm 0.6.3: Stop gate güven çapası (#17) ve triage/feedback düzeltmeleri (#34–#36)` and open a PR.
   - The body has `## How I tested` (commands and output, screenshot paths).
   - It also has `## Merge sonrası (kullanıcı, kendi terminali)` with the block below exactly.

Merge sonrası (kullanıcı):
- `git fetch origin && git tag -a v0.6.3 -m "delixcrew 0.6.3" <merge commit> && git push origin v0.6.3`
- GitHub Security Advisory GHSA-r43g-fqh7-qv2h: patched version `0.6.3`, then publish (user's decision, K194).
- After updating the plugin: once per repository's main checkout, `python3 <plugin dir>/scripts/trust.py allow` (CHANGELOG migration note).

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, no `✘`; `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0; `claude plugin validate .` → passes
- `grep -c '"version": "0.6.3"' .claude-plugin/plugin.json` → `1`
- `grep -c 'data-version="0.6.3"' site/index.html site/tr/index.html site/usage.html site/tr/usage.html` → `2` each; the same grep for `0.6.2` → `0` each
- `grep -cF 'coming in the next release' site/index.html site/usage.html` and `grep -cF 'sonraki sürümle gelecek' site/tr/index.html site/tr/usage.html` → `0` each
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## 0.6.3 — 2026-11-04` then `40:## 0.6.2 — 2026-11-04`
- `git diff --stat origin/main` → only the 6 Files; `git diff origin/main -- CHANGELOG.md` → one changed line

## Review Focus
- Exactly 12 labels removed. No sentence is cut, and no `.` or `)` is lost or doubled.
- `plugin.json` changes only the version value.
- TR/EN parity is unchanged.

## Don'ts
- Do not create or push a tag. Do not run `gh release`, `gh api` writes or `git push` to main.
- Do not edit the Advisory.
- Do not touch any path outside Files.

## Report contract
`.delix/report.md`: one of `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`, the verification outputs, the screenshot paths, the PR number and any assumptions.

**Docs/site:** this card is the site update the CLAUDE.md version rule asks for.

## Review findings (filled by the lead)
- (none yet)
