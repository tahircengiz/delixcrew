# SPEC — Feedback süzgeci: kalan açıklar ve dokümanın koda eşitlenmesi

> Size: **M** · Tier: 3 · Date: 2026-11-04 · Status: **approved (gate 1, 2026-11-04)** (rev 2: architect FIX + security FIX işlendi)
> Source: grill kararları K159, K160, K170 (kullanıcı), K161–K169, K171–K172 (lead, geri alınır). STATUS.md K numaralarının
> devamıdır. Önceki spec (kapalı): [`archive/0.6.x-feedback-cleanup/SPEC.md`](archive/0.6.x-feedback-cleanup/SPEC.md)
> (REQ-1–REQ-8, K134–K158). Kaynak liste: STATUS.md §9 "Açık iş" (kapanış drift kontrolü, 2026-11-04).

## 1. Goal
`feedback.sanitize()`, public issue'lar ve triage yorumları için süzgeçtir. Kapanış drift kontrolü ile spec incelemesi,
main `928d9b9`'da şu açıkları ölçtü:
- host'tan sonra gelen yol ya da port (`key:host/…`, `host:acme/…`, düz metinde `github.com/<başka sahip>/…`);
- `_` ile biten ya da baştaki sıfırlı IP;
- terminale ham basılan ya da gizli veri taşıyabilen görünmez karakterler (U+2028, variation selector, Hangul filler);
- surrogate'te traceback;
- `cmd_add` yinelenen dalında kuyruk dışına yazım.

README'nin Feedback metni de koddan dar. Başarı ölçütü üç koşul: aşağıdaki her girdi burada yazan çıktıyı verir, mevcut
testlerin hiçbir beklentisi gevşemez, iki README koddaki kuralı aynı biçimde anlatır.

## 2. Out of scope
- K151 (birleşik işaretli etiketin host olarak tanınması, `corp.भारत`) ve K153 (`x.internal.1`, `/` olmadan
  `jenkins:8080`, `:` sonrası `a:b:8080/x`): §6'da kalan risk olarak durur.
- Son etiketi dosya uzantısı olan ad (`x.internal.conf`) bugünkü gibi host sayılmaz; bu davranış yalnız README'ye yazılır.
- `write_gate.py`, `bash_gate.py`, site sayfaları (K164), sürüm (K161).
- `triage.py`'nin davranışı. Yalnız `visible`/`invisible` fonksiyonlarını artık `feedback`'ten import eder (K170).

## 3. Requirements (testable)
### Requirement: REQ-1 Host'tan sonraki yol (K159, K169, K171)
The system SHALL URL dışı metinde host'u izleyen yolu da gizlemeli:
- **(a)** `:` ya da `\`'dan hemen sonra başlayan noktalı `host/…` URL adayıdır ve REQ-1 (K134) izin listesinden geçer.
  Noktalı host, son etiketi `_looks_like_host` ölçütünü geçen addır. Bu bağlamda `ad:port/…` URL adayı değildir; `:`
  ile ayrılmış MAC ve IPv6 grupları bugünkü kurallarında kalır. Diğer sol bağlamlar (`\w . @ / -`) bugünkü gibi muaftır.
- **(b)** Düz metinde `<redacted:host>`, `<redacted:ip>`, `<redacted:email>` ya da `<redacted:mac>` yer tutucusunun
  hemen ardından (araya en fazla bir `.` ya da `]` girebilir) `:`, `/`, `\`, `?` ya da `#` ve en az bir karakter geliyorsa, o parça
  `<redacted:path>` olur. Parça boşlukta ya da `` `'"<>()[] `` karakterlerinden birinde biter. Sondaki `.,;:`'den en fazla
  bir karakter korunur (K174).
- **(c)** Düz metinde `github.com/…`, `github.com\…`, `github.com:port/…` ve scp biçimi `github.com:sahip/…` her sol
  bağlamda (`\w` ve `-` hariç) aynı sahip izin listesinden geçer. Yol ayrıca URL kuyruk karakter listesine
  (`URL_TAIL_OK_RE`) uymalıdır. `tahircengiz/delixcrew` ve `anthropics/…` yolları kalır; `.` ya da `..` parçası olan,
  `%` içeren ve başka her yol `github.com<redacted:path>` olur.
#### Scenario: sızan yollar
- WHEN girdi şunlardan biri olur: `key:ci.acme-corp.net/api/x`, `ref:github.com/acme/private`,
  `x\ci.acme-corp.net/api/x`, `user@ci.acme-corp.net/api/x`, `see 10.1.2.3/api/x`, `a/ci.acme-corp.net:8080/api/x`,
  `ci.acme-corp.net:acme/private`, `git@github.com:acme/private`, `vendor/github.com/acme/private-lib/x.go`,
  `~/src/github.com/acme/private`, `(@github.com/acme/private)`
- THEN çıktılar sırasıyla şunlardır: `key:<redacted:url>`, `ref:<redacted:url>`, `x\<redacted:url>`,
  `<redacted:email><redacted:path>`, `see <redacted:ip><redacted:path>`, `a/<redacted:host><redacted:path>`,
  `<redacted:host><redacted:path>`, `<redacted:email><redacted:path>`, `vendor/github.com<redacted:path>`,
  `~/src/github.com<redacted:path>`, `(@github.com<redacted:path>)`
#### Scenario: izinli ve değişmeyenler
- WHEN girdi `see github.com/tahircengiz/delixcrew/issues/1.`, `go github.com/anthropics/x`, `github.com/`,
  `see x.acme-corp.net: ok`, `a/b`, `w/o`, `a:b:8080/x`, `nas:/volume1/x` ya da `de:ad:be:ef:00:11/x` olur, ya da
  `tests/*_tests.sh` dosyalarındaki mevcut girdilerden biri verilir
- THEN ilk üçü, `a/b`, `w/o` ve `a:b:8080/x` değişmez. Diğerleri şöyle olur: `see <redacted:host>: ok`,
  `nas:<redacted:path>`, `<redacted:mac><redacted:path>` (bugün `<redacted:mac>/x` olur ve idempotent değildir). Mevcut
  test beklentilerinin hepsi aynen geçer.

### Requirement: REQ-2 IP kenar biçimleri (K172)
The system SHALL düz metinde IP adresini şu iki biçimde de tanımalı:
- Adresin ardından `_` gelse de tanınmalı. IPv6'da adresin önünde `_` olsa da tanınmalı; IPv4'te bu bugün zaten geçerli
  (K158).
- `IPV4_RE`'ye uyan ve her okteti ≤ 255 olan, ama `ipaddress`'in reddettiği adres de `<redacted:ip>` olmalı (baştaki
  sıfır, fail closed).

Harf, rakam ya da `.` ile bitişik adres bugünkü gibi tanınmaz.
#### Scenario: kenar
- WHEN girdi `10.20.30.40_`, `fd00:1:2::3_`, `_fd00:1:2::3` ya da `host 010.001.002.003` olur
- THEN adres `<redacted:ip>` olur ve `_` korunur. `v1.2.3.4`, `1.2.3.4a` ve `999.1.1.1` değişmez.

### Requirement: REQ-3 Görünmez karakter izin listesi (K160, K170)
The system SHALL `feedback.build()`'de, triage'ın K133 izin listesini ham ve temizlenmiş metne uygulamalı:
- İzin verilen karakterler: yeni satır, L*, N*, P*, S*, Zs; feedback'te bunlara sekme de eklenir.
- İzin verilenlerden çıkarılanlar: Hangul filler, boş Braille ve U+1D159, Hangul jungseong/jongseong aralıkları.
- Emoji seçici (U+FE0E/U+FE0F) yalnız görünür bir So sembolünden sonra gelebilir.
- Listede olmayan karakter `invisible character` BLOCKED nedenini verir.

`visible` ve `invisible` fonksiyonları `triage.py`'den `feedback.py`'ye taşınır. `invisible`'a izinli ek karakter
parametresi eklenir. `triage.py` bu fonksiyonları import eder ve davranışı değişmez. `bad_char` ile
`unicode control character (Cc/Cf/Co)` nedeni değişmez.

Girdide Cs (tek başına surrogate) varsa `build()` gitleaks'i çağırmadan ve hash hesaplamadan yalnız `invisible character`
nedeniyle döner. `validate()` Cs içeren alanı `<alan>: lone surrogate` hatasıyla reddeder: `add` exit 2 döner, kayıt yazmaz.
#### Scenario: görünmez karakterler
- WHEN bir taslağın `title`'ı `"ok"+"︀"*8` ya da `"aㅤb"` olur, ya da `actual`'ında U+2028 ya da U+2029 vardır
- THEN `preview` `VERDICT: BLOCKED: … invisible character` basar ve exit 4 döner; stdout'ta U+2028 ya da U+2029 yoktur
- WHEN `title` `"I ❤️ it"` olur, `actual`'da sekme ve yeni satır vardır
- THEN `invisible character` nedeni çıkmaz
#### Scenario: surrogate
- WHEN kayıt dosyası elle değiştirilip `title`'a `"x\ud800"` yazılır, ya da `add`'a aynı girdi verilir
- THEN `preview` exit 4 döner, `list` exit 0 döner, ikisinin de stderr'inde `Traceback` geçmez; `add` exit 2 döner ve
  kuyrukta yeni kayıt oluşmaz

### Requirement: REQ-4 `cmd_add` yinelenen dalı
The system SHALL `cmd_add`'da yalnız `id`'si `ID_RE.fullmatch` geçen kaydı yinelenen sayıp yeniden yazmalı. Yeni numara
hesabı da `fullmatch` kullanır. `get_record` (CLI'dan gelen id) aynı kuralla sıkılaşır.
#### Scenario: bozuk id
- WHEN `F001.json` kaydının `id`'si elle `"../x"` ya da `"F001\n"` yapılır, ardından aynı parmak izli `add` çalıştırılır
- THEN `add` exit 0 döner ve yeni bir kayıt açar (`F002 new`); kuyruk dizininin dışında ve içinde başka dosya oluşmaz

### Requirement: REQ-5 Doğrusal süre (ReDoS)
The system SHALL yeni ya da değişen her regex için 50 000 karakterlik kötü girdide `sanitize(x, None)`'ı 0,5 sn içinde
bitirmeli; çakışan alternation kullanılmaz.
#### Scenario: zaman
- WHEN şu ≈50 000 karakterlik girdiler verilir: `a //b ` tekrarı; `http://github.com/tahircengiz/delixcrew/` ardından
  `1.` tekrarı (kuyruktaki IPv4 regex'i); `key:a.bc/` tekrarı; `<redacted:host>/` tekrarı; `<redacted:host>:` tekrarı;
  `:` tekrarı; `\` tekrarı; `_a:` tekrarı; `github.com/` tekrarı; `010.` tekrarı
- THEN her biri < 0,5 sn sürer ve test süreyi yazar
- AND `a //b ` girdisinin 400 000 karakterlik süresi, 50 000 karakterlik süresinin 12 katını geçmez; her süre 3 koşunun en
  küçüğüdür. `_url_pass` korunmayan parçaları listede biriktirip sonda birleştirir (K173)

### Requirement: REQ-6 Eksik testler
The system SHALL mevcut davranışı testle sabitlemeli:
- Eski REQ-2: `a//b` → `a/<redacted:path>`, `>/Users/alice/x` → `><redacted:path>`.
- Eski REQ-4: bu spec'in REQ-1 ve REQ-2 girdileri mevcut idempotens kontrolüne (`seen` listesi) eklenir. Residual
  önizleme kontrolü bugünkü REQ-1 dosyalarını içerir; buna eski REQ-2 ve REQ-3 girdi dosyaları ile bu spec'in REQ-1 ve
  REQ-2 girdileri de eklenir. Bu girdilerin hiçbiri "residual match" nedeni vermez.
#### Scenario: sabitleme
- WHEN `bash tests/sanitize_tests.sh` çalışır
- THEN `a//b` ve `>/Users/alice/x` için birer `✔` satırı basılır; idempotens ve residual kontrolleri genişlemiş kümeyle geçer

### Requirement: REQ-7 Doküman (K167)
The system SHALL README.md Feedback → "What is redacted" ve "What blocks a draft" bölümlerinde, README.tr.md'de de
karşılıklarında, aşağıdaki kuralları aynı commit'te ve aynı içerikle anlatmalı:
- izinli URL yalnız şemasız, `http` ya da `https` olur;
- kuyruktaki noktalı parçada ilk etiketten sonrası dosya uzantısı ya da rakamdır;
- `.` ve `..` yol parçası URL'yi düşürür;
- terim kontrolü URL'nin tamamında yapılır;
- IP yalnız kanonik noktalı biçimiyle izinlidir (`http://127.1/` silinir);
- son etiketi dosya uzantısı olan ad host sayılmaz;
- MAC adresi silinir;
- REQ-1'in host'tan sonraki yol kuralı, düz metindeki `github.com/…` dahil;
- REQ-3'ün `invisible character` nedeni.

CHANGELOG `## Unreleased` altındaki mevcut Feedback maddesine bu spec'in davranış değişiklikleri eklenir; yeni madde açılmaz.
#### Scenario: ikiz
- WHEN iki README'nin Feedback bölümü karşılaştırılır
- THEN ikisinde de `https`, `127.1`, MAC, `github.com<redacted:path>` ve `invisible character` geçer; `bash tests/site_tests.sh`
  geçer

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| function | `feedback.sanitize(text, term_re) -> str` | imza aynı; REQ-1, REQ-2 davranışı | `feedback.build`, `triage.py` |
| function | `feedback.visible(c)`, `feedback.invisible(text, extra="")` | `triage.py`'den taşındı; `extra` izinli ek karakterler | `feedback.build`, `triage.py` |
| function | `feedback.validate(d)` | + `<alan>: lone surrogate` (exit 2) | `cmd_add` |
| BLOCKED nedeni | `invisible character` | yeni (feedback); `unicode control character (Cc/Cf/Co)` aynen | `preview`, `send`, README |
| constant | `feedback.SANITIZER_VERSION` | `"3"`, değişmez (K161) | hash |

## 5. Data and migration
Kuyruk ve kayıt biçimi değişmez, göç yok. Sürüm `"3"` kalır: hash içeriğe bağlı olduğu için, çıktısı değişen taslağın eski
önizleme hash'i zaten uyuşmaz (exit 5).

## 6. Security note
- 🔐 `feedback.py` korumalı listede değil, ama dışarıya (public issue) giden metnin süzgeci; bu yüzden Tier 3 sayılır. T020
  Approved satırı ister. T021 yalnız doküman, Tier 1.
- Tehdit: iç host'un yolu ya da portu, private GitHub repo yolu ya da iç IP public issue'ya gider; elle düzenlenmiş ya da
  prompt injection altında yazılmış bir taslak görünmez karakterle veri kaçırır veya terminalde görüneni değiştirir.
  Tasarım fail closed: şüpheli `host/…` URL izin listesinden geçer, izin listesi dışındaki karakter BLOCKED olur.
- Kalan risk, bu spec dışında (önceki §6'dan devreden):
  - K151: birleşik işaretli etiketin host olarak tanınmaması. Feedback'te bu karakterler artık BLOCKED.
  - K153: `x.internal.1`, `/` olmadan `ad:port`, `:` sonrası `a:b:8080/x`.
  - Dosya uzantılı son etiket (`x.internal.conf`).
  - NFKC'den sağ çıkan ayraç benzerleri.
  - Bash ile kuyruğa yazım.
- Kalan risk, yeni:
  - `localhost[:port]/…` yolu yalnız terim kontrolünden geçer (K134 gereği izinli).
  - Girdideki düz `<redacted:x>` metni bir IP'yi ya da host'u parçalara bölebilir (`10.1<redacted:x>.2.3`).
  - REQ-1b parçası `<`'de biter (`…/api<b>internal/secret`).
  - `ID_RE` Unicode rakamı kabul eder (`F٠٠١`); kuyruk içinde kalır, zararsız.
- Aşırı silme (fail closed):
  - Var olanlar: `std::vector.size/x`, `Link:https://…`.
  - Yeni: `1.2.3.4_beta` → `<redacted:ip>_beta`; ağ önekleri (`10.1.2.0/24`, `fd00::/64` → `<redacted:ip><redacted:path>`);
    port tek başına (`<redacted:ip>:8080` → `<redacted:ip><redacted:path>`); feedback taslağında Devanagari gibi birleşik
    işaretli metin (BLOCKED).
- Mevcut test dosyalarında hiçbir beklenti gevşetilmez. Değişen test dosyası yalnız `tests/sanitize_tests.sh`;
  `tests/triage_tests.sh` aynen geçer.

## 7. Acceptance criteria (DoD)
- [ ] Her REQ için geçen test. Doğrulama komutu: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → hepsi geçer.
- [ ] REQ-5 süreleri PR gövdesinde.
- [ ] `qa` ACCEPT; `security` CLEAN ve insan onayı (🔐). İnceleyici her güvenlik bulgusunu hem dal ağacında hem main'de
  yeniden üretir.
- [ ] PR gövdesinde "How I tested" bölümü var; push öncesi iç adres taraması 0.

## 8. Open questions
- (yok)

## 9. Decisions
- **K159** (kullanıcı, 2026-11-04; geri alınır) Host'tan sonraki yol yapısal bir kuralla kapanır (REQ-1). Reddedilen
  seçenek: yalnız `:` sonrasını düzeltmek. Ölçüm main `928d9b9`'da: 5 vakanın 5'i sızdı. Security incelemesi aynı
  sınıftan 8 vaka daha buldu (K171).
- **K160** (kullanıcı, 2026-11-04; geri alınır) U+2028, U+2029 ve surrogate BLOCKED olur. Reddedilen seçenekler: bu
  karakterleri `\n`'e çevirmek (içerik sessizce değişir) ve yalnız ekranda kaçışlamak (gösterilen ile gönderilen
  ayrılır). Uygulama yolu K170 ile izin listesine döndü.
- **K161** (geri alınır) `SANITIZER_VERSION` `"3"` kalır. Gerekçe: `3` henüz yayınlanmadı (CHANGELOG `## Unreleased`),
  hash zaten içeriğe bağlı.
- **K162** (geri alınır) `cmd_add` için `ID_RE.fullmatch` yeterli; `id` ile dosya adının eşitliği aranmaz. Ölçüm (main
  kodu, karalama kuyruğu): `id`'si `../x` olan kayıtla aynı parmak izli `add`, kuyruk dizininin bir üstüne `x.json` yazıyor.
- **K163** (geri alındı, yerine K173) `_url_pass` birleştirmesine dokunulmaz. STATUS §9 O(n²) diyordu, ama main ölçümü doğrusal:
  `a //b ` tekrarı 50K karakterde 0,106 sn, 100K'da 0,232 sn, 200K'da 0,551 sn. Hatayı yeniden üreten test yok; koruma
  olarak REQ-5'teki büyüme testi kalır.
- **K164** (geri alınır) Site sayfaları değişmez. "Invisible Unicode control character" ifadesi doğru kalıyor (K141 ile
  aynı gerekçe).
- **K165** (geri alınır) Kart taslağı:
  - T020 backend 🔐: `scripts/feedback.py`, `scripts/triage.py` (yalnız taşıma ve import), `tests/sanitize_tests.sh`;
    REQ-1–REQ-6.
  - T021 docs: `README.md`, `README.tr.md`, `CHANGELOG.md`; REQ-7; T020 merge'ünden sonra.
- **K166** (geri alınır) Önceki spec ve T016–T019 `archive/0.6.x-feedback-cleanup/`'a taşındı (`a9ba5d5`); STATE
  boşaltıldı, `verifications` kaydı yerinde.
- **K167** (geri alınır) README, kodun bugünkü kuralını madde madde anlatır; örnekler bu spec'ten alınır ve `10.1.2.3`,
  `acme-corp` kullanır.
- **K168** (geri alınır) REQ-1b yalnız yer tutucudan hemen sonra uygulanır. Gerekçe: `ABS_PATH_RE` host, IP ve e-posta
  adımlarından önce çalışıyor; adım sırasını değiştirmek mevcut bütün beklentileri riske atar.
- **K169** (geri alınır; architect P1 ×2, security Medium) REQ-1a yalnız noktalı host'a uygulanır. `ad:port/` dahil
  olsaydı `de:ad:be:ef:00:11/x` ve `fd12:3456:789a:1:2:3:4:5/64` kısmen açığa çıkardı (prototipte ölçüldü). `bad_char`
  değişmez; değişseydi `triage.py` `Cleaner` U+2028'i sessizce silerdi ve `issue_sha` değişirdi.
- **K170** (kullanıcı, 2026-11-04; geri alınır) Görünmez karakterlerde triage'ın K133 izin listesi feedback'e de uygulanır;
  fonksiyon tek yerde (`feedback.py`) durur. Main ölçümü: `"ok"+"︀"*8` başlıklı taslak temiz geçiyor. Bedeli:
  birleşik işaretli metin BLOCKED olur. Reddedilen seçenekler: engelleme listesini genişletmek, §6'ya kalan risk yazmak.
- **K171** (geri alınır; security Medium ×2) REQ-1b'nin sağ tarafı `:` ya da `/` ile başlar; REQ-1c düz metindeki
  `github.com/…` yolunu sahip izin listesinden geçirir. Main ölçümü: `git@github.com:acme/private`,
  `ci.acme-corp.net:acme/private`, `a/10.1.2.3:8080/api/x`, `vendor/github.com/acme/private-lib/x.go` hiç değişmeden ya da
  yolu açık kalarak çıkıyor. Bu, K159'un yapısal kuralının devamıdır.
- **K173** (geri alınır; T020 tur 1, deterministik kapı) K163 yanlıştı. CI'da büyüme testi kırmızı: 50K'dan 200K'ya
  oran 7,79 (sınır 6). Lead ölçümü (main `7d2889a`, `a //b ` tekrarı): 200K 0,533 sn, 800K 5,514 sn, yani kuadratik.
  Liste birleştirmeli prototipte aynı ölçüm 0,278 sn ve 1,104 sn, yani doğrusal. `_url_pass` korunmayan parçaları
  listede biriktirip sonda birleştirir, çıktı aynı kalır. Büyüme testi 50K'dan 400K'ya ölçer, sınır ×12; ölçülen oran
  kuadratik kodda 17,1, doğrusal kodda 8,0. 200K kısa bir girdiydi, iki durumu ayırmaya yetmedi.
- **K174** (geri alınır; T020 tur 2, security 1 Medium + 3 Low). Lead her bulguyu PR dalında ve main'de üretti.
  REQ-1c'ye `:port` ve scp biçimi, ayrıca `.` ve `..` parçası eklendi. REQ-1b'ye host'un sonundaki nokta ve `\ ? #`
  ayraçları eklendi. Sondaki `.,;:`'den en fazla bir karakter korunur; `::` korunsaydı ikinci geçişte IPv6 sayılır ve
  idempotens bozulurdu.
- **K175** (kullanıcı, 2026-11-04; geri alınır) T020 tur 3, son tur. Lead 4 Low'un hepsini dalda ve main'de üretti.
  Kullanıcı hepsinin düzeltilmesini seçti. Düzeltilenler: testlerdeki ham görünmez karakterler (bu PR'la gelmişti),
  `[IPv6]` sonrası yol, `\` ayraçlı github.com yolu ve `%` kodlu github.com yolu. `x\jenkins:8080/…` K153 sınıfındadır,
  §6'da kalır.
- **K172** (geri alınır; security Low) Baştaki sıfırlı IPv4 fail closed: oktetler ≤ 255 ise `ipaddress` hatası silmeye yol
  açar. Main ölçümü: `010.001.002.003` değişmeden kalıyor.
