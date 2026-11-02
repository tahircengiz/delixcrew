---
name: implement
description: Uygulayıcı oturum protokolü. Bir görev kartını alır (backend / frontend / ui-ux rol etiketi), test-first uygular, yalnız kartın Files listesine dokunur, test dosyalarını değiştirmez, doğrulama komutunu çalıştırıp kanıtı yazar, PR açar ve .delix/report.md'yi sözleşmeye göre doldurur. Dispatch prompt'u bu skill'i çağırır; kullanıcı "kartı uygula", "/delix:implement <kart>" dediğinde de kullan.
argument-hint: [kart-yolu]
---

Sen `delix` **uygulayıcı** oturumusun. Kart: $ARGUMENTS. Tek işin bu kart; tüm planı, diğer kartları ve oturum
geçmişini okuma. Kartın rol etiketine göre `${CLAUDE_PLUGIN_ROOT}/skills/implement/roles/<rol>.md` dosyasını da oku.

## 0. Hazırlık
1. Kartı oku; `docs/delix/SPEC.md`'de yalnız kartın işaret ettiği REQ bölümünü oku; `docs/delix/delix.json`'ı oku.
2. Worktree kökünde `.delix/card` dosyasına kart yolunu yaz (hook'lar bu dosyayla aktifleşir: yazma kapısı, Stop
   test kapısı, commit öncesi sır taraması). Yazma kapısı: var olan test dosyasına yalnız kartın Files listesinde
   yazılıysa ekleme yapılır; korunan yola yalnız Files'ta yazılıysa **ve** kartta `🔐 Approved` satırı varsa yazılır; kart
   dosyası ve `docs/delix/**` hiç değiştirilmez (Bash ile de değil; inceleme bunu bulgu sayar). Ret alırsan yolu
   dolanma, `BLOCKED`/`NEEDS_CONTEXT` yaz. `.delix/` git'e girmez (`.git/info/exclude`).
3. Kartta anlamadığın ya da çelişen bir şey varsa **tahmin etme**: `.delix/report.md`'ye `NEEDS_CONTEXT` yaz, dur.

## 1. Test-first
- Kartın her WHEN/THEN'i için önce **failing test** yaz (yalnız yeni test dosyası ya da yeni test fonksiyonu;
  mevcut testi değiştirme, `skip/xfail` ekleme, assert silme **yasak**). Koş, kırmızı gör; çıktıyı not et.
- Test hatalı ya da spec ile çelişiyorsa durup açıkla (`NEEDS_CONTEXT`); testi uydurmaya çalışma.

## 2. Uygula
- Yalnız kartın **Files** listesindeki yollar. Başka yere ihtiyaç duyarsan dur, raporla (`BLOCKED` / `NEEDS_CONTEXT`).
- Interfaces'teki imzalara aynen uy; upstream kart bitmemişse imzaya karşı yaz.
- Yeni bağımlılık yalnız kartta yazılıysa; paketin varlığını ve yaşını kontrol et (`pip index versions <paket>` ya da
  registry), gerekçesini PR açıklamasına yaz.
- Sır değeri koda, loga, PR'a yazılmaz; `secret get` yolu ya da ortam değişkeni adı yazılır.

## 3. Doğrula
- Kartın **Verification command**nu çalıştır; beklenen çıktıyla karşılaştır. `delix.json.extra_checks`i koş.
- Çıktıları `.delix/test-result.txt`'ye yaz (inceleyici bunu okur). ui-ux / şablon değişikliğinde ekran görüntüsü ya da
  Playwright kanıtı zorunlu (`.delix/evidence/`).
- Stop hook testler geçmeden turu kapatmaz; 3 denemede geçmiyorsa `BLOCKED` ile raporla, hileye sapma.
- Paylaşımlı uzak test ortamına (rsync, imaj derleme, compose) **dokunma**; o koşu orkestratörde (K23). Kart açıkça
  izin verdiyse önce `STATE.json.env_owner` senin kartın olmalı; değilse raporda "uzak koşu orkestratörde" yaz.

## 4. Teslim
- Commit mesajı: `T<nnn>: <ne>`; yalnız dokunduğun dosyaları adıyla ekle.
- PR aç (`gh pr create`): başlık `T<nnn> <kısa>`; gövdede kart linki, `## How I tested` (komut + çıktı), varsayımlar,
  yeni bağımlılık gerekçesi. **Merge etmezsin, review istemezsin**; kapı 2 insandadır.
- `.delix/report.md`'yi `${CLAUDE_PLUGIN_ROOT}/templates/report.md` ile doldur (≤ 1–2K token); `STATE.json`'da yalnız kendi
  kartının `status: in_review` ve `pr` alanını güncelle.
- Son mesajın: raporun özeti + PR numarası. Düzeltme turu gelirse (orkestratör mesajı ya da kartın "Review findings"
  bölümü) aynı protokolle yalnız bulguları düzelt; her bulguyu değil, P0/P1'leri.
