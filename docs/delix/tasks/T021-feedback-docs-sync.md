# T021 — README Feedback + CHANGELOG: rules of T020 and the existing URL rules, EN/TR twins

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T021 | S | 1 | docs | 2 | open |

**Goal (1 sentence):** Both READMEs' Feedback sections describe the code's current redaction and BLOCKED rules item by item and with the same content. The existing `## Unreleased` Feedback bullet gains this spec's behaviour changes. · **Spec:** `docs/delix/SPEC.md#REQ-7`; K164, K167

## Files
- Modify: `README.md` (lines 145–151 and 153–157)
- Modify: `README.tr.md` (lines 144–150 and 152–156)
- Modify: `CHANGELOG.md` (line 13)

## Edit anchors (base 5638435; T020 does not touch these files, so the lines are the same on main after the T020 merge; match the content)
Wording is fixed. Wrap at ≤ 120 characters like the surrounding lines, and never break a line inside a backtick span.

`README.md`:
1. Replace lines 145–151. They start with `` from (folder name, git remote owner and repo) and your `--terms`. URLs are checked first (`scheme://…`, `//…`, `host/…`, `` and end with `too.`. The replacement is three paragraphs separated by one empty line:
   - P1: `` from (folder name, git remote owner and repo) and your `--terms`. A name whose last label is a file extension is not a host, so `notes.md` and `ci.acme-corp.conf` stay. An IP address is redacted also with a leading zero (`010.001.002.003`) or with a `_` next to it (`10.1.2.3_`). ``
   - P2: `` URLs are checked first (`scheme://…`, `//…`, `host/…`, `name:port/…`, and a dotted `host/…` right after `:` or `\`). A URL stays only if all of these hold: its scheme is empty, `http` or `https`; its host is on the allowlist above or is a loopback or documentation IP (IPv4 only in its canonical dotted form, so `http://127.1/` is removed); it has no user part (`user@`); its path and query hold only letters, digits and `._~-/` (`=&+` after `?` or `#`); no path segment is `.` or `..`; in every dotted part of the path or query, each label after the first is a file extension or a number (`a.tar.gz`, `v0.6.1`); the path holds no host name, IP or MAC address; no term appears anywhere in the URL, scheme and host included; on `github.com` only `tahircengiz/delixcrew` and `anthropics/…` paths stay. Any other URL keeps its scheme and the rest becomes `<redacted:url>` (`http://jenkins:8080/job/x` → `http://<redacted:url>`, `key:ci.acme-corp.net/api/x` → `key:<redacted:url>`; without a scheme the whole URL, `//fileserver/share` → `<redacted:url>`), so a link with `%` (`?q=is%3Aopen`) is removed too. ``
   - P3: `` A path or port right after a redacted host, IP, e-mail or MAC address is redacted with it (`see 10.1.2.3/api/x` → `see <redacted:ip><redacted:path>`, `git@github.com:acme/private` → `<redacted:email><redacted:path>`, `de:ad:be:ef:00:11/x` → `<redacted:mac><redacted:path>`). A `github.com/…` path in plain text, wherever it appears, keeps the same owner rule: `vendor/github.com/acme/private-lib/x.go` → `vendor/github.com<redacted:path>`. ``
2. Replace lines 153–157 (`**What blocks a draft**` … `an unreadable queue record.`) with: `` **What blocks a draft** (`VERDICT: BLOCKED: <reason>`, `send` exits 4; no secret value is printed): a `gitleaks` finding in the raw or the redacted text, or `gitleaks` missing, failing or timing out; an invisible Unicode control character (zero-width, bidi); any other character that is not a letter, number, punctuation mark, symbol, space, newline or tab (`invisible character`: for example U+2028, U+2029, a variation selector, a Hangul filler or a lone surrogate; an emoji selector such as U+FE0F may only follow a visible symbol such as U+2764), so text with combining marks (Devanagari, for example) is blocked too; an opaque string of 32+ characters (`[A-Za-z0-9+=_-]`, so a full git SHA is blocked too; use the short one); more than 15 code lines; a body over 8 KB; anything still matching the redaction rules after redaction; a record changed on disk since it was queued (`fingerprint mismatch`); an unreadable queue record. ``

`README.tr.md`:
3. Replace lines 144–150. They start with `` projelerin adları (klasör adı, git remote sahibi ve repo) ve `--terms` kelimeleriniz. URL'ler önce denetlenir `` and end with `` silinir. ``. The replacement is three paragraphs:
   - P1: `` projelerin adları (klasör adı, git remote sahibi ve repo) ve `--terms` kelimeleriniz. Son etiketi dosya uzantısı olan ad host sayılmaz; `notes.md` ve `ci.acme-corp.conf` kalır. IP adresi baştaki sıfırla (`010.001.002.003`) ya da hemen yanında `_` ile (`10.1.2.3_`) yazılsa da redakte edilir. ``
   - P2: `` URL'ler önce denetlenir (`şema://…`, `//…`, `host/…`, `ad:port/…` ve `:` ya da `\`'dan hemen sonra gelen noktalı `host/…`). Bir URL yalnız şunların hepsi tutarsa kalır: şeması yok, `http` ya da `https`; host'u yukarıdaki izinli listede ya da loopback veya belge aralığında bir IP (IPv4 yalnız kanonik noktalı biçimiyle; `http://127.1/` silinir); kullanıcı kısmı (`user@`) yok; yolu ile sorgusu yalnız harf, rakam ve `._~-/` (`?` ya da `#` sonrası `=&+`) taşıyor; hiçbir yol parçası `.` ya da `..` değil; yolun ya da sorgunun noktalı her parçasında ilk etiketten sonraki her etiket dosya uzantısı ya da sayı (`a.tar.gz`, `v0.6.1`); yolda host adı, IP ya da MAC adresi yok; URL'nin hiçbir yerinde, şema ve host dahil, terim geçmiyor; `github.com`'da yalnız `tahircengiz/delixcrew` ve `anthropics/…` yolları kalır. Diğer her URL'nin şeması kalır, gerisi `<redacted:url>` olur (`http://jenkins:8080/job/x` → `http://<redacted:url>`, `key:ci.acme-corp.net/api/x` → `key:<redacted:url>`; şemasızsa URL'nin tamamı, `//fileserver/share` → `<redacted:url>`); bu yüzden `%` içeren bağlantı da (`?q=is%3Aopen`) silinir. ``
   - P3: `` Redakte edilen host, IP, e-posta ya da MAC adresinin hemen ardından gelen yol ya da port da onunla birlikte redakte edilir (`see 10.1.2.3/api/x` → `see <redacted:ip><redacted:path>`, `git@github.com:acme/private` → `<redacted:email><redacted:path>`, `de:ad:be:ef:00:11/x` → `<redacted:mac><redacted:path>`). Düz metindeki `github.com/…` yolu nerede geçerse geçsin aynı sahip kuralından geçer: `vendor/github.com/acme/private-lib/x.go` → `vendor/github.com<redacted:path>`. ``
4. Replace lines 152–156 (`**Taslağı ne engeller**` … `okunamayan kuyruk kaydı.`) with: `` **Taslağı ne engeller** (`VERDICT: BLOCKED: <neden>`, `send` 4 ile çıkar; sır değeri basılmaz): ham ya da redakte metinde `gitleaks` bulgusu, ya da `gitleaks`'in olmaması, hata vermesi, zaman aşımı; görünmez Unicode kontrol karakteri (zero-width, bidi); harf, sayı, noktalama işareti, sembol, boşluk, yeni satır ya da sekme olmayan başka her karakter (`invisible character`: ör. U+2028, U+2029, variation selector, Hangul filler ya da tek başına surrogate; U+FE0F gibi bir emoji seçici yalnız U+2764 gibi görünür bir sembolden sonra gelebilir), bu yüzden birleşik işaretli metin de (ör. Devanagari) takılır; 32+ karakterlik opak dizi (`[A-Za-z0-9+=_-]`; tam git SHA'sı da takılır, kısasını kullanın); 15'ten fazla kod satırı; 8 KB'tan büyük gövde; redaksiyondan sonra hâlâ redaksiyon kuralına uyan bir şey; kuyruğa alındıktan sonra diskte değişmiş kayıt (`fingerprint mismatch`); okunamayan kuyruk kaydı. ``

`CHANGELOG.md`:
5. Replace line 13 `  normalization.` (the last line of the only `## Unreleased` bullet) with this continuation, indented 2 spaces and wrapped: `` normalization. A dotted `host/…` right after `:` or `\` is checked as a URL; a path or port right after a redacted host, IP, e-mail or MAC address is redacted with it (`see 10.1.2.3/api/x` → `see <redacted:ip><redacted:path>`); a `github.com/…` path in plain text keeps the owner rule (`vendor/github.com/acme/x` → `vendor/github.com<redacted:path>`); an IP with a leading zero or a `_` next to it is redacted. A draft with a character that is not a letter, number, punctuation mark, symbol, space, newline or tab (U+2028, a variation selector, a Hangul filler, a lone surrogate) is `BLOCKED` with `invisible character`; `add` refuses a lone surrogate, and a queue record whose `id` is not `F` and digits is never updated as a duplicate. `` Do not add a new bullet.

## Interfaces
- Consumed: T020 behaviour, merged on main (REQ-1–REQ-4 outputs, reason `invisible character`). No code.

## Global Constraints (from the spec)
- Only README Feedback → "What is redacted" / "What blocks a draft" and their TR counterparts change. CHANGELOG changes only in the existing `## Unreleased` Feedback bullet. No version bump (K161); no site change (K164).
- EN and TR say the same thing in the same commit. Every claim matches `scripts/feedback.py` on main (K167). Examples use only `acme-corp`, `10.1.2.3`-style values.

## Steps
1. On main with T020 merged, run the first Verification command and see **red** (`127.1`, `github.com<redacted:path>`, `invisible character` missing).
2. Make edits 1–5.
3. Run it and see **green**. Then run the claim check, `bash tests/site_tests.sh` and the full loop.
4. Commit `T021: README feedback rules synced with code; CHANGELOG Unreleased`. The PR body (`--body-file`) has `## How I tested`.

## Verification command → expected output
- `for f in README.md README.tr.md; do s=$(awk '/^## (Feedback|Geri bildirim)/{p=1;next} /^## /{p=0} p' "$f"); for w in 'https' '127.1' 'MAC' 'github.com<redacted:path>' 'invisible character' 'U+2028' '010.001.002.003' 'ci.acme-corp.conf' '<redacted:mac><redacted:path>' 'key:<redacted:url>'; do printf '%s\n' "$s" | grep -qF -- "$w" || echo "MISSING $f $w"; done; done; c=$(awk '/^## Unreleased/{p=1;next} /^## /{p=0} p' CHANGELOG.md); [ "$(printf '%s\n' "$c" | grep -c '^- ')" = 1 ] || echo "CHANGELOG bullets"; printf '%s\n' "$c" | grep -qF 'invisible character' || echo "MISSING CHANGELOG"; echo done` → only `done`
- Claim check: `python3 -c 'import sys;sys.path.insert(0,"scripts");import feedback as f;[print(f.sanitize(x,None)) for x in ("key:ci.acme-corp.net/api/x","see 10.1.2.3/api/x","git@github.com:acme/private","de:ad:be:ef:00:11/x","vendor/github.com/acme/private-lib/x.go","vendor/github.com/acme/x","http://127.1/","010.001.002.003","10.1.2.3_","ci.acme-corp.conf","notes.md","https://code.claude.com/docs/a.tar.gz")]'` → 12 lines in this order:
  - `key:<redacted:url>`
  - `see <redacted:ip><redacted:path>`
  - `<redacted:email><redacted:path>`
  - `<redacted:mac><redacted:path>`
  - `vendor/github.com<redacted:path>`
  - `vendor/github.com<redacted:path>`
  - `http://<redacted:url>`
  - `<redacted:ip>`
  - `<redacted:ip>_`
  - `ci.acme-corp.conf`
  - `notes.md`
  - `https://code.claude.com/docs/a.tar.gz`
- `bash tests/site_tests.sh` → exit 0; `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `git diff --stat origin/main` → only `README.md`, `README.tr.md`, `CHANGELOG.md`

## Review Focus
- The TR/EN twins match sentence for sentence, and every example string is identical in both.
- No README text outside the two paragraphs per file changes. The "Data & privacy" bullets stay.
- If a claim-check line differs, the README is wrong or T020 regressed: report `NEEDS_CONTEXT`, do not reword around it.

## Don'ts
- Do not touch: `site/**`, `scripts/**`, `tests/**`, `.claude-plugin/**`, `docs/delix/**`. No new section, no new CHANGELOG bullet, no version number.

## Report contract
`.delix/report.md` (≤ 1K tokens): status · commands + output (verification `done`, the 12 claim lines) · PR number. Read only this card and SPEC REQ-7.

## Review findings (filled by the lead)
- Round 1: …
