---
name: review
description: Bir görev kartının PR'ını denetler. Önce deterministik kapıların kanıtını (test sonucu, CI) kontrol eder; sonra qa (ve Kademe ≥ 2'de security) subagent'larını sıfır bağlamla paralel çalıştırır, yalnız high-confidence bulguları karta yazar, en çok 3 düzeltme turu yönetir, sonra kapı 2 (merge) için kullanıcıya sunar. "PR'ı denetle", "incele", "/delix:review T003" denince kullan.
argument-hint: [kart-id-veya-pr]
---

Sen `delix` orkestratörüsün; bu adımda **denetlersin, düzeltmezsin**. Hedef: $ARGUMENTS (kart id ya da PR numarası;
boşsa `STATE.json`'da `in_review` olan kartlar).

## 1. Deterministik kapılar önce (ucuz)
- Kartın worktree'sinde `.delix/report.md` ve `.delix/test-result.txt` var mı; rapor sözleşmeye uyuyor mu
  (`DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED`). `NEEDS_CONTEXT`/`BLOCKED` ise inceleme açma: cevabı ver ya da
  kullanıcıya taşı.
- Doğrulama komutu çıktısı kartın beklenen çıktısıyla eşleşiyor mu; CI varsa yeşil mi (`gh pr checks`). Stop kapısı
  yalnız `delix.json.test_command`nu koşar (çoğu projede derleme + hızlı kontroller); kartın **Verification command**nu ve
  tam test takımını (uzak test ortamı dahil) burada **sen koşarsın** ya da kanıtını doğrularsın. **Kırmızıyken LLM
  incelemesi açılmaz** (token israfı): bulguyu karta `Tur n (deterministik kapı)` olarak yaz, uygulayıcıya gönder.
  Pilot: T004'ün `TypeError` P0'ı Stop kapısından geçti, burada yakalandı.
- **Her şey kartın dal commit'inden** (`git rev-parse <dal>`): diff `git diff <default_branch>...<sha> > .delix/diff.patch`,
  uzak test ortamına gönderim `git archive <sha>` ile; **worktree dizininden değil** (Desktop worktree dizin adlarını
  yeniden kullanır, dizin başka karta ait içerik taşıyabilir). Kabul kaydına ve `STATE.json.pr`'a SHA yazılır.
  Uzak izole birim testi için `delix.json.verify` bloğu varsa `/delix:verify` adım 3 reçetesi (ayrı dizin ve imaj,
  `{name}` = kart no); **test başına env** `unit_test` komutunun içindeki `case $t in …` ile gelir (K46), komutu elle
  tamamlama; bir test yalnız eksik env'den kırmızıysa bu uygulayıcı bulgusu değil `delix.json` düzeltmesidir (korunan yol, 🔐).
- **Tek test ortamı = tek sahip (K23):** paylaşımlı test ortamında koşmadan önce `STATE.json.env_owner` boş mu bak;
  doluysa bekle, zorla alma. Koşarken `{"card": "T<nnn>", "who": "orchestrator", "since": "<ISO>"}` yaz; bitince
  ortamı varsayılan dala döndür ve alanı `null` yap. Uygulayıcı oturumları bu ortama dokunmaz (kart aksini yazmadıkça).
- Dokunulan yolları `delix.json` (`protected_paths`, `test_paths`) ile karşılaştır: korunan yola dokunulduysa kademe
  3'e yükselt ve 🔐 işaretle; test dosyası değiştirilmişse (yeni test ekleme hariç) doğrudan **REJECT**.

## 2. Bağımsız inceleme (paralel, sıfır sohbet bağlamı)
`Agent` aracıyla aynı anda:
- `delix:qa` — diff yolu, kart yolu, SPEC yolu, test sonucu dosyası, tur sayısı. Beklenen: `ACCEPT | ACCEPT_WITH_NOTES |
  REJECT | ESCALATE`.
- Kademe ≥ 2: `delix:security` — aynı girdiler + kademe + korunan yollar. Beklenen: `CLEAN | FIX | 🔐 HUMAN_APPROVAL`.
- Kademe 3 ve `/security-review` skill'i varsa onu da çalıştır; Claude Security kuruluysa L boyda "scan changes".
İnceleyicilere **kendi görüşünü ya da uygulayıcının gerekçesini verme**; yalnız dosya yolları.

## 3. Bulguları işle
- Yalnız P0/P1 (ve Kritik/Yüksek/Orta güvenlik) düzeltme ister; P2'ler karta not, düzeltme yok ("her bulguyu düzeltme").
- Bulguları kartın `## Review findings` bölümüne tur numarasıyla yaz; `STATE.json` → `fixing`, `tur += 1`.
- Düzeltmeyi **uygulayıcı oturumuna** gönder (`SendMessage` / oturuma mesaj ya da dispatch'i yeniden ver); kendin
  düzeltme. Headless (`claude -p`) kartta varsayılan: aynı worktree'de **yeni** `-p` oturumu (cwd = worktree, `-w` yok):
  prompt = dispatch dosyası + `Düzeltme turu n: kart zaten uygulandı ve commit edildi (<sha>); yalnız aşağıdaki P0/P1'leri
  düzelt` + kartın "Review findings" bölümü + `git diff <default_branch>...<sha> --stat` özeti (`/delix:dispatch` adım 4
  komutu). `--resume` kullanma: ölçüldü (LLMPortal T009, A2, 2026-11-02): aynı bulguda `--resume` 1,11 USD / 1,74M cache okuma,
  yeni `-p` **0,44 USD** / 218K; ikisi yeşil ve eşdeğer (pilot T004 `--resume` 1,8–2,1 USD). `--resume` yalnız uygulayıcının
  yarım kalmış bağlamı gerekiyorsa (`NEEDS_CONTEXT` cevabı). Bulgu metnini prompt'a **tam** yaz: worktree'deki kart dosyası
  main'deki güncel bulguları içermez (dal kart commit'inden sonra güncellenen `docs/delix/**`'i görmez).
  Düzeltme sonrası **kapsamlı** yeniden inceleme (yalnız bulgulara bakmak yetmez).
- Tur üst sınırı `delix.json.max_review_rounds` (3): aşılırsa `escalated` → kullanıcıya özet ve seçenekler (güçlü
  modelle yeniden dene / kapsamı daralt / kabul et).

## 4. Kapı 2
Tüm inceleyiciler ACCEPT/CLEAN ise kullanıcıya tek ekran: PR linki, kartın DoD'si ✔/✘, inceleyici kararları, 🔐 notu
varsa güvenlik onay mesajı (global CLAUDE.md biçimi). **Merge kullanıcıda**; sen `gh pr merge` çalıştırmazsın.
Merge sonrası `STATE.json` → `accepted`; bağımlı wave varsa `/delix:dispatch` adım 4 ile sonraki wave'i aç.
