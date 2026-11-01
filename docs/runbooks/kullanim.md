# Runbook — ekip ile bir özellik

1. Projede oturum aç (Desktop ya da terminal). Plugin Mac'te kalıcı kurulu (`claude plugin list` → `ekip@ekip-local`);
   değilse README "Kurulum" (marketplace add + install), tek seferlik için `claude --plugin-dir ~/Documents/projects/prj_Ekip`.
2. `/ekip:basla <istek>` → boy/kademe önerisini oku; `docs/ekip/ekip.json` ilk kez oluşturulduysa `test_komutu` ve
   `korunan_yollar`ı projeye göre düzelt (ör. LLMPortal: `tests/run_all.sh`, `keycloak/**`, `compose*.yaml`).
3. M/L ise `/ekip:spec` grill'ini cevapla; `yeter` diyebilirsin. Spec'i oku, **onayla** (kapı 1).
4. `/ekip:dagit` → kartlar ve dispatch dosyaları. Her kart için oturum aç: Desktop'ta `start_session` (worktree),
   terminalde `claude -w ekip-T001` ve içinde `/ekip:uygula docs/ekip/tasks/T001-<slug>.md`. Kademe 3 kartı kendin aç.
   İstediğin an `/ekip:durum`: kart tablosu ve bekleyen kapılar ("dosyaya yaz" dersen `docs/ekip/PANO.md`, Obsidian'da
   açılır; git'e girmez).
5. Uygulayıcı bitince PR ve `.ekip/rapor.md` gelir. Orkestratörde `/ekip:denetle T001`: tam test koşusu ve uzak ortam
   doğrulaması kartın **dal commit'inden** (`git archive <sha>`), tek test ortamında tek sahip (`STATE.json.ortam_sahibi`).
6. İnceleyiciler KABUL/TEMİZ ise PR'ı **sen merge et** (kapı 2). Sonraki wave için `/ekip:dagit` devam.
7. Tüm kartlar kabul → `/ekip:kapat`: ölçüm, drift, STATUS, worktree temizliği.

Baz çizgi (K16): ilk 10 görevi önce tek oturum Opus medium ile yap ve `docs/ekip/olcum.md`'ye maliyet/tur yaz;
ekip akışı buna karşı raporlanır.
