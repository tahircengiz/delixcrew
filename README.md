# ekip — Claude Code için ekip düzeni

`ekip`, tek oturumda "aç, klasör seç, geçmişi oku, devam et" döngüsünü gerçek bir yazılım ekibinin iş bölümüne
çevirir: **orkestratör** oturum grill ile tech spec yazar, işi görev kartlarına böler, her kartı kendi worktree'sinde
çalışan bir **uygulayıcı** oturumuna verir, **salt-okunur inceleyicilerle** (kalite, güvenlik) denetler. İnsan yalnız iki
kapıda devrededir: **spec onayı** ve **PR merge**. Kısıtlar prompt'ta değil harness'tadır: inceleyici rollerin `tools`
listesinde yazma aracı yoktur, plugin hook'ları korunan yollara yazmayı ve test dosyası değiştirmeyi engeller, Stop
hook'u testler geçmeden uygulayıcı turunu kapatmaz.

Tasarım ve kanıt: [tech spec](docs/spec/ekip-tech-spec.md) · [araştırma raporu](docs/research/reports/Çoklu%20ajan%20yazılım%20ekibi%20orkestrasyonu.md) · kararlar [STATUS.md](STATUS.md).

## Kurulum (yerel geliştirme)

```bash
claude --plugin-dir /Users/tacengiz/Documents/projects/prj_Ekip
```

Kalıcı kurulum için bir marketplace girdisi gerekir (henüz yok). Doğrulama: `claude plugin validate .`;
hook testleri: `bash tests/hook_testleri.sh`; davranış testleri: `claude plugin eval . --trust-plugin --no-publish`
(model çağrısı yapar, maliyeti vardır).

## Akış

| Adım | Komut | Ne olur |
|---|---|---|
| 1 | `/ekip:basla <istek>` | Bağlam okunur; **boy** (S/M/L: süreç ağırlığı) ve **kademe** (1/2/3: kapılar) önerilir; `docs/ekip/` kurulur. S ise tek kart. |
| 2 | `/ekip:spec` | Grill (tek soru, önerili) → `docs/ekip/SPEC.md` (SHALL + WHEN/THEN); `mimar` (+ Kademe 3'te `guvenlik`) inceler; L'de EGM. **Kapı 1.** |
| 3 | `/ekip:dagit` | `mimar` kartları ve wave planını yazar; çakışma kontrolü; dispatch prompt'ları; uygulayıcı oturumları (en çok 3 paralel). |
| 4 | `/ekip:uygula <kart>` | Uygulayıcı oturumda: test-first, yalnız kartın dosyaları, PR, `.ekip/rapor.md`. |
| 5 | `/ekip:denetle <kart>` | Deterministik kapılar → `kalite` (+ `guvenlik`) sıfır bağlamla → ≤ 3 düzeltme turu → **Kapı 2 (merge, insan).** |
| 6 | `/ekip:kapat` | STATUS/CHANGELOG, ölçüm (maliyet, tur), drift kontrolü, onaylı bellek yazımı, worktree temizliği. |
| her an | `/ekip:durum` | Salt-okunur pano: wave · kart · rol · kademe · status · tur · PR · maliyet · son rapor · bekleyen kapı (🔐, merge) tablosu sohbete ve `docs/ekip/PANO.md`'ye. `ekip-izleyici` monitor'ı `/ekip:dagit`'ten sonra değişimleri görev paneline yazar. |

## Roller

| Rol | Birim | Yetki | Model |
|---|---|---|---|
| orkestratör | ana oturum | kod yazmaz | üst |
| `ekip:mimar` | subagent | Read, Grep, Glob | opus |
| uygulayıcı (backend / frontend / ui-ux rol notu) | ayrı oturum, worktree | tümü; korunan yol ve var olan test dosyası yalnız kartın Files listesinde (korunan yol ek olarak 🔐 Onay satırıyla) açık, kart ve `docs/ekip/**` hook'la engelli | sonnet |
| `ekip:kalite` | subagent | Read, Grep, Glob | sonnet |
| `ekip:guvenlik` | subagent | Read, Grep, Glob + salt-okunur tarayıcı Bash | opus |
| `ekip:arayici` | subagent | Read, Grep, Glob | haiku |

## Proje tarafı dosyalar

`docs/ekip/ekip.json` (test komutu, korunan yollar, test yolları, paralel üst sınır), `docs/ekip/SPEC.md`,
`docs/ekip/tasks/T<nnn>-<slug>.md`, `docs/ekip/STATE.json`, `docs/ekip/PANO.md` (üretilir, salt-okunur). Uygulayıcı worktree'sinde `.ekip/kart` (hook'ları
aktifleştirir), `.ekip/rapor.md`, `.ekip/test-sonucu.txt`, `.ekip/kanit/`.

## Bilinen sınırlar

Plugin agent'ları `permissionMode`, `hooks`, `mcpServers` alanlarını yok sayar (kısıt `tools` + `hooks/hooks.json`).
Hook'lar plugin kurulu her oturumda yüklenir; uygulayıcı kapıları yalnız `cwd/.ekip/kart` varsa, inceleyici kapıları
yalnız `agent_type` `ekip:*` ise çalışır. Deneysel Agent Teams kullanılmaz. Plugin monitor'ı (`ekip-izleyici`) `-p` oturumlarında başlamaz ve
kapatılan plugin'le durmaz (oturum sonunda durur); `/ekip:durum` ise `-p`'de de çalışır. `gitleaks` kuruluysa commit öncesi sır
taraması yapılır; yoksa `.ekip/uyarilar.log`'a not düşer.

Yazma kapısı (`scripts/yazma_kapisi.py`) yalnız Write/Edit/MultiEdit/NotebookEdit araçlarını görür; uygulayıcının Bash
ile dosya yazması (`echo >`, `sed -i`, `tee`) bu hook'un kapsamı dışıdır (`bash_kapisi.py` yalnız `.env` yönlendirmesini
ve inceleyici Bash'ini keser). Bu yüzden kart dosyası, `docs/ekip/**` ya da kartta onaysız korunan yol değişikliği
`ekip:kalite` incelemesinde diff'ten bulgu sayılır. Kademe 3 izni kartın başlık tablosundan sonraki
`**🔐 Onay:** <YYYY-MM-DD> <kim>` satırıyla açılır; bu satırı yalnız orkestratör, kullanıcının sohbetteki açık "evet"inden
sonra yazar ve main'e commit eder.
