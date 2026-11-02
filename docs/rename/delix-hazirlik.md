# delix'e geçiş hazırlığı (ekip → delix, TR → EN)

**Durum:** uygulandı (2026-11-02, dal `claude/delix-rename-e7f96a`, STATUS §5 K47–K49); §4.5–4.7 bekliyor. Bu dosya o oturumun girdisiydi.
**Karar:** plugin adı `delix` (kullanıcı, 2026-11-02). Terimler İngilizceye çevrilir; ardından marketplace ve GitHub
public.

## 1. Açık sorular (rename'den önce cevaplanmalı)

1. **Şirket adı ile plugin adı aynı mı olacak?** `delix` zaten şirket markası (delix.dev, `prj_DelixSite`; ürünler
   Garage, ModelServ, LLMScale; her ürünün kendi rengi var). Seçenekler:
   - a) Plugin adı `delix`; komutlar `/delix:start`. Kısa ama sonradan ikinci bir delix plugin'i aynı ada sığmaz.
   - b) Marketplace `delix`, plugin bir ürün adı (`delix/<ürün>`), komutlar `/<ürün>:start`. Diğer ürünlerle aynı
     desen.
   - Önerim: **a**, eğer plugin delix'in Claude tarafındaki tek ürünü kalacaksa; değilse **b**.
2. **Logo:** bağımsız yeni logo (kullanıcı, 2026-11-02); şimdilik logosuz devam. İki konsept turu
   [logo-konseptler/](logo-konseptler/) altında (SVG + genel bakış PNG): tur 1 Helix / Wordmark / Gates, tur 2 (ekip
   anlamı) Huddle / Crew / Round table; önerilen Huddle (yukarıdan ekip toplantısı, gövdeler x'i kurar), 16 px için
   ayrı küçük boy çizimi gerekir. Yön seçilince logo-design skill'iyle kit (Phase 7).
3. **Komut dili:** İngilizceye geçiş public öncesi mi, rename ile aynı anda mı? Önerim: aynı anda (iki kez kırılma
   olmasın; LLMPortal göçü de tek sefer).

## 2. Slogan

| Aday | Not |
|---|---|
| **Spec first. Agents build. You hold the gates.** | Önerim. Üç cümlede akış ve insan kontrolü; kısa. |
| An AI engineering team with two human gates. | Ayırt edici özelliği söyler; daha düz. |
| Plan like an architect. Build like a team. Merge like an owner. | Ritmi iyi; uzun. |

Açılım (isteğe bağlı, README'de alt satır): **D**efine · **E**laborate · **L**ay out · **I**mplement · e**X**amine
(grill → spec → kartlar → uygulama → doğrulama). Şirket sloganı ("software that runs where your data lives") ayrı
kalır.

## 3. Terim envanteri ve İngilizce karşılıklar

Kaynak: repo taraması (2026-11-02, `docs/research/` hariç); "Kırılır" sütunu string karşılaştırma ya da regex ile
okunan yerleri gösterir, bunlar test ve fixture'larla birlikte aynı commit'te değişmeli.

### 3.1 Kimlik: plugin, komut, ajan

| Şimdi | Yeni | Kırılır |
|---|---|---|
| plugin `ekip`, marketplace `ekip-local`, kurulum `ekip@ekip-local` | `delix`, `delix-local`, `delix@delix-local` | `plugin.json:2`, `marketplace.json:9`, README:21,25 |
| `/ekip:basla` | `/delix:start` | eval `skill-calisti.md:4` regex |
| `/ekip:spec` | `/delix:spec` | |
| `/ekip:dagit` | `/delix:dispatch` | |
| `/ekip:uygula` | `/delix:implement` | |
| `/ekip:denetle` | `/delix:review` | |
| `/ekip:dogrula` | `/delix:verify` | |
| `/ekip:durum` | `/delix:status` | |
| `/ekip:kapat` | `/delix:close` | |
| ajan `mimar` | `architect` | `ekip_ortak.py:7-8` (`INCELEYICILER`), eval `mimar-cagrildi.md:4` |
| ajan `kalite` | `qa` | aynı + eval `kalite-cagrildi.md:4` |
| ajan `guvenlik` | `security` | aynı + `bash_kapisi.py:21` (`endswith`) |
| ajan `arayici` | `scout` | aynı |
| skill dizinleri `skills/ekip-*` | `skills/<komut>` (ör. `skills/verify`) | yalnız yol |

### 3.2 Hedef projeye yazılan yollar

| Şimdi | Yeni | Kırılır |
|---|---|---|
| `docs/ekip/` | `docs/delix/` | `ekip_ortak.py:36`, `yazma_kapisi.py:61`, `pano_uret.py:119-122` |
| `docs/ekip/ekip.json` | `docs/delix/delix.json` | |
| `docs/ekip/PANO.md` | `docs/delix/BOARD.md` | `ekip-basla` `.gitignore` satırı |
| `docs/ekip/olcum.md` | `docs/delix/metrics.md` | |
| `docs/ekip/dogrulama/` | `docs/delix/verifications/` | |
| `STATE.json`, `SPEC.md`, `tasks/`, `contracts/`, `design.md` | aynı | |
| `.ekip/` (worktree) | `.delix/` | `ekip_ortak.py:28`, `stop_kapisi.py:17`, `pano_uret.py:154,163` |
| `.ekip/kart`, `rapor.md`, `test-sonucu.txt`, `kanit/`, `uyarilar.log` | `.delix/card`, `report.md`, `test-result.txt`, `evidence/`, `warnings.log` | |
| `skills/ekip-uygula/roller/` | `skills/implement/roles/` | |
| şablonlar `gorev-karti.md`, `rapor.md` | `task-card.md`, `report.md` | |

### 3.3 Yapılandırma ve kayıt anahtarları

| Şimdi | Yeni |
|---|---|
| `test_komutu`, `ek_kontroller`, `korunan_yollar`, `test_yollari` | `test_command`, `extra_checks`, `protected_paths`, `test_paths` |
| `paralel_ust_sinir`, `inceleme_tur_ust_sinir`, `varsayilan_dal`, `pr_aciklama_bolumu` | `max_parallel`, `max_review_rounds`, `default_branch`, `pr_body_section` |
| config `dogrulama{uzak, dizin, imaj, hazirlik, birim_test, temizlik}` | `verify{remote, dir, image, setup, unit_test, cleanup}` |
| STATE `boy`, `guncelleme`, `ortam_sahibi{kart, kim, baslangic}` | `size`, `updated`, `env_owner{card, who, since}` |
| STATE `kartlar{dosya, rol, kademe, status, pr, tur, maliyet_usd}` | `cards{file, role, tier, status, pr, rounds, cost_usd}` |
| STATE `dogrulama[]{ad, tarih, taban, girdi, kademe, karar, rapor, kapilar{yerel, uzak_birim, tam}, kalite, guvenlik}` | `verifications[]{name, date, base, input, tier, verdict, report, gates{local, remote_unit, full}, qa, security}` |

Not: bugün `dogrulama` iki anlamda (config bloğu ve kayıt listesi); `verify` / `verifications` ayrımı bunu çözer.

### 3.4 Durum ve karar değerleri

| Şimdi | Yeni |
|---|---|
| status `acik, suruyor, incelemede, duzeltme, kabul, ret, eskale` | `open, in_progress, in_review, fixing, accepted, rejected, escalated` |
| `kalite`: `KABUL, KABUL_ÇEKİNCELİ, RET, ESKALE` | `ACCEPT, ACCEPT_WITH_NOTES, REJECT, ESCALATE` |
| `guvenlik`: `TEMİZ, DÜZELT, 🔐 İNSAN ONAYI` | `CLEAN, FIX, 🔐 HUMAN_APPROVAL` |
| `mimar`: `HAZIR, DÜZELT` | `READY, FIX` |
| kapı: `GEÇTİ, KALDI, koşulmadı, önceden kırmızı, ölçülmedi` | `PASS, FAIL, not run, pre-existing failure, not measured` |
| rapor `DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED` | aynı (zaten İngilizce) |

### 3.5 Şablon başlıkları ve etiketler (makine okur)

| Şimdi | Yeni | Kırılır |
|---|---|---|
| `**🔐 Onay:** <tarih> <kim>` | `**🔐 Approved:** <date> <who>` | `yazma_kapisi.py:22`, `hook_testleri.sh:46,49` |
| `**Durum:**` | `**Status:**` | `pano_uret.py:21`, `templates/rapor.md:3` |
| `## Kanıt`, `## Çekinceler / kalan iş` | `## Evidence`, `## Concerns / remaining work` | `pano_uret.py:84`, `pano_testleri.sh` |
| `## Doğrulama komutu → beklenen çıktı`, `## Yasaklar`, `## Rapor sözleşmesi` | `## Verification command → expected output`, `## Don'ts`, `## Report contract` | eval `zorunlu-alanlar.md:3` |
| `## Varsayımlar`, `## Dokunulan dosyalar`, `## İnceleme bulguları`, `## Wave planı`, `## Çakışma kontrolü`, `## Emin olmadığım`, `## Nasıl test ettim` | `## Assumptions`, `## Files touched`, `## Review findings`, `## Wave plan`, `## Conflict check`, `## Unsure about`, `## How I tested` | |
| `## Files`, `## Interfaces`, `## Steps`, `## Review Focus` | aynı | `yazma_kapisi.py:34` |

### 3.6 Kavramlar

Boy S/M/L → **Size** S/M/L · Kademe 1/2/3 → **Tier** 1/2/3 · Kapı 1/2 → **Gate** 1 (spec approval) / 2 (merge) ·
kart → **card** · tur → **round** · uygulayıcı → **implementer** · orkestratör → **orchestrator** · inceleyici →
**reviewer** · ortam kilidi → **environment lock** · wave ve rol etiketleri (backend/frontend/ui-ux) aynı.

### 3.7 Betik, test, eval adları

| Şimdi | Yeni |
|---|---|
| `ekip_ortak.py`, `yazma_kapisi.py`, `bash_kapisi.py`, `stop_kapisi.py`, `pano_uret.py` | `common.py`, `write_gate.py`, `bash_gate.py`, `stop_gate.py`, `board.py` |
| `tests/hook_testleri.sh`, `tests/pano_testleri.sh` | `tests/hook_tests.sh`, `tests/board_tests.sh` |
| CLI `--proje`, `--dosya` | `--project`, `--write` |
| eval `boy-kademe-siniflandirma`, `inceleyici-yazamaz`, `gorev-karti-formati`, `sir-reddi`, `ilgisiz-istek` | `size-tier-classification`, `reviewer-cannot-write`, `task-card-format`, `secret-refusal`, `unrelated-request` |

Python fonksiyon ve değişken adları (`kart_yolu`, `eslesir`, `INCELEYICILER` …) dosya içinde aynı commit'te çevrilir;
dış sözleşme değiller.

## 4. Rename oturumu için iş sırası

1. Worktree + dal `delix-rename`; başarı ölçütü: `claude plugin validate .` ✔, hook ve pano testleri yeşil, eval
   süiti bir kez (`--max-cost-usd 5`).
2. Tanımlayıcılar (§3) + testler ve fixture'lar aynı commit'te.
3. Metin çevirisi: skill gövdeleri, ajan prompt'ları, şablonlar, README (İngilizce ana, `README.tr.md` Türkçe).
   Skill'ler kullanıcıya kendi dilinde cevap verir. İç geçmiş (`STATUS.md`, `docs/spec`, `docs/retro`,
   `docs/research`) Türkçe kalır.
4. LLMPortal göçü: `docs/ekip` → `docs/delix`, anahtarlar §3.3'e göre; tek tüketici olduğu için uyumluluk katmanı
   yazılmaz (karar rename oturumunda teyit edilir).
5. Mac kurulumu: `ekip@ekip-local` kaldır, `delix@delix-local` kur (`/mac-change` R1, ledger satırı).
6. GitHub repo ve klasör adı (`prj_Ekip` → ör. `prj_Delix` ya da `delix-claude`); ayrı oturumda, çünkü cwd değişir.
7. Public öncesi: lisans, `gitleaks` ile tüm geçmiş taraması, `evals/sir-reddi/prompt.md:7`'deki sır benzeri
   literal'in sahte olduğunun teyidi, yayın taslağını kullanıcıya göstermek.
