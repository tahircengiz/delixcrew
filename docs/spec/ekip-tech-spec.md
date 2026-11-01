# Tech Spec — `ekip` plugin (v1 taslak, 2026-11-01)

> Durum: **onay bekliyor (kapı 1)**. Kararlar `STATUS.md` K1–K16. Kanıt: [araştırma raporu](../research/reports/Çoklu%20ajan%20yazılım%20ekibi%20orkestrasyonu.md)
> (145 kaynak; vendor/anekdot/doğrulanmamış ayrımı raporda). Bu doküman kısa tutulur; gerekçe raporda.

## 1. Amaç

Tek oturumda "aç, klasör seç, geçmişi oku, devam et" döngüsü yerine **ekip düzeni**: ince bir orkestratör oturum grill
ile spec yazar, işi görev kartlarına böler, her kartı kendi worktree'sinde çalışan bir uygulama oturumuna verir,
salt-okunur inceleyicilerle denetler; insan yalnız **spec onayı** ve **PR merge** noktalarında devrededir.

Araştırmanın ana dersi: ekip = **ayrık yetki alanları** (yazan incelemez, inceleyen yazamaz, orkestratör ikisini de
yapmaz, insan geri alınamazı imzalar), eşzamanlı çalışan çok ajan değil. Paralellik kodlamada 2–5× maliyet primi
getiriyor ve Opus 5.5'te ölçülebilir kalite kazancı vermiyor (Vals AI, 2026-10-09); kazanç **taze gözle inceleme ve
dar yetki**dir. Kısıtlar prompt'ta değil harness'ta yaşar (`tools` allowlist, PreToolUse deny, worktree, branch
protection); 2025–26 olaylarının hepsi kapının ajanın kapatabildiği yerde durmasından çıktı.

## 2. Kapsam

**İçinde:** plugin iskeleti; 7 rol kartı; spec, görev kartı, dispatch ve rapor şablonları; `/ekip:*` skill'leri;
deterministik kapı hook'ları; plugin eval süiti; pilot (prj_LLMPortal) ve baz çizgi ölçümü; kullanım runbook'u.

**Dışında (v1):** deneysel Agent Teams (uygulama için kullanılmaz; worktree izolasyonu yok, ~7× token, resume
kırılgan); GitHub issue/CI entegrasyonu; GTR9'da sunucu tarafı orkestrasyon; başka araçlar için rol dosyaları; görev
panosu UI'ı.

## 3. Mimari

### 3.1 Dört katman, iki insan kapısı, bir sürekli güvenlik kapısı (K1, K2)

| Katman | Nerede | Yetki | Model (K13) |
|---|---|---|---|
| **Orkestratör** | ana oturum, proje klasöründe | kod yazmaz; grill, spec, kart, atama, denetim, PR kabul | üst (Fable 5.1 / Opus 5.5; pilot ölçer) |
| **Mimar** | salt-okunur subagent | spec'i okur, repo'yu tarar, kartları ve arayüz sözleşmelerini yazar (dosyaya orkestratör koyar) | Opus 5.5 |
| **Uygulayıcı** | ayrı oturum, kendi worktree'si, PR açar | kartı uygular, test-first, Stop hook geçmeden bitmez | Sonnet 5.5 |
| **İnceleyiciler** (`kalite`, `guvenlik`) | salt-okunur subagent, sıfır sohbet bağlamı | PR diff'ini spec ve karta karşı; yalnız high-confidence | Sonnet / Opus |
| **Arayıcı** | mevcut `arayici` / `Explore` | dosya ve kaynak bulma, <100K bağlam | Haiku 5.5 |

Kapı 1 = spec onayı (S boyda kartın onayı). Kapı 2 = PR merge. Kullanıcının global güvenlik onay kapısı
(`~/.claude/CLAUDE.md`) akışın içindedir: Kademe 3 yoluna dokunan görev PR'dan önce de onaya düşer.

**Eşzamanlılık (K14):** aynı anda açık uygulama oturumu **1–3**, yalnız dosya kümeleri ayrık kartlar paralel; ötesi
sıralı. "Backlog'da çalış" türü dağıtım yok; her kartın tek sahibi var.

### 3.2 Roller: 7 kart, 3–4 canlı (K11)

Roller "izin + prompt + model" üçlüsüdür, eşzamanlı 7 ajan değil. `backend` / `frontend` / `ui-ux` **uygulayıcı
oturumunun rol etiketi ve rol prompt'u**dur, ayrı ajan değil (hiçbir birincil kaynak disiplin bazlı dosya sınırı
vermiyor; Anthropic'in rolleri planner/generator/evaluator).

| Rol kartı | Birim | `tools` | Kaynak metin (vibecoding-agents) |
|---|---|---|---|
| `orkestrator` | ana oturum | tümü; kod yazmaz (skill kuralı) | context-manager, task-decomposition-expert, product-strategist |
| `mimar` | subagent | Read, Grep, Glob | architect-review, backend/cloud/database-architect |
| `uygulayici` (+ etiket backend / frontend / ui-ux) | worktree oturumu | tümü; `tests/**` ve Kademe 3 yolları PreToolUse deny | python-pro, typescript-pro, fullstack, frontend-developer, mobile-developer, ui-ux-designer, devops-* |
| `kalite` | subagent | Read, Grep, Glob (Bash yok; testleri Stop hook/CI koşar, inceleyici çıktıyı okur) | test-engineer, code-reviewer, debugger, error-detective, performance-engineer |
| `guvenlik` | subagent | Read, Grep, Glob + sınırlı Bash (gitleaks, semgrep); PreToolUse yazma yasağı | security-auditor (+ `/security-review`, Claude Security L'de) |
| `arayici` | mevcut | Read, Grep, Glob | search-specialist, technical-researcher |

UI/UX'in en sağlam karşılığı ayrı "tasarımcı ajan" değil, **Playwright/screenshot kanıtı üreten QA adımı** + ui-ux rol
prompt'u (Impeccable). Dokümantasyon (technical-writer) `ekip-kapat` adımı.

### 3.3 Plugin yapısı ve sınırları (K3, K5)

```
prj_Ekip/
  .claude-plugin/plugin.json
  agents/        mimar.md kalite.md guvenlik.md arayici.md
  skills/        ekip-basla/ ekip-spec/ ekip-dagit/ ekip-uygula/(roller/backend|frontend|ui-ux.md) ekip-denetle/ ekip-kapat/
  hooks/         hooks.json  (PreToolUse: korunan yollar, gitleaks, inceleyici yazma yasağı; Stop: test kapısı)
  templates/     spec-M.md spec-L.md gorev-karti.md dispatch.md rapor.md STATE.json
  evals/         plugin eval süiti
  docs/          spec/ research/ runbooks/
```

Bilinen sınırlar (resmî doküman, 2026-11-01): plugin agent'ları `permissionMode`, `hooks`, `mcpServers`,
`initialPrompt` alanlarını **yok sayar** → kısıt yalnız `tools` allowlist + plugin `hooks/hooks.json` PreToolUse
(`agent_type` matcher, `^ekip:guvenlik$` gibi anchor'lı). Plugin kökündeki CLAUDE.md yüklenmez → talimat skill'de.
Plugin hook'ları kurulu her oturumda ateşlenir → `agent_type` ve yol ile dar tutulur. Durum `${CLAUDE_PLUGIN_DATA}`.
`disallowedTools: Bash(git push *)` tüm Bash'i kaldırır → kullanılmaz. Ana oturum auto/bypass modundayken subagent
`permissionMode`'u yok sayılır → bu alana güvenilmez.

### 3.4 Uygulayıcı oturumu başlatma (K15, pilotta kesinleşir)

Orkestratör interaktif oturumu kendisi açamaz. Seçenekler: (a) Desktop'ta `start_session` (görünür, kullanıcı
sürebilir); (b) `claude -p --worktree --max-budget-usd --max-turns` headless (bütçe kapısı yalnız burada; `-p`
oturumu "trusted" sayılmaz, frontmatter hook'ları çalışmaz, settings/plugin hook'ları çalışır; worktree ve lock
temizlenmez). Öneri: Kademe 1–2 kartlar (b), Kademe 3 kartlar kullanıcının gözü önünde (a). `--bare` **kullanılmaz**
(hooks, skills, plugins, CLAUDE.md'yi atlar). Worktree varsayılan daldan dallanır (`worktree.baseRef`); hook'larda
`${CLAUDE_PROJECT_DIR}` değil input'taki `cwd`.

## 4. İki eksen: boy ve kademe (K12)

**Boy (S/M/L) süreç ağırlığını, Kademe (1/2/3) kapıları belirler.** 3 satırlık Keycloak değişikliği S boy / Kademe 3'tür.
LOC tabanlı eşik kullanılmaz (PR boyutu ile hata ilişkisi U-biçimli; ~10 dosya optimum).

| Boy | Ölçüt | Spec | Görev | Paralellik |
|---|---|---|---|---|
| **S** | tek kart, yeni davranış yok ya da tek yerde | spec = görev kartı (3–5 WHEN/THEN) | 1 | yok |
| **M** | yeni ekran/endpoint, 2–5 kart | `SPEC.md` (1–2 sayfa) + görev listesi | 2–5 | ≤ 2 |
| **L** | ≥ 2 disiplin, veri modeli/auth/mimari değişir | grill → `SPEC.md` + `design.md` + `contracts/`; EGM draft/review/resolve (K6) | 5+ | ≤ 3 |

| Kademe | Tetikleyici (yol + eylem + dış içerik geçmişi) | Deterministik kapı (her zaman) | LLM inceleme | İnsan |
|---|---|---|---|---|
| **1 rutin** | proje içi dosya, test/doküman, geri alınabilir, dış içerik okunmadı | Stop hook (test + typecheck + lint), gitleaks PreToolUse, CI | yok ya da yalnız high-confidence spec-uyum | PR merge |
| **2 özellik** | yeni davranış, çok dosya, bağımlılık ekleme, şablon/route | K1 + Semgrep + SCA/registry doğrulaması (`pip-audit`, paket var mı/yaşı/OSV) + e2e/Playwright kanıtı | `kalite` sıfır-bağlam, `SPEC.md`'ye karşı, "skip style" | spec onayı + PR merge |
| **3 hassas** | `auth/`, Keycloak/OIDC, secrets/.env, CI workflow, lockfile, deploy, prod veri, CLAUDE.md/memory yazımı, dışa yayın | K2 + yol tabanlı PreToolUse deny / CODEOWNERS / branch protection | + `guvenlik` (Opus) ve `/security-review`; bu oturum dış içerik okumaz (Rule of Two) | spec + güvenlik onay kapısı + PR merge; interaktif oturum |

Kademe 1'de insan onayı istenmez: onay yorgunluğu Kademe 3 onayını değersizleştirir (Microsoft red-team 2026:
"HitL bypass en çok istismar edilen mod"; kullanıcılar manuel izinlerin %93'ünü zaten kabul ediyor).

## 5. Akış (`/ekip:*`)

1. **`/ekip:basla <istek>`** — proje CLAUDE.md, STATUS.md, README haritası; boy ve kademe önerisi; S ise doğrudan kart.
2. **`/ekip:spec`** — grill (tek soru, önerili; `[NEEDS CLARIFICATION]` yerine soru) → `docs/ekip/SPEC.md`;
   gereksinim biçimi OpenSpec: `### Requirement` → "SHALL" → `#### Scenario` WHEN/THEN; `mimar` incelemesi; L'de EGM.
   **Kapı 1.**
3. **`/ekip:dagit`** — `mimar` kartları yazar (§6), orkestratör `docs/ekip/tasks/T001-<slug>.md` ve `STATE.json`'a
   koyar; bağımlılık görev listesinde "wave" olarak (aynı wave paralel, wave'ler sıralı); interface-first.
4. **Atama** — dispatch prompt'u (§6) ile oturum açılır; worker tüm planı okumaz.
5. **`/ekip:denetle`** — PR başına: deterministik kapılar (CI yeşil olmadan inceleme yok) → `kalite` (+ Kademe 3'te
   `guvenlik`) paralel subagent → yalnız high-confidence, severity'li bulgular → düzeltme döngüsü **≤ 3 tur** aynı
   uygulayıcıya (`SendMessage`/karta), 4. turda güçlü modele eskalasyon ya da kullanıcıya; her düzeltmeden sonra
   kapsamlı yeniden inceleme; orkestratör **kendisi düzeltmez**. **Kapı 2: merge (kullanıcı).**
6. **`/ekip:kapat`** — STATUS.md, CHANGELOG, doküman; karta `maliyet_usd`, `cache_hit`, `tur`; paylaşılan bellek
   (CLAUDE.md, agent-memory) yazımı yalnız burada, insan onayıyla (OWASP ASI06 memory poisoning).

## 6. Artefaktlar

**Görev kartı** (`gorev-karti.md`; "project bağlamı olmayan, teste isteksiz junior" için yazılır):
`id · boy · kademe · rol etiketi` · Amaç (1 cümle) + spec gereksinim linki (`REQ-3`) · **Files** (oluştur / değiştir
satır aralığıyla / test; tam yollar; sahiplik ayrık) · **Interfaces** (tüketilen/üretilen imzalar) · **Global
Constraints** (spec'ten aynen kullanılacak değerler) · **Steps** (failing test → kırmızı → uygula → yeşil → commit) ·
**Doğrulama komutu + beklenen çıktı** (`pytest tests/test_x.py -q` → `3 passed`) · **Review Focus** · **Yasaklar**
(dokunulmayacak yollar; test dosyası değiştirilmez, test hatalıysa dur ve açıkla; yeni bağımlılık gerekçeli) ·
**Rapor sözleşmesi**.

**Dispatch prompt'u** (`dispatch.md`): görevin plandaki yeri (1 satır), kart yolu, önceki kartlardan gelen arayüz
kararları, orkestratörün belirsizlik çözümleri, rapor dosyası yolu. Oturum geçmişi ve tüm plan **verilmez**.

**Rapor sözleşmesi** (`rapor.md`, ≤ 1–2K token): `DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED` + kanıt
(komut, çıktı, screenshot yolu) + PR numarası + varsayımlar + kalan iş. PR açıklamasında "Nasıl test ettim" komut +
çıktı ile.

**Durum:** `docs/ekip/STATE.json` (JSON seçildi: modeller üzerine yazmaya daha az eğilimli; uygulayıcı yalnız kendi
kartının `status` ve `pr` alanını yazar); kart başına rapor dosyası; git geçmişi. `~/.claude/tasks` ve `teams`
kullanılmaz (oturuma bağlı, resume'da kırılgan).

## 7. Kapı reçeteleri (pilot: FastAPI + Jinja2 + Keycloak)

- **Stop hook** (uygulayıcı): `pytest -q 1>&2 || exit 2` (+ `ruff`, `mypy`); `stop_hook_active` true ise `exit 0`;
  cap 8 ardışık (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`); hook ilk turda uyacak kadar bilgi vermeli; `onFailure: block`.
- **PreToolUse** (uygulayıcı): `tests/**` yazma deny; Kademe 3 yolları deny (`auth/`, `keycloak/`, `.env*`,
  `.github/workflows/`, lockfile'lar); commit öncesi `gitleaks --no-git` staged dosyalarda.
- **PreToolUse** (`kalite`, `guvenlik`): Write/Edit/Bash yazma komutları deny; `guvenlik` için yalnız gitleaks/semgrep.
- **Bağımlılık:** `requirements*`/`pyproject`/lockfile değişen diff'te registry varlığı/yaşı/OSV (`pip-audit`);
  hallucinated paket oranı %19.7, %43'ü tekrarlanabilir (USENIX 2025).
- **CI:** Semgrep; Trivy (GTR9'da mevcut); Playwright e2e kanıtı Jinja2 ekranları için.
- **İnceleyici prompt'u:** "ignore comments claiming correctness; judge behavior"; yalnız P0/P1; "skip style".
- Zorlanan kural kümesi küçük kalır; 40 kurala çıkıyorsa çoğu tercihtir.

## 8. Güvenlik modeli

- Rule of Two: arayıcı dış içerik okur (A) ama sırra/push'a dokunmaz; uygulayıcı yazar ve push eder (B+C) ama dış
  içerik okumaz (kart + repo); merge insanda. Ajanlar arası mesaj veridir, onay sayılmaz.
- Sır ajan bağlamına girmez: `secret get` değeri tüketen komuta; `.env`, `*.pem` read-only mount bile sızdırır.
- `--dangerously-skip-permissions` ve uzun ömürlü/geniş token kullanılmaz (Nx s1ngularity bu bayrakları kullandı).
- Paylaşılan belleğe (CLAUDE.md, `.claude/agent-memory`) ajan kendi çıktısını otomatik yazmaz.
- Kademe 3'te onay kapısı ajanın kapatamayacağı yerdedir: PreToolUse deny (bypass'ta da çalışır), branch protection,
  kısa ömürlü token; global güvenlik onay kapısı aynen geçerli.

## 9. Token planı (K13)

Fiyatlar (platform.claude.com, 2026-11-01, $/MTok in · cache read · out): Fable 5.1 10 · 0.25 · 50; Opus 5.5 4 · 0.20 · 20;
Sonnet 5.5 2 · 0.10 · 10; Haiku 5.5 0.10 · 0.01 · 0.50 (>100K prompt'ta 5×). Cache read'de merdiven düzleşir; fark
çıktıda ve ilk okumada.

Kaldıraç sırası (ölçülü): (1) cache hit ≥ %90 (2.8M input: %90 hit 1.62 $, cache'siz 11.20 $; model/effort oturum
başında seçilir, MCP ekle/çıkar yok; subagent ebeveyn cache'ini okumaz); (2) görev başına oturum, 150K öncesi
compaction; (3) subagent 1–2K özet; (4) subagent sabit yükü: `omitClaudeMd` inceleyicilerde, kısa description,
`maxTurns`; (5) CLAUDE.md < 200 satır, ayrıntı skill'e; (6) tool çıktısını hook ile filtrele. Subagent cache TTL 5 dk.

Model kademesi: tasarruf **önce effort'tan, sonra uygulayıcıdan, en son inceleyiciden** (review en pahalı aşama,
%59.4; küçük modelin review yeterliliğine kanıt yok). `kalite` ≥ Sonnet, `guvenlik` Opus, Haiku yalnız arama/özet.
Kademeleme oturum içi `/model` ile değil subagent `model` alanıyla (cache model kapsamlı).

Guardrail: interaktif oturumda dolar kapısı yok → `maxTurns`, `-p`'de `--max-budget-usd`; OTel
`claude_code.token.usage` (`query_source`, `agent.name`) ve `/usage`.

## 10. Başarı ölçütleri (pilot, prj_LLMPortal)

0. **Baz çizgi önce:** aynı 10 görevde "tek oturum, Opus 5.5 medium" maliyeti ve ilk-denemede-CI-yeşil oranı ölçülür;
   ekip akışı buna karşı raporlanır (ölçülmeden iddia yok).
1. Bir M boy / Kademe 2 özellik uçtan uca: spec onayı → kartlar → ≤ 2 paralel uygulayıcı → PR → kapılar → merge;
   kullanıcı yalnız 2 kapıda müdahale etti.
2. Her PR'da test kanıtı kartta; Kademe 2+ PR'larda inceleyici bulgusu ve kapanışı görünür; `/security-review`
   bulgusu sıfır ya da kabul edilmiş.
3. Bir Kademe 3 kart (ör. Keycloak ayarı) interaktif oturumda, güvenlik onay kapısından geçerek bitti.
4. Plugin eval ≥ 5 case: boy/kademe sınıflandırma; kart üretimi; inceleyicinin `Edit` çağırmaması
   (`tool_used: Edit, max: 0`); Stop kapısı; sır sızıntısı reddi. Reçete: `--json --threshold 0.8 --trust-plugin
   --model <pin> --judge-model <pin> --no-publish --max-cost-usd 20`.
5. Ölçüm: insan review'ından geçmiş merge oranı, ilk denemede CI yeşil, revert sayısı, kart başına maliyet ve cache hit.

## 11. Yapılmayacaklar (kanıtlı)

Agent Teams ile uygulama · aynı dosyaya iki ajan, "backlog'da çalış" · orkestratörün kodu kendisinin düzeltmesi ·
self-review'ü saymak · her bulguyu düzeltmek, inceleyiciye "sorun bul" demek · rol kısıtını prompt'a bırakmak ·
`stop_hook_active` kontrolsüz Stop hook · worktree'de `${CLAUDE_PROJECT_DIR}` · spec şişirmek, bağlamı worker'a
kopyalamak · ajanın kendi çıktısını paylaşılan belleğe yazması · `--dangerously-skip-permissions` · merge oranını kalite
saymak · 50 subagent, vague brief.

## 12. Riskler

- [Orta] Paralel oturumlar çakışır → kartta dosya sahipliği, `mimar` kontrolü, ≤ 3 paralel.
- [Orta] Stop hook döngüsü token yakar → cap 8, ilk turda uyulabilir mesaj, `stop_hook_active`.
- [Orta] Plugin agent frontmatter'ındaki kısıtlar yok sayılır → `tools` + plugin hooks.json; eval ile doğrulanır.
- [Orta] Harness bileşenleri model nesline bağlı varsayımlar taşır → pilot sonunda "bir bileşeni çıkar, taşıyıcı mı"
  turu.
- [Düşük] EGM arayüzü değişir → yalnız L'de, skill adıyla.

## 13. Açık sorular (pilot cevaplar)

1. Baz çizgi sayıları (maliyet, ilk denemede CI yeşil).
2. Orkestratör Fable 5.1 mi Opus 5.5 mi (çıktı token payı, cache hit).
3. `kalite` Bash'siz mi, sınırlı Bash'li mi: bulgu kalitesi farkı.
4. Uygulayıcı: `start_session` (interaktif) mi `-p --worktree` mi; hook, temizlik, bütçe dengesi.
5. 2–3 paralel uygulayıcı sıralıya göre kalite kaybı yaratıyor mu.
6. Hangi harness parçası Opus 5.5 / Fable 5.1 ile artık gereksiz.
