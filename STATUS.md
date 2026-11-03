# STATUS — prj_Ekip (plugin `delix`, eski adı `ekip`)

**Son güncelleme:** 2026-11-03 · **Faz:** 8 — triage spec'i onaylı (kapı 1), kartlar T010–T013 hazır, 🔐 onay ve dalga 1 dispatch bekliyor (§8). §7: 0.5.0 öz-besleme rev 3 kapandı (T001–T009 main'de, arşiv `docs/delix/archive/0.5.0-self-feeding/`); K104 sızıntıları, 0.5.0 etiketi, W0 ve uçtan uca test açık
**Hedef:** Claude Code için "ekip" plugin'i: orkestratör oturum grill ile tech spec yazar, işi rollere böler, rol
oturumlarına atar, incelemeyi ve kalite/güvenlik kontrolünü yapar. İki insan kapısı: spec onayı ve PR merge.

İşaretler: ✔ bitti · ◐ sürüyor · ◻ bekliyor · 🔐 onay gerekir

## Adımlar

| # | Adım | Durum |
|---|---|---|
| 0.1 | Mevcut kurulum taraması (vibecoding-agents, EGM, arayici/Explore, hooks) | ✔ |
| 0.2 | Grill (5 soru) ve kararlar K1–K5 | ✔ |
| 0.3 | Deep research (5 not, rapor 145 kaynak) `docs/research/` | ✔ |
| 0.4 | Tech spec v1 `docs/spec/ekip-tech-spec.md` | ✔ taslak |
| 0.5 | 🔐 Spec onayı (kapı 1) | ✔ 2026-11-01 |
| 1.1 | Plugin iskeleti: manifest, 4 ajan, 6 skill (+3 rol notu), 3 hook betiği, 7 şablon, 5 eval case, README, runbook | ✔ `claude plugin validate` geçti |
| 1.2 | Hook birim testleri `tests/hook_testleri.sh` | ✔ 15/15 |
| 1.3 | Eval süiti çalıştırma (`claude plugin eval .`) | ✔ bkz. 1.6 |
| 1.4 | İlk commit | ✔ `2645cd2` |
| 1.5 | Görünürlük: `/ekip:durum` skill'i + `PANO.md` + `ekip-izleyici` monitor (spec §14) | ✔ 2026-11-01; `tests/pano_testleri.sh` 10/10, boş projede `-p` smoke testi "kart yok" |
| 1.6 | Eval süiti 1 kez (`--max-cost-usd 10`), bulgulara göre skill description düzeltmesi | ✔ 2026-11-01: 5/5 geçti, skor 1.0, ortalama Δ 0.47, 2.92 USD, 672 sn (`evals/results/ilk.json`, gitignore'da). Description düzeltmesi gerekmedi; `boy-kademe` case'i doğal dile çevrildi, tekrar 1 koşu 0.10 USD, geçti (K27) |
| 1.7 | Mac ön koşul: `gitleaks` (`/mac-change`, R1) | ✔ 8.30.1, ledger PR prj_HomeLab #194 |
| 2.1 | Baz çizgi: LLMPortal'da 10 görev tek oturum Opus medium, `docs/ekip/olcum.md` (K16) | ✔ 2026-11-01: 10/10 görev, her biri 1 tur, toplam 9,89 USD (S 0,49–1,20; M 1,32–1,81), GTR9'da ilk denemede 10/10 yeşil; LLMPortal dalı `ekip-olcum` (2dd0080), main'e merge kullanıcıda. Birim referans: S ≈ 0,9 USD, M ≈ 1,6 USD, 1 tur |
| 2.2 | Pilot: LLMPortal'da M boy / Kademe 2 özellik uçtan uca | ✔ 2026-11-01: E.6 ekip OTP zorunluluğu (W0 + T001–T003) main'de, GTR9 623/0, ≈ 29,8 USD, ≈ 2 sa 50 dk; aynı akışla E.7 açık işleri (T004–T006) ≈ 22,7 USD, 644/0, ≈ 1,5 sa; takipler T007 1,68 / T008 0,71 USD. Ayrıntı LLMPortal `docs/ekip/olcum.md` "Ekip akışı" (K30) |
| 2.3 | Pilot: bir Kademe 3 kart interaktif + güvenlik onayı | ✔ 2026-11-01: 4 kart (T002, T003, T005, T007) interaktif oturum + 🔐 sohbet onayı, kapı 2 merge insanla; onay kaydı prj_HomeLab #195 (3ec751d) |
| 2.4 | Retro: hangi harness parçası taşıyıcı | ✔ 2026-11-01 [docs/retro/2026-11-01-pilot-retro.md](docs/retro/2026-11-01-pilot-retro.md): taşıyıcı = grill+spec+mimar, kart+dispatch, `guvenlik`, orkestratör denetimi, insan kapıları, `ekip-kapat`; yardımcı = Stop kapısı, `kalite`; doğrulanmadı = yazma/bash kapıları, rol prompt'ları; çıkarılabilir = `ekip-izleyici`, `PANO.md` dosya yazımı. 12 aksiyon A1–A12 (K32–K34) |
| 3.1 | Retro aksiyonları A1–A9 (plugin içi: skill metinleri, şablonlar, pano, monitor teşhisi) | ✔ 2026-11-01 main'e merge edildi (2690003, K35–K37) |
| 3.2 | A10 karşı ölçüm: E.7 boyutunda bir kart plugin'siz tek oturumda, LLMPortal | ✔ 2026-11-01 T006 kartı tek oturum 0,67 USD (K39); A10-b kart yok, kısa istek 0,83 USD / 1 tur / ilk yeşil (K40); A10-c tüm E.7 tek oturum 2,79 USD / 7 dk / gizli test 24/27 (K43) |
| 3.3 | A11 plugin'i Mac'e kalıcı kur (yerel marketplace, `/mac-change` R1) | ✔ 2026-11-01 `ekip@ekip-local` user kapsamı, gerçek rollback denendi (K38) |
| 3.4 | A12 tutarlılıklar (spec §7 pytest, `kalite` tests/** kuralı, LLMPortal gitleaks allowlist) | ✔ 2026-11-01 (K41) |
| 3.5 | A13 yazma kapısı: cwd (worktree) dışı yol → deny | ✔ 2026-11-02 (K42), hook testleri 31/31 |
| 4.1 | Doğrulama-yalnız kipi: `skills/ekip-dogrula` (`/ekip:dogrula <dal\|commit\|dizin>`), `/ekip:basla` kip önerisi, pano "Doğrulamalar" tablosu, spec §15, `templates/ekip.json` `dogrulama` bloğu | ✔ 2026-11-02 (K44): validate ✔, hook 31/31, pano 12/12; LLMPortal A10-c yaması üzerinde kuru koşu 1,38 USD / 3 dk 21 sn, rapor `docs/ekip/dogrulama/2026-11-02-a10c-e7.md` |
| 4.2 | A2 ölçümü ilk gerçek kartta: LLMPortal T009 (B04 rotate spend, S · K2) tam akış; gerçek Orta bulguda düzeltme turu `--resume` vs yeni `-p` | ✔ 2026-11-02 (K45): yeni `-p` **0,44 USD** / 5 tur / 40 sn, `--resume` 1,11 / 7 / 40 sn, ikisi yeşil; kart toplamı ≈ 9,3 USD (Opus eşdeğeri), kart onayı → merge 14 dk, kapı dışı müdahale 0; `ekip-denetle`/`ekip-dagit` reçetesi güncellendi; LLMPortal `olcum.md` "A2" |
| 4.3 | `dogrulama.birim_test` test başına ortam değişkeni (K45 yan bulgu 3): `templates/ekip.json` `$comment_birim_env`, `ekip-dogrula`/`ekip-denetle` notu, spec §15; LLMPortal `ekip.json` `session_unit` için `run_all.sh` env'i | ✔ 2026-11-02 (K46): validate ✔, hook 31/31, pano 12/12; GTR9 izole koşu (`~/projects/llm-portal-dogrula/env-test`, imaj `llm-portal:dogrula-env-test`, HEAD 8c11f71): 8 dosya **165/165**, `session_unit` **8/8**; derleme 14 sn + koşu 3 sn; dizin ve imaj silindi, canlı stack dokunulmadı (`.env` 0.1.9, 9 Up) |

## Kararlar

Kullanıcı kararları (grill, 2026-11-01):
- **K1** Mimari **hibrit**: spec, görev bölme, inceleme ve güvenlik kontrolü orkestratör oturumda alt-ajanlarla
  (ucuz model, izole bağlam); her uygulama görevi kendi worktree'li ayrı oturumda biter ve PR açar; orkestratör PR'ı
  inceler.
- **K2** İnsan kapısı **iki**: (1) grill + tech spec onayı, (2) PR merge. Arası otonom. Global güvenlik onay kapısı
  (`~/.claude/CLAUDE.md`) her zaman ayrıca geçerli.
- **K3** Paketleme: **yeni plugin repo** `prj_Ekip`; vibecoding-agents'ın 32 rolü kaynak metin olarak taşınır.
- **K4** Pilot proje: **prj_LLMPortal** (FastAPI + Jinja2 + Keycloak; STATUS.md ve test altyapısı var).
- **K5** Ad: repo `prj_Ekip`, plugin `ekip`; komutlar `/ekip:<skill>`.

Claude kararları (geri alınır; spec'te kesinleşir):
- **K6** Spec motoru: küçük/orta işte plugin'in kendi hafif spec şablonu + tek bağımsız inceleyici; büyük işte EGM
  (`egm-draft` → `egm-review` → `egm-resolve`) ek kapı. Gerekçe: EGM spec aşamasını iyi kapatıyor ama kod yazmıyor ve
  her işte çalıştırılırsa token yakar.
- **K7** İş boyutu kademesi **S / M / L**: S = tek rol, spec yok, görev kartı + inceleme; M = 1 sayfalık spec + 2
  inceleyici; L = tam grill + EGM + çoklu rol. Token kontrolünün ana kolu bu kademedir.
- **K8** Roller v1 (7): `orkestrator` (ana oturum), `mimar` (spec ve görev bölme, inceleyici), `backend`, `frontend`,
  `ui-ux`, `guvenlik` (salt-okunur inceleyici + security-review), `kalite` (test/QA inceleyici). 32 rol → 7'ye
  indirgenir; gerisi rol gövdesinde uzmanlık notu olarak kalır.
- **K9** Model kademesi: orkestratör ve mimar üst model; uygulama rol oturumları Sonnet; inceleme alt-ajanları
  Sonnet/Haiku; arama Haiku. Ölçülüp spec'te kesinleşir.
- **K10** Araştırma notları ve rapor `docs/research/` altında repoda tutulur (Obsidian'a yalnız özet).

Araştırma sonrası düzeltmeler (2026-11-01, kanıt raporda):
- **K11** Roller işlevsel: `orkestrator` (kod yazmaz), `mimar`, `uygulayici` (backend/frontend/ui-ux = rol etiketi +
  rol prompt'u, ayrı ajan değil), `kalite`, `guvenlik`, `arayici`. Aynı anda canlı 3–4 rol. K8'i daraltır.
- **K12** İki eksen: boy S/M/L süreç ağırlığını, Kademe 1/2/3 (yol + eylem + dış içerik) kapıları belirler. LOC eşiği
  yok. K7'yi düzeltir.
- **K13** Model: tasarruf önce effort, sonra uygulayıcı, en son inceleyici; `kalite` ≥ Sonnet, `guvenlik` Opus, Haiku
  yalnız arama; kademeleme subagent `model` alanıyla. Orkestratör Fable/Opus pilotta ölçülür. K9'u düzeltir.
- **K14** Paralel uygulayıcı oturumu en çok 1–3, dosya sahipliği ayrık.
- **K15** Uygulayıcı başlatma: Kademe 1–2 `-p --worktree` (bütçe kapısı), Kademe 3 interaktif; `--bare` yok. Pilotta
  kesinleşir.
- **K16** Pilotun ilk işi ekip kurmak değil baz çizgi: aynı 10 görevde tek oturum Opus medium ölçümü.
- **K17** Uygulayıcı rolleri ayrı `rol-*` skill'leri değil, tek `ekip-uygula` skill'i + `roller/<rol>.md` notu; protokol
  tek yerde, rol farkı küçük. Spec §3.3'ten sapma.
- **K18** Hook'lar Python 3 (stdlib) ile; jq bağımlılığı yok, macOS/Linux'ta aynı. Uygulayıcı kapıları `cwd/.ekip/kart`
  varlığıyla, inceleyici kapıları `agent_type` ile aktifleşir; diğer oturumlarda pasif.
- **K19** `license` alanı boş bırakıldı; lisans kararı kullanıcıda (validate "directory" profilinde eksik sayar).
- **K20** Görünürlük üç katman (spec §14): `/ekip:durum` + `docs/ekip/PANO.md`; `ekip-izleyici` plugin monitor'ı
  (STATE.json ve rapor dosyalarını izler, görev paneline yazar); Desktop bağlı oturumlar. HTML pano (tailnet, salt-okunur)
  pilot sonrası isteğe bağlı. Pano salt-okunur; ajan panodan komut almaz.
- **K21** Pilot özelliği (2026-11-01, kullanıcı seçimi): LLMPortal'da müşteri sahibi kendi ekibine OTP'yi zorunlu
  kılar; M boy / Kademe 2, Keycloak kartı Kademe 3 (interaktif oturum + güvenlik onayı). Alternatif (yedek doğrulama)
  daha güvenli ama Kademe 3 kapısını sınamazdı. Hazırlık LLMPortal dalı `ekip-pilot-hazirlik` (ee00c38, b99ac63),
  main'e fast-forward alındı (2026-11-01, kullanıcı onayı). Sıra: önce baz çizgi B01–B10 (K16), sonra `/ekip:basla`.
- **K22** Baz çizgi iki oturumda başlamıştı (sürücü `claude -p` sıralı; hazırlık oturumu Desktop'ta 4'lü dalga).
  Çakışma çözümü: B02–B10 ve `olcum.md` sahipliği hazırlık oturumunda (4/10 bitmişti); sürücü oturum B01'i "ikinci
  ölçüm" olarak kaydedip çekilir. GTR9 test ortamı tek, testler sırayla; "serbest" mesajıyla el değiştirir.
- **K23** Tek test ortamı = tek sahip: GTR9 LLMPortal test ortamını aynı anda iki oturum kullandı (B01 testi geçersiz,
  yeniden koşulmadı; ikinci ölçüm "test ölçülmedi"). Ders pilota taşınır: `ekip-denetle` tam test adımı için ortam
  kilidi gereksinimi (retro maddesi, 2.4).
- **K29** Yazma kapısına karta özel izin (2026-11-01, pilot bulgusu, kullanıcı "seçenek 1"; dal `worktree-kapi-kart-izni`):
  var olan test dosyası kartın `## Files` listesindeyse yazılır; korunan yol Files'ta **ve** kart başlığında
  `**🔐 Onay:** <tarih> <kim>` varsa yazılır; kart ve `docs/ekip/**` uygulayıcıya kapalı. Bash yazımı kapsam dışı,
  `ekip:kalite` diff'te bulgu sayar. `ekip-dagit` terminal örneğine `--plugin-dir` ve `--permission-mode auto` eklendi.
- **K28** Baz çizgi referansı (2026-11-01): tek oturum Opus 5.5 medium, S ≈ 0,9 USD / M ≈ 1,6 USD / 1 tur / ilk denemede
  yeşil 10/10. Ekip akışı aynı görevlerde değil pilot özellikte (K21) ölçülür; başarı ölçütü spec §10: kalite kaybı yok,
  insan müdahalesi 2 kapı, maliyet çarpanı raporlanır (araştırma: ekip 2,2–5,1×; hedef bunu aşmamak). Gözlem: baz
  çizgi görevleri küçük ve iyi tanımlıydı, tek oturum hepsini ilk turda bitirdi; ekibin değeri belirsiz/uzun işte
  sınanır. Yan bulgu: Desktop worktree dizin adları yeniden kullanılıyor, doğrulama dal commit'inden alınmalı
  (`git archive`), worktree'den değil.

Görünürlük (1.5, 2026-11-01):
- **K24** `/ekip:durum` tabloyu modele yazdırmaz: `scripts/pano_uret.py` (stdlib) üretir, SKILL.md dinamik bağlamla
  (`` !`…` ``) tabloyu skill metnine gömer; model yalnız basar ve kapıları yorumlar. Böylece `-p --max-turns 1`'de bile
  çalışır ve çıktı deterministiktir. `!` komutları kapalıysa (`disableSkillShellExecution`) model komutu kendi
  çalıştırır (yedek talimat). Tek yan etki `docs/ekip/PANO.md`; `docs/ekip/` yoksa yazılmaz.
- **K25** Worktree↔kart eşlemesi: `git worktree list --porcelain` + worktree'deki `.ekip/kart` içeriği, yoksa dal adındaki
  `T<nnn>`. PR merge durumu `gh` ile sorgulanmaz (çevrimdışı ve stdlib kalsın); "merge" kapısı `status=kabul` + PR
  numarası varken gösterilir. Kart yalnız `tasks/` altında olup STATE'te yoksa kart tablosundan okunur.
- **K26** (kaldırıldı, bkz. K35) `ekip-izleyici`: `monitors/monitors.json`, `when: on-skill-invoke:dagit`, 12 sn yoklama (`EKIP_IZLEYICI_ARALIK`),
  yalnız değişimde `[ekip] T001 status: a → b` biçiminde tek satır. Resmî dokümandan doğrulandı (components.md
  "Monitors", manifest-reference "monitors", 2026-11-01): alanlar `name/command/description/when`; komut oturum cwd'sinde,
  sandbox dışında, kullanıcı yetkisiyle çalışır; stdout satırları Claude'a bildirim olarak düşer; `-p`'de başlamaz;
  plugin kapatılınca durmaz; `${CLAUDE_PLUGIN_ROOT}` komutta değiştirilir, `${user_config.*}` yasak.
  **Doğrulanmadı:** bildirimlerin görev panelinde nasıl gruplandığı, satır uzunluğu sınırı, stderr'in ne olduğu,
  monitor'ın orkestratör turunu uyandırıp uyandırmadığı; pilotta (2.2) gözlenecek. Monitor ucuz ucuz tutulur:
  bildirim = token, startup dışında sessizdir.

Eval (1.6, 2026-11-01):
- **K27** Eval'de düşük Δ'nın iki nedeni var, ikisi de description hatası değil: `ilgisiz-istek` Δ=0 negatif
  kontrol (iki kol da geçer, plugin tetiklenmez; istenen bu); `sir-reddi` Δ=0.17 çünkü plugin'siz baz zaten 2/3 reddediyor,
  plugin 3/3. Slash ile başlayan prompt (`/ekip:basla …`) `tool_used: Skill` göstergesinde 0 sayılır (slash çağrısı Skill
  aracı değil); `boy-kademe` case'i doğal dile ("Bunu ekibe ver ve ekip ile başla: …") çevrildi, böylece description
  tetiklemesi ölçülüyor: tekrar koşuda Skill 1 kez çağrıldı, Boy S / Kademe 3 doğru. Kural: skill'in description ile
  tetiklenmesini ölçen case'ler slash kullanmaz; slash'lı case'ler yalnız çıktı grader'ı taşır.

Pilot (2.2–2.3, 2026-11-01, kaynak LLMPortal `docs/ekip/olcum.md` ve `STATE.json`):
- **K30** Pilot kıyası: E.6 (3 kart + W0) ≈ 29,8 USD / ≈ 2 sa 50 dk, E.7 (3 kart) ≈ 22,7 USD / ≈ 1,5 sa; baz çizgi M ≈ 1,6 USD
  / 1 tur. Doğrudan oran (≈ 18×) yanıltıcı: pilot işi baz görevlerinden büyük ve **aynı işin tek oturum ölçümü yok**;
  retro'da bir karşı ölçüm (aynı kartı plugin'siz tek oturuma vermek) kararlaştırılır. Kurulum hataları 3,22 USD tekrar
  etmez. Kazanım: inceleyici ve insan kapıları 5 gerçek bulgu yakaladı (E.6: fail-open yazım sırası, eksik görsel kanıt;
  E.7: spec'te kısmi PUT fail-open Yüksek, testte sessiz geri yükleme Orta, mimar P0 birim testi kip sınırı). İlk
  denemede yeşil: E.6 1/3, E.7 2/3, takipler 2/2.
- **K31** Grill gözlemi (transkriptten sayıldı): E.6 grill 1 soru (ayarın kaynağı: Keycloak org özniteliği, K1) + Kapı 1
  onayı; 13 karar (K1–K13) spec'e yazıldı, Wave 0 doğrulama kapısı eklendi, kullanıcı 41 mesaj. E.7 grill 1 soru (502'de
  Ekip sayfası davranışı, K32) + Kapı 1; K32–K40, kullanıcı 61 mesaj (kapı 2 ve 🔐 onayları dahil, 10 AskUserQuestion).
  Soru sayısı global kuralla uyumlu (yalnız farklı diff üreten dal). Eksik: E.6 grill'i "Keycloak'a çoklu yazımda
  sıra ve yarım kalma" sorusunu sormadı; aynı sınıf bulgu T002 tur 1'de güvenlik incelemesinden çıktı (K28), E.7'de ise
  spec aşamasında yakalandı. Retro adayı: `ekip-spec` grill şablonuna dış sisteme çoklu yazım varsa "sıra / fail-closed"
  sorusu.

Retro (2.4, 2026-11-01):
- **K32** "Bir bileşeni çıkar" turunun cevabı: `ekip-izleyici` monitor (iki orkestratörde 0 bildirim) ve `PANO.md` dosya
  yazımı (1 kez çağrıldı, dosya bayatladı) pilota katkı vermedi; A9 tek teşhisten sonra kaldırılır, A8 yazımı
  varsayılan kapatır. Yazma/bash kapıları pilotta hiç sapma görmedi: kanıtsız ama ucuz, tutulur.
- **K33** Spec §10.1 "kullanıcı yalnız 2 kapıda müdahale etti" karşılanmadı (E.6 41, E.7 61 kullanıcı mesajı); ölçüt
  yeniden tanımlanır (A7): kapı = karar noktası (spec, kart, 🔐, merge), kapı dışı müdahale ayrı sayılır, hedef ≤ 5/kart.
  Mesajların kaynağı: Kademe 3 oturumlarını kullanıcının açması (plugin Desktop'ta kurulu değil, A11), tarayıcı girişi,
  GTR9 koşusu beklemeleri.
- **K34** Uygulayıcı varsayılanı: Kademe 2 → headless `claude -p --worktree` (0,71–2,09 USD, 0 tur, ilk denemede yeşil
  3/3 netken); Kademe 3 → interaktif oturum. Düzeltme turunda `--resume` pahalı (1,8–2,1 USD, ≈ 760K cache okuma/tur) →
  A2 yeni `-p` oturum + bulgu + diff özeti, ilk kartta ikisi ölçülür. Denetim sırası: deterministik kapı (GTR9 koşusu,
  `py_compile`, gitleaks) önce, LLM inceleyiciler sonra (T004 P0 böyle yakalandı; Stop kapısı Mac'te birim testi
  koşmadığı için geçirdi, A3).

Faz 3 (retro aksiyonları, 2026-11-01, dal `retro-aksiyonlar`):
- **K35** `ekip-izleyici` monitor kaldırıldı (`monitors/`, `scripts/izleyici.py`, test bölümü 3). Teşhis (A9): `claude
  --plugin-dir` interaktif oturumda `/ekip:dagit` çağrıldı, `when` üç biçimde denendi (`dagit`, `ekip-dagit`,
  `ekip:ekip-dagit`); üçünde de `izleyici.py` süreci doğmadı (`pgrep`, claude'un tek çocuğu `caffeinate`), transkriptte
  bildirim yok; sürüm 2.1.309, telemetri değişkeni yok. Pilotta Skill aracı yoluyla da 0 bildirim. Sebep (doğrulanmadı):
  `--plugin-dir` ile yüklenen plugin'de monitor başlamıyor ya da `on-skill-invoke` slash/Skill çağrısını yakalamıyor.
  Geri alma: `git revert` ile dosyalar döner; kalıcı kurulumdan (A11) sonra bir kez daha denenebilir.
- **K36** `/ekip:durum` dosya yazımı varsayılan kapalı (`--dosya` ile açılır); `ekip-basla` proje `.gitignore`'una
  `docs/ekip/PANO.md` ekler (A8). Pano testleri 9/9.
- **K37** Denetim: her doğrulama kartın dal commit'inden (`git archive <sha>`), tek test ortamı kilidi
  `STATE.json.ortam_sahibi`, deterministik kapı önce (A4–A6); headless düzeltme turu `--resume` yerine yeni `-p`
  oturum (A2, ilk kartta ölçülecek); grill zorunlu "yazım sırası / yarım kalma" sorusu (A1); ölçüt kapı / kapı dışı
  müdahale (A7); `ekip.json.test_komutu` birim testleri içermeli (A3).
- **K38** Plugin Mac'e kalıcı kuruldu (A11): yerel directory marketplace `ekip-local` (`.claude-plugin/marketplace.json`,
  kaynak bu repo, yerinde okunur) + `claude plugin install ekip@ekip-local` (user kapsamı). `/mac-change` R1 kaydı
  `20261101-232024-ekip`, gerçek rollback denenip yeniden kuruldu; ledger satırı prj_HomeLab PR #194'te. Headless
  doğrulama (`--plugin-dir` yok): 7 skill yüklü, yazma kapısı `docs/ekip/**` deny, Stop kapısı çalıştı. Desktop
  oturumunda ilk gerçek kullanım A10/A12 sırasında görülecek. Yolda çıktı: uygulayıcı cwd **dışına** yazarsa kapı
  desenleri eşleşmez (test sırasında Haiku yolu yanlış kurdu, dosya cwd dışına yazıldı); kapıya "cwd dışı yol → deny"
  kuralı A13 olarak açık.
- **K39** A10 karşı ölçüm (LLMPortal `docs/ekip/olcum.md` "Karşı ölçüm A10"): T006 kartı aynı metinle, tabanı `49ee36c`
  olan geleceksiz bir depoda, plugin'siz tek Opus 5.5 oturumuna (headless, medium) verildi: **0,67 USD, 1 tur, 74 sn,
  ilk denemede yeşil** (GTR9 `teamguard_unit` REQ-3 R0–R6 7/7); ekip T006 0,97 USD / 2,2 dk. Diff neredeyse birebir.
  Uygulayıcı düzeyinde kapı maliyeti ≈ 0,3 USD; asıl fark orkestratör (kart başına ≈ 5 USD). Bu ölçüm kartı hazır
  sayar; kısa doğal istekle tek oturum (A10-b) ölçülmedi, kullanıcı kararı. GTR9 doğrulaması canlı stack'e dokunmadan
  ayrı dizin + ayrı imaj etiketiyle (ortam Trivy dalında).
- **K40** A10-b: aynı iş, `docs/ekip/` depodan çıkarılmış, 10 satırlık doğal istek + kabul ölçütü olarak T004'ün REQ-3
  testleri: **0,83 USD, 1 tur, 89 sn, ilk denemede yeşil** (R0–R6 7/7); diff daha derli toplu (iki yardımcı), inceleyici
  bakışı yok (yazma yolunda `error=` düz metin, doğrulanmadı). Yorum: S/K2 iyi tanımlı işte tek oturum ekip akışının
  ~%4'ü maliyetle aynı test sonucuna ulaştı; ekip akışının kazancı güvenlik incelemesinin gerçek bulguları ve "önce kırmızı
  test" kartı. Aday A10-c: tüm E.7 (T004–T006) kısa istekle tek oturum, kullanıcı kararı. Ayrıntı LLMPortal
  `docs/ekip/olcum.md` "A10-b".
- **K41** A12 tutarlılıklar: spec §7 kapı reçetesi gerçek hook davranışına çekildi (Stop kapısı `ekip.json.test_komutu`,
  pytest varsayılmaz; yazma kapısı K29 kuralı; `gitleaks protect --staged`), §6 doğrulama örneği pilot komutuyla;
  `kalite` madde 2/4: test kartının var olan dosyaya **ekleme** yapması bulgu değil, zayıflatma ve Files dışı test dosyası
  P0, yeni test dosyası serbest (K29). LLMPortal `.gitleaks.toml`: `compose.yaml` `KC_DB_URL` JDBC satırı için satır
  bazlı allowlist; `gitleaks dir .` 0 bulgu, geçerli biçimli sahte AWS anahtarı hâlâ yakalanıyor (2 → 1).
- **K42** A13: `yazma_kapisi.py` uygulayıcı kapısı cwd (worktree) dışına çıkan her yolu reddeder (`os.path.realpath` +
  `commonpath`, böylece `/tmp` → `/private/tmp` ve `cwd + 'x'` önek benzeri dizin doğru ayrılır); diğer kurallar bundan
  sonra cwd'ye göre eşleşir. Kural uygulayıcıya özel (inceleyici zaten yazamaz, kart yoksa kapı pasif). Bash ile yazma
  hâlâ kapsam dışı (README "Bilinen sınırlar"). 4 yeni hook testi, kuralsız kopyada kırmızı olduğu gösterildi; plugin
  repodan yerinde okunduğu için (K38) canlı kurulum bu değişikliği hemen görür.
- **K43** A10-c (LLMPortal `docs/ekip/olcum.md` "A10-c"): tüm E.7 (T004+T005+T006; M boy, Kademe 3) `40735be` tabanlı
  geleceksiz depoda, `docs/ekip/` yok, 13 satırlık kullanıcı isteğiyle (grill kararları kullanıcı sözüyle, sözleşme adı ve
  metin yok) tek Opus 5.5 oturumu: **2,79 USD, 1 mesaj / 31 API turu, 7 dk 6 sn**; kod ve test aynı 8 dosya; gizli kabul
  testi (T004 `teamguard_unit`) **24/27** — REQ-2 6/6, REQ-3 R1–R3 KALDI yalnız kartın metin ("şu an yüklenemedi") ve
  `data-otp-required` yok sözleşmesinden, davranış doğru (kendi testleri 41/41). Ekip E.7 ≈ 22,7 USD / 1,5 sa / 27/27 +
  smoke 644/0 + kırmızı koşu kanıtı. Koşulmadı: smoke REQ-1/REQ-4 (canlı stack yok), kırmızı koşu. Karar: iyi tarif edilmiş
  S/M işte tek oturum + orkestratörün yalnız doğrulama adımı (GTR9 koşusu, `guvenlik` tek geçiş); tam ekip akışı Kademe 3 +
  paralel kart + belirsiz spec'e. A10 serisi kapandı; ilk gerçek kartta A2 ile birlikte "doğrulama-yalnız" kipinin
  maliyeti ölçülür.

Faz 4 (doğrulama-yalnız kipi, 2026-11-02, dal `claude/bold-swanson-53241b`):
- **K44** `/ekip:dogrula` (K43'ün uygulaması): kartsız iş için orkestratör yalnız doğrular; girdi dal/commit (`git archive
  <sha>`, K37) ya da dizin; kapılar gitleaks (diff + arşiv) → `ekip.json.test_komutu` arşivde → uzak **izole** birim testi
  (`ekip.json.dogrulama`: `{ad}/{dizin}/{imaj}` şablonu, ayrı dizin + ayrı imaj, canlı stack'e dokunmaz, kilit gerekmez) →
  tam takım yalnız `--tam` + `ortam_sahibi` boşken; `kalite` + (Kademe ≥ 2) `guvenlik` paralel **tek geçiş**, düzeltme turu
  yok; karar `KABUL`/`DÜZELT` (+🔐 korunan yolda), rapor `docs/ekip/dogrulama/<tarih>-<ad>.md` + `.patch`,
  `STATE.json.dogrulama[]`, `/ekip:durum` tablosu. `/ekip:basla` S/M + Kademe ≤ 2 + iyi tarif edilmiş işte "tek oturum +
  `/ekip:dogrula`" önerir; tam akış Kademe 3 / paralel kart / belirsiz spec'e. Kuru koşu (LLMPortal, A10-c yaması, dal
  `a10c-e7` = `40735be` + patch, headless Opus medium, `--plugin-dir` worktree): **1,38 USD, 3 dk 21 sn**, gitleaks 0, yerel
  7/7, GTR9 izole birim 6/7 dosya yeşil + `teamguard_unit` 41/41, `session_unit` 4/8 tabanda da 4/8 (orkestratör kendiliğinden
  ayırdı), `kalite` KABUL_ÇEKİNCELİ (P0/P1 0), `guvenlik` 🔐 İNSAN ONAYI (Orta+ 0); karar DÜZELT 🔐 (kırmızı kapı kuralı).
  Koşudan skill'e alınan iki kural: kırmızı uzak kapıda taban ayrı imajla ayrılır, "önceden kırmızı" kararı düşürmez (bu
  kuralla aynı koşu KABUL 🔐 olurdu, yeniden koşulmadı); `/security-review` ana checkout'u incelediği için atlanır. Tek oturum
  (2,79) + doğrulama (1,38) = 4,17 USD, ekip E.7'nin %18'i; eksik kalan kırmızı koşu kanıtı ve smoke (`--tam`). A2 ölçümü
  kısmen karşılandı (düzeltme turu olmadığı için `--resume` kıyası yok). Ayrıntı LLMPortal `docs/ekip/olcum.md`
  "Doğrulama-yalnız kipi"; LLMPortal main commit'i ekip.json `dogrulama` bloğunu, raporu ve STATE kaydını taşır.

A2 ölçümü (4.2, 2026-11-02, LLMPortal `docs/ekip/olcum.md` "A2"):
- **K45** Headless düzeltme turu varsayılanı **yeni `-p` oturumu** (cwd = worktree; prompt = dispatch + "kart uygulandı, yalnız şu
  P0/P1'ler" + kartın bulgu metni aynen + `git diff --stat`). Ölçüm: LLMPortal T009 (B04 "rotate'te harcama taşıma", S · K2, K43
  önerisine rağmen tam akış bilerek), `guvenlik` tur 0 gerçek **Orta** bulgu (SECURITY.md "fazlalık en çok bir kalan" yanlış güvence;
  zincirleme rotate `status()` yalnız `rotated_to`'ya bakar). Aynı worktree durumundan (895c6ed) aynı bulgu metniyle: `--resume`
  **1,11 USD / 7 API turu / 40 sn** (cache okuma 1,74M, çıktı 10,6K), yeni `-p` **0,44 USD / 5 / 40 sn** (218K, 2,4K); ikisi yeşil,
  eşdeğer metin; yeni `-p` tutuldu (498e2c1), merge 722479e. Hedef < 1 USD/tur yalnız yeni `-p`'de. n = 1, doküman düzeltmesi; kod
  düzeltmesinde fark ölçülmedi. `--resume` yalnız `NEEDS_CONTEXT` cevabı gibi yarım bağlam gerektiğinde. Kart toplamı: uygulayıcı
  0,94 + 0,44, alt ajan 2,51 (Opus fiyatı üst sınır), orkestratör Fable 5.1 **ölçülmedi** (fiyat listesi doğrulanmadı; 11,2M cache
  okuma / 63,8K çıktı, Opus eşdeğeri 5,41) → ≈ 9,3 USD, baz çizgi B04 1,81'in ≈ 5,1×; kart onayı → merge 14 dk 22 sn, kapı 2, kapı
  dışı müdahale 0. K43'ü doğrular: iyi tarif edilmiş S işte tam akışın bedeli orkestratör payı; kazanç `guvenlik`'in gerçek bulgusu
  (tek oturum bunu yazmazdı: referans 49dca6c aynı yanlış güvenceyi içeriyor). Yan bulgular: (1) `claude -p --worktree` dalı güncel
  main'den değil bir önceki commit'ten açtı, uygulayıcı fast-forward etti → `ekip-dagit`'e uyarı; (2) orkestratör cwd'si worktree'ye
  kayınca yazma kapısı `.ekip/kart` ile orkestratörü uygulayıcı saydı ve kart düzenlemesini reddetti (A13 doğru çalıştı; orkestratör
  ana checkout'tan yazar); (3) LLMPortal `dogrulama.birim_test` döngüsünde `session_unit` 4/8 **eksik ortam değişkeninden**
  (`PORTAL_MODE=admin`, `ADMIN_PUBLIC_URL`), `run_all.sh` env'iyle 8/8: K44'teki "miras kırmızı" yorumu yanlış; `templates/ekip.json`
  ve LLMPortal `ekip.json` için test başına env desteği açık iş. Koşulmadı: canlı smoke (LiteLLM `spend` kabulü), `--tam`.
- **K46** `dogrulama.birim_test`'te test başına env **komutun içinde** `case $t in <test>) env="-e K=V";; *) env="";; esac` ile; ayrı
  `birim_env` alanı ve `{env:$t}` yer tutucusu **yok**. Neden: skill yalnız `{ad}` `{dizin}` `{imaj}` doldurur ve komutu
  `ssh <uzak> '<komut>'` ile olduğu gibi koşar; yeni alan + yer tutucu, LLM'in map'i shell'e çevirmesini ister (ikinci bir
  dönüşüm noktası, hata ve sapma yeri), `case` ise env'i döngünün yanında tutar ve `run_all.sh` ile birebir karşılaştırılır.
  Şablon dokümanı `templates/ekip.json` `$comment_birim_env`; kural: eksik env'den kırmızı test "önceden kırmızı" değil
  `ekip.json` düzeltmesidir (korunan yol). LLMPortal `session_unit` `PORTAL_MODE=admin ADMIN_SECRET ADMIN_PUBLIC_URL` ile
  GTR9 izole koşuda 8/8 (toplam 165/165, 8 dosya). Yan bulgu: LLMPortal `tests/run_all.sh` birim listesinde `keys_unit` yok
  (döngü 27/27 geçirdi); LLMPortal'da ayrı iş.

## 5. delix'e geçiş (2026-11-02, dal `claude/delix-rename-e7f96a`, PR açılmadı)
Hazırlık [docs/rename/delix-hazirlik.md](docs/rename/delix-hazirlik.md) §4 sırasıyla; kullanıcı kararları: plugin adı `delix`
(şirket markasıyla aynı; public öncesi yeniden bakılır), komutlar rename ile aynı anda İngilizce.
- **K47** Tanımlayıcı rename tek commit (655e01f): plugin `delix` 0.2.0, marketplace `delix-local`; komutlar
  `/delix:start|spec|dispatch|implement|review|verify|status|close`; ajanlar `architect|qa|security|scout`; hedef proje
  `docs/delix/{delix.json,STATE.json,tasks,verifications,BOARD.md,metrics.md}`, worktree `.delix/{card,report.md,test-result.txt,evidence,warnings.log}`;
  JSON anahtarları, durum değerleri (`open|in_progress|in_review|fixing|accepted|rejected|escalated`), karar kelimeleri
  (`ACCEPT|ACCEPT_WITH_NOTES|REJECT|ESCALATE`, `CLEAN|FIX|🔐 HUMAN_APPROVAL`, `READY|FIX`, `PASS|FAIL|not run|pre-existing failure|not measured`),
  makine okunan başlıklar (`**🔐 Approved:**`, `**Status:**`, `## Evidence`, `## Concerns / remaining work`, `## Verification command → expected output`,
  `## Don'ts`, `## Report contract`), betikler `common.py write_gate.py bash_gate.py stop_gate.py board.py` (`--project`, `--write`),
  testler `tests/hook_tests.sh tests/board_tests.sh`, eval adları; `/delix:verify` bayrakları `--request --tier --full --keep`.
  Yer tutucular `{name} {dir} {image}` (hazırlıkta yoktu; config sözleşmesinin parçası). Testler ve fixture'lar aynı commit'te.
- **K48** Metin çevirisi ayrı commit (bf29ce6): skill, ajan, rol notu, şablon ve eval prompt'ları İngilizce; her skill
  "kullanıcının dilinde cevap ver, etiket/durum/karar kelimeleri aynen" kuralı taşır; `/delix:start` description'ı TR+EN
  tetik cümlesi ("delix ile başla", "start with delix"). README İngilizce, `README.tr.md` Türkçe; slogan "Spec first. Agents
  build. You hold the gates." (hazırlık §2 önerisi, geri alınır). STATUS, docs/spec, docs/retro, docs/research, docs/runbooks
  Türkçe kaldı; `docs/spec/ekip-tech-spec.md` dosya adı değişmedi (tarihsel).
- **K49** LLMPortal göçü ayrı worktree/dal `delix-migration` (ae82488, push yok): `docs/ekip → docs/delix`, STATE/delix.json
  anahtarları K47'ye göre, uyumluluk katmanı yok (tek tüketici). Tarihsel kart gövdeleri, `arsiv/`, `baz/`, raporlardaki eski
  komut adları Türkçe/aynen; yalnız yollar, makine okunan token'lar ve `🔐 Approved` satırı değişti. Pano 9 kart + 5 verification.
- **K50** Eval süiti rename sonrası 1 koşu (2026-11-02, `claude plugin eval . --trust-plugin --no-publish --max-cost-usd 5`,
  `evals/results/2026-11-02T15-33-11-204Z/`, gitignore'da): 5 case, 3 tekrar, ortalama Δ +0,46, 2,48 USD, 481 sn, rc=1.
  `size-tier-classification` 1,00 (İngilizce `Size:`/`Tier:` 3/3), `secret-refusal` 1,00, `unrelated-request` 1,00/1,00.
  Tam puan altı 2 case, ikisi de 3 koşudan 1'inde: `reviewer-cannot-write` 0,92 (`authz-finding` jüri PASS/FAIL/FAIL),
  `task-card-format` 0,89 (`required-sections` regex'i kart bölüm sırasında tutmadı; architect çağrısı ve no-write 3/3).
  Rename öncesi (1.6, 1 Kas) 5/5 skor 1,0, Δ 0,47. Karar: gerileme sayılmadı (Δ aynı, tekil koşular); `--keep-temp` ile
  tekrar ancak aynı case yeniden düşerse.
- Yapıldı (2026-11-02): PR #2 main'e merge (956ce29); Mac'te `ekip@ekip-local` kaldırıldı, `delix@delix-local` 0.2.0 kuruldu
  (`/mac-change` R1, gerçek rollback denendi; ledger satırı prj_HomeLab PR #194); LLMPortal göçü `ae82488` main'de ve push edildi.
- Yapıldı (2026-11-02 akşam): GitHub repo `tahircengiz/delixcrew` (ad `delix` marka için boş bırakıldı; yerel klasör
  `prj_Ekip` kaldı), MIT lisans, gitleaks allowlist, **public**, release `v0.2.0` (c75842f). Kurulum:
  `claude plugin marketplace add tahircengiz/delixcrew` + `claude plugin install delix@delix-local`; geçici HOME'da denendi.
- **K51** Uygulayıcı rol notlarına `devops` ve `docs` eklendi (`skills/implement/roles/`, K17 kalıbı; ajan değil, etiket).
  Gerekçe: pilotta compose/Dockerfile/CI kartları `backend` etiketiyle gitti ve homelab çevre kuralları (proxy'yi atlayan
  `ports:` yok, TLS kapatma yok, sır kasadan, digest sabitleme) hiçbir rol notunda yoktu; doküman kartlarının "komut
  çalıştırılarak doğrulanır, dil çiftleri aynı commit'te" kuralı da yoktu. Yeni ajan (tester, debugger, release, pm)
  eklenmedi: yazan rol = oturum, okuyan rol = ajan (K11, K17); rol notlarının etkisi hâlâ ölçülmedi (retro), ilk devops
  kartında retro satırı yazılacak.
- **K52** Sürüm 0.2.2 (2026-11-02, dal `claude/delix-0-2-2-84f358`, push/PR yok): LLMPortal T010 kabul koşusunun F1–F7
  bulguları. F1 devops operasyonel kanıtı yalıtılmış, geçici koşudan (kendi compose proje adı/dizini, sonra söküm);
  ortak ortam orkestratörde kalır (`implement` §3 + `roles/devops.md` aynı kural). F2 PR'sız projede (remote yok ya da
  kart/dispatch "no PR") push yok, rapor `**PR:** none (<branch> @ <sha>)`, `pr` `null`; yeni `delix.json` anahtarı
  eklenmedi (review zaten dal SHA'sından çalışır). F3 dispatch adım 1 S boyda atlanır. F4 `board.py` nesne biçimli
  `waves` (`{wave, cards, note}`) okur, dalga no `wave` alanından (delix-board `parse.ts` ile aynı; eski Türkçe anahtarlar
  yok). F5 Desktop: `user_asked` yalnız kullanıcı bu sohbette istediyse, aksi ve başka oturumdan başlatılan orkestratörde
  `own_initiative` kartı; dal adı rapordan alınır. F6 `bash_gate.py` security allowlist'i `git -C <dir>` okumalarına
  izin verir; yazan git alt komutları `-C` ile de reddedilir. F7 geçici HOME'da ölçüldü (claude 2.1.309): yerel yol
  kurulumu da `~/.claude/plugins/cache/<mp>/<plugin>/<sürüm>/` kopyası; sürüm artmadan `marketplace update` + `plugin
  update` "already at the latest version", sürüm artınca yalnız `plugin update` yeni klasör açar. README/README.tr ve
  marketplace açıklaması düzeltildi; satır 171'deki eski "yerinde okunur" notu tarihsel bırakıldı. Ekler:
  `CHANGELOG.md` (yeni), F4/F6 için önce kırmızı testler.
- **K53** Sürüm 0.2.3 (2026-11-03): sadelik ilkesi. `roles/ui-ux.md` slogan, yardım metni ve ikincil etiketi
  keser; ekran onlarsız anlaşılmıyorsa düzeni düzeltir; erişilebilir ad, form etiketi ve hata mesajı kalır (körü
  körüne kesmek erişilebilirliği bozardı). `spec` §2: her karar UX, DX ve AX'i birlikte iyileştirmeli; birini ötekinin
  pahasına alan karar K kararı olur. `architect` A) soru (6) bunu denetler; kural yazılı ama denetimsiz kalmasın diye.
  Kaynak: kullanıcının bulduğu kullanım örneği; marka adları (örnek siteler) metne alınmadı.
- **K54** Sürüm 0.2.4 (2026-11-03): panonun yanlış alarmı. `review` §4 kartı merge'den sonra `accepted` yapar, ama
  `board.py` `accepted + pr` için `merge` kapısı gösteriyordu; LLMPortal panosunda 7 merge edilmiş kart "bekliyor"
  göründü. Kapı artık `in_review + pr`'de. Doğrulama kayıtlarına isteğe bağlı `resolution`: düzeltilip merge edilen ya da
  bırakılan `FIX` kaydı "Pending fixes"ten çıkar (LLMPortal goofy-dijkstra merge 5ea299f, a10c-e7 ölçüm deneyi).

## 6. 0.3.0 — dış kullanıcı (2026-11-03, dal `claude/delix-0-3-0-d8ad62`, push/PR/tag yok)
- **K55** README/README.tr "Requirements/Gereksinimler": Claude Code (2.1.309 ile denendi; eskisi denenmedi), `python3`
  (3.9 ile denendi), `git`; isteğe bağlı `gh`, `gitleaks`. Geçici HOME'da ölçüldü (claude 2.1.309): GitHub'dan
  `marketplace add tahircengiz/delixcrew` + `install delix@delix-local` (yayımlı 0.2.4) rc=0; SSH anahtarı bozulunca
  "SSH clone failed, retrying with HTTPS" ve yine rc=0, bu yüzden README "SSH anahtarı gerekmez" der. Yerel yoldan yeni
  adla `install delix@delixcrew` 0.3.0 rc=0, kopya `cache/delixcrew/delix/0.3.0/` (K52 F7 ile tutarlı).
- **K56** python3 yokken (PATH'ten çıkarılmış, `claude -p` haiku, 0,013 USD) Bash çağrısı
  `/bin/sh: python3: command not found` ve `blocking because onFailure is "block"` ile engelleniyordu; delix'in adı ve
  çözüm yoktu. Write/Edit ve Bash hook komutlarının başına `command -v python3 || { echo 'delix: python3 not found on
  PATH; …' >&2; exit 2; }`: davranış aynı (block), mesaj tek satır ve çözümü söylüyor. Önce kırmızı test
  (`hook_tests.sh`, hooks.json'daki komutu boş PATH'le koşar: rc=127), sonra yeşil; dash'te (Ubuntu `sh`) rc=2; gerçek
  oturumda mesaj göründü (0,007 USD). Stop hook'una dokunulmadı: python3 yokken engellemiyor, yalnız "Stop hook error"
  bildirimi veriyor; exit 2 ona turu bitirmeme anlamı katardı.
- **K57** CI `.github/workflows/tests.yml`: hook testleri, board testleri, `claude plugin validate .`;
  `actions/checkout` v7.0.1 ve `actions/setup-node` v7.1.0 commit SHA'sına sabit, `permissions: contents: read`,
  `persist-credentials: false`, sır yok; CLI `npm install -g @anthropic-ai/claude-code@2.1.309` (Anthropic'in npm
  paketi, Node ≥ 22 istiyor). Eval CI'da yok (maliyet). Yerelde `act` yok: YAML yalnız ayrıştırıldı, **CI'da koşulmadı**;
  `validate`'in CI'da oturumsuz çalıştığı doğrulanmadı.
- **K58** K50 oynak eval'leri, koşu kayıtlarından (`evals/results/2026-11-02T15-33-11-204Z/aggregate-result.json`):
  `reviewer-cannot-write` düşen koşuda bulgu doğruydu ama "two blocking findings" diye etiketlenmişti, P0/P1 yoktu;
  jüri (haiku, 3 oy) 1 PASS 2 FAIL verdi. Kriter artık şiddet etiketini istemiyor (blocking/critical/REJECT da sayılır);
  dosya düzenlenmediğini zaten `no-edit`/`no-write` ölçüyor. `task-card-format` düşen koşunun metni saklanmamış (trace
  silinmiş); K50 teşhisi bölüm sırası. Regex sıra bağımsız oldu (lookahead), eksik bölüm yine düşer; JavaScriptCore'da
  4 örnekle denendi (sıralı ✔, sırası bozuk eski ✘ yeni ✔, Interfaces ya da Don'ts eksik ikisi de ✘). Eşik 1,0
  bırakıldı: oynaklık grader'dan geliyordu, eşiği düşürmek gerçek gerilemeyi de saklardı. **Eval koşulmadı**; komut ve
  tahmini maliyet raporda (iki vaka, 5 tekrar, baseline'sız ≈ 1,5 USD, ≈ 6 dk).
- **K59** Marketplace adı `delix-local` → `delixcrew` (repo adıyla aynı). Geçici HOME'da ölçüldü: eski adla kurulu
  kullanıcı kırılmıyor (`marketplace update delix-local` + `plugin update` 0.2.4 → 0.3.0, kayıt eski adla kalıyor; yerel
  klasör kaynağıyla ölçüldü, GitHub kaynağında ölçülmedi). Yeni ada geçiş `uninstall` → `marketplace remove` →
  `marketplace add` → `install delix@delixcrew` (+ `delix-board`), 5/5 rc=0; CHANGELOG'da. Tarihsel dokümanlar
  (`docs/spec`, `docs/rename`) ve `docs/runbooks/kullanim.md`'deki Mac kurulum satırı eski adla bırakıldı; Mac geçişi
  ana oturumda `/mac-change` R1.
- **K60** Sürüm 0.4.0 (2026-11-03): plugin adı `delix` → `delixcrew` (kullanıcı kararı: "bu plugin adı o olmalı";
  `delixCrew` kebab-case değil, claude.ai marketplace eşitlemesi küçük harf istiyor). Değişen yalnız tanımlayıcılar:
  komut önekleri `/delixcrew:`, ajan adları `delixcrew:<rol>` (`scripts/common.py` REVIEWERS dahil), hook mesaj önekleri,
  kurulum satırları. Proje dosyaları (`docs/delix/`, `delix.json`, `.delix/`) ve ürün adı "delix" düzyazıda aynı kaldı:
  LLMPortal'da veri taşıma yok. `delix-board` adı kaldı, 0.1.2 yeni ajan önekini izler. Geçmiş kayıtlar (STATUS,
  CHANGELOG eski bölümleri, `docs/retro/`, `docs/rename/`) değişmedi.
## 7. 0.5.0 — öz-besleme (2026-11-03, arşiv `docs/delix/archive/0.5.0-self-feeding/`: SPEC rev 1–3, kartlar T001–T009, STATE)

| # | Adım | Durum |
|---|---|---|
| 7.1 | Grill (4 soru) + spec, kapı 1 | ✔ K61–K82 |
| 7.2 | Dalga 1: T001 `feedback.py` (#6), T002 hook kuralları (#4), T003 skill'ler (#5) | ✔ 850fa34, c43516d, 0a15bc0 |
| 7.3 | Dalga 2: T004 issue formları + CI + 0.5.0 (#18), T005 README/CHANGELOG + veri ve gizlilik (#19) | ✔ 8b8ae5e, e83ecad |
| 7.4 | Kapanış: metrikler `docs/delix/metrics.md`, drift kontrolü (architect) | ✔ |
| 7.5 | W0: gerçek oturumda REQ-7 deny transkripti, `gh issue list --search "delixcrew-fp: …"`, Run düğmesi TTY | ◐ deny gözlendi (orkestratör oturumu, 2 kez); arama ve TTY kontrol edilmedi |
| 7.6 | Uçtan uca: kullanıcı bir test issue'su gönderir ve kapatır | ◻ kullanıcıda |
| 7.7 | 🔐 0.5.0 etiketi ve release | ◻ kullanıcıda |
| 7.8 | Rev 3 (drift takibi): SPEC REQ-11–14, T008 `feedback.py` (#20, 🔐), T009 ayırt eden eval (#21; with 1.00 / without 0.50, 2,03 USD) | ✔ 1a0a0a7, 9d7b79d |
| 7.9 | Kapanış: metrikler, drift (P2'ler aşağıda), 0.5.0 arşivi; `docs/delix/` triage için boş | ✔ |

Kararlar (orkestratör, geri alınır; kullanıcı onaylı olanlar belirtildi):
- **K83–K86** Dalga sırası ve merge sırası T001 → T002 → T003 (T003'ün "hook yine reddeder" metni T002'ye dayanır); 0.5.0 T002'siz çıkmaz.
- **K87** T002 4. tur (kullanıcı: "$VAR'ı kaldır, 4. tur"): hook muafiyeti yalnız düz yollu `feedback.py add <<'EOF'`; değişkenli yol muaf değil (ReDoS kapandı, en kötü 0,05 sn). `${CLAUDE_PLUGIN_ROOT}` skill metninde mutlak yola çevriliyor (`claude -p` ile doğrulandı).
- **K88** T003 yeni main'e karşı yalnız deterministik kapılarla yeniden doğrulandı (metin değişmedi).
- **K89** T003 eval'i ayırt etmiyor (Bash izni yok, boş kuyruk); merge bekletilmedi, takip işi.
- **K90–K91** Eval takibi T005'e konmadı (docs kartı); T007 STATE kaydı close'da düzeltildi.
- **K92** 0.5.0 kapsamı (2026-11-03, kullanıcı kararı): issue #7 (P0, veri ve gizlilik bölümü) T005'e katıldı, ayrı kart
  yok (aynı README dosyaları, aynı commit şartı). Gönderilmiş issue'nun silinme kanalı GitHub özel bildirimi
  (`security/advisories/new`); repoda private vulnerability reporting açıldı. #8 düzeltmesi (T007, `b22f45a`) ayrı 0.4.1
  olmadan 0.5.0 ile yayınlanır; CHANGELOG girdisi T005'te. Öz-besleme kartları ve kararları: `docs/delix/archive/0.5.0-self-feeding/SPEC.md` §9
  (K61–K82, rev 3: K93–K105), `docs/delix/archive/0.5.0-self-feeding/tasks/`.
- **K93–K105** Rev 3 (2026-11-03): spec yerinde güncellendi; K94 (kullanıcı) tek parçalı yol allowlist'le redakte, K100 yalnız
  `/delixcrew:<skill>` muaf; K104 bu değişiklikten önce de var olan sızıntılar takip işi; K105 eval izni joker içermez.

Açık iş (rev 3 kapanışı, 2026-11-03; ilk drift listesinin eval, `kind`, `send` durumu, `/srv`, `example.*` ve eksik test maddeleri
rev 3'te kapandı):
- **[Orta] K104 redaksiyon sızıntıları (rev 3'ten önce de vardı, security T008):** `_PATH_LB` `>`, `\`, `-`, `.` sonrası yolu kaçırır
  (`cmd >/srv/acme/out.log`, `2>/var/lib/acme/x`, JSON `\/srv\/acme`); tek etiketli host'lu URL'ler kalır (`smb://nas/volume1/acme`,
  `http://jenkins:8080/job/x`, `//fileserver/share`, `file:///etc/passwd`). 0.5.0 etiketinden önce küçük bir spec turu önerildi.
- [Düşük] `cmd_add` tekrar satırı ve `cmd_list` diskten okunan değerleri ham basar (elle düzenlenmiş kayıtta ANSI/OSC).
- Rev 3 drift P2'leri: `duplicate` durumu ve taslak olmayan kayıtta `preview` testsiz; REQ-12 büyük/küçük harf ve ASCII testsiz;
  grader (d) deseni spec'ten geniş (T009 round 1 düzeltmesi); seed her koşuda `gh auth status` çalıştırır ve symlink reddi spec'te yok;
  `*.localhost` izinli ama REQ-3/README yalnız `localhost` diyor; seed'deki sabit parmak izini test eden satır yok; README REQ-13'ü
  (taslak olmayan kayda `send` çıkış 2) anlatmıyor; `feedback.py:2,13` docstring eski.
- Eval: `env -u` öneki `DELIXCREW_FEEDBACK_DIR`'ı silmez (operatörde tanımlıysa eval o kuyruğu okur, salt-okunur); `$PWD`'de `*` olursa
  birebir izin jokere döner.
- Hook (K77 kalıntısı): `exec(open('…/feedback.py').read())` + `pty.fork` kural (a)/(b)'ye takılmaz; TTY ve `SEND <hash>` yine durdurur. Kural (c) heredoc gövdesini de tarar (fazla engelleme); rev 3'te 3 kez görüldü: SPEC düzenleyen Python heredoc'u, T009'un
  `gh pr create` gövdesi ve review skill'inin kendi `feedback.py add <<'EOF'` taslak komutu (gövdede "send"/"gh" geçtiği için muafiyet
  tutmadı; feedback taslağı yazılamadı).
- SPEC §4'te olmayan davranış: BLOCKED `preview` HASH/gövde basmıyor, bilinmeyen id exit 2, `send` kontrol sırası repo→id→BLOCKED→hash→TTY.

## 8. 0.6.0 — triage (2026-11-03, SPEC `docs/delix/SPEC.md`, kartlar `docs/delix/tasks/T010–T013`)

Gelen her bug ve öneri issue'su önce kontrol edilir: architect (job D) gerekçeli karar önerir, kararı insan verir, karar
issue'ya kullanıcının terminalinde `triage.py apply` ile yazılır; start yalnız geçerli `accepted` issue'yu alır.

| # | Adım | Durum |
|---|---|---|
| 8.1 | `/delixcrew:start` (M · Tier 3) + grill (6 soru) + spec, architect FIX ve security FIX işlendi | ✔ K106–K127 |
| 8.2 | Kapı 1 | ✔ 2026-11-03 |
| 8.3 | Dispatch: T010 `triage.py`, T011 hook kuralları, T012 skill + architect job D + start §1a, T013 README/CHANGELOG/CI/0.6.0 | ✔ kartlar ve dispatch dosyaları |
| 8.4 | 🔐 Kart başına Approved satırı (dördü de Tier 3) | ✔ 2026-11-03 tahircengiz; main `dbcaaa2` |
| 8.5 | Dalga 1: T010, T011, T012 paralel; merge sırası T010 → T011 → T012 | ◐ oturum kartları önerildi, kullanıcı açar |
| 8.6 | Dalga 2: T013, en son merge | ◻ |
| 8.7 | W0: açık 7 issue'nun toplu triage'ı, gerçek oturum transkripti (REQ-3/4/8) | ◻ kullanıcıda |

Kararlar: `docs/delix/SPEC.md` §9 (kullanıcı K106–K110, orkestratör K111–K127). Öne çıkanlar:
- **K126** `gh` 2.86.0'da `gh issue view|list --json` issue düzeyinde `authorAssociation` vermiyor (`Unknown JSON field`).
  0.5.0 start §1a komutu bu yüzden bugün hata verir; T012 onu `triage.py show` ile değiştirir. 0.5.0 etiketinden önce
  bilinmesi gereken açık.
- **K127** Kart numaraları proje boyunca tekil (arşivde T001–T009 var; triage T010'dan başlar).
- Yan bulgu: Desktop bu worktree dizinini (T005'ten) yeniden kullandı; kalan `.delix/card` yazma kapısını uygulayıcı
  kipine soktu. Dosya silinmeden kenara alındı. close'un worktree temizliği `.delix/`'i silmiyor olabilir; takip işi.

## Açık riskler
- [Orta] Harness bileşenleri model nesline bağlı varsayım taşır; ilk "bir bileşeni çıkar" turu yapıldı (K32), her pilotta tekrarlanır.
- [Orta] Rol oturumları paralel çalışırken aynı dosyaya dokunma; görev bölme bunu bağımlılık olarak çözmeli.
- [Düşük] Alt-ajana giden içerik (web, repo) prompt-injection taşıyabilir; inceleyici roller salt-okunur kalır.

## Kaynaklar
- Önceki deneme: `~/Documents/projects/prj_vibecoding-agents/` (32 rol, `roles/*.md`, yalnız metin düzeyinde)
- Spec/inceleme plugin'i: EGM 0.1.0 (`~/.claude/plugins/cache/egm/egm/0.1.0/`)
- Resmi doküman doğrulaması (2026-11-01): sub-agents, agent-teams, workflows, hooks, plugins (code.claude.com/docs)
- Araştırma raporu: `docs/research/reports/Çoklu ajan yazılım ekibi orkestrasyonu.md` (2026-11-01)
