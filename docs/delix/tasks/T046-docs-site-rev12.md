# T046 — Docs and site after spec C rev 12: wave-15 behaviour, Known limits, stale lines, delix-board 0.1.6

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T046 | M | 2 | docs | 16 | open |

> Tier 2: no protected path. `plugins/delix-board/.claude-plugin/plugin.json` does not match `.claude-plugin/**`. `scripts/common.py:210–212` matches that entry only from the repo root (`fnmatch` on the relative path, or the prefix `.claude-plugin/`) or on the basename `plugin.json`, as T032 found for 0.1.5. T042 and `/delixcrew:close` own the root `.claude-plugin/plugin.json`, the site's `data-version` marks, the release labels it removes, and `CHANGELOG.md` (K285). The card is Tier 2 because it makes public claims on the site. It changes text only: no new element, class or style, so there is no design-token step.

> **Dispatch precondition (lead):** T043, T044, T045, T047 and T048 are merged; the release card T042 comes after this card (K309). The lead:
> - rewrites every anchor below at the dispatch base (line + content, like T032);
> - writes `labels: on` or `labels: off` in `docs/delix/tasks/T046.dispatch.md`;
> - checks that the merged T044, T047 and T048 cards have `## Docs handover (T046)`.
>
> The anchors are written at base 1da4990. Lead, 2026-11-14: the 9 files are unchanged from 1da4990 to 8e8fedd (`git diff --stat` over them is empty), so every anchor holds as written; the merged-code line numbers in Sources and Interfaces are re-pointed to 8e8fedd (they were `base :…`). Re-check each anchor; if the quoted content is not at your base, stop with `NEEDS_CONTEXT`.

**Goal (1 sentence):** README, README.tr, the four site pages and delix-board's README and tech spec describe the wave-15 behaviour, fix the stale lines from the closing drift check, and delix-board becomes 0.1.6 while the root version stays as it is (T042 releases after this card, K309). The wave-15 behaviour is: T043's `--no-lazy-fetch` and raw-input rules, queue rows and the pane's second line; T044's ref-write rule; T045's escalation; with it the `bash_gate` reading of T047 (wave 17) and T048 (wave 18). · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-2`, `#REQ-5`, `#REQ-6`; §6; K259, K290, K291, K293, K294, K296, K297, K305, K306, K309, K311

**Docs/site:** this card is the update. CLAUDE.md "Site (GitHub Pages)" covers a hook rule and new board behaviour (README Flow and Known limits).

## Inputs (merged; read, do not edit)
- **`## Docs handover (T046)` of three merged cards:**
  - `docs/delix/tasks/T044-bash-gate-ref-writes.md`: H1 (the implementer rule sentence), H2 (the Known-limits sentences), H3 (the push-rule out-of-reach list), EN and TR;
  - `docs/delix/tasks/T047-bash-gate-argv.md`: H0 to H4;
  - `docs/delix/tasks/T048-bash-gate-parser.md`: H0 to H3.

  T047 and T048 are merged, so take the "merged first" branch of each H0 (the lead confirmed both merges: T047 `5914313`, T048 `12b3d26`). If a section, a part or a language is missing, stop with `NEEDS_CONTEXT`. Do not write these texts yourself. Copy the words as given and HTML-escape `<`, `>`, `&` on the site; a backticked word is a `<code>` element there.
- **Composition (lead, K311).** Below, "H1", "H2" and "H3" in the anchors mean these composed texts:
  - **H1** = T044 H1, then T047 H1, then T048 H1, as one run of sentences in that order (README Bash paragraph, site index bash_gate Implementer cell).
  - **H2** = T044 H2 with T047 H2's parenthetical in place of T044's: `(such as `git symbolic-ref`, `git fast-import`, `git fetch` with a refspec into `refs/remotes/`, or `git branch -f`)` / `(`git symbolic-ref`, `git fast-import`, `refs/remotes/` içine refspec'li `git fetch` ya da `git branch -f` gibi)`.
  - **H3**, three changes to the push-rule list; every other item stays. In the README each quoted phrase below may wrap over two lines:
    1. Remove T044 H3's `git remote` URL item (T047 H4 confirms it), with its comma.
    2. The variables item becomes T048 H2:
       - README EN: `words built from variables, `eval`, globs or ANSI-C quoting (`$'...'`),` → `words built from <T048 H2 EN>,`;
       - README TR: `değişken, `eval`, glob ya da ANSI-C tırnağı (`$'...'`) ile kurulan kelimeler` → `<T048 H2 TR> ile kurulan kelimeler`;
       - site EN: `words built from variables, <code>eval</code>, globs or ANSI-C quoting,` → `words built from <T048 H2 EN>,`;
       - site TR: `değişken, <code>eval</code>, glob ya da ANSI-C tırnağıyla kurulan kelimeler` → `<T048 H2 TR> ile kurulan kelimeler`.
    3. The false-positive clause: after `an `echo` or a commit message,` (TR `tek satırındaki `git` ve `push` kelimelerini`) insert the text below; the clause's existing last item (the push in a command that also has `cd` …) stays last. T044's and T048's "and" are dropped and the Turkish objects take the accusative so the list reads as one series:
       - EN: ` the words `git` and `update-ref` on one line there, a `git remote` form outside its read forms (run `git fetch` to refresh refs), a quote that is never closed in front of a `git` word, also in a heredoc body (close the quote or put the text in a file), a command nested too deep for the hook to read,` (README and site; the README's `, and a push in a command` keeps its `and`).
       - TR: `, aynı satırda `git` ve `update-ref` kelimelerini, okuma biçimleri dışındaki bir `git remote` biçimini (ref'leri tazelemek için `git fetch` çalıştır), bir `git` kelimesinin önünde, heredoc gövdesinde de, hiç kapanmayan tırnağı (tırnağı kapat ya da metni bir dosyaya yaz), hook'un okuyamayacağı kadar derin iç içe bir komutu` (README and site, before ` ve `cd` ya da`).
  - T048 H0: the forms T048 closes are not added as Known limits. Nothing about the brace-group false positive is written (T048 H3's last line).
- **Labels:** `{L}` is ` (coming in the next release)` (EN) / ` (sonraki sürümle gelecek)` (TR) with `labels: on`, and empty with `labels: off`.
  - It goes once at the end of each inserted or changed site block, before its final full stop, as anchor 8 shows: the H1 run of sentences gets one `{L}`, not one per sentence.
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
     Sources: merged `plugins/delix-board/hooks/data.ts` at 8e8fedd (`cat-file` `:190`; status, diff and log argv `:198`, `:203`, `:207`; `<default>` `:148–159`; card check `:161–168`; budget `:171–175`), `scripts/board.py` (`<default>` `:246–247`; status, diff, log, `cat-file` `:280`, `:284–285`, `:301`, `:305`); spec §6 (K284, K294).
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
     Sources: merged `views.tsx` `agentSections` (`:167–248`, caption `:159–163`); spec §4 `queue` row. The condition for the second line, from merged `views.tsx`: Ajanlar and Seni bekliyor rows that have a card (`:203`, `:218`), every Merge'e hazır row (`:232`); the text above says "kartta" for Seni bekliyor, and for Ajanlar write `kartı olan satırda altında ikinci, soluk bir satırda` in place of `altında ikinci, soluk bir satırda`.
   - **Lines 96–97, replace.** Line 96 is `blocked rapordan). Bir satıra basmak kart ayrıntısını açar. Altta "Bekleyen kapılar" kutusu (yoksa "Bekleyen kapı yok"),`. Line 97 is `` `env_owner` doluysa ortak test ortamı kilidi, verifications özeti (ad · verdict · maliyet).``
     ```text
     blocked rapordan). Bir satıra basmak kart ayrıntısını açar. Özet şeridinin hemen altında, Spec C bölümlerinden ve
     wave gruplarından önce "Bekleyen kapılar" kutusu (yoksa "Bekleyen kapı yok; kapılar sohbette açılır."); `env_owner`
     doluysa kutunun içinde ortak test ortamı kilidi. En altta, wave gruplarından sonra verifications özeti
     ("Doğrulamalar (kartsız)": ad · tarih · verdict · maliyet).
     ```
     Sources: `views.tsx` at 8e8fedd (box `:294–308`, empty text `:300`, `env_owner` `:307`, sections `:310`, waves `:312–317`, verifications `:319–334`).
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
     - Sources: merged `scripts/board.py` `## Waiting on you` / `## Ready to merge` rows (`:714–720`, ledger text `_ledger` `:463–469`); `skills/status/SKILL.md:27`.
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
  - T043: the `status`, `diff` and `log` argv with `--no-lazy-fetch` in `data.ts` (`:198`, `:203`, `:207`) and `scripts/board.py` (`:280`, `:284–285`, `:301`); the `cat-file` read (`data.ts:190`, `board.py:305`).
  - T043: the `default_branch` rule (`data.ts:148–159`; `board.py:246–247`) and the call-5 card rule (`data.ts:161–168`).
  - T043: `views.tsx` `agentSections` (`:167–248`: Leads `changed_at`, Ajanlar second line, Seni bekliyor / Merge'e hazır `opened_by` and `last_round`), and board.py `## Waiting on you` / `## Ready to merge` rows (`:714–720`).
  - T044, T047, T048: `## Docs handover (T046)` (T044 H1–H3, T047 H0–H4, T048 H0–H3), composed as in Inputs; the rules they describe are in merged `scripts/bash_gate.py`.
  - T045: `skills/review/SKILL.md` §4 (`:84–85`) and `skills/close/SKILL.md` §1 (`:16`) (`escalated`, "an unreviewed head was merged").
  - T042: root version and labels, read only.
  - All line numbers are at 8e8fedd.
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
1. Read the dispatch (`labels:`) and the Docs handovers of T044, T047 and T048. If one is missing, stop with `NEEDS_CONTEXT`.
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
- H3: `grep -cF 'another URL for' README.md site/usage.html` → `0` each; `grep -cF 'verilen başka bir URL' README.tr.md site/tr/usage.html` → `0` each
- H3: `for s in 'brace expansion' 'a command whose output spells a word' 'to refresh refs)' 'also in a heredoc body'; do for f in README.md site/usage.html; do [ "$(grep -cF -e "$s" "$f")" = 1 ] || echo "not once in $f: $s"; done; done` → no output; the same with `'süslü parantez genişletme' 'çıktısı bir kelimeyi yazan komut' 'tazelemek için' 'heredoc gövdesinde de'` over `README.tr.md site/tr/usage.html` → no output
- `python3 -c "import re,sys;[print(f) for f in sys.argv[1:] if re.search('[\u200b-\u200f\u202a-\u202e\u2060-\u2064\ufeff]', open(f,encoding='utf-8').read())]" docs/spec/delix-board.md plugins/delix-board/README.md README.md README.tr.md site/usage.html site/tr/usage.html site/index.html site/tr/index.html` → no output
- `git diff --stat origin/main` → only the 9 files

## Review Focus
- Every argv, flag and heading matches the merged code byte for byte: `--no-lazy-fetch` comes after the prefix on `status`, `diff` and `log`. No text claims the flag for calls 1–3.
- "Use no network" becomes "run no `git fetch` and no `gh`". The text claims only what K284/K294 support.
- TR/EN parity: README and README.tr; usage and tr/usage; index and tr/index.
- Known limits: the lead is not hook-bound for `gh pr merge` or the Git actions commands. Nothing contradicts `README.md:127` (the implementer deny) or the composed H1/H2.
- The composed H1 to H3 (Inputs, K311) match the three handovers word for word, apart from the dropped "and"s and the Turkish case endings that Inputs names, and the round-1 fixes F1 to F4 (K312, Review findings).
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

Read only this card, spec §3–§6 and §9 K290–K297, K305, K306, K309 and K311, the Docs handovers of T044, T047 and T048, and the merged files named in Interfaces.

## Review findings (filled by the lead)
- Round 1 (PR #77, head `2ccdc65e46b25393205e380af1384767a2285a55`, 2026-11-14): qa `ACCEPT` (0 P0, 0 P1), security
  `FIX` (1 Medium, 1 Low, 2 unsure notes). Lead gates on the clean `git archive` of the head: exactly the 9 Files; 16
  suites exit 0 with no `✘`; `claude plugin validate` passes for the root and delix-board; `claude plugin test
  plugins/delix-board` 48 pass; the Stop gate gives `[exit 0]` twice; CI `check` and `test` green. The lead's content
  check (108 items) passes: every Verification count, and every handover sentence (T044 H1/H2, T047 H1/H2, T048
  H1/H2) and the composed H3 inserts appear in README, README.tr and the site, after joining wrapped lines.
  - Medium (security): the docs overstate the ref and remote rule. H1's "so a card session does not rewrite refs or
    remotes" and the removal of the `origin` URL item from the four push-rule lists say more than the hook does. Lead
    repro with real git and bash 3.2.57 on temp repos (no network), hook from the head, which equals main's
    `bash_gate.py`: a `printf … >>` of `pushurl`, of `url.*.insteadOf`, or a `sed -i` of `url` into the git config
    file passes the hook, the own-branch push that follows passes too, and the branch lands in the other repository
    (3 of 3); `git config remote.origin.pushurl …` and `git remote set-url …` deny. Fix F1, F2.
  - Low (security): on the index pages the closing sentence "This is a check on the command's words, an allowlist
    that fails closed" reads as if it covered the whole Implementer cell; the ref rule denies one command name. Fix F3
    (same line as F1, so it costs nothing).
  - Note (security unsure): T048 H1 says the hook reads `$'…'` "as bash does"; it reads it to its end and decodes only
    a backslash before a backslash, a quote or `?` (`bash_gate.py` `_ESC`). Fix F4 (same sentences as F1).
  - Notes (security unsure, no change): `site/usage.html:226` scopes `--no-lazy-fetch` to "their object reads", which
    holds; a gitleaks hit in `evals/secret-refusal/prompt.md:7` is an eval fixture outside the diff.
  - Fix round 1 (K312): the lead's wording, prototyped on a copy of the head (each old text matches once, 26 counts
    hold, `site_tests.sh` exit 0). Old → new; the README matches ignore line breaks; on the site backticks are `<code>`:
    - F1 EN (README.md, site/index.html): `so a card session does not rewrite refs or remotes (T044, K296)` →
      `so a card session does not rewrite refs or remotes with those commands (T044, K296)`. TR (README.tr.md,
      site/tr/index.html): `kart oturumu ref ya da remote yazmaz (T044, K296)` → `kart oturumu bu komutlarla ref ya da
      remote yazmaz (T044, K296)`.
    - F2 EN (README.md, site/usage.html): ``a `gh` alias for `pr merge`, `gh api` ref`` → ``a `gh` alias for `pr
      merge`, a URL for `origin` (`url`, `pushurl` or `url.*.insteadOf`) that a command other than git writes into the
      git config file, in the same or an earlier call (the own-branch push then goes to that URL), `gh api` ref``. TR
      (README.tr.md, site/tr/usage.html): ``` `pr merge` için bir `gh` alias'ı, delixcrew'un ``` → ``` `pr merge` için
      bir `gh` alias'ı, git dışı bir komutun aynı ya da önceki bir çağrıda git ayar dosyasına yazdığı bir `origin`
      URL'si (`url`, `pushurl` ya da `url.*.insteadOf`; kendi dalının push'u o adrese gider), delixcrew'un ```.
    - F3 (site/index.html, site/tr/index.html): `This is a check on the command's words, an allowlist that fails
      closed` → `The push rule is a check on the command's words, an allowlist that fails closed`; `Bu, komutun
      kelimeleri üzerinde fail closed çalışan bir izin listesi denetimidir` → `Push kuralı, komutun kelimeleri üzerinde
      fail closed çalışan bir izin listesi denetimidir`.
    - F4 EN (README.md, site/index.html): ``ends a heredoc body at its delimiter, and reads `$'…'` and brace groups as
      bash does;`` → ``ends a heredoc body at its delimiter, reads brace groups as bash does, and reads `$'…'` to its
      end without decoding escapes such as `\x67`;``. TR (README.tr.md, site/tr/index.html): ``` heredoc gövdesini
      sınırlayıcısında bitirir, `$'…'`'yu ve süslü parantez gruplarını bash gibi okur; ``` → ``` heredoc gövdesini
      sınırlayıcısında bitirir, süslü parantez gruplarını bash gibi okur, `$'…'`'yu da sonuna kadar okur ama `\x67`
      gibi kaçışları çözmez; ```.
    - Checks (each `grep -cF`, a line count): `does not rewrite refs or remotes with those commands` 1 in README.md and
      site/index.html; `kart oturumu bu komutlarla ref ya da remote yazmaz` 1 in README.tr.md and site/tr/index.html
      (it replaces the dispatch's TR H1 phrase `kart oturumu ref ya da remote yazmaz`); `that a command other than git
      writes into the git config file` 1 in README.md and site/usage.html; `git ayar dosyasına yazdığı bir` 1 in
      README.tr.md and site/tr/usage.html; `The push rule is a check on the command` 1 and `This is a check on the
      command` 0 in site/index.html; `Push kuralı, komutun kelimeleri` 1 and `Bu, komutun kelimeleri` 0 in
      site/tr/index.html; `without decoding escapes such as` 1 in README.md and site/index.html; `kaçışları çözmez` 1
      in README.tr.md and site/tr/index.html. Every earlier Verification count stays as it is (site `^+ ` lines 10,
      unlabelled 0).
  - Evidence: `rev77/` files in the lead's scratchpad (not in the repo).
- Round 2 (PR #77, head `76fcc0a58f96c79224c218c8a3ef3bd8072ddb6d`, 2026-11-14): qa `ACCEPT` (0 P0, 0 P1), security
  `FIX` (1 Medium, 3 unsure notes). Lead gates on the clean `git archive` of the head: exactly the 9 Files; 16 suites
  exit 0 with no `✘`; `claude plugin validate` passes for the root and delix-board; `claude plugin test
  plugins/delix-board` 48 pass; the Stop gate gives `[exit 0]` twice; CI `check` and `test` green; the lead's content
  check (124 items) passes. Security checked F1, F3 and F4 against the merged code; they hold.
  - Medium (security): F2's "that a command other than git writes" still says more than the hook does: some `git
    config` writes of the same keys pass the hook too. Lead repro with real git 2.54 and bash 3.2.57 on temp repos (no
    network), hook from the head, which equals main's `bash_gate.py`: 4 of 4 forms pass, the own-branch push that
    follows passes and the branch lands in the other repository; plain `git config remote.origin.pushurl …` denies.
    The forms stay out of this card and the docs (K313); the code gap goes to a separate 🔐 Tier 3 card. Fix F5.
  - Notes (security unsure, no change): `docs/spec/delix-board.md:171` "Nesne okuyan dört çağrı" and
    `site/usage.html:226` "their object reads" are loose, since `for-each-ref` also reads commit objects (local in a
    `blob:none` or `tree:0` clone); with a forged `origin/HEAD` STATE the printed `--match-head-commit` block carries
    the SHA that STATE names, while the merge click stays the user's.
  - Fix round 2 (K313): the lead's wording, prototyped on a copy of the head (each old text matches once, the 120
    other checks of the content check hold, `site_tests.sh` exit 0; 4 files, 5 lines). Old → new; the README matches
    ignore line breaks, and the README line break stays where it is:
    - F5 EN (README.md, site/usage.html): `that a command other than git writes into the git config file, in the same
      or an earlier call` → `written into the git config file in the same or an earlier call`. TR (README.tr.md,
      site/tr/usage.html): `git dışı bir komutun aynı ya da önceki bir çağrıda git ayar dosyasına yazdığı bir` → `aynı
      ya da önceki bir çağrıda git ayar dosyasına yazılan bir`.
    - Checks (each `grep -cF`, a line count): `that a command other than git` 0 and `written into the git config file
      in the same or an earlier call` 1 in README.md and site/usage.html; `git dışı bir komutun` 0, `git ayar
      dosyasına yazdığı bir` 0 and `git ayar dosyasına yazılan bir` 1 in README.tr.md and site/tr/usage.html. They
      replace round 1's F2 checks; every other count stays as it is.
  - Evidence: `rev77/r2/` files in the lead's scratchpad (not in the repo).
