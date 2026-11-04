# SPEC — Spec B: Stop gate güven çapası, izinli `cat` heredoc'u, repo yazma mesajı

> Size: **M** · Tier: 3 · Date: 2026-11-04 · Status: **approved (gate 1, 2026-11-04)** (rev 3: T026 inceleme turu 0, K217–K222)
> Source: issue [#17](https://github.com/tahircengiz/delixcrew/issues/17) (triage `accepted`; istek metni kullanıcı onaylı,
> 2026-11-04) ve lead notları (kural (c) aşırı engellemesi, yanıltıcı deny mesajı). Grill kararları K199–K202
> (kullanıcı), lead kararları K203–K214. STATUS.md K numaralarının devamıdır. Önceki spec (kapalı):
> [`archive/0.6.x-triage-fixes/SPEC.md`](archive/0.6.x-triage-fixes/SPEC.md) (K178–K198).

## 1. Goal
Stop gate bugün `delix.json` içindeki `test_command` ve `extra_checks`'i, depoda izlenmeyen yerel bir `.delix/card`
varsa shell'de çalıştırıyor. Kendi `.git`'iyle gelen bir arşiv bu koşulu sağlar (`scripts/common.py:45-47`,
`scripts/stop_gate.py:31`). Güveni depo dışına taşıyoruz: komutlar, kullanıcının kendi terminalinde bir kez onayladığı
(depo kimliği + komut hash'i) kaydıyla eşleşmedikçe çalışmaz. Yanında iki hook sürtünmesi giderilir:
- **Kural (c):** yalnız dosya yazan bir `cat` heredoc'u, gövdesinde `gh issue …` ile `delixcrew` geçtiği için reddediliyor.
- **Deny mesajı:** repo ayarı yazan `gh api` çağrıları "triage decisions…" mesajıyla reddediliyor.

Başarı: arşiv vakası ve sembolik bağlantılı `.git` vakası testte kırmızıdan yeşile döner. Normal dispatch akışı, ana
checkout'ta bir kez onay verildikten sonra değişmez.

## 2. Out of scope
- Onayı geri alma ya da listeleme komutu. README, kayıt dosyasından satır silmeyi anlatır (K208).
- Komutun çalıştırdığı depo dosyalarını hash'lemek. Onay "bu depo ve bu komut dizesi" içindir (§6).
- `DELIXCREW_FEEDBACK_DIR` / `DELIXCREW_TRIAGE_DIR` env override'ları (§8).
- Proje `.claude/settings.json`'unun kendi hook'ları ve `PATH`'i. Klasör güven diyaloğu kabul edilince bunlar zaten kod
  çalıştırabilir; çapa yalnız `delix.json` kanalını kapatır (§6).
- Sürüm artırma ve yayın. 0.6.3 kararı ayrı (K209).
- Yeni heredoc kalıpları: yalnız tek bir `cat` şekli eklenir.

## 3. Requirements (testable)

### Requirement: REQ-1 Onay anahtarı
Stop gate, komut listesini yalnız `(git_common_dir, sha256)` çifti güven kaydında varsa çalıştırır (K199):
- Komut listesi `[test_command or "pytest -q"] + extra_checks`. `delix.json` yok ya da bozuksa liste `["pytest -q"]`
  olur. Bir öğe `str` değilse (ör. `extra_checks` dizi yerine string) Stop gate hiçbir komutu çalıştırmaz ve REQ-2
  yoluna girer.
- `sha256` = listenin kanonik JSON'unun (`json.dumps(list, ensure_ascii=False, separators=(",", ":"))`) özeti.
  `h12` = `sha256`'nın ilk 12 hex karakteri.
- `git_common_dir` = `git rev-parse --git-common-dir` çıktısının gerçek yolu (realpath).

Git'in çıktısına ek olarak, depo kimliği dosya sisteminden doğrulanır; doğrulamada `os.lstat` kullanılır ve sembolik
bağlantı izlenmez (K211). `R` = `realpath(cwd)`:
- **Ana worktree:** `<cwd>/.git` sembolik bağlantı olmayan gerçek bir dizindir ve `git_common_dir` == `R + "/.git"`.
- **Bağlı worktree:** `<cwd>/.git` sembolik bağlantı olmayan düz bir dosyadır ve tek satırı `gitdir: <yol>` biçimindedir.
  Ayrıca:
  - `realpath(<yol>)` == `<git_common_dir>/worktrees/<ad>` olmalı (`<ad>` bu yoldan alınır);
  - `<git_common_dir>/worktrees/<ad>/gitdir` dosyasının içeriği (strip edilmiş) == `R + "/.git"`;
  - karşılaştırmada cwd tarafında `.git` çözülmez.
- Başka her durumda `trust_key` `None` döner ve hiçbir komut çalışmaz.

Bütün git çağrıları `card_path` ile aynı biçimdedir: `-c core.fsmonitor=false`, stdin DEVNULL, 5 sn timeout. Ek olarak
env'den `GIT_*` ile başlayan bütün değişkenler çıkarılır (K212). Bu kural `card_path`'in git çağrılarına da uygulanır.
#### Scenario: kendi .git'iyle gelen arşiv
- WHEN dizinde düz `git init`, izlenmeyen `.delix/card` ve `touch MARK` komutlu `delix.json` var, kayıt boş
- THEN `MARK` oluşmaz
#### Scenario: sembolik bağlantılı .git (mutlak ve göreli)
- WHEN `.git`, onaylı bir deponun `.git` dizinine (ya da onaylı bir worktree'nin `.git` dosyasına) sembolik bağlantı;
  `delix.json` byte byte aynı
- THEN `MARK` oluşmaz
#### Scenario: onaylı ana checkout'un worktree'si
- WHEN ana checkout `(common, h)` ile onaylı ve `git worktree add` ile açılan worktree aynı komutları taşıyor
- THEN Stop gate komutu çalıştırır ve davranış bugünküyle aynıdır (geçen test → exit 0, kırık → exit 2,
  `test-result.txt`'de `[exit 1]`)
#### Scenario: delix.json değişti
- WHEN worktree dalında `test_command` değişmiş
- THEN komut çalışmaz; aynı worktree'den yeni onay verilince çalışır, ana checkout'un eski onayı geçerli kalır
#### Scenario: sahte gitfile
- WHEN `.git` dosyası onaylı bir deponun `worktrees/<ad>` dizinini gösteriyor ama o dizinin `gitdir`'i bu cwd'yi göstermiyor
- THEN komut çalışmaz
#### Scenario: GIT_DIR env
- WHEN hook env'inde `GIT_DIR` onaylı bir deponun `.git`'ini gösteriyor
- THEN sonuç env yokmuş gibi hesaplanır

### Requirement: REQ-2 Onaysız komutta Stop gate
Onay yoksa Stop gate (K201):
- hiçbir komutu çalıştırmaz;
- `.delix/test-result.txt`'ye `[not run: commands not approved, hash <h12>]` yazar;
- stderr'e üç satır yazar: onaysız olduğunu, kullanıcının kendi terminalinde çalıştıracağı tam komutu
  (`python3 <plugin>/scripts/trust.py allow`, `cwd` bu worktree) ve "write BLOCKED in .delix/report.md naming this
  command, then stop" talimatını;
- exit 2 döner.

`stop_hook_active` ya da raporda `BLOCKED`/`NEEDS_CONTEXT` varken bugünkü exit 0 yolu değişmez.

`.delix/test-result.txt` her yolda sembolik bağlantı izlenmeden yazılır: `O_NOFOLLOW`, ya da `.delix` içinde geçici
dosya + `os.replace` (K213). Dosya `O_TRUNC` olmadan açılır; `fstat` ile `st_nlink != 1` (hardlink) ise kesilmeden
kapatılır, değilse `ftruncate` edilir (K218). Hedef sembolik bağlantı ya da hardlink ise dosyaya yazılmaz ve stderr'de bir satır uyarı çıkar. Bugün bu
yol bağlantının gösterdiği dosyayı eziyor; lead bunu main'de yeniden üretti.
#### Scenario: onaysız, ilk durma
- WHEN kart yerel, kayıt boş, rapor yok
- THEN exit 2, komut çalışmadı, stderr'de `trust.py allow` geçer
#### Scenario: BLOCKED rapor
- WHEN aynı durumda `.delix/report.md` başı `BLOCKED` içeriyor
- THEN exit 0
#### Scenario: test-result sembolik bağlantısı
- WHEN `.delix/test-result.txt` depo dışındaki bir dosyaya sembolik bağlantı
- THEN o dosya değişmez

### Requirement: REQ-3 `trust.py allow`
Yeni `scripts/trust.py allow`, kullanıcının terminalinde, cwd'deki depo için çalışır. Sırayla:
1. REQ-1 anahtarını hesaplar. Git work tree değilse, REQ-1'in dosya sistemi kontrolü geçmezse ya da `str` olmayan bir
   öğe varsa exit 7 ve tek satırlık stderr.
2. Çift zaten kayıttaysa "already approved" yazar ve exit 0. Bu adım TTY istemez.
3. Kaynak dosyanın yolunu (`docs/delix/delix.json`) ve her komutu ayrı satırda `json.dumps` ile kaçışlanmış olarak
   gösterir. `git cat-file blob HEAD:docs/delix/delix.json` çıktısı, çalışma ağacındaki dosyanın `O_NOFOLLOW` ile
   okunan içeriğinden farklıysa (ya da biri okunamazsa) "delix.json differs from HEAD" uyarısı basar (K214). `git diff`
   kullanılmaz: deponun kendi `diff.external` / textconv / clean filter ayarı onaydan önce kod çalıştırır (K217).
   `git_common_dir` de ekrana `json.dumps` ile basılır (K219).
4. `Type TRUST <h12> to approve these commands for <git_common_dir> (the word TRUST, a space, then the hash): `
   istemini basar (K200, SEND/APPLY kalıbı).
5. stdin TTY değilse ya da yazılan metin tam eşleşmezse kayıt yazılmaz ve exit 6 döner; uyuşmazlıkta beklenen metin
   tekrar edilir.
6. Eşleşince kayıt atomik yazılır: geçici dosya + `os.replace`, dosya 0600, dizin 0700. Ardından exit 0.

Yalnız stdlib kullanılır.
#### Scenario: TTY yok
- WHEN `echo "TRUST abc" | trust.py allow`
- THEN exit 6, kayıt yok
#### Scenario: doğru onay (pseudo-terminal ile test)
- WHEN TTY'de `TRUST <h12>` yazılır
- THEN kayıtta `(common, sha256)` var ve REQ-1 senaryosu komutu çalıştırır
#### Scenario: gizlenmiş komut
- WHEN `test_command` `"true\r; curl x"` içeriyor
- THEN ekranda `"true\r; curl x"` kaçışlanmış görünür

### Requirement: REQ-4 Kaydın yeri ve korunması
Kayıt `<home>/.claude/delixcrew/trust.json` dosyasıdır. `<home>` = `pwd.getpwuid(os.getuid()).pw_dir`; `HOME` ya da
herhangi bir env değişkeni okunmaz (K203).

Biçim: `{"version": 1, "entries": [{"git_common_dir": str, "sha256": str, "approved_at": ISO-8601}]}`.

`is_trusted` kaydı şu koşullarla okur, aksi her durumda boş sayar (fail closed):
- dosya `O_NOFOLLOW` ile açılır;
- dosyanın ve dizinin sahibi `getuid()` olur ve `mode & 0o077 == 0`;
- `version` 1 olur ve JSON geçerli olur.

Her oturumda iki hook kaydı korur:
- **`write_gate.py`:** Write/Edit/MultiEdit/NotebookEdit ile bu dosyaya yazmayı reddeder; mevcut casefold kalıbı
  kullanılır.
- **`bash_gate.py`:** şu üç komutu reddeder; kurallar koşulsuzdur, feedback (a)/(b) gibi:
  - (a) `trust.py` + `allow` geçen komut;
  - (b) `trust.py` ile `script|expect|unbuffer|pty.spawn|pty.fork|openpty|tmux|screen|socat|zpty` birlikte geçen komut;
  - (c) casefold edilmiş metninde `delixcrew/trust.json` geçen komut. (c) tam metne uygulanır, REQ-5 ve capture
    muafiyetleri ona dokunmaz.

Mesaj iki gate'te de ayrı ayrı literal yazılır (K210):
`TRUST_DENY = "delixcrew: Stop gate commands are approved only by the user from their own terminal"`.
#### Scenario: ajan onay vermeye çalışır
- WHEN Bash `python3 /x/scripts/trust.py allow`
- THEN deny, `TRUST_DENY`
#### Scenario: ajan kaydı yazar
- WHEN Write `~/.claude/delixcrew/Trust.json` (harf varyantı) ya da Bash `cat > /Users/u/.claude/delixcrew/trust.json <<'EOF'`
- THEN deny
#### Scenario: başkasına yazılabilir kayıt
- WHEN kayıt 0644 ya da sembolik bağlantı
- THEN `is_trusted` `False`

### Requirement: REQ-5 İzinli `cat` heredoc'u
Komutun tamamı tam olarak şu biçimdeyse, bilinen yol kurallarının hepsi yalnız ilk satıra uygulanır (K202):
- biçim: `cat[ \t]+>>?[ \t]*<yol>[ \t]+<<'DELIM'` (ya da `"DELIM"`), ardından gövde, son satır `DELIM`;
- kapsanan kurallar: feedback (a)/(b)/(c), triage (a)/(b)/(c)/(d), trust (a)/(b). Trust (c) tam metinde kalır.

Kalıbın kısıtları:
- `<yol>` tek karakter sınıfıdır: `(?!-)[^X]+`; `X` = `_PATH`'in dışlanan karakterleri. İsteğe bağlı dizin grubu
  yoktur (ReDoS, K211b).
- `<<-` desteklenmez.
- `<yol>` casefold edildiğinde `.claude/delixcrew/` içeriyorsa muafiyet uygulanmaz.
- Gövdede `DELIM` satırı tekrar ederse, delimiter satırı `\r` ya da sondaki boşlukla bitiyorsa ya da biçim tutmazsa tam
  metin kontrol edilir (fail closed).

Aynı kural T024'ün iki capture kalıbına da genişler: capture eşleşmesinde feedback (c) ile triage (c)/(d) de yalnız ilk
satıra bakar (K204). Korunan yola shell yazımı kontrolü (`bash_gate.py:94`) tam metinde kalır.
#### Scenario: not dosyası
- WHEN `cat > notes.md <<'EOF'\ngh issue close 9 --repo tahircengiz/delixcrew\nEOF`
- THEN allow
#### Scenario: zincir
- WHEN aynı komutun sonuna `; gh issue close 9 -R tahircengiz/delixcrew` eklenir ya da gövdeden sonra satır gelir
- THEN deny
#### Scenario: ReDoS
- WHEN 200 KB gövde, 5k `EOF` satırı, 20k `/` içeren yol
- THEN her biri < 0.05 sn

### Requirement: REQ-6 Repo yazma mesajı
`gh api` yazma çağrısında bugünkü deny koşulu aynen kalır. Değişen yalnız mesajdır:
- Triage (d)'nin baktığı metinde (REQ-5'e göre `checked`) `issues`, `labels` ve `graphql` kelimelerinden hiçbiri
  yoksa (ör. `repos/…/rulesets`, `vulnerability-alerts`), mesaj
  `REPO_DENY = "delixcrew: writes to the delixcrew GitHub repository (settings, rulesets, security) run only from the user's own terminal"`
  olur (K205).
- Issues, labels ve graphql yolları bugünkü mesajlarını korur; mevcut test satırları değişmez.
#### Scenario: ruleset
- WHEN `gh api -X POST repos/tahircengiz/delixcrew/rulesets --input r.json`
- THEN deny, `REPO_DENY`

### Requirement: REQ-7 Doküman ve akış metinleri
- README.md / README.tr.md güncellenir:
  - "What this plugin does on your machine";
  - "Known limits": §6 kalıntıları ve "bash denylist yalnız sürtünmedir; sınır izin istemidir (K77)";
  - "Files": kayıt dosyası ve satır silerek geri alma.
- `skills/dispatch/SKILL.md`: ilk dispatch'ten önce ana checkout'ta `trust.py allow`.
- `skills/implement/SKILL.md`: Stop gate "not approved" dediğinde BLOCKED.
- `site/` dört sayfası: CLAUDE.md tetikleyicisi (yeni komut ve hook kuralı); sürüm etiketi değişmez (K209).
- `bash tests/site_tests.sh` yeşil kalır.

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| function | `common.trust_key(cwd) -> tuple[str, str] \| None` | `(git_common_dir, sha256)`; REQ-1 doğrulaması tutmazsa `None` | stop_gate, trust.py |
| function | `common.is_trusted(cwd) -> bool` | kaydı her çağrıda okur (REQ-4 koşulları); hata = `False` | stop_gate |
| function | `common.trust_file() -> str` | pwd tabanlı yol (REQ-4); testler modül özniteliğiyle değiştirir, env ile değil | write_gate, trust.py, testler |
| CLI | `trust.py allow` | exit 0 / 6 / 7 (REQ-3) | kullanıcı |
| file | `~/.claude/delixcrew/trust.json` | REQ-4 biçimi | stop_gate, trust.py |
| const | `TRUST_DENY`, `REPO_DENY` | REQ-4 ve REQ-6 metinleri, her gate'te literal | bash_gate, write_gate, testler |

## 5. Data and migration
Yeni dosya `trust.json`; ilk kurulumda yoktur, yokluğu "onaysız" demektir. Güncelleme sonrası mevcut kullanıcıların ilk
Stop gate'i REQ-2 ile durur. Geçiş adımı `trust.py allow`'u ana checkout'ta bir kez çalıştırmaktır; README ve CHANGELOG
bunu söyler. Geri alma: plugin'in önceki sürümü; kayıt dosyası zararsız olarak kalır.

## 6. Security note
🔐 **Korunan yollar:** `scripts/stop_gate.py`, `scripts/common.py`, `scripts/bash_gate.py`, `scripts/write_gate.py`.
Lead, dispatch'ten önce ayrı bir commit'le `scripts/trust.py`'yi `docs/delix/delix.json` `protected_paths`'e ekler;
`delix.json` implementer'a kapalıdır (`docs/delix/**`). Her kartta 🔐 Approved satırı.

**Tehdit:** dosyaları, `.git`'i (dizin, dosya ya da sembolik bağlantı) ve `delix.json`'u saldırgana ait bir dizin.
Çapa yalnız `delix.json` kanalını kapatır; proje ayarlarının hook'ları ve `PATH`'i kapsam dışıdır. Bu tehdide karşı
kararlar:
- Depo kimliği git çıktısından değil dosya sisteminden (`lstat`) doğrulanır (K211).
- Git çağrıları `GIT_*` env'i olmadan yapılır (K212).
- Kayıt yolu pwd'den okunur (K203).
- Kayıt dosyası sahiplik ve izin koşullarıyla okunur.
- `test-result.txt` sembolik bağlantı izlemeden yazılır (K213).
- Onay ekranı kaçışlıdır ve HEAD'den farkı gösterir (K214).

**Kalıntılar (Known limits'e girer):**
- Onaylı bir depoda komut dizesi aynı kalıp `tests/` değişirse Stop gate çalışır; bu, kullanıcının o dalda testi
  çalıştırmasıyla eşdeğerdir.
- Silinen bir deponun ya da `prune` edilmemiş bir worktree'nin yoluna açılan yeni bir dizin eski onayı devralabilir.
- Bash denylist'i yalnız sürtünmedir: tırnak bölme, değişken, glob, `cd` sonrası göreli yol, `//`, `/./` ya da
  sembolik bağlantılı dizinle yazılmış komutlar geçer (K220). Sınır, Claude
  Code'un Bash izin istemidir (K77).
- REQ-5'in `~/.claude/delixcrew/` dışındaki yollar için açtığı yetenek, Write aracının zaten yapabildiğinden büyük değildir.

## 7. Acceptance criteria (DoD)
- [ ] Her REQ için geçen bir test var; arşiv ve sembolik bağlantılı `.git` senaryoları önce kırmızı. Doğrulama komutu:
  `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → bütün süitler geçer.
- [ ] ReDoS denemeleri (REQ-5) ölçülür ve PR'a yazılır.
- [ ] `claude plugin validate .` geçer.
- [ ] Tier 3: `qa` ACCEPT, `security` CLEAN ya da yalnız 🔐 HUMAN_APPROVAL ve kullanıcı onayı.
- [ ] PR gövdesinde "How I tested" var.

## 8. Open questions
- (izleme, kapsam dışı) `DELIXCREW_FEEDBACK_DIR` / `DELIXCREW_TRIAGE_DIR` proje `env`'iyle değişebilir; bu, write_gate
  kuyruk korumasını başka dizine kaydırır. Ayrı bir issue açılmalı.
- (canlıda kontrol, T027) Claude Code'un Bash aracı komutu zsh `eval` ile sarıyor; REQ-5 heredoc ayrıştırmasının canlıda
  aynı kaldığı implementer tarafından gerçek oturumda denenir.

## 9. Decisions
- **K199** (kullanıcı, geri alınır): onay anahtarı `git_common_dir` realpath'i + komut listesi hash'i; worktree'ler ana
  checkout'u miras alır.
- **K200** (kullanıcı, geri alınır): onay ayrı CLI `trust.py allow` ile verilir; TTY + `TRUST <h12>` yazılır; hook'lar
  ajanı engeller.
- **K201** (kullanıcı, geri alınır): onaysız komutta çalıştırma, exit 2 ile bir kez durdur, implementer BLOCKED yazar.
- **K202** (kullanıcı, geri alınır): kural (c) için tek izinli `cat > yol <<'D'` kalıbı; diğer her şekil tam metin.
- **K203** (lead, geri alınır): kayıt yolu pwd veritabanından; testler `common` modül özniteliğini runpy ile değiştirir.
- **K204** (lead, geri alınır): T024'ün capture muafiyeti (c)/(d)'yi de kapsar. Böylece "tek izinli heredoc → ilk
  satır" kuralı tek ve tutarlı olur.
- **K205** (lead, geri alınır): yeni mesaj yalnız issues/labels/graphql dışındaki `gh api` yazmalarında; mevcut test
  satırları korunur.
- **K206** (lead, 🔐): "test satırı değişmez" kuralının tek istisnası. Değişen yerler:
  - `tests/hook_tests.sh:69-76` (Stop gate);
  - `tests/trust_tests.sh` vaka 4 ve 4b (4b `delix.json`'u değiştirdiği için kendi onayını alır).

  Değişen tek şey, komut çalışmadan önce test kaydına onay eklemektir; beklenen sonuçlar aynı kalır. Kırık test vakasına
  yeni bir doğrulama eklenir: `test-result.txt` `[exit 1]` içerir ve `[not run:` içermez. Kartta satır satır listelenir.
- **K207** (lead, geri alınır): kart bölümü (dispatch'te architect kesinleştirir):
  - T026: güven çapası (`common.py`, `stop_gate.py`, `trust.py`, `write_gate.py`, `trust_tests.sh`, `hook_tests.sh`
    Stop bölümü);
  - T027: `bash_gate.py` (REQ-4 bash kuralları, REQ-5, REQ-6), testleri yeni `tests/bash_gate_heredoc_tests.sh`
    dosyasında;
  - T028: dokümanlar ve site (REQ-7); T026 ve T027'den sonra.
  - T026 ile T027 paralel çalışır, ortak dosyaları yok; mesaj sabitleri her gate'te literal.
- **K208** (lead, geri alınır): geri alma ve listeleme komutu yok; README satır silmeyi anlatır.
- **K209** (lead, geri alınır): bu spec sürüm artırmaz; 0.6.3 yayını (#36 düzeltmesi) ayrı karar, kullanıcıda.
- **K210** (lead, geri alınır):
  - `trust.py` exit kodlarını feedback/triage ile hizalar (6 = onay yok, 7 = ön koşul);
  - mesaj sabitleri gate başına literal yazılır, `FEEDBACK_DENY` gibi.
- **K211** (lead, geri alınır; architect P0 + security High, lead main'de yeniden üretti): sembolik bağlantılı `.git`.
  - Sorun: `card_path` kartı kabul ediyor, `--git-common-dir` kurbanın `.git`'ini veriyor. Bu yüzden depo kimliği
    `lstat` ile, bağlantı izlenmeden doğrulanır.
  - K211b: REQ-5 yolu tek karakter sınıfı (ReDoS).
- **K212** (lead, geri alınır): hook'ların git çağrıları `GIT_*` env'i olmadan yapılır.
- **K213** (lead, geri alınır; security Medium, main'de yeniden üretildi): `test-result.txt` sembolik bağlantı izlenmeden yazılır.
- **K214** (lead, geri alınır; security Medium): onay ekranı komutları `json.dumps` ile gösterir, `str` olmayan öğe
  exit 7 döner, `delix.json` HEAD'den farklıysa uyarı basar.
- **K217** (lead, geri alınır; T026 security High, lead dalda yeniden üretti: `diff.external` + `trustExitCode` ile
  onay reddedildiği halde yardımcı çalıştı): `trust.py` onaydan önce `git diff` çalıştırmaz; HEAD karşılaştırması
  `git cat-file blob` + Python'da bayt karşılaştırması.
- **K218** (lead, geri alınır; T026 security Low): `test-result.txt` hardlink ise kesilmez ve yazılmaz.
- **K219** (lead, geri alınır; T026 security Low): `git_common_dir` ekranda kaçışlı.
- **K220** (lead, geri alınır; T027 security Low): trust (c) alt dize kuralının atlanma biçimleri Known limits'e (T028).
- **K221** (lead, geri alınır; T026 qa P2, implementer sapması): liste olmayan `extra_checks` `[[extra]]` olarak sarılır;
  tek `str` olmayan öğe olur, onaylanamaz ve çalışmaz (REQ-1). Kart çapası 4'teki `[extra]` metni bunun yerine geçer.
- **K222** (lead, geri alınır; T026 security unsure): merge sırası T027 → T026. T026 tek başına Bash yolunu açık bırakır;
  ajan tarafı engelleri T027'dedir.
