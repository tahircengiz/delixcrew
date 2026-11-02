# SPEC — <özellik adı>

> Boy: **M** · Kademe: <1|2|3> · Tarih: <YYYY-MM-DD> · Durum: taslak | **onaylı (kapı 1, <tarih>)**
> Kaynak: grill kararları K<n>–K<m> (aşağıda). Kısa tut: spec, kodun yarısından uzunsa transcript'tir, plan değil.

## 1. Amaç (2–3 cümle)
Kim, neyi, neden. Başarı ne demek.

## 2. Kapsam dışı
- …

## 3. Gereksinimler (test edilebilir)
### Requirement: REQ-1 <ad>
Sistem SHALL …
#### Scenario: <ad>
- WHEN …
- THEN …

### Requirement: REQ-2 <ad>
…

## 4. Arayüz sözleşmeleri
| Tür | Ad | İmza / şekil | Tüketen |
|---|---|---|---|
| endpoint | `POST /api/x` | istek / yanıt gövdesi | frontend |
| fonksiyon | `module.fn(a: int) -> B` | … | … |
| şablon context | `templates/x.html` | `{ "items": [...] }` | … |

## 5. Veri ve göç
Değişen tablo/alan; göç gerekiyorsa adımı ve geri alma.

## 6. Güvenlik notu
Dokunulan korunan yollar (Kademe 3 ise 🔐 insan onayı); yetki, girdi doğrulama, sır.

## 7. Kabul ölçütleri (DoD)
- [ ] Her REQ için geçen test; doğrulama komutu: `<komut>` → `<beklenen>`
- [ ] Kademe ≥ 2: `qa` ACCEPT; Kademe 3: `security` CLEAN + insan onayı
- [ ] PR açıklamasında "How I tested"

## 8. Açık sorular
- `[NEEDS CLARIFICATION: …]` kalmamalı; kalan varsa kapı 1'den önce sor.

## 9. Kararlar
- K<n>: …
