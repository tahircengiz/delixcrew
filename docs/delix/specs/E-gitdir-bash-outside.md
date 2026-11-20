# SPEC — Spec E: kart worktree'sinin `.git`'i yazma kapısında, Bash yazımının worktree dışı Bilinen sınır

> Size: **M** · Tier: 3 · Date: 2026-11-20 · Status: **approved (gate 1, 2026-11-20)** · rev 3 (rev 2: architect FIX
> P1×3 P2×4, hepsi işlendi, K362 değişti, K364; rev 3: security 🔐 HUMAN_APPROVAL Medium×2 Low×4, hepsi işlendi,
> K361 ve K364 değişti, K365)
> Source: Spec D incelemesinde lead'in bulduğu iki önceden var olan açık (T056 `## Review findings` Round 1 son madde,
> Round 2 security Low; STATUS §14.4 "Lead takibi"). Grill kararları K358 ve K359 (kullanıcı), lead kararları
> K360–K365. K numaraları STATUS.md'nin devamıdır. Satır numaraları Spec D kapanışına (`af6c35b`) göredir. Önceki
> spec: [`D-stale-card-config.md`](D-stale-card-config.md).

## 1. Goal
Hook'lar kartı `cwd/.delix/card` ve worktree'nin `.git`'i üzerinden bulur (`scripts/common.py`, `card_path`:
`git rev-parse --show-toplevel`, `git ls-files`). Write aracı kart worktree'sinin `.git` dosyasına bozuk içerik
yazarsa git çalışmaz, `card_path` `None` döner ve üç hook kapanır; ardından `docs/delix/**`, korunan yol ve
varsayılan dala push serbest kalır. Lead 2026-11-20'de bunu gerçek hook'larla main `ab07cfe`'de, PR #88 @ `0f09664`'te
ve birleşmiş main `68187e1`'de üretti. Model dosyayı en çok Write/Edit ile yazar; bu yol sabit bir kuralla kapanır. İkinci açık
(Bash yazma kuralı hedefin worktree içinde olup olmadığına bakmıyor) Bilinen sınır olarak yazılır.
Başarı: Write/Edit kart worktree'sinin `.git`'ine yazamaz; README, README.tr ve site iki sınırı doğru anlatır.

## 2. Out of scope
- Bash ile `.git`'e yazmanın reddi (K361): `.delix/card`'ı silmekle aynı sınıf (README push kuralı listesi).
- Bash yönlendirme/`cp`/`mv`/`tee` kuralına worktree dışı denetimi (K358): `sed -i`, `python3 -c`, `dd` zaten
  kuralın dışında; bugünkü Bilinen sınır cümlesiyle aynı sınıf.
- `card_path`'in bozuk git'te fail closed olması (K359).
- İç içe `.git` (`src/.git`, submodule): kartın bulunmasını etkilemez.
- `.git/info/exclude`'a Write/Edit: kart ana checkout'taysa artık reddedilir; `.delix/` dışlaması Bash'le yazılır
  (deny metni komutu verir). Bağlı worktree'de bu dosya ortak git dizinindedir, A13 onu bugün de reddediyor.

## 3. Requirements

### Requirement: REQ-1 Kart worktree'sinin `.git`'i Write aracıyla yazılmaz (K358, K359, K360)
Yazma kapısı etkinken (geçerli ve işi bitmemiş `.delix/card`) Write, Edit, MultiEdit ve NotebookEdit, cwd'nin kendi
`.git`'ine (gitfile ya da dizin) ve altındaki her yola yazamaz. Eşleşme `common.matches(path, [".git/**"], cwd)` ile
yapılır: verilen yol ya da realpath, NFD + `casefold` katlanmış (Spec D REQ-5). Kural `docs/delix/**` kuralından
sonra, Files izninden önce durur: listelenmiş ve `🔐 Approved` taşıyan kart da `.git`'i açamaz.
Deny metni (tek satır, iki testte harfi harfine):
`delixcrew: '<path>' is the worktree's .git; the implementer cannot change it with this tool (the hooks find the card through it). .delix/ is excluded with: echo .delix/ >> "$(git rev-parse --git-path info/exclude)"; for anything else, explain with NEEDS_CONTEXT in the report.`
#### Scenario: bağlı worktree'nin gitfile'ı
- WHEN kart worktree'si `<ana checkout>/.claude/worktrees/x`; hedef `.git`, `./.git`, `.GIT`, `.Git`, mutlak
  `<W>/.git` ya da `src/../.git`; araç Write, Edit, MultiEdit ya da NotebookEdit (`notebook_path`)
- THEN yukarıdaki metinle reddedilir; ardından Write `docs/delix/STATE.json` bugünkü metinle reddedilmeye devam eder.
#### Scenario: symlink üzerinden
- WHEN depoda izlenen `l -> .git` ve `d -> .` var; hedef `l`, `d/.git` ya da `d/d/.git`
- THEN reddedilir.
#### Scenario: ana checkout kart worktree'si
- WHEN kart bağlı olmayan bir checkout'ta (`.git` dizin); hedef `.git/HEAD`, `.git/refs/remotes/origin/HEAD`,
  `.GIT/config` ya da `l/info/exclude`
- THEN reddedilir.
#### Scenario: kontroller
- WHEN hedef `.gitignore`, `.gitattributes`, `.gitkeep`, `src/.git`, `src/x.py` ya da `.delix/report.md`
- THEN izin verilir; `docs/delix/**`, korunan yol ve var olan test dosyası bugünkü metinleriyle reddedilir.
#### Scenario: kapı etkin değil
- WHEN cwd'de `.delix/card` yok ya da kart `origin/HEAD` STATE'inde `accepted`
- THEN `.git/HEAD` yazımına hook karışmaz.
#### Scenario: listelenmiş `.git`
- WHEN kartın Files listesi `.git`'i içerir ve kart `🔐 Approved` taşır
- THEN Write `.git` yine REQ-1 metniyle reddedilir.
#### Scenario: okunamayan `delix.json`
- WHEN `docs/delix/delix.json` bozuk
- THEN Write `.git` bugünkü gibi Spec D REQ-2 metniyle reddedilir.

### Requirement: REQ-2 Bash yazımının iki sınırı Bilinen sınır olarak yazılır (K358, K361)
README `## Known limits` ve README.tr `## Bilinen sınırlar`:
- "A path escaping the worktree (cwd) is always rejected (A13, K42)" cümlesi yazma kapısına (Write/Edit) bağlanır.
- Bash yazma kuralı (yönlendirme, `cp`, `mv`, `tee`) yolu cwd'ye göre eşler: `scripts/**` gibi dizinli bir desen
  worktree dışındaki hedefi eşlemez (başka bir checkout, kart worktree'sini `.claude/worktrees/<x>` altında tutan ana
  checkout ve onun `docs/delix/`'i; `../../../scripts/x.py` gibi göreli ya da mutlak yol); `.env*` gibi dizinsiz desen
  dosya adına bakar ve eşler. Bu yazım plugin'in kendi dosyalarına da ulaşır: plugin bir checkout'tan yükleniyorsa
  (`--plugin-dir`, `directory` marketplace) hook kodu o andan ya da sonraki `claude plugin update`'ten sonra değişmiş
  olur; böyle bir oturumdan ya da güncellemeden önce o checkout'ta `git status` bakılır. Sınır Claude Code'un Bash
  izin istemidir (K77); dispatch'in açtığı `--permission-mode auto` oturumunda istem yoktur, bu yazımı yalnız auto
  mode sınıflandırıcısı görür.
- Bash'in worktree'nin `.git`'ini değiştirmesi (`printf … > .git` ya da `git add -f .delix/card`) üç hook'u kapatır;
  `.delix/card`'ı silmekle ve worktree kökünün altına `cd` ile aynı sınıftır.
Bash cümlesini taşıyan diğer yerler aynı "worktree içindeki" kaydıyla daraltılır: README "What this plugin does"
(`README.md:121` "denies shell writes into a protected path", `README.tr.md:121-122`); `site/index.html` ve
`site/tr/index.html` Known limits notu (satır 446, "bash_gate catches only redirects, `cp`, `mv` and `tee` into a
protected path") ve uygulayıcı satırı (satır 475, "Shell writes into a protected path are denied"). Site:
`site/usage.html` ve `site/tr/usage.html` Known limits listesine iki sınır için bir madde. Her bölümün `Source:` /
`Kaynak:` satırı kaynağı adlandırır. Belge kartı her yerin yeni cümlesini kartta harfi harfine yazar.
#### Scenario: metin denetimi
- WHEN kartın yazdığı her yeni cümle `grep -F` ile kendi dosyasında aranır
- THEN her biri bir kez bulunur, eski A13 cümlesi README ve README.tr'de 0 kez bulunur, `bash tests/site_tests.sh`
  yeşil.

### Requirement: REQ-3 REQ-1'in belgesi ve sürüm (K362, K363)
`.git` reddedilen hedeflere eklenir: README "What this plugin does on your machine" yazma kapısı cümlesi
(`README.md:105`) ve README.tr eşi; `site/index.html` ve `site/tr/index.html` yazma kapısı şemasının 4. satırı ("Card
file or docs/delix/**?", satır 407) ve `aria-label`'ı (satır 365; yeni kutu yok, şema boyu değişmez) ve uygulayıcı
satırı (satır 466). CHANGELOG T058'in yazdığı `## 0.7.3` başlığının üstüne yeni `## Unreleased` alır, REQ-1 için bir
madde (🔐). Sürüm kartı `0.7.4`'ü `.claude-plugin/plugin.json`'a, sitenin `data-version` işaretlerine, CHANGELOG
başlığına ve dört footer tarihine yazar (T058 D4: footer tarihi CHANGELOG tarihidir).
#### Scenario: sürüm
- WHEN sürüm kartı birleşir
- THEN `"version": "0.7.4"` `plugin.json`'da 1 kez, her sayfada `data-version="0.7.4"` T058'deki kadar, `## 0.7.4 — `
  CHANGELOG'da 1 kez, `## Unreleased` 0 kez; `README.md:105` cümlesi `.git` içerir; `bash tests/site_tests.sh` yeşil.

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| rule | `.git` reddi | `matches(path, [".git/**"], cwd)` doluysa REQ-1 metniyle deny | `write_gate.py` |
| message | REQ-1 deny metni | §3'teki tek satır | testler |
| test | `tests/gitdir_gate_tests.sh` (yeni) | `ALL PASSED` ile biter, tetik kelimeleri çalışma anında kurar | `test_command` |

## 5. Data and migration
Şema değişmez. `STATE.json`'a üç kart eklenir. Yeni git çağrısı yok.

## 6. Security note
- 🔐 Korunan yollar: `scripts/write_gate.py` (REQ-1), `.claude-plugin/plugin.json` (sürüm). Kart başına
  `**🔐 Approved:**` satırı kullanıcının sohbetteki evet'iyle yazılır.
- REQ-1 yalnız ret yönündedir; hiçbir yazımı açmaz. Çözülemeyen yol bugünkü gibi `docs/delix/**` kuralında fail closed
  reddedilir (kural ondan sonra durur).
- `card_path`'in dayandığı her şey REQ-1'den sonra Write ile değişemez: `.delix/card` (Spec D etkin işaret kuralı),
  realpath (Write symlink kuramaz), `.git` ve altı (REQ-1), ortak git dizini ve bağlı worktree'nin `gitdir` kaydı (cwd
  dışında, A13). Varsayım: git dizini ve ortak dizin ya `.git`'in kendisi ya da cwd dışındadır; gitfile'ın worktree
  içindeki bir klasörü gösterdiği düzen (`--separate-git-dir` ile alt klasör) kapsanmaz ve REQ-1'den sonra Write ile
  kurulamaz.
- Kalan yollar Bash'tedir ve Bilinen sınırdır (REQ-2): `.git`'i Bash'le değiştirmek ve worktree dışı Bash yazımı. Lead
  2026-11-20'de worktree dışı yazımın ana checkout'un `scripts/common.py`'sine ve `docs/delix/STATE.json`'una göreli ve
  mutlak yolla geçtiğini, Write aracının aynı yazımı A13 ile reddettiğini, `git add -f .delix/card`'ın üç hook'u
  kapattığını, `git config core.bare true` ve `core.worktree`'nin kapatmadığını üretti. Bu repoda ana checkout
  plugin'in kaynağıdır (`directory` marketplace); kurulu kopya `~/.claude/plugins/cache/` altındadır, ana checkout'a
  yazım hook'u yalnız `--plugin-dir` oturumunda ya da `plugin update`'ten sonra değiştirir (update'in çalışma ağacını
  mı HEAD'i mi kopyaladığı doğrulanmadı).
- Dispatch uygulayıcıyı `--permission-mode auto` ile açar (`skills/dispatch/SKILL.md:58-59`): Bash yollarını o
  oturumda izin istemi değil auto mode sınıflandırıcısı görür. Bash kuralı kelime denetimidir, kapatılamaz: `sed -i`,
  `python3 -c` ve `dd` aynı yazımı kuralın dışında yapar.
- Sır yok.

## 7. Acceptance criteria (DoD)
- [ ] REQ-1'in her senaryosu için `tests/gitdir_gate_tests.sh`'te test; var olan test dosyası değişmez.
  `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` yeşil, CI yeşil.
- [ ] Testler Mac'teki python3 3.9.6 ve 3.13 shim'iyle koşar (CI 3.12).
- [ ] Lead'in repro'su (`.git`'e Write, ardından `docs/delix/STATE.json`) birleşmiş kodda deny verir.
- [ ] REQ-2 ve REQ-3 metin denetimi; `bash tests/site_tests.sh` yeşil.
- [ ] Hook kartı ve sürüm kartı: qa ACCEPT, security CLEAN + 🔐 kullanıcı onayı; belge kartı: qa ACCEPT.

## 8. Open questions
- (yok)

## 9. Decisions
- **K358** (kullanıcı, 2026-11-20, geri alınır) Açık 1 (Write ile `.git`) düzeltilir, açık 2 (Bash yazımı worktree
  dışı) Bilinen sınır olarak yazılır. Alternatifler: ikisini de düzeltmek (`bash_gate.py` büyür, `sed -i` ve
  `python3 -c` yine dışarıda), ikisini de belgelemek (Write/Edit tek çağrıyla hook'ları kapatabilir kalır). Kullanıcıya
  sorulan gerekçede "Bash'te izin istemi var" deniyordu; dispatch oturumunda (`--permission-mode auto`) bu doğru değil
  (security Medium, rev 3), kapı 1'de kullanıcıya söylendi.
- **K359** (kullanıcı, 2026-11-20, geri alınır) Düzeltme yazma kapısındadır. Alternatif: `card_path` bozuk git'te fail
  closed (üç korunan dosya; issue #8 ayrımı, yani deponun getirdiği kartın pasif kalması, yeniden sınanır).
- **K360** (lead, geri alınır) Desen yalnız `.git/**`'dir: `_match_one` bunu `.git`'in kendisine ve altına eşler,
  `src/.git`'e eşlemez (prototipte ölçüldü). Kural `docs/delix/**`'ten sonra, Files izninden önce durur. Neden:
  çözülemeyen yol ve bozuk `delix.json` bugünkü metinlerini korur; kart `.git`'i listeleyerek açamaz.
- **K361** (lead, geri alınır; rev 3'te değişti) Bash ile `.git`'i değiştirmek reddedilmez, belgelenir. Neden: Bash
  zaten `.delix/card`'ı silebiliyor ve `git add -f` ile izletebiliyor (README push kuralı listesi); kelime denetimi
  bunları kapatamaz. Write/Edit ise modelin dosya yazdığı asıl araçtır ve yolu sabit bir kuralla denetlenir; fark
  buradadır. Rev 1'deki "Write izin istemi olmadan çalışır, Bash istem ister" gerekçesi dispatch oturumunda geçerli
  değil: `--permission-mode auto`'da ikisinde de istem yok (security Medium).
- **K362** (lead, geri alınır; rev 2'de değişti) Kartlar: 🔐 hook kartı (REQ-1; `scripts/write_gate.py`, yeni test
  dosyası), belge kartı (REQ-2, REQ-3'ün belge kısmı; README, README.tr, dört site sayfası, CHANGELOG), 🔐 sürüm kartı
  (0.7.4). Dalga 1: hook ve belge kartı paralel (ortak dosya yok); dalga 2: sürüm. Dalga 1, T058 birleşip Spec D
  kapandıktan sonra açılır; taban T058'in merge commit'idir, satır numaraları dispatch'te o tabana karşı denetlenir.
  Neden: T058 CHANGELOG `## Unreleased`'ı ve dört site sayfasını değiştiriyor (architect P1). Kart numaraları T058'den
  sonra.
- **K363** (lead, geri alınır) Sürüm `0.7.4`: var olan kapıya bir ret kuralı; yeni komut, rol ya da kapı yok (Spec D'nin
  0.7.3'üyle aynı sınıf).
- **K364** (lead, geri alınır; rev 3'te değişti) Deny metni yalnız `.delix/` dışlamasının Bash komutunu verir, "git
  komutu kullan" demez. Neden: kart ana checkout'taysa `.git/info/exclude`'a Write/Edit artık reddedilir (implement
  skill'i `.delix/`'in bu dosyayla dışlandığını söylüyor, `skills/implement/SKILL.md:17-18`); bağlı worktree'de dosya
  cwd dışında olduğundan yol bugün de Bash'tir. Genel bir "git kullan" yönlendirmesi uygulayıcıyı hook'ları kapatan
  `git add -f .delix/card` gibi yollara iterdi (security Low).
- **K365** (lead, geri alınır) Rev 2 ve rev 3 farkı yeniden incelenmedi: değişiklik belge metni ve deny metnidir, kural
  ve yeri aynı kaldı. Hook kartının ve belge kartının incelemesinde bakılır.

Lead prototipi (2026-11-20, birleşmiş main `68187e1`, rev 1 deny metniyle): `write_gate.py`'ye 5 satır; Python 3.9.6
ve 3.13.13'te 16 `.git` biçimi allow → deny, 6 izin kontrolü ve 3 başka kural kontrolü değişmedi, Bash
`printf junk > .git` allow kaldı; 3.9.6'da 18 test dosyasının hepsi, 3.13.13'te yazma kapısının 3 test dosyası
`ALL PASSED`.
