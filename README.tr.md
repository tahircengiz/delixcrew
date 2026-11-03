# delix — Claude Code için ekip düzeni

**Spec first. Agents build. You hold the gates.**

`delix`, tek oturumda "aç, klasör seç, geçmişi oku, devam et" döngüsünü gerçek bir yazılım ekibinin iş bölümüne
çevirir: **orkestratör** oturum grill ile tech spec yazar, işi görev kartlarına böler, her kartı kendi worktree'sinde
çalışan bir **uygulayıcı** oturumuna verir, **salt-okunur inceleyicilerle** (qa, security) denetler. İnsan yalnız iki
kapıda devrededir: **spec onayı** ve **PR merge**. Kısıtlar prompt'ta değil harness'tadır: inceleyici rollerin `tools`
listesinde yazma aracı yoktur, plugin hook'ları korunan yollara yazmayı ve test dosyası değiştirmeyi engeller, Stop
hook'u testler geçmeden uygulayıcı turunu kapatmaz.

English version: [README.md](README.md). Tasarım ve kanıt: [tech spec](docs/spec/ekip-tech-spec.md) ·
[araştırma raporu](docs/research/reports/Çoklu%20ajan%20yazılım%20ekibi%20orkestrasyonu.md) · kararlar [STATUS.md](STATUS.md).
Skill'ler kullanıcının dilinde cevap verir; etiketler, durum değerleri ve karar kelimeleri İngilizce kalır.

## Gereksinimler

- **Claude Code** (plugin marketplace desteğiyle); 2.1.309 ile denendi, eski sürümler denenmedi.
- `PATH`'te **`python3`** (3.9 ile denendi). Hook'lar Python betiğidir ve hata olunca engeller; python3 yoksa her
  oturumda her Write, Edit ve Bash çağrısı `delixcrew: python3 not found on PATH …` satırıyla engellenir.
- **`git`**: uygulayıcı oturumlar kart dallarında, worktree'lerde çalışır.
- İsteğe bağlı: **`gh`** (GitHub CLI, oturum açık) PR açmak ve okumak için; remote yoksa commit'ler kart dalında kalır ve
  rapor `**PR:** none` yazar. **`gitleaks`**: uygulayıcının her commit'inden önce sır taraması; yoksa
  `.delix/warnings.log`'a not düşülür.

GitHub SSH anahtarı gerekmez: `marketplace add` önce SSH'ı dener, olmazsa HTTPS'e geçer.

## Kurulum

GitHub'dan (Desktop ve terminal, `--plugin-dir` gerekmez):

```bash
claude plugin marketplace add tahircengiz/delixcrew
```

```bash
claude plugin install delixcrew@delixcrew
```

Yerel klondan: `claude plugin marketplace add /path/to/delix`, sonra aynı `install` komutu. Marketplace tanımı
[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). İki kurulum da plugin'i Claude'un plugin
cache'ine sürüm başına bir klasör olarak kopyalar; kurulum yalnız `plugin.json` sürümü değişince güncellenir:
`claude plugin marketplace update delixcrew` (GitHub; yerel klasör doğrudan okunur), sonra
`claude plugin update delixcrew@delixcrew`, ardından Claude'u yeniden başlat. Sürüm artmadan yapılan yerel değişiklik
kurulu kopyaya ulaşmaz, `git pull` tek başına yetmez; denemek için `claude --plugin-dir /path/to/delix` klasörü yerinde okur.
0.4.0'dan önce `delix` plugin adıyla (ya da `delix-local` marketplace adıyla) kurduysan: [CHANGELOG](CHANGELOG.md#040--2026-11-03).
Doğrulama (CI her push ve PR'da da koşar): `claude plugin validate .`; hook testleri: `bash tests/hook_tests.sh`; pano testleri:
`bash tests/board_tests.sh`; davranış testleri: `claude plugin eval . --trust-plugin --no-publish` (model çağrısı yapar,
maliyeti vardır).

### Eşlikçi: delix-board

[`delix-board`](plugins/delix-board/README.md) aynı marketplace'te ayrı, salt-okunur bir mod: sohbetin yanında canlı
pane (pano, uzun koşular, kart ayrıntısı, ölçüm grafikleri), istem üstünde band ve koşu bitince toast. delix'in çalışması
için gerekmez; headless oturumlarda hiçbir şey çizmez.

```bash
claude plugin install delix-board@delixcrew
```

![Terminalde delix-board](plugins/delix-board/assets/board-terminal-pano.png)

## Akış

| Adım | Komut | Ne olur |
|---|---|---|
| 1 | `/delixcrew:start <istek>` | Bağlam okunur; **size** (S/M/L: süreç ağırlığı) ve **tier** (1/2/3: kapılar) önerilir; `docs/delix/` kurulur. S ise tek kart. |
| 2 | `/delixcrew:spec` | Grill (tek soru, önerili) → `docs/delix/SPEC.md` (SHALL + WHEN/THEN); `architect` (+ Tier 3'te `security`) inceler; L'de EGM. Yalnız UI işinde bir design system adımı: spec `DESIGN.md`'ye (ya da repodaki token dosyasına) bağlanır, ikisi de yoksa `DESIGN.md` üretilir. **Kapı 1.** |
| 3 | `/delixcrew:dispatch` | `architect` kartları ve wave planını yazar; çakışma kontrolü; dispatch prompt'ları; uygulayıcı oturumları (en çok 3 paralel). |
| 4 | `/delixcrew:implement <kart>` | Uygulayıcı oturumda: test-first, yalnız kartın dosyaları, PR, `.delix/report.md`. |
| 5 | `/delixcrew:review <kart>` | Deterministik kapılar → `qa` (+ `security`) sıfır bağlamla → ≤ 3 düzeltme turu → **Kapı 2 (merge, insan).** |
| 6 | `/delixcrew:close` | STATUS/CHANGELOG, ölçüm (maliyet, tur), drift kontrolü, onaylı bellek yazımı, worktree temizliği. |
| kısa yol | `/delixcrew:verify <dal\|commit\|dizin>` | Kartsız yapılmış işi (tek oturum ya da sen) **yalnız doğrular** (K43): gitleaks, yerel test, uzak **izole** birim testi (ayrı dizin + ayrı imaj, canlı stack'e dokunmaz), istenirse `--full`; `qa` (+ `security`) **tek geçiş**, düzeltme turu yok → `docs/delix/verifications/<tarih>-<ad>.md` raporu (ACCEPT / FIX, 🔐) ve `STATE.json.verifications`. S/M + iyi tarif + Tier ≤ 2 işte `/delixcrew:start` bunu önerir; tam akış Tier 3 / paralel kart / belirsiz spec'e. |
| her an | `/delixcrew:status` | Salt-okunur pano: wave · kart · rol · tier · status · tur · PR · maliyet · son rapor · bekleyen kapı (🔐, merge) tablosu sohbete; istenirse (`--write`) `docs/delix/BOARD.md`'ye (git'e girmez). |

## Roller

| Rol | Birim | Yetki | Model |
|---|---|---|---|
| orkestratör | ana oturum | kod yazmaz | üst |
| `delixcrew:architect` | subagent | Read, Grep, Glob | opus |
| uygulayıcı (backend / frontend / ui-ux / devops / docs rol notu) | ayrı oturum, worktree | tümü; korunan yol ve var olan test dosyası yalnız kartın Files listesinde (korunan yol ek olarak 🔐 Approved satırıyla) açık, kart ve `docs/delix/**` hook'la engelli | sonnet |
| `delixcrew:qa` | subagent | Read, Grep, Glob | sonnet |
| `delixcrew:security` | subagent | Read, Grep, Glob + salt-okunur tarayıcı Bash | opus |
| `delixcrew:scout` | subagent | Read, Grep, Glob | haiku |

## Proje tarafı dosyalar

`docs/delix/delix.json` (test komutu, korunan yollar, test yolları, paralel üst sınır, `verify` uzak izole koşu bloğu),
`docs/delix/SPEC.md`, `docs/delix/tasks/T<nnn>-<slug>.md`, `docs/delix/STATE.json` (kartlar + `verifications` kayıtları),
`docs/delix/verifications/<tarih>-<ad>.md|.patch` (`/delixcrew:verify` raporu ve yaması), `docs/delix/BOARD.md` (yalnız istenince
üretilir, `.gitignore`'da). Uygulayıcı worktree'sinde `.delix/card` (hook'ları aktifleştirir), `.delix/report.md`,
`.delix/test-result.txt`, `.delix/evidence/`.

## Geri bildirim

delixcrew'un kendisi sorun çıkardığında (bir hook doğru işi reddeder, bir skill adımı yazıldığı gibi uygulanamaz, bir
plugin sınırını elle aşarsınız) sorunun yerel bir taslağını tutabilir; bunu bu repoya GitHub issue olarak
gönderebilirsiniz. Siz kendi terminalinizden göndermedikçe makinenizden hiçbir şey çıkmaz.

**Varsayılan kapalı.** Kendi terminalinizde açıp kapatırsınız; betik plugin'in kurulum dizinindedir, marketplace
kurulumunda `~/.claude/plugins/cache/delixcrew/delixcrew/<version>/scripts/feedback.py`:

```bash
python3 <plugin dizini>/scripts/feedback.py enable --terms acme,example-corp
```

`--terms` redakte edilecek kendi kelimelerinizi ekler (müşteri adı, kod adı). `status` açık mı, kuyruk dizini ve taslak
sayısını gösterir; `disable` kapatır. Kapalıyken hiçbir şey yazılmaz: `/delixcrew:feedback note`
`delixcrew feedback is off; enable: python3 <path>/feedback.py enable` satırını gerçek yolla gösterir;
`/delixcrew:close` ve `/delixcrew:review` sessiz kalır. Taslaklar
`~/.claude/delixcrew/feedback/` altında durur (`DELIXCREW_FEEDBACK_DIR` ile değişir), asla proje reposunda değil.

**Akış.**
1. Taslağı `/delixcrew:feedback note` (bu sohbetteki bir bulgu) ya da yukarıdaki üç olaydan biri yaşandıysa
   `/delixcrew:close` ve `/delixcrew:review` oluşturur. Tekrarlanan bulgu yeni taslak açmaz, sayacı artırır.
2. `/delixcrew:feedback review` her taslağı yayınlanacağı haliyle **aynen** gösterir (repo, label, başlık, gövde);
   `VERDICT:` ve `HASH:` satırlarıyla.
3. Göndermek için sohbette kimliğiyle cevap verin: `evet F003` (ya da `yes F003`). Kimliksiz "evet", "hepsini gönder" ya
   da bir dosyada yazan "approved" onay değildir. Claude size tek bir komut verir:
   `python3 <plugin dizini>/scripts/feedback.py send F003 --confirm <hash>`.
4. Bunu **kendi terminalinizde** çalıştırın. Kuyruk dizinini ve tam metni yeniden basar, `SEND <hash>` yazmanızı
   bekler. Önizlemeden sonra metin değiştiyse durur ve yeniden önizleme ister.

Claude göndermez: hook'lar her oturumda `feedback.py send`'i, `feedback.py`'yi `script`, `expect`, `unbuffer` ya da
`pty.spawn` altında çalıştırmayı, delixcrew'u hedefleyen `gh issue create|comment|edit` ve `gh api … issues`
komutlarını ve kuyruk dizinine Write/Edit'i `delixcrew: feedback is sent only by the user from their own terminal`
mesajıyla reddeder.

**Gönderim için gerekenler:** `PATH`'te `gitleaks` ve oturumu açık `gh`. `gitleaks` yoksa her taslak `BLOCKED` olur;
`gh` yoksa taslak kuyrukta kalır ve `send` 7 ile çıkar. Hedef repo sabit `tahircengiz/delixcrew`'dur; `send` issue
açmadan önce taslağın parmak izi satırını (`delixcrew-fp: …`) arar, bu satırı taşıyan bir issue varsa ikincisini açmaz,
o URL'yi kaydeder. GitHub'da elle de issue açabilirsiniz; issue formları aynı başlıkları sorar.

**Ne redakte edilir** (önizlemeden önce, başlık dahil): kısa bir izinli liste (`github.com`, `code.claude.com`,
`docs.anthropic.com`, `anthropic.com`, `example.*`, `*.example`, `*.test`, `*.invalid`, `localhost`) dışındaki her host
adı, ör. `build.example-corp.dev` → `<redacted:host>`; belge aralıkları ve loopback dışındaki IP adresleri
(`10.1.2.3` → `<redacted:ip>`); MAC ve e-posta adresleri; ev dizini yollarının kullanıcı kısmı (`/Users/<siz>/x` →
`~/x`) ve diğer her mutlak yol (`/srv/app` → `<redacted:path>`); kullanıcı adınız ve makine adınız; taslakların geldiği
projelerin adları (klasör adı, git remote sahibi ve repo) ve `--terms` kelimeleriniz.

**Taslağı ne engeller** (`VERDICT: BLOCKED: <neden>`, `send` 4 ile çıkar; sır değeri basılmaz): ham ya da redakte
metinde `gitleaks` bulgusu, ya da `gitleaks`'in olmaması, hata vermesi, zaman aşımı; görünmez Unicode kontrol karakteri
(zero-width, bidi); 32+ karakterlik opak dizi (`[A-Za-z0-9+=_-]`; tam git SHA'sı da takılır, kısasını kullanın);
15'ten fazla kod satırı; 8 KB'tan büyük gövde; redaksiyondan sonra hâlâ redaksiyon kuralına uyan bir şey.

**Kalan risk.** Hook'lar göndermenin *bilinen* yollarını kapatır; her şeyi engellemez. Claude sizin `gh` oturumunuzla
çalışır ve gizlenmiş bir komut (base64'ten kurulan komut, dosyaya yazılmış bir sarmalayıcı, `gh` dışı bir HTTP isteği)
desen eşleyen bir hook'u aşabilir. Bu, delixcrew olsun olmasın her Claude oturumu için geçerlidir. Daha güçlü bir koruma
isterseniz kendi `settings.json`'unuza bir deny kuralı ekleyin; delixcrew bunu yalnız önerir, ayarlarınızı değiştirmez:

```json
{ "permissions": { "deny": ["Bash(gh issue create:*)", "Bash(gh api:*)"] } }
```

## Bilinen sınırlar

Plugin agent'ları `permissionMode`, `hooks`, `mcpServers` alanlarını yok sayar (kısıt `tools` + `hooks/hooks.json`).
Hook'lar plugin kurulu her oturumda yüklenir; uygulayıcı kapıları yalnız `cwd/.delix/card` varsa, inceleyici kapıları
yalnız `agent_type` `delixcrew:*` ise çalışır. Deneysel Agent Teams kullanılmaz. Plugin monitor'ı yok: eski izleyici pilotta
ve 3 teşhis koşusunda hiç başlamadı, 2026-11-01'de kaldırıldı (retro A9, K35). `/delixcrew:status` `-p`'de de çalışır.
`gitleaks` kuruluysa commit öncesi sır taraması yapılır; yoksa `.delix/warnings.log`'a not düşer.

Yazma kapısı (`scripts/write_gate.py`) yalnız Write/Edit/MultiEdit/NotebookEdit araçlarını görür; uygulayıcının Bash
ile dosya yazması (`echo >`, `sed -i`, `tee`) bu hook'un kapsamı dışıdır (`bash_gate.py` yalnız korunan yollara
yönlendirme, `cp`, `mv` ve `tee`'yi, inceleyici Bash'ini ve her oturumda bilinen geri bildirim gönderme yollarını keser;
bkz. [Geri bildirim](#geri-bildirim)). Worktree (cwd) dışına çıkan yol her zaman reddedilir (A13, K42); yol eşleşmeleri cwd'ye
göredir. Bu yüzden kart dosyası, `docs/delix/**` ya da kartta onaysız korunan yol değişikliği `delixcrew:qa` incelemesinde
diff'ten bulgu sayılır. Tier 3 izni kartın başlık tablosundan sonraki `**🔐 Approved:** <YYYY-MM-DD> <kim>` satırıyla
açılır; bu satırı yalnız orkestratör, kullanıcının sohbetteki açık "evet"inden sonra yazar ve main'e commit eder.

## Lisans

MIT, bkz. [LICENSE](LICENSE). Kaynak ve issue'lar: <https://github.com/tahircengiz/delixcrew>.
