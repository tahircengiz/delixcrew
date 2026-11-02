# Retro — pilot E.6 / E.7 (prj_LLMPortal, 2026-11-01)

Soru (STATUS 2.4, spec §12 ve §13.6): **hangi harness parçası taşıyıcı**, hangisi Opus 5.5 ile gereksiz ya da
doğrulanmamış. Kaynaklar: LLMPortal `docs/ekip/olcum.md` (Ekip akışı E.6, E.7), `STATE.json` + `arsiv/E6-STATE.json`,
kartların "İnceleme bulguları" bölümleri (T001–T008), `SPEC.md` + `arsiv/E6-SPEC.md` kararları, 12 oturum transkripti
(`~/.claude/projects/<proje>/`; `usage`, `tool_use`, `stop_hook_summary`
kayıtları betikle sayıldı). Fiyat Opus 5.5 liste (4 / 20 / 8 / 0,20 USD per MTok). "Doğrulandı" yalnız bu
kaynaklardan okunan değerler içindir; yorum satırları ayrı işaretlidir.

## 1. Sayılar

| Ölçü | Baz çizgi (10 görev) | E.6 (W0 + T001–T003) | E.7 (T004–T006) | Takipler (T007, T008) |
|---|---|---|---|---|
| Maliyet | 9,89 USD; M ≈ 1,6 USD/görev | ≈ 29,8 USD (orkestratör 11,55 = %39) | ≈ 22,7 USD (orkestratör 15,16 = %67) | 1,68 + 0,71 USD (orkestratör payı ölçülmedi) |
| Kart başı uygulayıcı | – | T001 3,94 · T002 8,21 · T003 5,10 | T004 5,39 · T006 0,97 · T005 1,14 | T007 1,68 · T008 0,71 |
| Duvar süresi | 1–3 dk/görev | ≈ 2 sa 50 dk | ≈ 1 sa 30 dk | ≈ 8 dk · 1,3 dk |
| İlk denemede yeşil | 10/10 | 1/3 (T003 kod evet, kanıt eksik) | 2/3 (T004 2 düzeltme turu) | 2/2 |
| GTR9 tam takım | görev başına ilgili testler | 623 / 0 | 644 / 0 | 656 / 0 |
| Kullanıcı mesajı (orkestratör) | 1/görev | 41 | 61 | – |
| Kullanıcı mesajı (uygulayıcı) | – | T002 21 · T003 4 | T005 2 · T006 2 · T004 4 (headless) | T007 4 · T008 2 |
| Model / cache okuma | Opus 5.5 medium | tümü Opus 5.5; orkestratör %98, uygulayıcılar %91–98 | aynı | aynı |
| Gerçek bulgu (kapılar) | – | 2 (fail-open yazım sırası; eksik görsel kanıt) | 3 (spec'te kısmi PUT fail-open Yüksek; testte sessiz geri yükleme Orta; mimar P0 kip sınırı) | 0 düzeltme, Düşük notlar |
| Revert / merge | – | 0 / 3 | 0 / 3 | 0 / 2 |

Yorum: oran (≈ 18× M görevi) yanıltıcıdır; pilot işi baz görevlerinden büyüktür ve **aynı işin tek oturum ölçümü yoktur**
(aksiyon A10). Güvenilir kıyas şimdilik yalnız kart düzeyinde: headless Kademe 2 kartı (T006 0,97, T008 0,71, T005
1,14 USD, 0 tur, ilk denemede yeşil) baz çizgi S/M bandının içindedir. Pahalı kalemler: (1) orkestratörün denetim turları
(GTR9 koşusu + 3 alt ajan + diff okuma, kart başına ≈ 3–5 USD); (2) resume edilen headless test kartının düzeltme turu
(tek satırlık düzeltme 1,8–2,1 USD, her turda ≈ 760K cache okuma); (3) interaktif Kademe 3 kartın uzun oturumu (T002
8,21 USD, 21 kullanıcı mesajı; T003 5,10 USD, 22 tarayıcı eylemi).

## 2. Bileşen başına karar

Etiketler: **taşıyıcı** (kanıtlı değer; kaldırılırsa pilot kötüleşirdi) · **yardımcı** (çalıştı, değeri küçük ya da
başka bileşenle örtüşüyor) · **doğrulanmadı** (pilotta tetiklenmedi ya da ölçülmedi; tutulur ama iddia edilmez) ·
**çıkarılabilir** (pilotta katkı yok).

| Bileşen | Pilotta gözlenen | Karar |
|---|---|---|
| Grill + spec (`ekip-basla`, `ekip-spec`, `mimar`) | E.6: 1 grill sorusu (K1 ayarın kaynağı) + Kapı 1; 13 karar spec'e; Wave 0 doğrulama kapısı spec'in yarım kalmasını önledi (K14: org özniteliği tekil uçta var, listede yok). E.7: 1 soru (K32) + Kapı 1; `mimar` spec'te P0 (birim testi kip sınırı, K39), `guvenlik` spec'te Yüksek (kısmi PUT fail-open). Soru sayısı global kurala uygun. | **taşıyıcı.** Eksik: E.6 grill'i "dış sisteme çoklu yazımda sıra / yarım kalma" sorusunu sormadı, aynı sınıf bulgu T002 tur 1'de çıktı (K28) → A1. |
| Kart + dispatch (`ekip-dagit`, `templates/gorev-karti.md`, `dispatch.md`) | 8 kart, Files sahipliği ayrık; iki paralel kart (T005 + T006, wave 2) çakışmadı, ikisi de ilk denemede yeşil; headless uygulayıcı yalnız kart + spec bölümüyle 0 tur bitirdi (T006, T008). Kartın "Orkestratörün belirsizlik çözümleri" satırı headless'ta soru sormayı önledi. | **taşıyıcı.** |
| Uygulayıcı: headless `claude -p` (Kademe 2) | 0,71–2,09 USD / 1–4 dk; dispatch metni ASCII olmalı (K30). Düzeltme turu `--resume` ile pahalı (T004: 1,77 ve 2,09 USD). | **taşıyıcı** (Kademe 2 için varsayılan). Düzeltme turu için A2. |
| Uygulayıcı: interaktif oturum (Kademe 3, 🔐) | T002 1 sa 36 dk / 21 mesaj; T005 ≈ 6 dk / 2 mesaj (kart netken kısa); T003 ekran görüntüsü için 22 tarayıcı eylemi + kullanıcı girişi. Desktop oturumunu kullanıcı açtı (plugin kurulu değil, K29 prj_Ekip). | **taşıyıcı** (güvenlik onayı için zorunlu); maliyeti kartın netliğine bağlı. Kurulum A11. |
| Yazma kapısı (`yazma_kapisi.py`) | 1 gerçek engel: T001 2. denemede mevcut test dosyasını kilitledi (yanlış pozitif → K29 düzeltmesi, 0,96 USD). Düzeltme sonrası 7 oturumda 0 engel; uygulayıcı Files dışına çıkmadı. | **doğrulanmadı** (sapma olmadı, kapı sınanmadı). Ucuz ve deterministik; tutulur. |
| Bash kapısı (`bash_kapisi.py`) | Transkriptlerde engel bulunamadı. | **doğrulanmadı.** Tutulur. |
| Stop kapısı (`stop_kapisi.py`, `ekip.json.test_komutu`) | 6 oturumda her turda koştu (1,7–2,3 sn), hiç engellemedi. T004'ün P0'ı (`TypeError`, REQ-3 testleri hiç koşmadı) Stop kapısından geçti; çünkü Mac test komutu `compileall + i18n + gen_env`, birim testleri GTR9 imajında. P0'ı orkestratörün deterministik kapısı (GTR9 koşusu) yakaladı, LLM incelemesi açılmadan. | **yardımcı.** Değeri `test_komutu`nun kapsamı kadar → A3. "Deterministik kapı önce, LLM incelemesi sonra" sırası doğru, skill'e yazılır (A4). |
| `kalite` alt ajanı (Read/Grep/Glob) | 11 çağrı. Gerçek: T003 P1 (DoD ekran görüntüsü yok), T001/T002 P2'ler (yanlış sebeple geçen kontrol). Çoğu KABUL / KABUL_ÇEKİNCELİ. | **yardımcı.** DoD kanıt denetimi (ekran görüntüsü, test kanıtı) asıl katkısı; Bash'siz kalması yetti (§13.3). |
| `guvenlik` alt ajanı | 11 çağrı. Gerçek Orta+: T002 fail-open yazım sırası (K28), T004 sessiz geri yükleme (test realm fail-open), E.7 spec'te kısmi PUT fail-open (Yüksek). Testlerin hiçbiri bunları yakalamazdı. Ayrıca bir bulguyu kendisi çürüttü (set_enabled kısmi PUT). | **taşıyıcı.** |
| `mimar` alt ajanı | 8 çağrı. K17 test kancası, K39 P0 kip sınırı, K38/K40 sınır kararları. | **taşıyıcı** (spec aşamasında). |
| Orkestratör denetimi (`ekip-denetle`) | Kart başına GTR9 koşusu + 3 alt ajan + diff okuma; E.7'de orkestratör payı %67. Test ortamı tek, iki kez çakıştı (K23). Worktree adı yeniden kullanılınca stage'e yanlış içerik gitti (dal commit'inden `git archive` ile düzeltildi). | **taşıyıcı ama en pahalı.** A5 (ortam kilidi), A6 (dal commit'inden doğrulama), A4 (sıra). |
| İnsan kapıları (Kapı 1 spec, Kapı 2 merge, 🔐) | Kapı 1 ×2 + kart onayı ×2; Kapı 2 ×8; 🔐 ×4. Kullanıcı 41 ve 61 mesaj: "yalnız 2 kapıda müdahale" (spec §10.1) **karşılanmadı**. Sebepler: Kademe 3 oturumlarını kullanıcı açtı; tarayıcı girişi kullanıcıda; GTR9 koşuları bekleme turları; onaylar AskUserQuestion ile ayrı mesaj. | Kapılar **taşıyıcı**; ölçüt yeniden tanımlanır (A7): "kapı" = karar noktası, "kapı dışı müdahale" ayrı sayılır. |
| `/ekip:durum` + `PANO.md` | E.6'da 1 kez, E.7'de 0 kez çağrıldı; `PANO.md` 16:25'te kaldı, commit'lenmemiş, üç oturum "ona dokunmadım" dedi. | **çıkarılabilir** olarak dosya yazımı: varsayılan `--yazma`, dosya yalnız istenince (A8). Skill tutulur. |
| `ekip-izleyici` monitor | İki orkestratörde de `/ekip:dagit` çağrıldı; transkriptte 0 `[ekip]` bildirimi (K26'daki "doğrulanmadı" → pilotta **çalıştığı görülmedi**). | **çıkarılabilir** adayı; tek teşhis (A9), çalışmıyorsa kaldır. |
| `ekip-kapat` | STATE kapanış, olcum.md tabloları, SPEC durum satırı, STATUS/CHANGELOG, arşiv (`arsiv/E6-*`). Ölçüm bu sayede var. | **taşıyıcı** (ölçüm için). |
| Rol prompt'ları (`roller/backend.md`, `frontend.md`, `ui-ux.md`) | Etkisi ölçülmedi; frontend kartı (T006) 0 tur bitti ama kart netliğinden mi rol metninden mi ayrıştırılamaz. | **doğrulanmadı.** |
| Eval süiti | Pilotta kullanılmadı (1.6'da 5/5). | – |

Spec §12 "bir bileşeni çıkar" turunun cevabı: pilottan **`ekip-izleyici` monitor** ve **`PANO.md` dosya yazımı**
çıkarılabilir; kapılar (yazma/bash) kanıtsız ama ucuz, tutulur. Taşıyıcı çekirdek: grill+spec+mimar, kart+dispatch,
`guvenlik`, orkestratör denetimi (deterministik kapı önce), insan kapıları, kapanış ölçümü.

## 3. Spec §10 başarı ölçütleri

| # | Ölçüt | Durum |
|---|---|---|
| 0 | Baz çizgi önce | ✔ 10 görev, 9,89 USD |
| 1 | M/K2 özellik uçtan uca, ≤ 2 paralel, kullanıcı yalnız 2 kapıda | ◐ uçtan uca ✔, 2 paralel ✔ (wave 2); "2 kapı" ✗ (41 / 61 mesaj) |
| 2 | PR'da test kanıtı, inceleyici bulgusu görünür, güvenlik bulgusu 0 ya da kabul | ✔ kartlarda "İnceleme bulguları", olcum.md |
| 3 | Bir Kademe 3 kart interaktif + güvenlik onayı | ✔ 4 kart (T002, T003, T005, T007) |
| 4 | Eval ≥ 5 case | ✔ 1.6 |
| 5 | Merge oranı, ilk denemede yeşil, revert, kart maliyeti, cache | ✔ merge 8/8, revert 0, ilk yeşil 5/8, cache %91–99; eksik: tek oturum karşı ölçümü |

## 4. Spec §13 açık sorulara pilot cevapları

1. Baz çizgi: S ≈ 0,9 / M ≈ 1,6 USD, 1 tur, 10/10 yeşil.
2. Orkestratör modeli: tüm oturumlar Opus 5.5 (transkript `model` alanı); Fable 5.1 denenmedi. Çıktı payı düşük
   (E.7 orkestratör 183K çıktı / 45,6M giriş), maliyet giriş ve cache yazımında.
3. `kalite` Bash'siz yetti; gerçek P0 deterministik kapıdan geldi. Bash vermek yerine kapı sırası (A4).
4. Uygulayıcı: Kademe 2 → `claude -p --worktree` (ucuz, 0 tur); Kademe 3 → interaktif oturum (onay şart).
   Düzeltme turunda `--resume` pahalı (A2).
5. 2 paralel (T005 + T006): kalite kaybı gözlenmedi (ikisi ilk denemede yeşil, çakışma yok). 3 paralel denenmedi.
6. Gereksiz: `ekip-izleyici`, `PANO.md` dosyası. Kanıtsız: yazma/bash kapıları, rol prompt'ları.

## 5. Aksiyonlar (sırada; her biri ayrı küçük değişiklik)

| # | Aksiyon | Yer | Not |
|---|---|---|---|
| A1 | Grill şablonuna soru: dış sisteme (Keycloak, DB) birden çok yazım varsa "sıra ve yarım kalma: fail-closed mu?" | `skills/ekip-spec/SKILL.md` | K28 sınıfı bulgu spec'e çekilir |
| A2 | Headless düzeltme turu: `--resume` yerine yeni `-p` oturum + kart + inceleme bulgusu + `git diff` özeti; ilk kartta ikisi ölçülür | `skills/ekip-denetle`, `ekip-dagit` | **Yapıldı 2026-11-02 (K45):** LLMPortal T009 (B04 rotate spend, S/K2) gerçek Orta bulguda aynı worktree durumundan iki yol: `--resume` 1,11 USD / 7 tur / 40 sn (cache okuma 1,74M), yeni `-p` **0,44 USD** / 5 tur / 40 sn (218K); ikisi yeşil ve eşdeğer; yeni `-p` tutuldu, varsayılan oldu; hedef < 1 USD/tur yalnız yeni `-p`'de tutuyor. n = 1 (doküman düzeltmesi). LLMPortal `docs/ekip/olcum.md` "A2" |
| A3 | `ekip.json.test_komutu` kapsamı: Mac'te koşabilen birim testleri varsa dahil; yoksa kartta "Stop kapısı yalnız derleme" notu | `templates/ekip.json`, LLMPortal `docs/ekip/ekip.json` | T004 P0 dersi |
| A4 | Denetim sırası skill'e yazılır: deterministik kapı (test koşusu, `py_compile`, gitleaks) → ancak geçerse LLM inceleyiciler | `skills/ekip-denetle/SKILL.md` | E.7'de fiilen uygulandı |
| A5 | Test ortamı kilidi: `STATE.json.ortam_sahibi` (kart id + zaman); `ekip-denetle` kilit doluysa bekler | `templates/STATE.json`, `ekip-denetle`, `ekip-uygula` | K23 |
| A6 | Doğrulama dal commit'inden (`git archive <sha>`), worktree dizininden değil | `skills/ekip-denetle/SKILL.md`, runbook | Desktop worktree adı yeniden kullanıyor |
| A7 | Ölçüt yeniden tanımı: "insan kapısı" = karar noktası (spec onayı, kart onayı, 🔐, merge); "kapı dışı müdahale" ayrı sayılır ve hedef ≤ 5/kart | `docs/spec/ekip-tech-spec.md` §10.1, `ekip-kapat` ölçüm tablosu | pilot: 41 / 61 toplam mesaj |
| A8 | `/ekip:durum` varsayılan `--yazma`; `PANO.md` yalnız `--dosya` ile; `ekip-basla` proje `.gitignore`'a `docs/ekip/PANO.md` ekler | `skills/ekip-durum`, `scripts/pano_uret.py`, `ekip-basla` | üç oturum "dokunmadım" dedi |
| A9 | `ekip-izleyici` tek teşhis: `claude --plugin-dir` interaktif oturumda `/ekip:dagit` sonrası monitor süreci var mı (`ps`), stdout satırı düşüyor mu; düşmüyorsa `monitors/` kaldırılır, K26 güncellenir | `monitors/monitors.json` | **Yapıldı 2026-11-01:** 3 `when` biçimiyle 3 koşu, süreç hiç doğmadı; kaldırıldı (STATUS K35) |
| A10 | Karşı ölçüm: E.7 boyutunda bir kart (örn. T006 benzeri S/K2) plugin'siz tek oturuma aynı kart metniyle verilir; maliyet, tur, ilk yeşil | LLMPortal, sıradaki küçük iş | Yapıldı 2026-11-01: T006 aynı kartla tek oturum 0,67 USD / 1 tur / ilk yeşil (ekip 0,97); A10-b kart yok, kısa istek 0,83 USD / 1 tur / ilk yeşil (K40); A10-c tüm E.7 kısa istek tek oturum 2,79 USD / 7 dk, gizli test 24/27 (3 KALDI kart sözleşmesi, davranış doğru), ekip 22,7 USD (K43, 2026-11-02) |
| A11 | Plugin'i Mac'e kalıcı kur (yerel marketplace, `/mac-change` R1) → Kademe 3 oturumları Desktop'tan plugin'li açılır, kullanıcı mesajı azalır | `.claude-plugin/marketplace.json`, Mac ayarı | 🔐 R1 onayı kullanıcıda |
| A12 | Küçük tutarlılıklar: spec §7 kapı reçetesi pytest yazıyor, LLMPortal'da pytest yok (düzelt); inceleyici `tests/**` kuralı ile "test kartı test dosyasına ekler" (K29) çelişkisi netleştirilir; LLMPortal `.gitleaks.toml` allowlist `compose.yaml:69` yanlış pozitifi | `docs/spec` §7, `agents/kalite.md`, LLMPortal | Yapıldı 2026-11-01 (K41): spec §6/§7 gerçek hook davranışı, kalite madde 2/4, LLMPortal `.gitleaks.toml` |
| A13 | Yazma kapısı cwd (worktree) dışına yazan yolu denetlemiyordu (A11 testinde çıktı, K38): `../`, başka mutlak dizin ve önek benzeri dizin deny | `scripts/yazma_kapisi.py`, `tests/hook_testleri.sh` | Yapıldı 2026-11-02 (K42): realpath + commonpath; 4 yeni test, kuralsız kopyada kırmızı |

Kapsam dışı (LLMPortal tarafında, ekip plugin'i değil): B01/B04/B08 kart adayları, `main.py` `%r` logları, Keycloak
config'siz koşul davranışı.
