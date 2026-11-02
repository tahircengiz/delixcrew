---
name: status
description: Ekip işinin anlık durumunu gösterir: docs/delix/STATE.json, görev kartları ve uygulayıcı worktree'lerindeki .delix/report.md dosyalarından wave · kart · rol · kademe · status · tur · PR · maliyet · son rapor · bekleyen kapı (🔐, merge) tablosunu sohbete basar; istenirse (`--write`) docs/delix/BOARD.md'yi yeniden üretir. Salt-okunur, kod yazmaz. "durum", "pano", "kartlar ne durumda", "hangi kart bekliyor", "/delix:status" denince kullan.
allowed-tools: Bash(python3 *board.py*)
---

Sen `delix` orkestratörüsün; bu adım **salt-okunur**: kod yazmaz, kart ya da STATE değiştirmez, oturum açmaz.
Aşağıdaki tablo `${CLAUDE_PLUGIN_ROOT}/scripts/board.py` ile bu projenin kökünde üretildi; dosya yazılmadı.
Kullanıcı "dosyaya yaz" / "PANO.md" / "Obsidian" derse `--write` ile yeniden koş (`docs/delix/BOARD.md`; proje
`.gitignore`'unda olmalı, commit edilmez).

## Pano

!`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/board.py"`

## Ne yapacaksın

1. Tabloyu **olduğu gibi** sohbete bas (satır atlama, yeniden biçimleme yok). Üstte "No cards" yazıyorsa yalnız şunu
   söyle: bu projede ekip işi yok ya da henüz kart dağıtılmadı; başlamak için `/delix:start <istek>`, dağıtmak için
   `/delix:dispatch`. Dosya arama, script yazma yok.
2. Tablonun altına en çok 3 satır yorum: **bekleyen kapılar** (🔐 = Kademe 3 kart, kullanıcının gözü önünde interaktif
   oturum ve güvenlik onayı ister; `merge` = kapı 2, PR'ı insan merge eder; `needs_context` / `blocked` = uygulayıcı
   raporunda yardım bekliyor, `/delix:review <kart>` ya da karta ek bağlam) ve sırada ne olduğu. "Verifications" tablosu
   varsa (`/delix:verify`, kartsız iş): `FIX` satırları kullanıcının düzeltmesini bekler, `🔐` sohbette onay ister;
   bunları da aynı 3 satırın içinde say.
3. Tablo yukarıda yoksa (ör. `!` komutları kapalı) komutu kendin çalıştır:
   `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/board.py"` (proje kökünde). Başka araç kullanma.

Maliyet sütunu `STATE.json.cost_usd`'den gelir; `/delix:close` doldurur, boşsa "not measured" doğrudur, tahmin yazma.
Worktree'ler `git worktree list` ile bulunur; eşleme `.delix/card` içeriği ya da dal adındaki `T<nnn>` iledir.
