# T060 — Docs: the write gate denies the worktree's `.git`; two limits of the Bash write rule; CHANGELOG Unreleased

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T060 | M | 2 | docs | 29 | open |

**Tier:** 2. Seven files, and the text describes new hook behaviour. No file is protected and none matches `test_paths` (`docs/delix/delix.json:7-24`).

**Goal (1 sentence):** Change the text in four places, with no version change:
- README and README.tr: `.git` joins the write gate's denied targets, the Bash sentence is narrowed to "inside the worktree", the A13 sentence is tied to the write gate, and the two Bash limits are added;
- the four site pages: the same, as TR/EN twins;
- `CHANGELOG.md`: a new `## Unreleased` with two items.

**Spec:** `docs/delix/specs/E-gitdir-bash-outside.md` REQ-2, REQ-3 (text), K358, K361, K364

**Docs/site:** this card is the README/site update for T059. T059's behaviour comes from the spec REQ-1 text only, so this card runs in parallel with it. Merge it after T059 or together (T057 round 1, security Low: the site publishes on every push to main).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `README.md` (A1 to A4)
- Modify: `README.tr.md` (A5 to A8)
- Modify: `site/index.html` (A9 to A13)
- Modify: `site/tr/index.html` (A14 to A18)
- Modify: `site/usage.html` (A19)
- Modify: `site/tr/usage.html` (A20)
- Modify: `CHANGELOG.md` (A21)
- Test: none new. `tests/site_tests.sh` already checks the pages.

## Interfaces
- Consumed: the T059 behaviour in spec REQ-1 (text only).
- Produced: the `## Unreleased` section. Its two items' first lines carry `(🔐 K358, K359, K360):` and `(K358, K361):`. T061 anchors on these and on `## Unreleased`.

## Lead decisions
- **D1 · Reflow:** README.md 105–106 and 121–122, and README.tr.md 106–107 and 121–122, are reflowed, because the new text would pass 120 characters. No other words change.
- **D2 · Known limits:** the A13 sentence changes in place (README.md:394, README.tr.md:395). The two Bash limits become a new paragraph after the write-gate paragraph, so "For that reason" / "Bu yüzden" keep their referent.
- **D3 · Index diagram:** only in-line replacements. There is no new box and no `viewBox` change. The row 4 box text is EN 33 and TR 34 characters; row 2 EN is 35 and TR row 6 is 38.
- **D4 · Source lines:** no `Source:` / `Kaynak:` line changes.
  - The usage line (240) already names `README.md (Known limits, …)`, which carries the new item.
  - The index line (489) names `scripts/write_gate.py`, `scripts/bash_gate.py` and `README.md (Known limits, …)`.
- **D5 · "can change":** the hook-code sentence says "can change" / "değişebilir". Spec §6: it was not checked whether `plugin update` copies the work tree or HEAD.
- **D6 · No version change:** no `data-version`, footer date or `plugin.json` edit (T061).

## Edit anchors (base main af6c35b)
- Line counts on the base: `README.md` 455, `README.tr.md` 459, `CHANGELOG.md` 291, `site/index.html` and `site/tr/index.html` 702 each, `site/usage.html` and `site/tr/usage.html` 251 each.
- Line numbers are from the base. Edit by content: match the quoted text, and if it differs, stop with `NEEDS_CONTEXT`.
- Code blocks are not indented: copy each line as it stands, including its leading spaces.
- The lead applied A1 to A21 to a base copy with an independent applier (2026-11-20) and got the "after" sha256s
  below (sha256 prefixes, 16 hex). On that copy `bash tests/site_tests.sh` gave 23 `✔`, every Verification `grep`
  matched, and the numstat and `wc -l` values below held. Compare yours with `shasum -a 256 <file>`; if one
  differs, find the anchor before you go on.

| file | base | after |
|---|---|---|
| `README.md` | `801997f0a67e3ee1` | `1e9b66b1150f1d4e` |
| `README.tr.md` | `1f63bb3a0c9995dc` | `8c387cf41e82e3f0` |
| `CHANGELOG.md` | `06b2e77a22c3dffd` | `97c18f72a72f8f13` |
| `site/index.html` | `b67fb00f2f855285` | `340c67eae6f3bf78` |
| `site/tr/index.html` | `fa6b6790b05464d9` | `24ac0a5ae6202cf5` |
| `site/usage.html` | `89483d2225b0ee1f` | `e031898309073080` |
| `site/tr/usage.html` | `f3dd136448126a2c` | `7e27f21786285811` |

**A1 · `README.md` lines 105–106 · replace.** Current:
```text
  `~/.claude/delixcrew/trust.json`; for the reviewer agents it denies every write. In an implementer worktree it also denies writes outside the worktree, to the card and `docs/delix/**`, to a
  protected path without an approved card, and to an existing test file.
```
With (4 lines):
```text
  `~/.claude/delixcrew/trust.json`; for the reviewer agents it denies every write. In an implementer worktree it
  also denies writes outside the worktree, to the card, to `docs/delix/**`, to the worktree's own `.git` file or
  directory and anything under it (the hooks find the card through it; T059), to a protected path without an
  approved card, and to an existing test file.
```

**A2 · `README.md` lines 121–122 · replace.** Current:
```text
  other reviewers get no Bash. In an implementer worktree it denies shell writes into a protected path and runs
  `gitleaks protect --staged` before every `git commit`. There a push runs only as
```
With:
```text
  other reviewers get no Bash. In an implementer worktree it denies shell writes into a protected path inside the
  worktree and runs `gitleaks protect --staged` before every `git commit`. There a push runs only as
```

**A3 · `README.md` line 394 · replace.** Current:
```text
paths; see [Feedback](#feedback) and [Triage](#triage)). A path escaping the worktree (cwd) is always rejected (A13, K42); path matching is relative to cwd. For
```
With (2 lines):
```text
paths; see [Feedback](#feedback) and [Triage](#triage)). The write gate always rejects a path that escapes the worktree
(cwd; A13, K42); path matching is relative to cwd. For
```

**A4 · `README.md` · insert after line 397** (`the card's header table; only the lead writes it, after the user's explicit "yes" in chat, and commits it to main.`). Insert 13 lines; the first is blank:
```text

The Bash write rule (redirects, `cp`, `mv` and `tee`) matches its target relative to cwd as well, so a pattern with a
folder, such as `scripts/**`, does not match a target outside the worktree: another checkout, the main checkout that
holds the card worktree under `.claude/worktrees/<x>` and its `docs/delix/`, by a relative path such as
`../../../scripts/x.py` or an absolute one. A pattern without a folder, such as `.env*`, looks at the file name and
still matches. Such a write also reaches the plugin's own files: when the plugin runs from a checkout, its hook code
can change at once (`--plugin-dir`) or with the next `claude plugin update` (a `directory` marketplace); run
`git status` in that checkout before such a session or update. The boundary here is Claude Code's Bash permission
prompt (K77); the `--permission-mode auto` session that dispatch opens has no prompt, so only the auto mode
classifier sees this write (K358). A Bash command that changes the worktree's `.git` (`printf … > .git` or
`git add -f .delix/card`) switches the three hooks off; that is the same class as deleting `.delix/card` and a
`cd` below the worktree root (see the push rule below; K361). The write gate denies that change through Write and
Edit (T059).
```

**A5 · `README.tr.md` lines 106–107 · replace.** Current:
```text
  reddeder. Uygulayıcı worktree'sinde ayrıca worktree dışına, karta ve `docs/delix/**`'a, onaylı kartı olmayan korumalı
  yola ve mevcut test dosyasına yazmayı reddeder.
```
With (3 lines):
```text
  reddeder. Uygulayıcı worktree'sinde ayrıca worktree dışına, karta, `docs/delix/**`'a, worktree'nin kendi `.git`
  dosyasına ya da dizinine ve altındaki her yola (hook'lar kartı onun üzerinden bulur; T059), onaylı kartı olmayan
  korumalı yola ve mevcut test dosyasına yazmayı reddeder.
```

**A6 · `README.tr.md` lines 121–122 · replace.** Current:
```text
  denetimidir, sandbox değildir. Diğer inceleyicilere Bash verilmez. Uygulayıcı worktree'sinde korumalı yola kabuk
  yazmasını reddeder ve her `git commit`'ten önce `gitleaks protect --staged` çalıştırır. Orada push yalnız
```
With (3 lines):
```text
  denetimidir, sandbox değildir. Diğer inceleyicilere Bash verilmez.
  Uygulayıcı worktree'sinde, worktree içindeki korumalı yola kabuk yazmasını reddeder ve her `git commit`'ten önce
  `gitleaks protect --staged` çalıştırır. Orada push yalnız
```

**A7 · `README.tr.md` line 395 · replace.** Current:
```text
yollarını keser; bkz. [Geri bildirim](#geri-bildirim) ve [Triage](#triage)). Worktree (cwd) dışına çıkan yol her zaman reddedilir (A13, K42); yol eşleşmeleri cwd'ye
```
With (2 lines):
```text
yollarını keser; bkz. [Geri bildirim](#geri-bildirim) ve [Triage](#triage)). Yazma kapısı worktree (cwd) dışına çıkan
yolu her zaman reddeder (A13, K42); yol eşleşmeleri cwd'ye
```

**A8 · `README.tr.md` · insert after line 398** (`açılır; bu satırı yalnız ekip lideri, kullanıcının sohbetteki açık "evet"inden sonra yazar ve main'e commit eder.`). Insert 12 lines; the first is blank:
```text

Bash yazma kuralı (yönlendirme, `cp`, `mv` ve `tee`) hedefi de cwd'ye göre eşler; bu yüzden `scripts/**` gibi
klasörlü bir desen worktree dışındaki bir hedefi eşlemez: başka bir checkout, kart worktree'sini
`.claude/worktrees/<x>` altında tutan ana checkout ve onun `docs/delix/`'i (`../../../scripts/x.py` gibi göreli
ya da mutlak bir yolla). `.env*` gibi klasörsüz bir desen dosya adına bakar ve yine eşler. Böyle bir yazım plugin'in
kendi dosyalarına da ulaşır: plugin bir checkout'tan çalışıyorsa hook kodu hemen (`--plugin-dir`) ya da sonraki
`claude plugin update` ile (`directory` marketplace) değişebilir; böyle bir oturumdan ya da güncellemeden önce o
checkout'ta `git status` çalıştır. Buradaki sınır Claude Code'un Bash izin istemidir (K77); dispatch'in açtığı
`--permission-mode auto` oturumunda istem yoktur, bu yazımı yalnız auto mode sınıflandırıcısı görür (K358).
Worktree'nin `.git`'ini değiştiren bir Bash komutu (`printf … > .git` ya da `git add -f .delix/card`) üç hook'u
kapatır; bu, `.delix/card`'ı silmekle ve worktree kökünün altına `cd` ile aynı sınıftır (bkz. aşağıdaki push
kuralı; K361). Yazma kapısı aynı değişikliği Write ve Edit ile reddeder (T059).
```

**A9–A13 · `site/index.html` · replace in the line.** Each Find occurs once:
- **A9 · line 365:** `outside the worktree, card and docs/delix, protected path` → `outside the worktree, card, docs/delix and .git, protected path`
- **A10 · line 407:** `>Card file or docs/delix/**?<` → `>Card file, docs/delix/** or .git?<`
- **A11 · line 446:** `<code>tee</code> into a protected path. To cover this gap` → `<code>tee</code> into a protected path inside the worktree. To cover this gap`
- **A12 · line 466:** `Outside the worktree, the card and <code>docs/delix/**</code> are closed.` → `Outside the worktree, the card, <code>docs/delix/**</code> and the worktree's own <code>.git</code> are closed.`
- **A13 · line 475:** `<dd>Shell writes into a protected path are denied.` → `<dd>Shell writes into a protected path inside the worktree are denied.`

**A14–A18 · `site/tr/index.html` · replace in the line.** Each Find occurs once:
- **A14 · line 365:** `worktree dışı, kart ve docs/delix, korumalı yol` → `worktree dışı, kart, docs/delix ve .git, korumalı yol`
- **A15 · line 407:** `>Kart dosyası ya da docs/delix/** mı?<` → `>Kart, docs/delix/** ya da .git mi?<`
- **A16 · line 446:** `bash_gate yalnız korumalı yola giden yönlendirmeyi` → `bash_gate yalnız worktree içindeki korumalı yola giden yönlendirmeyi`
- **A17 · line 466:** `Worktree dışı, kart ve <code>docs/delix/**</code> kapalı.` → `Worktree dışı, kart, <code>docs/delix/**</code> ve worktree'nin kendi <code>.git</code>'i kapalı.`
- **A18 · line 475:** `<dd>Korumalı yola shell ile yazma reddedilir.` → `<dd>Worktree içindeki korumalı yola shell ile yazma reddedilir.`

**A19 · `site/usage.html` · insert after line 222** (`        <li>write_gate sees only the Write, Edit, MultiEdit and NotebookEdit tools, not files written through Bash. …</li>`). Insert 1 line:
```text
        <li>In a card worktree the write gate denies a path outside the worktree and the worktree's own <code>.git</code>. The Bash write rule (redirects, <code>cp</code>, <code>mv</code>, <code>tee</code>) matches its target relative to cwd, so a pattern with a folder such as <code>scripts/**</code> does not match a target outside the worktree: another checkout, the main checkout that holds the card worktree under <code>.claude/worktrees/&lt;x&gt;</code> and its <code>docs/delix/</code>, by a relative path such as <code>../../../scripts/x.py</code> or an absolute one. A pattern without a folder such as <code>.env*</code> looks at the file name and still matches. Such a write also reaches the plugin's own files: when the plugin runs from a checkout, its hook code can change at once (<code>--plugin-dir</code>) or with the next <code>claude plugin update</code> (a <code>directory</code> marketplace); run <code>git status</code> in that checkout first. The boundary is Claude Code's Bash permission prompt; the <code>--permission-mode auto</code> session that dispatch opens has no prompt, so only the auto mode classifier sees this write. A Bash command that changes the worktree's <code>.git</code> (<code>printf … &gt; .git</code> or <code>git add -f .delix/card</code>) switches the three hooks off, the same as deleting <code>.delix/card</code>.</li>
```

**A20 · `site/tr/usage.html` · insert after line 222** (`        <li>write_gate yalnız Write, Edit, MultiEdit ve NotebookEdit araçlarını görür; …</li>`). Insert 1 line:
```text
        <li>Kart worktree'sinde yazma kapısı worktree dışındaki bir yolu ve worktree'nin kendi <code>.git</code>'ini reddeder. Bash yazma kuralı (yönlendirme, <code>cp</code>, <code>mv</code>, <code>tee</code>) hedefi cwd'ye göre eşler; bu yüzden <code>scripts/**</code> gibi klasörlü bir desen worktree dışındaki bir hedefi eşlemez: başka bir checkout, kart worktree'sini <code>.claude/worktrees/&lt;x&gt;</code> altında tutan ana checkout ve onun <code>docs/delix/</code>'i (<code>../../../scripts/x.py</code> gibi göreli ya da mutlak bir yolla). <code>.env*</code> gibi klasörsüz bir desen dosya adına bakar ve yine eşler. Böyle bir yazım plugin'in kendi dosyalarına da ulaşır: plugin bir checkout'tan çalışıyorsa hook kodu hemen (<code>--plugin-dir</code>) ya da sonraki <code>claude plugin update</code> ile (<code>directory</code> marketplace) değişebilir; önce o checkout'ta <code>git status</code> çalıştır. Sınır Claude Code'un Bash izin istemidir; dispatch'in açtığı <code>--permission-mode auto</code> oturumunda istem yoktur, bu yazımı yalnız auto mode sınıflandırıcısı görür. Worktree'nin <code>.git</code>'ini değiştiren bir Bash komutu (<code>printf … &gt; .git</code> ya da <code>git add -f .delix/card</code>) üç hook'u kapatır; bu, <code>.delix/card</code>'ı silmekle aynıdır.</li>
```

**A21 · `CHANGELOG.md` line 5 · replace.** Current: `## 0.7.3 — 2026-11-20`. Replace it with these 17 lines; the last one is the current line:
```text
## Unreleased

- **The write gate denies writes to the card worktree's `.git`** (🔐 K358, K359, K360): in a card worktree
  Write, Edit, MultiEdit and NotebookEdit can no longer write the worktree's own `.git` (the gitfile of a linked
  worktree or the directory of a main checkout) or anything under it, in any letter case and through a symlink, even
  when the card lists the path and carries the approval line. Junk written there used to stop git, so the hooks no
  longer found the card and switched off, which opened `docs/delix/**`, protected paths and a push to the default
  branch. The deny message gives the Bash command that adds `.delix/` to `info/exclude`. Bash can still change
  `.git`; that is a known limit (K361).
- **Two limits of the Bash write rule are documented** (K358, K361): the rule matches a redirect, `cp`, `mv` or
  `tee` target relative to cwd, so a folder pattern such as `scripts/**` does not match a target in another
  checkout or in the main checkout that holds the card worktree, and that write can reach the plugin's own hook
  code when the plugin runs from a checkout. The `--permission-mode auto` session that dispatch opens shows no Bash
  prompt for it. A Bash change to the worktree's `.git` switches the hooks off, like deleting `.delix/card`.
  README, README.tr and the site say so, and their write-gate text names `.git`.

## 0.7.3 — 2026-11-20
```

## Global Constraints
- Spec REQ-2: "Bash cümlesini taşıyan diğer yerler aynı "worktree içindeki" kaydıyla daraltılır … Belge kartı her yerin yeni cümlesini kartta harfi harfine yazar."
- Spec REQ-3: "`.git` reddedilen hedeflere eklenir … (satır 365; yeni kutu yok, şema boyu değişmez)".
- CLAUDE.md site rules apply:
  - no script, event handler or form;
  - every claim comes from a repo file;
  - the TR and EN twins carry the same content;
  - a backticked word is `<code>`, and `<`, `>` and `&` are escaped.
- New README and CHANGELOG lines are at most 120 characters. No raw invisible character. Turkish letters, `—`, `…` and `🔐` stay as the files already have them.
- No version change (T061).

## Steps
1. Baseline:
   - `bash tests/site_tests.sh` gives 23 `✔`;
   - `grep -n '^## ' CHANGELOG.md | head -1` gives `5:## 0.7.3 — 2026-11-20`;
   - `grep -cF 'A path escaping the worktree (cwd) is always rejected (A13, K42)' README.md` gives `1`.
2. Apply A1 to A21 with the Edit tool and change nothing else.
3. Run Verification and write the output to `.delix/evidence/verification.txt`.
4. Open the four pages in a browser and save one screenshot per page to `.delix/evidence/`. Check two things:
   - on both index pages, the row 4 box text fits inside its box;
   - the new usage Known limits item reads cleanly.
5. Commit and push:
   - Run `git add` with the 7 paths by name.
   - Commit `T060: Spec E belgesi, .git reddi ve Bash yazımının sınırları`.
   - Run `git push -u origin HEAD` alone.
   - Open the PR with `--body-file`. The body has `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔`, no `✘`.
- Each `grep -cF` gives `1`:
  - **`README.md`:**
    - "to the worktree's own \`.git\` file or"
    - 'denies shell writes into a protected path inside the'
    - 'The write gate always rejects a path that escapes the worktree'
    - 'matches its target relative to cwd as well'
    - 'the \`--permission-mode auto\` session that dispatch opens has no prompt'
    - 'switches the three hooks off; that is the same class as deleting'
  - **`README.tr.md`:**
    - "worktree'nin kendi \`.git\`"
    - 'worktree içindeki korumalı yola kabuk yazmasını reddeder'
    - 'Yazma kapısı worktree (cwd) dışına çıkan'
    - "hedefi de cwd'ye göre eşler"
    - 'yalnız auto mode sınıflandırıcısı görür (K358)'
    - 'ile aynı sınıftır (bkz. aşağıdaki push'
  - **`site/index.html`:**
    - 'card, docs/delix and .git, protected path'
    - '>Card file, docs/delix/** or .git?<'
    - 'into a protected path inside the worktree. To cover'
    - "and the worktree's own <code>.git</code> are closed."
    - 'Shell writes into a protected path inside the worktree are denied.'
  - **`site/tr/index.html`:**
    - 'kart, docs/delix ve .git, korumalı yol'
    - '>Kart, docs/delix/** ya da .git mi?<'
    - 'bash_gate yalnız worktree içindeki korumalı yola'
    - "ve worktree'nin kendi <code>.git</code>'i kapalı."
    - 'Worktree içindeki korumalı yola shell ile yazma reddedilir.'
  - **`site/usage.html`:**
    - "In a card worktree the write gate denies a path outside the worktree and the worktree's own <code>.git</code>."
    - 'so only the auto mode classifier sees this write'
  - **`site/tr/usage.html`:**
    - "Kart worktree'sinde yazma kapısı worktree dışındaki bir yolu"
    - 'bu yazımı yalnız auto mode sınıflandırıcısı görür.'
  - **`CHANGELOG.md`:**
    - '(🔐 K358, K359, K360):'
    - '(K358, K361):'
- Each of these gives `0`:
  - `grep -cF 'A path escaping the worktree (cwd) is always rejected (A13, K42)' README.md`
  - `grep -cF 'Worktree (cwd) dışına çıkan yol her zaman reddedilir (A13, K42)' README.tr.md`
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## Unreleased` then `21:## 0.7.3 — 2026-11-20`.
- `grep -cF 'data-version="0.7.3"'` on each of the four pages → `2` (unchanged).
- `git diff --numstat origin/main...HEAD` → 7 paths:
  - `README.md` 21/5, `README.tr.md` 20/5, `CHANGELOG.md` 16/0;
  - `site/index.html` and `site/tr/index.html` 5/5 each;
  - `site/usage.html` and `site/tr/usage.html` 1/0 each.

  If they differ, report the actual numbers.
- `wc -l` → `README.md` 471, `README.tr.md` 474, `CHANGELOG.md` 307, both index pages 702, both usage pages 252.
- Line-length and invisible-character checks: the two T057 commands (`docs/delix/tasks/T057-docs-stale-card-config.md` Verification), run on `README.md README.tr.md CHANGELOG.md` → no output.

## Review Focus
- **No claim beyond the spec (K305):** each new text matches REQ-2 (three bullets) and REQ-3, plus K358, K361 and K364. Also check the "can change" wording (D5).
- **Parity and markup:** the TR/EN twins match, the HTML is escaped, and the row 4 box fits in both languages (screenshots).
- **Old A13 sentence:** gone from both READMEs. "For that reason" still refers to Bash being outside the write gate.

## Don'ts
- Do not touch `scripts/**`, `tests/**`, `hooks/**`, `docs/delix/**` (STATE.json too), `plugins/**`, `.claude-plugin/**`, `skills/**`, `agents/**`, `templates/**`, or any `data-version` mark or footer.
- Do not reword a sentence the anchors do not change. If an anchor looks wrong, stop with `NEEDS_CONTEXT`.

## Out of scope (each with the reason)
- A Bash `.git` item in the index Known limits note: REQ-2 names only the usage list.
- `site/index.html:475` and `site/tr/index.html:475` still describe the delix.json rule from before T056. That is not Spec E text; it is a lead follow-up.
- Version, footer dates and PR numbers: T061.

## Report contract
`.delix/report.md` holds:
- the status token;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version`;
- the screenshot paths;
- the PR number in the `**PR:**` line, and the branch;
- assumptions.

Do not write STATE.json. Read only this card and spec REQ-2, REQ-3, K358, K361, K364.

## Review findings (filled by the lead)
- (none yet)
