# delix-board — tech spec ve mimari

Tarih: 2026-11-02 · Durum: **onaylandı** (2026-11-02, "Onayla, kodla") · Sürüm: delix-board 0.1.1 (delix 0.2.1 değişmez)

## 1. Amaç

delix akışında insan uzun süre bekliyor: GTR9'da `tests/run_all.sh` (~11 dk), imaj derlemesi, CI, `delix:qa` /
`delix:security` alt ajanları. Bugün durumu görmenin tek yolu `/delix:status`'un sohbete bastığı markdown tablo.
delix-board, Claude Code'un yanında duran **canlı bir panel**dir: kartları, kapıları, bekleyen koşuyu ve ölçümleri
sohbete yazı dökmeden gösterir. Salt okunur; delix'in hiçbir dosyasına yazmaz.

## 2. Kullanıcı kararları (değişmez)

- **K1 yüzey:** canlı Pane + istemin üstünde band (AbovePrompt) + olaylarda toast ve status satırı. Artifact sayfası yok.
- **K2 görünümler:** (a) genel pano, (b) bekleme, (c) kart ayrıntısı, (d) ölçüm grafikleri.
- **K3 paket:** ayrı eşlik plugin'i, aynı repo (`prj_Ekip`) ve aynı marketplace (`delix-local`); delix'in kendisi
  değişmez; headless uygulayıcılar ve `claude -p` UI yüklemez.

## 3. Kapsam dışı

Karta yazma, kapı onaylama, merge, komut çalıştırma düğmeleri (panel yalnız gösterir; kapılar sohbette kalır,
delix spec §14 "ajan panodan komut almaz" ilkesiyle aynı). GTR9'a kendi başına bağlanma (ssh yok; yalnız oturumun
zaten çalıştırdığı komutun çıktısını izler). Artifact/HTML sayfası. delix'in `board.py`'sini değiştirmek.

## 4. Veri kaynakları ve okuma

Hepsi `$.fs` ve `$.process.run` ile; Node/DOM yok.

| Kaynak | Ne alınır | Not |
|---|---|---|
| `docs/delix/STATE.json` | spec, size, tier, updated, `env_owner`, waves, cards (role, tier, wave, status, rounds, pr, cost_usd, cost_attempts_usd, qa, security, approved, note), verifications | `waves` iki biçimde gelir: şablondaki `[["T001"]]` ve LLMPortal'daki `[{wave, cards, note}]`; ikisi de okunur |
| `docs/delix/tasks/T<nnn>-*.md` | kart başlığı, üst tablo satırı (STATE'te eksik alanlar için yedek, `board.py` `from_card_file` ile aynı), `## Files` maddeleri, `## Review findings` / `## İnceleme bulguları` altındaki tur maddeleri | Başlıklar Türkçe ya da İngilizce olabilir; ikisi de tanınır |
| `docs/delix/verifications/*.md` | yalnız STATE.verifications'ta adı geçen rapor yolu (ayrıntıda link/ad) | İçerik parse edilmez |
| `docs/delix/metrics.md` | kart satırı olan markdown tablolar: ilk hücrede `T\d{3}` geçen satırdan maliyet (ilk sayı, Türkçe ondalık virgül), tur, süre (`N dk`, `N,N dk`, `N sn`, `HH:MM–HH:MM`) | Serbest metin; yalnız STATE'te olmayan değerleri doldurur. Bulunamayan "ölçülmedi" |
| `git worktree list --porcelain` | worktree yolu + dal → kart eşlemesi (`.delix/card`, yoksa dal adındaki `T\d{3}`) | `board.py` ile aynı kural |
| `<worktree>/.delix/report.md` | Status (DONE…BLOCKED), PR, tek satır özet | `board.py` `report_summary` mantığı |
| `<worktree>/.delix/test-result.txt` | son 12 satır + GEÇTİ/KALDI/PASS/FAIL sayısı | Kart ayrıntısında "test sonucu" |
| STATE `previous` (arşiv STATE yolu) | önceki spec'in kartlarının status, tier, rounds, pr, cost kaydı | Uygulamada eklendi: güncel STATE'te olmayan ama dosyası duran kart **arşiv kartı** sayılır; kaydı arşiv STATE'ten okunur, wave'i yoktur, **kapı tutmaz**, panoda "Önceki spec" grubunda en sonda durur. Eski Türkçe anahtarlar (`kartlar`, `kademe`, `rol`, `tur`, `kabul`…) da okunur |

**Proje kökü:** `session.start`'taki `cwd`'den `git rev-parse --show-toplevel` ve `--git-common-dir`. Ortak dizinin
üstü (ana checkout) `docs/delix/STATE.json` taşıyorsa o kullanılır (orkestratör STATE'i ana checkout'ta yazar; uygulayıcı
worktree'deki kopya bayat olabilir), yoksa toplevel. İkisinde de yoksa **boş durum**: "Bu klasör bir delix projesi değil"
ve `/delix:start` ipucu.

**Tazeleme:** `$.clock.every(4000)` ile yalnız `stat` (mtime) okunur; değişen dosya yeniden parse edilir. Worktree
listesi 20 sn'de bir. Ayrıştırılmış görüntü (`Snapshot`) `$.state`'e yazılır; render yalnız onu okur.
Bütçe: bir tik ≤ ~15 `stat`; LLMPortal'da 22 kart dosyası mtime değişmedikçe tekrar okunmaz.

## 5. Bekleme görünümü: uzun koşu nasıl yakalanır (karar)

**Karar B1: `tool.call` hook'u, ilerleme dosyası değil.** delix değişmeyeceği için (K3) `.delix/` altına ilerleme
dosyası yazdıramayız; oturumun kendi Bash çağrısını izlemek ek sözleşme gerektirmez ve LLMPortal'daki gerçek
komutları (`ssh gtr9 '… bash tests/run_all.sh'`, `scripts/build.sh`, `gh run watch`) olduğu gibi yakalar.

- **Tanıma:** `on('tool.call', { tool: 'Bash' })` komut metnini desen listesine bakar. Varsayılanlar:
  `run_all.sh`, `build.sh`, `release.sh`, `install_trial`, `upgrade_restore_drill`, `gh run watch`,
  `gh pr checks … --watch`, `docker (compose )?build`. Etiket, eşleşen desenin kısa adıdır (`run_all.sh`).
  `userConfig.extraPatterns` (virgüllü regex listesi) ek desen verir.
- **Ön plan koşusu:** `next(e)` beklenirken satır "çalışıyor" görünür (geçen süre, önceki koşuya göre tahmini kalan).
  Bash ara çıktı akıtmadığı için ön planda canlı satır yoktur; bitince son satırlar ve sayımlar sonuçtan alınır.
- **Arka plan koşusu** (`run_in_background`, ~11 dk'lık koşularda olağan): sonuç `backgroundTaskId` ve çıktı dosyası
  yolunu verir; dosya 2 sn'de bir `stat` edilir, büyüdükçe son ~64 KB okunur → canlı son satırlar ve sayaç.
  **Bitiş:** `session.append` hook'u, görev bildirimi satırında bu görev kimliğini ve durumunu (`completed` / `failed` /
  `killed`) görünce koşuyu kapatır. Yedek: çıktı dosyası 15 dk büyümezse "sessiz" işaretlenir (bitti sayılmaz).
- **İlerleme:** takım sayısı = `=== <ad>` satırları; kontrol sayısı = `GEÇTİ|PASS|ok` ve `KALDI|FAIL` ile başlayan
  satırlar. Beklenen toplam ve süre, aynı etiketin son başarılı koşusundan (`$.store`, oturumlar arası). İlk koşuda
  yalnız sayaç ve geçen süre görünür, yüzde yok (uydurma tahmin yok).
- **Alt ajanlar:** `on('tool.call', { tool: 'Agent' })` `subagent_type` `delix:*` olanları (qa, security, architect,
  scout) aynı listeye "inceleyici" satırı olarak ekler; ön plan alt ajanı `next` dönünce kapanır.
- **Bitince:** toast (`run_all.sh bitti: 670 GEÇTİ / 0 KALDI · 10 dk 47 sn`; KALDI > 0 ise "KALDI" önde) ve status
  satırı temizlenir. Koşu sürerken status satırı: `delix · run_all.sh 6:12 · 410/670`.
- Liste son 20 koşuyu tutar (`$.state`); geçmiş süre/sayım özeti son 10 koşu `$.store`'da.

## 6. Görünümler

Pane başlığı `delix`; üstte dört sekme düğmesi (Pano · Bekleme · Kart · Ölçüm) ve proje adı + STATE `updated`.
Seçili görünüm ve kart `$.state`'te; sekme `hotkey` 1–4.

**(a) Pano.** Özet şeridi: kart sayısı, durum dağılımı (renkli yığılmış çubuk), toplam maliyet, toplam tur, açık
worktree. Wave grupları altında kart satırları: durum noktası + id + başlık + rol + tier + tur + maliyet + kapı
rozetleri (kilit = 🔐 Tier 3 açık kart, merge = kabul edilmiş ve PR var ama merge edilmemiş, escalated, needs_context /
blocked rapordan). Bir satıra basmak kart ayrıntısını açar. Altta "Bekleyen kapılar" kutusu (yoksa "Bekleyen kapı yok"),
`env_owner` doluysa ortak test ortamı kilidi, verifications özeti (ad · verdict · maliyet).

Kapı kuralları `board.py` ile birebir: Tier 3 ve açık durum → kilit; `accepted` + PR → merge; ancak PR alanı
`merge <sha>` ile başlıyorsa merge kapısı kapanmış sayılır (LLMPortal'ın kaydı; board.py bunu ayırmıyor).

**(b) Bekleme.** Aktif koşu kartı: ikon, etiket, komutun kısaltılmışı, geçen süre (tabular), ilerleme çubuğu (beklenen
süre varsa), takım ve kontrol sayaçları (GEÇTİ yeşil, KALDI kırmızı), son 8 satır (mono). Altında çalışan inceleyici alt
ajanlar ve son biten 5 koşu (sonuç ikonu, süre, sayım). Koşu yoksa: "Bekleyen koşu yok" + izlenen desenlerin listesi.

**(c) Kart ayrıntısı.** Başlık, üst bilgiler (rol, tier, wave, durum, PR, maliyet, onay), Files listesi (Create/Modify/
Test etiketli), worktree ve rapor durumu + özeti, test sonucu (sayım + son satırlar), qa / security kararı (STATE'ten,
renkli rozet), tur geçmişi (her tur maddesi tek satır; altındaki bulgu maddeleri önem etiketiyle: High/Yüksek,
Medium/Orta, Low/Düşük, P0–P2). Önceki / sonraki kart düğmeleri.

**(d) Ölçüm.** Kart başına dört seri: maliyet (USD), tur, süre (dk), kapı sayısı. Kart başına yatay çubuk; ölçülmeyen
değer taralı/soluk çubuk + "ölçülmedi". Üstte her seri için sparkline (kart sırasıyla) ve toplam/ortalama. Kapı sayısı
türetilir ve öyle etiketlenir: kart onayı 1 + Tier 3 ise 🔐 1 + merge 1. Altta verifications maliyetleri.

**Band (AbovePrompt).** Tek satır, öncelik sırasıyla: (1) koşu sürüyorsa etiket, süre, mini çubuk, sayaç;
(2) bekleyen kapı varsa "2 kapı bekliyor: T011 kilit · T012 merge"; (3) yoksa band boş (`next(e)`). Sağda "Panoyu aç"
düğmesi. `hasSurvey` iken çekilir. delix projesi değilse ve koşu yoksa hiç görünmez.

**Komut:** `/delix-board [pano|bekleme|kart <Tnnn>|olcum]` paneli açar ve görünümü seçer.
**Açılış:** etkileşimli oturumda delix projesi bulunursa pane `session.start`'ta bir kez açılır.

## 7. Yüzeyler ve görsel dil

- **masaüstü / vscode / mobile:** ikonlar ve grafikler `Svg` (Lucide tarzı 24px çizgi ikonlar, elle yazılmış path'ler:
  lock, git-merge, timer, check-circle, x-circle, alert-triangle, flask, users, file). Çubuk ve sparkline Svg.
- **terminal:** Svg yok; çubuk, yığılmış çubuk ve sparkline tek `Raster` (blok karakterler `█▏▎▍▌▋▊▉`, sparkline
  `▁▂▃▄▅▆▇█`, renkler hücre başına); ikonlar tek genişlikli Unicode geometrik işaretler (● ◐ ○ ✓ ✕ ▲ ◆), emoji değil.
- Ortak yapı (Box/Text/Button) iki yüzeyde aynı; yalnız `gfx` katmanı yüzeye göre çizer. Her görünüm iki yüzeyde de
  okunur: grafik çizilemese bile sayılar metin olarak yanında durur.
- **Palet (durum):** open gri `#8B949E`, in_progress mavi `#3B82F6`, in_review mor `#8B5CF6`, fixing amber `#F59E0B`,
  accepted yeşil `#22C55E`, rejected kırmızı `#EF4444`, escalated turuncu `#F97316`. Metinde tema anahtarları
  (`success`, `error`, `warning`, `merged`, `suggestion`, `inactive`, `subtle`) kullanılır, açık/koyu tema uyumlu;
  Svg ve Raster yukarıdaki orta tonlarda.
- Genişlik `e.props.bodyColumns`'a göre: < 60 sütunda rol/maliyet kolonları düşer.

## 8. Headless ve güvenlik

- Mod yalnız biri görebiliyorsa başlar: `session.start` `isInteractive: true` (REPL), başlangıçta
  `$.session.surfaces()` dolu ya da sonradan bir yüzey bağlanırsa (`session.attach`). Claude Desktop, Claude Code'u SDK
  ile çalıştırır; orada `isInteractive` false gelir, masaüstü yüzeyi sonradan bağlanır (0.1.1 düzeltmesi). Yüzeysiz
  `claude -p` hiçbir şey başlatmaz: zamanlayıcı yok, pane yok, `tool.call` hook'ları doğrudan `next(e)`. Böylece
  kullanıcı kapsamında kurulu olsa bile headless uygulayıcılara yük bindirmez (K3). `/delix-board` komutu her oturumda
  kaydedilir; UI çizmez.
- Salt okunur: `$.fs.write` yok; `$.process.run` yalnız `git rev-parse` ve `git worktree list`. `tool.call` hook'ları
  çağrıyı değiştirmez, reddetmez (gating hook yok). Ağ yok.
- Okunan dosyalar proje içi; çıktı dosyası yolu yalnız Bash sonucundan gelir.

## 9. Kabul ölçütleri

1. `claude plugin validate plugins/delix-board` temiz; `tsc -p` temiz (VS Code'un içindeki TypeScript ile).
2. `claude plugin test plugins/delix-board`: fixture STATE (LLMPortal'dan kırpılmış, iki `waves` biçimi) ile
   (a) pano kartları ve kapıları, (b) bekleme: run_all çıktısı fixture'ından sayaçlar ve bitiş toast'ı, (c) kart
   ayrıntısı Files ve tur geçmişi, (d) ölçüm "ölçülmedi" ayrımı, boş durum, headless no-op; her biri `terminal` ve
   `desktop` yüzeyinde.
3. LLMPortal'da gerçekten açıldı: masaüstü pane'de dört görünüm ekran görüntüsüyle; terminalde (`claude --plugin-dir`)
   en az pano metni okundu.
4. README'de kurulum (`claude plugin install delix-board@delix-local`) ve görsel.
5. `prj_Ekip`'te `claude/delix-board` dalında commit; delix `plugin.json` sürümü 0.2.1 kalır.

## 10. Mimari

```
plugins/delix-board/
  .claude-plugin/plugin.json      name delix-board, version 0.1.1, types ./types/index.d.ts, userConfig.extraPatterns
  hooks/hooks.json                { "modules": ["./register.tsx"] }
  hooks/register.tsx              bağlama: session.start, command, timers, tool.call, session.append, ui.render
  hooks/parse.ts                  saf ayrıştırıcılar (I/O yok): state, kart md, report, test-result, metrics, run çıktısı
  hooks/data.ts                   kök bulma, mtime önbelleği, $.fs/$.process okuma → Snapshot
  hooks/wait.ts                   desenler, koşu modeli, arka plan tail, bitiş, geçmiş
  hooks/views.tsx                 Pano, Bekleme, Kart, Ölçüm, Band, boş durum
  hooks/gfx.tsx                   palet, Icon, Bar, StackBar, Spark: Svg (masaüstü) / Raster + glif (terminal)
  types/index.d.ts                PluginState sözleşmesi: snapshot, runs, view, selected (Shaped)
  tests/fixtures.ts               STATE, kart, metrics, run_all çıktısı örnekleri (dize sabitleri)
  tests/*.test.tsx                kabul ölçütü 2
  README.md                       kurulum, görünümler, ekran görüntüsü
```

Veri akışı: `session.start` → kök bulunur → `every(4s)` `data.refresh` → `update(snapshot)` → okuyan render'lar
yeniden çizilir. `tool.call(Bash|Agent)` → `wait.start/finish` → `update(runs)` + toast/status. Render hook'ları
yazmaz; yalnız `read`. Saf `parse.ts` ayrıca birim test edilir.

Paketleme: marketplace `delix-local`'e ikinci giriş `{ "name": "delix-board", "source": "./plugins/delix-board" }`.
delix girişi `./` olarak kalır; `plugins/` klasörü delix'in hooks/skills yollarına girmez.

## 11. Riskler ve açık noktalar

- Görev bildirimi metninin biçimi (görev kimliği, durum) sürüme göre değişebilir: yedek "sessiz" kuralı var; canlıda
  doğrulanacak.
- metrics.md serbest metin; ayrıştırma en iyi çaba, bulunamayan "ölçülmedi". İleride `/delix:close` STATE'e süre ve kapı
  yazarsa (delix tarafı, ayrı iş) tek kaynak STATE olur.
- `board.py` `waves`'i yalnız liste biçiminde okuyor; nesne biçiminde (LLMPortal) dict anahtarları üzerinde dönüyor ve
  wave numarası kartın kendi `wave` alanından geliyor. delix-board iki biçimi de okur; board.py düzeltmesi ayrı iş.
- Mod API'si erken erişim; delix-board Claude Code 2.1.309'a göre yazılır.
