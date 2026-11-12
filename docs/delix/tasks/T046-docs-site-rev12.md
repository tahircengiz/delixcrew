# T046 — Docs and site after spec C rev 12: wave-15 behaviour, Known limits, stale lines, delix-board 0.1.6

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T046 | M | 2 | docs | 16 | open |

> Tier 2: no protected path. `plugins/delix-board/.claude-plugin/plugin.json` does not match `.claude-plugin/**`. `scripts/common.py:210–212` matches that entry only from the repo root (`fnmatch` on the relative path, or the prefix `.claude-plugin/`) or on the basename `plugin.json`, as T032 found for 0.1.5. T042 and `/delixcrew:close` own the root `.claude-plugin/plugin.json`, the site's `data-version` marks, the release labels it removes, and `CHANGELOG.md` (K285). The card is Tier 2 because it makes public claims on the site. It changes text only: no new element, class or style, so there is no design-token step.

> **Dispatch precondition (lead):** T042, T043, T044 and T045 are merged. The lead:
> - rewrites every anchor below at the dispatch base (line + content, like T032);
> - writes `labels: on` or `labels: off` in `docs/delix/tasks/T046.dispatch.md`;
> - checks that T044's merged card has `## Docs handover (T046)`.
>
> The anchors are written at base 1da4990. Re-check each one; if the quoted content is not at your base, stop with `NEEDS_CONTEXT`.

**Goal (1 sentence):** README, README.tr, the four site pages and delix-board's README and tech spec describe the wave-15 behaviour, fix the stale lines from the closing drift check, and delix-board becomes 0.1.6 while the root version stays as T042 left it. The wave-15 behaviour is: T043's `--no-lazy-fetch` and raw-input rules, queue rows and the pane's second line; T044's ref-write rule; T045's escalation. · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-2`, `#REQ-5`, `#REQ-6`; §6; K259, K290, K291, K293, K294, K296, K297

**Docs/site:** this card is the update. CLAUDE.md "Site (GitHub Pages)" covers a hook rule and new board behaviour (README Flow and Known limits).

## Inputs (merged; read, do not edit)
- **T044 `## Docs handover (T046)`** (in its card, or the same section in PR body of T044):
  - H1: the implementer rule sentence, EN and TR;
  - H2: the Known-limits sentence(s), EN and TR;
  - H3: the items T044 closed in, or added to, the push-rule out-of-reach list.

  If the section, a part or a language is missing, stop with `NEEDS_CONTEXT`. Do not write these texts yourself. Copy the words as given and HTML-escape `<`, `>`, `&` on the site.
- **Labels:** `{L}` is ` (coming in the next release)` (EN) / ` (sonraki sürümle gelecek)` (TR) with `labels: on`, and empty with `labels: off`.
  - It goes before the final full stop of each new or changed site sentence.
  - A sentence that already ends with a label keeps it and gets no second one.
  - README and docs get no labels.
  - No `labels:` line in the dispatch → `NEEDS_CONTEXT`.
- **T043 / T045:** see Interfaces. If the merged text differs from the wording below only in words, use the merged wording and list each case in the report. If the behaviour differs, stop with `NEEDS_CONTEXT`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `docs/spec/delix-board.md` (lines 3, 40, 48–49, 96–97, 99–104, 154–166, 185)
- Modify: `plugins/delix-board/README.md` (lines 14–25, 49)
- Modify: `plugins/delix-board/.claude-plugin/plugin.json` (line 4)
- Modify: `README.md` (lines 71, 74, 127, 381–386, 398–399, after 402)
- Modify: `README.tr.md` (lines 71, 74, 127, 382–388, 399–400, after 403)
- Modify: `site/usage.html` and `site/tr/usage.html` (lines 98, 124, 225, 226 each)
- Modify: `site/index.html` and `site/tr/index.html` (line 475 each)
- Test: none (docs card; the checks are in Verification)

## Edit anchors (base 1da4990)
- Edit each file bottom-up.
- `[…]` marks an elided middle; the text on each side of it is byte for byte.
- Wrap README and docs prose at ≤ 120 characters. A phrase that Verification greps stays on one line. Never wrap inside a code span.

1. **`docs/spec/delix-board.md`** (Turkish)
   - **Line 185, substring:** `version 0.1.1,` → `version 0.1.6,`. Line 150 `(0.1.1 düzeltmesi)` is history and stays.
   - **Lines 154–166, replace** (from `- Salt okunur: `$.fs.write` yok;` to `Ağ yok: `git fetch` ve `gh` yok; uzak bilgi son fetch anının hâlidir.`) with:
     ```text
     - Salt okunur: `$.fs.write` yok; `$.process.run` yalnız salt-okur yerel git (Spec C, K257, K262, K263, K275, K277,
       K284, K293, K294). Her çağrı `git --no-optional-locks -c core.fsmonitor=false` ile başlar ve 5 sn zaman aşımlıdır;
       depo çağrıları oturumun checkout'unda, worktree çağrıları o worktree'de (`cwd`) koşar. Açılışta bir kez
       `rev-parse --show-toplevel`. 20 sn'de bir: `rev-parse --git-common-dir`, `worktree list --porcelain -z`,
       `for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)`,
       `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`; sonra her
       worktree'de `--no-lazy-fetch status --porcelain`; `.delix/card`'ı hiçbir biçimde (dosya, bağlantı, dizin, okunamayan
       dosya) olmayan ve STATE'i commit'lenmemiş olmayan worktree'de
       `--no-lazy-fetch diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` ve, STATE dosyası varsa,
       `--no-lazy-fetch log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json` (`<default>` = `delix.json`'daki
       `default_branch` Spec C REQ-4 dal kalıbına uyan bir metinse o, değilse `main`). N worktree için bakış başına en çok
       4 + 3N çağrı. Nesne okuyan dört çağrı (`cat-file`, `status`, `diff`, `log`) `--no-lazy-fetch` taşır: kısmi klonda
       eksik nesne uzak depodan çekilmez (K284). git < 2.44 bu bayrağı reddeder: bu çağrılar hata verir, alanlar `?` olur,
       hiçbir kart merge'e hazır olmaz ve o worktree'ler Git işleri komutu almaz (fail closed, K294).
       `refs/remotes/origin/HEAD` yoksa (`git init` + `remote add` ile kurulan depo) hiçbir kart merge'e hazır olmaz;
       `git remote set-head origin -a` onu kurar. `tool.call` hook'ları çağrıyı değiştirmez, reddetmez (gating hook yok).
       Ağ yok: `git fetch` ve `gh` yok; uzak bilgi son fetch anının hâlidir.
     ```
     Sources: merged `plugins/delix-board/hooks/data.ts` (status, diff and log argv at base `:168`, `:173`, `:177`; `<default>` `:128–139`; card check `:164`; budget `:142`), `scripts/board.py` (base `:233–234`, `:267–288`); spec §6 (K284, K294).
   - **Lines 99–104, replace** (from `Spec C bölümleri (`views.tsx` `agentSections`)` to `` `fetch yok`. ``) with:
     ```text
     Spec C bölümleri (`views.tsx` `agentSections`), "Bekleyen kapılar" kutusundan sonra, wave gruplarından önce:
     **Leads** (ana checkout ve lead worktree'leri: dal, spec başlığı, açık / bekleyen / hazır sayısı, STATE'in son
     değişme zamanı `changed_at`, `stale`), **Ajanlar** (rol, worktree, dal, upstream, değişikliğin düştüğü yer,
     commit'lenmemiş dosya sayısı; altında ikinci, soluk bir satırda kartı açan lead (`opened_by`) ve son tur kayıtları
     (`last_round`)), **Seni bekliyor** (kart ya da doğrulama · neden; kartta `opened_by` ve `last_round`),
     **Merge'e hazır** (kart · PR · incelenen SHA; `opened_by` ve `last_round`), **Git işleri** (tür · hedef; komut düz
     metin ya da not; altında "Komutları sen çalıştırırsın; panel çalıştırmaz."). Başlıkta `son fetch: <zaman>` ya da
     `fetch yok`. `last_round` girdisi `<rol> r<tur> @<sha7> <verdict> · by <lead dalı>` biçimindedir; doğrulama
     girdisinde `opened_by` ve `last_round` yoktur (Spec C K290, K291).
     ```
     Sources: merged `views.tsx` `agentSections` (base `:160–231`); spec §4 `queue` row. Take the condition for the second line (every row or only rows with a card) from merged `views.tsx`.
   - **Lines 96–97, replace.** Line 96 is `blocked rapordan). Bir satıra basmak kart ayrıntısını açar. Altta "Bekleyen kapılar" kutusu (yoksa "Bekleyen kapı yok"),`. Line 97 is `` `env_owner` doluysa ortak test ortamı kilidi, verifications özeti (ad · verdict · maliyet).``
     ```text
     blocked rapordan). Bir satıra basmak kart ayrıntısını açar. Özet şeridinin hemen altında, Spec C bölümlerinden ve
     wave gruplarından önce "Bekleyen kapılar" kutusu (yoksa "Bekleyen kapı yok; kapılar sohbette açılır."); `env_owner`
     doluysa kutunun içinde ortak test ortamı kilidi. En altta, wave gruplarından sonra verifications özeti
     ("Doğrulamalar (kartsız)": ad · tarih · verdict · maliyet).
     ```
     Sources: `views.tsx:255–316` (box `:275–289`, `env_owner` `:288`, sections `:291`, waves `:293–298`, verifications `:300–315`).
   - **Lines 48–49, two substrings:** `` (`git status --porcelain` `` → `` (`git --no-lazy-fetch status --porcelain` ``, and `` (`git log -1 --no-show-signature `` → `` (`git --no-lazy-fetch log -1 --no-show-signature ``.
   - **Line 40, replace the whole row** (it starts `| worktree başına `git status --porcelain`;`) with:
     `| worktree başına `git --no-lazy-fetch status --porcelain`; `.delix/card`'ı hiçbir biçimde (dosya, bağlantı, dizin, okunamayan dosya) olmayan ve STATE'i commit'lenmemiş olmayan worktree'de `git --no-lazy-fetch diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` | commit'lenmemiş dosya sayısı; lead tespiti (çıkış 1 = dal STATE'i değiştirmiş) | Üç noktalı, merge-base'e göre (Spec C REQ-1); `--no-ext-diff` dış diff yardımcısını çalıştırmaz (K275); `--no-lazy-fetch` kısmi klonda eksik nesneyi çekmez (K284, K294); kart kuralı K293 |`
   - **Line 3, substring:** `Sürüm: delix-board 0.1.1 (delix 0.2.1 değişmez)` → `Sürüm: delix-board 0.1.6 (ilk onay 0.1.1; kök plugin sürümünü bu belge değiştirmez)`.
2. **`plugins/delix-board/README.md`**
   - **Line 49, substring:** `the Spec C sections Leads, Ajanlar (agents: role, worktree, branch, upstream, where the changes land, uncommitted files), Seni bekliyor (waiting on you), Merge'e hazır (ready to merge) and Git işleri` → `the Spec C sections Leads (with the time each lead's STATE last changed), Ajanlar (agents: role, worktree, branch, upstream, where the changes land, uncommitted files; below it, a dimmed second line with who opened the card and its last review round), Seni bekliyor (waiting on you) and Merge'e hazır (ready to merge), both with who opened each card and its last review round, and Git işleri`.
   - **Lines 14–25, replace** (from `Beside the files it runs only read-only local git,` to `` `origin/HEAD` is missing no card is, and `git remote set-head origin -a` sets it.``) with:
     ```text
     Beside the files it runs only read-only local git, every call as `git --no-optional-locks -c core.fsmonitor=false …`
     (the repository calls in the session's checkout, the others in the worktree they ask about): once at start
     `rev-parse --show-toplevel`; every 20 seconds `rev-parse --git-common-dir`, `worktree list --porcelain -z`,
     `for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)`
     and `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`, then in each
     worktree `--no-lazy-fetch status --porcelain` and, where `.delix/card` does not exist in any form (file, link,
     directory) and `STATE.json` has no uncommitted change,
     `--no-lazy-fetch diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` (`<default>`:
     `default_branch` in `docs/delix/delix.json` when it is a plain branch name, else `main`) and, if it holds a
     `STATE.json`, `--no-lazy-fetch log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`: at most 4 + 3N calls
     per look for N worktrees. `--no-lazy-fetch` keeps a partial clone from fetching a missing object for these reads; git
     older than 2.44 rejects it, so those calls fail, their fields show `?`, no card is ready to merge and those worktrees
     get no git action command.
     There is no `git fetch` and no `gh`, so remote data is as of the last fetch, whose time the header shows. A card is
     ready to merge only when the STATE at `refs/remotes/origin/HEAD` shows the same card, PR and reviewed SHA; when
     `origin/HEAD` is missing no card is, and `git remote set-head origin -a` sets it.
     ```
3. **`plugins/delix-board/.claude-plugin/plugin.json`**, line 4: `  "version": "0.1.5",` → `  "version": "0.1.6",`.
4. **`README.md`**
   - **After line 402, append H2 (EN).** Line 402 is `status skill text only.`, and line 403 is empty. Write it as new lines of the same paragraph.
   - **Lines 398–399, substring.** Replace `With git older than 2.44 nothing does either, because that` + line break + `read uses `--no-lazy-fetch`.` with: `With git older than 2.44 nothing does either: the STATE read and, in each worktree, the `status`, `diff` and `log` calls use `--no-lazy-fetch` (so a partial clone fetches no missing object for them, K284); that git rejects the flag, so those calls fail, their fields show `?` and those worktrees get no Git actions command (K294).`
   - **Lines 381–386.** Replace the substring `K279) is a pattern check on words too, defence in depth and not a GitHub boundary:` with `K279) is a check on words too, an allowlist that fails closed, defence in depth and not a GitHub boundary:`. Then apply H3 to the out-of-reach list, which runs from `words built from variables` to `are out of its reach;`.
   - **Line 127, append** ` <H1 EN>` after `(T041, K279).`
   - **Line 74, two edits.**
     - After `Ready to merge and Git actions;` insert ` Agents, Waiting on you and Ready to merge name who opened each card and its last review round;`.
     - Replace `You run them; the lead never does.` with `You run them; the status skill tells the lead never to run them, and no hook enforces that (see [Known limits](#known-limits)).`
     - Sources: merged `scripts/board.py` `## Waiting on you` / `## Ready to merge` rows (base `:691–697`); `skills/status/SKILL.md:27`.
   - **Line 71, append** before the final ` |`: ` After your merge the lead records it: the card becomes `accepted`, or `escalated` when the merged head is not the commit the reviewers saw (K297).` Source: merged `skills/review/SKILL.md` §4.
5. **`README.tr.md`**
   - **After line 403, append H2 (TR).** Line 403 is `için kural yalnız review ve status skill metnindedir.`
   - **Lines 399–400, substring.** Replace `2.44'ten eski git'te de görünmez, çünkü bu` + line break + `okuma `--no-lazy-fetch` kullanır.` with: `2.44'ten eski git'te de görünmez: STATE okuması ve her worktree'deki `status`, `diff` ve `log` çağrıları `--no-lazy-fetch` kullanır (kısmi klonda bu çağrılar için eksik nesne çekilmez, K284); o git bayrağı reddeder, bu yüzden bu çağrılar hata verir, alanları `?` gösterir ve o worktree'ler Git actions komutu almaz (K294).`
   - **Lines 382–388.** Replace the substring `da kelimeler üzerinde bir kalıp denetimidir, derinlemesine savunmadır, GitHub sınırı değildir:` with `da kelimeler üzerinde, fail closed çalışan bir izin listesi denetimidir, derinlemesine savunmadır, GitHub sınırı değildir:`. Then apply H3 to the list, which runs to `onun erişimi dışındadır;`.
   - **Line 127, append** ` <H1 TR>` after `(T041, K279).`
   - **Line 74, two edits.**
     - After `Git actions bölümleri;` insert ` Agents, Waiting on you ve Ready to merge her kartı kimin açtığını ve son inceleme turunu gösterir;`.
     - Replace `Komutları sen çalıştırırsın; lead hiç çalıştırmaz.` with `Komutları sen çalıştırırsın; status skill'i lead'e onları hiç çalıştırmamasını söyler, bunu bir hook zorlamaz (bkz. [Bilinen sınırlar](#bilinen-sınırlar)).`
   - **Line 71, append** before the final ` |`: ` Merge'den sonra lead bunu kaydeder: kart `accepted` olur; merge edilen uç inceleyicilerin gördüğü commit değilse `escalated` (K297).`
6. **`site/usage.html`**
   - **Line 226, replace the whole `li`:**
     `        <li><code>/delixcrew:status</code> and delix-board run no <code>git fetch</code> and no <code>gh</code>: remote branch data is as of your last fetch. Their object reads use <code>--no-lazy-fetch</code>, so a partial clone fetches nothing for them; git older than 2.44 rejects that flag, so those fields show <code>?</code>, nothing shows as ready to merge and those worktrees get no Git actions command. A card shows as ready to merge only when the STATE at <code>origin/HEAD</code> holds the same review; when <code>origin/HEAD</code> is missing nothing does, and <code>git remote set-head origin -a</code> sets it. No hook stops the lead from running <code>gh pr merge</code> or a Git actions command (a push, <code>git worktree remove</code>, <code>git branch -D</code>) itself; for the lead that rule is skill text. <H2 EN without its final stop>{L}.</li>`
   - **Line 225.** Replace the substring `The implementer push rule is a pattern check on words, not a GitHub boundary:` with `The implementer push rule is a check on words, an allowlist that fails closed, not a GitHub boundary:`. Apply H3, then `{L}` at the end.
   - **Line 124**, before `</td></tr>`, insert: ` Waiting on you and Ready to merge also name who opened each card and its last review round{L}.`
   - **Line 98**, after `The card becomes <code>accepted</code> and the next wave opens.`, insert: ` If the merged head is not the commit the reviewers saw, the card becomes <code>escalated</code> instead and waits on you{L}.`
7. **`site/tr/usage.html`**
   - **Line 226, replace the whole `li`:**
     `        <li><code>/delixcrew:status</code> ve delix-board <code>git fetch</code> ve <code>gh</code> çalıştırmaz: uzak dal bilgisi son fetch anının hâlidir. Nesne okumaları <code>--no-lazy-fetch</code> kullanır, kısmi klonda onlar için hiçbir şey çekilmez; 2.44'ten eski git bu bayrağı reddeder, bu yüzden alanlar <code>?</code> gösterir, hiçbir kart merge'e hazır görünmez ve o worktree'ler Git actions komutu almaz. Bir kart yalnız <code>origin/HEAD</code>'deki STATE aynı incelemeyi taşıyınca merge'e hazır görünür; <code>origin/HEAD</code> yoksa hiçbiri görünmez, <code>git remote set-head origin -a</code> onu kurar. Lead'in <code>gh pr merge</code>'ü ya da bir Git actions komutunu (push, <code>git worktree remove</code>, <code>git branch -D</code>) kendisinin çalıştırmasını bir hook engellemez; lead için bu kural skill metnidir. <H2 TR, son noktası olmadan>{L}.</li>`
   - **Line 225.** Replace the substring `Uygulayıcının push kuralı kelimeler üzerinde bir kalıp denetimidir, GitHub sınırı değildir:` with `Uygulayıcının push kuralı kelimeler üzerinde, fail closed çalışan bir izin listesi denetimidir, GitHub sınırı değildir:`. Apply H3, then `{L}` at the end.
   - **Line 124**, before `</td></tr>`, insert: ` Seni bekleyenler ve merge'e hazır olanlar her kartı kimin açtığını ve son inceleme turunu da gösterir{L}.`
   - **Line 98**, after `Kart <code>accepted</code> olur ve sıradaki wave açılır.`, insert: ` Merge edilen uç inceleyicilerin gördüğü commit değilse kart bunun yerine <code>escalated</code> olur ve seni bekler{L}.`
8. **`site/index.html` line 475** (bash_gate Implementer `dd`). After `<code>gh pr merge</code> is denied` and whatever follows it up to its full stop (a label may or may not be there), insert: ` <H1 EN>{L}. This is a check on the command's words, an allowlist that fails closed: defence in depth, not a GitHub boundary (see Known limits on the usage page){L}.` If H1 already ends with a stop, drop the extra one.
9. **`site/tr/index.html` line 475.** After `<code>gh pr merge</code> reddedilir` and whatever follows it up to its full stop, insert: ` <H1 TR>{L}. Bu, komutun kelimeleri üzerinde fail closed çalışan bir izin listesi denetimidir: derinlemesine savunmadır, GitHub sınırı değildir (bkz. kullanım sayfasındaki Bilinen sınırlar){L}.`

The Source / Kaynak lines stay. They already name README.md (Flow, Known limits), the skills and `scripts/bash_gate.py` (index `:489`, usage `:104`, `:130`, `:240`).

## Interfaces
- Consumed (merged; quote exactly; base line numbers, re-pointed by the lead):
  - T043: the `status`, `diff` and `log` argv with `--no-lazy-fetch` in `data.ts` (base `:168`, `:173`, `:177`) and `scripts/board.py` (base `:267`, `:271`, `:288`).
  - T043: the `default_branch` rule (`data.ts:128–139`; `board.py:233–234`) and the call-5 card rule (`data.ts:164`).
  - T043: `views.tsx` `agentSections` (Leads `changed_at`, Ajanlar second line, Seni bekliyor / Merge'e hazır `opened_by` and `last_round`), and board.py `## Waiting on you` / `## Ready to merge` rows.
  - T044: `## Docs handover (T046)` (H1–H3).
  - T045: `skills/review/SKILL.md` §4 and `skills/close/SKILL.md` §1 (`escalated`, "an unreviewed head was merged").
  - T042: root version and labels, read only.
- Produced: no code interface.

## Global Constraints (verbatim from the spec and CLAUDE.md)
- K259: "delix-board spec §8 git izin listesi ve §6 görünümleri bu spec'le güncellenir (docs kartı); delix-board sürümü artar, kök plugin sürümü değil."
- K290: "delix-board yama sürümü artar."
- K294: "git < 2.44 bayrağı reddeder: 4–6 hata verir, alanlar `?`, o worktree'lerin Git actions'ı not olur" · "Kapsam 4–6: 1–3 ağaç ya da blob okumaz (lead üretmedi, doğrulanmadı); README ve site Known limits'e eski git satırı docs kartıyla girer."
- §6: "Bilinen sınır: lead'in `gh pr merge`'ü ya da bir Git actions komutunu çalıştırmasını bir hook engellemez (yalnız skill metni); Known limits'e yazılır."
- K297: "Farklıysa `merged`'i yine yazar (olgu), kartı `escalated` yapar ve kullanıcıya "incelenmemiş uç merge edildi" der; kart Seni bekliyor'da kalır"
- CLAUDE.md: "Every claim on the site comes from a repo file; each section names its sources in its `Source:` / `Kaynak:` line". The English and Turkish pages carry the same content. No script, event handler, form or third-party asset other than the Umami tag.
- HTML-escape `<`, `>`, `&` inside site text. Write invisible characters only as `\uXXXX`, never raw.

## Steps
1. Read the dispatch (`labels:`) and T044's Docs handover. If either is missing, stop with `NEEDS_CONTEXT`.
2. Red: these Verification checks each fail at your base: `0.1.6`, `an allowlist that fails closed`, the argv loop, `merged head is not the commit the reviewers saw`.
3. Read the merged sources named in Interfaces.
4. Edit the 9 files per the anchors, each file bottom-up.
5. Green: run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
6. Open `site/usage.html`, `site/tr/usage.html`, `site/index.html` and `site/tr/index.html`. Save a screenshot of each Known limits list and each bash_gate card to `.delix/evidence/`.
7. Run `git add` with the 9 paths by name. Commit `T046: docs and site for spec C rev 12; delix-board 0.1.6`. Run `git push -u origin HEAD` as its own command, with no `cd`. Open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, no line starting `✘`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `claude plugin validate .` and `claude plugin validate plugins/delix-board` → pass; `claude plugin test plugins/delix-board` → pass
- `grep -cF '"version": "0.1.6"' plugins/delix-board/.claude-plugin/plugin.json` → `1`
- `git diff origin/main -- .claude-plugin CHANGELOG.md` → no output; `git diff origin/main -- site | grep -c 'data-version'` → `0`
- `grep -cF 'delix-board 0.1.6' docs/spec/delix-board.md` → `1`; `grep -cF 'version 0.1.6' docs/spec/delix-board.md` → `1`; `grep -cF 'version 0.1.1' docs/spec/delix-board.md` → `0`; `grep -cF 'Altta "Bekleyen kapılar"' docs/spec/delix-board.md` → `0`
- `for s in '--no-lazy-fetch status --porcelain' '--no-lazy-fetch diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json' '--no-lazy-fetch log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json' '--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json' '4 + 3N' '2.44'; do for f in docs/spec/delix-board.md plugins/delix-board/README.md; do grep -qF -e "$s" "$f" || echo "missing in $f: $s"; done; done` → no output
- `grep -cE '(`|git )(status --porcelain|diff --no-ext-diff|log -1 )' docs/spec/delix-board.md plugins/delix-board/README.md` → `0` each
- `grep -cF 'the lead never does' README.md` → `0`; `grep -cF 'lead hiç çalıştırmaz' README.tr.md` → `0`
- `grep -cF 'no hook enforces that (see [Known limits](#known-limits))' README.md` → `1`; `grep -cF 'bunu bir hook zorlamaz (bkz. [Bilinen sınırlar](#bilinen-sınırlar))' README.tr.md` → `1`
- `grep -cF 'pattern check on words' README.md site/usage.html` → `0` each; `grep -cF 'bir kalıp denetimidir, derinlemesine' README.tr.md` → `0`; `grep -cF 'kelimeler üzerinde bir kalıp denetimidir' site/tr/usage.html` → `0`
- `grep -cF 'an allowlist that fails closed' README.md site/usage.html site/index.html` → `1` each; `grep -cF 'fail closed çalışan bir izin listesi' README.tr.md site/tr/usage.html site/tr/index.html` → `1` each
- `grep -cF 'merged head is not the commit the reviewers saw' README.md site/usage.html` → `1` each; `grep -cF 'edilen uç inceleyicilerin gördüğü commit değilse' README.tr.md site/tr/usage.html` → `1` each
- `grep -cF 'who opened each card and its last review round' README.md site/usage.html plugins/delix-board/README.md` → `1` each; `grep -cF 'kimin açtığını ve son inceleme turunu' README.tr.md site/tr/usage.html` → `1` each
- `grep -cF 'get no Git actions command (K294)' README.md` → `1`; `grep -cF 'Git actions komutu almaz (K294)' README.tr.md` → `1`
- `grep -cF '2.44' README.md README.tr.md site/usage.html site/tr/usage.html plugins/delix-board/README.md docs/spec/delix-board.md` → `2`, `2`, `1`, `1`, `1`, `1`
- `grep -cF 'git worktree remove</code>, <code>git branch -D</code>' site/usage.html site/tr/usage.html` → `1` each
- `grep -cF 'set-head origin -a' README.md README.tr.md site/usage.html site/tr/usage.html plugins/delix-board/README.md docs/spec/delix-board.md` → `1` each
- `git diff -U0 origin/main -- site | grep -c '^+ '` → `10`. Then:
  - `labels: on`: `git diff -U0 origin/main -- site | grep '^+ ' | grep -cvF -e 'coming in the next release' -e 'sonraki sürümle gelecek'` → `0`
  - `labels: off`: `git diff -U0 origin/main -- site | grep '^+ ' | grep -cF -e 'coming in the next release' -e 'sonraki sürümle gelecek'` → `0`
- One `grep -cF` per H1/H2 sentence (the lead lists them in the dispatch) → `1` in each target file
- `python3 -c "import re,sys;[print(f) for f in sys.argv[1:] if re.search('[\u200b-\u200f\u202a-\u202e\u2060-\u2064\ufeff]', open(f,encoding='utf-8').read())]" docs/spec/delix-board.md plugins/delix-board/README.md README.md README.tr.md site/usage.html site/tr/usage.html site/index.html site/tr/index.html` → no output
- `git diff --stat origin/main` → only the 9 files

## Review Focus
- Every argv, flag and heading matches the merged code byte for byte: `--no-lazy-fetch` comes after the prefix on `status`, `diff` and `log`. No text claims the flag for calls 1–3.
- "Use no network" becomes "run no `git fetch` and no `gh`". The text claims only what K284/K294 support.
- TR/EN parity: README and README.tr; usage and tr/usage; index and tr/index.
- Known limits: the lead is not hook-bound for `gh pr merge` or the Git actions commands. Nothing contradicts `README.md:127` (the implementer deny) or T044's H1/H2.
- Labels follow the dispatch line. The root version, the `data-version` marks and `CHANGELOG.md` are unchanged.
- `index.html:63` and `usage.html:98` keep "the lead never runs `gh pr merge`" (a rule statement sourced to review §4). The card does not change that phrase.

## Don'ts
- Do not touch `scripts/**`, `plugins/delix-board/hooks/**`, `plugins/delix-board/tests/**`, `tests/**`, `skills/**`, `agents/**`, root `.claude-plugin/**`, `CHANGELOG.md`, `STATUS.md` or `docs/delix/**`. On the index pages, change only line 475.
- Do not remove or move a release label (T042's job). Do not write H1–H3 yourself.
- Do not use spec §4's numbering or the `git -C <wt>` form.
- No Verification or helper command puts the words `git` and `push` on one line, apart from step 7's push (`README.md:387–388`).
- Claim nothing the merged code does not do. If the code and this card disagree on behaviour, write `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 1K tokens) with:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output (also in `.delix/evidence/verification.txt`);
- the screenshot paths;
- the PR number;
- every wording you took from merged code instead of this card;
- assumptions.

Read only this card, spec §3–§6 and §9 K290–K297, T044's Docs handover, and the merged files named in Interfaces.

## Review findings (filled by the lead)
- Round 1: …
