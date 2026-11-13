# SPEC — Spec C: board'da ajanlar, onay/merge kuyruğu ve bekleyen git işleri

> Size: **M** · Tier: 2 · Date: 2026-11-04 · Status: **approved (gate 1, 2026-11-04)** (rev 3: architect FIX
> işlendi, P0×2 P1×3 P2×2; yeniden kontrolde kalan P1 rol tespiti üç noktalı diff'e çevrildi; rev 4: job B, K260–K261; rev 5 (2026-11-11): K262 güvenilir ledger, kullanıcı seçimi A; K263 git sertleştirmesi; rev 6 (2026-11-12): wave 9 tur 1, K273–K276; rev 7: tur 2 notları, K277; rev 8 (2026-11-12): K277 takip kartları T037–T041, çağrı 6/7 bayrakları ve R8'', K278–K279; rev 9 (2026-11-12): T041 tur 1, K280–K281; rev 10: T041 tur 2, K282; rev 11: T041 tur 3, K283; rev 12 (2026-11-13): kapanış drift kontrolü, grill K290–K293
> (kullanıcı), K294–K299 (lead), takip kartları. Tier 2; istisna `scripts/bash_gate.py` kartları T041 ve rev 12'nin ref
> yazma kartı, 🔐 Tier 3, K279)
> Source: kullanıcı isteği (sohbet, 2026-11-04, dört madde); grill kararları K240–K243 ve K262 (kullanıcı), lead kararları
> K244–K261, K263 ve K273–K277. Spec B (#17) aynı anda başka bir lead oturumunda açık olduğu için bu dosya `docs/delix/SPEC.md` yerine
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
  sürüm çıkarken ayrı iş); hook ve `delix.json.protected_paths` altındaki her dosya. İstisna: kart oturumlarının push ve
  ref yazma kuralı için `scripts/bash_gate.py` (T041 ve rev 12'nin ref yazma kartı, 🔐 Tier 3, kullanıcının o işe özel
  evet'iyle; K279, K296).

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
uygulayıcıyı açınca bir `implementer` kaydı (dal `gh pr view <n> --json headRefName`'den, rapordan değil (T036);
Desktop oturum adı `start_session` sonucundan; bilinince doldurulur), `review` her `qa` ve `security` koşusu için
incelenen SHA ve verdict'le bir kayıt. Kullanıcı merge edince lead `status` → `accepted` ile aynı anda `merged`'i yazar; `merged.head` son turun `qa`
SHA'sından farklıysa `accepted` yerine `escalated` (K297).
`board.py` ve panel her kart için "kim açtı" (`opened_by`) ve son tur inceleyicilerini (`last_round`) kartın worktree'si
varsa Ajanlar satırında, worktree'si olsun olmasın Seni bekliyor ve Merge'e hazır satırlarında gösterir (K290, K291);
panelin kart görünümü tüm listeyi gösterir.
#### Scenario: iki inceleme turu
- WHEN T029'un `agents` listesinde tur 1 ve tur 2 için `qa` kayıtları varsa
- THEN board yalnız tur 2'yi (`qa r2 @<sha7> ACCEPT · by <lead branch>`), panel kart görünümü ikisini gösterir
#### Scenario: eski STATE
- WHEN bir kartta `agents` ve `merged` yoksa
- THEN board `—` gösterir, hata vermez; `pr: "merge <sha>"` biçimi merge edilmiş sayılır
#### Scenario: worktree'si olmayan hazır kart
- WHEN merge'e hazır bir kartın hiçbir worktree'si yoksa ve son turu `qa ACCEPT`, `security 🔐 HUMAN_APPROVAL` ise
- THEN iki yüzeyin Seni bekliyor ve Merge'e hazır satırları `opened_by`'ı ve iki kaydı (security verdict'i dahil)
  gösterir (K291)
#### Scenario: panelde ikinci satır
- WHEN kartı olan bir worktree ve bir lead worktree'si varsa
- THEN panelin Ajanlar satırının altındaki soluk satır `opened_by`'ı ve `last_round`'u, Leads satırı `changed_at`'i
  gösterir (K290)
#### Scenario: incelenmemiş uç merge edildi
- WHEN `gh pr view` `MERGED` ve son turun `qa` SHA'sından farklı bir `headRefOid` döndürürse
- THEN lead `merged`'i yazar, kartı `escalated` yapar ve kullanıcıya söyler; kart Seni bekliyor'da kalır (K297)
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
doğrulama (`FIX*` ve `resolution` yok). **Bitti** (`queue.done`): `accepted`; derive ve `board.py --json` üretir, hiçbir
yüzey ayrı bölüm olarak göstermez, panel kart durumunu `kabul` yazar (K295). Kart tablosunun "pending gate" sütunu `agents` kaydı
olan kartta bu kuralı, olmayanda bugünkü kuralı izler (K254).
#### Scenario: inceleme sonrası değişen dal
- WHEN `in_review` bir kartın son turu ACCEPT ama `origin/<dal>` ucu o turdaki SHA'dan farklıysa
- THEN kart merge'e hazır değil, "seni bekliyor" altında `changed after review` notuyla görünür
#### Scenario: tur sürüyor
- WHEN kart `in_review`, PR'ı var, `agents`'ta güncel uç için `qa` kaydı yoksa
- THEN kart merge'e hazır değildir
#### Scenario: merge edilmiş kart panelde
- WHEN kart `accepted` ve `pr` sayıysa
- THEN panel kartın durumunu `kabul` gösterir, merge kapısı yok (önceden panel "merge" diyordu; K255)
#### Scenario: sahte kaynak STATE
- WHEN kartsız bir worktree'deki STATE, `origin/<default>` STATE'inde kaydı olmayan bir kart için `qa ACCEPT` ve PR ucunun
  SHA'sını taşıyor ve board o worktree'den çalışıyor ya da panel onu kaynak seçiyorsa
- THEN kart merge'e hazır değildir, merge komutu yoktur, kart `review not on origin/<default>` notuyla bekler; aynı kayıt
  `origin/<default>`'a push edilince kart merge'e hazır olur

### Requirement: REQ-4 Bekleyen git işleri ve tek satırlık komutlar
The system SHALL bekleyen git işlerini §4'teki sırayla ve komutuyla listeler:
- **push:** ana checkout ve board'u çalıştıran worktree dışında bir worktree'de checkout edilmiş, varsayılan dal olmayan,
  detached olmayan, upstream'i `gone` olmayan ve (upstream'i yok ya da upstream'den ileride) dal:
  `git -C <path> push -u origin <branch>`
- **merge:** merge'e hazır kart: `gh pr merge <n> --squash --match-head-commit <sha40>` (SHA son `qa` kaydından; K247)
- **remove_worktree:** temiz, ana checkout olmayan, board'u çalıştıran worktree olmayan ve (kartı `origin/<default>` STATE'inde
  `accepted` ve `merged` kayıtlı ya da son etkinliği 7 günden eski, upstream'i var ve ileride değil) worktree: `git worktree remove <path>`
- **delete_branch:** hiçbir worktree'de checkout edilmemiş, kartı kaynak STATE'te olan, o kartın `origin/<default>` STATE'inde `merged` kaydı olan ve yerel ucu `merged.head`'e
  eşit dal: `git branch -D <branch>` (K249)
- commit'lenmemiş dosyası olan worktree'ye komut yok: `uncommitted <n> files: commit or discard in its session`; `git
  status` hata verince `<n>` yerine `?` yazar ve komut yine yoktur.
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
sayıları, STATE'in son değişme zamanı (`changed_at`; iki yüzey de gösterir, K290) ve `stale` (son etkinlik 7 günden
eski, K250; ana checkout hiç stale olmaz). Ana tablonun ve kuyruğun kaynağı başlıkta adlandırılır (K256).
#### Scenario: iki aktif lead
- WHEN ana checkout dışında, dalında ya da çalışma ağacında STATE değişikliği olan iki lead worktree'si varsa
- THEN Leads tablosunda üç satır görünür ve her birinin sayıları kendi STATE'inden gelir

### Requirement: REQ-6 İki yüzey aynı sonucu verir
The system SHALL board.py'de ve panelde ham girdiden (§4 git çıktıları + dosyalar) `agents`, `leads`, `queue`
(`waiting`/`ready`/`done`), `actions` ve `fetched_at` alanlarını üreten saf bir `derive(raw)` fonksiyonu tutar;
`board.py --json` bu alanları ekler. Eşlik fixture'ı `tests/fixtures/board_parity.json` (ham girdi + beklenen çıktı)
ve panel kopyası `plugins/delix-board/tests/board_parity.ts`'tir: `export const PARITY = ` + JSON dosyasının baytları
(K252, K261). Panel 20 sn'lik yenilemede N worktree için en çok 4 + 3N git çağrısı yapar (K257, K262).
Fixture yalnız `derive`'ı sınar; ham girdiyi toplayan kod iki yüzeyde aynı kuralları izler ve her yüzey bunları kendi
testinde sınar (K293): `delix.json.default_branch` REQ-4'teki dal kalıbına
(`^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$`) uyan bir metinse o, değilse `main`; çağrı 5
yalnız worktree'de `.delix/card` hiçbir biçimde (normal dosya, bağlantı, dizin, okunamayan dosya) yokken koşar;
çağrı 4–6'nın argv'si §4'teki gibi `--no-lazy-fetch` taşır (K284, K294).
#### Scenario: eşlik
- WHEN fixture iki süite verilirse
- THEN iki `derive` çıktısı fixture'daki `expected` ile alan alan eşittir ve panel kopyası öneki atılınca `cmp` ile
  JSON'a eştir
#### Scenario: ham girdi kuralları
- WHEN `delix.json`'da `default_branch` `"-x"`, `"a b"` ya da `"a//b"` ise ve bir worktree'de `.delix/card` başka bir
  dosyaya bağlantı, hedefi olmayan bir bağlantı, bir dizin ya da kart kimliği taşımayan bir dosyaysa
- THEN iki yüzey `origin/main...HEAD` ile karşılaştırır ve o worktree için çağrı 5'i koşmaz (git çağrı kaydında yok)

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| data | `cards.<T>.agents[]` | `{"role":"implementer"\|"qa"\|"security","by":"<lead branch>","round":<int>,"sha":"<40 hex>"\|null,"verdict":"<token>"\|null,"at":"<ISO-8601 Z>"}`; yalnız `implementer`: `"branch":"<name>"\|null,"session":"<Desktop name>"\|"-p"\|null` | board.py, panel, dispatch/review/close |
| data | `queue.waiting[]`, `queue.ready[]` | bugünkü alanlar aynen + `"opened_by":"<lead branch>"\|null` ve `"last_round":["<role> r<n> @<sha7> <verdict> · by <lead branch>", …]`; ikisi Ajanlar satırındakiyle aynı kaynaktan ve aynı biçimde, kartsız (doğrulama) girdide `null` ve `[]` (K291) | board.py, panel, parite fixture'ı |
| data | `cards.<T>.merged` | `{"sha":"<merge commit 40 hex>","head":"<merged PR head 40 hex>","at":"<ISO>"}`; lead `gh pr view <n> --json state,mergeCommit,headRefOid` ile okur ve yalnız `state` `MERGED` iken yazar (T039) | board.py, panel |
| git | çağrılar (sıra ve argv birebir) | her çağrı `git --no-optional-locks -c core.fsmonitor=false` ile başlar (K263); 4–6 da 7 gibi bu önekten sonra `--no-lazy-fetch` alır (K284, K294); worktree başına çağrılar worktree'yi süreç `cwd`'si olarak alır, argv'de `-C` yoktur; sıra iki yüzeyde farklıdır ve sonucu değiştirmez: panel 7'yi worktree döngüsünden (4–6) önce koşar, board.py 2'yi iki kez okur (K295); 1) `git rev-parse --git-common-dir` 2) `git worktree list --porcelain -z` → NUL ile ayrılmış kayıtlar, `\n` ya da `\r` içeren bir kayıt tüm listeyi geçersiz kılar; yol, HEAD, `branch refs/heads/<b>` \| `detached` 3) `git for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)` → track: boş = `in sync`, `ahead N`, `behind N`, `ahead N, behind M`, `gone`; upstream boş = `no upstream` 4) worktree başına `status --porcelain` → satır sayısı, STATE kirli mi 5) `.delix/card`'ı hiçbir biçimde olmayan (K293) ve STATE'i kirli olmayan worktree başına `diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` → exit 1 = dal STATE'i değiştirmiş (K275) 6) STATE kirli değilse `log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`: board.py ana checkout ve her lead için, panel `.delix/card`'ı olmayan ve STATE dosyası olan her worktree için (panel rolü çağrılardan sonra bilir; sonuç aynı, bütçe 4 + 3N içinde; K277, K295) 7) bakış başına bir kez, kendi kökünde `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json` → ham `trusted_state`; hata ya da `origin/HEAD` yok = null, hiçbir kart merge'e hazır olmaz (K262, K276); derive, çağrı 3 çıktısında `refs/remotes/origin/HEAD` yoksa `trusted_state` ne olursa olsun T = `{}` sayar (R8'', K277); her çağrı zaman aşımlı, hata alanı `?` yapar | derive |
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
Tier 2; korumalı yola yalnız `scripts/bash_gate.py` kartları dokunur (T041 ve rev 12'nin ref yazma kartı, 🔐 Tier 3, K279, K296). Risk: board'un ürettiği komut Run düğmesiyle kullanıcının Mac'inde çalışır; dal ve
yol adları git'ten gelir ve auto mode'daki bir oturum `refs/heads/-f` gibi bir dal yaratabilir. K248: ad kalıpları
`-` ile başlayan, boşluk ya da kabuk karakteri içeren her şeyi dışlar, böylece tırnaklamaya gerek kalmaz ve iki dilde
aynı kalır; `gh pr merge` incelenen SHA'ya `--match-head-commit` ile bağlanır, bayat ref incelenmemiş ucu merge
edemez. Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz; nesne okuyan çağrılar (4–7) `--no-lazy-fetch` taşır: ağaçsız partial clone'da (`--filter=tree:0`) çağrı 6'nın `log`'u eksik nesneyi remote'tan çekiyordu (lead git 2.54'te üretti; bayrakla çıkış 128, çekme yok; K284). git < 2.44 bu bayrağı reddeder: 4–6 hata verir, alanlar `?` olur ve o worktree'ler için Git actions komutu çıkmaz (fail closed, K294). Merge kullanıcının tıklamasıdır (kapı 2). Bilinen sınır:
lead'in `gh pr merge`'ü ya da bir Git actions komutunu çalıştırmasını bir hook engellemez (yalnız skill metni);
Known limits'e yazılır.

Kaynak STATE güvenilir değildir (K262): kartsız herhangi bir worktree'ye yazılan STATE kaynak olabilir. Merge'e hazır,
merge komutu ve `merged`'e dayanan temizlik önerileri yalnız `refs/remotes/origin/HEAD`'in gösterdiği STATE de
(uzak deponun varsayılan dalı; `delix.json`'daki `default_branch` bu ref'i seçmez, K276) aynı kart, PR ve SHA'yı gösterince
üretilir; o kopyaya lead push eder (review §4). Bu spec'te "`origin/<default>` STATE'i" bu kopyadır. Kalan risk: bir oturum yerel izleme ref'ini commit +
`update-ref` ile yeniden yazabilir (kart oturumunda bunu ve `git remote set-head`'i rev 12'nin 🔐 ref yazma kartı reddeder; K296); bu, uç denetiminin `refs/remotes/origin/<dal>`'a duyduğu güvenle aynıdır, dosya
yazmaktan fazlasını ister ve sonraki fetch ref'i düzeltir. `origin/HEAD`'i `git remote set-head` ile başka dala çevirmek
de `.git`'e yazmaktır; fetch onu düzeltmez, `git remote set-head origin -a` düzeltir. `git clone` `origin/HEAD`'i kurar;
`git init` + `remote add` ile kurulan depoda bir kez `git remote set-head origin -a` gerekir, yoksa hiçbir kart hazır olmaz.
Kart oturumları kullanıcının kimliğiyle `git push origin HEAD:<default>` çalıştırabiliyordu ve varsayılan dalın ruleset'i
kullanıcı rolüne bypass verir (T036 tur 1 security notu); T041'den beri `bash_gate` kart oturumunun varsayılan dala push'unu
ve `gh pr merge`'ü reddeder (🔐, K279–K283). Bu derinlemesine savunmadır, ruleset'teki sahip bypass'ı kalır; kuralın tamamı
(R-P2a–R-P6) yalnız T041 kartındadır, kalan açıkları rev 12'nin ref yazma kartı kapatır. Git çağrıları `--no-optional-locks` (başka worktree'nin
index'ine yazmaz) ve `-c core.fsmonitor=false` ile koşar: paylaşılan `.git/config`'teki bir fsmonitor betiği her
worktree'deki `git status`'ta çalışır (lead 2026-11-05'te git 2.54'te üretti; bayrakla çalışmadı) (K263). `git diff
--quiet` paylaşılan config'teki `diff.external` + `diff.trustExitCode`'u ve `.gitattributes` diff sürücüsünü çalıştırır
(lead 2026-11-12'de üretti; `--no-ext-diff` ile çalışmadı; textconv `--quiet` ile çalışmaz) (K275). Spec ve kart
dosyası yalnız worktree içinde, normal dosya ve ≤ 1 MiB ise okunur. Doğrulanmadı: `filter.<driver>.clean` `git status`'ta
çalışabilir; ön koşulu `.git/config`'e yazmak ya da global config'te tanımlı bir sürücü için worktree'ye `.gitattributes`
yazmak (ör. `filter.lfs.clean`).

Wave 9 tur 2'de lead'in git 2.54'te ürettiği üç yol (K277, takip kartı): `log.showSignature` + `gpg.program` çağrı 6'da
imzalı commit başına bir program çalıştırır (`--no-show-signature` ile çalışmadı); `refs/replace/*` çağrı 7'nin okuduğu
blob'u değiştirir (`--no-replace-objects` ile değişmedi); `origin/HEAD` yokken `refs/heads/refs/remotes/origin/HEAD` ya da
aynı adlı etiket çağrı 7'de çözülür, yani "`origin/HEAD` yok = null" git düzeyinde tutmaz (varken tam ad kazanır). Üçünün
ön koşulu paylaşılan `.git`'e (config ya da ref) yazmaktır; bu yazma `core.hooksPath` ile lead'in sıradan commit'inde de
kod çalıştırır (lead üretti), bu yüzden board'daki bu sertleştirmeler derinlemesine savunmadır.

## 7. Acceptance criteria (DoD)
- [ ] Her REQ için geçen test; doğrulama: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0,
  `claude plugin test plugins/delix-board` → geçer, `claude plugin validate .` → geçer
- [ ] Mevcut `tests/board_tests.sh` ve panel testlerinde değişen satır yalnız kartlarda satır numarası ve gerekçesiyle
  adı geçenlerdir (K255, K273, T038 satır 678, T043)
- [ ] `qa` ACCEPT (Tier 2)
- [x] Bu repoda gerçek koşu: `/delixcrew:status` bu oturumun worktree'sini `lead` gösterir, Run bloklarında `-f`,
  `reset`, `clean` yoktur (2026-11-12, kapanış; STATUS §13)
- [ ] Panel aynı satırları gösterir, Desktop'ta ekran görüntüsüyle doğrulanır: delix-board'un rev 12'yi taşıyan sürümü bu
  Mac'e kurulduktan sonra; görüntü ve gözlem `docs/delix/verifications/` altına yazılır (K292)
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
- **K244** (lead, geri alınır) Spec B açıkken bu spec `docs/delix/specs/C-board-visibility.md`'de, K blok K240–K299 (K280'den sonrası Spec B kapandıktan sonra),
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
- **K277** (lead, 2026-11-12, geri alınır) Wave 9 tur 2'de kapanır (T034 qa ACCEPT, security CLEAN; T035 qa ACCEPT_WITH_NOTES,
  security CLEAN). Tur 2 güvenlik notları (§6'daki üç git yolu, stat ile open arası yarış ve sınırsız okuma, yol parçasındaki
  bağlantı, `readSnapshot` okumaları) tek takip kartına gider: çağrı 6 `--no-show-signature`, çağrı 7 `--no-replace-objects`,
  derive çağrı 3 çıktısında `refs/remotes/origin/HEAD` yoksa T'yi `{}` sayar, tek güvenli okuma yardımcısı. Neden: hepsi Low,
  ön koşulları `.git`'e yazmak ve bu zaten kod çalıştırıyor; inceleme kuralı yalnız Medium ve üstünü düzeltir, Low için
  son tur (3) harcanmaz. K275 açık bir düzeltme turuna eklendiği için yükseltilmişti. Takip kartları (rev 8): T037 board.py ve
  T038 panel (aynı R-G6, R-G7, R8'' ve tek güvenli okuma yardımcısı), T039 review §4 `MERGED` kontrolü, T040 F010 (K278),
  T041 🔐 kart oturumunun push kuralı (K279).
- **K278** (kullanıcı, 2026-11-12, geri alınır) F010 tasarım B: uygulayıcı kartın Verification çıktısını
  `.delix/evidence/verification.txt`'ye yazar, review ve qa iki dosyayı da okur; Stop gate ve `test-result.txt` aynen kalır
  (K213/K218 değişmez, Tier 2, T040). A (gate `.delix/stop-gate.txt`'ye yazar) reddedildi: Tier 3, ~10 mevcut test satırı,
  README/site ve panelin "test sonucu" anlamı değişirdi.
- **K279** (kullanıcı, 2026-11-12, geri alınır) `main-review` ruleset'indeki sahip bypass'ı kalır: lead her turda STATE'i
  main'e doğrudan push eder (review §4). Kart oturumlarının varsayılan dala push'unu ve `gh pr merge`'ü T041'deki
  `bash_gate` kuralı reddeder (🔐, kullanıcı "Evet, T041 (R-P6 dahil)"); bu derinlemesine savunmadır, GitHub sınırı değildir
  ve Known limits'e yazılır. Lead ekleri: başarısız git çağrısı = reddet (çıkış 0/1 dışı ya da yok), komutta `cd`/`pushd`/`popd`
  varsa push reddedilir.
- **K280** (lead, 2026-11-12, geri alınır) T041 uygulayıcı eki: `push.default=upstream` iken dal adı biçimi dalın
  upstream'ine gider; lead tekrar üretti (`origin/main`'i izleyen dalda `git push origin claude/t1` uzaktaki main'i
  günceller). Dal adı biçimi yalnız `branch.<b>.merge` boşken ya da dalın kendisiyken geçer; `HEAD` biçimi etkilenmez.
  Kuralı yalnız daraltır. Uygulayıcı oturumu kullanıcı onayı bildirdi; lead o kaydı görmediği için lead kararı yazılır.
- **K281** (lead, 2026-11-12, geri alınır) T041 tur 1 security Medium ×2. (1) R-P3b: push aynı komutta yalnız global
  seçeneksiz `add`, `commit`, `status`, `diff`, `log`, `show` git komutlarıyla durur. Hook dalı ve upstream'i komut
  çalışmadan okur; aynı satırdaki `checkout`, `switch` ya da bir alias (`co`) push'tan önce dalı değiştirebiliyordu.
  Engelleme listesi değil izin listesi: alias'lar da kapanır. (2) Known limits'teki `gh api` satırı "delixcrew'un kendi
  reposu dışındaki her repoda" olur; REPO_DENY yalnız delixcrew reposunu kapsar (kartın Out of reach maddesi yanlıştı).
  İkisi de kuralı daraltır ya da dokümanı düzeltir; K279'daki 🔐 onayının kapsamı büyümez.
- **K282** (lead, 2026-11-12, geri alınır) T041 tur 2 security Medium ×2; lead gerçek git 2.54 ile üretti (hook izin verdi,
  uzaktaki main ilerledi). (1) R-P2a: değer alan `--attr-source` ve `--shallow-file` alt komutu gizliyordu
  (`git --attr-source HEAD push origin main`); git'in kendi değersiz seçenek listesi ve `--ad=değer` dışındaki her seçenek
  reddedilir (izin listesi). (2) R-P4a: `help.autocorrect` açıkken git bilmediği adın yerine en yakın komutu çalıştırır
  (`psuh` → `push`); `help.` R-P5 anahtarlarına girer, ayar açıksa git'in listelemediği ad reddedilir. Bilinen sınırlara
  glob ve ANSI-C tırnağı, `gh pr checkout`, `pr merge` için `gh` alias'ı ve `git remote` ile verilen URL eklenir. (3) Lead:
  `--config-env` ile verilen alias da main'i push ediyordu; R-P5 `--config-env` anahtarını `-c` gibi denetler. Kuralı
  daraltır; 🔐 onayının kapsamı büyümez. Tur 3 son turdur (`max_review_rounds` 3); orada da Medium çıkarsa kullanıcıya
  seçenek götürülür.
- **K283** (kullanıcı, 2026-11-12, geri alınır) T041 tur 3: qa ACCEPT, security Medium. Değersiz yazılmış
  `help.autocorrect` (`[help]` altında yalnız `autocorrect`) git için açıktır, ama `git config --get` boş satır basar ve
  R-P4a onu kapalı okuyordu; lead gerçek git 2.54 ile üretti (hook izin verdi, uzaktaki main ilerledi). Tur sınırı
  (`max_review_rounds` 3) doldu; kullanıcı sınırın üstünde tek, küçük bir 4. turu seçti ("Evet, 4. tur"). İçerik: boş
  olmayan okuma açık sayılır (açıkça boş değer de: fail closed), aynı satırda başka komutun yazdığı git ayarı bilinen
  sınırlara girer (kod değil), site sınır listesi kartla eşitlenir. Kuralı daraltır; 🔐 onayının kapsamı büyümez.
  4. turda yeni Medium çıkarsa düzeltme turu açılmaz, kullanıcıya gelinir. Satırın tamamını izin listesine bağlamak
  takip işidir.
- **K284** (lead, 2026-11-12, geri alınır) T032 güvenlik notu: ağaçsız partial clone'da (`--filter=tree:0`, git 2.54)
  çağrı 6'nın `log`'u eksik nesneyi remote'tan çekiyordu (lead üretti: pack 3 → 4; `--no-lazy-fetch` ile çıkış 128,
  çekme yok). Düzeltme turu açılmadı, düzeltme takip kartında (K294).
- **K285** (lead, 2026-11-12, geri alınır) Spec C değişiklikleri kapanışta CHANGELOG `## Unreleased`'a yazıldı; sürüm
  numarası, kök `plugin.json` (korunan yol, 🔐) ve sitedeki "sonraki sürümle gelecek" etiketleri ayrı bir sürüm kartının
  işi.
- **K290** (kullanıcı, 2026-11-13, geri alınır) Kapanış drift kontrolü: panel `changed_at`'i (Leads), `opened_by`'ı ve
  `last_round`'u (Ajanlar) göstermiyordu; derive üretiyor, `board.py` basıyordu. Panele eklenir (seçenek A, "Panele
  ekle"); dar panelde kesilmemesi için Ajanlar satırının altında ikinci, soluk bir satır. Spec'i daraltmak (B) reddedildi:
  veri hazır ve REQ-5 ile DoD "panel aynı satırları gösterir" diyor. delix-board yama sürümü artar.
- **K291** (kullanıcı, 2026-11-13, geri alınır) "Kim açtı" ve son tur yalnız Ajanlar satırındaydı; worktree'si olmayan
  kartta `board.py`'de hiç, panelde yalnız kart görünümünde vardı. `queue.waiting[]` ve `queue.ready[]` girdileri
  `opened_by` ve `last_round` taşır (§4), iki yüzey basar. Neden: merge kararı Merge'e hazır listesinden verilir ve
  `security` verdict'inin `CLEAN` mi `🔐 HUMAN_APPROVAL` mı olduğu orada görünmeli. Bedel: parite fixture'ının
  `expected`'ı değişir (K252: architect üretir, lead dispatch'ten önce yazar).
- **K292** (kullanıcı, 2026-11-13, geri alınır) DoD'un panel ekran görüntüsü, delix-board'un rev 12'yi taşıyan sürümü
  bu Mac'e kurulunca alınır ve `docs/delix/verifications/` altına yazılır; o zamana kadar madde açık. Bu Mac'te kurulu
  delix-board 0.1.4, Spec C'nin paneli 0.1.5'te ve yayınlanmadı. Yerelden kurmak (Mac değişiklik protokolü, kapsam büyür)
  ve maddeyi kaldırmak (gerçek görünüm doğrulanmamış kalır) reddedildi.
- **K293** (kullanıcı, 2026-11-13, geri alınır) Ham girdi iki yüzeyde tek kurala bağlanır (REQ-6): `default_branch` REQ-4
  dal kalıbı, değilse `main` (bugün panelin davranışı; `board.py` boş olmayan her metni alıyordu); çağrı 5 `.delix/card`
  hiçbir biçimde yokken koşar (bugün panelin davranışı; `board.py` kart kimliği okunamayınca, bağlantıda da koşuyordu).
  Kırık kartlı bir worktree üç noktalı diff yüzünden lead sayılmaz; STATE'i kirliyse ya da dalı bir `by` değeriyse
  REQ-1 gereği lead'dir. Etki küçüktü (rol tespiti, Leads tablosu; merge kararı `origin/HEAD`
  STATE'inden); farkı spec'e yazmak (B) reddedildi.
- **K294** (lead, 2026-11-13, geri alınır) K284'ün düzeltmesi: çağrı 4–6 (`status`, `diff`, `log`) iki yüzeyde 7 gibi
  `--no-lazy-fetch` alır. git < 2.44 bayrağı reddeder: 4–6 hata verir, alanlar `?`, o worktree'lerin Git actions'ı not
  olur; K262'den beri o sürümde zaten hiçbir kart hazır değildir (fail closed). Reddedilen: hook'lardaki gibi
  `GIT_NO_LAZY_FETCH=1` ortam değişkeni (K225): eski git'te korumayı sessizce kaybeder, panelin süreç çağrısında ortam
  verilebildiği doğrulanmadı ve ham toplama iki yüzeyde yine ayrışırdı (K293). Kapsam 4–6: 1–3 ağaç ya da blob okumaz
  (lead üretmedi, doğrulanmadı); README ve site Known limits'e eski git satırı docs kartıyla girer.
- **K295** (lead, 2026-11-13, geri alınır) Drift düzeltmeleri, davranış değişmez, spec koda uyar: §4 çağrı sırası ve
  argv (`cwd`, `-C` yok; panel 7'yi döngüden önce, `board.py` 2'yi iki kez okur); REQ-6 panel kopyası `board_parity.ts`
  (K261); REQ-2 dal `gh pr view`'dan (T036); Tier ve kapsam (§2, §6; T041 korunan yolu değiştirdi, K279); §6'daki
  "`bash_gate` bunu engellemez" cümlesi T041'le eskidi; "bitti" yerine `kabul`, `queue.done` hiçbir yüzeyde bölüm değil;
  ana checkout ve board'un kendi worktree'si push ve `remove_worktree` almaz, ana checkout stale olmaz; `delete_branch`
  kartın kaynak STATE'te de olmasını ister; `git status` hatasında `uncommitted ? files` notu; T041 kuralının tamamı
  yalnız kartta.
- **K296** (lead, 2026-11-13, geri alınır) T032 security notu (uçtan uca izlenmedi): güvenilir STATE yerel
  `refs/remotes/origin/HEAD`'ten okunur ve bu ref'ler worktree'ler arasında paylaşılır; kart oturumu `git update-ref`,
  `git remote set-head` ya da eşdeğeri bir yazmayla lead'in board'una sahte "merge'e hazır" gösterebilir. Kart oturumunda
  bu yazmaları `bash_gate` reddeder: 🔐 Tier 3 kart (`scripts/bash_gate.py` korunan yol), dispatch'ten önce kullanıcının o
  işe özel evet'i ve kartta `**🔐 Approved:**` satırı gerekir. T041'in kalan notları (aynı satırdaki başka komutun yazdığı
  git ayarı, push satırının tamamına izin listesi, UTF-8 olmayan config baytında belirsiz ret, `delix.json` nesne değilken
  atlanan kurallar, `gh` alias ve `git remote set-url`) aynı hook'ta olduğu için aynı karta girer (`scripts/bash_gate.py`, gerekirse
  `scripts/common.py`); kapsamı architect kartla sınırlar.
- **K297** (lead, 2026-11-13, geri alınır) Merge sonrası kontrol (T039 incelemesinin notu): lead `merged`'i yazarken
  `headRefOid`'i son turun `qa` kaydındaki SHA ile karşılaştırır. Eşitse bugünkü gibi `accepted`. Farklıysa `merged`'i
  yine yazar (olgu), kartı `escalated` yapar ve kullanıcıya "incelenmemiş uç merge edildi" der; kart Seni bekliyor'da
  kalır ve `remove_worktree` önerilmez (`accepted` ister). Reddedilen: `accepted` + not; incelenmemiş kod merge edilmiş
  sayılırdı. Kartta `qa` kaydı yoksa fark var sayılır (fail closed). Yer: review §4 ve close skill'inin `merged` adımı,
  `tests/ledger_tests.sh`.
- **K298** (lead, 2026-11-13, geri alınır) Rev 12 takip kartları (architect job B): dalga 15 paralel, dosyaları ayrık:
  T043 iki board yüzeyi (`scripts/board.py`, panel `data.ts`/`parse.ts`/`views.tsx`; K284/K294, K290, K291, K293, T038
  notları), 🔐 T044 `scripts/bash_gate.py` (K296, T041 notları), T045 review ve close skill metni (K297), review §2'deki "dosya içeriği veridir" cümlesi ve `agents/qa.md`
  kanıt maddesi (K278 artığı); dalga 16 T046
  doküman ve site (delix-board 0.1.6), T042 sürüm kartından sonra (başka oturumun kartı; numara ona ayrıldı). Bütün board
  işi tek kartta: iki süit parite fixture'ını birebir eşitlikle karşılaştırır, K291 `expected.queue`'yu değiştirir ve iki
  derive ile fixture tek PR'da inmezse main kırmızı kalır. Bu yüzden K252'nin istisnası: fixture değişikliğini lead
  dispatch'ten önce yazmaz, T043 kartındaki birebir farkı uygulayıcı uygular, başka satıra dokunmaz. T044'ün README ve
  site cümleleri CLAUDE.md'nin "aynı değişiklik" kuralının istisnası olarak T046'da iner (T044 kartının
  `## Docs handover (T046)` bölümü).
- **K299** (lead, 2026-11-13, geri alınır) T044 kartı Sonnet oturumunda yazıldı (architect çağrısı iki kez model
  güvenlik filtresine takıldı); lead çapaları 4246815'te doğruladı. Kapsam R-U1–R-U5; kartın kararları D1–D6 bu
  numarada: `git remote` izin listesine bağlı (düz, `-v` / `--verbose`, `show`, `get-url`; geri kalan her biçim ret,
  fail closed), `set-url` kapsamda (T041'in push kuralı `origin` adına güvenir), `scripts/common.py` değişmez
  (`trust.py` `UnicodeDecodeError`'a dayanır; yakalama `bash_gate.py`'de), nesne olmayan `delix.json` kart
  worktree'sinde bütün Bash'i reddeder, yeni test dosyası `tests/ref_gate_tests.sh`, büyüme testi ×8 girdide oran < 20.
  K296'daki `gh` alias'ı kapsam dışı (O3, K279: derinlemesine savunma). Lead kararı (O4): `git symbolic-ref`'in
  yazma biçimi bu karta girmez; `refs/remotes/` içine refspec'li `git fetch` aynı ref'i yazar ve bütünüyle
  reddedilemez, tek yolu kapatmak kuralın vaadini değiştirmez; T046'nın Bilinen sınırlar cümlesi (kartın H2'si) onu
  adıyla anar. Ayrı 🔐 kart adayları (korunan yol): O5 ayrışmayan `delix.json`'ı `common.delix_json` `{}` okur ve
  Bash'in korunan yol denetimi boşalır (kart yazarı 4246815'te ölçtü); O6 `write_gate.py` nesne olmayan değerde çöker.
