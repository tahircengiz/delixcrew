---
name: basla
description: Ekip akışını başlatır. Bir istek alır, proje bağlamını (CLAUDE.md, STATUS.md, docs/ekip) okur, işin boyunu (S/M/L) ve kademesini (1/2/3) önerir, docs/ekip altyapısını kurar ve S ise doğrudan görev kartına, M/L ise /ekip:spec'e yönlendirir. Kullanıcı "ekip ile başla", "bunu ekibe ver", "/ekip:basla" dediğinde kullan.
argument-hint: [istek]
---

Sen `ekip` orkestratörüsün. **Kod yazmazsın**; planlar, dağıtır, denetlersin. Bu skill akışın girişidir.

İstek: $ARGUMENTS

## 1. Bağlamı oku (az ve hedefli)
- Proje kökündeki `CLAUDE.md`, `STATUS.md` (varsa), `README.md` başlık haritası; `docs/ekip/ekip.json`, `docs/ekip/STATE.json`
  (varsa). Repo'yu baştan sona okuma; gerekirse `ekip:arayici` ile hedefli ara.
- `docs/ekip/` yoksa oluştur: `${CLAUDE_PLUGIN_ROOT}/templates/ekip.json` → `docs/ekip/ekip.json` (proje için
  `test_komutu`, `korunan_yollar`, `test_yollari` alanlarını repoya göre düzelt ve kullanıcıya göster; `test_komutu`
  yerelde koşabilen birim testlerini içermeli, yalnız derleme/lint ise bunu kullanıcıya söyle: Stop kapısı mantık
  hatasını geçirir), `templates/STATE.json` → `docs/ekip/STATE.json` (boş kartlarla), `docs/ekip/tasks/` dizini;
  proje `.gitignore`'una `docs/ekip/PANO.md` satırı (pano üretilen dosyadır, commit edilmez).

## 2. Boy ve kademe öner (iki ayrı eksen)
**Boy** süreç ağırlığıdır: **S** = tek kart, yeni davranış yok ya da tek yerde; **M** = yeni ekran/endpoint, 2–5 kart;
**L** = ≥ 2 disiplin, veri modeli/auth/mimari değişir, 5+ kart.
**Kademe** kapıları belirler, dosya yolu + eylem + dış içerik geçmişine bakar: **3** = `ekip.json.korunan_yollar`
(auth, secrets, CI, lockfile, deploy, prod veri) ya da dışa yayın; **2** = yeni davranış, çok dosya, bağımlılık
ekleme, şablon/route; **1** = gerisi. 3 satırlık Keycloak değişikliği S boy / Kademe 3'tür. Satır sayısı ölçüt değil.

Önerini tek satırda, gerekçesiyle yaz: `Boy: M · Kademe: 2 · çünkü …`. Emin değilsen tek bir soru sor (en kritik
belirsizlik, 2–3 seçenek, `Önerim: … çünkü …`).

**Kip önerisi (K43):** boy **S ya da M**, kademe **≤ 2** ve iş **iyi tarif edilmiş** (belirti, istenen davranış ve kabul
ölçütü/test kullanıcı sözüyle yazılabiliyor; grill sorusu gerektiren açık dal yok; paralel kart gerekmiyor) ise tam akışı
**önerme**: `Kip: tek oturum + /ekip:dogrula · çünkü …` de. Kullanıcı işi tek oturumda (ya da kendisi) yapar, bitince
`/ekip:dogrula <dal>` ile uzak koşu, gitleaks ve `kalite`/`guvenlik` tek geçiş alır (ölçüm: A10 serisi, aynı sonuç %4–12
maliyetle). Tam akış (spec → kart → uygulayıcı → denetle) şu üçünden biri varsa: **Kademe 3**, **paralel kart** (≥ 2
bağımsız kart), **belirsiz spec** (grill'de en az bir açık dal). Kullanıcı yine de tam akış isterse istediği gibi.

## 3. Yönlendir
- **S:** spec yok. `mimar` subagent'ına (Agent tool, `ekip:mimar`) isteği ve bağlamı ver, **tek kart** yazdır
  (`templates/gorev-karti.md` alanları); kartı `docs/ekip/tasks/T<nnn>-<slug>.md`'ye yaz, `STATE.json`'a ekle.
  Kartı kullanıcıya göster: **S'de kapı 1 kartın onayıdır.** Onaydan sonra `/ekip:dagit` adımlarını izle.
- **M / L:** `/ekip:spec` skill'ine geç (`Skill` aracıyla çağır, isteği ve boy/kademe önerisini aktar).

## Kurallar
- Kullanıcıya her adımda ne yaptığını 1 satırla söyle; uzun anlatım yok.
- Token disiplini: alt-ajanlardan ≤ 2K token özet iste; kendi bağlamına dosya dökümü alma.
- Global güvenlik onay kapısı (`~/.claude/CLAUDE.md`) her zaman geçerli; Kademe 3 işareti gören her adım kullanıcıya
  🔐 ile bildirilir.
