# STATUS — prj_Ekip (plugin `ekip`)

**Son güncelleme:** 2026-11-01 · **Faz:** 1→2 — görünürlük ve eval yan oturumda; LLMPortal hazırlığı bitti, pilot adayı seçimi bekliyor
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
| 1.3 | Eval süiti çalıştırma (`claude plugin eval .`) | ◻ maliyetli, pilot öncesi 1 kez |
| 1.4 | İlk commit | ✔ `2645cd2` |
| 1.5 | Görünürlük: `/ekip:durum` skill'i + `PANO.md` + `ekip-izleyici` monitor (spec §14) | ◐ yan oturum, dal `claude/goofy-hugle-87d0ae` |
| 1.6 | Eval süiti 1 kez (`--max-cost-usd 10`), bulgulara göre skill description düzeltmesi | ◐ koşuyor (1.5 oturumu) |
| 1.7 | Mac ön koşul: `gitleaks` (`/mac-change`, R1) | ✔ 8.30.1, ledger PR prj_HomeLab #194 |
| 2.1 | Baz çizgi: LLMPortal'da 10 görev tek oturum Opus medium, `docs/ekip/olcum.md` (K16) | ◐ liste B01–B10 hazır (LLMPortal dal `ekip-pilot-hazirlik`, commit ee00c38); koşu ◻ |
| 2.2 | Pilot: LLMPortal'da M boy / Kademe 2 özellik uçtan uca | ◻ aday seçimi kullanıcıda (Aday 1 OTP zorunluluğu / Aday 2 yedek doğrulama) |
| 2.3 | Pilot: bir Kademe 3 kart interaktif + güvenlik onayı | ◻ |
| 2.4 | Retro: hangi harness parçası taşıyıcı | ◻ |

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

## Açık riskler
- [Orta] Harness bileşenleri model nesline bağlı varsayım taşır; pilot sonunda "bir bileşeni çıkar" turu.
- [Orta] Rol oturumları paralel çalışırken aynı dosyaya dokunma; görev bölme bunu bağımlılık olarak çözmeli.
- [Düşük] Alt-ajana giden içerik (web, repo) prompt-injection taşıyabilir; inceleyici roller salt-okunur kalır.

## Kaynaklar
- Önceki deneme: `~/Documents/projects/prj_vibecoding-agents/` (32 rol, `roles/*.md`, yalnız metin düzeyinde)
- Spec/inceleme plugin'i: EGM 0.1.0 (`~/.claude/plugins/cache/egm/egm/0.1.0/`)
- Resmi doküman doğrulaması (2026-11-01): sub-agents, agent-teams, workflows, hooks, plugins (code.claude.com/docs)
- Araştırma raporu: `docs/research/reports/Çoklu ajan yazılım ekibi orkestrasyonu.md` (2026-11-01)
