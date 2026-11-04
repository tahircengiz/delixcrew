# SPEC — Triage ve feedback akışında üç düzeltme: onay istemi, yerel kayıt mesajı, çapraz heredoc muafiyeti

> Size: **M** · Tier: 3 · Date: 2026-11-04 · Status: **approved (gate 1, 2026-11-04)** (rev 2: architect FIX + security FIX işlendi)
> Source: issue'lar [#34](https://github.com/tahircengiz/delixcrew/issues/34), [#35](https://github.com/tahircengiz/delixcrew/issues/35),
> [#36](https://github.com/tahircengiz/delixcrew/issues/36) (üçü de triage'da `accepted`, 2026-11-04; istek metni kullanıcı onaylı).
> Kararlar K178–K192 (lead, geri alınır). STATUS.md K numaralarının devamıdır. Önceki spec (kapalı):
> [`archive/0.6.2-feedback-filter-gaps/SPEC.md`](archive/0.6.2-feedback-filter-gaps/SPEC.md) (K159–K176).

## 1. Goal
İlk gerçek triage koşusunda (0.6.1) üç sürtünme ölçüldü: yalnız `APPLY` yazınca ret mesajı beklenen metni söylemiyor;
kaydı yapılmış ama uygulanmamış `accept` "triage edilmemiş" diye raporlanıyor; bir capture heredoc'unun gövdesi öbür
script'in kuralına takılıyor (bu oturumda iki kez yeniden üretildi, main `1b3cf9e`). Spec incelemesinde bir açık daha
ölçüldü: `-` ile başlayan yol (`python3 -ic/…/feedback.py add <<'EOF'`) kalıba uyuyor ve Python gövdeyi kod olarak
çalıştırıyor (K187). Başarı: üç durumda kullanıcı ne yapacağını mesajdan öğrenir, muafiyet yalnız gerçekten veri olan
gövdeye uygulanır, mevcut testlerin hiçbir beklentisi gevşemez.

## 2. Out of scope
- Not dosyasına heredoc ile ekleme (`cat >> notes <<'EOF'`) muafiyeti: Write aracı bu işi görür (K183).
- `cd … &&` önekli ya da `; echo …` sonekli capture çağrısı: tam metin denetimi ve fail closed kalır (K183).
- Feedback kuralı (c) ve triage (c)/(d) (`gh` yolları) heredoc aşırı engellemesi (spec B, STATUS §9); `${…}` yollu çağrıya
  muafiyet; triage kuralı (a)'nın argv listesi biçimi ve README.md:312-313 ifadesi (§8).
- Triage skill'ine "var olan kaydı uygula" girişi (K189). Sürüm, etiket, release (K179); site sayfaları (K184). #9, #10, #12, #17.

## 3. Requirements (testable)

### Requirement: REQ-1 Onay istemi beklenen metni söyler (#34, K180)
The system SHALL `triage.py apply` ve `feedback.py send`'in istem ve ret satırlarını şu metinlerle yazmalı (`<h>` gerçek
12 hex hash): istem `Type APPLY <h> to apply it (the word APPLY, a space, then the hash): ` ve
`Type SEND <h> to send it (the word SEND, a space, then the hash): `; ret (stderr, `err()` ile)
`not confirmed: type exactly APPLY <h> (the word APPLY, a space, then the hash); nothing applied` ve
`not confirmed: type exactly SEND <h> (the word SEND, a space, then the hash); nothing sent`. Birebir karşılaştırma
(`readline().strip() != "APPLY " + h`), TTY kontrolü, hash bağlama ve exit 6 aynen kalır; yazılan satır hiçbir çıktıya
eklenmez (bugünkü kod; yeni test istenmez).
#### Scenario: yalnız anahtar kelime
- WHEN `tty_run "APPLY" … apply 12 --confirm <h>` (aynısı `send` için `SEND`)
- THEN exit 6, gh'ye yazma çağrısı yok; birleşik çıktıda `tr -d '\r' | grep -qF '<ret satırı>'` geçer (pty stdout ve
  stderr'i birleştirir, `\r\n` verir; `2>dosya` ve `grep -x` kullanılmaz)
#### Scenario: doğru metin değişmez
- WHEN `APPLY <h>` (ya da `SEND <h>`) yazılır
- THEN bugünkü akış sürer; mevcut REQ-6 testleri (yanlış metin exit 6, pipe exit 6) geçer

### Requirement: REQ-2 Yerelde kaydedilmiş ama uygulanmamış kabul (#35, K181, K189, K190)
The system SHALL `triage.py show <n> --require accepted`'ın **iki** exit 8 dalında da (etiket/işaret yok; işaret eski
sha'lı) mesajı basmadan önce `load_record(n)`'a bakmalı: geçerli kayıtta `decision == "accept"`, `status == "recorded"`
ve `issue_sha` canlı `issue_sha(title, body)`'ye eşitse stderr'e
`issue #<n> is recorded locally as accept but not applied; from your own terminal run python3 "<path>" preview <n>, then the apply command with the HASH it prints`
yazmalı (`<path>` = `os.path.abspath(__file__)`). Başka her durumda o dalın bugünkü mesajı birebir kalır. Exit 8 ve boş
stdout her durumda kalır; yerel kayıt hiçbir zaman kabul sayılmaz. `skills/start/SKILL.md` adım 1a, exit 8'de sabit
"run triage first" cümlesi yerine yalnız stderr satırını gösterip durur. README.md "From issue to work" paragrafı ve
README.tr.md karşılığı bu durumu anlatır.
#### Scenario: kayıt var, apply yok
- WHEN issue 12'ye `accept` kaydı yapılır, `apply` çalışmaz, `show 12 --require accepted` çağrılır
- THEN exit 8, stdout boş, stderr birebir yeni mesaj (`<path>` test içinde hesaplanır)
#### Scenario: bugünkü mesaj kalır (her satır birebir karşılaştırılır)
- WHEN kayıt yoktur; kayıt JSON'u geçersizdir; kayıt eski sha taşır; kayıt `defer`'dir; kayıt `status: applied`'dır ama
  etiket yoktur
- THEN exit 8, stdout boş, stderr birebir `issue #<n> is not triaged as accepted; run /delixcrew:triage #<n>`

### Requirement: REQ-3 Capture heredoc'u yalnız veri gövdesinde ve iki script için muaf (#36, K182, K187, K188)
The system SHALL `scripts/bash_gate.py`'de:
- **(a)** dört yol kalıbında (`_QPATH`, `_PATH`, `_TQPATH`, `_TPATH`) yolun `-` ile başlamasını reddetmeli
  (`(?!-)`, tırnaklı biçimde tırnaktan hemen sonra); böyle bir komut kalıba uymaz ve tam metinle denetlenir;
- **(b)** komutun tamamı `ADD_HEREDOC` ya da `RECORD_HEREDOC`'a fullmatch oluyor ve ayraç gövdede erken geçmiyorsa
  feedback (a)/(b) ve triage (a)/(b) kurallarının **ikisini de** yalnız başlık satırına (group 1) uygulamalı.
Kural sırası, kalıpların geri kalanı, `gh` kuralları, deny metinleri ve korumalı yol yönlendirme denetimi değişmez.
#### Scenario: çapraz allow
- WHEN feedback add heredoc gövdesi `triage.py apply 12 --confirm abc` ya da `triage.py … under script` içerir; triage
  record heredoc gövdesi `feedback.py send F001 --confirm abc` ya da `feedback.py … under script` içerir
- THEN dördü de allow
#### Scenario: seçenek biçimli yol deny (bugün dördü allow, lead main'de ölçtü)
- WHEN `python3 -ic/x/feedback.py add <<'EOF'` ve `python3 "-ic/x/feedback.py" add <<'EOF'`, aynısı `triage.py record 12`
  için; gövde aynı ya da öbür script'in `send`/`apply`'ını `pty.spawn` ile sürer
- THEN her biri deny
#### Scenario: çapraz biçimde hileler deny
- WHEN çapraz allow gövdeleri şu biçimlerle gelir: tırnaksız `<<EOF` + `$(…)` ya da backtick; ayraç satırında komut;
  ayraçtan sonra satır; gövdede erken ayraç; `<<-'EOF'` ve gövdede sekmeli erken ayraç; başlıkta sonek (`<<'EOF' | bash`,
  `<<'EOF' && x`); `#`, `\<<`, `"<<` hileleri; `${VAR}` yol; `cd x && <kalıp>`; `<kalıp>; echo x`
- THEN her biri deny. Test genel `deny` yardımcısını kullanır (`tests/hook_tests.sh:11`): tam metne düşen komutta feedback
  bloğu önce çalıştığı için hangi deny metninin geleceği gövdeye bağlıdır; sıra değiştirilmez.
#### Scenario: zaman
- WHEN mevcut ReDoS probe'larına çapraz biçimde iki probe eklenir (50 000+ karakter gövde)
- THEN her probe mevcut eşiğin (`ls`'e göre < 0,1 sn) altında; süreler PR gövdesinde

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| CLI çıktısı | `triage.py apply`, `feedback.py send` istem + ret | REQ-1 metinleri; exit 6 aynı | kullanıcı terminali |
| CLI çıktısı | `triage.py show <n> --require accepted` stderr | REQ-2 ikinci mesaj; exit 8 aynı | `skills/start` 1a |
| hook | `bash_gate.py` yol kalıpları, feedback/triage (a)(b) | REQ-3; deny metinleri aynı | tüm oturumlar |

## 5. Data and migration
Kayıt ve kuyruk biçimi değişmez; göç yok.

## 6. Security note
- 🔐 İki kart da Tier 3 (K186): `scripts/bash_gate.py` korumalı yol (REQ-3); REQ-1 dışarı yayın yapan iki yolun onay
  adımını değiştirir (önceki her kart 🔐 idi: T010, T014, T020). Dispatch öncesi sohbette kart başına Approved satırı ve
  interaktif oturum; `security` iki kartta da birebir karşılaştırma, TTY ve hash bağlamanın değişmediğini doğrular.
- **Mevcut açık (main `1b3cf9e`, lead ölçtü, K187):** yol kalıbı `-` ile başlayan token'ı kabul ediyor. `python3
  -ic/<dizin>/feedback.py add <<'EOF'` ve triage record karşılığı fullmatch oluyor; Python `-i -c` ile gövdeyi stdin'den
  kod olarak çalıştırıyor (`BODY RAN` gözlendi) ve gövdenin `pty.spawn` ile kendi `send`/`apply`'ını sürmesi hook'tan
  geçiyor. REQ-3 (a) bunu kapatır; (b) tek başına uygulansaydı çapraz yönü de açardı.
- Kalan risk (REQ-3): yol sabit değildir; her `<dizin>/feedback.py` ya da `<dizin>/triage.py` kalıba uyar. Muafiyet
  gövdeyi o dosyaya stdin olarak verir; aynı adlı başka bir dosya gövdeyi okuyabilir. Bu, README.md:311-314'deki "desen
  tabanlı, gizlenmiş komut yakalanmaz" kalan riskiyle aynı sınıftır; yeni yetenek değildir. `apply`/`send` ayrıca TTY,
  hash bağlama ve yazılan `APPLY <h>`/`SEND <h>` ister.
- REQ-2: kayıt dizinine shell'den yazılabilir (README.md:300-301). Sahte bir kayıt yalnız mesajı değiştirir, exit kodunu
  değil; mesaj kullanıcıyı sohbette onay vermediği bir kaydı önizlemeye yönlendirebilir. Sınır: `apply` yorumun tamamını
  gösterir ve yazılan hash'i ister; mesajda yalnız issue numarası ve yerel script yolu geçer, issue metni geçmez.
- REQ-1 kapıyı gevşetmez: karşılaştırma birebir, harf katlama ya da yalnız hash eşleşmesi yok, yazılan girdi yankılanmaz.

## 7. Acceptance criteria (DoD)
- [ ] Her REQ için geçen test; doğrulama: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → hepsi geçer;
  `claude plugin validate .` geçer
- [ ] REQ-3 zaman probe'larının süreleri PR gövdesinde
- [ ] `qa` ACCEPT; iki kartta `security` CLEAN + insan onayı (🔐)
- [ ] PR gövdesinde "How I tested"

## 8. Open questions
Gate 1'i bekletmeyen, bu spec dışı takip adayları (P2, önceden var olan):
- Triage kuralı (a) argv listesi biçimini (`"triage.py","apply"`) tanımıyor; feedback kuralı (a) tanıyor
  (`bash_gate.py:29` ile `:53`). Tek başına TTY'ye takılır; hook'un listelemediği bir pty sürücüsüyle birlikte önemli.
- README.md:312-313 "`triage.py` yolunda TTY ve `APPLY <hash>` yine durdurur" der; pty süren gizlenmiş bir komut ikisini de
  aşar. İfade daraltılmalı (#10 SECURITY.md işiyle birlikte).

## 9. Decisions
- **K178** (geri alınır) Önceki spec ve T020–T021 `archive/0.6.2-feedback-filter-gaps/`'a taşındı; STATE boşaltıldı,
  doğrulama kayıtları yerinde.
- **K179** (geri alınır) Sürüm artmaz; CHANGELOG `## Unreleased` (K140 emsali). Sürüm ve etiket ayrı iş (K177 emsali).
- **K180** (geri alınır) İstem ve ret metni REQ-1'deki gibi sabit. Tırnak kullanılmaz: kullanıcı tırnağı da yazar ve
  birebir karşılaştırma reddeder. Yazılan metin yankılanmaz (K139 terminal güvenliği).
- **K181** (geri alınır) Yeni mesaj yalnız `decision accept` + `status recorded` + canlı sha'da; `applied` kaydı varken
  etiketin eksik olması (biri kaldırmış) bugünkü mesajı alır, çünkü yeniden triage doğru adımdır.
- **K182** (geri alınır) Çapraz muafiyet iki kalıbın zaten hesaplanan eşleşmesini paylaşır; yeni regex yok (ReDoS yüzeyi
  büyümez). Gerekçe: en küçük değişiklik, iki capture biçimi simetrik olur.
- **K183** (geri alınır) Not dosyası biçimi ve `cd`/`echo` sarmalı kapsam dışı: muafiyet tek çağrı + tırnaklı ayraçla
  sınırlı kalır (fail closed); bedel, bu biçimlerde Write aracı ya da çağrıyı tek başına çalıştırmak.
- **K184** (geri alınır) Site değişmez: `site/index.html:553` "exit 8 when the acceptance check fails" doğru kalır; komut,
  hook kuralı adı, rol, kapı ya da dosya eklenmiyor.
- **K185** (geri alınır) Kart taslağı: T023 REQ-1 + REQ-2 (`scripts/triage.py`, `scripts/feedback.py`,
  `skills/start/SKILL.md`, `README.md`, `README.tr.md`, `tests/triage_tests.sh`, `tests/feedback_tests.sh`) ve T024 REQ-3
  (`scripts/bash_gate.py`, `tests/hook_tests.sh`); ikisi de Tier 3 🔐 (K186), ortak dosya yok, paralel. CHANGELOG
  `## Unreleased` maddelerini `/delixcrew:close`'ta lead yazar (iki kart aynı dosyada çakışmasın). Kesin bölme dispatch'te.
- **K186** (geri alınır; architect P1) T023 de Tier 3 🔐: dışarı yayın yapan onay adımına dokunuyor; kademe kuralı
  (`skills/start/SKILL.md`) ve T010/T014/T020 emsali.
- **K187** (geri alınır; security Medium, lead main'de üretti) `(?!-)` düzeltmesi REQ-3'e ve T024'e alındı. Kapsam bir
  satır büyür; alınmasaydı REQ-3 (b) kapıyı gevşetirdi.
- **K188** (geri alınır; architect P1 + security Low) REQ-3 deny testleri genel `deny` yardımcısıyla; kural sırası değişmez.
- **K189** (geri alınır; architect P1) Yeni mesaj script'in gerçek yolunu taşır, `preview` ve `apply`'ı kullanıcı kendi
  terminalinde çalıştırır (onaylı istek ve #35'in beklediği). Seçenek: `/delixcrew:triage #<n>`'e yönlendirmek; triage'ı
  baştan tekrarlatır, #35'in şikâyet ettiği şey. Sahte kayıt yönlendirmesi §6'da.
- **K190** (geri alınır; architect P2) Kayıt kontrolü iki exit 8 dalında da yapılır: değişmiş, yeniden triage edilip
  kaydedilmiş ama uygulanmamış issue da aynı mesajı alır.
- **K191** (geri alınır) Spec incelemesi: architect FIX (3 P1, 4 P2) ve security FIX (1 Medium, 3 Low) işlendi; önceden
  var olan iki P2 §8'de.
- **K192** (geri alınır) Kart numaraları T023/T024: T022, paralel oturumda #10 kartına verildi (PR #46,
  `4b52a3b`). Taban `4b52a3b`; #46 README'leri değiştirdiği için README satır referansları o ağaca göre.
