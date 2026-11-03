# Runbook — ekip ile bir özellik

1. Projede oturum aç (Desktop ya da terminal). Plugin Mac'te kalıcı kurulu (`claude plugin list` → `delix@delixcrew`);
   değilse README "Kurulum" (marketplace add + install), tek seferlik için `claude --plugin-dir ~/Documents/projects/prj_Ekip`.
2. `/delix:start <istek>` → boy/kademe önerisini oku; `docs/delix/delix.json` ilk kez oluşturulduysa `test_command` ve
   `protected_paths`ı projeye göre düzelt (ör. LLMPortal: `tests/run_all.sh`, `keycloak/**`, `compose*.yaml`).
3. M/L ise `/delix:spec` grill'ini cevapla; `yeter` diyebilirsin. Spec'i oku, **onayla** (kapı 1).
4. `/delix:dispatch` → kartlar ve dispatch dosyaları. Her kart için oturum aç: Desktop'ta `start_session` (worktree),
   terminalde `claude -w delix-T001` ve içinde `/delix:implement docs/delix/tasks/T001-<slug>.md`. Kademe 3 kartı kendin aç.
   İstediğin an `/delix:status`: kart tablosu ve bekleyen kapılar ("dosyaya yaz" dersen `docs/delix/BOARD.md`, Obsidian'da
   açılır; git'e girmez).
5. Uygulayıcı bitince PR ve `.delix/report.md` gelir. Orkestratörde `/delix:review T001`: tam test koşusu ve uzak ortam
   doğrulaması kartın **dal commit'inden** (`git archive <sha>`), tek test ortamında tek sahip (`STATE.json.env_owner`).
6. İnceleyiciler ACCEPT/CLEAN ise PR'ı **sen merge et** (kapı 2). Sonraki wave için `/delix:dispatch` devam.
7. Tüm kartlar kabul → `/delix:close`: ölçüm, drift, STATUS, worktree temizliği.

## Kısa yol — tek oturum + `/delix:verify` (K43)

İş S/M boy, Kademe ≤ 2 ve iyi tarif edilmişse (`/delix:start` bunu kendisi önerir) tam akış yerine:
1. İşi tek oturumda yap (ya da kendin): belirti + istenen davranış + kabul testi tek istekte; dalda ya da commit'te bitir.
2. Orkestratör oturumunda `/delix:verify <dal> --request <istek-dosyası>`: kabul ölçütü istek metninden alınır; `--tier`
   zorlamak, `--tam` tam takımı (ortam kilidi boşken) koşmak, `--tut` uzak dizini bırakmak için.
3. Kapılar: gitleaks (diff + arşiv) → `delix.json.test_command` → GTR9'da **ayrı dizin + ayrı imaj** birim testi
   (`delix.json.verify`; LLMPortal: `~/projects/llm-portal-dogrula/<ad>`, imaj `llm-portal:dogrula-<ad>`, canlı stack'e
   dokunmaz) → `qa` + `security` tek geçiş. Düzeltme turu yok.
4. Rapor `docs/delix/verifications/<tarih>-<ad>.md`: ACCEPT ya da FIX (+ 🔐 korunan yolda). FIX ise düzelt, yeniden
   `/delix:verify`. Merge sende. `/delix:status` "Verifications" tablosunda görünür.
Headless: `claude -p --permission-mode auto --output-format json "/delix:verify <dal> --request <dosya>"` → `total_cost_usd`
rapora yazılır.

Baz çizgi (K16): ilk 10 görevi önce tek oturum Opus medium ile yap ve `docs/delix/metrics.md`'ye maliyet/tur yaz;
ekip akışı buna karşı raporlanır.
