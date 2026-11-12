# T032 — Docs and site: delix-board spec §4/§6/§8, board README and 0.1.5, README Flow/Files/Known limits, usage pages

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T032 | S | 2 | docs | 13 | open |

> Tier 2: no protected path. `plugins/delix-board/.claude-plugin/plugin.json` does not match `.claude-plugin/**`, because that pattern is anchored at the repo root (`scripts/common.py:211`); the root `.claude-plugin/plugin.json` is not touched. It is Tier 2 because it makes public claims on the site.

**Goal (1 sentence):** The docs and the site describe the merged Spec C board behaviour (T029–T031, hardened by T034, T035, T037 and T038), and delix-board's version becomes 0.1.5 while the root version stays unchanged. · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-1`–`#REQ-6`; §4 (git row); §6 (Known limits, `origin/HEAD`); K245, K247, K259, K262, K263, K275, K276, K277

**Docs/site:** this card is the update. `site/usage.html` line 124 describes `/delixcrew:status` output, and its Known limits list mirrors README Known limits (CLAUDE.md: README Flow and Known limits). `site/index.html` and `site/tr/index.html` have no status or board claim. They change only in their line 489 Source / Kaynak line, which cites `CHANGELOG (Unreleased)` although `CHANGELOG.md` has no such section (`CHANGELOG.md:5` is `## 0.6.3 — 2026-11-04`; T033 review, P2). T041's "(coming in the next release)" / "(sonraki sürümle gelecek)" labels on line 475 of both index pages and line 225 of both usage pages stay as they are.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `docs/spec/delix-board.md` (§4 line 35, after line 38, lines 43–44, line 55; §6 line 90, after line 92, lines 94–95, line 104; §8 lines 139–141)
- Modify: `plugins/delix-board/README.md` (after line 12; line 36; line 38; after line 59)
- Modify: `plugins/delix-board/.claude-plugin/plugin.json` (line 4)
- Modify: `README.md` (line 74; line 91; after line 391)
- Modify: `README.tr.md` (line 74; line 91; after line 392)
- Modify: `site/usage.html` (line 124; after line 225)
- Modify: `site/tr/usage.html` (line 124; after line 225)
- Modify: `site/index.html` (line 489, Source line only)
- Modify: `site/tr/index.html` (line 489, Kaynak line only)
- Test: none (docs card; the checks are in Verification)

## Edit anchors
Base: main at fee18189eded717ee232d9405801e13e71ae8684. Line numbers are from that commit. `[…]` marks an elided middle of a long line; the text on each side of it is byte for byte. Edit each file **from the bottom up** so the line numbers stay valid. Match the quoted content before you edit. If it is not there, stop with `NEEDS_CONTEXT`. Keep every argv below on one line: do not wrap inside a code span, because Verification greps it line by line.

1. `docs/spec/delix-board.md` (Turkish)
   - **line 139–141, replace.** Current:
     ```text
     - Salt okunur: `$.fs.write` yok; `$.process.run` yalnız salt-okur git: `rev-parse`, `worktree list`, STATE için
       `status --porcelain` ve `log -1`. `tool.call` hook'ları
       çağrıyı değiştirmez, reddetmez (gating hook yok). Ağ yok.
     ```
     New:
     ```text
     - Salt okunur: `$.fs.write` yok; `$.process.run` yalnız salt-okur yerel git (Spec C, K257, K262, K263, K275, K277).
       Her çağrı `git --no-optional-locks -c core.fsmonitor=false` ile başlar ve 5 sn zaman aşımlıdır; depo çağrıları
       oturumun checkout'unda, worktree çağrıları o worktree'de (`cwd`) koşar. Açılışta bir kez `rev-parse --show-toplevel`.
       20 sn'de bir: `rev-parse --git-common-dir`, `worktree list --porcelain -z`,
       `for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)`,
       `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`; sonra her
       worktree'de `status --porcelain`; `.delix/card`'ı olmayan ve STATE'i commit'lenmemiş olmayan worktree'de
       `diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` ve, STATE dosyası varsa,
       `log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json` (`<default>` = `delix.json`'daki
       `default_branch`, yoksa ya da geçersizse `main`). N worktree için bakış başına en çok 4 + 3N çağrı.
       `refs/remotes/origin/HEAD` yoksa (`git init` + `remote add` ile kurulan depo) hiçbir kart merge'e hazır olmaz;
       `git remote set-head origin -a` onu kurar. `tool.call` hook'ları çağrıyı değiştirmez, reddetmez (gating hook yok).
       Ağ yok: `git fetch` ve `gh` yok; uzak bilgi son fetch anının hâlidir.
     ```
     Sources: `plugins/delix-board/hooks/data.ts:44` (prefix), `:59` (show-toplevel), `:149` (timeout 5000), `:151`, `:153`, `:41`+`:156`, `:160`, `:168`, `:172–177`, `:128–139` (`<default>`), `:142` (4 + 3N); `plugins/delix-board/hooks/parse.ts:635` (no `origin/HEAD` → T = {}).
   - **line 104, replace the substring** `P0–P2). Önceki / sonraki kart düğmeleri.` (full line: `Medium/Orta, Low/Düşük, P0–P2). Önceki / sonraki kart düğmeleri.`) with:
     `P0–P2), **Kayıt** bölümü (Spec C `agents` listesinin tamamı: `implementer · by <lead dalı> · <dal> · <oturum>`, inceleyici için `<rol> r<tur> @<sha7> <verdict> · by <lead dalı>`; boşsa "Kayıt yok."). Önceki / sonraki kart düğmeleri.`
     Sources: `views.tsx:458–471`.
   - **lines 94–95, replace.** Current:
     ```text
     Kapı kuralları `board.py` ile birebir: Tier 3 ve açık durum → kilit; `accepted` + PR → merge; ancak PR alanı
     `merge <sha>` ile başlıyorsa merge kapısı kapanmış sayılır (LLMPortal'ın kaydı; board.py bunu ayırmıyor).
     ```
     New:
     ```text
     Kapı kuralları (K254, K255; `parse.ts` `gatesOf`): `agents` kaydı olan kart Spec C REQ-3'ü izler (`tier 3 approval`
     → kilit, `ready to merge` → merge, `escalated`, rapordan `needs_context` / `blocked`); kaydı olmayan kart bugünkü
     kuralı izler: Tier 3 ve açık durum → kilit; `in_review` + PR → merge, ancak PR alanı `merge <sha>` ile başlıyorsa
     merge kapısı yok (LLMPortal'ın kaydı; board.py bunu ayırmıyor); `escalated`; rapordan `needs_context` / `blocked`.
     `accepted` = merge edildi (review skill §4): merge kapısı yok.
     ```
     Sources: `parse.ts:356–372`, `data.ts:321`, `scripts/board.py:775–788`.
   - **after line 92, insert** an empty line and this paragraph. Line 92 is `` `env_owner` doluysa ortak test ortamı kilidi, verifications özeti (ad · verdict · maliyet).``
     ```text
     Spec C bölümleri (`views.tsx` `agentSections`), "Bekleyen kapılar" kutusundan sonra, wave gruplarından önce:
     **Leads** (ana checkout ve lead worktree'leri: dal, spec başlığı, açık / bekleyen / hazır sayısı, `stale`),
     **Ajanlar** (rol, worktree, dal, upstream, değişikliğin düştüğü yer, commit'lenmemiş dosya sayısı), **Seni bekliyor**
     (kart ya da doğrulama · neden), **Merge'e hazır** (kart · PR · incelenen SHA), **Git işleri** (tür · hedef; komut düz
     metin ya da not; altında "Komutları sen çalıştırırsın; panel çalıştırmaz."). Başlıkta `son fetch: <zaman>` ya da
     `fetch yok`.
     ```
     Sources: `views.tsx:160–231`, `:275–293`, `:70`.
   - **line 90, replace the substring** `merge = kabul edilmiş ve PR var ama merge edilmemiş` with `merge = merge'e hazır kart (`agents` kaydı varsa) ya da `in_review` + PR (kayıt yoksa)`. The full line is `rozetleri (kilit = 🔐 Tier 3 açık kart, merge = kabul edilmiş ve PR var ama merge edilmemiş, escalated, needs_context /`. Sources: `parse.ts:362`, `:368`.
   - **line 55, insert** after the sentence `sonradan açılan orkestratör worktree'si en geç 20 sn'de görünür.` the text ` Bu bakış N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262); çağrılar §8'de.`. The full line is `listesi ve onunla okunan STATE'in seçimi 20 sn'de bir; sonradan açılan orkestratör worktree'si en geç 20 sn'de görünür. Ayrıştırılmış görüntü (`Snapshot`) `$.state`'e yazılır; render yalnız onu okur.` Source: `data.ts:142`.
   - **lines 43–44, replace three substrings.** Line 43 is `kazanır: commit edilmemiş değişikliği olan kopyada dosyanın mtime'ı (`git status --porcelain -- docs/delix/STATE.json``. Line 44 is `boş değil), temiz kopyada o dosyaya dokunan son commit'in zamanı (`git log -1 --format=%ct -- docs/delix/STATE.json`).`
     - In line 43, `` `git status --porcelain -- docs/delix/STATE.json` `` becomes `` `git status --porcelain` ``.
     - In line 44, `boş değil)` becomes `çıktısında 3. dizinden sonrası `docs/delix/STATE.json` olan bir satır var)`.
     - In line 44, `` `git log -1 --format=%ct -- docs/delix/STATE.json` `` becomes `` `git log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json` ``.
     Sources: `data.ts:168–169`, `:177`.
   - **after line 38, insert five table rows.** Line 38 is `| STATE `previous` (arşiv STATE yolu) | önceki spec'in kartlarının […] (`kartlar`, `kademe`, `rol`, `tur`, `kabul`…) da okunur |`
     ```text
     | `git for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)` | dal ucu, upstream, ahead/behind, commit zamanı | Ağ yok; listede `refs/remotes/origin/HEAD` yoksa hiçbir kart merge'e hazır olmaz (K277) |
     | worktree başına `git status --porcelain`; `.delix/card`'ı olmayan ve STATE'i commit'lenmemiş olmayan worktree'de `git diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` | commit'lenmemiş dosya sayısı; lead tespiti (çıkış 1 = dal STATE'i değiştirmiş) | Üç noktalı, merge-base'e göre (Spec C REQ-1); `--no-ext-diff` dış diff yardımcısını çalıştırmaz (K275) |
     | `git --no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json` | güvenilir STATE: merge'e hazır, merge komutu ve `merged`'e dayanan temizlik yalnız bu kopya aynı kartı, PR'ı ve SHA'yı gösterince | Bakış başına bir kez, oturumun checkout'unda; hata = hiçbir kart hazır değil (K262, K276, K277) |
     | `<common-dir>/FETCH_HEAD` ve `<common-dir>/worktrees/*/FETCH_HEAD` mtime | son fetch: başlıkta `son fetch: <zaman>`, hiçbiri yoksa `fetch yok` | `<common-dir>` = `git rev-parse --git-common-dir` |
     | STATE `cards.<T>.agents` / `merged` | kim açtı, kim inceledi (rol, tur, SHA, verdict, `by`), merge kaydı | Spec C REQ-2; yalnız lead yazar |
     ```
     Sources: `data.ts:41`, `:156`, `:168–174`, `:160`, `:184–192`; `views.tsx:70`; `templates/STATE.json:8`.
   - **line 35, replace.** Current: `| `git worktree list --porcelain` | worktree yolu + dal → kart eşlemesi (`.delix/card`, yoksa dal adındaki `T\d{3}`) | `board.py` ile aynı kural |`
     New: `| `git worktree list --porcelain -z` | worktree yolu + dal → kart eşlemesi (`.delix/card`, yoksa dal adındaki `T\d{3}`) | `board.py` ile aynı kural; NUL ile ayrılmış alanlardan biri `\n` ya da `\r` içerirse liste boş sayılır (K263) |`
     Sources: `data.ts:51–55`, `scripts/board.py:150–156`.
2. `plugins/delix-board/README.md`
   - **after line 59, insert one line.** Line 59 is `synthetic project in `tests/fixtures.ts`). The design and its decisions (Turkish): [docs/spec/delix-board.md](../../docs/spec/delix-board.md).`
     `` `tests/board_parity.ts` is `export const PARITY = ` followed by the bytes of the repository's `tests/fixtures/board_parity.json`; the pane's `derive` must return its `expected` (`tests/board.test.tsx`), and `bash tests/board_tests.sh` checks the copy. ``
     Sources: `tests/board_tests.sh:78`, `:88`; `plugins/delix-board/tests/board.test.tsx:294`.
   - **line 38, append** before the final ` |`: `; Kayıt: the card's `agents` ledger (who opened it, every qa / security record)`. The full line is `| `/delix-board kart T010` | Kart (card) | one card: header, review verdicts, Files list, the worktree report and test result, review rounds with finding severities |`. Source: `views.tsx:458–471`.
   - **line 36, replace the substring** `pending gates (Tier 3 approval, merge, escalation), cards by wave,` with `pending gates (Tier 3 approval, merge, escalation), the Spec C sections Leads, Ajanlar (agents: role, worktree, branch, upstream, where the changes land, uncommitted files), Seni bekliyor (waiting on you), Merge'e hazır (ready to merge) and Git işleri (git actions: each command as text; the pane never runs it), cards by wave,`. Source: `views.tsx:167–227`, `:291–293`.
   - **after line 12, insert** an empty line and this paragraph. Line 12 is `every 20 seconds.`
     ```text
     Beside the files it runs only read-only local git, every call as `git --no-optional-locks -c core.fsmonitor=false …`
     (the repository calls in the session's checkout, the others in the worktree they ask about): once at start
     `rev-parse --show-toplevel`; every 20 seconds `rev-parse --git-common-dir`, `worktree list --porcelain -z`,
     `for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)`
     and `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`, then in each
     worktree `status --porcelain` and, where there is no `.delix/card` and `STATE.json` has no uncommitted change,
     `diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` (`<default>`: `default_branch` in
     `docs/delix/delix.json`, else `main`) and, if it holds a `STATE.json`,
     `log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`: at most 4 + 3N calls per look for N worktrees.
     There is no `git fetch` and no `gh`, so remote data is as of the last fetch, whose time the header shows. A card is
     ready to merge only when the STATE at `refs/remotes/origin/HEAD` shows the same card, PR and reviewed SHA; when
     `origin/HEAD` is missing no card is, and `git remote set-head origin -a` sets it.
     ```
     Sources: as in item 1, §8.
3. `plugins/delix-board/.claude-plugin/plugin.json` line 4, replace: `  "version": "0.1.4",` → `  "version": "0.1.5",`.
4. `README.md`
   - **after line 391, insert** an empty line and this paragraph. Line 391 is `(partial clone) repository can still be fetched from its remote while the hooks read the index (K225).`; line 392 (empty) and line 393 `## License` stay.
     ```text
     `/delixcrew:status` and delix-board read only local files and local git: they run no `git fetch` and no `gh`, so
     remote branch data is as of your last fetch (the header shows its time). A card shows under Ready to merge only when
     the STATE that `refs/remotes/origin/HEAD` points at (the remote's default branch, where the lead pushes its records)
     holds the same card, PR and reviewed SHA; until then it waits as `review not on origin/<default>`. When `origin/HEAD`
     is missing, as in a repository set up with `git init` and `git remote add` instead of `git clone`, nothing shows as
     Ready to merge; `git remote set-head origin -a` sets it. With git older than 2.44 nothing does either, because that
     read uses `--no-lazy-fetch`. The merge command they print carries `--match-head-commit <sha>`, so a stale view cannot
     merge a head nobody reviewed. No hook stops the lead from running `gh pr merge` or a Git actions command itself: the
     T041 push rule denies `gh pr merge` only in an implementer worktree, and for the lead the rule lives in the review and
     status skill text only.
     ```
     Sources: `scripts/board.py:292–293`, `:548`, `:501`, `:630`, `:673`; `parse.ts:635`; `scripts/bash_gate.py:110–111`, `:129`; spec §6 lines 169–170, K262 (line 244).
   - **line 91, replace the substring** `(cards + `verifications` records)` with `(cards with their `agents` ledger and `merged` record + `verifications` records)`. The full line is `` `docs/delix/SPEC.md`, `docs/delix/tasks/T<nnn>-<slug>.md`, `docs/delix/STATE.json` (cards + `verifications` records),``. Source: `templates/STATE.json:8`, `:11`.
   - **line 74, append** before the final ` |`: ` Below it: Leads, Agents, Waiting on you, Ready to merge and Git actions; each push / merge / cleanup command in its own one-line `bash` block for Desktop's Run button. You run them; the lead never does.`. Line 74 ends `on request (`--write`) to `docs/delix/BOARD.md` (not committed). |`. Sources: `scripts/board.py:672`, `:682`, `:691`, `:695`, `:698`; `skills/status/SKILL.md:18–19`, `:27`.
5. `README.tr.md`
   - **after line 392, insert** an empty line and this paragraph. Line 392 is `nesne, hook'lar index'i okurken uzak depodan yine çekilebilir (K225).`; line 393 (empty) and line 394 `## Lisans` stay.
     ```text
     `/delixcrew:status` ve delix-board yalnız yerel dosyaları ve yerel git'i okur: `git fetch` ve `gh` çalıştırmaz, bu
     yüzden uzak dal bilgisi son fetch anının hâlidir (başlık zamanını gösterir). Bir kart Ready to merge altında yalnız
     `refs/remotes/origin/HEAD`'in gösterdiği STATE (uzak deponun varsayılan dalı; lead kayıtlarını oraya push eder) aynı
     kartı, PR'ı ve incelenen SHA'yı taşıyınca görünür; o zamana dek `review not on origin/<default>` notuyla bekler.
     `origin/HEAD` yoksa (`git clone` yerine `git init` ve `git remote add` ile kurulan depoda olduğu gibi) hiçbir kart
     Ready to merge altında görünmez; `git remote set-head origin -a` onu kurar. 2.44'ten eski git'te de görünmez, çünkü bu
     okuma `--no-lazy-fetch` kullanır. Bastıkları merge komutu `--match-head-commit <sha>` taşır; bayat bir görünüm
     kimsenin incelemediği bir ucu merge edemez. Lead'in `gh pr merge`'ü ya da bir Git actions komutunu kendisinin
     çalıştırmasını bir hook engellemez: T041 push kuralı `gh pr merge`'ü yalnız uygulayıcı worktree'sinde reddeder; lead
     için kural yalnız review ve status skill metnindedir.
     ```
   - **line 91, replace the substring** `(kartlar + `verifications` kayıtları)` with `(`agents` kaydı ve `merged` kaydıyla kartlar + `verifications` kayıtları)`.
   - **line 74, append** before the final ` |`: ` Altında Leads, Agents, Waiting on you, Ready to merge ve Git actions bölümleri; her push / merge / temizlik komutu Desktop'un Run düğmesi için kendi tek satırlık `bash` bloğunda. Komutları sen çalıştırırsın; lead hiç çalıştırmaz.`. Line 74 ends `` `docs/delix/BOARD.md`'ye (git'e girmez). |``. Section names stay English, as `board.py` prints them.
6. `site/usage.html`
   - **after line 225, insert** the `li` below. Line 225 is `        <li>The implementer push rule is a pattern check on words, not a GitHub boundary: […] <code>log</code> or <code>show</code> (coming in the next release).</li>`.
     `        <li><code>/delixcrew:status</code> and delix-board use no network: remote branch data is as of your last <code>git fetch</code>. A card shows as ready to merge only when the STATE at <code>origin/HEAD</code> holds the same review; when <code>origin/HEAD</code> is missing nothing does, and <code>git remote set-head origin -a</code> sets it. No hook stops the lead from running <code>gh pr merge</code> itself; that rule is skill text (coming in the next release).</li>`
   - **line 124, insert** after `Also works under <code>-p</code>.` and before `</td></tr>`: ` Below it: leads, agents, what waits on you, what is ready to merge, and the push / merge / cleanup commands, each in its own one-line block for the Run button (coming in the next release).`. Line 124 starts `        <tr><th><code>/delixcrew:status</code></th><td>Any time</td><td>Read-only board:`.
   - Source lines 130 and 239 already name README.md (Flow) and README.md (Known limits); leave them.
7. `site/tr/usage.html`
   - **after line 225, insert** the `li` below. Line 225 is `        <li>Uygulayıcının push kuralı kelimeler üzerinde bir kalıp denetimidir, GitHub sınırı değildir: […] içeren bir komuttaki push'u da reddeder (sonraki sürümle gelecek).</li>`.
     `        <li><code>/delixcrew:status</code> ve delix-board ağ kullanmaz: uzak dal bilgisi son <code>git fetch</code> anının hâlidir. Bir kart yalnız <code>origin/HEAD</code>'deki STATE aynı incelemeyi taşıyınca merge'e hazır görünür; <code>origin/HEAD</code> yoksa hiçbiri görünmez, <code>git remote set-head origin -a</code> onu kurar. Lead'in <code>gh pr merge</code>'ü kendisinin çalıştırmasını bir hook engellemez; bu kural skill metnidir (sonraki sürümle gelecek).</li>`
   - **line 124, insert** after `<code>-p</code> altında da çalışır.` and before `</td></tr>`: ` Altında: lead'ler, ajanlar, seni bekleyenler, merge'e hazır olanlar ve push / merge / temizlik komutları, her biri Run düğmesi için kendi tek satırlık bloğunda (sonraki sürümle gelecek).`.
8. `site/index.html` and `site/tr/index.html`, line 489: replace the substring `· scripts/trust.py · CHANGELOG (Unreleased)</p>` with `· scripts/trust.py · CHANGELOG 0.6.3</p>`. On EN the line starts `  <p class="src"><b>Source:</b> hooks/hooks.json`; on TR it starts `  <p class="src"><b>Kaynak:</b> hooks/hooks.json`. The content it cites is in `CHANGELOG.md:23` and `:32`, under `## 0.6.3`. Nothing else on these two pages changes; line 475 keeps T041's label.

## Interfaces
- Consumed (merged; quote exactly):
  - board.py section headings `## Leads`, `## Agents`, `## Waiting on you`, `## Ready to merge`, `## Git actions` (`scripts/board.py:672–698`).
  - The line `You run these with Desktop's Run button; the lead never runs them.` (`:698`) and `remote data as of the last fetch:` (`:673`).
  - Commands `git -C <path> push -u origin <branch>` (`:618`), `gh pr merge <n> --squash --match-head-commit <sha>` (`:630`), `git worktree remove <path>` (`:626`), `git branch -D <branch>` (`:640`).
  - Reason `review not on origin/<default>` (`:501`; `parse.ts:607`).
  - Panel headings `Leads`, `Ajanlar`, `Seni bekliyor`, `Merge'e hazır`, `Git işleri` (`views.tsx:167`, `:182`, `:197`, `:208`, `:219`), `Kayıt` / `Kayıt yok.` (`:458–459`), `Komutları sen çalıştırırsın; panel çalıştırmaz.` (`:227`), `son fetch:` / `fetch yok` (`:70`).
  - Panel git argv (`data.ts:41`, `:44`, `:59`, `:151–177`), budget (`data.ts:142`; `tests/board.test.tsx:680`).
  - `gh pr merge` deny in implementer worktrees only (`scripts/bash_gate.py:110–111`, `:129`, `:264–271`).
- Produced: no code interface.

## Global Constraints (verbatim from the spec and CLAUDE.md)
- K259: "delix-board spec §8 git izin listesi ve §6 görünümleri bu spec'le güncellenir (docs kartı); delix-board sürümü artar, kök plugin sürümü değil."
- §6: "Bilinen sınır: lead'in `gh pr merge` çalıştırmasını bir hook engellemez (yalnız skill metni); Known limits'e yazılır."
- §6: "`git clone` `origin/HEAD`'i kurar; `git init` + `remote add` ile kurulan depoda bir kez `git remote set-head origin -a` gerekir, yoksa hiçbir kart hazır olmaz."
- REQ-6: "Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262)."
- CLAUDE.md: "Every claim on the site comes from a repo file"; the English and Turkish pages carry the same content; no script, form, event handler or third-party asset other than the Umami tag.
- HTML-escape `<`, `>`, `&` inside `<code>`. No raw invisible characters.

## Steps
1. Red: run the Verification checks that name `0.1.5`, `set-head origin -a`, `match-head-commit`, the argv loop and `CHANGELOG 0.6.3`. Each fails on fee18189.
2. Read the merged sources named in Interfaces, at those lines.
3. Edit the 9 files per the anchors, each file bottom-up.
4. Green: run every Verification command. Write their output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]` (`skills/implement/SKILL.md:36–37`).
5. Open `site/usage.html` and `site/tr/usage.html` from `site/`. Save a screenshot of each Known limits list to `.delix/evidence/`.
6. Run `git add` with the 9 paths by name. Commit `T032: docs and site for Spec C board visibility; delix-board 0.1.5`. Run `git push -u origin HEAD` as its own command, with no `cd` on that line (`README.md:122–127`). Open a PR with `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, no line starting `✘`.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0.
- `claude plugin validate .` and `claude plugin validate plugins/delix-board` → pass; `claude plugin test plugins/delix-board` → pass.
- `grep -cF '"version": "0.1.5"' plugins/delix-board/.claude-plugin/plugin.json` → `1`.
- `git diff origin/main -- .claude-plugin/plugin.json` → no output.
- `git diff origin/main -- site | grep -c 'data-version'` → `0`.
- `grep -cF 'match-head-commit' README.md README.tr.md` → `README.md:1`, `README.tr.md:1`.
- `grep -cF 'set-head origin -a' README.md README.tr.md site/usage.html site/tr/usage.html plugins/delix-board/README.md docs/spec/delix-board.md` → `1` for each file.
- `for s in 'git --no-optional-locks -c core.fsmonitor=false' 'rev-parse --show-toplevel' 'rev-parse --git-common-dir' 'worktree list --porcelain -z' 'for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)' '--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json' 'status --porcelain' 'diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json' 'log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json' '4 + 3N'; do for f in docs/spec/delix-board.md plugins/delix-board/README.md; do grep -qF -e "$s" "$f" || echo "missing in $f: $s"; done; done` → no output.
- `grep -cF '3 + 3N' docs/spec/delix-board.md plugins/delix-board/README.md` → `0` each.
- `grep -cF 'coming in the next release' site/usage.html` → `3`; `grep -cF 'sonraki sürümle gelecek' site/tr/usage.html` → `3`; the same two greps on `site/index.html` / `site/tr/index.html` → `1` each.
- `grep -cF 'CHANGELOG (Unreleased)' site/index.html site/tr/index.html` → `0` each; `grep -cF 'scripts/trust.py · CHANGELOG 0.6.3</p>' site/index.html site/tr/index.html` → `1` each.
- `python3 -c "import re,sys;[print(f) for f in sys.argv[1:] if re.search('[\u200b-\u200f\u202a-\u202e\u2060-\u2064\ufeff]', open(f,encoding='utf-8').read())]" docs/spec/delix-board.md plugins/delix-board/README.md README.md README.tr.md site/usage.html site/tr/usage.html` → no output.
- `git diff --stat origin/main` → only the 9 files.

## Review Focus
- Every argv, flag, heading and message matches the cited code line byte for byte. Check especially `refs/remotes/origin/HEAD` (not `origin/<default>`) in the `cat-file` read, `--no-ext-diff`, `--no-show-signature`, `--no-replace-objects`, `-z`, and `4 + 3N`.
- TR/EN parity: README and README.tr; usage and tr/usage.
- The Known limits sentence claims no hook boundary for the lead, and does not contradict `README.md:127` (the implementer `gh pr merge` deny).
- No "Done" / "Bitti" section is claimed: `queue.done` exists (`board.py:516`, `parse.ts:621`), but neither surface renders it.
- The root version and every `data-version` mark are unchanged.

## Don'ts
- Do not touch `scripts/**`, `plugins/delix-board/hooks/**`, `plugins/delix-board/tests/**`, `tests/**`, `skills/**`, `.claude-plugin/**` (root), or `CHANGELOG.md` (written at `/delixcrew:close`). On `site/index.html` and `site/tr/index.html`, change only item 8.
- Do not use spec §4's numbering or its `git -C <wt>` form. Write the argv the code runs (worktree as `cwd`).
- Claim nothing the merged code does not do. If the code and this card disagree, write `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 1K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output (also in `.delix/evidence/verification.txt`);
- the screenshot paths;
- the PR number;
- assumptions.

Read only this card, spec §3–§6 and the merged files named in Interfaces.

## Review findings (filled by the lead)
- Round 1 (PR #71, head `3ae69413912ce22308a22d4b97f043e7a633ec55`, 2026-11-12): qa `ACCEPT` (0 P0, 0 P1), security
  `CLEAN` (2 Low). Lead gates on the clean `git archive` of the head: the shell suites exit 0 on Python 3.9.6 and
  3.13.13, `claude plugin validate .` and `claude plugin validate plugins/delix-board` pass, the delix-board test is
  37 pass 0 fail; every Verification check of this card passes on the archive; 9 files, no protected path, no removed
  test line; CI `check` and `test` pass. Ready for gate 2.
  - Notes (follow-ups, not this card):
    - Lead, reproduced (security unsure): in a treeless partial clone (`--filter=tree:0`, git 2.54) the board's
      `git log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json` fetches from the remote (packs 3 to 4);
      with `--no-lazy-fetch` the same call exits 128 and fetches nothing. `status` and `diff` fetched nothing in that
      test. So the site's "use no network" / "ağ kullanmaz" (this card's text, spec §8) does not hold for such
      a clone. Follow-up code card: `--no-lazy-fetch` on the `status`, `diff` and `log` calls in `scripts/board.py`
      and `plugins/delix-board/hooks/data.ts`.
    - Security Low: README line 74 (both languages) "the lead never does" is stronger than what enforces it (skill
      text only); the README's Known limits says so.
    - Security Low: the site's Known limits names only `gh pr merge`; the README also names the Git actions
      commands (push, worktree remove, branch -D).
    - Security unsure, not traced: the trusted STATE is read from the local ref `refs/remotes/origin/HEAD`, and
      `scripts/bash_gate.py` has no rule for `git update-ref` or `git remote set-head` in an implementer worktree. A
      forged Ready to merge also needs the source STATE to agree; follow-up check.
