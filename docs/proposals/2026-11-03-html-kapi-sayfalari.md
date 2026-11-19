# Öneri — insan kapılarında HTML karar sayfası

> Durum: **öneri, beklemede** (2026-11-19) · S1–S7 önerileri kabul edildi (kullanıcı, 2026-11-03: "öneri") · S1
> prototipi yapıldı (§10) · Plugin kodu yok. 0.6.0 kapandı; ondan sonraki M spec (Spec C, kapı 1 2026-11-04) sayfasız
> geçti, S6'nın iki ölçümünden biri böylece kaçtı. Sıradaki adım: bir sonraki M spec'in kapı 1'inde, onaydan önce, sayfa
> S1 yöntemiyle elle üretilir ve §7 ölçülür (§10'daki "anlamlı ölçüm"). Plugin'e alma (`/delixcrew:start` → grill →
> spec) bu ölçümden sonra kararlaştırılır. Bu not bir spec değildir; K numarası almaz, kararlar aşağıda S1–S7.

## 1. Neden, neden şimdi değil

Kaynak: Thariq Shihipar, "Using Claude Code: The unreasonable effectiveness of HTML" (claude.dev, 2026-05-20) ve eşlik
galerisi (thariqs.github.io/html-effectiveness). Tez: uzun Markdown okunmuyor; tek dosyalık HTML (tablo, SVG, açılır
bölüm, "değişiklikleri kopyala" düğmesi) insanı ajanın kararlarına bağlı tutuyor. **Tez ölçümsüz:** yazar "kişisel görüş"
diyor, token farkına ve USD maliyetine sayı vermiyor (Obsidian notu, Eleştirel Not).

delix'te bu tezin sınanacağı yer belli: retro'ya göre insan kapıları **taşıyıcı**
([pilot retro §2](../retro/2026-11-01-pilot-retro.md)). Kapı 1 bugün yalnız `AskUserQuestion: Do you approve the spec?`
([spec §4](../../skills/spec/SKILL.md)); kullanıcı `SPEC.md`'yi Markdown olarak okuyup onaylıyor (0.6.0 SPEC 248 satır, 0.5.0 rev 3 SPEC 304 satır). Aynı
retro bir uyarı da taşıyor: yazılan ama okunmayan görünüm (`PANO.md`) **çıkarılabilir** çıktı. HTML sayfası da aynı akıbete
uğrayabilir; bu yüzden öneri ölçümle başlar (§7) ve tutma/çıkarma kuralı baştan yazılır.

Şimdi değil: 0.6.0 triage dalgası sürüyor (STATUS §8: T010 son düzeltme turu, T012 incelemede, T013 açık). Bu not
`docs/delix/`'e dokunmaz, spec açmaz.

Kapsam dışı: genel bir "HTML yap" skill'i (artifact-design skill'i ve Artifact aracı sayfa yapımını zaten kapsıyor;
kullanıcı kuralı "üçüncü tekrarda skill"); delix-board'a HTML eklemek (zaten canlı SVG pano çiziyor, durum gösterir, karar
içeriği göstermez; iki iş çakışmıyor).

## 2. Kapsam

### Pilot: kapı 1 karar sayfası
`/delixcrew:spec` §4'te, `AskUserQuestion`'dan hemen önce üretilir. İçerik, sırayla:

| Bölüm | İçerik | Biçim |
|---|---|---|
| Başlık şeridi | spec adı, Size · Tier, rev, `SPEC.md` sha256 ilk 12 hane, üretim zamanı | metin |
| Değiştirmek isteyeceğin kararlar | K kararları **değişme ihtimaline göre** sıralı (yüksek → düşük), her biri "spec'in seçimi" açık, alternatif(ler) `<details>` içinde kapalı; kullanıcı alternatifi seçebilir ya da not yazabilir | kart + radyo + metin kutusu |
| Mimari / veri akışı | bileşenler ve oklar; dış sisteme yazım sırası varsa (spec skill §1 madde 4, zorunlu soru) numaralı | satır içi SVG |
| Gereksinimler | REQ-n başlıkları, senaryolar kapalı `<details>` | liste |
| Riskler | risk · olasılık · etki · önlem; güvenlik notu satırları | tablo |
| Tier ve 🔐 | korunan yollar, 🔐 gerektiren kartlar/yollar, güvenlik notu | vurgulu kutu |
| Açık sorular | spec §8 maddeleri, her birine cevap kutusu | liste + metin kutusu |
| Güvenebileceğin mekanik iş | DoD, test komutları, dosya listesi | kapalı `<details>` |
| Export | **"Değişiklikleri prompt olarak kopyala"** | düğme + seçilebilir `<textarea>` yedeği |

Export metni yalnız kullanıcının değiştirdiği yerleri taşır ve spec'e bağlıdır (örnek):

```
Gate 1 change requests · SPEC sha 3f2a9c1b7e04 · rev 2
- K112: use the alternative "write the label after the comment" instead of the spec's pick
- REQ-3: <user's note>
- Open question 2: <user's answer>
```

Orkestratör yapıştırılan metindeki sha'yı `SPEC.md` ile karşılaştırır; farklıysa sayfayı yeniden üretir, isteği
uygulamaz (triage'daki `issue_sha` bağının aynısı, K123).

### Sonraki aday 1: kapı 2 merge sayfası
[review §4](../../skills/review/SKILL.md)'teki "tek ekran"ın HTML hali: diff (`git diff <default>...<sha>`, `.delix/diff.patch`
zaten üretiliyor) üzerinde qa/security bulguları **kenar notu** olarak (`qa.md` ve `security.md` çıktısı zaten
`<file:line>` taşıyor), şiddet rengi, DoD ✔/✘, inceleyici kararları. Tier 3'te isteğe bağlı **merge öncesi quiz**
(diffin davranışını soran 4–6 soru). Quiz bir öz-kontroldür, kapı değildir: galerideki örnekte de 6/6 yalnız bir
görüntü durumu, merge'i engelleyen bir mekanizma yok. Merge yine kullanıcının elinde.

### Sonraki aday 2: W0 triage panosu
Açık issue'lar karar sütunlarında (accept / needs-info / duplicate / wontfix / defer), architect job D önerisiyle önceden
dizili; kullanıcı kartları taşır, gerekçeyi düzeltir. **Brif'teki "export = `triage.py apply` girdisi" onaylı spec'le
çelişiyor:** `apply` yalnız kullanıcının terminalinde, TTY ve issue başına `--confirm <hash>` ile koşar (REQ-6), hash ancak
`record` → `preview`'dan sonra doğar, toplu `apply` yok (K117). Panonun export'u en fazla sohbete yapıştırılan bir karar
listesi olabilir (`accept #12`, `wontfix #13`, …); bunun REQ-4'ü ("her issue ayrı karar") karşılayıp karşılamadığı
yoruma açık, K117 "her karar ayrı sohbet onayı" diyor. Pano bu yüzden **K117'yi gözden geçiren ayrı bir spec turu**
ister, T010 merge olmadan başlayamaz ve üç sayfa içinde en riskli girdiyi (dış kullanıcının issue metni) taşır. Bkz. S5.

## 3. İlke: kaynak doğru Markdown/JSON'da kalır

- `SPEC.md`, kartlar ve `STATE.json` kaynak doğrudur. HTML **türetilmiş görünümdür**: elle düzenlenmez, commit edilmez,
  her üretimde baştan yazılır. Kullanıcının sayfada yaptığı değişiklik dosyaya değil export metni üzerinden sohbete
  döner; spec'i orkestratör günceller.
- Yer: `docs/delix/views/` (ör. `gate1-<spec-sha>.html`), `/delixcrew:start` `.gitignore`'a ekler (`BOARD.md` ile aynı
  emsal, K36). Uygulayıcı `docs/delix/**`'e yazamadığı için (yazma kapısı) sayfayı değiştiremez.
- Artifact yayını isteğe bağlı ikinci kanal: dosya her zaman yazılır; Artifact aracı olan oturumda (Desktop) aynı dosya
  özel (private) olarak yayımlanır ve link verilir. Bkz. S3.
- **Görünüm onay kanalı değildir.** Kapı 1 onayı `AskUserQuestion`'da, 🔐 onayı sohbette global CLAUDE.md biçiminde
  kalır. Export metni "approve" taşımaz; sayfada "onayla" düğmesi yoktur. Gerekçe: iki insan kapısı zayıflamaz (triage
  REQ-3 feature ilkesi 2).

## 4. Kim üretir

- **Orkestratör oturumu**, spec §4'te ve (aday 1) review §4'te. Alt ajanlar (architect, qa, security) salt-okunur, Write
  araçları yok; sayfaya veri (bulgu, kontrol listesi) sağlarlar, dosya yazmazlar.
- Headless `claude -p` uygulayıcı koşuları sayfa üretmez; delix-board da headless oturumda hiçbir şey çizmez. `-p`
  oturumda Artifact aracının bulunup bulunmadığı **doğrulanmadı**; tasarım buna dayanmıyor.
- Üretim yöntemi (S2): model sayfanın **verisini** yazar (kararların değişme ihtimali sırası, alternatif metinleri,
  diyagram düğüm/kenar listesi, riskler) ve küçük bir JSON olarak verir; stdlib bir betik (`scripts/gate_view.py`, adı
  spec'te kesinleşir) bunu sabit şablona kaçışlı basar. Emsal K24: `/delixcrew:status` tabloyu modele yazdırmaz,
  `board.py` üretir; çıktı deterministik ve test edilebilir olur. Yargı modelde, işleme betikte.
- Alternatifler bugün `SPEC.md`'de yazılı değil (grill'de 2–3 seçenek + "My pick" sohbette kalıyor). Model onları grill
  bağlamından JSON'a taşır; spec şablonuna yeni bölüm eklenmez (kapsam büyütmez). Sonuç: sayfa grill'i yapan oturumda
  üretilirse zengin, başka oturumda üretilirse alternatifsiz olur; ikincisi kabul edilir ve sayfada yazılır.

## 5. Güvenlik

Girdiler güvenilmezdir: triage'dan doğan spec dış kullanıcının issue metnini taşıyabilir; kapı 2 sayfası PR diff'ini,
triage panosu ham issue başlık ve gövdesini basar.

1. **Kaçışsız basım yok.** Her metin betikte `html.escape` ile basılır. JS'in okuyacağı veri tek bir
   `<script type="application/json">` bloğunda; `<`, `>`, `&`, U+2028/U+2029 `\u` kaçışlı (böylece `</script>` bloğu
   kapatamaz). JS veriyi `JSON.parse` ile okur, DOM'a yalnız `textContent` / `createElement` ile yazar. Galerideki
   örnekler (quiz, triage panosu) veriyi `innerHTML` ile basıyor; o kalıp kopyalanmaz.
2. **Harici kaynak yok.** Script, stil, font, CDN, görsel URL'si yok; SVG betikte üretilir, modelin yazdığı ham SVG/HTML
   sayfaya girmez. Galerinin dört örneği de (plan, PR inceleme, quiz, triage panosu) kaynak kodunda harici kaynak
   taşımıyor (2026-11-03, `curl` + `grep`).
3. **Derinlemesine savunma:** `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src
   'unsafe-inline'; script-src 'unsafe-inline'; img-src data:; form-action 'none'; base-uri 'none'">`. Bir kaçış hatası
   olsa bile fetch, XHR, görsel ya da form ile ağa çıkılamaz; sayfa yönlendirmesini (`location = …`) CSP kapatmaz, bu
   yüzden birincil savunma madde 1'deki kaçıştır. Artifact yayınında sayfa kendi `<head>`'ini taşımaz (yayın kabuğu sarar),
   bu yüzden meta CSP orada yazılmaz; ağ kısıtını Artifact'ın kendi CSP'si koyar (Artifact sözleşmesi: izinli CDN dışı her
   host ve fetch/XHR engelli; belgeden okundu, denenmedi). Yerel dosya sürümünde CSP meta şablonun `<head>`'indedir.
4. **Export'u kullanıcı yapıştırır**, sayfa hiçbir yere göndermez (fetch yok, form yok). Yapıştırılan metin kullanıcının
   kendi mesajıdır; içinde issue'dan gelen alıntı olsa bile orkestratör onu talimat değil değişiklik isteği olarak okur.
5. **Sır yok:** spec zaten sır değeri taşımaz (spec kuralı: `secret get` yolu yazılır). Artifact yayını özel başlar;
   özel projede spec'in claude.ai'ye gitmesi yine de bir dış yazımdır, bu yüzden S3'te kullanıcıya bırakılır.
6. Test (spec'te REQ olur): kötü niyetli fixture (`</script><img src=x onerror=…>`, `<!--`, U+2028, RTL override)
   sayfada metin olarak görünür, çalışmaz; çıktıda `<script src`, `http://`, `https://` geçmez; yön denetim karakteri
   ham geçmez.
7. **Yön denetim karakterleri** (U+202A–202E, U+2066–2069) `html.escape`'ten geçer, ama metni görünürde yeniden dizer
   (Trojan Source sınıfı): kullanıcı issue'dan gelen bir cümleyi olduğundan farklı okuyabilir. Betik bunları görünür
   işarete çevirir (`[U+202E]`). Prototipte bulundu ve düzeltildi (§10).

## 6. Değişikliğin ulaşacağı yerler (spec için ön liste)

`skills/spec/SKILL.md` §4 (üretim adımı) · yeni `scripts/gate_view.py` + şablon · `tests/view_tests.sh` + CI
(`.github/workflows/tests.yml`) · `skills/start/SKILL.md` (`.gitignore` satırı) · README/README.tr · CHANGELOG ·
`.claude-plugin/plugin.json` sürümü. Ajanlara, hook'lara ve delix-board'a dokunmaz. Tahmini boy **M · Tier 2**
(güvenilmez metni işleyen yeni betik; korunan yol yok). Doğrulanmadı, start'ta kesinleşir.

## 7. Maliyet ve etki ölçümü

Prototipte iki ölçü alındı (§10); geri kalanı pilotta ölçülecek.

| Ölçü | Nasıl | Taban |
|---|---|---|
| Sayfa başına USD | orkestratör transkriptinde görünüm adımının `usage` kayıtları (retro yöntemi, Opus liste fiyatı) | prototipte 3,24 USD, üst sınır (§10); şablon hazırken **ölçülmedi** |
| Kapı 1'de istenen değişiklik sayısı | kapı 1 ile onay arasında kullanıcının istediği K/REQ/açık soru değişikliği | 0.6.0: 0 (§10); 0.5.0 (rev 1–3): **ölçülmedi** |
| Kapı 1 süresi | spec hazır → onay | aynı transkriptlerden |
| Sayfa kullanıldı mı | export metni yapıştırıldı mı (transkript) + kullanıcının tek satırlık beyanı | – |
| Kapı 2'de spec kaynaklı bulgu | review'da "spec'te belirsizdi" sınıfı bulgu sayısı | retro K30/K31 |

Tutma/çıkarma kuralı (S6): iki M spec boyunca ölçülür; sayfa en az birinde kullanıldıysa ve maliyeti spec fazının
belirlenen payını aşmıyorsa tutulur, aksi halde `PANO.md` gibi çıkarılır. "Daha çok değişiklik istendi" tek başına
başarı da başarısızlık da değildir: kapı 1'de yakalanan değişiklik, review turunda yakalanandan ucuzdur (pilot dersi, K31:
E.6'da grill'in sormadığı yazım sırası bulgusu T002 düzeltme turunda çıktı, E.7'de spec'te yakalandı ve tur gerekmedi).

## 8. Açık kararlar (her biri önerili)

| # | Soru | Seçenekler | Önerim |
|---|---|---|---|
| S1 | Plugin'e almadan önce prototip | 1) 0.6.0 SPEC'inden (onaylı, salt okunur) tek sayfalık elle prototip, scratchpad'de, plugin'e girmez · 2) doğrudan grill → spec | **1**, çünkü tez ölçümsüz; kullanıcı sayfaya bakıp "kapı 1'de bunu kullanır mıydım" diyebilir, kod yazılmadan karar verilir |
| S2 | Üretim yöntemi | 1) model serbest HTML · 2) betik yalnız `SPEC.md`'den · 3) model JSON verir, betik şablona kaçışlı basar | **3**, çünkü sıralama ve alternatif modelin yargısı, kaçış ve SVG ise deterministik ve test edilebilir olmalı (K24 emsali) |
| S3 | Yayın yeri | 1) yalnız yerel dosya · 2) yalnız Artifact · 3) dosya her zaman + Artifact aracı varsa özel yayın | **3**, çünkü plugin public ve CLI'da da çalışmalı; Desktop'ta telefondan açılan link kullanıcının çok cihazlı çalışmasına uyar |
| S4 | Export onay taşıyabilir mi | 1) hayır, yalnız değişiklik isteği · 2) "approve" satırı olabilir | **1**, çünkü kapı 1 ve 🔐 onayı sohbette kalmalı; görünüm onay kanalı olursa iki insan kapısı zayıflar |
| S5 | W0 triage panosu | 1) bu öneriden çıkar; W0'ı düz akışla koş, ölç, gerekirse K117'yi gözden geçiren ayrı spec · 2) kapı 1 ile aynı spec'e al | **1**, çünkü onaylı spec'le (REQ-4/6, K117) çelişiyor ve T010'a bağlı |
| S6 | Tutma eşiği | 1) sayfa maliyeti ≤ spec fazının %10'u ve iki spec'in en az birinde kullanıldı · 2) eşik yok, kullanıcı beyanı | **1**, çünkü `PANO.md` dersi: ölçütsüz görünüm sessizce bayatlar. %10 ölçülmemiş bir başlangıç değeri, pilottan sonra düzeltilir |
| S7 | Kapı 2 quiz | 1) yalnız Tier 3, gönüllü, merge'i engellemez · 2) pilota al | **1** ve kapı 2 sayfasından sonra, çünkü sorulara cevap üretmek ayrı maliyet; önce kenar notlu diff'in değeri görülmeli |

## 9. GitHub issue taslağı (açılmadı)

Onaylanırsa 0.6.0 sonrası triage'ın ilk iç girdisi olabilir. **Açmak dışa yazmadır; kullanıcı onayı olmadan açılmaz.**

```
Title: Gate 1: optional HTML decision page derived from SPEC.md
Kind: feature

Problem: Gate 1 asks "Do you approve the spec?" over a 250–300 line Markdown file. Decisions, alternatives
and risks are hard to review; change requests come back as free text.

Proposal: before the gate-1 question, the orchestrator writes a single-file HTML view of SPEC.md
(decisions sorted by how likely they are to change, alternatives collapsed, data-flow SVG, risks, Tier/🔐,
open questions, a "copy changes as prompt" button bound to the SPEC hash). SPEC.md stays the source of
truth; the page is generated, gitignored, never an approval channel. No external scripts; all text escaped.

Measure: USD per page, change requests at gate 1, time to approval; drop it if unused after two specs.
```

## 10. S1 prototipi (2026-11-03)

Onaylı 0.6.0 SPEC'inin (sha `fe95dea7edeb`) kapı 1 sayfası, S2 yöntemiyle: veriyi orkestratör yazdı, stdlib bir betik
sabit şablona `html.escape` ile bastı. Betik ve çıktı git dışında kaldı (`.delix/proto/`, `.git/info/exclude`); plugin'e
girmedi. S1'deki scratchpad yerine worktree kullanıldı: worktree'de T011'den kalan `.delix/card` yazma kapısını
uygulayıcı kipine alıyor ve worktree dışına yazımı reddediyor. Yayın: özel Artifact (sürüm 2, yalnız sahibine açık).

| Kontrol | Sonuç |
|---|---|
| Alternatiflerin kaynağı | 0.6.0 grill'inin 6 sorusu ve seçenekleri orkestratör transkriptinden betikle çıkarıldı (K106–K110 ve arşiv yeri). Grill oturumu dışında da bulunabiliyor, ama bu ek bir adım. K117 ve K116'nın alternatifleri türetildi ve sayfada öyle işaretlendi. |
| Kaçış | Kötü niyetli fixture (`</script><img onerror>`, `<!--`, U+2028, RTL override): ham `<img` 0, kaçışlı 49, `<script` 1 (sayfanın kendi betiği; veri DOM'da, betikte fixture karakteri 0). §5 madde 1'deki JSON veri bloğu prototipte yok, o yol **denenmedi**. |
| Yön karakteri (kontrol turu) | RTL override ham geçiyordu ve fixture metnini tarayıcıda ters diziyordu (`"'` yerine `'"`); sayfanın kendi etiketleri ayrı kutuda olduğu için etkilenmedi. Betikte görünür işarete çevrildi: ham U+202E 49 → 0, ekranda `[U+202E]` doğru sırada. Gerçek sayfa değişmedi (SPEC'te bu karakter yok), Artifact yeniden yayımlanmadı. |
| Harici kaynak | `http(s)://` 0, `innerHTML` 0; JS `new Function` ile ayrıştırıldı |
| Yerel dosya biçimi | Prototip yalnız Artifact gövdesini üretir: `<head>`, `meta charset` ve CSP meta yok, yerel önizleme ayrı sarmalayıcıyla yapıldı. Sarmalayıcısız sunulunca başlık bozuk kodlandı (`KapÄ±`). §5 madde 3'teki CSP meta ve S3'ün "dosya her zaman" yolu **denenmedi**; şablon iki biçimi de üretmeli. |
| Etkileşim (tarayıcı paneli, yerel sunucu) | K110'da alternatif + not + açık soru 2 cevabı, sayaç 3, export metni SPEC sha'sıyla doğru. Pano erişimi panelde reddedildi, yedek yol metni seçti. Artifact içinde kopyalama tıklanarak **denenmedi**. |
| Telefon ve tema | İlk sürümde 375 px'te sayfa 894 px'e taştı (grid öğesi diyagramın `min-width`'i yüzünden daralamıyordu); `min-width: 0` ile 375 = 375. Koyu tema okunuyor. |
| Maliyet | **3,24 USD**, 27 API çağrısı, ≈ 8 dk (bu oturumun transkripti; Opus 5.5 liste fiyatı: çıkış 53,7K, cache yazma 90,7K, cache okuma 7,18M). Üst sınırdır: transkript taramasını, tarayıcı kontrollerini, iki düzeltmeyi ve şablonu ilk kez yazmayı içerir. Bedelin %44'ü, yaklaşık 200K bağlamın her çağrıda cache'ten okunması. Şablon hazırken sayfa başına maliyet **ölçülmedi**. |

Dersler:
- Taşma hatası ancak ölçülerek bulundu. Sabit şablonda bir kez düzeltilir ve testle korunur; her sayfayı serbest yazan
  yöntemde (S2 seçenek 1) her seferinde yeniden çıkabilir. S2 kararını destekliyor.
- İlk sayfada bir sınıflama yanlışı vardı: K112 "grill'de sorulmadı" diye işaretlenmişti, oysa yazım sırası K108 sorusunun
  seçenek metninde geçiyordu. Sürüm 2'de düzeltildi. Kaynak etiketini model elle koyuyor ve yanılabiliyor; spec'e
  "alternatifin kaynağı" alanı girerse bu, architect incelemesinin kontrol edeceği bir madde olur.
- Kapı 1'de istenen değişiklik (§7), ilk ölçüm (2026-11-03): kullanıcı sayfaya baktı, **0 değişiklik** ("değiştirmezdim").
  Gerçek kapı 1 de Markdown ile 0 değişiklikti: rev 2 ilk soruda "Onaylıyorum" cevabı aldı (orkestratör transkripti).
  Bu spec iki yolu ayırt etmiyor. Ölçüm geriye dönük (spec onaylanmış ve uygulanmakta, kullanıcı içeriği biliyordu) ve
  n = 1. Sayfanın Markdown'dan daha kolay okunup okunmadığı sorulmadı. Anlamlı ölçüm, sıradaki gerçek M spec'te onaydan
  **önce** yapılacak (S6: iki spec).

