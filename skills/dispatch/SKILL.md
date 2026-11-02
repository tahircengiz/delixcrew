---
name: dispatch
description: Onaylı spec'i görev kartlarına böler ve dağıtır. architect subagent'ına kartları ve wave planını yazdırır, çakışma kontrolü yapar, docs/delix/tasks ve STATE.json'ı günceller, her kart için dispatch prompt'u üretir ve uygulayıcı oturumlarının nasıl açılacağını söyler (en çok 3 paralel). Kapı 1 geçildikten sonra, "dağıt", "görevlere böl", "/delix:dispatch" denince kullan.
argument-hint: [spec-yolu]
---

Sen `delix` orkestratörüsün; bu adımda **böler ve dağıtırsın, kod yazmazsın**. Spec: $ARGUMENTS (boşsa
`docs/delix/SPEC.md`). Spec başlığında `onaylı (kapı 1` yoksa dur ve `/delix:spec`'e yönlendir (S boyda onaylı kart yeter).

## 1. Kartları yazdır
`Agent` ile `delix:architect`: SPEC yolu, `docs/delix/delix.json` (korunan yollar, test yolları, paralel üst sınır), "iş B:
görev kartı üretimi". Çıktıdaki her kartı `docs/delix/tasks/T<nnn>-<slug>.md`'ye yaz (`templates/task-card.md`
alanları eksiksiz; eksik alan varsa mimara geri sor, kendin tahminle doldurma). `## Wave plan`nı `STATE.json.waves`'e,
kartları `STATE.json.cards`a (status `open`, tur 0).

## 2. Çakışma ve kademe kontrolü
- Aynı dosya iki kartta mı? Varsa birleştir ya da sıraya al (ayrı wave). `Agent` ile architect "iş C".
- Her kartın kademesi `protected_paths` ile tutarlı mı; Kademe 3 kartları 🔐 ile işaretle, bunlar **interaktif**
  oturumda ve kullanıcının güvenlik onayıyla yapılır.
- Her kartın Files listesindeki test ve korunan yollar kapıyla uyumlu mu: var olan test dosyasına ekleme ve korunan yol
  yalnız Files'ta backtick içinde açıkça yazılıysa açılır (glob değil, tam yol). Kademe 3 kartlara başlık tablosundan
  sonra `**🔐 Approved:** <YYYY-MM-DD> <kim>` satırı yalnız kullanıcının sohbetteki açık "evet"inden sonra yazılır ve main'e
  commit edilir (worktree bu commit'ten dallanır); onaysız kartta hook korunan yolu reddeder.
- Bir wave'de en çok `max_parallel` (varsayılan 3) kart; fazlası sonraki wave'e.

## 3. Dispatch prompt'ları
Her kart için `${CLAUDE_PLUGIN_ROOT}/templates/dispatch.md`'yi doldur ve `docs/delix/tasks/T<nnn>.dispatch.md`'ye yaz:
plandaki yer, kart yolu, önceki kartlardan gelen arayüz kararları, belirsizlik çözümleri. **Oturum geçmişi ve tüm plan
verilmez.**

## 4. Oturumları aç (wave sırasıyla)
Kullanıcıya her kart için tek satır: kart, rol, kademe, nasıl açılacağı.
- **Claude Desktop (Code sekmesi):** `start_session` aracı varsa `initiation: user_asked`, `use_worktree: true`,
  `context: fresh`, prompt = dispatch dosyasının içeriği; Kademe 3 kartlar için kullanıcıya oturumu kendisinin açmasını
  söyle (gözü önünde).
- **Terminal:** Kademe 1–2 için
  `claude -p --worktree delix-T<nnn> --plugin-dir <plugin kökü> --permission-mode auto --max-turns 60 --max-budget-usd <bütçe> "$(cat docs/delix/tasks/T<nnn>.dispatch.md)"`;
  Kademe 3 için `claude -w delix-T<nnn> --plugin-dir <plugin kökü> --permission-mode auto` interaktif. `--plugin-dir`
  yalnız plugin kalıcı kurulu değilse gerekir (yoksa uygulayıcı `implement` skill'ini ve hook'ları bulamaz).
  `--bare` kullanılmaz. Düzeltme turu (headless kart): `--resume` değil, aynı worktree'de yeni oturum (ölçüm A2: 0,44 vs
  1,11 USD, ikisi yeşil):
  `cd <worktree> && claude -p --permission-mode auto --max-budget-usd <bütçe> --output-format json "$(cat <kök>/docs/delix/tasks/T<nnn>.dispatch.md)
  Düzeltme turu <n>: kart zaten uygulandı ve commit edildi (<sha>); yalnız aşağıdaki P0/P1'leri düzelt. ## Review findings
  <bulgu metni, kartın main'deki bölümünden aynen> ## Diff özeti $(git diff <default_branch>...<dal> --stat)"`.
  Sonuç JSON'undaki `total_cost_usd`, `num_turns`, `duration_ms` ölçüme girer.
- Worktree varsayılan daldan dallanır; kartın bağımlı olduğu kart merge edilmemişse interface-first çalışılır.
  **Dikkat:** `claude -p --worktree` dalı her zaman güncel yerel `main`'den açmayabilir (T009'da bir commit geriden açıldı,
  uygulayıcı fast-forward etti). Kart commit'ini atmadan dispatch verme; dispatch'e "taban: <main SHA>" yaz ya da worktree'yi
  `git worktree add .claude/worktrees/delix-T<nnn> -b worktree-delix-T<nnn> main` ile kendin açıp `cd` + `claude -p` ile koş.
Açılan her kart için `STATE.json` status → `in_progress`.

## 5. Bekle ve topla
Uygulayıcı oturum bitince `.delix/report.md` ve PR gelir; `STATE.json` status → `in_review`, sonra `/delix:review`.
Orkestratör beklerken **kod yazmaz, kartı kendisi yapmaz** (bağlamı kirletir, incelemeyi atlar).
