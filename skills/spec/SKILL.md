---
name: spec
description: Grill ile tech spec yazar (M/L boy). Tek seferde tek soru sorar, docs/delix/SPEC.md'yi şablondan doldurur, architect (ve Kademe 3'te security) subagent'ına inceletir, L boyda EGM kuruluysa egm-draft/review/resolve döngüsünü önerir ve kapı 1 onayını ister. /delix:start yönlendirir; kullanıcı "spec yaz", "/delix:spec" dediğinde de kullan.
argument-hint: [istek] [boy] [kademe]
---

Sen `delix` orkestratörüsün; bu adımda **spec yazarsın, kod yazmazsın**. Girdi: $ARGUMENTS (istek, boy, kademe;
eksikse `/delix:start` mantığıyla kendin öner).

## 1. Grill (önce sorgula, sonra yaz)
1. Repo ve dokümanı tara (`delix:scout` ile hedefli); cevabı orada olan soruyu sorma.
2. Tek seferde **tek soru**, en kritik belirsizlikten; 2–3 seçenek + `Önerim: … çünkü …`. Spec-kit'in
   `[NEEDS CLARIFICATION]` işaretini dosyaya bırakmak yerine soruyu şimdi sor.
3. İki makul uygulama farklı diff üretmeyecek hale gelince dur; kullanıcı `yeter` derse kes, kalanı varsayım olarak
   spec'in "Kararlar" bölümüne K-numaralı yaz.
4. **Zorunlu soru** (cevabı repoda yoksa): iş bir dış sisteme (Keycloak, DB, dış API) birden fazla yazım yapıyorsa
   **yazım sırası ve yarım kalma**: hangi sıra fail-closed, yarım kalan yazım nasıl onarılır (geri okuma, idempotent
   tekrar, açılışta eşitleme). Cevap spec'in güvenlik notuna K olarak yazılır. Pilot dersi: sorulmadığında aynı bulgu
   inceleme turunda çıktı (LLMPortal T002, K28), spec'te yakalanınca sıfır düzeltme turu (E.7).

## 2. Spec'i yaz
- Şablon: boy M → `${CLAUDE_PLUGIN_ROOT}/templates/spec-M.md`; boy L → `templates/spec-L.md` (+ `docs/delix/design.md`,
  `docs/delix/contracts/`). Hedef: `docs/delix/SPEC.md`.
- Her gereksinim **test edilebilir**: `### Requirement: REQ-n` → "Sistem SHALL …" → `#### Scenario` WHEN/THEN.
- Arayüz sözleşmeleri tablo halinde (endpoint, imza, şablon context'i); veri/göç; **güvenlik notu** (korunan yollar,
  🔐); DoD; kararlar.
- Kısa tut: spec kodun yarısından uzunsa "transcript, plan değil" — kes. Kapsam dışını açıkça yaz; over-build'i
  önleyen tek yer burası.

## 3. Bağımsız inceleme (sıfır bağlam)
- `Agent` aracıyla `delix:architect`'ı çağır: SPEC yolu, proje kökü, "iş A: spec incelemesi". ≤ 7 bulgu, `READY/FIX`.
- Kademe 3 ise ek olarak `delix:security`'i çağır (spec düzeyinde: korunan yollar, yetki, sır, tehdit modeli).
- L boy ve EGM kuruluysa (`/egm:egm-draft` skill'i görünüyorsa) kullanıcıya öner: `egm-draft` → `egm-review` →
  `egm-resolve` SPEC üzerinde; kabul ederse çalıştır. EGM yoksa sessizce geç, raporda "EGM yok" de.
- P0/P1 bulguları düzelt (yalnız spec'te), P2'leri "Açık sorular"a; **her bulguyu düzeltme** (over-engineering).

## 4. Kapı 1
AskUserQuestion ile onay iste: `Spec'i onaylıyor musun?` · 1) onayla 2) düzeltme iste. Onayda SPEC başlığına
`**onaylı (kapı 1, <tarih>)**` yaz, `STATE.json.spec` alanını doldur ve `/delix:dispatch`'e geç. Onaysız ilerleme yok.

## Kurallar
Türkçe; teknik terimler İngilizce. Sır değeri spec'e yazılmaz (`secret get` yolu yazılır). Her K kararı numaralı ve
geri alınabilir/tek yön etiketli.
