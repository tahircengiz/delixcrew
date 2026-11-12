# T032 — Docs and site: delix-board spec §4/§6/§8, board README and 0.1.5, README Flow/Files/Known limits, usage pages

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T032 | S | 2 | docs | 13 | open |

> Tier 2: no protected path. `plugins/delix-board/.claude-plugin/plugin.json` does not match `.claude-plugin/**`, because that pattern is anchored at the repo root (`scripts/common.py:211`); the root `.claude-plugin/plugin.json` is not touched. It is Tier 2 because it makes public claims on the site.

**Goal (1 sentence):** The docs and the site describe the merged T029–T031 behaviour, and delix-board's version becomes 0.1.5 while the root version stays unchanged. · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-1`–`#REQ-6`; §6 (Known limits); K245, K247, K259

**Docs/site:** this card is the update. The site is affected because `site/usage.html` line 124 describes `/delixcrew:status` output and its Known limits list mirrors README Known limits (CLAUDE.md: README Flow and Known limits). `site/index.html` and `site/tr/index.html` have no status or board claim; they change only in their line 489 Source / Kaynak line, which still cites `CHANGELOG (Unreleased)` after the 0.6.3 release (T033 review, P2).

## Files
- Modify: `docs/spec/delix-board.md` (§4 table after line 38 and lines 54–56; §6 lines 88–95 and 101–104; §8 lines 139–141)
- Modify: `plugins/delix-board/README.md` (lines 8–12; Views rows lines 36 and 38; lines 58–59)
- Modify: `plugins/delix-board/.claude-plugin/plugin.json` (line 4)
- Modify: `README.md` (Flow row line 74; Files line 91; Known limits: new paragraph right before `## License`)
- Modify: `README.tr.md` (line 74; line 91; new paragraph right before `## Lisans`)
- Modify: `site/usage.html` (line 124; Known limits `ul`: new `li` after line 224)
- Modify: `site/tr/usage.html` (the same elements)
- Modify: `site/index.html` (line 489, Source line only)
- Modify: `site/tr/index.html` (line 489, Kaynak line only)

## Edit anchors
Base: main after T029, T030, T031, **Spec B's T028** (merged, 429e79b) **and T033** (0.6.3 release, wave 8) merge. T028 edits README Known limits after line 339 and `site/usage.html` lines 95, 104, 229–237; T033 changes the `data-version` marks to 0.6.3 and removes the 12 "(coming in the next release)" / "(sonraki sürümle gelecek)" labels, so the labels this card adds are the only ones on the site. Line numbers are from ad27168; the lead refreshes them at dispatch; match the content. **Wave 9 (T034–T036, K262–K263) changes these anchors; the lead rewrites them at dispatch:** §4 rows get the git flags (`--no-optional-locks -c core.fsmonitor=false`), `worktree list --porcelain -z` and a `cat-file blob refs/remotes/origin/<default>:docs/delix/STATE.json` row; `3 + 3N` becomes `4 + 3N` (items 1 and 2); the §8 argv list gains `cat-file blob`; README and site Known limits gain "Ready to merge comes only from the STATE on origin/<default>". Quote section names, commands and messages from the merged code byte for byte.

1. `docs/spec/delix-board.md` (Turkish)
   - §4, after line 38, four table rows:
     - `git for-each-ref refs/heads refs/remotes`: dal ucu, upstream, ahead/behind, commit zamanı; ağ yok.
     - worktree başına `status --porcelain` ve `diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json`: commit'lenmemiş sayı, lead tespiti (üç noktalı, merge-base'e göre).
     - `<common-dir>/FETCH_HEAD` ve `<common-dir>/worktrees/*/FETCH_HEAD` mtime: son fetch.
     - STATE `cards.<T>.agents` / `merged`: kim açtı, kim inceledi, merge kaydı (Spec C REQ-2).
   - Lines 54–56: add the budget sentence "20 sn'de en çok 3 + 3N git çağrısı (K257)".
   - §6 Pano (88–95):
     - Add the five sections: Leads, Ajanlar, Seni bekliyor, Merge'e hazır, Git işleri (komutlar düz metin, panel çalıştırmaz).
     - Lines 94–95 become the K254/K255 rule: `agents` kaydı olan kart Spec C REQ-3'ü, olmayan board.py'nin kuralını izler (Tier 3 + açık → kilit; `in_review` + PR → merge; `merge <sha>` merge edilmiş sayılır; `accepted` = merge edildi, kapı yok).
   - §6 Kart (101–104): add the `agents` record list.
   - §8 lines 139–141 become: "Salt okunur: `$.fs.write` yok; `$.process.run` yalnız salt-okur yerel git (Spec C, K257): açılışta `rev-parse --show-toplevel`; 20 sn'de bir `rev-parse --git-common-dir`, `worktree list --porcelain`, `for-each-ref refs/heads refs/remotes --format=…`, worktree başına `status --porcelain`, kartsız ve STATE'i temiz worktree'de `diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` ve `log -1 --format=%ct -- docs/delix/STATE.json`; N worktree için en çok 3 + 3N çağrı. `tool.call` hook'ları çağrıyı değiştirmez, reddetmez (gating hook yok). Ağ yok: `git fetch` ve `gh` yok; uzak bilgi son fetch anının hâlidir."
2. `plugins/delix-board/README.md`
   - Append to the paragraph at lines 8–12: "Beside the files it runs read-only local git only (`rev-parse`, `worktree list`, `for-each-ref`, and per worktree `status`, `diff --quiet`, `log -1`), at most 3 + 3N calls per 20-second look for N worktrees; no `git fetch`, no `gh`, so remote data is as of the last fetch, whose time the header shows."
   - Pano row (36): append "; leads, agents (role, branch, upstream, where the changes land), what waits on you, what is ready to merge, and the git actions as text (printed, never run)".
   - Kart row (38): append "; the ledger of who opened the card and who reviewed it (`agents`)".
   - Development (58–59): append "`tests/board_parity.ts` is a byte copy of the repository's `tests/fixtures/board_parity.json` behind `export const PARITY = `; `derive` must return its `expected`, and `bash tests/board_tests.sh` checks the copy."
3. `plugins/delix-board/.claude-plugin/plugin.json` line 4: `"version": "0.1.4",` → `"version": "0.1.5",`.
4. `README.md`
   - Flow row 74: append "Below it: Leads, Agents, Waiting on you, Ready to merge and Git actions; each push / merge / cleanup command in its own one-line `bash` block for Desktop's Run button. You run them; the lead never does."
   - Line 91: "`docs/delix/STATE.json` (cards + `verifications` records)" → "`docs/delix/STATE.json` (cards with their `agents` ledger and `merged` record + `verifications` records)".
   - Known limits, new last paragraph: "`/delixcrew:status` and delix-board read only local files and local git: they run no `git fetch` and no `gh`, so remote branch data is as of your last fetch (the header shows its time). The merge command they print carries `--match-head-commit <sha>`, so a stale view cannot merge a head nobody reviewed. No hook stops the lead from running `gh pr merge` or a Git actions command itself; that rule lives in the review and status skill text only."
5. `README.tr.md`: the same content in Turkish at the same three places. Technical terms and section names stay English.
6. `site/usage.html`
   - Line 124, inside the status `td`, append: " Below it: leads, agents, what waits on you, what is ready to merge, and the push / merge / cleanup commands, each in its own one-line block for the Run button (coming in the next release)."
   - After line 224, add `<li><code>/delixcrew:status</code> and delix-board use no network: remote branch data is as of your last <code>git fetch</code>. No hook stops the lead from running <code>gh pr merge</code> itself; that rule is skill text (coming in the next release).</li>`.
   - Source lines 130 and 237 already name README.md (Flow) and README.md (Known limits); leave them.
7. `site/tr/usage.html`: the same two elements in Turkish, with "(sonraki sürümle gelecek)".
8. `site/index.html` and `site/tr/index.html` line 489: in the Source / Kaynak line, `CHANGELOG (Unreleased)` becomes `CHANGELOG 0.6.3`. Nothing else on these two pages changes.

## Interfaces
- Consumed (merged T029–T031; quote exactly): section names, the line "You run these with Desktop's Run button; the lead never runs them.", the command forms, the git argv list, and the panel headings `Leads`, `Ajanlar`, `Seni bekliyor`, `Merge'e hazır`, `Git işleri`.
- Produced: no code interface.

## Global Constraints (verbatim from the spec and CLAUDE.md)
- K259: "delix-board spec §8 git izin listesi ve §6 görünümleri bu spec'le güncellenir (docs kartı); delix-board sürümü artar, kök plugin sürümü değil."
- §6: "Bilinen sınır: lead'in `gh pr merge` çalıştırmasını bir hook engellemez (yalnız skill metni); Known limits'e yazılır."
- CLAUDE.md: "Every claim on the site comes from a repo file"; the English and Turkish pages carry the same content; no script, form, event handler or third-party asset other than the Umami tag.
- HTML-escape `<`, `>`, `&` inside `<code>`. No raw invisible characters.

## Steps
1. Read the merged `scripts/board.py` (`git_sections`), `plugins/delix-board/hooks/views.tsx` and `skills/status/SKILL.md`, and capture the exact names and lines.
2. Edit the 7 files per the anchors.
3. Run `bash tests/site_tests.sh`, the full loop, and both validates.
4. Open `site/usage.html` and `site/tr/usage.html` from `site/` and save a screenshot of each to `.delix/evidence/`.
5. Commit `T032: docs and site for Spec C board visibility; delix-board 0.1.5`. Open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, no `✘`.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0.
- `claude plugin validate .` and `claude plugin validate plugins/delix-board` → pass.
- `grep -cF '"version": "0.1.5"' plugins/delix-board/.claude-plugin/plugin.json` → `1`.
- `git diff origin/main -- .claude-plugin/plugin.json` → no output.
- `git diff origin/main -- site | grep -c 'data-version'` → `0`.
- `grep -cF 'match-head-commit' README.md README.tr.md` → each ≥ 1.
- `grep -cF 'coming in the next release' site/usage.html` equals `grep -cF 'sonraki sürümle gelecek' site/tr/usage.html`.
- `git diff --stat origin/main` → only the 9 files.

## Review Focus
- Every quoted name and command matches the merged code.
- TR/EN parity.
- The Known limits sentence does not claim a hook boundary.
- The root version and every `data-version` mark are unchanged.

## Don'ts
- Do not touch `scripts/**`, `plugins/delix-board/hooks/**`, `plugins/delix-board/tests/**`, `tests/**`, `skills/**`, `.claude-plugin/**` (root), or `CHANGELOG.md` (written at `/delixcrew:close`). On `site/index.html` and `site/tr/index.html` change only item 8.
- Claim nothing the merged code does not do. If they disagree, write `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 1K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output;
- the screenshot paths;
- the PR number;
- assumptions.

Read only this card, spec §3–§6 and the merged files named in Steps.

## Review findings (filled by the lead)
- (none yet)
