# T062 — Docs: Spec E close drift (README, site, implement skill) and the measured hook root (K371)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T062 | S | 2 | docs | 31 | open |

**Tier:** 2. Seven files; the text describes the limits of the write gate and the Bash hook, and one skill sentence that an implementer acts on. No file is protected and none matches `test_paths` (`docs/delix/delix.json:7-24`).

**Goal (1 sentence):** Replace the sentences that the Spec E close drift check found wrong or incomplete, and the hook-root sentences that the K371 measurement settled, with the 21 anchors below, with no version change.

**Spec:** none (size S). Sources: `STATUS.md` §15 "Açık iş (kapanış drift kontrolü, 2026-11-20 …)" and K371; `docs/delix/specs/E-gitdir-bash-outside.md` REQ-2 (text the drift is measured against), K358, K361, K364.

**Docs/site:** this card is a README/site update. The site publishes on every push to main; nothing here depends on unmerged code.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `README.md` (A1 to A4)
- Modify: `README.tr.md` (A5 to A8)
- Modify: `site/index.html` (A9)
- Modify: `site/tr/index.html` (A10)
- Modify: `site/usage.html` (A11 to A15)
- Modify: `site/tr/usage.html` (A16 to A20)
- Modify: `skills/implement/SKILL.md` (A21)
- Test: none new. `tests/site_tests.sh` already checks the pages; `tests/evidence_tests.sh` reads the implement skill.

## Interfaces
- Consumed: none (behaviour is already on main: T059 `.git` deny, the REQ-5 `cat` heredoc exemption).
- Produced: none.

## Lead decisions
- **D1 · What the anchors fix** (the drift list, item by item):
  - the `cat` heredoc sentence in README Known limits was wrong for `.git` and for a target outside the worktree: A4, A8;
  - the Bash `.git` item on both usage pages lacked the `cd` clause: A15, A20;
  - the implement skill's write-gate summary lacked `.git` and named `.git/info/exclude` (in a linked worktree `.git` is a file): A21;
  - README "into protected paths" lacked "inside the worktree": A2, A6;
  - pre-existing, fits here: "For that reason" / "To cover this gap" (qa counts a card or `docs/delix/**` change in the diff) did not say that a Bash write outside the worktree is not in the diff: A2, A6 (README), A9, A10 (index), A12, A17 (usage); each is a new sentence after a full stop, so "For that reason" keeps its scope;
  - K371 (D3): the Known limits sentence "can change at once (`--plugin-dir`) or with the next `claude plugin update` (a `directory` marketplace)": A3, A7, A14, A19; the Install text "a local change without a version bump does not reach the installed copy, `git pull` alone is not enough": A1, A5, A11, A16; the cache path named "for a marketplace install", which a `directory` marketplace also is: "GitHub marketplace install" in A3, A7, A13, A18.
- **D2 · Reflow:** each README and skill anchor replaces the quoted lines only and reflows them at 120 characters without breaking a `code span`; the lines around them do not change. The site anchors are in-line replacements.
- **D3 · K371 measurement (lead, 2026-11-20):** in a Claude Code session whose process started after the 0.7.4 update (Claude Code 2.1.328, `directory` marketplace at the checkout, `installed_plugins.json` `installPath` = the cache copy `0.7.4`), `ps` caught the Bash hook four times out of four as `python3 /Users/<user>/Documents/projects/prj_Ekip/scripts/bash_gate.py`, the checkout, not the cache. The Write hook ran too briefly to be caught; the plural "hooks" rests on `hooks/hooks.json:7,13,20`, where all three hooks run `${CLAUDE_PLUGIN_ROOT}`. The skills' base directory was the checkout too. A GitHub install was not measured; the text keeps its cache sentence for it. The new text states the measurement with its version.
- **D4 · Source lines:** no `Source:` / `Kaynak:` line changes. Usage Known limits (`site/usage.html:241`) names `README.md (Known limits, …)`, usage Install (`site/usage.html:82`) names `README.md (Installation)`, and the index note (`site/index.html:489`) names `scripts/bash_gate.py` and `README.md (Known limits, …)`.
- **D5 · No version change, no CHANGELOG:** no `data-version`, footer or `plugin.json` edit. The next release card writes the CHANGELOG entry for this text.
- **D6 · Skill sentence (K364):** the skill says Write and Edit never write the worktree's `.git` and gives the `info/exclude` command from the deny message (`scripts/write_gate.py:116-117`) as the one Bash write there, so an implementer that sees `.delix/` in `git status` neither stops with `BLOCKED` nor skips the exclude.
- **D7 · `cat` heredoc (A4, A8):** the sentence says only what the heredoc can reach. It does not describe how `bash_gate.py` checks the heredoc's target; that check is a separate lead follow-up (K374).

## Edit anchors (base main 56c4d6d)
- Line counts on the base: `README.md` 473, `README.tr.md` 476, `site/index.html` 702, `site/tr/index.html` 702, `site/usage.html` 252, `site/tr/usage.html` 252, `skills/implement/SKILL.md` 71.
- Line numbers are from the base. Edit by content: match the quoted text, and if it differs, stop with `NEEDS_CONTEXT`.
- Code blocks are not indented: copy each line as it stands, including its leading spaces (the skill lines start with three spaces).
- The lead applied A1 to A21 to a base copy with an independent applier (plain string replace, each Find exactly once; 2026-11-20) and got the "after" sha256s below (sha256 prefixes, 16 hex). On that copy `bash tests/site_tests.sh` gave 23 `✔`, every Verification `grep` gave its count in bash and zsh, and the numstat and `wc -l` values below held. Compare yours with `shasum -a 256 <file>`; if one differs, find the anchor before you go on.

| file | base | after |
|---|---|---|
| `README.md` | `ac474d1f180a45b8` | `1d0d4dc4d0293ee9` |
| `README.tr.md` | `7bca481d8012a97a` | `931ea701be9535e6` |
| `site/index.html` | `887308471ecd82c9` | `57e9ed423dd788ed` |
| `site/tr/index.html` | `82ef285ac721e6e9` | `a46fa80936fba2be` |
| `site/usage.html` | `a0b3b333985841af` | `4c0df401f155d62b` |
| `site/tr/usage.html` | `924d4aafd22a0d27` | `f0aaf2441d7a422d` |
| `skills/implement/SKILL.md` | `64b406c6d795e0e3` | `274ab16dde0120de` |

**A1 · `README.md` lines 41–46 · replace.** Current (6 lines):
```text
From a local clone: `claude plugin marketplace add /path/to/delix`, then the same `install` command. The marketplace
definition is [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Both installs copy the plugin into
Claude's plugin cache, one folder per version, so an install updates only when the version in `plugin.json` changes:
run `claude plugin marketplace update delixcrew` (GitHub; a local folder is read directly), then
`claude plugin update delixcrew@delixcrew`, and restart Claude. A local change without a version bump does not reach the
installed copy, `git pull` alone is not enough; to try one, `claude --plugin-dir /path/to/delix` reads the folder in place.
```
With (8 lines):
```text
From a local clone: `claude plugin marketplace add /path/to/delix`, then the same `install` command. The marketplace
definition is [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Both installs copy the plugin into
Claude's plugin cache, one folder per version, so an install updates only when the version in `plugin.json` changes: run
`claude plugin marketplace update delixcrew` (GitHub; a local folder is read directly), then
`claude plugin update delixcrew@delixcrew`, and restart Claude. With a GitHub install, a change without a version bump
does not reach the installed copy. A local-folder install gets that copy too, but its hooks ran from the folder itself
in a 2026-11-20 measurement (Claude Code 2.1.328, K371), so a change or a `git pull` there reaches the hooks at once. To
try a change without installing, `claude --plugin-dir /path/to/delix` reads the folder in place.
```

**A2 · `README.md` lines 394–399 · replace.** Current (6 lines):
```text
files through Bash (`echo >`, `sed -i`, `tee`) is outside this hook (`bash_gate.py` intercepts only redirects, `cp`, `mv`
and `tee` into protected paths, reviewer Bash and, in every session, the known feedback send paths and triage write
paths; see [Feedback](#feedback) and [Triage](#triage)). The write gate always rejects a path that escapes the worktree
(cwd; A13, K42); path matching is relative to cwd. For
that reason a change to the card file, `docs/delix/**` or an unapproved protected path in the card counts as a finding in
the `delixcrew:qa` review of the diff. Tier 3 permission is opened by the `**🔐 Approved:** <YYYY-MM-DD> <who>` line after
```
With (7 lines):
```text
files through Bash (`echo >`, `sed -i`, `tee`) is outside this hook (`bash_gate.py` intercepts only redirects, `cp`,
`mv` and `tee` into protected paths inside the worktree, reviewer Bash and, in every session, the known feedback send
paths and triage write paths; see [Feedback](#feedback) and [Triage](#triage)). The write gate always rejects a path
that escapes the worktree (cwd; A13, K42); path matching is relative to cwd. For that reason a change to the card file,
`docs/delix/**` or an unapproved protected path in the card counts as a finding in the `delixcrew:qa` review of the
diff. A Bash write outside the worktree, such as into the main checkout, is not in that diff (see the next paragraph).
Tier 3 permission is opened by the `**🔐 Approved:** <YYYY-MM-DD> <who>` line after
```

**A3 · `README.md` lines 408–410 · replace.** Current (3 lines):
```text
marketplace install) takes effect at once. When the plugin runs from a checkout, its hook code can change at once
(`--plugin-dir`) or with the next `claude plugin update` (a `directory` marketplace); run `git status` in that checkout
before such a session or update. The boundary here is Claude Code's Bash permission
```
With (4 lines):
```text
GitHub marketplace install) takes effect at once. When the plugin runs from a checkout (`--plugin-dir`, or a `directory`
marketplace, where the hooks run from that folder and not from the cached copy that `installed_plugins.json` names;
measured with Claude Code 2.1.328, K371), a change to its hook code takes effect at once; run `git status` in that
checkout before such a session. The boundary here is Claude Code's Bash permission
```

**A4 · `README.md` lines 444–447 · replace.** Current (4 lines):
```text
outside quotes, or a `{` or `}` word after a command's name (T052; run the other command in a separate call). The one
allowed `cat` heredoc
writes nothing the Write tool could not already write. With git older than 2.44, a missing object in a promisor
(partial clone) repository can still be fetched from its remote while the hooks read the index (K225).
```
With (5 lines):
```text
outside quotes, or a `{` or `}` word after a command's name (T052; run the other command in a separate call). The one
allowed `cat` heredoc can write what the Write tool denies: like any other Bash write, it can reach the worktree's
`.git` and a target outside the worktree (T059, A13; see the Bash write rule above). With git older than 2.44, a missing
object in a promisor (partial clone) repository can still be fetched from its remote while the hooks read the index
(K225).
```

**A5 · `README.tr.md` lines 40–45 · replace.** Current (6 lines):
```text
Yerel klondan: `claude plugin marketplace add /path/to/delix`, sonra aynı `install` komutu. Marketplace tanımı
[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). İki kurulum da plugin'i Claude'un plugin
cache'ine sürüm başına bir klasör olarak kopyalar; kurulum yalnız `plugin.json` sürümü değişince güncellenir:
`claude plugin marketplace update delixcrew` (GitHub; yerel klasör doğrudan okunur), sonra
`claude plugin update delixcrew@delixcrew`, ardından Claude'u yeniden başlat. Sürüm artmadan yapılan yerel değişiklik
kurulu kopyaya ulaşmaz, `git pull` tek başına yetmez; denemek için `claude --plugin-dir /path/to/delix` klasörü yerinde okur.
```
With (8 lines):
```text
Yerel klondan: `claude plugin marketplace add /path/to/delix`, sonra aynı `install` komutu. Marketplace tanımı
[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). İki kurulum da plugin'i Claude'un plugin cache'ine
sürüm başına bir klasör olarak kopyalar; kurulum yalnız `plugin.json` sürümü değişince güncellenir:
`claude plugin marketplace update delixcrew` (GitHub; yerel klasör doğrudan okunur), sonra
`claude plugin update delixcrew@delixcrew`, ardından Claude'u yeniden başlat. GitHub kurulumunda sürüm artmadan yapılan
değişiklik kurulu kopyaya ulaşmaz. Yerel klasör kurulumu da bu kopyayı alır, ama 2026-11-20 ölçümünde (Claude Code
2.1.328, K371) hook'ları klasörün kendisinden çalıştı; oradaki bir değişiklik ya da `git pull` hook'lara hemen ulaşır.
Kurmadan denemek için `claude --plugin-dir /path/to/delix` klasörü yerinde okur.
```

**A6 · `README.tr.md` lines 395–400 · replace.** Current (6 lines):
```text
ile dosya yazması (`echo >`, `sed -i`, `tee`) bu hook'un kapsamı dışıdır (`bash_gate.py` yalnız korunan yollara
yönlendirme, `cp`, `mv` ve `tee`'yi, inceleyici Bash'ini ve her oturumda bilinen geri bildirim gönderme yollarını ve triage yazma
yollarını keser; bkz. [Geri bildirim](#geri-bildirim) ve [Triage](#triage)). Yazma kapısı worktree (cwd) dışına çıkan
yolu her zaman reddeder (A13, K42); yol eşleşmeleri cwd'ye
göredir. Bu yüzden kart dosyası, `docs/delix/**` ya da kartta onaysız korunan yol değişikliği `delixcrew:qa` incelemesinde
diff'ten bulgu sayılır. Tier 3 izni kartın başlık tablosundan sonraki `**🔐 Approved:** <YYYY-MM-DD> <kim>` satırıyla
```
With (7 lines):
```text
ile dosya yazması (`echo >`, `sed -i`, `tee`) bu hook'un kapsamı dışıdır (`bash_gate.py` yalnız worktree içindeki
korunan yollara yönlendirme, `cp`, `mv` ve `tee`'yi, inceleyici Bash'ini ve her oturumda bilinen geri bildirim gönderme
yollarını ve triage yazma yollarını keser; bkz. [Geri bildirim](#geri-bildirim) ve [Triage](#triage)). Yazma kapısı
worktree (cwd) dışına çıkan yolu her zaman reddeder (A13, K42); yol eşleşmeleri cwd'ye göredir. Bu yüzden kart dosyası,
`docs/delix/**` ya da kartta onaysız korunan yol değişikliği `delixcrew:qa` incelemesinde diff'ten bulgu sayılır.
Worktree dışına, örneğin ana checkout'a Bash ile yapılan bir yazım o diff'te görünmez (bkz. sonraki paragraf). Tier 3
izni kartın başlık tablosundan sonraki `**🔐 Approved:** <YYYY-MM-DD> <kim>` satırıyla
```

**A7 · `README.tr.md` lines 408–410 · replace.** Current (3 lines):
```text
(marketplace kurulumunda `~/.claude/plugins/cache/delixcrew/delixcrew/<version>/`) yapılan yazım hemen geçerli olur.
Plugin bir checkout'tan çalışıyorsa hook kodu hemen (`--plugin-dir`) ya da sonraki `claude plugin update` ile
(`directory` marketplace) değişebilir; böyle bir oturumdan ya da güncellemeden önce o checkout'ta `git status` çalıştır.
```
With (4 lines):
```text
(GitHub marketplace kurulumunda `~/.claude/plugins/cache/delixcrew/delixcrew/<version>/`) yapılan yazım hemen geçerli
olur. Plugin bir checkout'tan çalışıyorsa (`--plugin-dir` ya da `directory` marketplace; ikincisinde hook'lar
`installed_plugins.json`'un gösterdiği önbellek kopyasından değil o klasörden çalışır, Claude Code 2.1.328 ile ölçüldü,
K371) hook koduna yapılan değişiklik hemen geçerli olur; böyle bir oturumdan önce o checkout'ta `git status` çalıştır.
```

**A8 · `README.tr.md` lines 447–449 · replace.** Current (3 lines):
```text
İzin verilen tek `cat` heredoc'u,
Write aracının zaten yazamayacağı hiçbir şeyi yazmaz. 2.44'ten eski git ile promisor (kısmi klon) bir repoda eksik bir
nesne, hook'lar index'i okurken uzak depodan yine çekilebilir (K225).
```
With (3 lines):
```text
İzin verilen tek `cat` heredoc'u Write aracının reddettiğini yazabilir: öteki Bash yazımları gibi worktree'nin
`.git`'ine ve worktree dışındaki bir hedefe ulaşabilir (T059, A13; bkz. yukarıdaki Bash yazma kuralı). 2.44'ten eski git
ile promisor (kısmi klon) bir repoda eksik bir nesne, hook'lar index'i okurken uzak depodan yine çekilebilir (K225).
```

**A9 · `site/index.html` line 446 · replace in the line.** Find:
```text
to <code>docs/delix/**</code> in the diff as a finding.</li>
```
Replace with:
```text
to <code>docs/delix/**</code> in the diff as a finding. A Bash write outside the worktree, such as into the main checkout, is not in that diff.</li>
```

**A10 · `site/tr/index.html` line 446 · replace in the line.** Find:
```text
değişikliği görürse bunu bulgu sayar.</li>
```
Replace with:
```text
değişikliği görürse bunu bulgu sayar. Worktree dışına, örneğin ana checkout'a Bash ile yapılan bir yazım o diff'te görünmez.</li>
```

**A11 · `site/usage.html` line 74 · replace in the line.** Find:
```text
changes; <code>git pull</code> alone is not enough.</p>
```
Replace with:
```text
changes. A local-folder install gets that copy too, but its hooks ran from the folder itself in a measurement with Claude Code 2.1.328, so a change or a <code>git pull</code> there reaches the hooks at once.</p>
```

**A12 · `site/usage.html` line 222 · replace in the line.** Find:
```text
in the diff counts as a finding in the qa review.</li>
```
Replace with:
```text
in the diff counts as a finding in the qa review. A Bash write outside the worktree is not in that diff (next item).</li>
```

**A13 · `site/usage.html` line 223 · replace in the line.** Find:
```text
&lt;version&gt;/</code> for a marketplace install) takes effect at once.
```
Replace with:
```text
&lt;version&gt;/</code> for a GitHub marketplace install) takes effect at once.
```

**A14 · `site/usage.html` line 223 · replace in the line.** Find:
```text
When the plugin runs from a checkout, its hook code can change at once (<code>--plugin-dir</code>) or with the next <code>claude plugin update</code> (a <code>directory</code> marketplace); run
```
Replace with:
```text
When the plugin runs from a checkout (<code>--plugin-dir</code>, or a <code>directory</code> marketplace, where the hooks run from that folder and not from the cached copy that <code>installed_plugins.json</code> names; measured with Claude Code 2.1.328), a change to its hook code takes effect at once; run
```

**A15 · `site/usage.html` line 223 · replace in the line.** Find:
```text
switches the three hooks off, the same as deleting <code>.delix/card</code>.</li>
```
Replace with:
```text
switches the three hooks off, the same class as deleting <code>.delix/card</code> or running <code>cd</code> below the worktree root (see the push rule below).</li>
```

**A16 · `site/tr/usage.html` line 74 · replace in the line.** Find:
```text
sürüm değişince gelir; tek başına <code>git pull</code> yetmez.</p>
```
Replace with:
```text
sürüm değişince gelir. Yerel klasör kurulumu da bu kopyayı alır, ama Claude Code 2.1.328 ile yapılan bir ölçümde hook'ları klasörün kendisinden çalıştı; oradaki bir değişiklik ya da <code>git pull</code> hook'lara hemen ulaşır.</p>
```

**A17 · `site/tr/usage.html` line 222 · replace in the line.** Find:
```text
qa incelemesinde bulgu sayılır.</li>
```
Replace with:
```text
qa incelemesinde bulgu sayılır. Worktree dışına Bash ile yapılan bir yazım o diff'te görünmez (sonraki madde).</li>
```

**A18 · `site/tr/usage.html` line 223 · replace in the line.** Find:
```text
(marketplace kurulumunda <code>~/.claude
```
Replace with:
```text
(GitHub marketplace kurulumunda <code>~/.claude
```

**A19 · `site/tr/usage.html` line 223 · replace in the line.** Find:
```text
Plugin bir checkout'tan çalışıyorsa hook kodu hemen (<code>--plugin-dir</code>) ya da sonraki <code>claude plugin update</code> ile (<code>directory</code> marketplace) değişebilir;
```
Replace with:
```text
Plugin bir checkout'tan çalışıyorsa (<code>--plugin-dir</code> ya da <code>directory</code> marketplace; ikincisinde hook'lar <code>installed_plugins.json</code>'un gösterdiği önbellek kopyasından değil o klasörden çalışır, Claude Code 2.1.328 ile ölçüldü) hook koduna yapılan değişiklik hemen geçerli olur;
```

**A20 · `site/tr/usage.html` line 223 · replace in the line.** Find:
```text
üç hook'u kapatır; bu, <code>.delix/card</code>'ı silmekle aynıdır.</li>
```
Replace with:
```text
üç hook'u kapatır; bu, <code>.delix/card</code>'ı silmekle ya da worktree kökünün altına <code>cd</code> yapmakla aynı sınıftır (bkz. aşağıdaki push kuralı).</li>
```

**A21 · `skills/implement/SKILL.md` lines 15–18 · replace.** Current (4 lines):
```text
   list; a protected path is written only if it is in Files **and** the card carries a `🔐 Approved` line; the card file
   and `docs/delix/**` are never changed (not via Bash either; the review counts it as a finding). If you get a
   rejection, do not route around it; write `BLOCKED`/`NEEDS_CONTEXT`. `.delix/` is kept out of git
   (`.git/info/exclude`).
```
With (6 lines):
```text
   list; a protected path is written only if it is in Files **and** the card carries a `🔐 Approved` line; the card file
   and `docs/delix/**` are never changed (not via Bash either; the review counts it as a finding). The worktree's own
   `.git` is never written with Write or Edit (the hooks find the card through it; T059). If you get a rejection, do not
   route around it; write `BLOCKED`/`NEEDS_CONTEXT`. `.delix/` is kept out of git through `info/exclude`; if
   `git status` shows it, run `echo .delix/ >> "$(git rev-parse --git-path info/exclude)"`, the one Bash write into
   `.git` (the `.git` deny message gives the same command; running it is not routing around the gate).
```

## Global Constraints
- CLAUDE.md site rules apply: no script, event handler or form; every claim comes from a repo file; the TR and EN twins carry the same content; a backticked word is `<code>`, and `<`, `>` and `&` are escaped.
- New README and skill lines are at most 120 characters. No raw invisible character. Turkish letters, `—`, `…` and `🔐` stay as the files already have them.
- No version change.

## Steps
1. Baseline: `bash tests/site_tests.sh` gives 23 `✔`; `grep -cF 'writes nothing the Write tool could not already write' README.md` gives `1`; ``grep -cF -- '(`.git/info/exclude`)' skills/implement/SKILL.md`` gives `1`.
2. Apply A1 to A21 with the Edit tool and change nothing else. A13, A14 and A15 are in the same line (223) of `site/usage.html`, A18, A19 and A20 in the same line of `site/tr/usage.html`: apply them in order.
3. Compare the seven sha256 prefixes with the table. Run Verification and write the output to `.delix/evidence/verification.txt`.
4. Open `site/usage.html` and `site/tr/usage.html` in a browser and save two screenshots of each to `.delix/evidence/`: the install note and the Known limits list.
5. Commit and push:
   - Run `git add` with the 7 paths by name.
   - Commit `T062: Spec E kapanış drift'i ve ölçülen hook kökü (K371)`.
   - Run `git push -u origin HEAD` alone.
   - Open the PR with `--body-file`. The body has `## How I tested`.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔`, no `✘`.
- `shasum -a 256` of the seven files → the "after" prefixes in the table.
- Each line below prints the count after `→`:
```text
grep -cF -- 'With a GitHub install, a change' README.md  → 1
grep -cF -- 'its hooks ran from the folder itself' README.md  → 1
grep -cF -- 'into protected paths inside the worktree, reviewer Bash' README.md  → 1
grep -cF -- 'is not in that diff (see the next paragraph).' README.md  → 1
grep -cF -- 'GitHub marketplace install) takes effect at once.' README.md  → 1
grep -cF -- 'where the hooks run from that folder and not from the cached copy' README.md  → 1
grep -cF -- 'measured with Claude Code 2.1.328, K371), a change to its hook code takes effect at once' README.md  → 1
grep -cF -- 'allowed `cat` heredoc can write what the Write tool denies: like any other Bash write' README.md  → 1
grep -cF -- 'writes nothing the Write tool could not already write' README.md  → 0
grep -cF -- 'or with the next `claude plugin update`' README.md  → 0
grep -cF -- '`git pull` alone is not enough' README.md  → 0
grep -cF -- 'GitHub kurulumunda' README.tr.md  → 1
grep -cF -- 'klasörün kendisinden çalıştı' README.tr.md  → 1
grep -cF -- '(`bash_gate.py` yalnız worktree içindeki' README.tr.md  → 1
grep -cF -- 'görünmez (bkz. sonraki paragraf).' README.tr.md  → 1
grep -cF -- '(GitHub marketplace kurulumunda' README.tr.md  → 1
grep -cF -- 'Claude Code 2.1.328 ile' README.tr.md  → 1
grep -cF -- 'Write aracının reddettiğini yazabilir: öteki Bash yazımları gibi' README.tr.md  → 1
grep -cF -- 'zaten yazamayacağı hiçbir şeyi yazmaz' README.tr.md  → 0
grep -cF -- 'ya da sonraki `claude plugin update` ile' README.tr.md  → 0
grep -cF -- '`git pull` tek başına yetmez' README.tr.md  → 0
grep -cF -- 'such as into the main checkout, is not in that diff.</li>' site/index.html  → 1
grep -cF -- 'Bash ile yapılan bir yazım o diff' site/tr/index.html  → 1
grep -cF -- 'but its hooks ran from the folder itself in a measurement with Claude Code 2.1.328' site/usage.html  → 1
grep -cF -- 'is not in that diff (next item).</li>' site/usage.html  → 1
grep -cF -- 'for a GitHub marketplace install) takes effect at once.' site/usage.html  → 1
grep -cF -- 'measured with Claude Code 2.1.328), a change to its hook code takes effect at once' site/usage.html  → 1
grep -cF -- 'the same class as deleting <code>.delix/card</code> or running <code>cd</code>' site/usage.html  → 1
grep -cF -- 'alone is not enough.</p>' site/usage.html  → 0
grep -cF -- 'or with the next <code>claude plugin update</code>' site/usage.html  → 0
grep -cF -- 'ile yapılan bir ölçümde' site/tr/usage.html  → 1
grep -cF -- 'görünmez (sonraki madde).</li>' site/tr/usage.html  → 1
grep -cF -- '(GitHub marketplace kurulumunda <code>' site/tr/usage.html  → 1
grep -cF -- 'ölçüldü) hook koduna yapılan değişiklik hemen geçerli olur;' site/tr/usage.html  → 1
grep -cF -- 'yapmakla aynı sınıftır (bkz. aşağıdaki push kuralı).</li>' site/tr/usage.html  → 1
grep -cF -- 'tek başına <code>git pull</code> yetmez' site/tr/usage.html  → 0
grep -cF -- 'ya da sonraki <code>claude plugin update</code> ile' site/tr/usage.html  → 0
grep -cF -- 'is never written with Write or Edit (the hooks find the card' skills/implement/SKILL.md  → 1
grep -cF -- 'rev-parse --git-path info/exclude' skills/implement/SKILL.md  → 1
grep -cF -- 'running it is not routing around the' skills/implement/SKILL.md  → 1
grep -cF -- '(`.git/info/exclude`)' skills/implement/SKILL.md  → 0
```
- `grep -cF 'data-version="0.7.4"'` on each of the four pages → `2` (unchanged).
- `git diff --numstat origin/main...HEAD` → 7 paths: `README.md` 21/16, `README.tr.md` 20/16, `site/index.html` 1/1, `site/tr/index.html` 1/1, `site/usage.html` 3/3, `site/tr/usage.html` 3/3, `skills/implement/SKILL.md` 5/3. If they differ, report the actual numbers.
- `wc -l` → `README.md` 478, `README.tr.md` 480, `site/index.html` 702, `site/tr/index.html` 702, `site/usage.html` 252, `site/tr/usage.html` 252, `skills/implement/SKILL.md` 73.
- Line length and invisible characters on the added lines (no output):
```text
git diff -U0 origin/main...HEAD -- README.md README.tr.md skills/implement/SKILL.md | python3 -c "import sys,unicodedata as u; [print(l.rstrip()) for l in sys.stdin if l.startswith('+') and not l.startswith('+++') and (len(l.rstrip(chr(10)))>121 or any(u.category(c)=='Cf' for c in l))]"
```

## Review Focus
- **Claims against code:** A4 and A8 against `scripts/bash_gate.py:33-47` (CAT_HEREDOC) and `scripts/write_gate.py` (the `.git` deny, the outside-worktree deny A13); A21 against `scripts/write_gate.py:113-117` (the `.git` deny and its `info/exclude` command); A15 and A20 against `scripts/common.py:119-130` (`card_path` needs cwd to be the toplevel).
- **K371 wording:** A1, A3, A5, A7, A11, A14, A16 and A19 say what D3 measured and no more (one setup, one Claude Code version, a GitHub install not measured).
- **Parity and markup:** TR/EN twins match, the HTML is escaped, "For that reason" / "Bu yüzden" keep their referent, and "see the next paragraph" points at the Bash write rule paragraph.

## Don'ts
- Do not touch `scripts/**`, `tests/**`, `hooks/**`, `docs/delix/**` (STATE.json too), `plugins/**`, `.claude-plugin/**`, `agents/**`, `templates/**`, `CHANGELOG.md`, any skill other than `skills/implement/SKILL.md`, or any `data-version` mark or footer.
- Do not reword a sentence the anchors do not change. If an anchor looks wrong, stop with `NEEDS_CONTEXT`.

## Out of scope (each with the reason)
- Spec E REQ-2 says a `directory` marketplace's hook code changes with the next `claude plugin update` (`docs/delix/specs/E-gitdir-bash-outside.md:72-73`), which K371 measured otherwise, and the CHANGELOG REQ-2 item that REQ-3 does not describe (K362): the spec is a closed gate-1 record; STATUS §15 records both (lead, K372).
- The `bash_gate.py` protected-path redirect check and the forms it does not see: code in a protected path (Tier 3); a separate lead follow-up (K374).
- The gitleaks `^evals/` allowlist path that does not match the absolute `--no-git` path: `.gitleaks.toml` is a protected path (Tier 3); it would grow this card (lead follow-up).
- CHANGELOG lines over 120 characters (7 lines in old sections): no CHANGELOG change here (D5); the next release card, which edits CHANGELOG anyway, can rewrap them.
- The impeccable design-hook flags on the four pages (`tiny-text`, `border-accent-on-rounded`, `cramped-padding`): CSS and design work, another discipline (lead follow-up).
- The `feedback.py` path "for a marketplace install" (`README.md:210`, `site/usage.html:183` and twins): the cache copy exists in both installs and runs, so the command works as written.
- "intercepts only … into protected paths inside the worktree" (A2, A6) keeps its scope; a pattern without a folder also matches outside the worktree, which the next paragraph already says.

## Report contract
`.delix/report.md` holds:
- the status token;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version`;
- the screenshot paths;
- the PR number in the `**PR:**` line, and the branch;
- assumptions.

Do not write STATE.json. Read only this card and, if you need it, spec REQ-2, K358, K361, K364.

## Review findings (filled by the lead)
