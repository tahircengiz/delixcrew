# SPEC — Spec D: bayat kart işareti, `delix.json` fail closed, `docs/delix` sahipliği

> Size: **M** · Tier: 3 · Date: 2026-11-19 · Status: **approved (gate 1, 2026-11-19)** · rev 5 (rev 2: architect FIX
> P1×4 P2×3, security FIX Medium×5 Low×2, hepsi işlendi, K351–K354; rev 3: yeniden kontrolde architect P1×1, security
> Medium×1 ve lead'in doğruladığı symlink açığı, K348 değişti, K355; rev 4: yeniden kontrolde architect P1×1, security
> Medium×1 (lead harf duyarsızlığı açığını üretti), K356; rev 5: security Medium×1 (Files izni symlink'le), K357;
> architect rev 4'te READY verdi, rev 5 farkı yeniden incelenmedi, T056'nın kart incelemesinde bakılır)
> Source: geri bildirim taslakları F005, F007, F012, F014, F017, F023, F024, F026, F030, F032 (yerel kuyruk) ve STATUS
> "Açık iş" O5, O6. Grill kararları K344, K351 ve K355 (kullanıcı), lead kararları K345–K350, K352–K354, K356, K357. K
> numaraları STATUS.md'nin devamıdır. Önceki spec: [`C-board-visibility.md`](C-board-visibility.md).

## 1. Goal
Desktop uygulaması worktree klasör adlarını yeniden kullanıyor. Eski kartın `.delix/card` işareti klasörde kalınca üç
hook (yazma, Bash, Stop) yeni oturumu o kartın uygulayıcısı sayıyor ve lead'in `docs/delix` yazımını reddediyor (5
taslak). `delix.json` okuması iki yerde kırılgan: bozuk dosya boş `{}` okunuyor, korunan yol listesi boşalıyor ve yazım
geçiyor (O5); nesne olmayan dosya ya da liste olmayan `protected_paths` `write_gate.py`'yi traceback ile düşürüyor (O6;
`hooks.json`'daki `onFailure: block`'un bu durumda yazımı durdurup durdurmadığı doğrulanmadı). Ayrıca implement skill'i
ve architect, yazma kapısının yasakladığı `docs/delix/**` yazımını uygulayıcıya veriyor (5 taslak).
Başarı: işi biten kartın işareti hook'ları açmaz, okunamayan config kapıyı açık mesajla kapatır, uygulayıcıya
yapamayacağı adım verilmez.

## 2. Out of scope
- Bash kapısına `origin/HEAD`'i kaydıran komutlar için ret kuralı (K351; §6'da Bilinen sınır).
- Board ve panelin bayat işaretli worktree'yi eski karta eşlemesi ve `remove_worktree` bloğu (F013).
- Düzeltme turunda kartın Files listesini genişletmek (F028), raporu worktree dışına kopyalamak (F025).
- `/security-review` adımının hedefi (F006, F008, F009), dispatch dalının upstream'i (F027, F029).
- Stop gate'in `delix.json` anlamı: eksik ya da bozuk config bugünkü gibi `pytest -q` koşar.

## 3. Requirements

### Requirement: REQ-1 İşi biten kartın işareti hook'ları açmaz (K344, K345, K352, K353)
`card_path(cwd)` bugünkü yerel işaret koşullarına ek olarak, işaretteki kartın işi bittiyse `None` döndürür.
- **Kart:** işaret metninin son yol parçası `T<rakamlar>` ile başlar; kimlik rakam dizisinin tamamıdır (`T1000-x.md` →
  `T1000`). Kart kaydı yalnız `file` alanı işaret metnine harfi harfine eşitse sayılır.
- **Güvenilir okuma (§4'teki argv):** önce tam ad `refs/remotes/origin/HEAD` doğrulanır ve commit SHA'sı alınır; STATE o
  SHA'dan `--no-lazy-fetch --no-replace-objects cat-file blob` ile, en çok 1 MiB okunur (board ile aynı, K262, K277,
  K284). Worktree'deki `docs/delix/STATE.json` kopyası hiç okunmaz.
- **İşi bitti:** kart kaydı `status: accepted` taşır ya da `merged` alanı bir nesnedir. Kimlik güncel `cards`'ta yoksa,
  aynı SHA'daki STATE'in `archive` listesindeki en çok 20 yol aynı kuralla okunur; yalnız
  `docs/delix/archive/<ad>/STATE.json` biçimindeki ve `..` içermeyen metinler.
- **Fail closed:** her hata ya da istisna (git yok, zaman aşımı, ref yok, boyut, UTF-8, JSON, beklenmeyen tip) işareti
  etkin bırakır. `write_gate.py` `card_path`'i bir kez çağırır.
- **Etkin işaret korunur (K348):** işaret etkinken yazma kapısı, realpath'i (K356 katlamasıyla) `.delix/card` olan
  hedefe Write ile farklı metin yazımını (iki taraf da baş ve sondaki boşluk kırpılarak karşılaştırılır) ve Write
  dışındaki her araçla dokunuşu reddeder. İşi biten kartın işareti hook'ları açmadığı için yerine yeni işaret
  yazılabilir. "İşi bitti" kararı yalnız `card_path`'tedir.
#### Scenario: kabul edilmiş kart
- WHEN işaret `docs/delix/tasks/T055-release-0-7-2.md`, `origin/HEAD` STATE'inde T055 `accepted` ve `file` eşit
- THEN yazma kapısı `docs/delix/SPEC.md` yazımına izin verir, Bash'te uygulayıcı kuralları koşmaz, Stop gate test
  komutunu çalıştırmaz; stderr'e bir kez şu satır yazılır (tek satır):
  ```
  delixcrew: .delix/card names T055, which is accepted on origin/HEAD; implementer hooks stay inactive here.
  Move .delix aside before starting a new card.
  ```
#### Scenario: merge edilmiş ama escalated kart
- WHEN kart `escalated` ve `merged` bir nesne
- THEN ilk senaryoyla aynı sonuç.
#### Scenario: süren ya da bilinmeyen kart (fail closed)
- WHEN kart `open`, `in_progress`, `in_review`, `fixing`, `rejected` ya da `merged`'sız `escalated`; kart hiçbir
  STATE'te yok; `file` eşit değil; işarette `T<rakamlar>` yok; `refs/remotes/origin/HEAD` yok; STATE okunamıyor ya da
  nesne değil
- THEN hook'lar bugünkü gibi uygulayıcı kipindedir.
#### Scenario: çapayı taklit eden yollar
- WHEN `refs/remotes/origin/HEAD` yok ama `refs/tags/refs/remotes/origin/HEAD` ya da aynı adlı dal kartı `accepted`
  gösteren bir commit'e işaret ediyor; ya da `git replace` STATE blob'unu kartı `accepted` gösteren bir blob'la
  değiştirmiş
- THEN hook'lar uygulayıcı kipindedir.
#### Scenario: kimlik ve kopya
- WHEN işaret `T1000-x.md`, `T100` `accepted`; ya da worktree'deki STATE kopyası kartı `accepted` gösteriyor,
  `origin/HEAD` göstermiyor
- THEN hook'lar uygulayıcı kipindedir.
#### Scenario: arşivdeki kart
- WHEN kart yalnız `archive` listesindeki bir STATE'te `accepted` ve `file` eşit
- THEN ilk senaryoyla aynı sonuç; listede biçime uymayan öğe ve okunamayan yol atlanır.
#### Scenario: canlı başka kartın işareti
- WHEN `.delix/card` işi bitmemiş T0xx'i gösteriyor ve Write farklı bir kart yolu yazmak istiyor (`.DELIX/card`
  yazımı dahil); ya da Edit, MultiEdit veya NotebookEdit `.delix/card`'a dokunuyor
- THEN yazma kapısı reddeder (tek satır):
  ```
  delixcrew: .delix/card names T0xx, which is not finished on origin/HEAD; this worktree belongs to that card.
  Write nothing under .delix; end with BLOCKED in your final message; the lead opens a new worktree.
  ```
#### Scenario: aynı kartın işareti
- WHEN etkin işaretin metniyle aynı metin, sonunda satır sonu olsa da, Write ile yeniden yazılır (düzeltme turu, kendi
  worktree'si)
- THEN izin alır.

### Requirement: REQ-2 `delix.json` okunamazsa kart worktree'sinde kapı kapalıdır (K346)
`delix_json(cwd)` yalnız okunabilen bir JSON nesnesini döndürür; dosya yoksa, okunamıyorsa, JSON değilse ya da nesne
değilse `None` döndürür. Etkin kart worktree'sinde `write_gate.py` ve `bash_gate.py`, `delix_json` `None` döndüğünde
ya da `protected_paths` veya `test_paths` (varsa) metin listesi değilse reddeder; ikisinin mesajı aynıdır: `delixcrew:
docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; this card worktree stays
blocked until the user fixes it from their own terminal`. Yazma kapısı, `outside_cwd` denetiminden sonra, hedefin
realpath'i `realpath(cwd)/.delix/` altındaysa yazımı bu redden muaf tutar (uygulayıcı `BLOCKED` raporunu
yazabilsin); `.delix/card` için REQ-1'in etkin işaret kuralı yine geçerlidir. Stop gate davranışı değişmez.
#### Scenario: bozuk JSON (O5)
- WHEN `delix.json` içeriği `{"protected_paths": [` ve uygulayıcı korunan bir yola yazmak ister
- THEN yazma reddedilir (bugün izin alıyor); Bash komutu da aynı mesajla reddedilir.
#### Scenario: nesne olmayan JSON ya da liste olmayan alan (O6)
- WHEN `delix.json` içeriği `[]`, ya da `{"protected_paths": 5}`, ya da `{"test_paths": [1]}`
- THEN iki kapı traceback'siz, aynı mesajla reddeder.
#### Scenario: eksik dosya
- WHEN kart worktree'sinde `docs/delix/delix.json` yok
- THEN yazma ve Bash aynı mesajla reddedilir; `tests/ref_gate_tests.sh`'teki 57. vaka (bugün allow) deny'a döner (K354).
#### Scenario: rapor yazılabilir
- WHEN `delix.json` bozuk ve uygulayıcı `.delix/report.md` yazar
- THEN yazma izin alır.
#### Scenario: muafiyetten kaçış
- WHEN `delix.json` bozuk ve hedef `.delix/../scripts/common.py` ya da `.delix/x/common.py` (`.delix/x` → `../scripts`)
- THEN yazma reddedilir.
#### Scenario: kart worktree'si dışı
- WHEN `.delix/card` yok (ya da REQ-1'e göre bayat)
- THEN `delix.json`'un durumu hiçbir hook'un kararını değiştirmez.

### Requirement: REQ-3 Uygulayıcıya `docs/delix` adımı verilmez (K347, K348)
- `skills/implement/SKILL.md`: uygulayıcı `STATE.json`'a yazmaz; PR numarasını raporun PR satırına yazar, `in_review`
  ve `pr`'yi lead kaydeder. Adım 0.2: `.delix/card` başka bir kartı gösteriyorsa uygulayıcı eski kimliği okur, sonra
  yeni işareti Write ile yazar. Kapı reddederse (eski kart sürüyor, REQ-1) `.delix/` altına hiçbir şey yazmaz
  (canlı kartın `report.md`'si değişmez) ve son mesajında `BLOCKED` döner. İzin alırsa `.delix/`
  içinde kalan her şey (`card` ve `previous/` hariç) `.delix/previous/<id>/`'e taşınır; `<id>` eski işaretin
  `T<rakamlar>` kimliğidir, yoksa `unknown`. Hiçbir dosya silinmez; taşıma raporda yazılır.
- `templates/STATE.json` `$comment`: implementer STATE'e yazmaz, lead yazar.
- `agents/architect.md` job B: kartın Files listesi `docs/delix/**` yolu taşımaz; kanıt `.delix/evidence/`'a yazılır,
  `docs/delix` değişikliği dalga planında lead adımıdır.
- `skills/dispatch/SKILL.md` §2: Files'ta `docs/delix/**` yolu olan kart lead adımına taşınır.
#### Scenario: metin denetimi
- WHEN `grep -n "STATE.json" skills/implement/SKILL.md templates/STATE.json`
- THEN uygulayıcıya `STATE.json` yazdıran satır yok; `env_owner` okuma satırı kalır.

### Requirement: REQ-4 Doküman ve sürüm (K349, K350, K351)
- README ve README.tr: "implementer worktree" tanımı (satır 164) REQ-1'i, `delix.json` cümlesi (satır 136) REQ-2'yi
  anlatır. Bilinen sınır paragrafı (satır 436-440): `symbolic-ref`, refspec'li `fetch`/`pull`, `fast-import` ve git
  dizinine dosya yazmak artık yalnız board'u değil kart worktree'sinin hook'larını da kapatır; bu, `.delix/card`'ı
  silmekle eşdeğerdir (satır 407). `replace` ve aynı adlı tag/dal okuma tarafında kapanır.
- Sitenin dört sayfası aynı içeriği taşır (`usage` hook ve Known limits satırları, `index` akış şemasındaki
  "No local .delix/card?" kutusu). CHANGELOG'da `## Unreleased`.
- Sürüm kartı `0.7.3` yazar: `plugin.json`, sitenin `data-version`'ları, CHANGELOG başlığı. `bash tests/site_tests.sh`
  geçer.

### Requirement: REQ-5 Korunan ve test yolu symlink'le ya da harf farkıyla atlanmaz (K355, K356)
`common.matches` (iki kapının korunan yol, test yolu, `docs/delix/**` ve yönlendirme denetimi) verilen yolun yanında
hedefin realpath'ini de `realpath(cwd)`'ye göre eşler; ikisinden biri eşleşirse kural uygulanır. Eşleşmeden önce yol
ve desen aynı katlamadan geçer: NFD + `casefold` (`write_gate.py`'deki `_fold`, K129). Lead 2026-11-19'da bugünkü
kodda `lnk -> scripts` symlink'i üzerinden `lnk/x.py` ve APFS'te `Scripts/x.py`, `SCRIPTS/x.py` yazımının korunan
`scripts/x.py` kuralını geçtiğini üretti. Kapıyı **açan** Files listesi denetimi (`listed`) ise iki biçimin de
listede olmasını ister: verilen yol listede ama realpath'i değilse liste dışı sayılır (K357).
#### Scenario: klasör symlink'i
- WHEN kart worktree'sinde `lnk -> scripts`, `protected_paths` `scripts/x.py` içerir, kartta Approved yok
- THEN Write ile `lnk/x.py` ve Bash ile `cp a lnk/x.py` reddedilir; `scripts/x.py` bugünkü gibi reddedilir.
#### Scenario: test yolu
- WHEN `tlink -> tests`, `tests/a_tests.sh` var ve kartın Files listesinde yok
- THEN `tlink/a_tests.sh` yazımı var olan test dosyası kuralına takılır.
#### Scenario: harf farkı
- WHEN `protected_paths` `scripts/x.py` içerir; hedef `Scripts/x.py`, `SCRIPTS/x.py` ya da `DOCS/delix/STATE.json`
- THEN üçü de reddedilir. Harfe duyarlı dosya sisteminde (CI) ayrı bir `Scripts/x.py` dosyası da korunan sayılır; bu
  fazla ret bilinçlidir (fail closed).
#### Scenario: listedeki symlink
- WHEN kart `docs/a.md`'yi listeler ve `🔐 Approved` taşır, `docs/a.md` → `../scripts/common.py`; ya da kart
  `src/a.py`'yi listeler, `src/a.py` → `../tests/a_tests.sh` (var olan test)
- THEN iki Write da reddedilir.

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| function | `common.card_path(cwd)` | `str \| None`; işi biten kartta `None` + stderr satırı | üç hook |
| function | `common.delix_json(cwd)` | `dict \| None` (önce `{}`) | iki kapı, `stop_commands` |
| argv | ref doğrulama | `git --no-lazy-fetch show-ref --verify refs/remotes/origin/HEAD` | `card_path` |
| argv | STATE okuma | `git --no-lazy-fetch --no-replace-objects cat-file blob <sha>:<yol>`, ≤ 1 MiB | `card_path` |
| function | `common.matches(path, patterns, cwd)` | katlanmış yol ya da realpath eşleşirse desen | iki kapı |
| rule | Files izni (`listed`) | verilen yol **ve** realpath listede | `write_gate.py` |
| message | REQ-2 deny metni | iki kapıda harfi harfine aynı | testler |
| message | etkin işaret deny metni | REQ-1 senaryosundaki tek satır | testler |
| file | `.delix/previous/<id>/` | eski kartın `.delix` içeriği, git dışı | lead, review |

Git çağrıları `common.git` üzerinden (`core.fsmonitor=false`, `GIT_*` env'i silinmiş, `GIT_NO_LAZY_FETCH=1`, 5 s).

## 5. Data and migration
Şema değişmez. `STATE.json`'a T056–T058 eklenir. Eski `delix_json` `{}` dönüşüne dayanan tek çağıran
`stop_commands`'tır; zaten `isinstance` ile `{}`'e çeviriyor (`scripts/common.py:83-84`).

## 6. Security note
- 🔐 Korunan yollar: `scripts/common.py`, `scripts/write_gate.py`, `scripts/bash_gate.py` (T056);
  `.claude-plugin/plugin.json` (T058). Kart başına `**🔐 Approved:**` satırı kullanıcının sohbetteki evet'iyle yazılır.
- REQ-1 bir kapıyı **açan** kuraldır ve çapası işaretten güçlü değildir (K351). Kart oturumu
  `refs/remotes/origin/HEAD`'i bugünkü Bash kapısından geçen komutlarla kaydırabilir: `git symbolic-ref <ad> <hedef>`,
  `git fetch . HEAD:<ref>` (ağsız), git dizinine dosya yazmak; README `git pull` refspec'ini ve `git fast-import`'u da
  sayıyor. Sahte STATE Bash heredoc'uyla commit edilebilir (yazma kapısı yalnız Write/Edit'i görür). Lead
  2026-11-19'da geçici depoda Bash kapısının `symbolic-ref`, refspec'li `fetch`, `hash-object -w`, `replace`, aynı
  adlı `tag` ve heredoc yazımına izin verdiğini, `symbolic-ref` ile `fetch`'in çapayı gerçekten kaydırdığını üretti;
  `pull` ve `fast-import` denenmedi. Kazanılan yeni yetenek yok: `.delix/card`'ı silmek üç hook'u bugün zaten
  kapatıyor (README satır 407, 396-399 "friction, not a boundary"). Fark: bu yollar silinmiş bir işaretten zor fark
  edilir; README ve sitede yazılır.
- Okuma tarafı board'la aynı sertleşir (K352): `replace` nesneleri ve `origin/HEAD` yokken aynı adlı tag ya da dal
  okumayı değiştiremez (ikisi de geçici depoda üretildi), git < 2.44'te `--no-lazy-fetch` bilinmeyen seçenek olarak
  hata verir ve işaret etkin kalır.
- Her bilinmeyen durumda kapı kapalı kalır (REQ-1 fail closed, REQ-2). REQ-2 bugün açık olan iki yolu kapatır;
  `.delix/` muafiyeti realpath ile denetlenir, `..` ve symlink'le korunan yola kaçılamaz.
- Önceden var olan iki açık kapanır (K355, K356, REQ-5): korunan yol ve `docs/delix/**` worktree içindeki klasör
  symlink'iyle ya da APFS'te harf farkıyla atlanabiliyordu.
- Etkin işaret yalnız aynı metinle yeniden yazılabilir (REQ-1): başka kartın oturumu canlı kartın klasörünü ve onun
  `🔐 Approved` satırını Write ile devralamaz. Bash ile işaretin üzerine yazmak (`printf … > .delix/card`) Bilinen
  sınırdır; işareti silmekle aynı sınıftadır (README satır 407).
- Sır yok.

## 7. Acceptance criteria (DoD)
- [ ] REQ-1, REQ-2 ve REQ-5'in her senaryosu için yeni `tests/stale_card_tests.sh`'te test; `tests/ref_gate_tests.sh`'te
  yalnız iki satır bilinçli değişir (K354): 30. satırdaki beklenen mesaj REQ-2 metni olur, 57. vaka `deny` olur.
  `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` yeşil, CI yeşil.
- [ ] Testler Mac'teki python3 3.9 ve 3.13 shim'iyle koşar (Mac python 3.9.6, CI 3.12).
- [ ] "Ağ yok" iddiası `--filter=tree:0` klonda pack sayısıyla ölçülür (K284).
- [ ] Yeni regex ReDoS için ×4–×8 girdi büyümesiyle zaman oranıyla ölçülür.
- [ ] REQ-3 ve REQ-4 metin denetimi; `bash tests/site_tests.sh` yeşil.
- [ ] T056 ve T058: qa ACCEPT, security CLEAN + 🔐 kullanıcı onayı; T057: qa ACCEPT.

## 8. Open questions
- (yok)

## 9. Decisions
- **K344** (kullanıcı, 2026-11-19, geri alınır) Bayat işaret kartın durumuyla anlaşılır: `origin/HEAD` STATE'inde
  `accepted` ya da `merged` nesnesi. Alternatifler: dal bağı (uygulayıcının `git switch`'i kapıları açardı, fail open),
  kod yok yalnız uyarı (kilit her seferinde elle çözülürdü).
- **K345** (lead, geri alınır) Kart güncel STATE'te yoksa `archive` listesindeki STATE'lere bakılır (en çok 20, yol
  biçimi sabit); her okuma hatası işareti etkin bırakır. Neden: T001–T021 arşivde.
- **K346** (lead, geri alınır; rev 2'de genişledi) `delix_json` eksik, bozuk ve nesne olmayanı ayırmadan `None`
  döndürür; liste olmayan `protected_paths`/`test_paths` da aynı sayılır; iki kapı aynı mesajla reddeder; `.delix/`
  yazımı muaf; Stop gate `pytest -q`'da kalır. Neden: bugün iki yol fail open ya da çöküyor (O5, O6); Bash kapısı nesne
  olmayanı zaten reddediyor (R-U4), kural ona hizalanır.
- **K347** (lead, geri alınır) `docs/delix` lead'indir: uygulayıcı STATE ve `docs/delix/**` yazmaz, kural metinle
  düzeltilir. Alternatif "kapı karta yazılmış `docs/delix` yolunu açar" reddedildi: uygulayıcı STATE'e yazabilirse
  kendi qa kaydını da yazabilir (ledger, Spec C REQ-2). Bedeli: kanıt dosyasını lead taşır (DX), güvenlik kazanır.
- **K348** (lead, geri alınır; rev 3'te değişti) Eski `.delix` silinmez. İşaret etkinse yazma kapısı yeni işareti
  reddeder, uygulayıcı `BLOCKED` döner; işi biten kartın işaretinin yerine yeni işaret yazılır ve kalan dosyalar
  `.delix/previous/<id>/`'e taşınır. "İşi bitti" kararı kodda tek yerde (`card_path`). Rev 1 skill metninde ikinci bir
  tanım yazıyordu; rev 2 koşulsuz taşıyordu ve canlı bir kartın klasörünü başka kartın oturumuna veriyordu (architect
  P1, yeniden kontrol).
- **K349** (lead, geri alınır) Kartlar: T056 🔐 hook kodu ve testi (REQ-1, REQ-2, REQ-5); T057 skill, ajan, şablon,
  README, site, CHANGELOG `Unreleased`; T058 🔐 sürüm. Dalga 1: T056 ve T057 paralel (ortak dosya yok); dalga 2: T058.
- **K350** (lead, geri alınır) Sürüm `0.7.3`: düzeltme; yeni komut, rol ya da kapı yok.
- **K351** (kullanıcı, 2026-11-19, geri alınır) Çapayı kaydıran Bash yolları Bilinen sınır olarak yazılır, ret kuralı
  eklenmez; okuma board'la aynı sertleşir. Alternatif: T056'ya hedefli `symbolic-ref`, `:` içeren `fetch`/`pull`
  refspec'i, `fast-import`, `filter-branch` reddi (`bash_gate.py` büyür, git dizinine yazma yine açık kalır).
- **K352** (lead, geri alınır) Güvenilir okuma §4'teki iki argv'dir: tam ref doğrulaması, sonra SHA'dan
  `--no-replace-objects cat-file`, ≤ 1 MiB. Neden: board aynı çapayı aynı sertleştirmeyle okuyor (K262, K277, K284).
- **K353** (lead, geri alınır) Kart kimliği rakam dizisinin tamamıdır ve kayıt `file` alanının işarete tam eşitliğiyle
  eşlenir. Neden: `T100`/`T1000` karışmaz; aynı kimlikli başka kayıt (arşiv) canlı kartın hook'larını açamaz.
  Bugün 32 güncel ve 23 arşiv kartının hepsinde `file` var.
- **K354** (lead, geri alınır) `tests/ref_gate_tests.sh`'te iki beklenti bilinçli değişir (mesaj ve eksik dosya); bu
  test zayıflatma değil REQ-2 davranışıdır. T056'nın Files listesinde yazılır; qa bu iki satırın dışındaki her
  değişikliği bulgu sayar.
- **K355** (kullanıcı, 2026-11-19, geri alınır) Önceden var olan symlink açığı T056'da kapanır: yol eşleşmesi verilen
  yola ve realpath'e bakar (REQ-5). Alternatif: ayrı 🔐 kart, açık Known limits'e yazılır. Neden: aynı dosya ve aynı
  kart, değişiklik küçük, testle kanıtlanır.
- **K356** (lead, geri alınır) K355'in kapattığı açık sınıfı harf farkını da kapsar: yol ve desen NFD + `casefold` ile
  katlanır, etkin işaret karşılaştırması da. Neden: security bildirdi, lead APFS'te üretti (`Scripts/x.py` korunan
  `scripts/x.py` kuralını geçiyor); kullanıcı aynı sınıfın symlink yolunu T056'ya almıştı (K355). Bedeli: harfe duyarlı
  dosya sisteminde harf farkı olan ayrı dosya da korunan sayılır (fail closed).
- **K357** (lead, geri alınır) Ret yönündeki kurallar iki yol biçiminden (verilen, realpath) birine bakar; izin
  yönündeki Files denetimi ikisini birden ister. Neden: security, "birinden biri" kuralının izin yönünde listelenmiş
  bir symlink'le korunan ya da test dosyasını açtığını gösterdi (rev 4, kodu okuyarak).
