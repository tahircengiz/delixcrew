# T067 — Docs: the intake step, `docs/delix/intake.json` and the feedback counter sentence; CHANGELOG Unreleased (Spec F card C)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T067 | M | 2 | docs | 35 | open |

**Tier:** 2. Seven files. The text describes new behaviour (Spec F A and B). No file is protected and none matches `test_paths` (`docs/delix/delix.json:7-24`). Review: qa + security.

**Goal (1 sentence):** Change the text in four places, with no version change:
- README and README.tr: an intake row in Flow, `docs/delix/intake.json` in Files, and the corrected counter sentence in Feedback;
- the two usage pages: the same as TR/EN twins (first job, commands, project files, feedback, `Source:` lines);
- the two index pages: the record in the Lead row of the Topology table;
- `CHANGELOG.md`: a new `## Unreleased` with three items.

**Spec:** `docs/delix/specs/F-intake-decisions.md` REQ-7. The behaviour described comes from REQ-2, REQ-5 and §4, and from K401, K402, K405, K407, K408, K415, K416 and K418.

**Docs/site:** this card is the CLAUDE.md "a command or project file is added" update for `/delixcrew:intake`, `/delixcrew:start I<nnn>` and `docs/delix/intake.json`. T065 (#95 `8f7b3a4`) and T066 (#94 `78b8d92`) are already merged, so there is no merge-order rule.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `README.md` (A1 to A3)
- Modify: `README.tr.md` (A4 to A6)
- Modify: `site/index.html` (A7, A8)
- Modify: `site/tr/index.html` (A9, A10)
- Modify: `site/usage.html` (A11 to A18)
- Modify: `site/tr/usage.html` (A19 to A26)
- Modify: `CHANGELOG.md` (A27)
- Test: none new. `tests/site_tests.sh` already checks the pages.

## Interfaces
- **Consumed** (the text only, on main `d2528d4`):
  - `skills/intake/SKILL.md:10-17, 26-30, 47-56, 58-70, 72-74`
  - `skills/start/SKILL.md:42-54`
  - `skills/feedback/SKILL.md:53-57`
  - `skills/review/SKILL.md:57-60`
  - `skills/close/SKILL.md:30-32`
  - `scripts/intake.py:2-8, 64-95, 98-127, 149-240, 243-276, 373-377`
  - `templates/intake.json:1`
  - `scripts/feedback.py:223-227, 680-690` (the fingerprint, and count + 1)
  - `tests/intake_tests.sh:452-457`
- **Produced:** the `## Unreleased` section in `CHANGELOG.md`. Its three items' first lines carry these strings:
  - `(K402, K414–K417, K420, K421, K425–K427, K433; #95):`
  - `(K401, K405–K409, K415, K418, K419, K425; #94):`
  - `(K408, K415):`

  T068 anchors on `## Unreleased` and these strings, and adds this card's PR number to the third.

## Lead decisions
- **D1 · Reflow:** README.md 95–96 and 228–229, and README.tr.md 95–96 and 230, are reflowed because the new text would pass 120 characters. No other words change.
- **D2 · Flow rows:** each Flow row (A1, A4) is one Markdown table line, like rows 69–77, which are already over 120 characters. The 120-character rule applies to every other new line, and the line-length check skips lines that start with `|`.
- **D3 · Index:** no SVG change. Only the Topology table's Lead "Writes" cell changes, plus its `Source:` line (reasons under Out of scope).
- **D4 · Source lines:**
  - usage first job: adds `intake` to the skill list and `scripts/intake.py`;
  - usage commands: adds `skills/intake/SKILL.md · scripts/intake.py`;
  - usage files: adds `templates/intake.json · skills/intake/SKILL.md`;
  - usage feedback: adds `scripts/feedback.py · skills/intake/SKILL.md`;
  - index Topology: adds `skills/intake/SKILL.md`.
- **D5 · Counter wording:** "(letter case, punctuation and digits aside)" comes from `scripts/feedback.py:223-227`. The joining sentence is limited to the delixcrew repository (K408, `skills/feedback/SKILL.md:54`).
- **D6 · CHANGELOG:** T065 and T066 items carry #95 and #94. This card's own item has no PR yet; T068 adds it.
- **D7 · Tone:** README.tr uses "siz" and the TR site uses "sen", as each file already does.
- **D8 · No version change:** no `data-version`, footer date or `plugin.json` edit (T068).
- **D9 · Live record:** main now has `docs/delix/intake.json` (the lead's REQ-8 seed). `tests/intake_tests.sh` checks it in your Stop gate; it gives exit 0. The text holds with or without the record ("only where you asked for it").

## Edit anchors (base main d2528d4)
- Line counts on the base: `README.md` 478, `README.tr.md` 480, `CHANGELOG.md` 307, `site/index.html` and `site/tr/index.html` 702 each, `site/usage.html` and `site/tr/usage.html` 252 each. Line numbers are from the base; the seven files are the same on later main up to the commit that adds this card. Edit by content: match the quoted text, and if it differs, stop with `NEEDS_CONTEXT`.
- Code blocks are not indented: copy each line as it stands, including its leading spaces.
- "Replace in the line": the Find text occurs once in its file; replace only that text.
- The lead applied A1 to A27 to a base copy with an independent applier (2026-11-21; a script that parses this section and checks every anchor against its base line) and got the "after" sha256s below (sha256 prefixes, 16 hex). On that copy `bash tests/site_tests.sh` gave 23 `✔`, 0 `✘`, exit 0, every Verification `grep` matched, and the numstat and `wc -l` values below held. Compare yours with `shasum -a 256 <file>`; if one differs, find the anchor before you go on.

| file | base | after |
|---|---|---|
| `README.md` | `1d0d4dc4d0293ee9` | `bab0c59c06deb58b` |
| `README.tr.md` | `931ea701be9535e6` | `17f329eac099e3f2` |
| `CHANGELOG.md` | `01bd37ab5f15548f` | `8cb2f1ccbac3d548` |
| `site/index.html` | `57e9ed423dd788ed` | `ed50a80591fc4a07` |
| `site/tr/index.html` | `a46fa80936fba2be` | `d1da2018b021c9ca` |
| `site/usage.html` | `4c0df401f155d62b` | `e756c0ea32a29a90` |
| `site/tr/usage.html` | `f0aaf2441d7a422d` | `1edeee0f32ea1d6b` |

**A1 · `README.md` · insert after line 77.** Current line 77:
```text
| issues | `/delixcrew:triage [#n]` | In the delixcrew repo: reads incoming issues cleaned, the read-only `architect` checks each one and proposes a decision; after your `<decision> #<n>` in chat it records it and shows the exact comment; you publish it from your own terminal. See [Triage](#triage). |
```
Insert (1 line):
```text
| intake | `/delixcrew:intake [add\|decide\|list]` | Only where `docs/delix/intake.json` exists (set up only when you ask): follow-ups, review findings a card did not fix, close drift and, in the delixcrew repo, feedback drafts wait there as items with their evidence; a new event of the same problem is a new ref on its item. `decide` shows each pending item with the decision of the table in `scripts/intake.py`; an `accept`, a `wontfix` or a decision other than the table's is written only after your `<decision> I<nnn>` in chat, the lead writes that consent, and `intake.py check` fails when the decision, the table's result or the number of refs changes after it. `/delixcrew:start I<nnn>` takes only an accepted item with no work yet, shows it as `UNTRUSTED` and writes no file before your yes in chat. |
```

**A2 · `README.md` lines 95–96 · replace.** Current:
```text
on request, in `.gitignore`). In the implementer worktree: `.delix/card` (activates the hooks), `.delix/report.md`,
`.delix/test-result.txt`, `.delix/evidence/`.
```
With (4 lines):
```text
on request, in `.gitignore`) and `docs/delix/intake.json` (the intake items with their refs, evidence, decision,
basis, reason, consent and `work`, checked by `scripts/intake.py check`; only where you asked the lead to set it
up from `templates/intake.json`, not by default). In the implementer worktree: `.delix/card`
(activates the hooks), `.delix/report.md`, `.delix/test-result.txt`, `.delix/evidence/`.
```

**A3 · `README.md` lines 228–229 · replace.** Current:
```text
   and `/delixcrew:review` when one of the three events above happened. A repeated finding raises the draft's count
   instead of adding a new one.
```
With (4 lines):
```text
   and `/delixcrew:review` when one of the three events above happened. A finding with the same kind (bug or
   feature), component and title (letter case, punctuation and digits aside) raises the draft's count; a different
   wording opens a new draft. Only in the delixcrew repository itself (with `docs/delix/intake.json`)
   does the lead join the drafts of one problem in one intake item, one ref per draft (`/delixcrew:intake add`).
```

**A4 · `README.tr.md` · insert after line 77.** Current line 77:
```text
| issue'lar | `/delixcrew:triage [#n]` | delixcrew reposunda: gelen issue'ları temizlenmiş okur, salt-okunur `architect` her birini kontrol edip bir karar önerir; sohbette `<karar> #<n>` yazınca kaydeder ve yayınlanacak yorumu aynen gösterir; yayını siz kendi terminalinizden yaparsınız. Bkz. [Triage](#triage). |
```
Insert (1 line):
```text
| intake | `/delixcrew:intake [add\|decide\|list]` | Yalnız `docs/delix/intake.json` olan projede (siz isteyince kurulur): takip işleri, kartın düzeltmediği inceleme bulguları, close'un drift bulguları ve delixcrew reposunda geri bildirim taslakları kanıtlarıyla birer öğe olarak orada bekler; aynı sorunun yeni olayı kendi öğesine yeni bir ref olur. `decide` bekleyen her öğeyi `scripts/intake.py`'deki tablonun verdiği kararla gösterir; `accept`, `wontfix` ya da tablodan farklı bir karar ancak sohbette `<karar> I<nnn>` yazmanızdan sonra yazılır, bu onayı ekip lideri yazar ve sonra karar, tablonun sonucu ya da ref sayısı değişirse `intake.py check` hata verir. `/delixcrew:start I<nnn>` yalnız kabul edilmiş ve henüz işe dönüşmemiş öğeyi alır, onu `UNTRUSTED` olarak gösterir ve sohbetteki evet'inizden önce hiçbir dosya yazmaz. |
```

**A5 · `README.tr.md` lines 95–96 · replace.** Current:
```text
üretilir, `.gitignore`'da). Uygulayıcı worktree'sinde `.delix/card` (hook'ları aktifleştirir), `.delix/report.md`,
`.delix/test-result.txt`, `.delix/evidence/`.
```
With (4 lines):
```text
üretilir, `.gitignore`'da) ve `docs/delix/intake.json` (ref'leri, kanıtı, kararı, dayanağı, gerekçesi, onayı ve
`work` alanıyla intake öğeleri; `scripts/intake.py check` denetler; yalnız ekip liderinden istediğiniz projede
`templates/intake.json`'dan kurulur, varsayılan olarak yoktur). Uygulayıcı worktree'sinde `.delix/card`
(hook'ları aktifleştirir), `.delix/report.md`, `.delix/test-result.txt`, `.delix/evidence/`.
```

**A6 · `README.tr.md` line 230 · replace.** Current:
```text
   `/delixcrew:close` ve `/delixcrew:review` oluşturur. Tekrarlanan bulgu yeni taslak açmaz, sayacı artırır.
```
With (4 lines):
```text
   `/delixcrew:close` ve `/delixcrew:review` oluşturur. Türü (bug ya da feature), bileşeni ve başlığı (büyük-küçük
   harf, noktalama ve rakam farkı sayılmaz) aynı olan bulgu yeni taslak açmaz, taslağın sayacını artırır; farklı
   ifade yeni taslak açar. Ekip lideri aynı sorunun taslaklarını yalnız delixcrew reposunun kendisinde
   (`docs/delix/intake.json` varken) bir intake öğesinde birleştirir (her taslak bir ref; `/delixcrew:intake add`).
```

**A7, A8 · `site/index.html` · replace in the line:**
- **A7 · line 185:** `metrics, feedback draft</td>` → `metrics, feedback draft, the intake record (where <code>docs/delix/intake.json</code> exists)</td>`
- **A8 · line 194:** `· scripts/bash_gate.py</p>` → `· scripts/bash_gate.py · skills/intake/SKILL.md</p>`

**A9, A10 · `site/tr/index.html` · replace in the line:**
- **A9 · line 185:** `metrics, feedback taslağı</td>` → `metrics, feedback taslağı, intake kaydı (<code>docs/delix/intake.json</code> olan projede)</td>`
- **A10 · line 194:** `· scripts/bash_gate.py</p>` → `· scripts/bash_gate.py · skills/intake/SKILL.md</p>`

**A11 · `site/usage.html` line 92 · replace in the line.** Find:
```text
<code>/delixcrew:verify</code> instead of the full flow.</p></li>
```
With:
```text
<code>/delixcrew:verify</code> instead of the full flow. Where <code>docs/delix/intake.json</code> exists, <code>/delixcrew:start I&lt;nnn&gt;</code> takes the request from an intake item: only an accepted item with no work yet; it is shown as <code>UNTRUSTED</code> and no file is written before your yes in chat.</p></li>
```

**A12 · `site/usage.html` line 104 · replace in the line:** `verify (SKILL.md) · scripts/trust.py</p>` → `verify, intake (SKILL.md) · scripts/trust.py · scripts/intake.py</p>`

**A13 · `site/usage.html` · insert after line 126.** Current line 126:
```text
        <tr><th><code>/delixcrew:triage</code></th><td>Only in the delixcrew repo, when issues arrive</td><td>Reads issues cleaned; the architect proposes a decision. You decide in chat with the number (<code>accept #12</code>) and publish the comment and labels from your own terminal. Only an issue accepted in triage becomes work through <code>/delixcrew:start #&lt;n&gt;</code>.</td></tr>
```
Insert (1 line):
```text
        <tr><th><code>/delixcrew:intake</code></th><td>Only where <code>docs/delix/intake.json</code> exists</td><td><code>add</code>: records a follow-up, a review finding a card did not fix, a close drift finding or, in the delixcrew repo, a feedback draft as an item with its evidence; a new event of the same problem is a new ref on that item. <code>decide</code>: shows each pending item with the decision of the table in <code>scripts/intake.py</code>. You decide in chat with the id (<code>accept I004</code>); an <code>accept</code>, a <code>wontfix</code> or a decision other than the table's is written only then. <code>list</code>: shows the items. Only an accepted item with no work yet becomes work through <code>/delixcrew:start I&lt;nnn&gt;</code>.</td></tr>
```

**A14 · `site/usage.html` line 130 · replace in the line:** `· README.md (Triage)</p>` → `· README.md (Triage) · skills/intake/SKILL.md · scripts/intake.py</p>`

**A15 · `site/usage.html` · insert after line 147.** Current line 147:
```text
        <li><code>verifications/&lt;date&gt;-&lt;name&gt;.md</code>: verify reports</li>
```
Insert (1 line):
```text
        <li><code>intake.json</code>: intake items with their refs, evidence, decision, consent and <code>work</code>; only where you asked the lead to set it up from <code>templates/intake.json</code>, not by default</li>
```

**A16 · `site/usage.html` line 173 · replace in the line:** `· templates/report.md</p>` → `· templates/report.md · templates/intake.json · skills/intake/SKILL.md</p>`

**A17 · `site/usage.html` line 184 · replace in the line.** Find:
```text
A repeated finding raises the draft's count instead of adding a new one.
```
With:
```text
A finding with the same kind (bug or feature), component and title (letter case, punctuation and digits aside) raises the draft's count; a different wording opens a new draft. Only in the delixcrew repository itself (with <code>docs/delix/intake.json</code>) does the lead join the drafts of one problem in one intake item, one ref per draft.
```

**A18 · `site/usage.html` line 199 · replace in the line:** `Data &amp; privacy) · skills/feedback/SKILL.md</p>` → `Data &amp; privacy) · skills/feedback/SKILL.md · scripts/feedback.py · skills/intake/SKILL.md</p>`

**A19 · `site/tr/usage.html` line 92 · replace in the line.** Find:
```text
<code>/delixcrew:verify</code> önerilir.</p></li>
```
With:
```text
<code>/delixcrew:verify</code> önerilir. <code>docs/delix/intake.json</code> olan projede <code>/delixcrew:start I&lt;nnn&gt;</code> isteği bir intake öğesinden alır: öğe kabul edilmiş ve henüz işe dönüşmemiş olmalıdır; öğe <code>UNTRUSTED</code> olarak gösterilir ve sohbetteki evet'inden önce hiçbir dosya yazılmaz.</p></li>
```

**A20 · `site/tr/usage.html` line 104 · replace in the line:** `verify (SKILL.md) · scripts/trust.py</p>` → `verify, intake (SKILL.md) · scripts/trust.py · scripts/intake.py</p>`

**A21 · `site/tr/usage.html` · insert after line 126.** Current line 126:
```text
        <tr><th><code>/delixcrew:triage</code></th><td>Yalnız delixcrew reposunda, issue gelince</td><td>Issue'ları temizleyerek okur; architect bir karar önerir. Kararı sen sohbette numarasıyla verirsin (<code>accept #12</code>); yorum ve etiketi kendi terminalinde yayımlarsın. Yalnız triage'da kabul edilen issue <code>/delixcrew:start #&lt;n&gt;</code> ile işe dönüşür.</td></tr>
```
Insert (1 line):
```text
        <tr><th><code>/delixcrew:intake</code></th><td>Yalnız <code>docs/delix/intake.json</code> olan projede</td><td><code>add</code>: bir takip işini, kartın düzeltmediği bir inceleme bulgusunu, bir close drift bulgusunu ya da delixcrew reposunda bir geri bildirim taslağını kanıtıyla birlikte öğe olarak kaydeder; aynı sorunun yeni olayı o öğeye yeni bir ref olur. <code>decide</code>: bekleyen her öğeyi <code>scripts/intake.py</code>'deki tablonun kararıyla gösterir. Kararı sen sohbette id ile verirsin (<code>accept I004</code>); <code>accept</code>, <code>wontfix</code> ya da tablodan farklı bir karar ancak o zaman yazılır. <code>list</code>: öğeleri gösterir. Yalnız kabul edilmiş ve henüz işe dönüşmemiş öğe <code>/delixcrew:start I&lt;nnn&gt;</code> ile işe dönüşür.</td></tr>
```

**A22 · `site/tr/usage.html` line 130 · replace in the line:** `· README.md (Triage)</p>` → `· README.md (Triage) · skills/intake/SKILL.md · scripts/intake.py</p>`

**A23 · `site/tr/usage.html` · insert after line 147.** Current line 147:
```text
        <li><code>verifications/&lt;tarih&gt;-&lt;ad&gt;.md</code>: verify raporları</li>
```
Insert (1 line):
```text
        <li><code>intake.json</code>: ref'leri, kanıtı, kararı, onayı ve <code>work</code> alanıyla intake öğeleri; yalnız ekip liderinden istediğin projede <code>templates/intake.json</code>'dan kurulur, varsayılan olarak yoktur</li>
```

**A24 · `site/tr/usage.html` line 173 · replace in the line:** `· templates/report.md</p>` → `· templates/report.md · templates/intake.json · skills/intake/SKILL.md</p>`

**A25 · `site/tr/usage.html` line 184 · replace in the line.** Find:
```text
Aynı bulgu tekrar ederse yeni taslak açılmaz, sayaç artar.
```
With:
```text
Türü (bug ya da feature), bileşeni ve başlığı (büyük-küçük harf, noktalama ve rakam farkı sayılmaz) aynı olan bulgu yeni taslak açmaz, taslağın sayacını artırır; farklı ifade yeni taslak açar. Ekip lideri aynı sorunun taslaklarını yalnız delixcrew reposunun kendisinde (<code>docs/delix/intake.json</code> varken) tek bir intake öğesinde birleştirir; her taslak bir ref olur.
```

**A26 · `site/tr/usage.html` line 199 · replace in the line:** `Data &amp; privacy) · skills/feedback/SKILL.md</p>` → `Data &amp; privacy) · skills/feedback/SKILL.md · scripts/feedback.py · skills/intake/SKILL.md</p>`

**A27 · `CHANGELOG.md` line 5 · replace.** Current: `## 0.7.4 — 2026-11-20`. Replace it with these 30 lines; the last one is the current line:
```text
## Unreleased

- **The intake record and its read-only checker** (K402, K414–K417, K420, K421, K425–K427, K433; #95):
  `scripts/intake.py check | list [--pending] | show I<nnn> [--require accepted]` reads `docs/delix/intake.json`
  (a missing file is an empty record) and writes no file. `check` exits 2 on a shape error (including a `title` or
  `reason` that fails the public text filter) and 8 on a rule: a `basis: table` decision that differs from the
  code table; an `accept`, a `wontfix`, a decision on a `gate_open` item or a maintainer decision without consent;
  a consent whose decision, table result or event count (`len(refs)`) no longer matches; a `gate_open` item with
  neither `work` nor `covered_by`. `show --require accepted` exits 8 unless the item is accepted, follows the
  rules and has no `work`. With a feedback queue on the machine the filter also uses its terms, and it fails
  closed (exit 2) when the queue cannot be read. `templates/intake.json` is the empty record;
  `tests/intake_tests.sh` runs the cases and, when the repository has a record, requires exit 0 from its `check`.
- **`/delixcrew:intake` and four entry points** (K401, K405–K409, K415, K418, K419, K425; #94): where
  `docs/delix/intake.json` exists, the new skill `/delixcrew:intake [add|decide|list]` keeps the record.
  `add` writes an item with its evidence, and a new event of the same problem becomes a new ref on that item.
  `decide` shows each pending item with the table's decision and asks for `<decision> I<nnn>` in chat;
  an `accept`, a `wontfix`, a decision on a `gate_open` item and a decision other than the table's are written
  only with that consent, while a `duplicate`, `defer` or `needs-info` that the table gives needs none.
  `/delixcrew:start I<nnn>` takes only an accepted item with no `work`, shows it as `UNTRUSTED` and writes
  nothing before the user's yes in chat. Review findings a card did not fix and close drift findings become work
  only as intake items, and so does a feedback draft in the delixcrew repository; a security finding stays in an
  out-of-repo note until it is fixed. Projects without the file work as before.
- **README, README.tr and the site name the intake step** (K408, K415): the Flow and Files sections of both
  READMEs and the usage page's first job, commands and project files name `/delixcrew:intake`,
  `/delixcrew:start I<nnn>` and `docs/delix/intake.json`, which exists only where the user asked for it. The
  Feedback flow now says which finding raises a draft's count: the same kind, component and title (letter case,
  punctuation and digits aside); a different wording opens a new draft, and only in the delixcrew repository are
  the drafts of one problem joined in one intake item. The index lists the record among what the lead writes.

## 0.7.4 — 2026-11-20
```

## Global Constraints
- Spec REQ-7: "README, README.tr, dört site sayfası ve CHANGELOG'da: Flow'a intake adımı, Files'a `docs/delix/intake.json`, Feedback'teki sayaç cümlesinin düzeltmesi …: aynı tür, bileşen ve başlık sayacı artırır; farklı ifade yeni taslak açar; aynı sorunun taslakları intake öğesinde birleşir."
- K305: every new sentence describes only what the Consumed files do on main `d2528d4`.
- CLAUDE.md site rules apply:
  - no script, event handler or form;
  - every claim comes from a repo file named in its section's `Source:` / `Kaynak:` line;
  - the TR and EN twins carry the same content;
  - `<`, `>` and `&` are escaped.
- New README and CHANGELOG lines are at most 120 characters, except the two Flow rows (D2). No raw invisible character. Turkish letters, `—`, `–`, `…` and `·` stay as the files already have them.
- No version change (T068).

## Steps
1. Baseline:
   - `bash tests/site_tests.sh` gives 23 `✔`, exit 0;
   - `grep -n '^## ' CHANGELOG.md | head -1` gives `5:## 0.7.4 — 2026-11-20`;
   - `grep -cF 'A repeated finding raises the draft' README.md` gives `1`;
   - `grep -cF 'intake' site/usage.html` gives `0`.
2. Apply A1 to A27 with the Edit tool and change nothing else.
3. Run Verification and write the output to `.delix/evidence/verification.txt`.
4. Open the four pages in a browser and save one screenshot per page to `.delix/evidence/`. Check two things:
   - on both usage pages, the new commands row, the Files item and the first-job sentence read cleanly;
   - on both index pages, the Topology table's Lead row reads cleanly.
5. Commit and push:
   - Run `git add` with the 7 paths by name.
   - Commit `T067: Spec F belgesi, intake adımı, intake.json ve sayaç cümlesi`.
   - Run `git push -u origin HEAD` alone.
   - Open the PR with `--body-file`. The body has `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔`, no `✘`.
- Each `grep -cF` gives `1`:
  - **`README.md`:**
    - '| intake | `/delixcrew:intake [add\|decide\|list]` |'
    - 'and `intake.py check` fails when the decision, the table'
    - 'on request, in `.gitignore`) and `docs/delix/intake.json` (the intake items with their refs, evidence, decision,'
    - 'up from `templates/intake.json`, not by default). In the implementer worktree: `.delix/card`'
    - 'A finding with the same kind (bug or'
    - 'wording opens a new draft. Only in the delixcrew repository itself (with `docs/delix/intake.json`)'
    - 'does the lead join the drafts of one problem in one intake item, one ref per draft (`/delixcrew:intake add`).'
  - **`README.tr.md`:**
    - '| intake | `/delixcrew:intake [add\|decide\|list]` |'
    - 'tablonun sonucu ya da ref sayısı değişirse `intake.py check` hata verir.'
    - '`work` alanıyla intake öğeleri; `scripts/intake.py check` denetler;'
    - 'kurulur, varsayılan olarak yoktur). Uygulayıcı worktree'
    - 'Türü (bug ya da feature), bileşeni ve başlığı (büyük-küçük'
    - 'noktalama ve rakam farkı sayılmaz) aynı olan bulgu yeni taslak açmaz'
    - 'bir intake öğesinde birleştirir (her taslak bir ref; `/delixcrew:intake add`).'
  - **`site/index.html`:**
    - 'metrics, feedback draft, the intake record (where <code>docs/delix/intake.json</code> exists)</td>'
    - 'scripts/bash_gate.py · skills/intake/SKILL.md</p>'
  - **`site/tr/index.html`:**
    - 'metrics, feedback taslağı, intake kaydı (<code>docs/delix/intake.json</code> olan projede)</td>'
    - 'scripts/bash_gate.py · skills/intake/SKILL.md</p>'
  - **`site/usage.html`:**
    - '<code>/delixcrew:start I&lt;nnn&gt;</code> takes the request from an intake item'
    - 'verify, intake (SKILL.md) · scripts/trust.py · scripts/intake.py</p>'
    - '<tr><th><code>/delixcrew:intake</code></th>'
    - 'README.md (Triage) · skills/intake/SKILL.md · scripts/intake.py</p>'
    - '<li><code>intake.json</code>: intake items with their refs'
    - 'templates/report.md · templates/intake.json · skills/intake/SKILL.md</p>'
    - 'A finding with the same kind (bug or feature), component and title'
    - 'Only in the delixcrew repository itself (with <code>docs/delix/intake.json</code>) does the lead join'
    - 'skills/feedback/SKILL.md · scripts/feedback.py · skills/intake/SKILL.md</p>'
  - **`site/tr/usage.html`:**
    - '<code>/delixcrew:start I&lt;nnn&gt;</code> isteği bir intake öğesinden alır'
    - 'verify, intake (SKILL.md) · scripts/trust.py · scripts/intake.py</p>'
    - '<tr><th><code>/delixcrew:intake</code></th>'
    - 'README.md (Triage) · skills/intake/SKILL.md · scripts/intake.py</p>'
    - 'alanıyla intake öğeleri; yalnız ekip liderinden istediğin projede'
    - 'templates/report.md · templates/intake.json · skills/intake/SKILL.md</p>'
    - 'Türü (bug ya da feature), bileşeni ve başlığı (büyük-küçük harf'
    - 'yalnız delixcrew reposunun kendisinde (<code>docs/delix/intake.json</code> varken)'
    - 'skills/feedback/SKILL.md · scripts/feedback.py · skills/intake/SKILL.md</p>'
  - **`CHANGELOG.md`:**
    - '(K402, K414–K417, K420, K421, K425–K427, K433; #95):'
    - '(K401, K405–K409, K415, K418, K419, K425; #94):'
    - '(K408, K415):'
- Each of these gives `0`:
  - `grep -cF 'A repeated finding raises the draft' README.md`
  - `grep -cF 'Tekrarlanan bulgu yeni taslak açmaz, sayacı artırır.' README.tr.md`
  - `grep -cF 'A repeated finding raises the draft' site/usage.html`
  - `grep -cF 'Aynı bulgu tekrar ederse' site/tr/usage.html`
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## Unreleased` then `34:## 0.7.4 — 2026-11-20`.
- `grep -cF 'data-version="0.7.4"'` on each of the four pages → `2` (unchanged).
- `git diff --numstat origin/main...HEAD` → 7 paths:
  - `README.md` 9/4, `README.tr.md` 9/3, `CHANGELOG.md` 29/0;
  - `site/index.html` and `site/tr/index.html` 2/2 each;
  - `site/usage.html` and `site/tr/usage.html` 8/6 each.

  If they differ, report the actual numbers.
- `wc -l` → `README.md` 483, `README.tr.md` 486, `CHANGELOG.md` 336, both index pages 702, both usage pages 254.
- Line length: `git diff -U0 origin/main...HEAD -- README.md README.tr.md CHANGELOG.md | python3 -c "import sys; [print(len(l), l[:60]) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and not l.startswith('+|') and len(l) > 121]"` → no output.
- Invisible characters: `git diff -U0 origin/main...HEAD | python3 -c "import sys, unicodedata as u; [print(ascii(l)) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and any(u.category(c) in ('Cf', 'Zl', 'Zp') for c in l)]"` → no output.

## Review Focus
- **No claim beyond the spec or code (K305).** Check each new sentence against the Consumed lines, especially:
  - consent: only `accept`, `wontfix`, a decision other than the table's, and a `gate_open` item's decision need it (`scripts/intake.py:269`). The table's `duplicate`, `defer` and `needs-info` need none (`skills/intake/SKILL.md:53-56`).
  - start: only an accepted item with no `work` (`scripts/intake.py:373-377`).
- **K408 and K415:** the joining sentence is limited to the delixcrew repository. `intake.json` exists only where the user asked (`skills/intake/SKILL.md:10-12`); `skills/start/SKILL.md:14-18` does not create it.
- **Counter rule:** the "same kind, component and title" wording matches `scripts/feedback.py:223-227, 680-690`.
- **Parity and markup:** the TR/EN twins match, the HTML is escaped, and the `Source:` lines name the new files.
- **CHANGELOG:** the first lines are exact, because T068 anchors on them.

## Don'ts
- Do not touch `scripts/**`, `tests/**`, `hooks/**`, `docs/delix/**` (STATE.json and `intake.json` too), `plugins/**`, `.claude-plugin/**`, `skills/**`, `agents/**`, `templates/**`, any SVG, or any `data-version` mark or footer.
- Do not reword a sentence the anchors do not change. If an anchor looks wrong, stop with `NEEDS_CONTEXT`.

## Out of scope (each with the reason)
- **Index main flow:** `site/index.html:200` ("six commands, two gates"), the flow SVG (206–272), the rail (34–43), the Lead box command list (106–107) and the docs/delix box (157–161), plus TR twins. The six are the main flow's commands, and verify, status, feedback and triage are outside that count too. Intake runs only where the record exists (K415). The SVG boxes have fixed widths. The usage page and the Topology table (A7, A9) carry it.
- **`site/index.html:514` and its TR twin** ("repeat → count + 1"): this is correct, because a draft with the same fingerprint gets count + 1 (`scripts/feedback.py:684-685`). It is a diagram label, and REQ-7 names only four places.
- **`site/index.html:496` and its TR twin** (the self-feeding intro): still true in every project. The delixcrew-only intake path is in the usage Feedback step (A17, A25).
- **README "Files it writes"** (`README.md:180-183` and its TR twin): it already covers `docs/delix/` as written by the lead skills and public once committed. That includes the record.
- **Known limits line:** the lead writes `consent`, and `intake.py` cannot see the chat (spec §6). Not REQ-7; a candidate intake item.
- **Pre-existing skill wording:** `skills/intake/SKILL.md:3` (description) says the skill "records a decision only after the maintainer names it". Add step 3 (lines 53–56) lets the lead write a table-given `duplicate`, `defer` or `needs-info` with no consent (K401). This card follows the body; the lead records the description as an intake item (not this card's Files).
- **Version, footer dates and this card's PR number:** T068.

## Report contract
`.delix/report.md` holds:
- the status token;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version`;
- the screenshot paths;
- the PR number in the `**PR:**` line, and the branch;
- assumptions.

Do not write STATE.json. Read only this card and spec REQ-5, REQ-7 and §4.

## Review findings (filled by the lead)
