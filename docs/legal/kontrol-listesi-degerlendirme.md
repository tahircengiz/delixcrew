# Yasal kontrol listesi değerlendirmesi: delixcrew

> Tarih: 2026-11-03 · Kapsam: `tahircengiz/delixcrew` 0.4.0 (main `92b0291`) ve onaylı 0.5.0 "öz-besleme" spec'i
> ([SPEC.md](../delix/SPEC.md)) · Kaynak liste: sosyal medyada paylaşılan 15 maddelik "uygulama yayınlarken dava yememek"
> listesi.
>
> **Bu belge yasal tavsiye değildir.** Mühendislik gözüyle yapılmış bir envanter ve önceliklendirmedir. ⚖️ işaretli
> maddeler için hukukçu görüşü alınmalıdır.

## 1. Ürün ne, veri nereye gidiyor

Liste bir web/mobil uygulama (hesap, ödeme, çerez, sunucuda kullanıcı verisi) için yazılmış. delixcrew öyle değil:

- **Ne:** Claude Code plugin'i; skill, subagent tanımı ve 3 Python hook'u ([hooks.json](../../hooks/hooks.json)) +
  yardımcı mod `delix-board` (yalnız yerel dosya okur, [data.ts](../../plugins/delix-board/hooks/data.ts)).
- **Dağıtım:** public GitHub reposu, MIT ([LICENSE](../../LICENSE)); kendi marketplace'i `delixcrew`
  ([marketplace.json](../../.claude-plugin/marketplace.json)). `gh repo view` → `visibility: PUBLIC`, `licenseInfo: mit`.
  Anthropic'in resmî plugin dizininde değil.
- **Sunucu yok, hesap yok, ödeme yok, telemetri yok.** Kanıt: `scripts/*.py` yalnız stdlib (`argparse, json, os, re,
  subprocess, shutil, fnmatch, datetime`); `urllib|requests|socket|curl|fetch(|telemetr|litellm` araması `scripts/`,
  `hooks/`, `plugins/delix-board/hooks/`, `skills/`, `agents/`, `templates/` altında ağ çağrısı bulmadı (eşleşen tek
  şey SVG `xmlns` URL'leri).
- **Kullanıcı makinesinde yazılan veri** (hepsi kullanıcının kendi projesinde ya da ev dizininde):
  `docs/delix/STATE.json` (kart durumu, tur, `cost_usd`), `docs/delix/tasks/*`, `.delix/card`, `.delix/report.md`,
  `.delix/test-result.txt` ([stop_gate.py](../../scripts/stop_gate.py)), `.delix/warnings.log`
  ([bash_gate.py](../../scripts/bash_gate.py)), `docs/delix/BOARD.md`.
- **Dışarı giden veri:** (a) Claude Code'un kendisi istemi ve kodu Anthropic'e gönderir; bu, kullanıcının Anthropic ile
  sözleşmesidir, plugin yeni bir akış eklemez. (b) `gh` ile PR açma/okuma: kullanıcının kendi GitHub hesabı ve reposu.
  (c) `/delixcrew:verify` uzak izole test: kullanıcının `delix.json`'da verdiği kendi makinesine `ssh`.
  (d) **0.5.0'da yeni:** öz-besleme, temizlenmiş bulguyu **public** `tahircengiz/delixcrew` reposuna GitHub Issue olarak
  gönderir (opt-in, kullanıcı kendi terminalinde onaylar; SPEC REQ-1…REQ-8). Bu, projenin **ilk ve tek** kişisel veri
  akışıdır: issue'yu açanın GitHub kullanıcı adı, OS adı, Claude Code ve plugin sürümü, serbest metin.

Sonuç: listedeki maddelerin çoğu **bugün** uygulanmaz; asıl riskler listede olmayan yerlerde (hook'ların kullanıcı
makinesinde komut çalıştırması, repo ele geçirilirse tedarik zinciri, marka/IP) ve 0.5.0 öz-besleme akışında.

## 2. 15 madde

Durum: **Yapıyoruz** · **Kısmen** · **Yapmalıyız** · **Uygulanmaz**. Öncelik P0 (0.5.0 yayınından önce) · P1 (yakın) ·
P2 (tetikleyici olursa / iyi olur). Efor S/M/L.

| # | Madde | Durum | Kanıt | Gerekçe | Öncelik | Efor |
|---|---|---|---|---|---|---|
| 01 | Privacy Policy | **Kısmen** (0.4.0: Uygulanmaz · 0.5.0: Yapmalıyız) | §1'deki ağ araması; SPEC REQ-3/REQ-8; [T005 kartı](../delix/tasks/T005-docs-feedback.md) | 0.4.0 yazara veri göndermez, politika gerekmez. 0.5.0 public issue'ya kullanıcı adı + ortam bilgisi + metin gönderir. T005 README "Feedback" bölümü opt-in'i ve temizlemeyi anlatıyor ama **"bu bilgi public olur, kim görür, nasıl silinir, kime yazılır"** cümleleri yok. Uzun bir politika değil, kısa bir "Data & privacy" bölümü yeter. | **P0** | S |
| 02 | Terms & Conditions | **Kısmen** | [LICENSE](../../LICENSE) MIT "AS IS" + sorumluluk reddi | Ücretsiz açık kaynakta MIT'nin garanti/sorumluluk reddi T&C'nin işini görür; ayrı T&C gereksiz. Eksik olan README'de görünür bir cümle: hook'lar araç çağrılarını engeller ve komut çalıştırır, kullanım riski kullanıcıdadır. | P1 | S |
| 03 | GDPR uygulanabilirliği | **Kısmen** ⚖️ | §1 | 0.4.0'da yazar veri işlemez, GDPR dışı. 0.5.0'da AB'li bir kullanıcı issue açarsa repo sahibi o kişisel veriyi (kullanıcı adı, metin) tutar ve silme talebine muhatap olur (issue'yu yazan silemez, yalnız düzenleyebilir; silme repo yöneticisindedir). Yazarın "controller" sayılıp sayılmadığı ve KVKK karşılığı hukukçu sorusu; pratik yükü küçük: iletişim kanalı + silme süreci. | P1 | S |
| 04 | Cookie Consent | **Uygulanmaz** | Web arayüzü yok; `delix-board` Claude Code içinde yerel panel | Çerez yok. Plugin delix.dev sitesinde tanıtılırsa çerez o sitenin (`prj_DelixSite`) işi. | — | — |
| 05 | Legal Basis | **Kısmen** ⚖️ | SPEC REQ-1 (varsayılan kapalı), REQ-6 (TTY + `SEND <hash>`) | 0.5.0 için dayanak fiilen **açık rıza / kullanıcının kendi eylemi**: varsayılan kapalı, her gönderim terminalde elle onaylanır. Teknik tasarım doğru; README'de bunun söylenmesi yeter. | P1 (01 ile birlikte) | S |
| 06 | Marketing Consent | **Uygulanmaz** | E-posta toplama, bülten, iletişim formu yok (repo taraması) | Pazarlama iletişimi yok. | — | — |
| 07 | Data Deletion | **Yapmalıyız** (0.5.0) | SPEC §4: `drop` → `status: dropped`, "dosya silinmez" | İki taraf: (a) yerel kuyruk `~/.claude/delixcrew/feedback/` hiç silinmiyor; README'de tek komutluk silme yolu yazılmalı (gerekirse `purge` alt komutu). (b) Gönderilmiş issue için silme talebi kanalı (yazar e-postası ya da SECURITY.md'deki kanal). | P1 | S |
| 08 | Data Retention | **Kısmen** | `.gitignore` yalnız `docs/delix/BOARD.md` ve `evals/results/` hariç tutuyor; `STATE.json` `cost_usd` alanı | Yazar veri saklamaz. Ama plugin kullanıcının reposuna `docs/delix/STATE.json` (maliyet), kart metinleri ve spec yazar; bunlar main'e commit edilir. Public repoda kullanıcı bunu bilmeden yayımlayabilir. README "Neler commit edilir" cümlesi. | P2 | S |
| 09 | Data Processing Agreements | **Uygulanmaz** | Alt işleyen yok; Anthropic ve GitHub ile ilişki kullanıcının kendi sözleşmesi | Yazar adına veri işleyen üçüncü taraf yok. 0.5.0'da GitHub platform sağlayıcıdır, DPA gerekmez (⚖️ teyit 03 ile birlikte). | — | — |
| 10 | Third-Party Disclosure | **Kısmen** | [README.md](../../README.md) "Requirements": `gh`, `gitleaks`, `git`, `python3` | Araçlar listelenmiş ama **veri akışı** yazılmamış: Claude Code → Anthropic, `gh` → GitHub, `verify` → kullanıcının ssh hedefi, 0.5.0 → public issue. Bir paragraf. | P1 | S |
| 11 | Data Security | **Kısmen** | Hook'lar, gitleaks, korunan yollar; CI'da pin'li action SHA, `permissions: contents: read`, `persist-credentials: false` ([tests.yml](../../.github/workflows/tests.yml)). **Eksik:** `gh api …/branches/main/protection` → "Branch not protected"; `…/rulesets` → `[]`; `…/private-vulnerability-reporting` → `enabled: false`; `security_and_analysis` → secret scanning, push protection, Dependabot `disabled` | Plugin kodu kullanıcı makinesinde, her oturumda, Write/Edit/Bash öncesi çalışır ve GitHub kurulumu main'i izler. Repo hesabı ele geçirilirse kötü kod tüm kullanıcılara gider. Ayrıca bkz. §3 E2 (Stop hook'u projenin tanımladığı komutu çalıştırır). | **P1** | S–M |
| 12 | Data Breach Procedure | **Yapmalıyız** (güvenlik olayı olarak) | `SECURITY.md` yok (`git ls-files`) | GDPR anlamında ihlal edilecek veri yazarda yok. Gerçek senaryo: kötü sürüm ya da hook açığı. Gereken: SECURITY.md (bildirim kanalı, yanıt süresi hedefi, desteklenen sürüm) + kısa olay adımları (sürümü geri çek, `plugin.json` sürüm artışıyla düzeltme, CHANGELOG ve issue ile duyuru). | P1 | S |
| 13 | Intellectual Property | **Kısmen** ⚖️ · **Açık soru** | LICENSE "Copyright (c) 2026 Tahir Cengiz"; [delix-hazirlik.md](../rename/delix-hazirlik.md) §1: "`delix` zaten şirket markası (delix.dev …)"; logo konseptleri [docs/rename/logo-konseptler/](../rename/logo-konseptler/) | Üç soru: (a) **Marka:** `delix`/`delixcrew` şirket markasıyla aynı ailede; şirket mi kişi mi sahibi, tescil var mı, üçüncü bir "Delix" ile çakışma var mı? (b) **Telif sahibi:** LICENSE kişiyi gösteriyor; plugin şirket ürünüyse telif sahibi şirket olmalı. (c) **Model çıktısı:** kodun büyük kısmı Claude ile yazıldı; Anthropic koşulları çıktı haklarını kullanıcıya bırakır, ama yapay zekâ üretimi kodun telif korumasına girip girmediği ülkeye göre belirsiz. MIT dağıtımını engellemez; "kim sahip" sorusu şirket ürünü olacaksa önemlidir. Kullanıcıya soruldu (§5). | P1 (a, b) · P2 (c) | S + hukukçu |
| 14 | Open-Source Licences | **Yapıyoruz** | Çalışma zamanı bağımlılığı yok: Python yalnız stdlib; board yalnız host modülü `claude-code` import eder. Harici araçlar kullanıcı kurar, repoda paketlenmez (`gitleaks` MIT, `gh` MIT, `git` GPL-2.0). CI: `actions/checkout`, `actions/setup-node` (MIT), `@anthropic-ai/claude-code@2.1.309` (Anthropic tescilli lisans; yalnız CI'da çalıştırılır, dağıtılmaz) | NOTICE gerekmez. Claude Code'un CI'da kullanımının lisansına uygunluğu **doğrulanmadı** (normal kullanım gibi görünüyor). | P2 | S |
| 15 | Payments & Subscriptions | **Uygulanmaz** | Ödeme, abonelik, lisans anahtarı yok | Ücretsiz MIT. Kullanıcının Anthropic faturası kendi hesabı; README maliyet uyarısı veriyor (evals "costs money"). Ücretli sürüm olursa yeniden değerlendirilir. | — | — |

## 3. Listede olmayan ama bu ürün için daha önemli maddeler

| # | Madde | Durum | Kanıt | Gerekçe | Öncelik | Efor |
|---|---|---|---|---|---|---|
| E1 | **"Kullanıcı makinesinde ne çalışır" açıklaması** | **Yapmalıyız** | README "Known limits" hook'ların her oturumda yüklendiğini söylüyor; Stop hook'un test komutunu çalıştırdığı, gitleaks'in çağrıldığı tek yerde toplu değil | Plugin kurulunca 3 hook her oturumda çalışır; `python3` yoksa **tüm** Write/Edit/Bash bloklanır; Stop hook 540 sn'ye kadar komut çalıştırır. Kullanıcı bunu kurmadan önce görmeli. | P1 | S |
| E2 | **Stop hook güven sınırı** (güvenlik) | **Yapmalıyız** | [stop_gate.py](../../scripts/stop_gate.py): `cwd/.delix/card` varsa `docs/delix/delix.json` `test_command` + `extra_checks` `shell=True` ile çalışır; [common.py](../../scripts/common.py) `card_path` yalnız dosyanın varlığına bakar | Bu iki dosyayı commit etmiş bir yabancı repo açılırsa, plugin kurulu kullanıcıda tur sonunda o repoda tanımlı kabuk komutu çalışır. Claude Code'un klasör güven diyaloğunun plugin hook'larını bu durumda koruyup korumadığı **doğrulanmadı**. Önlem adayı: `.delix/card` git'te izleniyorsa (`git ls-files --error-unmatch`) hook pasif kalsın; en azından SECURITY.md'de açıkça yazılsın. | **P1** | S–M |
| E3 | **Repo ve sürüm güvenliği** (tedarik zinciri) | **Yapmalıyız** | Madde 11 kanıtı; README: GitHub kurulumu `plugin.json` sürümü değişince güncellenir | main korumasız, push protection kapalı. Branch ruleset (force push/silme yasak, PR + CI zorunlu), secret scanning + push protection, private vulnerability reporting, Dependabot (yalnız `github-actions`), hesapta 2FA. | **P1** | S |
| E4 | **SECURITY.md** | **Yapmalıyız** | `git ls-files` içinde yok | 11, 12, E2 ve E3'ün belge tarafı. | P1 | S |
| E5 | **Anthropic ile ilişki ve marka kullanımı** | **Kısmen** | Plugin adı "Claude" içermiyor; README "for Claude Code" diyor | Adlandırma doğru (Claude markası üründe yok). Eksik: "Anthropic ile bağlantılı değildir, onaylanmamıştır" cümlesi. Resmî plugin dizinine başvurulursa o dizinin koşulları ayrıca okunmalı (bugün başvuru yok). | P2 | S |
| E6 | **Public repoda iç bilgi ve üçüncü taraf içeriği** | **Kısmen** | `STATUS.md` 39, [pilot retro](../retro/2026-11-01-pilot-retro.md) 12 satırda `GTR9` / `LLMPortal` adı geçiyor; [board ekran görüntüsü](../../plugins/delix-board/assets/board-terminal-pano.png) `prj_LLMPortal` kart başlıklarını gösteriyor; IP, iç alan adı, `/Users/<ad>` **yok** (`git grep` `192.168.`, `*.lab.delix.dev`, `tail1dafee`, `msentra` boş). [Araştırma notları](../research/) üçüncü taraf blog ve dokümanlardan tırnaklı alıntılar içeriyor (60+ karakterlik tırnaklı dizi: 552) | İç ağ sızıntısı yok. Kalan: (a) pilot proje adları ve görev başlıkları; LLMPortal bir müşteri/işveren projesiyse gizlilik sorunu olur (varsayım: kullanıcının kendi projesi). (b) Araştırma notlarındaki alıntılar kaynaklı ve kısa görünüyor, ama uzun alıntılar kısaltılmalı ya da notlar public repodan çıkarılmalı. | P2 | M |
| E7 | **Commit geçmişinde kişisel e-posta** | **Bilgi** | `git log --format=%ae`: 5 commit `tahircengiz@gmail.com` (`acec1e6`, `956ce29`, `20c4ef9`, `7fc8c71`, `2260271`, 2026-11-02), 49 commit noreply | Public geçmişte kişisel e-posta görünür. Geçmişi yeniden yazmak gerekmez; yeni commit'ler noreply ile gidiyor. Kullanıcıya bilgi. | — | — |
| E8 | **Export control** | **Uygulanmaz** (⚖️ teyit önerilmez) | Şifreleme kodu yok; yalnız `sha256` parmak izi (SPEC §4) | Kamuya açık açık kaynak, kripto işlevi yok. | — | — |

## 4. Kararlar (bu değerlendirmede verilenler, geri alınır)

- **L1:** İşler **delix kartı değil, düz GitHub issue** olarak açılır. Neden: etkin SPEC (öz-besleme) ve wave planı
  T001–T005'i kapsıyor, T001–T003 için açık PR'lar var (#4, #5, #6). Yasal işler bu spec'in kapsamında değil; kart açmak ya
  spec'i büyütür ya da paralel ikinci spec ister. Issue'lar ileride `/delixcrew:start #<n>` ile karta çevrilebilir
  (REQ-10).
- **L2:** Öz-besleme gizlilik metni (madde 01/05/07) T005'in README "Feedback" bölümüne girmeli; T005 kısıtları spec'ten
  birebir alındığı için ekleme orkestratör kararıyla yapılır. Issue bunu **0.5.0 yayın engeli** olarak işaretler.
- **L3:** Ortak görev panosunda bu proje için proje yok (`list_projects`: Cortex, Ev, HomeLab, MaxAI, MCP deneme,
  ModelServ, Ortak, Tesla-project, TestThis). Görevler yalnız GitHub'a açılır.
- **L4:** Repo ayar değişiklikleri (ruleset, secret scanning, PVR) issue olarak yazılır, otomatik uygulanmaz: dış etkili
  ayar, kullanıcı onayı ister.

## 5. Açık sorular

1. **Marka ve telif (madde 13):** `delix` şirket markası; plugin kişisel proje mi, şirket ürünü mü? Tescil var mı?
   Önerim: hukukçuya sormadan önce kısa bir ön tarama (TÜRKPATENT, EUIPO, USPTO "delix" sınıf 9/42) ve kararı
   STATUS.md'ye K numarasıyla yazmak; şirket ürünüyse LICENSE telif satırı şirket adına çevrilir.
2. **⚖️ Hukukçu gereken maddeler:** 03 (GDPR/KVKK'da repo sahibinin rolü), 05 (dayanak), 13 (marka, telif sahibi,
   yapay zekâ üretimi kod), 09 teyidi.
3. **LLMPortal** pilot verileri (STATUS, retro, ekran görüntüsü) üçüncü bir tarafın gizli bilgisi mi? Varsayım: hayır.

## 6. İş listesi (issue taslakları)

Her issue'nun sahip rolü ve kabul ölçütü vardır. Etiketler repoda mevcut olanlardan seçildi (`bug`, `documentation`,
`enhancement`, `question`); onaylanırsa `legal` ve `security` etiketleri eklenir.

| ID | Başlık | Öncelik | Efor | Rol | Etiket |
|---|---|---|---|---|---|
| I1 | 0.5.0 öz-besleme için veri ve gizlilik bölümü (yayın engeli) | P0 | S | docs | documentation, legal |
| I2 | Stop hook: git'te izlenen `.delix/card` ile yabancı repoda komut çalıştırma | P1 | S–M | backend | bug, security |
| I3 | Repo sertleştirme: ruleset, secret scanning, PVR, Dependabot | P1 | S | devops (sahip) | security |
| I4 | SECURITY.md ve README "Bu plugin makinende ne yapar / veri nereye gider" | P1 | S | docs | documentation, security |
| I5 | Marka, telif sahibi ve model çıktısı sahipliği kararı | P1 | S + hukukçu | sahip + hukukçu | question, legal |
| I6 | Öz-besleme kuyruğu için yerel silme yolu (`purge` ya da belgeli komut) | P2 | S | backend | enhancement |
| I7 | Public repo içerik gözden geçirmesi (pilot adları, ekran görüntüsü, araştırma alıntıları) | P2 | M | docs | documentation, legal |

Gövdeler ve kabul ölçütleri issue'larda; bağlantılar issue'lar açılınca bu tabloya eklenir.
