---
name: close
description: Bir spec'in tüm kartları merge edilince kapanış yapar: STATUS.md ve CHANGELOG güncellenir, kart başına maliyet/tur/cache ölçümü toplanır, spec↔kod drift kontrolü (architect; L'de EGM drift-report) yapılır, öğrenilenler yalnız insan onayıyla CLAUDE.md/memory'ye yazılır, worktree'ler temizlenir. "kapat", "retro", "/delix:close" denince kullan.
argument-hint: [spec-yolu]
---

Sen `delix` orkestratörüsün; kapanış adımı. Spec: $ARGUMENTS (boşsa `docs/delix/SPEC.md`).

## 1. Durum
`STATE.json`'da tüm kartlar `accepted` mü? Değilse listele ve dur (ya da kullanıcı kapsam dışı bırakmayı onaylarsa
`STATE.json`'a yaz).

## 2. Ölçüm (iddia değil sayı)
Kart başına: tur sayısı, `cost_usd` (`/usage` ya da OTel/ccusage varsa; yoksa `not measured`), cache hit (varsa), süre.
Orkestratör için: **kapı sayısı** (spec/kart onayı, 🔐, merge) ve **kapı dışı müdahale** (kullanıcı mesajı − kapı;
hedef ≤ 5 / kart, spec §10.1). Kaynak transkript (`~/.claude/projects/<proje>/<oturum>.jsonl`, `AskUserQuestion`
sayısı ve kullanıcı mesajları); elle sayım kabul, tahmin değil.
Toplamı ve "tek oturum baz çizgisi" varsa karşılaştırmasını `docs/delix/metrics.md`'ye ekle. Ölçülmeyen "not measured" yazılır.

## 3. Drift kontrolü
`Agent` ile `delix:architect`: SPEC ve merge edilmiş kodu karşılaştır, uygulanmamış REQ ve spec'te olmayan davranışı
listele. L boy ve EGM varsa `egm-drift-report`. Bulgular STATUS "Açık işler"e.

## 4. Doküman ve bellek
- `STATUS.md` (faz, adımlar, kararlar), `CHANGELOG.md` güncelle; README etkilenen bölüm.
- Öğrenilenleri (tuzak, kalıp) **öner**; `CLAUDE.md`, `.claude/agent-memory`, memory dizinine yalnız kullanıcı "evet"
  derse yaz (ajan kendi çıktısını paylaşılan belleğe otomatik yazmaz).

## 5. Temizlik
Merge edilmiş kartların worktree'lerini listele; kullanıcı onayıyla `git worktree remove`. `.delix/` dosyaları
worktree ile gider.

## 6. Retro (3 satır)
Ne iyi gitti · ne pahalıydı (tur, token) · hangi harness parçası gereksizdi ("bir bileşeni çıkar, taşıyıcı mı").
