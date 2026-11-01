---
name: denetle
description: Bir görev kartının PR'ını denetler. Önce deterministik kapıların kanıtını (test sonucu, CI) kontrol eder; sonra kalite (ve Kademe ≥ 2'de guvenlik) subagent'larını sıfır bağlamla paralel çalıştırır, yalnız high-confidence bulguları karta yazar, en çok 3 düzeltme turu yönetir, sonra kapı 2 (merge) için kullanıcıya sunar. "PR'ı denetle", "incele", "/ekip:denetle T003" denince kullan.
argument-hint: [kart-id-veya-pr]
---

Sen `ekip` orkestratörüsün; bu adımda **denetlersin, düzeltmezsin**. Hedef: $ARGUMENTS (kart id ya da PR numarası;
boşsa `STATE.json`'da `incelemede` olan kartlar).

## 1. Deterministik kapılar önce (ucuz)
- Kartın worktree'sinde `.ekip/rapor.md` ve `.ekip/test-sonucu.txt` var mı; rapor sözleşmeye uyuyor mu
  (`DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED`). `NEEDS_CONTEXT`/`BLOCKED` ise inceleme açma: cevabı ver ya da
  kullanıcıya taşı.
- Doğrulama komutu çıktısı kartın beklenen çıktısıyla eşleşiyor mu; CI varsa yeşil mi (`gh pr checks`). **Kırmızıyken
  LLM incelemesi açılmaz** (token israfı).
- Diff'i dosyaya al: `git diff <varsayilan_dal>...<dal> > .ekip/diff.patch`; dokunulan yolları `ekip.json`
  (`korunan_yollar`, `test_yollari`) ile karşılaştır: korunan yola dokunulduysa kademe 3'e yükselt ve 🔐 işaretle;
  test dosyası değiştirilmişse (yeni test ekleme hariç) doğrudan **RET**.

## 2. Bağımsız inceleme (paralel, sıfır sohbet bağlamı)
`Agent` aracıyla aynı anda:
- `ekip:kalite` — diff yolu, kart yolu, SPEC yolu, test sonucu dosyası, tur sayısı. Beklenen: `KABUL | KABUL_ÇEKİNCELİ |
  RET | ESKALE`.
- Kademe ≥ 2: `ekip:guvenlik` — aynı girdiler + kademe + korunan yollar. Beklenen: `TEMİZ | DÜZELT | 🔐 İNSAN ONAYI`.
- Kademe 3 ve `/security-review` skill'i varsa onu da çalıştır; Claude Security kuruluysa L boyda "scan changes".
İnceleyicilere **kendi görüşünü ya da uygulayıcının gerekçesini verme**; yalnız dosya yolları.

## 3. Bulguları işle
- Yalnız P0/P1 (ve Kritik/Yüksek/Orta güvenlik) düzeltme ister; P2'ler karta not, düzeltme yok ("her bulguyu düzeltme").
- Bulguları kartın `## İnceleme bulguları` bölümüne tur numarasıyla yaz; `STATE.json` → `duzeltme`, `tur += 1`.
- Düzeltmeyi **uygulayıcı oturumuna** gönder (`SendMessage` / oturuma mesaj ya da dispatch'i yeniden ver); kendin
  düzeltme. Düzeltme sonrası **kapsamlı** yeniden inceleme (yalnız bulgulara bakmak yetmez).
- Tur üst sınırı `ekip.json.inceleme_tur_ust_sinir` (3): aşılırsa `eskale` → kullanıcıya özet ve seçenekler (güçlü
  modelle yeniden dene / kapsamı daralt / kabul et).

## 4. Kapı 2
Tüm inceleyiciler KABUL/TEMİZ ise kullanıcıya tek ekran: PR linki, kartın DoD'si ✔/✘, inceleyici kararları, 🔐 notu
varsa güvenlik onay mesajı (global CLAUDE.md biçimi). **Merge kullanıcıda**; sen `gh pr merge` çalıştırmazsın.
Merge sonrası `STATE.json` → `kabul`; bağımlı wave varsa `/ekip:dagit` adım 4 ile sonraki wave'i aç.
