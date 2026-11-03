# SPEC — Feedback temizliği: URL izin listesi, yol bağlamları, kuyruk kapısında harf büyüklüğü

> Size: **M** · Tier: 3 · Date: 2026-11-03 · Status: **approved (gate 1, 2026-11-03)** (architect FIX + security FIX işlendi)
> Source: grill kararı K134 (kullanıcı), K135–K148 (lead, geri alınır). STATUS.md K numaralarının devamıdır.
> Önceki spec'ler (kapalı): [`archive/0.6.0-triage/SPEC.md`](archive/0.6.0-triage/SPEC.md),
> [`archive/0.5.0-self-feeding/SPEC.md`](archive/0.5.0-self-feeding/SPEC.md) (REQ-3, REQ-12, K94, K101, K104).

## 1. Goal
`feedback.py preview/send` public bir issue'ya giden metni temizler; `triage.py` aynı `sanitize()`'ı yorumlar için
kullanır (K115). main `79ef030`'da ölçüldü: yönlendirme sonrası yol (`>/srv/acme/out.log`, `2>/var/lib/acme/x`), JSON
kaçışlı yol (`\/srv\/acme`), tek etiketli ya da şemalı host'lu URL (`smb://nas/volume1/acme`, `http://jenkins:8080/job/x`,
`//fileserver/share`, `file:///etc/passwd`, `redis://cache:6379`, `postgres://user@db/x`, `http://intranet/`), sayısal
host biçimleri (`http://167838211/x`, `http://0x0A010203/`, `http://012.01.02.03/`, `http://10.1.3/`) ve Unicode
host (`https://bücher.example-corp.de/a`) **değişmeden** geçiyor; izinsiz FQDN'li URL'de host silinip yol kalıyor.
Ayrıca yazma kapısı feedback kuyruğunu harf büyüklüğüne duyarlı karşılaştırıyor (K129) ve `add`/`list` diskten okunan
değeri ham basıyor.
Başarı: yukarıdaki her girdi temizlenir; URL'de **yalnız izinli host/yol kalır** (izin listesi, fail closed; T010'daki
yasak listesi 6 tur sürdü); mevcut testler sürüm satırı dışında değişmeden geçer.

## 2. Out of scope
- URL dışındaki çıplak sayılar (`167838211`, `0x0A010203` düz metinde): IP olarak yorumlanmaz (K136).
- Göreli yollar (`skills/x/y`, `./scripts/x`, `../x`): proje adları `origin_terms`/`--terms` ile silinir, yol kuralı değil.
- #12 kuyruk silme yolu (`feedback.py purge`): `triage.py show 12 --require accepted` exit 8 (K143).
- Sürüm artırma, etiket, release; site sayfaları (K140, K141). Hook kuralı (c) heredoc aşırı engellemesi (spec B).
- `triage.py` kodu: davranışı import ettiği `sanitize()` ile değişir, dosyası değişmez (K142).
- README/README.tr.md'nin Feedback bölümü dışı (#10 işi).

## 3. Requirements (testable)

### Requirement: REQ-1 URL izin listesi (K134)
The system SHALL `sanitize()`'ın ilk adımı olarak (NFKC → URL → ev dizini → yol → … → terim) her URL'yi ayrıştırıp yalnız
izinli olanı değiştirmeden bırakmalı.
- **URL biçimleri:** `<şema>://…` (`[A-Za-z][A-Za-z0-9+.-]*`); şemasız `//…`; REQ-3'ün host saydığı bir adla başlayan
  `host/…`; `<ad>:<1–5 rakam>/…` (`jenkins:8080/job/x`). `://` ya da `//`'dan hemen sonra boşluk, satır sonu, metin sonu,
  bitiş karakteri ya da `<redacted:` geliyorsa URL yoktur ve metin değişmez. Bitiş: boşluk ya da `` ` ' " < > ( ) [ ] ``
  (IPv6 köşeli parantezi host'un parçası); sondaki `.,;:)` URL'ye dahil değildir ve çıktıda kalır.
- **Authority:** `//`'dan (ya da şemasız biçimin başından) sonraki ilk `/`, `\`, `?` ya da `#`'e kadardır. Port atılır,
  küçük harfe çevrilir. Authority'de `@` varsa URL izinsizdir (userinfo hiçbir host'ta kalmaz). Host yalnız
  `[a-z0-9.-]+` ya da zone id'siz köşeli IPv6 olabilir; boş host, başka karakter (Unicode dahil) ya da ayrıştırma hatası
  URL'yi izinsiz yapar (fail closed).
- **İzinli host:** `code.claude.com`, `docs.anthropic.com`, `anthropic.com`, `localhost` (tam), `example`, `*.example`,
  `example.com`/`.net`/`.org` ve alt alanları (K147); `github.com` yalnız yol boşsa, ilk iki parça `tahircengiz/delixcrew`
  ya da ilk parça `anthropics` ise (harf büyüklüğüne duyarsız, tam parça); kanonik noktalı IPv4 ya da köşeli IPv6 ve
  loopback/RFC 5737/`2001:db8::/32` (K136).
- **İzinli kuyruk (K146):** authority'den sonraki kısım (yol + sorgu + parça) yalnız şu karakterlerden oluşur: yol
  `[A-Za-z0-9._~/-]`, `?` ve `#` sonrası `[A-Za-z0-9._~=&+-]`; `.` ya da `..` yol parçası yoktur; içinde REQ-3 host, IP ya
  da terim (`--terms`, `origin_terms`, kullanıcı ve makine adı) eşleşmesi yoktur. Aksi halde URL izinsizdir.
İzinli URL olduğu gibi kalır ve sonraki adımlar ona dokunmaz. İzinsiz URL'de `://`'dan sonrası `<redacted:url>` olur
(şema ve `://` kalır); şemasız biçim (`//x`, `host/x`, `ad:port/x`) tümüyle `<redacted:url>` olur.
#### Scenario: izinsiz URL'ler
- WHEN metinde (her biri ayrı satırda) `smb://nas/volume1/acme`, `http://jenkins:8080/job/x`, `//fileserver/share`,
  `file:///etc/passwd`, `redis://cache:6379`, `postgres://user@db/x`, `http://intranet/`,
  `https://build.example-corp.dev/acme/x`, `build.example-corp.dev/job/x`, `https://github.com/acme-corp/private/issues/1`,
  `https://bücher.example-corp.de/a`, `(http://intranet/x).`, `jenkins:8080/job/acme-build` vardır
- THEN satırlar birebir: `smb://<redacted:url>`, `http://<redacted:url>`, `<redacted:url>`, `file://<redacted:url>`,
  `redis://<redacted:url>`, `postgres://<redacted:url>`, `http://<redacted:url>`, `https://<redacted:url>`,
  `<redacted:url>`, `https://<redacted:url>`, `https://<redacted:url>`, `(http://<redacted:url>).`, `<redacted:url>`
#### Scenario: authority hileleri
- WHEN `https://deploy:Hunter2pass@github.com/tahircengiz/delixcrew.git`,
  `https://jenkins.acme-corp.internal\@github.com/tahircengiz/delixcrew`, `https://intranet.acme#@github.com/`,
  `https://intranet.acme?@github.com/`, `https://acme-crm.test/admin`, `http://billing.acme.localhost/api` vardır
- THEN hiçbirinde `Hunter2pass`, `deploy`, `jenkins`, `intranet`, `acme` geçmez; her biri `https://<redacted:url>` ya da
  `http://<redacted:url>` ile başlar
#### Scenario: sayısal host
- WHEN `http://167838211/x`, `http://0x0A010203/`, `http://012.01.02.03/`, `http://10.1.3/`, `http://10.1.2.3/x` vardır
- THEN her biri birebir `http://<redacted:url>` olur
#### Scenario: izinli host'ta iç bilgi
- WHEN `--terms acme` ile `https://docs.example.com/p?u=bob@example-corp.dev`,
  `https://github.com/tahircengiz/delixcrew/issues?q=acme`,
  `http://localhost:8080/cb?redirect_uri=https%3A%2F%2Fsso.corp.internal%2Fauth`,
  `https://github.com/tahircengiz/delixcrew/../../acme-corp/private-repo`,
  `https://github.com/anthropics/claude-code/issues?q=jenkins.corp.internal`, `https://code.claude.com/docs?from=/srv/x`,
  `http://localhost:3000/x?db=postgres://u@db.corp.internal/prod` vardır
- THEN her biri birebir `https://<redacted:url>` ya da `http://<redacted:url>` olur (sondaki metin kalmaz)
#### Scenario: izinli URL'ler ve URL olmayanlar değişmez
- WHEN `https://github.com/tahircengiz/delixcrew/issues/3`, `https://GitHub.com/TahirCengiz/DelixCrew`,
  `https://github.com/anthropics/claude-code/issues/1`, `https://code.claude.com/docs/en/hooks#pretooluse-input`,
  `https://github.com/tahircengiz/delixcrew/blob/main/scripts/feedback.py#L60`, `http://localhost:8080/a`,
  `localhost:8080/a`, `http://127.0.0.1:3000/`, `http://[2001:db8::1]/x`, `https://docs.example.com/p`,
  `github.com/tahircengiz/delixcrew`, `(https://github.com/tahircengiz/delixcrew).`, `smb://<redacted:url>`, `http://`,
  `// TODO`, `scripts/feedback.py:342` vardır
- THEN hiçbiri değişmez

### Requirement: REQ-2 Yol bağlamları (K104, K135)
The system SHALL mutlak yolu, `/`'dan önceki karakter ne olursa olsun `<redacted:path>` yapmalı; yalnız şu durumlarda yol
sayılmaz: `/`'dan önce harf/rakam/`_` (`a/b`, `w/o`), `~` (`~/x`), göreli önek (`./` ya da `../`, önündeki karakter `\w`
ya da `.` değilse; satır başı dahil), REQ-1'in ele aldığı URL. `/`'dan önce `/` (`a//b`) muaf değildir. JSON kaçışlı
ayraç (`\/`) ve Windows UNC (`\\server\share`) de yoldur. Ev dizini kuralı (`HOME_RE`) bugünkü sol bağlamıyla kalır:
`>/Users/alice/x` gibi bağlamda ev yolu `~/x` değil `<redacted:path>` olur (fail closed). REQ-12 (0.5.0) tek parça izin
listesi (`/delixcrew:<skill>`, yerleşik komutlar) aynen kalır.
#### Scenario: yönlendirme ve kaçış
- WHEN metinde `cmd >/srv/acme/out.log`, `x 2>/var/lib/acme/x`, `{"p":"\/srv\/acme"}`, `run --/srv/acme`,
  `foo./srv/acme`, `a|/opt/acme`, `\\fileserver\share\acme` vardır
- THEN `acme`, `srv`, `var/lib`, `opt`, `fileserver` çıktıda geçmez; `cmd >`, `x 2>`, `{"p":"` kalır
#### Scenario: göreli ve eğik çizgili metin değişmez
- WHEN `skills/feedback/SKILL.md`, `./scripts/feedback.py`, `` `./scripts/feedback.py` ``, `"../skills/x"`, `(./x)`,
  `../skills/x`, `~/x`, `a/b`, `w/o`, `bug / feature`, `/delixcrew:spec`, `/compact` vardır
- THEN hiçbiri değişmez

### Requirement: REQ-3 Unicode host (K137)
The system SHALL URL dışındaki noktalı host adını Unicode harfleriyle de tanımalı (NFKC sonrası) ve ASCII olmayan host'u
izinli saymamalı; son etiketi bilinen dosya uzantısı olan ad bugünkü gibi host değildir.
#### Scenario: IDN
- WHEN metinde `bücher.example-corp.de`, `xn--bcher-kva.example-corp.de` ve `notlar.md` vardır
- THEN ilk ikisi `<redacted:host>`, `notlar.md` değişmez

### Requirement: REQ-4 Kararlılık ve sürüm (K138)
The system SHALL REQ-1–REQ-3 senaryo girdileri için `sanitize(sanitize(x)) == sanitize(x)` sağlamalı ve `SANITIZER_VERSION`'ı
`"3"` yapmalı. Residual kontrolü ("residual match after sanitizing") ve mevcut BLOCKED beklentileri (ör. `see x.ioacme.md`,
terim `acme`) aynen kalır; `sanitize()` içinde fixpoint döngüsü yoktur.
#### Scenario: idempotent
- WHEN REQ-1–REQ-3 senaryolarındaki her girdi iki kez temizlenir
- THEN iki çıktı aynıdır; bu girdilerden kurulan taslağın `preview`'u "residual match" nedeni vermez (gitleaks gibi
  başka BLOCKED nedenleri bu senaryonun konusu değil)

### Requirement: REQ-5 ReDoS sınırı
The system SHALL yeni ya da değişen her regex için 50 000 karakterlik kötü girdide (`/` tekrarı, `a/` tekrarı, `\/`
tekrarı, `http://` tekrarı, `\\` tekrarı, `.` tekrarı, `x://` + 50 000 `a`) `sanitize()`'ı 0,5 sn içinde bitirmeli;
çakışan alternation kullanılmaz (aynı girdiyi iki dalın tüketebildiği `(a|a.)*` biçimi yok).
#### Scenario: zaman
- WHEN her kötü girdi `sanitize(x, None)`'a verilir
- THEN her biri < 0,5 sn (test ölçer ve süreyi yazar)

### Requirement: REQ-6 Kuyruk yazma kapısı harf büyüklüğü (K129)
The system SHALL `write_gate.py`'de feedback kuyruğu ve triage dizini karşılaştırmalarını iki tarafta da
`unicodedata.normalize("NFD", realpath(p)).casefold()` ile yapmalı (APFS harf büyüklüğüne ve Unicode normalizasyonuna
duyarsız); deny mesajları aynı kalır.
#### Scenario: büyük harfli yol
- WHEN `DELIXCREW_FEEDBACK_DIR` tanımsızken bir oturum `~/.claude/delixcrew/FEEDBACK/F001.json` ya da
  `~/.Claude/DelixCrew/feedback/config.json`'a Write/Edit dener
- THEN hook deny eder: `delixcrew: feedback is sent only by the user from their own terminal`
#### Scenario: normalizasyon
- WHEN `DELIXCREW_FEEDBACK_DIR` NFC `…/Masaüstü/fb`, hedef NFD `…/Masau\u0308stu\u0308/fb/F001.json`; aynısı
  `DELIXCREW_TRIAGE_DIR` için
- THEN ikisi de deny
#### Scenario: komşu yol serbest
- WHEN hedef `~/.claude/delixcrew/feedback-notes.md`
- THEN bu kural deny etmez

### Requirement: REQ-7 Terminal çıktısında kaçış (K139)
The system SHALL `cmd_add`'ın tekrar satırında ve `cmd_list`'te diskten okunan her değeri basmadan önce
`str.isprintable()` yanlış olan her karakteri (yeni satır, sekme, U+2028, tek başına surrogate dahil) görünür kaçışa
çevirmeli: U+00FF'e kadar `\xnn`, U+FFFF'e kadar `\unnnn`, üstü `\Unnnnnnnn`, küçük harf hex; ters eğik çizgi
kaçışlanmaz. Kayıt dosyası değişmez.
#### Scenario: OSC 8, ANSI, satır ayırıcı, surrogate
- WHEN bir kaydın `title`'ı elle `"\u001b]8;;http://x\u0007click\u001b]8;;\u0007"`, `status`'u `"draft\u001b[2J"`,
  `component`'i `"a\u2028b"`, başka bir kaydın `title`'ı `"x\ud800"` yapılır
- THEN `list` ve aynı parmak izli `add` exit 0 verir; stdout'ta 0x1B, 0x07, U+2028 yoktur; `\x1b]8;;`, `\u2028`,
  `\ud800` metni görünür

### Requirement: REQ-8 Doküman
The system SHALL README.md Feedback → "What is redacted" ve "Data & privacy", README.tr.md Feedback → karşılıkları
("Veri ve gizlilik" dahil) maddelerinde URL kuralını (izinsiz URL `<redacted:url>`, github.com'da yalnız delixcrew ve
anthropics yolu, userinfo hiçbir zaman kalmaz) ve daralan izinli ad listesini (`*.test`, `*.invalid`, `*.localhost` yok)
aynı commit'te anlatmalı; CHANGELOG'a `## Unreleased` altında tek madde eklenmeli.
#### Scenario: ikiz
- WHEN iki README'nin Feedback bölümü karşılaştırılır
- THEN ikisi de `<redacted:url>`, `tahircengiz/delixcrew`, `anthropics` geçirir; `bash tests/site_tests.sh` geçer

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| function | `feedback.sanitize(text: str, term_re) -> str` | imza aynı; REQ-1–4 davranışı | `feedback.build`, `triage.py` |
| constant | `feedback.SANITIZER_VERSION` | `"3"` (önceki önizleme hash'leri geçersizleşir) | hash; `tests/*` |
| placeholder | `<redacted:url>` | `PLACEHOLDER_RE` (`<redacted:[a-z]+>`) ile uyumlu, yeni tür | README |
| hook | `write_gate.py` feedback kuyruğu kuralı | casefold; deny metni aynı | tüm oturumlar |
| CLI çıktısı | `feedback.py list`, `add` (tekrar satırı) | sütunlar aynı; kontrol karakteri kaçışlı | kullanıcı |

## 5. Data and migration
Kuyruk/kayıt biçimi değişmez. `SANITIZER_VERSION` 3: önceden alınmış `preview` hash'i `send`'de uyuşmaz (exit 5); kullanıcı
yeniden `preview` alır. Göç yok.

## 6. Security note
- 🔐 `scripts/write_gate.py` korumalı yol (REQ-6). `feedback.py` korumalı listede değil ama dışarı (public issue) yayın
  süzgeci, Tier 3 sayılır: iki backend kartı da 🔐 Approved satırı ister.
- Tehdit: kullanıcının iç adı/yolu/host'u public issue'ya ya da triage yorumuna gider; elle düzenlenmiş kuyruk kaydı
  terminale kaçış dizisi basar (sahte önizleme, OSC 8 link). Tasarım fail closed: tanınmayan host'lu URL tümüyle silinir.
- Kalan risk (bu spec dışı): düz metinde sayısal IP, göreli yol, sürücüsüz `\srv\acme`, düz metinde `%2Fsrv`; NFKC'den
  sağ çıkan ayraç benzerleri (`。` U+3002, `∕` U+2215, `⁄` U+2044; kasıtlı gizleme); Bash ile kuyruk dizinine yazım
  (`bash_gate.py` yalnız `send`'i kapatır; `build()` parmak izi kontrolü ve `send`'in TTY onayı sınırlar, spec B). Temizlik
  desen tabanlı, kullanıcı önizlemeyi okur (README).
- Mevcut test dosyalarında yalnız sürüm (`"2"` → `"3"`) satırları değişir; beklenti gevşetilmez (K138).

## 7. Acceptance criteria (DoD)
- [ ] Her REQ için geçen test; doğrulama: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → hepsi geçer
- [ ] REQ-5 zaman testi süreleri PR gövdesinde
- [ ] `qa` ACCEPT; `security` CLEAN + insan onayı (🔐)
- [ ] PR gövdesinde "How I tested"; push öncesi iç adres taraması 0

## 8. Open questions
- (yok)

## 9. Decisions
- **K134** (kullanıcı, 2026-11-03; tek yön değil) URL kuralı izin listesi: izinsiz host'lu URL'de şemadan sonrası tümüyle
  `<redacted:url>`; github.com'da yalnız `tahircengiz/delixcrew` ve `anthropics/*` yolu kalır. Seçenekler: yalnız host
  izin listesi; bilinen biçimleri yamalamak (T010 dersine ters).
- **K135** (geri alınır) Yol kuralında sol bağlam izin listesi: yalnız `\w`, `~`, göreli önek ve URL muaf; geri kalan her
  karakterden sonra gelen `/` yol başlatır. Bedel: `foo./srv` gibi nadir metin de silinir (fail closed).
- **K136** (geri alınır) Sayısal host yalnız URL içinde ve yalnız kanonik IP literali izinli olabilir; düz metindeki sayılar
  IP sayılmaz (her sayıyı silmek metni bozar).
- **K137** (geri alınır) İzin listesi ASCII; Unicode host hiçbir zaman izinli değil (homograf).
- **K138** (geri alınır) `SANITIZER_VERSION` `"3"`; `tests/feedback_tests.sh` ve `tests/triage_tests.sh`'teki `"2"` satırları
  kartın Files listesinde, yalnız sürüm değişir. Yeni senaryolar yeni test dosyasında (`tests/sanitize_tests.sh`).
- **K139** (geri alınır) Kaçış ölçütü `str.isprintable()`, biçimi `\xnn`/`\unnnn`/`\Unnnnnnnn`; ters eğik çizgi
  kaçışlanmaz (amaç terminal güvenliği, birebir geri okunabilirlik değil). Yalnız terminal çıktısında.
- **K140** (geri alınır) Sürüm artmaz; CHANGELOG `## Unreleased`. Etiket/release kararı kullanıcıda (lead-backlog #9).
- **K141** (geri alınır) Site sayfaları değişmez: "allowlist dışı her host silinir" ifadesi doğru kalır.
- **K142** (geri alınır) `triage.py` değişmez; yorum temizliği aynı fonksiyonla sıkılaşır, `tests/triage_tests.sh` geçer.
- **K143** #12 (`purge`) kapsam dışı: triage kaydı `accepted` değil (exit 8, 2026-11-03).
- **K144** (geri alınır) Kart taslağı: T016 `feedback.py` (REQ-1–5, REQ-7), T017 `write_gate.py` (REQ-6; testi yeni
  `tests/write_gate_case_tests.sh`), paralel; T018 doküman (REQ-8) T016 merge'ünden sonra. Kesin bölme dispatch'te.
- **K146** (geri alınır; architect P1 + security High) İzinli host'un kuyruğu da izin listesinden geçer (karakter kümesi,
  nokta parçası yok, host/IP/terim yok); geçmezse URL tümüyle silinir. Percent-decode yerine `%` reddedilir: daha basit,
  bedeli `?q=is%3Aopen` gibi zararsız linklerin de silinmesi.
- **K147** (geri alınır; security Medium) İzinli ayrılmış adlar daraldı: `*.test`, `*.invalid`, `*.localhost` artık izinli
  değil (proje adı taşıyan geliştirme host'ları); `localhost` tam ad olarak kalır. `is_allowed_host` her yerde (URL, düz
  host, `local_terms`, `origin_terms`) aynı kuralı kullanır. 0.5.0 K97'yi daraltır.
- **K148** (geri alınır) Spec incelemesi: architect FIX (1 P0, 4 P1, 2 P2) ve security FIX (2 High, 2 Medium, 3 Low) işlendi;
  `<ad>:/yol` (K101) ve `http:\\nas` bugünkü yol kuralında kalır, URL biçimine alınmadı (mevcut test birebir bekliyor).
- **K145** (geri alınır) Önceki triage spec'i ve T010–T015 `archive/0.6.0-triage/`'a taşındı (`ff79206`); STATE boş,
  github-pages doğrulama kaydı yerinde.
