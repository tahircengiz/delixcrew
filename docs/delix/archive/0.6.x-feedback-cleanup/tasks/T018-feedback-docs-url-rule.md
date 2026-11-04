# T018 — README Feedback + CHANGELOG: URL rule and narrower allowlist

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T018 | S | 1 | docs | 2 | open |

**Goal (1 sentence):** Document the URL rule and the narrower allowlist in both READMEs' Feedback sections, and add one `## Unreleased` CHANGELOG bullet. · **Spec:** `docs/delix/SPEC.md#REQ-8`; K140, K141, K146, K147

## Files
- Modify: `README.md`
- Modify: `README.tr.md`
- Modify: `CHANGELOG.md`

## Edit anchors (base 79ef030; match the content). Wrap at about 120 characters like the surrounding lines; the wording is fixed.
`README.md`:
1. Replace line 139 `` `code.claude.com`, … `*.example`, `*.test`, `*.invalid`, `localhost`), `` → `` `code.claude.com`, `docs.anthropic.com`, `anthropic.com`, `example.com`, `example.net`, `example.org` and their subdomains, `*.example` and `localhost` as an exact name; not `*.test`, `*.invalid`, `*.localhost` or a non-ASCII name), ``
2. Replace line 144 `` from (folder name, git remote owner and repo) and your `--terms`. `` → the same sentence plus: `URLs are checked first (`scheme://…`, `//…`, `host/…`, `name:port/…`): a URL stays only if its host is on the allowlist above or is a loopback or documentation IP, it has no user part (`user@`), and its path and query hold only letters, digits and `._~-/` (`=&+` after `?` or `#`) with no `..` segment, host name, IP or term; on `github.com` only `tahircengiz/delixcrew` and `anthropics/…` paths stay. Any other URL keeps its scheme and the rest becomes `<redacted:url>` (`http://jenkins:8080/job/x` → `http://<redacted:url>`; without a scheme the whole URL, `//fileserver/share` → `<redacted:url>`), so a link with `%` (`?q=is%3Aopen`) is removed too.`
3. Replace line 168 `  part of home paths, other absolute paths, e-mail addresses and hosts outside the allowlist are redacted; a draft with a` → `  part of home paths, other absolute paths, e-mail addresses, hosts outside the allowlist and URLs that are not allowed (`<redacted:url>`) are redacted; a draft with a`

`README.tr.md`:
4. Replace line 138 `` `docs.anthropic.com`, … `*.example`, `*.test`, `*.invalid`, `localhost`) dışındaki her host `` → `` `docs.anthropic.com`, `anthropic.com`, `example.com`, `example.net`, `example.org` ve alt alanları, `*.example` ve tam ad olarak `localhost`; `*.test`, `*.invalid`, `*.localhost` ve ASCII dışı ad yok) dışındaki her host ``
5. Replace line 143 `` projelerin adları (klasör adı, git remote sahibi ve repo) ve `--terms` kelimeleriniz. `` → the same sentence plus: `URL'ler önce denetlenir (`şema://…`, `//…`, `host/…`, `ad:port/…`): bir URL yalnız host'u yukarıdaki izinli listedeyse ya da loopback veya belge aralığında bir IP ise, kullanıcı kısmı (`user@`) yoksa ve yolu ile sorgusu yalnız harf, rakam ve `._~-/` (`?` ya da `#` sonrası `=&+`) taşıyorsa (`..` parçası, host adı, IP ya da terim yok) kalır; `github.com`'da yalnız `tahircengiz/delixcrew` ve `anthropics/…` yolları kalır. Diğer her URL'nin şeması kalır, gerisi `<redacted:url>` olur (`http://jenkins:8080/job/x` → `http://<redacted:url>`; şemasızsa URL'nin tamamı, `//fileserver/share` → `<redacted:url>`); bu yüzden `%` içeren bağlantı da (`?q=is%3Aopen`) silinir.`
6. Replace line 167 `  yollarının kullanıcı kısmı, diğer mutlak yollar, e-posta adresleri ve izinli liste dışındaki host'lar redakte edilir;` → `  yollarının kullanıcı kısmı, diğer mutlak yollar, e-posta adresleri, izinli liste dışındaki host'lar ve izinli olmayan URL'ler (`<redacted:url>`) redakte edilir;`

`CHANGELOG.md`:
7. Insert after line 4 (the empty line after line 3 `Earlier versions: git history and the [v0.2.0 release](…).`), before line 5 `## 0.6.1 — 2026-11-03`: `## Unreleased`, an empty line, the bullet below, an empty line.
   `- **Feedback redaction is stricter** (`SANITIZER_VERSION` 3; take a new `preview` before `send`): a URL keeps only an allowlisted host with a plain path, otherwise the part after its scheme becomes `<redacted:url>` (on `github.com` only `tahircengiz/delixcrew` and `anthropics/…`; a user part never stays); `*.test`, `*.invalid` and `*.localhost` are no longer allowed; absolute paths after `>`, `|`, `-` or `\/` and Windows UNC paths are redacted, as are Unicode host names; triage comments use the same redaction. `feedback.py list` and `add` print control characters from the queue as visible escapes, and the hook that guards the feedback and triage directories ignores letter case and Unicode normalization.`

## Interfaces
- Consumed: the behaviour of T016 (`<redacted:url>`, allowlist) and T017 (case-insensitive hook), both merged. No code.

## Global Constraints (from the spec)
- Only the Feedback sections of the two READMEs change (#10 owns the rest); no version bump; CHANGELOG under `## Unreleased` (K140). The site does not change (K141).
- The EN and TR text say the same thing; every claim matches `scripts/feedback.py` on main.

## Steps
1. Before editing, run the check from Verification and see **red** (`<redacted:url>` missing in both).
2. Make edits 1–7.
3. Run it and see **green**; then `bash tests/site_tests.sh` and the full loop.
4. Commit `T018: README feedback URL rule, narrower allowlist; CHANGELOG Unreleased`. The PR body has "## How I tested" (`--body-file`).

## Verification command → expected output
- `for f in README.md README.tr.md; do awk '/^## (Feedback|Geri bildirim)/{p=1;next} /^## /{p=0} p' "$f" > /tmp/fb.$$; for s in '<redacted:url>' 'tahircengiz/delixcrew' 'anthropics' 'localhost'; do grep -qF -- "$s" /tmp/fb.$$ || echo "MISSING $f $s"; done; grep -qF '`*.test`, `*.invalid`, `localhost`)' /tmp/fb.$$ && echo "OLD LIST $f"; done; echo done` → only `done`
- `bash tests/site_tests.sh` → exit 0, no ✘ line; `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `git diff --stat origin/main` → only `README.md`, `README.tr.md`, `CHANGELOG.md`

## Review Focus
- The TR/EN twins match sentence for sentence; the examples are identical.
- No README text outside `## Feedback` / `## Geri bildirim` changes.

## Don'ts
- Do not touch: `site/**`, `scripts/**`, `tests/**`, `.claude-plugin/**`, `docs/delix/**`. No new section and no version number.

## Report contract
`.delix/report.md` (≤ 1K tokens): status · commands + output · PR number. Read only this card and SPEC REQ-8.

## Review findings (filled by the lead)

### Round 0 (2026-11-04, PR #38, a3a4e63, base 63f3d7b)
- Deterministic gates (lead, from `git archive a3a4e63`): the card's verification command prints only `done` (verified for both READMEs); `bash tests/site_tests.sh` passes; full loop exit 0; diff touches only `README.md`, `README.tr.md`, `CHANGELOG.md`; CI `test` + `check` SUCCESS; internal-address scan 0.
- qa: ACCEPT_WITH_NOTES (P0 0, P1 0, P2 1). Tier 1, no security review.
- [P2, follow-up] The README tail sentence omits the T016 round 2 rule (K146 allowlist): a dotted tail part keeps only a known file extension or a number after each dot (`…/delixcrew/foo.bar` → `<redacted:url>`). The card fixed the wording; goes to the follow-up card.
