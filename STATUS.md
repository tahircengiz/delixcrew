# STATUS — prj_Ekip (plugin `ekip`)

**Son güncelleme:** 2026-11-01 · **Faz:** 2 — pilot bitti (E.6 ≈ 29,8 USD, E.7 ≈ 22,7 USD, hepsi main'de, GTR9 yeşil); sırada retro (2.4)
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
| 2.4 | Retro: hangi harness parçası taşıyıcı | ◻ maddeler: aynı işin tek oturum karşı ölçümü (K30); orkestratör payı %39 → %67; resume edilen headless test kartı düzeltme turu 1,8–2,1 USD; `ekip-denetle` için test ortamı kilidi (K23); dal commit'inden doğrulama (worktree adı yeniden kullanılıyor); grill şablonuna "yazım sırası / yarım kalma" sorusu (K31); reviewer `tests/**` kural çakışması; spec §7 pytest tarifi; `.gitleaks.toml` compose.yaml:69 allowlist; `ekip-izleyici` monitor gözlemi (K26 doğrulanmadı) |

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
- **K26** `ekip-izleyici`: `monitors/monitors.json`, `when: on-skill-invoke:dagit`, 12 sn yoklama (`EKIP_IZLEYICI_ARALIK`),
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

## Açık riskler
- [Orta] Harness bileşenleri model nesline bağlı varsayım taşır; pilot sonunda "bir bileşeni çıkar" turu.
- [Orta] Rol oturumları paralel çalışırken aynı dosyaya dokunma; görev bölme bunu bağımlılık olarak çözmeli.
- [Düşük] Alt-ajana giden içerik (web, repo) prompt-injection taşıyabilir; inceleyici roller salt-okunur kalır.

## Kaynaklar
- Önceki deneme: `~/Documents/projects/prj_vibecoding-agents/` (32 rol, `roles/*.md`, yalnız metin düzeyinde)
- Spec/inceleme plugin'i: EGM 0.1.0 (`~/.claude/plugins/cache/egm/egm/0.1.0/`)
- Resmi doküman doğrulaması (2026-11-01): sub-agents, agent-teams, workflows, hooks, plugins (code.claude.com/docs)
- Araştırma raporu: `docs/research/reports/Çoklu ajan yazılım ekibi orkestrasyonu.md` (2026-11-01)
