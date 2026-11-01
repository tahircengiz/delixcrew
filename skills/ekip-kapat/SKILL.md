---
name: kapat
description: Bir spec'in tüm kartları merge edilince kapanış yapar: STATUS.md ve CHANGELOG güncellenir, kart başına maliyet/tur/cache ölçümü toplanır, spec↔kod drift kontrolü (mimar; L'de EGM drift-report) yapılır, öğrenilenler yalnız insan onayıyla CLAUDE.md/memory'ye yazılır, worktree'ler temizlenir. "kapat", "retro", "/ekip:kapat" denince kullan.
argument-hint: [spec-yolu]
---

Sen `ekip` orkestratörüsün; kapanış adımı. Spec: $ARGUMENTS (boşsa `docs/ekip/SPEC.md`).

## 1. Durum
`STATE.json`'da tüm kartlar `kabul` mü? Değilse listele ve dur (ya da kullanıcı kapsam dışı bırakmayı onaylarsa
`STATE.json`'a yaz).

## 2. Ölçüm (iddia değil sayı)
Kart başına: tur sayısı, `maliyet_usd` (`/usage` ya da OTel/ccusage varsa; yoksa `ölçülmedi`), cache hit (varsa), süre.
Toplamı ve "tek oturum baz çizgisi" varsa karşılaştırmasını `docs/ekip/olcum.md`'ye ekle. Ölçülmeyen "ölçülmedi" yazılır.

## 3. Drift kontrolü
`Agent` ile `ekip:mimar`: SPEC ve merge edilmiş kodu karşılaştır, uygulanmamış REQ ve spec'te olmayan davranışı
listele. L boy ve EGM varsa `egm-drift-report`. Bulgular STATUS "Açık işler"e.

## 4. Doküman ve bellek
- `STATUS.md` (faz, adımlar, kararlar), `CHANGELOG.md` güncelle; README etkilenen bölüm.
- Öğrenilenleri (tuzak, kalıp) **öner**; `CLAUDE.md`, `.claude/agent-memory`, memory dizinine yalnız kullanıcı "evet"
  derse yaz (ajan kendi çıktısını paylaşılan belleğe otomatik yazmaz).

## 5. Temizlik
Merge edilmiş kartların worktree'lerini listele; kullanıcı onayıyla `git worktree remove`. `.ekip/` dosyaları
worktree ile gider.

## 6. Retro (3 satır)
Ne iyi gitti · ne pahalıydı (tur, token) · hangi harness parçası gereksizdi ("bir bileşeni çıkar, taşıyıcı mı").
