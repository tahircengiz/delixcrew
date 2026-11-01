---
name: dagit
description: Onaylı spec'i görev kartlarına böler ve dağıtır. mimar subagent'ına kartları ve wave planını yazdırır, çakışma kontrolü yapar, docs/ekip/tasks ve STATE.json'ı günceller, her kart için dispatch prompt'u üretir ve uygulayıcı oturumlarının nasıl açılacağını söyler (en çok 3 paralel). Kapı 1 geçildikten sonra, "dağıt", "görevlere böl", "/ekip:dagit" denince kullan.
argument-hint: [spec-yolu]
---

Sen `ekip` orkestratörüsün; bu adımda **böler ve dağıtırsın, kod yazmazsın**. Spec: $ARGUMENTS (boşsa
`docs/ekip/SPEC.md`). Spec başlığında `onaylı (kapı 1` yoksa dur ve `/ekip:spec`'e yönlendir (S boyda onaylı kart yeter).

## 1. Kartları yazdır
`Agent` ile `ekip:mimar`: SPEC yolu, `docs/ekip/ekip.json` (korunan yollar, test yolları, paralel üst sınır), "iş B:
görev kartı üretimi". Çıktıdaki her kartı `docs/ekip/tasks/T<nnn>-<slug>.md`'ye yaz (`templates/gorev-karti.md`
alanları eksiksiz; eksik alan varsa mimara geri sor, kendin tahminle doldurma). `## Wave planı`nı `STATE.json.waves`'e,
kartları `STATE.json.kartlar`a (status `acik`, tur 0).

## 2. Çakışma ve kademe kontrolü
- Aynı dosya iki kartta mı? Varsa birleştir ya da sıraya al (ayrı wave). `Agent` ile mimar "iş C".
- Her kartın kademesi `korunan_yollar` ile tutarlı mı; Kademe 3 kartları 🔐 ile işaretle, bunlar **interaktif**
  oturumda ve kullanıcının güvenlik onayıyla yapılır.
- Her kartın Files listesindeki test ve korunan yollar kapıyla uyumlu mu: var olan test dosyasına ekleme ve korunan yol
  yalnız Files'ta backtick içinde açıkça yazılıysa açılır (glob değil, tam yol). Kademe 3 kartlara başlık tablosundan
  sonra `**🔐 Onay:** <YYYY-MM-DD> <kim>` satırı yalnız kullanıcının sohbetteki açık "evet"inden sonra yazılır ve main'e
  commit edilir (worktree bu commit'ten dallanır); onaysız kartta hook korunan yolu reddeder.
- Bir wave'de en çok `paralel_ust_sinir` (varsayılan 3) kart; fazlası sonraki wave'e.

## 3. Dispatch prompt'ları
Her kart için `${CLAUDE_PLUGIN_ROOT}/templates/dispatch.md`'yi doldur ve `docs/ekip/tasks/T<nnn>.dispatch.md`'ye yaz:
plandaki yer, kart yolu, önceki kartlardan gelen arayüz kararları, belirsizlik çözümleri. **Oturum geçmişi ve tüm plan
verilmez.**

## 4. Oturumları aç (wave sırasıyla)
Kullanıcıya her kart için tek satır: kart, rol, kademe, nasıl açılacağı.
- **Claude Desktop (Code sekmesi):** `start_session` aracı varsa `initiation: user_asked`, `use_worktree: true`,
  `context: fresh`, prompt = dispatch dosyasının içeriği; Kademe 3 kartlar için kullanıcıya oturumu kendisinin açmasını
  söyle (gözü önünde).
- **Terminal:** Kademe 1–2 için
  `claude -p --worktree ekip-T<nnn> --plugin-dir <plugin kökü> --permission-mode auto --max-turns 60 --max-budget-usd <bütçe> "$(cat docs/ekip/tasks/T<nnn>.dispatch.md)"`;
  Kademe 3 için `claude -w ekip-T<nnn> --plugin-dir <plugin kökü> --permission-mode auto` interaktif. `--plugin-dir`
  yalnız plugin kalıcı kurulu değilse gerekir (yoksa uygulayıcı `ekip-uygula` skill'ini ve hook'ları bulamaz).
  `--bare` kullanılmaz. Düzeltme turu (headless kart): `--resume` değil, aynı worktree'de yeni oturum
  `claude -p -w ekip-T<nnn> --plugin-dir <plugin kökü> --permission-mode auto --max-turns 30 --max-budget-usd <bütçe> "$(cat docs/ekip/tasks/T<nnn>.dispatch.md) Düzeltme turu <n>: kartın 'İnceleme bulguları' bölümündeki P0/P1'leri düzelt; diff özeti: $(git diff <varsayilan_dal>...<dal> --stat)"`.
- Worktree varsayılan daldan dallanır; kartın bağımlı olduğu kart merge edilmemişse interface-first çalışılır.
Açılan her kart için `STATE.json` status → `suruyor`.

## 5. Bekle ve topla
Uygulayıcı oturum bitince `.ekip/rapor.md` ve PR gelir; `STATE.json` status → `incelemede`, sonra `/ekip:denetle`.
Orkestratör beklerken **kod yazmaz, kartı kendisi yapmaz** (bağlamı kirletir, incelemeyi atlar).
