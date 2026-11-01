---
name: durum
description: Ekip işinin anlık durumunu gösterir: docs/ekip/STATE.json, görev kartları ve uygulayıcı worktree'lerindeki .ekip/rapor.md dosyalarından wave · kart · rol · kademe · status · tur · PR · maliyet · son rapor · bekleyen kapı (🔐, merge) tablosunu sohbete basar; istenirse (`--dosya`) docs/ekip/PANO.md'yi yeniden üretir. Salt-okunur, kod yazmaz. "durum", "pano", "kartlar ne durumda", "hangi kart bekliyor", "/ekip:durum" denince kullan.
allowed-tools: Bash(python3 *pano_uret.py*)
---

Sen `ekip` orkestratörüsün; bu adım **salt-okunur**: kod yazmaz, kart ya da STATE değiştirmez, oturum açmaz.
Aşağıdaki tablo `${CLAUDE_PLUGIN_ROOT}/scripts/pano_uret.py` ile bu projenin kökünde üretildi; dosya yazılmadı.
Kullanıcı "dosyaya yaz" / "PANO.md" / "Obsidian" derse `--dosya` ile yeniden koş (`docs/ekip/PANO.md`; proje
`.gitignore`'unda olmalı, commit edilmez).

## Pano

!`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/pano_uret.py"`

## Ne yapacaksın

1. Tabloyu **olduğu gibi** sohbete bas (satır atlama, yeniden biçimleme yok). Üstte "Kart yok" yazıyorsa yalnız şunu
   söyle: bu projede ekip işi yok ya da henüz kart dağıtılmadı; başlamak için `/ekip:basla <istek>`, dağıtmak için
   `/ekip:dagit`. Dosya arama, script yazma yok.
2. Tablonun altına en çok 3 satır yorum: **bekleyen kapılar** (🔐 = Kademe 3 kart, kullanıcının gözü önünde interaktif
   oturum ve güvenlik onayı ister; `merge` = kapı 2, PR'ı insan merge eder; `needs_context` / `blocked` = uygulayıcı
   raporunda yardım bekliyor, `/ekip:denetle <kart>` ya da karta ek bağlam) ve sırada ne olduğu.
3. Tablo yukarıda yoksa (ör. `!` komutları kapalı) komutu kendin çalıştır:
   `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/pano_uret.py"` (proje kökünde). Başka araç kullanma.

Maliyet sütunu `STATE.json.maliyet_usd`'den gelir; `/ekip:kapat` doldurur, boşsa "ölçülmedi" doğrudur, tahmin yazma.
Worktree'ler `git worktree list` ile bulunur; eşleme `.ekip/kart` içeriği ya da dal adındaki `T<nnn>` iledir.
