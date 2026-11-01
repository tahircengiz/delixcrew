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
  `test_komutu`, `korunan_yollar`, `test_yollari` alanlarını repoya göre düzelt ve kullanıcıya göster),
  `templates/STATE.json` → `docs/ekip/STATE.json` (boş kartlarla), `docs/ekip/tasks/` dizini.

## 2. Boy ve kademe öner (iki ayrı eksen)
**Boy** süreç ağırlığıdır: **S** = tek kart, yeni davranış yok ya da tek yerde; **M** = yeni ekran/endpoint, 2–5 kart;
**L** = ≥ 2 disiplin, veri modeli/auth/mimari değişir, 5+ kart.
**Kademe** kapıları belirler, dosya yolu + eylem + dış içerik geçmişine bakar: **3** = `ekip.json.korunan_yollar`
(auth, secrets, CI, lockfile, deploy, prod veri) ya da dışa yayın; **2** = yeni davranış, çok dosya, bağımlılık
ekleme, şablon/route; **1** = gerisi. 3 satırlık Keycloak değişikliği S boy / Kademe 3'tür. Satır sayısı ölçüt değil.

Önerini tek satırda, gerekçesiyle yaz: `Boy: M · Kademe: 2 · çünkü …`. Emin değilsen tek bir soru sor (en kritik
belirsizlik, 2–3 seçenek, `Önerim: … çünkü …`).

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
