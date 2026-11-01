# T<nnn> — <kısa başlık>

| id | boy | kademe | rol | wave | status |
|---|---|---|---|---|---|
| T<nnn> | S/M/L | 1/2/3 | backend / frontend / ui-ux | <n> | acik |

**Amaç (1 cümle):** … · **Spec:** `docs/ekip/SPEC.md#REQ-<n>`

## Files (sahiplik ayrık; başka karta ait dosyaya dokunma)
- Oluştur: `path/to/new.py`
- Değiştir: `path/to/existing.py` (satır ~40–80, `fn_x`)
- Test: `tests/test_x.py` (yalnız **yeni** test eklenir; mevcut test değiştirilmez)

## Interfaces
- Tüketilen: `module.fn(a: int) -> B` (T<prev> üretir; bitmemişse imzaya karşı yaz)
- Üretilen: `POST /api/x` → `{ "id": str }`

## Global Constraints (spec'ten aynen)
- …

## Steps
1. Failing test yaz (`tests/test_x.py::test_y`), koş, **kırmızı** gör.
2. Uygula (yalnız Files'taki yollar).
3. Koş, **yeşil** gör; `ruff`/`mypy` temiz.
4. Commit: `T<nnn>: <ne>`; PR aç, açıklamaya "Nasıl test ettim" (komut + çıktı).

## Doğrulama komutu → beklenen çıktı
`pytest tests/test_x.py -q` → `3 passed`

## Review Focus
- Spec'in ima ettiği ama test etmediği girdi: … (kapsayan test: …)

## Yasaklar
- Dokunulmaz: `auth/**`, `tests/**` (yeni test hariç), <korunan yollar>
- Test hatalı görünüyorsa **değiştirme**: dur, raporda `NEEDS_CONTEXT` ile açıkla.
- Yeni bağımlılık yalnız gerekçeyle ve kartta yazılı.

## Rapor sözleşmesi
Bitişte `.ekip/rapor.md` (≤ 1–2K token): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · kanıt (komut, çıktı,
screenshot yolu) · PR numarası · varsayımlar · kalan iş. Tüm planı okuma; yalnız bu kart ve spec'in ilgili bölümü.

## İnceleme bulguları (orkestratör doldurur)
- Tur 1: …
