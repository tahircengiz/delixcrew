# SPEC — Spec C: board'da ajanlar, onay/merge kuyruğu ve bekleyen git işleri

> Size: **M** · Tier: 2 · Date: 2026-11-04 · Status: **approved (gate 1, 2026-11-04)** (rev 3: architect FIX
> işlendi, P0×2 P1×3 P2×2; yeniden kontrolde kalan P1 rol tespiti üç noktalı diff'e çevrildi; rev 4: job B, K260–K261; rev 5 (2026-11-11): K262 güvenilir ledger, kullanıcı seçimi A; K263 git sertleştirmesi; rev 6 (2026-11-12): wave 9 tur 1, K273–K276)
> Source: kullanıcı isteği (sohbet, 2026-11-04, dört madde); grill kararları K240–K243 ve K262 (kullanıcı), lead kararları
> K244–K261, K263 ve K273–K276. Spec B (#17) aynı anda başka bir lead oturumunda açık olduğu için bu dosya `docs/delix/SPEC.md` yerine
> burada durur ve K numaraları K240'tan başlar (K244).

## 1. Goal
Kullanıcı aynı anda birden çok delix oturumu yürütüyor (lead'ler, worktree'deki uygulayıcılar, salt-okunur
inceleyiciler). Bugün board kartları gösteriyor ama şu dört soruyu cevaplamıyor: (1) hangi ajan hangi dalda ve
worktree'de, değişiklikleri nereye düşüyor; (2) kim hangi uygulayıcıyı gönderdi, kim kimin dalını inceledi; (3) ne
kullanıcının onayını bekliyor, ne merge'e hazır, ne bitti; (4) push, merge ve worktree temizliği için terminale
geçmek gerekiyor. Başarı: `/delixcrew:status` ve delix-board paneli dördünü yalnız yerel dosya ve yerel git ile
cevaplar; `/delixcrew:status` bekleyen her push/merge/temizlik işini Desktop'ta Run düğmesi çıkan tek satırlık komutla
verir. Board yine hiçbir komut çalıştırmaz ve `--write` dışında dosya yazmaz.

## 2. Out of scope
- Board'un ya da panelin komut çalıştırması, düğme koyması (K240; delix-board spec §3, delix spec §14 aynen kalır).
- Ağ: board.py ve panel `gh` çağırmaz, `git fetch` yapmaz (K245). Uzak dal bilgisi son fetch anındaki haldir.
- `git add`/`commit` önerisi (K246) ve kaydı olmayan eski yerel dalların toplu temizliği (`claude/*`): komut yok.
- delix dışı alt ajanlar (scout, Explore, general-purpose), architect ve verify çağrılarının kaydı; Desktop
  oturumlarının canlı hali (izin istemi bekleyen oturum): uygulamanın kenar çubuğu gösterir.
- Farklı lead STATE kopyalarındaki kartları tek tabloda ya da kuyrukta birleştirmek (K243): diğer lead'ler yalnız
  Leads tablosunda sayılarla görünür.
- Mevcut kart tablosunun sütunları ve satır biçimi (K254); kök `.claude-plugin/plugin.json` sürüm yükseltmesi (Tier 3,
  sürüm çıkarken ayrı iş); hook ve `delix.json.protected_paths` altındaki her dosya.

## 3. Requirements (testable)

### Requirement: REQ-1 Ajan satırları: rol, dal, worktree, değişikliğin düştüğü yer
The system SHALL `git worktree list` içindeki her worktree için bir satır üretir: rol, yol, dal, upstream durumu,
commit'lenmemiş dosya sayısı, düştüğü yer. Rol: `implementer T<nnn>` = `.delix/card` var; `lead` = kart yok ve
şunlardan biri: `docs/delix/STATE.json` çalışma ağacında kirli; dal STATE'i değiştirmiş
(`origin/<default_branch>...HEAD` üç noktalı diff boş değil); dal adı kaynak STATE'te bir `agents[].by` değeri.
Diğerleri `other`. Ana checkout `main checkout` diye işaretlenir. Upstream durumu: `no upstream`,
`in sync`, `<a> ahead`, `<b> behind`, `<a> ahead, <b> behind`, `gone`; detached HEAD `detached <sha7>`. Düştüğü yer:
rapor ya da STATE'te PR varsa `PR #<n> → <default_branch>`, yoksa upstream varsa `pushed: <upstream>`, yoksa `local only`.
#### Scenario: uygulayıcı, push edilmemiş commit ve PR
- WHEN `.delix/card` içinde `T029` olan, upstream'den 2 commit ilerideki ve raporunda `**PR:** #60` yazan worktree varsa
- THEN satır `implementer T029`, `2 ahead`, `PR #60 → main` gösterir
#### Scenario: origin/main'den yeni açılmış worktree
- WHEN kartı olmayan ve STATE'i `origin/main` ile aynı bir worktree varsa
- THEN rol `other`dır, Leads tablosunda görünmez
#### Scenario: eski main'den açılmış, STATE'e dokunmamış worktree
- WHEN worktree birkaç commit eski bir main'den açılmış, o arada main'de STATE değişmiş, dal STATE'e dokunmamışsa
- THEN rol `other`dır (uçla değil merge-base'le karşılaştırılır)

### Requirement: REQ-2 Gönderen ve inceleyen kaydı (ledger)
The system SHALL lead adımlarında `STATE.json.cards.<T>.agents` listesine §4'teki biçimde kayıt ekler: `dispatch`
uygulayıcıyı açınca bir `implementer` kaydı (dal ve Desktop oturum adı rapordan ya da `start_session` sonucundan
bilinince doldurulur), `review` her `qa` ve `security` koşusu için incelenen SHA ve verdict'le bir kayıt. Kullanıcı
merge edince lead `status` → `accepted` ile aynı anda `merged`'i yazar. Board her kart için "kim açtı" ve son tur
inceleyicilerini Ajanlar/Kuyruk bölümlerinde, panelin kart görünümü tüm listeyi gösterir.
#### Scenario: iki inceleme turu
- WHEN T029'un `agents` listesinde tur 1 ve tur 2 için `qa` kayıtları varsa
- THEN board yalnız tur 2'yi (`qa r2 @<sha7> ACCEPT · by <lead branch>`), panel kart görünümü ikisini gösterir
#### Scenario: eski STATE
- WHEN bir kartta `agents` ve `merged` yoksa
- THEN board `—` gösterir, hata vermez; `pr: "merge <sha>"` biçimi merge edilmiş sayılır
#### Scenario: skill metinleri biçimi taşır
- WHEN `skills/dispatch`, `skills/review`, `skills/close` SKILL.md ve `templates/STATE.json` okunursa
- THEN üçü §4'teki kayıt alan adlarını birebir içerir, şablon geçerli JSON'dur

### Requirement: REQ-3 Seni bekleyenler, merge'e hazırlar, bitenler
The system SHALL kaynak STATE'ten üç liste üretir (`accepted` = merge edildi, review skill §4; anlam değişmez).
**Merge'e hazır (kapı 2):** `in_review` + PR + en son turun `qa` kaydı `ACCEPT`/`ACCEPT_WITH_NOTES` + Tier ≥ 2'de aynı
turun `security` kaydı `CLEAN` ya da `🔐 HUMAN_APPROVAL` + `origin/<dal>` ucu o turda incelenen SHA'ya eşit + aynı kart, PR ve SHA `origin/<default>`'taki STATE kopyasında da
bu koşulları sağlar (güvenilir kopya, K262; Leads sayılarında da).
**Seni bekliyor:** merge'e hazır kartlar; kart dosyasında `**🔐 Approved:**` satırı olmayan `open` Tier 3 kart;
raporu `NEEDS_CONTEXT`/`BLOCKED` olan açık kart; `escalated`; son turu ACCEPT ama ucu değişmiş kart
(`changed after review`); son turu ACCEPT ama bu kayıt `origin/<default>` STATE'inde olmayan kart
(`review not on origin/<default>`); `agents` kaydı olmayan `in_review` + PR kart (`no review record`); bugünkü kuralla bekleyen
doğrulama (`FIX*` ve `resolution` yok). **Bitti:** `accepted`. Kart tablosunun "pending gate" sütunu `agents` kaydı
olan kartta bu kuralı, olmayanda bugünkü kuralı izler (K254).
#### Scenario: inceleme sonrası değişen dal
- WHEN `in_review` bir kartın son turu ACCEPT ama `origin/<dal>` ucu o turdaki SHA'dan farklıysa
- THEN kart merge'e hazır değil, "seni bekliyor" altında `changed after review` notuyla görünür
#### Scenario: tur sürüyor
- WHEN kart `in_review`, PR'ı var, `agents`'ta güncel uç için `qa` kaydı yoksa
- THEN kart merge'e hazır değildir
#### Scenario: merge edilmiş kart panelde
- WHEN kart `accepted` ve `pr` sayıysa
- THEN panel kartı "bitti" gösterir, merge kapısı yok (bugün panel "merge" diyor; K255)
#### Scenario: sahte kaynak STATE
- WHEN kartsız bir worktree'deki STATE, `origin/<default>` STATE'inde kaydı olmayan bir kart için `qa ACCEPT` ve PR ucunun
  SHA'sını taşıyor ve board o worktree'den çalışıyor ya da panel onu kaynak seçiyorsa
- THEN kart merge'e hazır değildir, merge komutu yoktur, kart `review not on origin/<default>` notuyla bekler; aynı kayıt
  `origin/<default>`'a push edilince kart merge'e hazır olur

### Requirement: REQ-4 Bekleyen git işleri ve tek satırlık komutlar
The system SHALL bekleyen git işlerini §4'teki sırayla ve komutuyla listeler:
- **push:** bir worktree'de checkout edilmiş, varsayılan dal olmayan, detached olmayan, upstream'i `gone` olmayan ve
  (upstream'i yok ya da upstream'den ileride) dal: `git -C <path> push -u origin <branch>`
- **merge:** merge'e hazır kart: `gh pr merge <n> --squash --match-head-commit <sha40>` (SHA son `qa` kaydından; K247)
- **remove_worktree:** temiz, ana checkout olmayan, board'u çalıştıran worktree olmayan ve (kartı `origin/<default>` STATE'inde
  `accepted` ve `merged` kayıtlı ya da son etkinliği 7 günden eski, upstream'i var ve ileride değil) worktree: `git worktree remove <path>`
- **delete_branch:** hiçbir worktree'de checkout edilmemiş, kartının `origin/<default>` STATE'inde `merged` kaydı olan ve yerel ucu `merged.head`'e
  eşit dal: `git branch -D <branch>` (K249)
- commit'lenmemiş dosyası olan worktree'ye komut yok: `uncommitted <n> files: commit or discard in its session`.
Komut yalnız dal adı `^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$` (`reset` ve `clean` hariç), yol `^/[A-Za-z0-9_./-]+$`, PR
numarası pozitif tamsayı ve SHA `^[0-9a-f]{40}$` iken üretilir; aksi halde `unsafe name: run by hand` (K248).
`/delixcrew:status` her komutu kendi tek satırlık ` ```bash ` bloğunda basar ve komutları kendisi çalıştırmaz; panel
aynı listeyi düz metin gösterir.
#### Scenario: merge edilmiş ama kirli worktree
- WHEN kartı `accepted` ve `merged` kayıtlı worktree'de commit'lenmemiş 1 dosya varsa
- THEN `git worktree remove` önerilmez, not satırı görünür
#### Scenario: bayrak gibi görünen dal adları
- WHEN dal adı `-f`, `--mirror` ya da `a;b` ise
- THEN o satır için komut yok, `unsafe name: run by hand` yazar; `x-fix` adlı dal ise normal komut alır
#### Scenario: asla önerilmeyenler
- WHEN fixture'daki her durum
- THEN komutların token listesinde `--force`, `-f`, `--force-with-lease`, `--mirror`, `reset`, `clean`, varsayılan dala
  push, ana checkout yolu ya da board'u çalıştıran worktree'nin yolu bulunmaz (denetim token düzeyinde)

### Requirement: REQ-5 Leads tablosu
The system SHALL ana checkout ve rolü `lead` olan her worktree için bir satır üretir: yol, dal, spec başlığı (o
worktree'deki `STATE.json.spec` dosyasının ilk `#` başlığı), o STATE'teki açık / seni bekleyen / merge'e hazır kart
sayıları, STATE'in son değişme zamanı ve `stale` (son etkinlik 7 günden eski, K250). Ana tablonun ve kuyruğun kaynağı
başlıkta adlandırılır (K256).
#### Scenario: iki aktif lead
- WHEN ana checkout dışında, dalında ya da çalışma ağacında STATE değişikliği olan iki lead worktree'si varsa
- THEN Leads tablosunda üç satır görünür ve her birinin sayıları kendi STATE'inden gelir

### Requirement: REQ-6 İki yüzey aynı sonucu verir
The system SHALL board.py'de ve panelde ham girdiden (§4 git çıktıları + dosyalar) `agents`, `leads`, `queue`
(`waiting`/`ready`/`done`), `actions` ve `fetched_at` alanlarını üreten saf bir `derive(raw)` fonksiyonu tutar;
`board.py --json` bu alanları ekler. Eşlik fixture'ı `tests/fixtures/board_parity.json` (ham girdi + beklenen çıktı)
ve bayt-eş kopyası `plugins/delix-board/tests/board_parity.json`'dır (K252). Panel 20 sn'lik yenilemede N worktree
için en çok 4 + 3N git çağrısı yapar (K257, K262).
#### Scenario: eşlik
- WHEN fixture iki süite verilirse
- THEN iki `derive` çıktısı fixture'daki `expected` ile alan alan eşittir ve `cmp` iki kopyayı eş bulur

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| data | `cards.<T>.agents[]` | `{"role":"implementer"\|"qa"\|"security","by":"<lead branch>","round":<int>,"sha":"<40 hex>"\|null,"verdict":"<token>"\|null,"at":"<ISO-8601 Z>"}`; yalnız `implementer`: `"branch":"<name>"\|null,"session":"<Desktop name>"\|"-p"\|null` | board.py, panel, dispatch/review/close |
| data | `cards.<T>.merged` | `{"sha":"<merge commit 40 hex>","head":"<merged PR head 40 hex>","at":"<ISO>"}`; lead `gh pr view <n> --json mergeCommit,headRefOid` ile okur | board.py, panel |
| git | çağrılar (sıra ve argv birebir) | her çağrı `git --no-optional-locks -c core.fsmonitor=false` ile başlar (K263); 1) `git rev-parse --git-common-dir` 2) `git worktree list --porcelain -z` → NUL ile ayrılmış kayıtlar, `\n` ya da `\r` içeren bir kayıt tüm listeyi geçersiz kılar; yol, HEAD, `branch refs/heads/<b>` \| `detached` 3) `git for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)` → track: boş = `in sync`, `ahead N`, `behind N`, `ahead N, behind M`, `gone`; upstream boş = `no upstream` 4) worktree başına `git -C <wt> status --porcelain` → satır sayısı, STATE kirli mi 5) kartsız ve STATE'i kirli olmayan worktree başına `git -C <wt> diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` → exit 1 = dal STATE'i değiştirmiş (K275) 6) lead başına STATE kirli değilse `git -C <wt> log -1 --format=%ct -- docs/delix/STATE.json` 7) bakış başına bir kez, kendi kökünde `--no-lazy-fetch cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json` → ham `trusted_state`; hata ya da `origin/HEAD` yok = null, hiçbir kart merge'e hazır olmaz (K262, K276); her çağrı zaman aşımlı, hata alanı `?` yapar | derive |
| fs | `fetched_at` | `<common-dir>/FETCH_HEAD` ve `<common-dir>/worktrees/*/FETCH_HEAD` mtime'larının en büyüğü; yoksa `never fetched` | başlık |
| fs | Approved | kart dosyasındaki `**🔐 Approved:**` satırı (dispatch §2) | REQ-3 |
| function | `derive(raw) -> {agents, leads, queue, actions, fetched_at}` | saf; sıralama: agents rol (lead, implementer, other) sonra yol; queue kart id; actions kart id ya da hedef, sonra push < merge < remove_worktree < delete_branch | board.py, panel |
| function | `board.py --json` | mevcut anahtarlar aynen + `derive` alanları; `actions[]` = `{kind, target, card\|null, command\|null, note}` | panel testleri, status skill |
| skill | `/delixcrew:status` | kart tablosu aynen; altına Leads, Agents, Waiting on you, Ready to merge, Git actions bölümleri; her komut ayrı tek satırlık `bash` bloğu; "Git actions komutlarını sen çalıştırmazsın" satırı | kullanıcı |
| ui | delix-board Pano + Kart | Pano: Leads, Ajanlar, Seni bekliyor, Merge'e hazır, Git işleri (metin); Kart: `agents` listesi; snapshot anahtarı bir artar | kullanıcı |

Design system: mevcut delix-board görsel dili ([docs/spec/delix-board.md](../../spec/delix-board.md) §7); yeni renk ve
bileşen yok.

## 5. Data and migration
`agents` ve `merged` isteğe bağlı yeni alanlar; eski STATE dosyaları değişmeden okunur. Göç yok. `templates/STATE.json`
örnek kartına iki alan eklenir. Panel snapshot anahtarı (`register.tsx`) bir artar.

## 6. Security note
Tier 2: korumalı yola dokunulmaz. Risk: board'un ürettiği komut Run düğmesiyle kullanıcının Mac'inde çalışır; dal ve
yol adları git'ten gelir ve auto mode'daki bir oturum `refs/heads/-f` gibi bir dal yaratabilir. K248: ad kalıpları
`-` ile başlayan, boşluk ya da kabuk karakteri içeren her şeyi dışlar, böylece tırnaklamaya gerek kalmaz ve iki dilde
aynı kalır; `gh pr merge` incelenen SHA'ya `--match-head-commit` ile bağlanır, bayat ref incelenmemiş ucu merge
edemez. Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz. Merge kullanıcının tıklamasıdır (kapı 2). Bilinen sınır:
lead'in `gh pr merge` çalıştırmasını bir hook engellemez (yalnız skill metni); Known limits'e yazılır.

Kaynak STATE güvenilir değildir (K262): kartsız herhangi bir worktree'ye yazılan STATE kaynak olabilir. Merge'e hazır,
merge komutu ve `merged`'e dayanan temizlik önerileri yalnız `refs/remotes/origin/HEAD`'in gösterdiği STATE de
(uzak deponun varsayılan dalı; `delix.json`'daki `default_branch` bu ref'i seçmez, K276) aynı kart, PR ve SHA'yı gösterince
üretilir; o kopyaya lead push eder (review §4). Bu spec'te "`origin/<default>` STATE'i" bu kopyadır. Kalan risk: bir oturum yerel izleme ref'ini commit +
`update-ref` ile yeniden yazabilir; bu, uç denetiminin `refs/remotes/origin/<dal>`'a duyduğu güvenle aynıdır, dosya
yazmaktan fazlasını ister ve sonraki fetch ref'i düzeltir. `origin/HEAD`'i `git remote set-head` ile başka dala çevirmek
de `.git`'e yazmaktır; fetch onu düzeltmez, `git remote set-head origin -a` düzeltir. `git clone` `origin/HEAD`'i kurar;
`git init` + `remote add` ile kurulan depoda bir kez `git remote set-head origin -a` gerekir, yoksa hiçbir kart hazır olmaz.
Kart oturumları kullanıcının kimliğiyle `git push origin HEAD:<default>` çalıştırabilir: `bash_gate` bunu engellemez ve
varsayılan dalın ruleset'i kullanıcı rolüne bypass verir (T036 tur 1 security notu); bu board'dan bağımsız, eski bir
boşluktur, takip kartında 🔐 kapatılır. Git çağrıları `--no-optional-locks` (başka worktree'nin
index'ine yazmaz) ve `-c core.fsmonitor=false` ile koşar: paylaşılan `.git/config`'teki bir fsmonitor betiği her
worktree'deki `git status`'ta çalışır (lead 2026-11-05'te git 2.54'te üretti; bayrakla çalışmadı) (K263). `git diff
--quiet` paylaşılan config'teki `diff.external` + `diff.trustExitCode`'u ve `.gitattributes` diff sürücüsünü çalıştırır
(lead 2026-11-12'de üretti; `--no-ext-diff` ile çalışmadı; textconv `--quiet` ile çalışmaz) (K275). Spec ve kart
dosyası yalnız worktree içinde, normal dosya ve ≤ 1 MiB ise okunur. Doğrulanmadı: `filter.<driver>.clean` `git status`'ta
çalışabilir; ön koşulu `.git/config`'e yazmak ya da global config'te tanımlı bir sürücü için worktree'ye `.gitattributes`
yazmak (ör. `filter.lfs.clean`).

## 7. Acceptance criteria (DoD)
- [ ] Her REQ için geçen test; doğrulama: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0,
  `claude plugin test plugins/delix-board` → geçer, `claude plugin validate .` → geçer
- [ ] Mevcut `tests/board_tests.sh` ve panel testlerinde değişen satır yalnız K255'in izin verdiği panel satırları
- [ ] `qa` ACCEPT (Tier 2)
- [ ] Bu repoda gerçek koşu: `/delixcrew:status` bu oturumun worktree'sini `lead` gösterir, Run bloklarında `-f`,
  `reset`, `clean` yoktur; panel aynı satırları gösterir, Desktop'ta ekran görüntüsüyle doğrulanır
- [ ] PR gövdesinde "How I tested"

## 8. Open questions
- Yok.

## 9. Decisions
- **K240** (kullanıcı, geri alınır) Madde 4: board bekleyen git işini ve tek satırlık komutu gösterir,
  `/delixcrew:status` Run düğmeli blok verir; board ve panel salt okunur kalır, merge kullanıcının tıklaması.
- **K241** (kullanıcı, geri alınır) Madde 2: kayıt lead adımlarından STATE.json'a; hook yok (Tier 2 kalır).
- **K242** (kullanıcı, geri alınır) İki yüzey: `/delixcrew:status` (board.py) ve delix-board paneli.
- **K243** (kullanıcı, geri alınır) Çoklu lead: ana tablo ve kuyruk tek kaynaktan, ayrıca Leads tablosu; kart
  birleştirme yok.
- **K244** (lead, geri alınır) Spec B açıkken bu spec `docs/delix/specs/C-board-visibility.md`'de, K blok K240–K279,
  kartlar T029'dan; STATE.json'a yazmadan önce her seferinde `origin/main`'e rebase (Spec B lead'i de yazıyor).
- **K245** (lead, geri alınır) Ağsız; başlıkta `fetched_at`. Bedel: uzak durum bayat olabilir; K247'deki
  `--match-head-commit` merge tarafındaki zararı keser.
- **K246** (lead, geri alınır) Commit önerisi yok; yalnız "commit'lenmemiş n dosya".
- **K247** (lead, geri alınır) Merge `--squash --match-head-commit <sha40>`: main geçmişi squash; repo
  `delete_branch_on_merge=false`, dal silme ayrı öneri.
- **K248** (lead, geri alınır) Ad kalıpları ve token düzeyinde yasak listesi (§6); tırnaklama yok.
- **K249** (lead, geri alınır) `git branch -D` yalnız checkout edilmemiş dalda, `merged` kaydı varken ve yerel uç
  `merged.head`'e eşitken. Ata kuralı yok: squash'ta yalnız hiç commit almamış dalda doğru olur.
- **K250** (lead, geri alınır) Stale = son etkinlik (dal ucu commit zamanı ya da STATE değişimi, hangisi yeniyse)
  7 günden eski.
- **K251** (lead, geri alınır) Kapı 2 tanımı REQ-3; `accepted` anlamı değişmez.
- **K252** (lead, geri alınır) Eşlik ortak fixture ve iki tarafta saf `derive` ile; panel board.py'yi çağırmaz
  (delix-board delix'ten bağımsız kurulur). Fixture sözleşmenin parçasıdır: içeriğini architect kartlarla üretir,
  lead dispatch'ten önce main'e yazar; uygulayıcılar değiştirmez.
- **K253** (lead, geri alınır) Rol tespiti REQ-1; Desktop oturum adı yalnız `implementer` kaydından gelir.
- **K254** (lead, geri alınır) Kart tablosu sütunları değişmez; yeni bilgi yeni bölümlere. `agents`'sız kartta
  "pending gate" bugünkü kuralı izler, böylece `tests/board_tests.sh`'teki satırlar değişmez.
- **K255** (lead, geri alınır) Panelin `accepted` + PR → `merge` kuralı yanlış (review skill §4); düzeltilir ve
  `plugins/delix-board/tests/board.test.tsx` ile `fixtures.ts`'teki buna dayanan satırlar değişir, kartta adıyla.
- **K256** (lead, geri alınır) board.py ana tablo kaynağı bugünkü gibi kendi kökü (koşturan oturumun STATE'i), panel
  `chooseRoot`; ikisi de başlıkta kaynağı adlandırır. Eşlik `derive` üzerinden, kaynak seçimi kapsam dışı.
- **K257** (lead, geri alınır) Git çağrı bütçesi en çok 3 + 3N (K262 ile 4 + 3N); sahte `$` ile sayılır.
- **K258** (lead, geri alınır) `merge` önerisi yalnız kaynak STATE'teki kartlar için; diğer lead'in hazır kartı
  Leads tablosunda sayı olarak görünür, komutu o lead'in `/delixcrew:status`'unda.
- **K259** (lead, geri alınır) delix-board spec §8 git izin listesi ve §6 görünümleri bu spec'le güncellenir (docs
  kartı); delix-board sürümü artar, kök plugin sürümü değil.
- **K260** (lead, geri alınır; architect job B) Yol kalıbına `_` eklendi: bu repodaki her worktree yolu `prj_Ekip`
  içeriyor, eski kalıpla hiçbir komut üretilmezdi; `_` kabukta tırnaksız güvenli. Dal kalıbı aynen.
- **K261** (lead, geri alınır) Panel kopyası `plugins/delix-board/tests/board_parity.ts` = `export const PARITY = ` +
  JSON dosyasının baytları (panelde JSON import örneği yok); fixture ASCII, ham karakterler `\uXXXX` kaçışlı.
- **K262** (kullanıcı, 2026-11-11, geri alınır) Sahte kaynak (T030 tur 2 güvenlik notu, lead üretti): merge'e hazır, merge
  komutu ve `merged`'e dayanan temizlik yalnız `origin/<default>` STATE'i aynı kart, PR ve SHA'yı da gösterince (seçenek A).
  B (komut yalnız kaynak kendi kökü iken) board.py'yi kapatmıyordu; K256'da kaynak hep kendi kökü. Bedel: kart, lead kaydı
  push edene kadar `review not on origin/<default>` ile bekler; bakış başına bir çağrı (4 + 3N); git < 2.44
  `--no-lazy-fetch`'i reddeder ve hiçbir kart hazır olmaz (fail closed, K223 gibi); varsayılan dalı yalnız PR kabul eden
  depoda lead'in STATE PR'ı önce merge edilir.
- **K263** (lead, geri alınır) T029–T031 incelemelerinin Low'ları: her git çağrısı `--no-optional-locks -c
  core.fsmonitor=false`; `worktree list -z`; dosya okumaları kapsam + normal dosya + 1 MiB; liste değerleri `one_line` +
  `strip` (girintili kod bloğu açılmaz); `reset`/`clean` adlı dal komut almaz.
- **K273** (lead, 2026-11-12, geri alınır) T035'in `NEEDS_CONTEXT`'i: mevcut "T029 edge rules" testinin raw'ına tek satır
  `trusted_state: JSON.stringify(state)` eklenir ("yalnız ekleme" kuralının tek istisnası); anahtar yokken güven denetimini
  atlamak reddedildi (fail open, K262'ye aykırı).
- **K274** (lead, 2026-11-12, geri alınır) R8' TR yalnız T'den kurulur: board.py `_queue(T, {}, refs, {})`, yerel rapordan
  PR ve worktree'den dal almaz; R10' `delete_branch` dalı da T'nin kartından. T029 kartında `pr` yokken board.py yerel
  rapordaki PR ile merge önerdi, panel önermedi (REQ-6; T034 tur 1 qa P1, lead üretti).
- **K275** (lead, 2026-11-12, geri alınır) Çağrı 5 `git diff --no-ext-diff --quiet`: `--quiet` güvenilen dış diff
  yardımcısını çalıştırır (§6). Bedel yok; çıkış kodu aynı.
- **K276** (lead, 2026-11-12, geri alınır) Çağrı 7 `refs/remotes/origin/HEAD` okur (T034 tur 1 security Medium): ref adı
  kökün `delix.json`'ındaki `default_branch`'ten gelince kartsız worktree kendi dalını `default_branch` yapıp sahte STATE'i
  o dala push ederek güvenilir kopyayı seçiyordu; fetch bunu düzeltmez. Bedel: `origin/HEAD`'i olmayan depoda hiçbir kart
  hazır olmaz (fail closed); `review not on origin/<default>` notu `default_branch` adını göstermeye devam eder.
