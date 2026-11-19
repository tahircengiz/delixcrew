# T057 — Docs: stale card and `delix.json` text, implementer leaves `docs/delix` to the lead, CHANGELOG Unreleased

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T057 | M | 2 | docs | 27 | open |

**Tier:** 2, as the lead proposed. There are 11 files and the text describes new hook behaviour; no file is protected and none matches `test_paths`. Tier 1 would be too low because the skill text changes what the implementer does (REQ-3).

**Goal (1 sentence):** Change the text in six places:
- README and README.tr: REQ-1, REQ-2 and the K351 known limit;
- the site's usage and index pages: the same, as TR/EN twins;
- the implement skill, the architect, dispatch and the STATE template: they stop giving the implementer `docs/delix` work;
- `CHANGELOG.md`: a new `## Unreleased` section.

It changes no version. · **Spec:** `docs/delix/specs/D-stale-card-config.md` REQ-3, REQ-4, K347–K351

**Docs/site:** this card is the README/site update for T056. T056's messages and behaviour come from the spec text only, so this card runs in parallel with it.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `skills/implement/SKILL.md` (A14, A15)
- Modify: `agents/architect.md` (A16)
- Modify: `skills/dispatch/SKILL.md` (A17, A18)
- Modify: `templates/STATE.json` (A19)
- Modify: `README.md` (A1 to A3)
- Modify: `README.tr.md` (A4 to A6)
- Modify: `site/usage.html` (A7, A8)
- Modify: `site/tr/usage.html` (A9, A10)
- Modify: `site/index.html` (A11)
- Modify: `site/tr/index.html` (A12)
- Modify: `CHANGELOG.md` (A13)
- Test: none new. `tests/site_tests.sh`, `tests/ledger_tests.sh` and `tests/evidence_tests.sh` already check these files.

## Interfaces
- Consumed: the T056 behaviour described in spec REQ-1 and REQ-2 (text only).
- Produced: the `## Unreleased` section, with four items whose first lines carry `(🔐 K344, K345, K348, K352, K353):`, `(🔐 K346):`, `(🔐 K355, K356, K357):` and `(K347, K348):`. T058 anchors on these.

## Lead decisions
- **D1 · README:** only the places spec REQ-4 names change: line 136 (REQ-2), line 164 (REQ-1) and lines 436–440 (K351). The write-gate bullet (lines 105–106) stays: it remains true, and the CHANGELOG names REQ-5.
- **D2 · Site:**
  - `usage` line 221 carries the REQ-1 and REQ-2 hook rule, and line 226 the known limit.
  - On the index pages only the flow-diagram box changes: line 389, at most 35 characters, the same as the longest box text in row 1.
  - Index lines 186 and 360 stay. They state a necessary condition, which is still true.
- **D3 · dispatch §5** gains `pr`. REQ-3 says the lead records `pr` (spec line 117); §5 already says `in_review`.
- **D4 · Source lines:** no `Source:` / `Kaynak:` line changes. The new text rests on `README.md` and `scripts/common.py (card_path)`, which `site/index.html:489` and `site/usage.html:240` already cite.

- **D5 · Known limits (lead, 2026-11-19):** `git pull` with a refspec was measured on main 22a51ef (git 2.54):
  `scripts/bash_gate.py` allows it in a card worktree and it moves `refs/remotes/origin/HEAD`, so the text names it as
  spec REQ-4 does. The text names the routes only, as REQ-4 asks; it does not describe how a card session would build
  the STATE it points to.
## Edit anchors (base main 22a51ef, full SHA 22a51ef68d01180425c0d1fab5edd9303a46f4f9)
Line counts on the base: `README.md` 445, `README.tr.md` 450, `CHANGELOG.md` 267, `site/index.html` and `site/tr/index.html` 702 each, `site/usage.html` and `site/tr/usage.html` 251 each, `skills/implement/SKILL.md` 63, `agents/architect.md` 80, `skills/dispatch/SKILL.md` 82, `templates/STATE.json` 21. Match the quoted content before you edit; if it differs, stop with `NEEDS_CONTEXT`. The code blocks are not indented: copy each line as it stands, including its leading spaces. Use the Edit tool.

The lead applied A1 to A19 to a base copy with a script and got the "after" sha256s below (sha256 prefixes, 16 hex);
on that copy `bash tests/site_tests.sh` gave 23 `✔`, and `tests/ledger_tests.sh` and `tests/evidence_tests.sh` passed.
Compare yours with `shasum -a 256 <file>`; if one differs, find the anchor before you go on.

| file | base | after |
|---|---|---|
| `README.md` | `66b96c3c1b7ba9fc` | `801997f0a67e3ee1` |
| `README.tr.md` | `810c58720c151b7d` | `1f63bb3a0c9995dc` |
| `CHANGELOG.md` | `a333340fb8ccb3b7` | `2631ce59e887d408` |
| `site/usage.html` | `eac1ef2faea0562e` | `653fb7ebfa5aee44` |
| `site/tr/usage.html` | `a6c509eee0538535` | `365a1fc2d37d966f` |
| `site/index.html` | `c8b97e0e4b2a4b3f` | `4966b99d2bd1c0f6` |
| `site/tr/index.html` | `3b9af28048e84ac4` | `1e1f94833b08dcc5` |
| `skills/implement/SKILL.md` | `705899cc2b92245f` | `64b406c6d795e0e3` |
| `agents/architect.md` | `008c6d68dca016b8` | `326ae056bba18161` |
| `skills/dispatch/SKILL.md` | `6ed62623a74ce19e` | `45c7d5cc60425f89` |
| `templates/STATE.json` | `58998a14a68c03a2` | `b3219ebe0a98e751` |

**A1 · `README.md` lines 136–137 · replace.** Current:
```text
  `docs/delix/delix.json` that is not a JSON object, or a byte that is not UTF-8 in a git setting the rule reads,
  makes it deny the command with a message instead of failing. The rules read a command both by the loose word scan and
```
With (5 lines):
```text
  byte that is not UTF-8 in a git setting the rule reads makes it deny the command with a message instead of
  failing. In a card worktree both `PreToolUse` hooks deny with one message when `docs/delix/delix.json` is
  missing, is not valid JSON or not a JSON object, or has a `protected_paths` or `test_paths` that is not a list
  of strings; the write hook still allows writes under `.delix/` (T056).
  The rules read a command both by the loose word scan and
```

**A2 · `README.md` lines 165–166 · replace.** Line 164 stays. Current:
```text
  ([`scripts/common.py`](scripts/common.py)). Without `python3` both `PreToolUse` hooks block (see
  [Requirements](#requirements)).
```
With (6 lines):
```text
  ([`scripts/common.py`](scripts/common.py)) whose card is not finished. The card is finished when the STATE at
  `refs/remotes/origin/HEAD` (read with `--no-lazy-fetch --no-replace-objects`, at most 1 MiB, never the
  worktree's copy), or an archive STATE it lists, holds the card (same id, same `file`) as `accepted` or with a
  `merged` record; then the three hooks stay inactive and print one line on stderr (T056). Any read error
  keeps them active. While the card is not finished, the write hook denies a Write that changes `.delix/card`
  and any other tool on it. Without `python3` both `PreToolUse` hooks block (see [Requirements](#requirements)).
```

**A3 · `README.md` lines 438–440 · replace.** Current:
```text
a file written under the git directory, or a command that a script or another program runs. delix-board reads its
trusted state from `refs/remotes/origin/HEAD`, so a card session can still make the board show a card as ready to merge
by those routes; the merge click (gate 2) stays yours.
```
With (6 lines):
```text
a file written under the git directory, or a command that a script or another program runs. delix-board and the card
worktree's hooks read their trusted state from `refs/remotes/origin/HEAD` (T056), so by those routes or by `git pull`
with a refspec a card session can still make the board show a card as ready to merge, and switch its own hooks off by
making its card look finished there (K351). That equals deleting `.delix/card` (see the push rule above), only harder
to spot. A `refs/replace/` object and a tag or branch named like `refs/remotes/origin/HEAD` do not change what the
hooks read. The merge click (gate 2) stays yours.
```

**A4 · `README.tr.md` lines 136–138 · replace.** Current:
```text
  biçimini reddeder; kart oturumu bu komutlarla ref ya da remote yazmaz (T044, K296). JSON nesnesi olmayan bir
  `docs/delix/delix.json` ya da kuralın okuduğu bir git ayarındaki UTF-8 olmayan bayt,
  komutun hata vermek yerine bir mesajla reddedilmesini sağlar. Kurallar bir komutu hem gevşek kelime taramasıyla hem de
```
With (5 lines):
```text
  biçimini reddeder; kart oturumu bu komutlarla ref ya da remote yazmaz (T044, K296). Kuralın okuduğu bir git
  ayarındaki UTF-8 olmayan bayt, komutun hata vermek yerine bir mesajla reddedilmesini sağlar. Kart worktree'sinde
  `docs/delix/delix.json` yoksa, geçerli bir JSON ya da JSON nesnesi değilse ya da `protected_paths` veya
  `test_paths` metin listesi değilse iki `PreToolUse` hook'u da tek bir mesajla reddeder; yazma hook'u `.delix/`
  altına yazıma yine izin verir (T056). Kurallar bir komutu hem gevşek kelime taramasıyla hem de
```

**A5 · `README.tr.md` lines 165–167 · replace.** Current:
```text
- Uygulayıcı worktree'si, work tree kökünde yerel ve git'in izlemediği bir `.delix/card` bulunan worktree'dir
  ([`scripts/common.py`](scripts/common.py)). `python3` yoksa iki `PreToolUse` hook'u da engeller (bkz.
  [Gereksinimler](#gereksinimler)).
```
With (7 lines):
```text
- Uygulayıcı worktree'si, work tree kökünde yerel ve git'in izlemediği bir `.delix/card` bulunan ve kartı bitmemiş
  worktree'dir ([`scripts/common.py`](scripts/common.py)). `refs/remotes/origin/HEAD`'teki STATE
  (`--no-lazy-fetch --no-replace-objects` ile en çok 1 MiB okunur, worktree'deki kopya hiç okunmaz) ya da onun
  listelediği bir arşiv STATE'i kartı (aynı kimlik, aynı `file`) `accepted` ya da bir `merged` kaydıyla taşıyorsa
  kart bitmiştir; o zaman üç hook etkin olmaz ve stderr'e bir satır yazar (T056). Her okuma hatası onları etkin
  bırakır. Kart bitmemişken yazma hook'u `.delix/card`'ı değiştiren bir Write'ı ve ona dokunan başka her aracı
  reddeder. `python3` yoksa iki `PreToolUse` hook'u da engeller (bkz. [Gereksinimler](#gereksinimler)).
```

**A6 · `README.tr.md` lines 443–444 · replace.** Current:
```text
delix-board güvenilir durumunu `refs/remotes/origin/HEAD`'ten okur; bu yüzden bir kart oturumu
o yollarla board'a bir kartı merge'e hazır gösterebilir; merge tıklaması (kapı 2) yine senindir.
```
With (5 lines):
```text
delix-board ve kart worktree'sinin hook'ları güvenilir durumu `refs/remotes/origin/HEAD`'ten okur (T056); bu yüzden
bir kart oturumu o yollarla ya da refspec'li `git pull` ile board'a bir kartı merge'e hazır gösterebilir ve kartını
orada bitmiş göstererek kendi hook'larını kapatabilir (K351). Bu, `.delix/card`'ı silmekle aynıdır (yukarıdaki push
kuralı), yalnız fark edilmesi daha zordur. Bir `refs/replace/` nesnesi ve `refs/remotes/origin/HEAD` adlı bir tag ya
da dal hook'ların okuduğunu değiştirmez. Merge tıklaması (kapı 2) yine senindir.
```

**A7 · `site/usage.html` line 221 · replace.** Current:
```text
        <li>The hooks load in every session where the plugin is installed. The implementer rules run only when <code>cwd/.delix/card</code> exists, the reviewer rules only when <code>agent_type</code> is <code>delixcrew:*</code>.</li>
```
With:
```text
        <li>The hooks load in every session where the plugin is installed. The implementer rules run only when <code>cwd/.delix/card</code> exists and its card is not finished: <code>accepted</code> or with a <code>merged</code> record in the STATE at <code>refs/remotes/origin/HEAD</code> or an archive STATE it lists (a read error counts as not finished). The reviewer rules run only when <code>agent_type</code> is <code>delixcrew:*</code>. In a card worktree a <code>docs/delix/delix.json</code> that is missing, is not valid JSON or not a JSON object, or has a <code>protected_paths</code> or <code>test_paths</code> that is not a list of strings blocks writes and Bash with one message; writes under <code>.delix/</code> stay allowed.</li>
```

**A8 · `site/usage.html` line 226 · replace in the line.** Find (once):
```text
delix-board reads its trusted state from <code>refs/remotes/origin/HEAD</code>, so a card session can still make the board show a card as ready to merge by those routes; the merge click (gate 2) stays yours.</li>
```
Replace with:
```text
delix-board and the card worktree's hooks read their trusted state from <code>refs/remotes/origin/HEAD</code>, so by those routes or by <code>git pull</code> with a refspec, a card session can still make the board show a card as ready to merge, and switch its own hooks off by making its card look finished there. That equals deleting <code>.delix/card</code>, only harder to spot. A <code>refs/replace/</code> object and a tag or branch named like <code>refs/remotes/origin/HEAD</code> do not change what the hooks read. The merge click (gate 2) stays yours.</li>
```

**A9 · `site/tr/usage.html` line 221 · replace.** Current:
```text
        <li>Hook'lar plugin'in kurulu olduğu her oturumda yüklenir. Uygulayıcı kuralları yalnız <code>cwd/.delix/card</code> varken, reviewer kuralları yalnız <code>agent_type</code> <code>delixcrew:*</code> iken çalışır.</li>
```
With:
```text
        <li>Hook'lar plugin'in kurulu olduğu her oturumda yüklenir. Uygulayıcı kuralları yalnız <code>cwd/.delix/card</code> varken ve kartı bitmemişken çalışır: kart, <code>refs/remotes/origin/HEAD</code>'teki STATE'te ya da onun listelediği bir arşiv STATE'inde <code>accepted</code> ya da bir <code>merged</code> kaydıyla duruyorsa bitmiştir (okuma hatası bitmemiş sayılır). Reviewer kuralları yalnız <code>agent_type</code> <code>delixcrew:*</code> iken çalışır. Kart worktree'sinde <code>docs/delix/delix.json</code> yoksa, geçerli bir JSON ya da JSON nesnesi değilse ya da <code>protected_paths</code> veya <code>test_paths</code> metin listesi değilse yazma ve Bash tek bir mesajla engellenir; <code>.delix/</code> altına yazım serbest kalır.</li>
```

**A10 · `site/tr/usage.html` line 226 · replace in the line.** Find (once):
```text
delix-board güvenilir durumunu <code>refs/remotes/origin/HEAD</code>'ten okur; bu yüzden bir kart oturumu o yollarla board'a bir kartı merge'e hazır gösterebilir; merge tıklaması (kapı 2) yine senindir.</li>
```
Replace with:
```text
delix-board ve kart worktree'sinin hook'ları güvenilir durumu <code>refs/remotes/origin/HEAD</code>'ten okur; bu yüzden bir kart oturumu o yollarla ya da refspec'li <code>git pull</code> ile, board'a bir kartı merge'e hazır gösterebilir ve kartını orada bitmiş göstererek kendi hook'larını kapatabilir. Bu, <code>.delix/card</code>'ı silmekle aynıdır, yalnız fark edilmesi daha zordur. Bir <code>refs/replace/</code> nesnesi ve <code>refs/remotes/origin/HEAD</code> adlı bir tag ya da dal hook'ların okuduğunu değiştirmez. Merge tıklaması (kapı 2) yine senindir.</li>
```

**A11 · `site/index.html` line 389 · replace in the line.** Find `>No local .delix/card?<` → `>No local .delix/card, or card done?<`

**A12 · `site/tr/index.html` line 389 · replace in the line.** Find `>Yerel .delix/card yok mu?<` → `>Yerel .delix/card yok mu, bitti mi?<`

**A13 · `CHANGELOG.md` line 5 · replace.** Current: `## 0.7.2 — 2026-11-19`. Replace with these 25 lines; the last one is the current line:
```text
## Unreleased

- **A finished card's `.delix/card` no longer switches the hooks on** (🔐 K344, K345, K348, K352, K353):
  when the STATE at `refs/remotes/origin/HEAD`, or an archive STATE it lists, holds the card that `.delix/card`
  names (same id and `file`) as `accepted` or with a `merged` record, the write, Bash and Stop hooks stay inactive
  and say so in one stderr line. Any read error keeps them active. While the card is not finished, the write hook
  denies a Write that changes `.delix/card` and every other tool on it. A `refs/replace/` object or a tag or branch
  named like `refs/remotes/origin/HEAD` does not change the read; commands that move `origin/HEAD` are a known
  limit (K351).
- **A `delix.json` the hooks cannot read blocks the card worktree** (🔐 K346): when
  `docs/delix/delix.json` is missing, not valid JSON, not a JSON object, or has a `protected_paths` or `test_paths`
  that is not a list of strings, the write and Bash hooks deny in a card worktree with one message instead of
  reading no protected path or failing. The write hook still allows `.delix/` (the report). The Stop gate is
  unchanged.
- **Protected and test paths match through a symlink and in any letter case** (🔐 K355, K356, K357):
  both hooks match a path and its real path inside the worktree, after folding letter case and Unicode
  normalization, so `lnk/x.py` with `lnk -> scripts`, or `Scripts/x.py`, no longer passes a `scripts/x.py` rule.
  The card's Files list allows a write only when the given path and its real path are both listed.
- **The implementer leaves `STATE.json` and `docs/delix` to the lead** (K347, K348):
  it puts the PR number in the report's PR line and the lead records `in_review` and `pr`. A session that finds
  another card's `.delix/card` moves the old files to `.delix/previous/<id>/`, or writes nothing and ends with
  `BLOCKED` while that card is not finished. The architect and dispatch keep `docs/delix/**` out of a card's Files
  list.

## 0.7.2 — 2026-11-19
```

**A14 · `skills/implement/SKILL.md` · insert after line 18** (`   (`.git/info/exclude`).`), 7 lines:
```text
   Write `.delix/card` only with the Write tool: while its card is not finished, the gate denies any other tool
   on it. If `.delix/card` already names another card, first read its old id (the `T<digits>` at the start of its
   last path part, else `unknown`), then write the new card path. If the gate denies that write (the old card is
   not finished on origin/HEAD), write nothing under `.delix/` (the live card's `report.md` stays as it is) and end
   your final message with `BLOCKED`. If it allows it, move everything else in `.delix/` except `card` and
   `previous/` into `.delix/previous/<id>/` with `mv -n` (never overwrite); delete no file and list the moves in
   the report.
```

**A15 · `skills/implement/SKILL.md` lines 57–59 · replace.** Current:
```text
  branch, write `**PR:** none (<branch> @ <sha>)` in the report and keep `pr` `null` (the review reads the branch SHA).
- Fill `.delix/report.md` from `${CLAUDE_PLUGIN_ROOT}/templates/report.md` (≤ 1–2K tokens); in `STATE.json` update only
  your own card's `status: in_review` and `pr` fields.
```
With (4 lines):
```text
  branch and write `**PR:** none (<branch> @ <sha>)` in the report (the review reads the branch SHA).
- Fill `.delix/report.md` from `${CLAUDE_PLUGIN_ROOT}/templates/report.md` (≤ 1–2K tokens) and put the PR
  number in its `**PR:**` line. Do not write `STATE.json` or anything under `docs/delix/`: the lead records
  `in_review` and `pr` from your report.
```

**A16 · `agents/architect.md` · insert after line 33** (`Global Constraints: its tokens only, no new colour, font or spacing value.`), 2 lines:
```text
A card's Files list holds no `docs/delix/**` path (the write gate denies it to the implementer): evidence goes to
`.delix/evidence/`, and a `docs/delix` change is a lead step in the wave plan.
```

**A17 · `skills/dispatch/SKILL.md` · insert after line 26** (`  commit); on an unapproved card the hook rejects the protected path.`), 2 lines:
```text
- A card whose Files list holds a `docs/delix/**` path: move that change to a lead step in the wave plan (the write
  gate denies `docs/delix/**` to the implementer); the card keeps the rest of its Files.
```

**A18 · `skills/dispatch/SKILL.md` line 77 · replace.** Line 78 stays. Current:
```text
When an implementer session finishes, `.delix/report.md` and a PR arrive; `STATE.json` status → `in_review`, fill
```
With (2 lines):
```text
When an implementer session finishes, `.delix/report.md` and a PR arrive; `STATE.json` status → `in_review`, `pr`
from the report's `**PR:**` line (the implementer writes no STATE), fill
```

**A19 · `templates/STATE.json` line 2 · replace.** Current:
```text
  "$comment": "docs/delix/STATE.json. The lead writes it; the implementer changes only its own card's status and pr fields.",
```
With:
```text
  "$comment": "docs/delix/STATE.json. Only the lead writes it; the implementer puts its PR number in .delix/report.md and the lead records status and pr.",
```

## Global Constraints
- Spec REQ-4: "Sitenin dört sayfası aynı içeriği taşır". The TR and EN twins carry the same clauses. On the site a backticked word is `<code>`, and `<`, `>` and `&` are escaped.
- No version change: no `data-version`, footer date or `plugin.json` edit (T058).
- New README and CHANGELOG lines are at most 120 characters. No raw invisible character; write one, if ever needed, as `\uXXXX`. Turkish letters, `—` and `🔐` stay as the files already have them.
- Keep the strings checked by `tests/ledger_tests.sh:21` (`from \`gh pr view <n> --json headRefName\`, not from the report`) and by `tests/evidence_tests.sh`.

## Steps
1. Baseline: `bash tests/site_tests.sh` gives 23 `✔`; `grep -n '^## ' CHANGELOG.md | head -1` gives `5:## 0.7.2 — 2026-11-19`.
2. Apply A1 to A19 with the Edit tool and change nothing else.
3. Run Verification and write the output to `.delix/evidence/verification.txt`.
4. Open the four pages in a browser. The box text fits inside its box on both index pages, and the usage Known limits read cleanly. Save one screenshot per page to `.delix/evidence/`.
5. Run `git add` with the 11 paths by name. Commit `T057: bayat kart ve delix.json belgesi, docs/delix lead'de`. Push with `git push -u origin HEAD` alone. Open the PR with `--body-file`; the body has `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔`, no `✘`. `bash tests/ledger_tests.sh` and `bash tests/evidence_tests.sh` → `ALL PASSED`.
- All suites → exit 0 on Python 3.9.6 and through the 3.13 shim (same commands as T056).
- `grep -n "STATE.json" skills/implement/SKILL.md templates/STATE.json` → exactly `skills/implement/SKILL.md:53:` (env_owner, read), `skills/implement/SKILL.md:66:` (Do not write) and `templates/STATE.json:2:`
- Each `grep -cF` gives `1`:
  - `'In a card worktree both `PreToolUse` hooks deny with one message when'`, `'whose card is not finished. The card is finished when the STATE at'` and `'and switch its own hooks off by'` in `README.md`;
  - `"\`PreToolUse\` hook'u da tek bir mesajla reddeder"`, `'bulunan ve kartı bitmemiş'` and `"hook'ların okuduğunu değiştirmez"` in `README.tr.md`;
  - `'and its card is not finished:'` and `'do not change what the hooks read'` in `site/usage.html`;
  - `'ve kartı bitmemişken çalışır'` and `"hook'ların okuduğunu değiştirmez"` in `site/tr/usage.html`;
  - `'>No local .delix/card, or card done?<'` in `site/index.html`;
  - `'>Yerel .delix/card yok mu, bitti mi?<'` in `site/tr/index.html`;
  - `'holds no `docs/delix/**` path'` in `agents/architect.md`;
  - `'move that change to a lead step in the wave plan'` and `"from the report's \`**PR:**\` line"` in `skills/dispatch/SKILL.md`.
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## Unreleased` then `29:## 0.7.2 — 2026-11-19`
- `grep -cF 'data-version="0.7.2"'` on each of the four pages → `2` (unchanged)
- `python3 -c "import json; json.load(open('templates/STATE.json'))"` → no output
- `git diff --numstat origin/main...HEAD` → 11 paths:
  - `README.md` 17/7, `README.tr.md` 17/8, `CHANGELOG.md` 24/0;
  - `site/usage.html` and `site/tr/usage.html` 2/2 each, `site/index.html` and `site/tr/index.html` 1/1 each;
  - `skills/implement/SKILL.md` 11/3, `agents/architect.md` 2/0, `skills/dispatch/SKILL.md` 4/1, `templates/STATE.json` 1/1.

  If git pairs lines differently, report the actual numbers.
- `git diff -U0 origin/main...HEAD -- README.md README.tr.md CHANGELOG.md skills agents | python3 -c "import sys; [print(len(l), l[:60]) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"` → no output
- `git diff -U0 origin/main...HEAD | python3 -c "import sys, unicodedata as u; [print(ascii(l)) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and any(u.category(c) in ('Cf', 'Zl', 'Zp') for c in l)]"` → no output

## Review Focus
- REQ-3 metin denetimi: no line tells the implementer to write `STATE.json`, and the env_owner read line stays.
- REQ-4: README lines 136, 164 and 436–440 (now 438–444), the usage hook and Known limits items, and the index box. Each one matches spec REQ-1 and REQ-2 and K351, with no claim beyond the spec (K305).
- TR/EN parity and escaped HTML. No version mark changes.

## Don'ts
- Do not touch `scripts/**`, `tests/**`, `hooks/**`, `docs/delix/**` (STATE.json too), `plugins/**`, `.claude-plugin/**`, or any `data-version` mark or footer.
- Do not reword a sentence the anchors do not change. If an anchor looks wrong, stop with `NEEDS_CONTEXT`.

## Out of scope (each with the reason)
- REQ-5 text in the README write-gate bullet: the spec does not list it (REQ-4); the CHANGELOG names it.
- New rows in the index write-gate diagram for the config and marker rules: REQ-4 names only the box.
- The version and PR numbers in the CHANGELOG: T058.

## Report contract
`.delix/report.md` holds:
- the status token;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version`;
- the screenshot paths;
- the PR number in the `**PR:**` line, and the branch;
- assumptions.

Do not write STATE.json. Read only this card and spec REQ-3, REQ-4, K347–K351.

## Review findings (filled by the lead)
- Round 1 (PR #87 @ `b13a18f5ba4dc70482e6bc3dfd8ac89545ec5d26`): deterministic gate green (the 11 files equal the lead's prototype
  byte for byte; CI `test` and `check` pass; Stop gate and Verification `[exit 0]`; both index boxes fit, seen in the
  screenshots). qa **ACCEPT** (P0 0, P1 0). security **CLEAN**:
  - Low (merge order, no text change): the README, site and implement-skill text describe T056's behaviour, and the
    site publishes on every push to main. Merge T057 after T056 or with it; if T056's behaviour changes, review A1, A4,
    A7, A9 and A14 again first.
  - P2, noted (no fix): the published Known limits name deleting `.delix/card` but not overwriting it through Bash
    (spec §6 known limit); the lead copies `pr` from the implementer's report, the same trust as before, bounded by
    the K297 head check after merge.
