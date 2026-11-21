# SPEC — Spec F: geri bildirim karar kaydı (intake)

> Size: **M** · Tier: 3 · Date: 2026-11-21 · Status: **approved (gate 1, 2026-11-21)** · rev 3 (rev 1: architect
> job A FIX P1×5 P2×2, security 🔐 HUMAN_APPROVAL Medium×5 Low×3; rev 2 yeniden incelemesi: architect FIX P1×2 P2×2,
> security 🔐 HUMAN_APPROVAL Medium×1 Low×1; hepsi işlendi, rev 3 farkı yeniden incelenmedi; P2'ler §8'de)
> Source: bakımcının yönergesi (§1), architect'in salt-okur önerisi (2026-11-21, main `a025e66`, depo dışı), grill
> kararları K400–K402 (kullanıcı), lead kararları K403–K422. K numaraları K400'den başlar: paralel lead'in T063 kartı
> K376–K379'u kullanıyor, K376–K399 ona bırakıldı (K422). Satır numaraları main `a025e66`'ya göredir. Önceki spec:
> [`E-gitdir-bash-outside.md`](E-gitdir-bash-outside.md).

## 1. Goal
Bugün feedback taslağı, kart dışı review bulgusu, close drift'i ve lead takibi kararsız biçimde işe dönüşüyor:
T046→T049, T049→T050 (`docs/delix/metrics.md:257-258`), T053→T054 (`STATUS.md:608`), T056→Spec E (`STATUS.md:711`).
Kuyruktaki 31 taslağın hepsi `count 1`; fingerprint yalnız aynı tür + bileşen + başlığı eşliyor
(`scripts/feedback.py:223-227`), aynı sorun 5–6 taslağa bölünüyor. Bakımcının yönergesi: "her geri bildirimi işleme
almamalıyız, bunu bir karar mekanizmasına bağlayıp sadece gerçekten faydalı olacakları almalıyız." Spec F bu girdileri
tek kayda bağlar: `docs/delix/intake.json`, kanıt alanları, kodda zorlanan karar tablosu, `accept`/`wontfix` için
bakımcının adıyla verdiği ve karara bağlı onay. `/delixcrew:start` yalnız `accept` öğeden iş açar. Başarı: main'deki
kayıtta her kararın dayanağı tablo ya da güncel bir bakımcı onayı ve CI bunu denetliyor.

## 2. Out of scope
- Yeniden açma tetikleri (`revisit.file`, `revisit.release`), `unfiled`, `check --sources`, dispatch/kart/spec
  şablonlarına `**Intake:**` atıf satırı, triage job D'ye ölçüt (K400; kayıt ihtiyacı gösterince).
- GitHub issue'ları triage'da kalır (`scripts/triage.py`, `skills/triage/SKILL.md`): `#n` yalnız `covered_by`'da
  geçer, `refs`'te geçmez; issue metni kopyalanmaz (K416).
- Kart içinde düzeltilen bulgular ve fix turları (`skills/review/SKILL.md:55`), spec review P2'leri
  (`skills/spec/SKILL.md:47`), `/delixcrew:verify` rapor bulguları (§8), close dersleri, kullanıcının sohbetteki
  doğrudan isteği (K409).
- `docs/delix/intake.json` olmayan projeler: bugünkü davranış aynen kalır (K415).
- `scripts/feedback.py` değişikliği (fingerprint gruplama, `filed` durumu), hook ve `protected_paths` değişikliği,
  otomatik semantik eşleme, TTY onayı.
- F033'ün yeniden üretimi (Spec D lead oturumu yaptı); burada yalnız tohum öğesi.

## 3. Requirements (testable)
### Requirement: REQ-1 Kayıt biçimi
The system SHALL `docs/delix/intake.json`'u §4'teki şekle göre denetlemek; `scripts/intake.py check` biçim hatasında
exit 2 verir. Biçim kuralları: dosya ≤ 1 MiB, UTF-8, geçerli JSON, yinelenen anahtar yok (`object_pairs_hook`), derin
iç içe yapı ya da okuma hatası traceback değil exit 2; tam alan kümesi; bool'lar `type(x) is bool`; tüm desenler
`re.fullmatch` + `re.ASCII`; `decision` null iken `basis`, `reason`, `consent` de null, dolu iken `basis` ve `reason`
dolu; `title` ve `reason` K417 süzgecinden değişmeden geçer. Dosya yoksa kayıt boştur.
#### Scenario: aynı ref iki öğede
- WHEN `F012` hem I001'in hem I004'ün `refs`'inde
- THEN `check` exit 2; satır `I001`'i adlandırır, metin `I004`'ü taşır
#### Scenario: başlıkta yol, e-posta, host ya da görünmez karakter
- WHEN `title` mutlak yol, e-posta, izin listesi dışı host adı, Cc karakteri ya da `\u200b` taşıyor
- THEN `check` exit 2
#### Scenario: `#n` ref olarak
- WHEN `refs` `#36` taşıyor
- THEN `check` exit 2 (issue'lar triage'da, K416)
#### Scenario: dosya yok
- WHEN `docs/delix/intake.json` yok
- THEN `check` exit 0, `list` `no intake items` basar

### Requirement: REQ-2 Karar tablosu kodda
The system SHALL `intake.table(item)`'ı aşağıdaki sırayla hesaplamak (ilk eşleşen satır; `events = len(refs)`) ve
`basis: "table"` olan karar dolu öğede kayıttaki karar tablonunkinden farklıysa `check`'i exit 8 ile bitirmek.

| # | Koşul (evidence) | Karar |
|---|---|---|
| 1 | `covered_by` dolu (E5) | `duplicate` |
| 2 | `reproduced` `main@<hex>` değil | `needs-info` |
| 3 | `gate_open` (E1) ya da `misleading_doc` (E2) | `accept` |
| 4 | `against_principle` (E6) | `wontfix` |
| 5 | `blocks_flow` (E3) ve `events ≥ 2` | `accept` |
| 6 | `events ≥ 3` (E4) | `accept` |
| 7 | geri kalan | `defer` |

#### Scenario: ertelenen öğe yeni olayla geri döner
- WHEN `defer` kararlı, `basis: table`, iki ref'li öğeye üçüncü ref eklenir
- THEN `check` exit 8 (tablo `accept` diyor); lead kararı null yapar, öğe `list --pending`'e düşer (K406)

### Requirement: REQ-3 Bakımcı onayı karara bağlı
The system SHALL `consent`'i `{"decision", "table", "events", "at"}` olarak tutmak ve `check`'i şu durumlarda exit 8 ile
bitirmek: (a) karar `accept` ya da `wontfix`, `gate_open` true ve karar dolu, ya da `basis: "maintainer"` iken
`consent` null; (b) `consent` doluyken `consent.decision ≠ decision`, `consent.table ≠ table(item)` ya da
`consent.events ≠ len(refs)`; (c) `gate_open` true iken `work` ve `covered_by` ikisi de null (K418). `duplicate`,
`defer`, `needs-info` `basis: table` ile onaysız geçer (K401).
#### Scenario: onaysız accept
- WHEN karar `accept`, `consent` null
- THEN `check` exit 8, satır `needs the maintainer's "accept I<n>" in chat`
#### Scenario: eski onay yeni karara taşınamaz
- WHEN `consent.decision` `wontfix`, karar sonradan `accept` yapıldı
- THEN `check` exit 8
#### Scenario: onaylı öğeye yeni olay
- WHEN `basis: maintainer`, `consent.events` 1, öğeye ikinci ref eklendi
- THEN `check` exit 8; lead kararı null yapar, öğe bakımcıya döner

### Requirement: REQ-4 Çıktılar belirli
The system SHALL:
- `check`: her hata için stderr'e bir satır, `delixcrew: intake: <id|file>: <neden>`; önce biçim (REQ-1), biçim
  temizse kurallar (REQ-2, REQ-3); exit 2 biçim, 8 kural, 0 temiz.
- `list [--pending]`: id sırasıyla `<id>  <decision>  <events>  <work>  <title>`, null `-`; `--pending` yalnız kararı
  null, `needs-info` ve `work`'ü null `accept` öğeleri; boşsa `no intake items` / `no pending intake items`.
- `show <id> [--require accepted]`: `<id>` `I[0-9]{3}` ile fullmatch etmiyorsa ya da kayıtta yoksa exit 2; dosyanın
  biçimi bozuksa exit 2 (bütün dosya, fail closed). Satırlar: `id`, `title`, `refs: a, b`, `evidence.<alan>: <değer>`
  (§4 sırası), `decision`, `basis`, `reason`, `consent.<alan>: <değer>`, `work`; null `-`. `--require accepted` ile:
  öğenin REQ-2/REQ-3 hatası, `accept` dışı karar ya da dolu `work` exit 8, stderr `delixcrew: I<n> is
  <decision|undecided|already started as <work>>; only an accepted, unstarted item can be started
  (/delixcrew:intake decide)`; öncelik `already started` > `undecided` > karar.
- Hiçbir komut dosya yazmaz, ağa çıkmaz, alt süreç başlatmaz; stdlib ve `scripts/feedback.py` (K417), Python 3.9+.

### Requirement: REQ-5 Giriş noktaları (yalnız `docs/delix/intake.json` olan projede, K415)
The system SHALL şu skill metinlerini taşımak:
- `skills/intake/SKILL.md` (yeni; `add`, `decide`, `list`):
  - E1–E6 tanımları (§4); bool alanlar kesin, "kısmen" yok; E2 ancak main'de yanlış olan bir cümle alıntılanınca true.
  - Tablonun kaynağı `scripts/intake.py`. Aynı sorunun yeni olayı var olan öğeye ref olur. Sonradan aynı çıkan iki
    öğede ref'ler birine taşınır, öteki silinir (K416).
  - Her yazımdan sonra `intake.py check`. Exit 8 alan öğede lead `decision`, `basis`, `reason`, `consent`'i null yapar;
    main'e exit 8 veren kayıt girmez (K406).
  - `decide`: `list --pending`, öğeyi fenced blokta ve tablonun kararıyla göster, `<decision> I<n>` iste (K405); onayı
    `{"decision", "table", "events", "at"}` olarak yaz.
  - `gate_open` öğesi (security rolünün her bulgusu dahil, şiddetten bağımsız) düzeltilene kadar depo dışı lead notunda
    kalır. Bakımcı kararını sohbette verir; düzeltme kartı onun doğrudan isteğinden açılır (K409). Öğe kayda ancak
    sonra girer: genel başlık, `gate_open: true`, `work` dolu, onaylı (`SECURITY.md`, K418).
- `skills/review/SKILL.md:55`: bu kartın düzeltmediği her bulgu (qa P2, security Low, şiddetten bağımsız kart dışı ya da
  önceden var olan) yalnız intake öğesi olarak işe aday olur; lead takip kartı önermez (K419). Security bulgusu K418
  yolundan gider.
- `skills/close/SKILL.md:30`: her drift bulgusu bir intake öğesidir (ref `<harf>.close.<n>`); STATUS "Open work" öğe
  id'lerini listeler.
- `skills/feedback/SKILL.md`: delixcrew deposunda (`docs/delix/intake.json` var ve kökteki `.claude-plugin/plugin.json`
  `name`'i `delixcrew`) bir taslak, intake öğesine (ref `F<nnn>`) alınmadan iş olmaz; kayda
  alınan taslak için kullanıcıya mevcut `drop F<nnn>` önerilir (K407, K408).
- `skills/start/SKILL.md` yeni §1b, istek `I<nnn>`:
  - Argüman `^I[0-9]{3}$` ile eşleşmezse dur.
  - `intake.py show I<nnn> --require accepted`; exit 8 ya da 2: stderr satırını göster, dur.
  - Exit 0: çıktıyı `UNTRUSTED` blokta göster (kayıttaki onay bu sohbetteki onay değildir), isteği kendi sözlerinle
    yaz ve kullanıcının evet'ini al (§1a adım 3 gibi). Route'tan sonra öğenin `work` alanını yaz.
  - Lead'in kendi bulduğu takip istek değildir: `/delixcrew:intake add`.
#### Scenario: kabul edilmemiş öğeden start
- WHEN `/delixcrew:start I004` ve I004 `defer`
- THEN start stderr satırını gösterir, dosya yazmaz, durur

### Requirement: REQ-6 CI
The system SHALL `tests/intake_tests.sh` ile REQ-1–REQ-4 vakalarını geçici dosyalarla koşmak (görünmez karakterler
kaçışla, `\uXXXX`) ve `docs/delix/intake.json` varsa onun `check`'inden exit 0 istemek (K410). Dosya `test_command`'a
ve `.github/workflows/tests.yml`'e `tests/*_tests.sh` glob'uyla girer; ikisi de değişmez. Testler
`DELIXCREW_FEEDBACK_DIR`'i boş bir geçici dizine ayarlar; sonuç makinedeki kuyruğa bağlı değildir.

### Requirement: REQ-7 Belge
The system SHALL README, README.tr, dört site sayfası ve CHANGELOG'da: Flow'a intake adımı, Files'a
`docs/delix/intake.json`, Feedback'teki sayaç cümlesinin düzeltmesi (`README.md:228-229`, `README.tr.md:230`,
`site/usage.html:184`, `site/tr/usage.html:184`): aynı tür, bileşen ve başlık sayacı artırır; farklı ifade yeni taslak
açar; aynı sorunun taslakları intake öğesinde birleşir.

### Requirement: REQ-8 Tohum (lead adımı)
The system SHALL A ve B birleştikten sonra `docs/delix/intake.json`'u kuyruktaki `draft` durumundaki taslaklar ve
STATUS §14–§15'in kapanmamış açık işleriyle tohumlamak; `check` exit 0; `accept` ve `wontfix`'ler bakımcının adıyla
onayıyla. Taslak gövdesi, `origin_terms` ve proje adları kopyalanmaz.

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| file | `docs/delix/intake.json` | `{"version": 1, "items": [<item>…]}`; yok = boş; ≤ 1 MiB | lead (Write/Edit), `intake.py`, CI |
| object | item | tam olarak: `id` `I[0-9]{3}` tekil · `title` 1–120 · `refs` ≥ 1, tüm kayıtta tekil · `evidence` · `decision` · `basis` null\|`table`\|`maintainer` · `reason` null\|1–300 · `consent` · `work` null\|`T[0-9]{3}`\|`spec [A-Z]` | `intake.py` |
| object | ref | `F[0-9]{3,}` · `K[0-9]+` · `T[0-9]{3}\.R[0-9]+(\.[0-9]+)?` · `[A-Z]\.close(\.[0-9]+)?` · `lead\.[0-9]{4}-[0-9]{2}-[0-9]{2}(\.[0-9]+)?` | `intake.py` |
| object | evidence | sıra: `gate_open`, `misleading_doc`, `blocks_flow`, `against_principle` (bool) · `reproduced` `main@[0-9a-f]{7,40}`\|`no`\|`not-tried` · `covered_by` null\|`K[0-9]+`\|`T[0-9]{3}`\|`#[0-9]+` | `intake.table` |
| object | consent | null\|`{"decision": <karar>, "table": <karar>, "events": <int ≥ 1>, "at": "<YYYY-MM-DDTHH:MM:SSZ>"}` | `check` |
| object | decision | null\|`accept`\|`needs-info`\|`duplicate`\|`wontfix`\|`defer` (triage değerleri, `scripts/triage.py:32-33`) | `intake.py`, start |
| function | `intake.table(item) -> str` | REQ-2 tablosu | `check`, testler |
| CLI | `intake.py check [--file P]` | exit 0 · 2 biçim · 8 kural; hata başına bir satır | CI, lead |
| CLI | `intake.py list [--pending] [--file P]` | REQ-4 satırları | lead, intake skill |
| CLI | `intake.py show I<nnn> [--require accepted] [--file P]` | exit 0 · 8 · 2 | start |
| skill | `/delixcrew:intake [add\|decide\|list]`, `/delixcrew:start I<nnn>` | REQ-5 | lead |

Ölçütler (lead doldurur ve kanıtı kendisi üretir; reviewer rolleri kod çalıştıramaz):
- **E1 `gate_open`:** bir delix kısıtı (yazma, push, yayın, sır) güncel main'de açık. Security rolünün her bulgusu bu
  sınıftadır (K418).
- **E2 `misleading_doc`:** README, site ya da skill'de alıntılanabilen bir cümle güncel main'de yanlış.
- **E3 `blocks_flow`:** belgelenmiş adım yazıldığı gibi tamamlanamıyor, kullanıcı elle müdahale etti
  (`skills/close/SKILL.md:22-23`).
- **E4 events:** `len(refs)`; aynı sorunun her olayı bir ref.
- **E5 `covered_by`:** main'de düzeltilmiş (`T<nnn>`), K kararlı Bilinen sınır (`K<n>`) ya da triage'daki issue
  (`#n`).
- **E6 `against_principle`:** `agents/architect.md:55-58` ilkelerinden biri tutmuyor (en basit değişiklik, iki insan
  kapısı, kısıt harness'te, rol dışı yetki yok).
- **`reproduced`:** hata ya da sınır güncel main'de gözlendi (`main@<sha>`), gözlenmedi (`no`), denenmedi
  (`not-tried`).

## 5. Data and migration
Yeni dosya, göç yok; dosya yokken komutlar boş kayıtla çalışır. Tohum REQ-8 (lead commit'i). Geri alma: dosyayı silmek
ve kart PR'larını geri almak; `feedback.py` kuyruğu değişmediği için kaybolan veri yok.

## 6. Security note
- Kartlar: A `scripts/intake.py` + test (yeni dosya, korunan yol değil) Tier 2; B skill metinleri Tier 2; C belge
  Tier 2; D sürüm 🔐 Tier 3 (`.claude-plugin/plugin.json`). Tier 2'de review qa + security koşar.
- Kapılar zayıflamaz: intake kapı 1'in önüne bir süzgeç ekler; `accept` öğe yine spec ya da kart onayından (kapı 1) ve
  PR merge'ünden (kapı 2) geçer; start kullanıcının bu sohbetteki evet'ini ister (REQ-5). Hiçbir rol yeni yetki
  almaz: lead kaydı `STATE.json` gibi yazar; implementer'ın Write/Edit'i `docs/delix/**`'a kapalı
  (`scripts/write_gate.py:109`). Bash ile `docs/delix`'e yazım bash_gate'te denetlenmiyor (önceden var); qa diff'te
  `docs/delix/**` değişikliğini bulgu sayar.
- `consent`'i lead yazar; script sohbet mesajını kanıtlayamaz (triage kaydıyla aynı). Önlem: onay karara, tablo
  sonucuna ve olay sayısına bağlı (REQ-3), kanıt değişince düşer; kapı 1 sert kapı kalır.
- Public repo: `title`/`reason` K417 süzgecinden geçer (yol, e-posta, host, IP, görünmez ve Cc karakter; lead'in
  makinesinde `extra_terms` ve kuyruktaki `origin_terms`). Taslak gövdesi ve issue metni kopyalanmaz. Açık koruma
  düzeltme kartı açılmadan kayda girmez (K418).
- `intake.py`: REQ-1 sertleştirmesi; `eval`, alt süreç, ağ, yazma yok. §4 desenlerinde iç içe ya da çakışan quantifier
  yok (ReDoS yok). Bozuk ya da kuralı çiğneyen canlı kayıt CI'yı ve kart oturumlarının Stop kapısını kırmızı yapar
  (K410 bedeli); bekleyen öğe null kararla tutulduğu için normal akış exit 0 kalır.

## 7. Acceptance criteria (DoD)
- [ ] `bash tests/intake_tests.sh` geçer; tüm suite Python 3.9.6 ve 3.13'te geçer
- [ ] `claude plugin validate .` geçer (yeni skill); `bash tests/site_tests.sh` geçer (C, D)
- [ ] Tohumdan sonra main'de `python3 scripts/intake.py check` exit 0; `list --pending` yalnız bekleyenleri basar
- [ ] Birleşmiş main'de lead denemesi: kabul edilmemiş öğeyle `/delixcrew:start I<nnn>` durur, dosya yazmaz
- [ ] A, B, C: `qa` ACCEPT + `security` CLEAN; D: `qa` + `security` + insan onayı 🔐; PR gövdesinde "How I tested"

## 8. Open questions
- P2 (architect): `/delixcrew:verify` rapor bulguları beşinci giriş noktası olsun mu (`skills/verify/SKILL.md:49`,
  `:75`)? v1'de §2'de; kayıtta ihtiyaç görülürse bir öğe.
- P2 (architect): B kartının skill satırlarına kalıcı grep testi (`tests/ledger_tests.sh:9-34` deseni) mi, yalnız kart
  doğrulaması mı? Dispatch'te karar.

## 9. Decisions
- K400 (kullanıcı, geri alınır): v1 çekirdek: kayıt, salt-okur doğrulayıcı, karar tablosu, dört giriş noktası (feedback,
  review, close, start). §2'deki tetikler, komutlar ve atıflar kayıt ihtiyaç gösterince.
- K401 (kullanıcı, geri alınır): bakımcının adıyla onayı: `accept`, `wontfix`, `gate_open` öğesinin her kararı, tablodan
  sapma. `duplicate`, `defer`, `needs-info`'yu lead tabloya göre yazar (`basis: table`).
- K402 (kullanıcı, geri alınır): tablo `scripts/intake.py`'de kod ve testli; architect dosyası değişmez. E6 gereken
  feature öğesinde lead architect'e sorabilir.
- K403 (lead, geri alınır): kayıt repoda (`docs/delix/intake.json`), çünkü K400'deki CI denetimi bunu ister. Bedel
  public görünürlük: K417 ve K418.
- K404 (lead, geri alınır): lead Write/Edit ile yazar, script salt-okur (STATE.json deseni). Yazan bir script de sohbet
  onayını kanıtlayamaz, yalnız kod ekler.
- K405 (lead, geri alınır): onay biçimi triage'la aynı (`skills/triage/SKILL.md:55-61`): `<decision> I<n>`. Bir mesajda
  birden çok öğe olabilir, her biri kendi kararı ve id'siyle; "accept all", id'siz "evet" onay değil.
- K406 (lead, geri alınır): `events = len(refs)`. Yeni olay var olan öğeye ref olur; tabloyu ya da onayı bozarsa lead
  kararı null yapar ve öğe `--pending`'e düşer. Ertelenen öğenin geri dönüşü budur (tetiklerin yerine). Main'deki
  kayıt her zaman exit 0 (architect P1, security Medium).
- K407 (lead, geri alınır): `feedback.py` değişmez; kayda alınan taslak için kullanıcıya `drop F<nnn>` önerilir.
- K408 (lead, geri alınır): `F` ref'i yalnız delixcrew deposunda (REQ-5'teki `plugin.json` ölçütü); başka projede
  taslaklar `send` ve triage yolundan gelir.
- K409 (lead, geri alınır): kullanıcının sohbette doğrudan isteği intake öğesi değildir; zaten bakımcının kararıdır.
- K410 (lead, geri alınır): canlı kayıt CI'da denetlenir (REQ-6). Bedel: bozuk kayıt kart oturumlarının Stop kapısını
  kırmızı yapar (§6); K406 normal akışı exit 0'da tutar.
- K411 (lead, geri alınır): eşikler (2 ve 3) architect önerisinden; tohum turunda tablo/bakımcı uyuşması sayılır,
  kapanışta raporlanır.
- K412 (lead, geri alınır): ad `intake`; start'taki "issue intake" ifadesi ve triage değişmez.
- K413 (lead, geri alınır): dalga planı W1 A + B (ayrık dosyalar), W2 C + tohum (lead), W3 D 🔐. Sürüm numarası
  dispatch'te, paralel lead'in sürüm kartından sonraki minor.
- K414 (lead, geri alınır): onay `{"decision", "table", "events", "at"}`; kayıttaki karar, tablo sonucu ya da olay
  sayısı değişince düşer (architect P1, security Medium). Triage'ın `issue_sha` bağının karşılığı.
- K415 (lead, geri alınır): kapsam dosyaya bağlı: giriş noktaları yalnız `docs/delix/intake.json` olan projede
  çalışır; v1'de yalnız delixcrew deposu tohumlanır, öteki projelerde davranış değişmez (architect P1, security
  Medium). Depo adı kontrolü (`gh`) gerekmez; klondaki kayıt start'ta `UNTRUSTED` gösterilir ve kullanıcının evet'i
  istenir.
- K416 (lead, geri alınır): `#n` yalnız `covered_by`'da; issue'lar triage'dan iş olur, iki kayıt çelişmez. Aynı çıkan
  iki öğe birleşir (ref taşınır), `covered_by` öğe göstermez; zincir kontrolü gerekmez.
- K417 (lead, geri alınır): `title`/`reason` süzgeci izin listesi, yeni kod değil:
  `unicodedata.normalize("NFKC", t) == t`, `feedback.sanitize(t, term_re) == t`, `not feedback.invisible(t)`, Cc
  karakter yok. `term_re` yalnız feedback kuyruğu olan makinede ve `scripts/feedback.py:521-523`'teki kümeyle kurulur:
  `extra_terms`, `local_terms()`, kuyruktaki `origin_terms`. CI'da kuyruk yok, yalnız genel kurallar geçerli (orada
  kullanıcı adı ve host yanlış pozitif verir). `~/` genel yol sayılır; `~<ad>/` kullanıcı adı olarak yerelde
  yakalanır. Lead denemesi: beş örnek F-başlığı değişmeden geçti; yol, e-posta ve host temizlendi (security Medium ve
  Low, architect P2).
- K418 (lead, geri alınır): açık koruma ve security rolünün her bulgusu `gate_open`'dır; düzeltilene kadar depo dışı
  notta kalır. Kayda ancak `work` (düzeltme kartı) ya da `covered_by` (birleşmiş düzeltme, K kararlı Bilinen sınır,
  issue) doluyken girer; REQ-3(c) bunu zorlar. Düzeltme kartı bakımcının doğrudan isteğinden açılır (K409). İki
  inceleyici ayrıştı: architect yalnız gerçek açık kapıyı depo dışında tutmayı önerdi, security her güvenlik
  bulgusunu. Seçilen security'ninki: `SECURITY.md` özel bildirimi istiyor, yük spec başına birkaç bulgu. Architect'in
  kilitlenme bulgusu `covered_by` ile çözüldü. `STATUS.md:753`'teki önceden var olan dosya:satır anması paralel lead'in
  işi, burada değişmez.
- K419 (lead, geri alınır): review giriş noktası şiddetten bağımsız: kartın düzeltmediği her bulgu (architect P1).
- K420 (lead, geri alınır): JSON sertleştirmesi REQ-1'de: 1 MiB, yinelenen anahtar, derinlik, kesin bool, ASCII
  fullmatch (security Low).
- K421 (lead, geri alınır): çıktı biçimi REQ-4'te sabit (architect P1).
- K422 (lead, geri alınır): Spec F'nin K numaraları K400'den; K376–K399 paralel lead'e bırakıldı (security Low).
