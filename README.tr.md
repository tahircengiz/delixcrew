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
| 2 | `/delixcrew:spec` | Grill (tek soru, önerili) → `docs/delix/SPEC.md` (SHALL + WHEN/THEN); `architect` (+ Tier 3'te `security`) inceler; L'de EGM. **Kapı 1.** |
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

## Bilinen sınırlar

Plugin agent'ları `permissionMode`, `hooks`, `mcpServers` alanlarını yok sayar (kısıt `tools` + `hooks/hooks.json`).
Hook'lar plugin kurulu her oturumda yüklenir; uygulayıcı kapıları yalnız `cwd/.delix/card` varsa, inceleyici kapıları
yalnız `agent_type` `delixcrew:*` ise çalışır. Deneysel Agent Teams kullanılmaz. Plugin monitor'ı yok: eski izleyici pilotta
ve 3 teşhis koşusunda hiç başlamadı, 2026-11-01'de kaldırıldı (retro A9, K35). `/delixcrew:status` `-p`'de de çalışır.
`gitleaks` kuruluysa commit öncesi sır taraması yapılır; yoksa `.delix/warnings.log`'a not düşer.

Yazma kapısı (`scripts/write_gate.py`) yalnız Write/Edit/MultiEdit/NotebookEdit araçlarını görür; uygulayıcının Bash
ile dosya yazması (`echo >`, `sed -i`, `tee`) bu hook'un kapsamı dışıdır (`bash_gate.py` yalnız `.env` yönlendirmesini
ve inceleyici Bash'ini keser). Worktree (cwd) dışına çıkan yol her zaman reddedilir (A13, K42); yol eşleşmeleri cwd'ye
göredir. Bu yüzden kart dosyası, `docs/delix/**` ya da kartta onaysız korunan yol değişikliği `delixcrew:qa` incelemesinde
diff'ten bulgu sayılır. Tier 3 izni kartın başlık tablosundan sonraki `**🔐 Approved:** <YYYY-MM-DD> <kim>` satırıyla
açılır; bu satırı yalnız orkestratör, kullanıcının sohbetteki açık "evet"inden sonra yazar ve main'e commit eder.

## Lisans

MIT, bkz. [LICENSE](LICENSE). Kaynak ve issue'lar: <https://github.com/tahircengiz/delixcrew>.
