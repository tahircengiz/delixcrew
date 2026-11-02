# ekip — Claude Code için ekip düzeni

`delix`, tek oturumda "aç, klasör seç, geçmişi oku, devam et" döngüsünü gerçek bir yazılım ekibinin iş bölümüne
çevirir: **orkestratör** oturum grill ile tech spec yazar, işi görev kartlarına böler, her kartı kendi worktree'sinde
çalışan bir **uygulayıcı** oturumuna verir, **salt-okunur inceleyicilerle** (qa, güvenlik) denetler. İnsan yalnız iki
kapıda devrededir: **spec onayı** ve **PR merge**. Kısıtlar prompt'ta değil harness'tadır: inceleyici rollerin `tools`
listesinde yazma aracı yoktur, plugin hook'ları korunan yollara yazmayı ve test dosyası değiştirmeyi engeller, Stop
hook'u testler geçmeden uygulayıcı turunu kapatmaz.

Tasarım ve kanıt: [tech spec](docs/spec/ekip-tech-spec.md) · [araştırma raporu](docs/research/reports/Çoklu%20ajan%20yazılım%20ekibi%20orkestrasyonu.md) · kararlar [STATUS.md](STATUS.md).

## Kurulum

Kalıcı (Desktop ve terminal, `--plugin-dir` gerekmez; repo yerinde okunur, kopya yok):

```bash
claude plugin marketplace add ~/Documents/projects/prj_Ekip
```

```bash
claude plugin install delix@delix-local
```

Marketplace tanımı [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json); güncelleme `git pull` sonrası
`claude plugin update delix@delix-local`. Tek seferlik deneme için `claude --plugin-dir ~/Documents/projects/prj_Ekip`
da çalışır. Mac'te kurulum `/mac-change` R1 kaydıyla yapıldı (2026-11-01, K38). Doğrulama: `claude plugin validate .`;
hook testleri: `bash tests/hook_tests.sh`; davranış testleri: `claude plugin eval . --trust-plugin --no-publish`
(model çağrısı yapar, maliyeti vardır).

## Akış

| Adım | Komut | Ne olur |
|---|---|---|
| 1 | `/delix:start <istek>` | Bağlam okunur; **boy** (S/M/L: süreç ağırlığı) ve **kademe** (1/2/3: kapılar) önerilir; `docs/delix/` kurulur. S ise tek kart. |
| 2 | `/delix:spec` | Grill (tek soru, önerili) → `docs/delix/SPEC.md` (SHALL + WHEN/THEN); `architect` (+ Kademe 3'te `security`) inceler; L'de EGM. **Kapı 1.** |
| 3 | `/delix:dispatch` | `architect` kartları ve wave planını yazar; çakışma kontrolü; dispatch prompt'ları; uygulayıcı oturumları (en çok 3 paralel). |
| 4 | `/delix:implement <kart>` | Uygulayıcı oturumda: test-first, yalnız kartın dosyaları, PR, `.delix/report.md`. |
| 5 | `/delix:review <kart>` | Deterministik kapılar → `qa` (+ `security`) sıfır bağlamla → ≤ 3 düzeltme turu → **Kapı 2 (merge, insan).** |
| 6 | `/delix:close` | STATUS/CHANGELOG, ölçüm (maliyet, tur), drift kontrolü, onaylı bellek yazımı, worktree temizliği. |
| kısa yol | `/delix:verify <dal\|commit\|dizin>` | Kartsız yapılmış işi (tek oturum ya da sen) **yalnız doğrular** (K43): gitleaks, yerel test, uzak **izole** birim testi (ayrı dizin + ayrı imaj, canlı stack'e dokunmaz), istenirse `--tam`; `qa` (+ `security`) **tek geçiş**, düzeltme turu yok → `docs/delix/verifications/<tarih>-<ad>.md` raporu (ACCEPT / FIX, 🔐) ve `STATE.json.verifications`. S/M + iyi tarif + Kademe ≤ 2 işte `/delix:start` bunu önerir; tam akış Kademe 3 / paralel kart / belirsiz spec'e. |
| her an | `/delix:status` | Salt-okunur pano: wave · kart · rol · kademe · status · tur · PR · maliyet · son rapor · bekleyen kapı (🔐, merge) tablosu sohbete; istenirse (`--write`) `docs/delix/BOARD.md`'ye (git'e girmez). |

## Roller

| Rol | Birim | Yetki | Model |
|---|---|---|---|
| orkestratör | ana oturum | kod yazmaz | üst |
| `delix:architect` | subagent | Read, Grep, Glob | opus |
| uygulayıcı (backend / frontend / ui-ux rol notu) | ayrı oturum, worktree | tümü; korunan yol ve var olan test dosyası yalnız kartın Files listesinde (korunan yol ek olarak 🔐 Approved lineyla) açık, kart ve `docs/delix/**` hook'la engelli | sonnet |
| `delix:qa` | subagent | Read, Grep, Glob | sonnet |
| `delix:security` | subagent | Read, Grep, Glob + salt-okunur tarayıcı Bash | opus |
| `delix:scout` | subagent | Read, Grep, Glob | haiku |

## Proje tarafı dosyalar

`docs/delix/delix.json` (test komutu, korunan yollar, test yolları, paralel üst sınır, `dogrulama` uzak izole koşu bloğu),
`docs/delix/SPEC.md`, `docs/delix/tasks/T<nnn>-<slug>.md`, `docs/delix/STATE.json` (kartlar + `dogrulama` kayıtları),
`docs/delix/verifications/<tarih>-<ad>.md|.patch` (`/delix:verify` raporu ve yaması), `docs/delix/BOARD.md` (yalnız istenince
üretilir, `.gitignore`'da). Uygulayıcı worktree'sinde `.delix/card` (hook'ları
aktifleştirir), `.delix/report.md`, `.delix/test-result.txt`, `.delix/evidence/`.

## Bilinen sınırlar

Plugin agent'ları `permissionMode`, `hooks`, `mcpServers` alanlarını yok sayar (kısıt `tools` + `hooks/hooks.json`).
Hook'lar plugin kurulu her oturumda yüklenir; uygulayıcı kapıları yalnız `cwd/.delix/card` varsa, inceleyici kapıları
yalnız `agent_type` `delix:*` ise çalışır. Deneysel Agent Teams kullanılmaz. Plugin monitor'ı yok: `ekip-izleyici` pilotta ve 3 teşhis koşusunda hiç başlamadı, 2026-11-01'de kaldırıldı (retro A9, K35).
kapatılan plugin'le durmaz (oturum sonunda durur); `/delix:status` ise `-p`'de de çalışır. `gitleaks` kuruluysa commit öncesi sır
taraması yapılır; yoksa `.delix/warnings.log`'a not düşer.

Yazma kapısı (`scripts/write_gate.py`) yalnız Write/Edit/MultiEdit/NotebookEdit araçlarını görür; uygulayıcının Bash
ile dosya yazması (`echo >`, `sed -i`, `tee`) bu hook'un kapsamı dışıdır (`bash_gate.py` yalnız `.env` yönlendirmesini
ve inceleyici Bash'ini keser). Worktree (cwd) dışına çıkan yol her zaman reddedilir (A13, K42); yol eşleşmeleri cwd'ye
göredir. Bu yüzden kart dosyası, `docs/delix/**` ya da kartta onaysız korunan yol değişikliği
`delix:qa` incelemesinde diff'ten bulgu sayılır. Kademe 3 izni kartın başlık tablosundan sonraki
`**🔐 Approved:** <YYYY-MM-DD> <kim>` satırıyla açılır; bu satırı yalnız orkestratör, kullanıcının sohbetteki açık "evet"inden
sonra yazar ve main'e commit eder.
