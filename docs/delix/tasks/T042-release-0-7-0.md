# T042 🔐 — Release 0.7.0: version, CHANGELOG, Spec C docs handover, site version marks and labels

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T042 | S | 3 | docs | 21 | open |

**🔐 Approved:** 2026-11-17 tahircengiz

> 🔐 Tier 3: `.claude-plugin/plugin.json` is protected (`.claude-plugin/**` in `docs/delix/delix.json`). The lead adds the Approved line after the user's item-specific "yes" in chat and commits it to main before dispatch.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-17 ("Evet, T042 onaylı", said in the lead session; K322).
> - Order (K309, K316, K319, the user): T046, T049, T050, then this card. T043 to T050 are merged on main (`279a8c9`).
> - It ships what `CHANGELOG.md` `## Unreleased` holds and Spec C waves 13 to 20 (#72 to #79), with the README and site sentences that T044 and T047 to T050 left to the release (K298, K316): T049's Docs handover. T050 adds no sentence (T050 D4, K320).
> - Claims (K305): the release claims no full assurance for the push rule. The CHANGELOG items name what the hook denies; the README's Known limits keep what it cannot see.
> - Publication (K313): README, README.tr, the site and the CHANGELOG name no form that passed main before T049 and T050.

**Goal (1 sentence):** Ship Spec C (T043 to T050, #72 to #79) and what `## Unreleased` already holds as **0.7.0**, so that the plugin version, the CHANGELOG heading and its six new items, T049's Docs handover in README, README.tr and the site, and the version marks, footer dates and release labels of the four site pages all name 0.7.0. · **Spec:** `docs/delix/specs/C-board-visibility.md` K309, K313 (T042 notu), K315, K316, K319, K320; the CLAUDE.md "Site (GitHub Pages)" rule covers a version change. The 0.6.3 release (T033, PR #61) is the pattern.

**Docs/site:** this card is the site update the CLAUDE.md version rule asks for, and the README / README.tr / site update of T049's `## Docs handover` (K316).

## Files (base origin/main 279a8c9; the README and site files are unchanged since e2864f6 (#77), `CHANGELOG.md` since 1da4990, `plugin.json` since 9f3c7fb (#61))
- Modify: `.claude-plugin/plugin.json` (A1, line 4)
- Modify: `CHANGELOG.md` (A2 to A4: lines 5, 8, insertion after line 25)
- Modify: `README.md` (A5 to A8: lines 127, 139, 398–399, 404)
- Modify: `README.tr.md` (A9 to A12: lines 127, 139, 399–400, 405)
- Modify: `site/index.html` (A13 to A17: lines 29, 475, 695)
- Modify: `site/tr/index.html` (A18 to A22: lines 29, 475, 695)
- Modify: `site/usage.html` (A23 to A31: lines 29, 98, 124, 225, 226, 244)
- Modify: `site/tr/usage.html` (A32 to A40: lines 29, 98, 124, 225, 226, 244)
- Test: none new. `tests/site_tests.sh` already fails when a page's version differs from `plugin.json`.

## Interfaces
- Consumed: `tests/site_tests.sh` version check (every `data-version` mark equals `plugin.json` `version`).
- Produced: version string `0.7.0`, which the user's tag `v0.7.0` names after the merge. delix-board stays 0.1.6 (T046, #77).

## Card writer's decisions (the lead confirms them at dispatch)
- **D1, CHANGELOG item for #74:** its title reads "An implementer session is denied `git update-ref` and `git remote` writes" instead of "cannot run". A repo file does not support "cannot run": the usage page's Known limits say the ref-write rule does not see a command that a script or another program runs, and K313's T042 note asks the item to name the denied forms, not to say that they never run. Every other word of the six items is the lead's.
- **D2, TR false-positive clause:** the list it joins is in the accusative (`…biçimini`, `…tırnağı`, `…push'u reddeder`), so the handover's `çağrısı` is written `çağrısını` (D9's text keeps it).
- **D3, the four Known limits:** H3 and the false-positive clause go into README, README.tr and the Known limits item of both usage pages. These four files carry the F5 item (K313) that K315 widens.
- **D4, no own item for T046 (#77):** it changed docs, the site and the pane version, not behaviour. The pane version is in the first item (0.1.6). The behaviour it documents is in the items for #72 to #79.
- **D5, footer date:** the footer date is the release date, the same as the CHANGELOG heading. The 0.6.2 release (commit `03b41a2`) moved it to its own day; T033 kept `2026-11-04` because 0.6.3 shipped that day.
- **D6, Source lines:** none changes. No `Source:` / `Kaynak:` line cites `CHANGELOG (Unreleased)` on the base (T032 fixed line 489). `CHANGELOG 0.6.3` on line 489 still names the release of the trust anchor. The new sentences rest on README.md and `scripts/bash_gate.py`, which those lines already cite.
- **D7, no Stop gate step after the update:** `scripts/trust.py`, `scripts/stop_gate.py`, `scripts/common.py`, `hooks/hooks.json`, `docs/delix/delix.json` and `templates/delix.json` are unchanged since `v0.6.3`, and no CHANGELOG item or README sentence names a migration for 0.7.0.
- **D8, the item for #78 and #79** keeps the lead's "also through the dashed name" without "(T050)": the items name PRs and K numbers, not cards, and #79 and K320 are in its head.
- **D9, the false-positive clause names the keys (lead):** in the four Known limits items the lead replaced the handover's "one of these keys" / "bu anahtarlardan birini" with the key list `alias.`, `remote.`, `push.`, `url.`, `include`, `help.`. The handover's antecedent (H1's key list) is not in that paragraph; the nearest keys there are only `origin`'s URL keys, and R-C1's false positive applies to every R-P5 key.

## Edit anchors (base main 279a8c9, full SHA 279a8c99b4f82c6625d79ecfadf849907a459b20)
Line numbers are from that commit. Each file lists its line count and sha256 on the base and after the card. Match the quoted content before you edit; if it differs, stop with `NEEDS_CONTEXT`. Apply every anchor with the Edit tool; `plugin.json` must use it, because the hook denies shell writes to protected paths.
- **replace in the line:** the "Find" text occurs exactly once in its file. It is the Edit tool's `old_string`, and "Replace with" is its `new_string`.
- **replace:** the "Current" lines occur once in the file. They are `old_string`, and the new lines are `new_string`.
- **insert after:** `old_string` is the quoted line; `new_string` is that line, a newline, then the block.
- The code blocks are not indented: copy each line as it is. README lines keep their two leading spaces, and nothing else has leading or trailing blanks.
- Applied to the base in any order, the anchors give the card writer's prototype byte for byte. A script read this card, applied the blocks two ways (the Edit tool's string order and line numbers bottom-up) and got every "after" sha256 below.

### `.claude-plugin/plugin.json`
Base: 19 lines, sha256 `0a795de0dad4191cbe70c5369a68906317d57cb8c67784c86e298d87225a56d8`. After the card: 19 lines, sha256 `ef1ff407c0c8d21a088d2e4d3b9fd16e9f3bd58c64e2400806a941486a74bc42`.

**A1 · line 4 · replace in the line · the version value.** Find (once in the file):
```text
"version": "0.6.3"
```
Replace with:
```text
"version": "0.7.0"
```

### `CHANGELOG.md`
Base: 214 lines, sha256 `8a6623300d3df19f21743ce0809916acf2d7bc56f65ea0177c32b074a10f2359`. After the card: 243 lines, sha256 `738c2bd3a08db273cfc70d9e0648453148dd3a902d72a17ad8e87f282eaf8641`.

**A2 · line 5 · replace in the line · the release heading.** Find (once in the file):
```text
## Unreleased
```
Replace with:
```text
## 0.7.0 — 2026-11-17
```

**A3 · line 8 · replace in the line · the pane version (T046).** Find (once in the file):
```text
delix-board pane (0.1.5)
```
Replace with:
```text
delix-board pane (0.1.6)
```

**A4 · line 25 · insert after · the six new items.** Line 25 is:
```text
  `help.autocorrect` is on. The README's Known limits name what the hook cannot see.
```
Insert these 29 lines after it (line 26, blank, stays below them):
```text
- **The board names who opened each card and its last review round** (K290, K291, K293, K294; #73): Agents, Waiting on
  you and Ready to merge carry who opened each card and its last review round on both surfaces; the pane shows them in a
  dimmed second line, and Leads shows when each lead's STATE last changed. The `status`, `diff` and `log` calls carry
  `--no-lazy-fetch` like the STATE read, so a partial clone fetches no missing object; git older than 2.44 rejects the
  flag, so those fields show `?` and nothing shows as ready to merge. Both surfaces read `default_branch` and
  `.delix/card` by one rule.
- **An implementer session is denied `git update-ref` and `git remote` writes** (🔐 K296, K312, K313; #74): in an
  implementer worktree the Bash hook denies `git update-ref` and every `git remote` form except plain `git remote`, `-v`
  / `--verbose`, `show` and `get-url`, also through an alias or the dashed name. A `docs/delix/delix.json` that is not a
  JSON object, or a byte that is not UTF-8 in a git setting the rule reads, denies with a message instead of failing.
- **An unreviewed merged head escalates** (K297; #72): after your merge the lead writes `accepted` only when the merged
  head is the commit the last qa round reviewed; otherwise it still records `merged`, sets `escalated` and tells you "an
  unreviewed head was merged".
- **The Bash hook reads a command the way bash builds its argv** (🔐 K300–K305; #75): the push, ref and remote rules read
  a command both by the loose word scan and as bash's argv, so a quoted blank, an option value with a comma or a
  bracket, a backslash-newline, a redirection and the text of an `sh -c` string no longer hide the subcommand. An alias
  that starts with a global option is followed to its command, and a quote never closed in front of a `git` word denies
  with a message.
- **The Bash hook reads a command in one pass the way bash does** (🔐 K306–K310; #76): the bash view follows command
  substitutions in double quotes, in heredoc bodies and glued to a word, takes a `#` as a comment only at the start of a
  word, ends a heredoc body at its delimiter, reads brace groups as bash does, and reads `$'…'` to its end without
  decoding escapes such as `\x67` (K312); an alias value is split the way git splits it. A command nested too deep for
  the hook to read denies with a message. Variables, `eval`, globs, ANSI-C escapes, command output that spells a word
  and brace expansion stay out of its reach (Known limits).
- **A `git config` read counts only where git reads one** (🔐 K317, K320; #78, #79): in an implementer worktree a
  `git config` call that names an `alias.`, `remote.`, `push.`, `url.`, `include` or `help.` key is denied unless git
  reads it as a read (`get` or `list` as its first argument, or a read option such as `--get` before the key), also
  through the dashed name; a word after the key and a comment do not count. A command that holds a `#`, a `(` or a
  backtick is read by the bash view as well.
```

### `README.md`
Base: 432 lines, sha256 `df5262fb2d7237c779963b0259cbe36bd8e66010c19d2f29e2cfcb92d27eb1c2`. After the card: 438 lines, sha256 `724e28410f13acc9713992fe1ce689e0d450319321cbb235a2e935123e813019`.

**A5 · line 127 · replace · H1, the R-P5 sentence (T049 Docs handover).** Current:
```text
  does not list while `help.autocorrect` is on. `gh pr merge` is denied there: gate 2 is the user's (T041, K279). It
```
Replace with these 4 lines:
```text
  does not list while `help.autocorrect` is on. A `git config` call that names an `alias.`, `remote.`, `push.`, `url.`,
  `include` or `help.` key is denied there unless git reads it as a read: `get` or `list` as its first argument, or a
  read option such as `--get` among the options before the key; a word after the key and a comment do not count (T049).
  `gh pr merge` is denied there: gate 2 is the user's (T041, K279). It
```

**A6 · line 139 · replace · H2, the bash view sentence (T049 Docs handover).** Current:
```text
  the hook to read is denied with a message (T048).
```
Replace with these 2 lines:
```text
  the hook to read is denied with a message (T048). A command that holds a `#`, a `(` or a backtick is read by the bash
  view as well (T049).
```

**A7 · lines 398–399 · replace · H3, the `origin` URL item (K315).** Current:
```text
a URL for `origin` (`url`, `pushurl` or `url.*.insteadOf`)
written into the git config file in the same or an earlier call (the own-branch push then
```
Replace with these 2 lines:
```text
a URL for `origin` (`url`, `pushurl`, `url.*.insteadOf` or `url.*.pushInsteadOf`) written into a git config file (the
repository's, the global one or an included one) in the same or an earlier call (the own-branch push then
```

**A8 · line 404 · replace · the false-positive clause (T049 Docs handover).** Current:
```text
to refresh refs), a quote that is never closed in front of a `git` word, also in a heredoc body (close the quote or put
```
Replace with these 3 lines:
```text
to refresh refs), a `git config` read of an `alias.`, `remote.`, `push.`, `url.`, `include` or `help.` key with another
option before the read option (use `--file=<file>` or `git remote get-url origin`), a quote that is never closed in
front of a `git` word, also in a heredoc body (close the quote or put
```

### `README.tr.md`
Base: 434 lines, sha256 `6ec6eb249d6e76b98ba698418dd3a7e467929b8ee2b93462e391515ade9e4463`. After the card: 441 lines, sha256 `c473b422199fdfb94b4c9af446210e10832da8d44c4bbe46f1f56ad8b2eb19ce`.

**A9 · line 127 · replace · H1, the R-P5 sentence (T049 Docs handover).** Current:
```text
  listelemediği bir komut adı da orada reddedilir. `gh pr merge` orada reddedilir: kapı 2 kullanıcınındır (T041, K279).
```
Replace with these 4 lines:
```text
  listelemediği bir komut adı da orada reddedilir. Orada `alias.`, `remote.`, `push.`, `url.`, `include` ya da `help.`
  anahtarını anan bir `git config` çağrısı, git onu okuma olarak okumuyorsa reddedilir: ilk argümanı `get` ya da `list`
  olmalı ya da anahtardan önceki seçeneklerde `--get` gibi bir okuma seçeneği bulunmalı; anahtardan sonraki kelime ve
  yorum sayılmaz (T049). `gh pr merge` orada reddedilir: kapı 2 kullanıcınındır (T041, K279).
```

**A10 · line 139 · replace · H2, the bash view sentence (T049 Docs handover).** Current:
```text
  kadar derin iç içe bir komut mesajla reddedilir (T048).
```
Replace with these 2 lines:
```text
  kadar derin iç içe bir komut mesajla reddedilir (T048). İçinde `#`, `(` ya da ters tırnak geçen bir komutu bash
  görünümü de okur (T049).
```

**A11 · lines 399–400 · replace · H3, the `origin` URL item (K315).** Current:
```text
(`gh pr checkout` gibi), `pr merge` için bir `gh` alias'ı, aynı ya da önceki bir çağrıda
git ayar dosyasına yazılan bir `origin` URL'si (`url`, `pushurl` ya da `url.*.insteadOf`; kendi dalının push'u o adrese
```
Replace with these 3 lines:
```text
(`gh pr checkout` gibi), `pr merge` için bir `gh` alias'ı, aynı ya da önceki bir çağrıda bir git ayar dosyasına
(reponun, global ya da include edilen) yazılan bir `origin` URL'si (`url`, `pushurl`, `url.*.insteadOf` ya da
`url.*.pushInsteadOf`; kendi dalının push'u o adrese
```

**A12 · line 405 · replace · the false-positive clause (T049 Docs handover).** Current:
```text
(ref'leri tazelemek için `git fetch` çalıştır), bir `git` kelimesinin önünde, heredoc gövdesinde de, hiç kapanmayan
```
Replace with these 3 lines:
```text
(ref'leri tazelemek için `git fetch` çalıştır), `alias.`, `remote.`, `push.`, `url.`, `include` ya da `help.` anahtarını
okuyan ve okuma seçeneğinden önce başka bir seçenek taşıyan `git config` çağrısını (`--file=<dosya>` ya da
`git remote get-url origin` kullan), bir `git` kelimesinin önünde, heredoc gövdesinde de, hiç kapanmayan
```

### `site/index.html`
Base: 702 lines, sha256 `988284bbe256538a9d06149152b8ac3d2166cc77cdbb4a0987dfe08262f2f680`. After the card: 702 lines, sha256 `cfc21f2dc50f737b3ae7a13ee4318920bdb4a6d8270850973b9b3c60f20716ed`.

**A13 · line 29 · replace in the line · header mark.** Find (once in the file):
```text
<span class="ver" data-version="0.6.3">delixcrew 0.6.3</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```

**A14 · line 475 · replace in the line · label, then H1 (T049 Docs handover).** Find (once in the file):
```text
is denied (coming in the next release). It also denies
```
Replace with:
```text
is denied. A <code>git config</code> call that names an <code>alias.</code>, <code>remote.</code>, <code>push.</code>, <code>url.</code>, <code>include</code> or <code>help.</code> key is denied there unless git reads it as a read: <code>get</code> or <code>list</code> as its first argument, or a read option such as <code>--get</code> among the options before the key; a word after the key and a comment do not count (T049). It also denies
```

**A15 · line 475 · replace in the line · label, then H2 (T049 Docs handover).** Find (once in the file):
```text
(T048) (coming in the next release). The push rule
```
Replace with:
```text
(T048). A command that holds a <code>#</code>, a <code>(</code> or a backtick is read by the bash view as well (T049). The push rule
```

**A16 · line 475 · replace in the line · label.** Find (once in the file):
```text
on the usage page) (coming in the next release).</dd>
```
Replace with:
```text
on the usage page).</dd>
```

**A17 · line 695 · replace in the line · footer mark and date.** Find (once in the file):
```text
<span data-version="0.6.3">delixcrew 0.6.3</span> · as of 2026-11-04.
```
Replace with:
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · as of 2026-11-17.
```

### `site/tr/index.html`
Base: 702 lines, sha256 `f1bc9a794fbace880e37fcb6bc10a0e0d8a7a660bce8076beea85c8af9cac787`. After the card: 702 lines, sha256 `4c9e994f84c0d04b71810a0ecb1be4c49e32cd5c4eb456ce96271431775f1841`.

**A18 · line 29 · replace in the line · header mark.** Find (once in the file):
```text
<span class="ver" data-version="0.6.3">delixcrew 0.6.3</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```

**A19 · line 475 · replace in the line · label, then H1 (T049 Docs handover).** Find (once in the file):
```text
reddedilir (sonraki sürümle gelecek). Ayrıca
```
Replace with:
```text
reddedilir. Orada <code>alias.</code>, <code>remote.</code>, <code>push.</code>, <code>url.</code>, <code>include</code> ya da <code>help.</code> anahtarını anan bir <code>git config</code> çağrısı, git onu okuma olarak okumuyorsa reddedilir: ilk argümanı <code>get</code> ya da <code>list</code> olmalı ya da anahtardan önceki seçeneklerde <code>--get</code> gibi bir okuma seçeneği bulunmalı; anahtardan sonraki kelime ve yorum sayılmaz (T049). Ayrıca
```

**A20 · line 475 · replace in the line · label, then H2 (T049 Docs handover).** Find (once in the file):
```text
(T048) (sonraki sürümle gelecek). Push kuralı
```
Replace with:
```text
(T048). İçinde <code>#</code>, <code>(</code> ya da ters tırnak geçen bir komutu bash görünümü de okur (T049). Push kuralı
```

**A21 · line 475 · replace in the line · label.** Find (once in the file):
```text
Bilinen sınırlar) (sonraki sürümle gelecek).</dd>
```
Replace with:
```text
Bilinen sınırlar).</dd>
```

**A22 · line 695 · replace in the line · footer mark and date.** Find (once in the file):
```text
<span data-version="0.6.3">delixcrew 0.6.3</span> · durum 2026-11-04.
```
Replace with:
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · durum 2026-11-17.
```

### `site/usage.html`
Base: 251 lines, sha256 `be41fdbbc225c63d1e2c32ceb8bd883d928177d7117b7e4806fd0be2a418aa8d`. After the card: 251 lines, sha256 `119fb4cafcc043e186881d20494d0e2dc1d6b2476351bd11cf27f106c09eb8d2`.

**A23 · line 29 · replace in the line · header mark.** Find (once in the file):
```text
<span class="ver" data-version="0.6.3">delixcrew 0.6.3</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```

**A24 · line 98 · replace in the line · label.** Find (once in the file):
```text
waits on you (coming in the next release).</p>
```
Replace with:
```text
waits on you.</p>
```

**A25 · line 124 · replace in the line · label.** Find (once in the file):
```text
for the Run button (coming in the next release). Waiting
```
Replace with:
```text
for the Run button. Waiting
```

**A26 · line 124 · replace in the line · label.** Find (once in the file):
```text
last review round (coming in the next release).</td>
```
Replace with:
```text
last review round.</td>
```

**A27 · line 225 · replace in the line · H3, the `origin` URL item (K315).** Find (once in the file):
```text
a URL for <code>origin</code> (<code>url</code>, <code>pushurl</code> or <code>url.*.insteadOf</code>) written into the git config file in the same or an earlier call
```
Replace with:
```text
a URL for <code>origin</code> (<code>url</code>, <code>pushurl</code>, <code>url.*.insteadOf</code> or <code>url.*.pushInsteadOf</code>) written into a git config file (the repository's, the global one or an included one) in the same or an earlier call
```

**A28 · line 225 · replace in the line · the false-positive clause (T049 Docs handover).** Find (once in the file):
```text
to refresh refs), a quote
```
Replace with:
```text
to refresh refs), a <code>git config</code> read of an <code>alias.</code>, <code>remote.</code>, <code>push.</code>, <code>url.</code>, <code>include</code> or <code>help.</code> key with another option before the read option (use <code>--file=&lt;file&gt;</code> or <code>git remote get-url origin</code>), a quote
```

**A29 · line 225 · replace in the line · label.** Find (once in the file):
```text
<code>show</code> (coming in the next release).</li>
```
Replace with:
```text
<code>show</code>.</li>
```

**A30 · line 226 · replace in the line · label.** Find (once in the file):
```text
stays yours (coming in the next release).</li>
```
Replace with:
```text
stays yours.</li>
```

**A31 · line 244 · replace in the line · footer mark and date.** Find (once in the file):
```text
<span data-version="0.6.3">delixcrew 0.6.3</span> · as of 2026-11-04.
```
Replace with:
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · as of 2026-11-17.
```

### `site/tr/usage.html`
Base: 251 lines, sha256 `4a12033f15148821624d9261a096c5d55d104fa460486435572fa3f718ffba97`. After the card: 251 lines, sha256 `c0c2fe2857ba5ab44615a31b34ad892a73b9c8dbe7b1d18dbf940f665de33b46`.

**A32 · line 29 · replace in the line · header mark.** Find (once in the file):
```text
<span class="ver" data-version="0.6.3">delixcrew 0.6.3</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```

**A33 · line 98 · replace in the line · label.** Find (once in the file):
```text
seni bekler (sonraki sürümle gelecek).</p>
```
Replace with:
```text
seni bekler.</p>
```

**A34 · line 124 · replace in the line · label.** Find (once in the file):
```text
bloğunda (sonraki sürümle gelecek). Seni
```
Replace with:
```text
bloğunda. Seni
```

**A35 · line 124 · replace in the line · label.** Find (once in the file):
```text
turunu da gösterir (sonraki sürümle gelecek).</td>
```
Replace with:
```text
turunu da gösterir.</td>
```

**A36 · line 225 · replace in the line · H3, the `origin` URL item (K315).** Find (once in the file):
```text
aynı ya da önceki bir çağrıda git ayar dosyasına yazılan bir <code>origin</code> URL'si (<code>url</code>, <code>pushurl</code> ya da <code>url.*.insteadOf</code>;
```
Replace with:
```text
aynı ya da önceki bir çağrıda bir git ayar dosyasına (reponun, global ya da include edilen) yazılan bir <code>origin</code> URL'si (<code>url</code>, <code>pushurl</code>, <code>url.*.insteadOf</code> ya da <code>url.*.pushInsteadOf</code>;
```

**A37 · line 225 · replace in the line · the false-positive clause (T049 Docs handover).** Find (once in the file):
```text
(ref'leri tazelemek için <code>git fetch</code> çalıştır), bir <code>
```
Replace with:
```text
(ref'leri tazelemek için <code>git fetch</code> çalıştır), <code>alias.</code>, <code>remote.</code>, <code>push.</code>, <code>url.</code>, <code>include</code> ya da <code>help.</code> anahtarını okuyan ve okuma seçeneğinden önce başka bir seçenek taşıyan <code>git config</code> çağrısını (<code>--file=&lt;dosya&gt;</code> ya da <code>git remote get-url origin</code> kullan), bir <code>
```

**A38 · line 225 · replace in the line · label.** Find (once in the file):
```text
push'u da reddeder (sonraki sürümle gelecek).</li>
```
Replace with:
```text
push'u da reddeder.</li>
```

**A39 · line 226 · replace in the line · label.** Find (once in the file):
```text
yine senindir (sonraki sürümle gelecek).</li>
```
Replace with:
```text
yine senindir.</li>
```

**A40 · line 244 · replace in the line · footer mark and date.** Find (once in the file):
```text
<span data-version="0.6.3">delixcrew 0.6.3</span> · durum 2026-11-04.
```
Replace with:
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · durum 2026-11-17.
```

## Global Constraints
- `plugin.json`: only the value `0.6.3` → `0.7.0`. No other key and no reformatting.
- `CHANGELOG.md`: line 5 `## Unreleased` → `## 0.7.0 — 2026-11-17`. The five existing items stay byte for byte except `(0.1.5)` → `(0.1.6)` in the first. The six new items follow them, word for word as in A4. Add no new `## Unreleased` heading (the 0.6.2 and 0.6.3 pattern).
- Date: if the lead changes the release date at dispatch, it changes A2 and the four footer anchors (A17, A22, A31, A40) together and replaces the five affected "after" sha256s.
- Site, on all four pages: both `data-version="0.6.3"` marks and their `delixcrew 0.6.3` text → 0.7.0 (8 marks); the footer date → the release date; the 16 release labels go, each with the space before it: ` (coming in the next release)` (EN, 8: index 3, usage 5) and ` (sonraki sürümle gelecek)` (TR, 8: index 3, usage 5). The sentence around each label stays, and its final punctuation stays in place.
- README, README.tr and the site: T049's H1, H2, H3 and false-positive clause in the places the anchors name, in the handover's words, except D2 and D9. On the site a backticked word is a `<code>` element, and `<`, `>` and `&` are escaped. The TR and EN twins carry the same content.
- Change nothing else: the `Source:` / `Kaynak:` lines (D6), the Umami tag and every other sentence stay. No `SECURITY.md`, `scripts/**`, `hooks/**`, `tests/**`, `plugins/**`, `docs/**` or `STATUS.md` change. The lead records the release in STATUS and STATE after the merge.
- Every new README and CHANGELOG line is at most 120 characters. No raw invisible character.

## Steps
1. Baseline on the base: `grep -cF 'data-version="0.6.3"'` → `2` on each page; `grep -oF 'coming in the next release' site/index.html site/usage.html | wc -l` → `8`, and the same for `sonraki sürümle gelecek` on the TR pages → `8`; `grep -n '^## ' CHANGELOG.md | head -2` → `5:## Unreleased` then `27:## 0.6.3 — 2026-11-04`.
2. Apply A1 to A40 with the Edit tool. Change nothing else.
3. Run the Verification commands and see the expected output. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
4. Open each of the four pages from `site/` in a browser. Check that the kicker and the footer show `delixcrew 0.7.0`, the footer shows the release date, the former label sentences read cleanly, and the new sentences sit in the bash_gate Implementer cell (index pages) and the Known limits list (usage pages). Save one screenshot per page to `.delix/evidence/`.
5. Run `git add` with the 8 paths by name. Commit `Sürüm 0.7.0: Spec C pano görünürlüğü ve Bash hook sertleştirmesi (T043–T050, #72–#79)`. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd`. No other command of yours holds `git` followed by `push`, `update-ref` or `remote` as words on one line. Write the PR body with the Write tool and open the PR with `--body-file`.
   - The body has `## How I tested` (commands and output, screenshot paths).
   - It also has `## Merge sonrası (kullanıcı, kendi terminali)` with the block below exactly.

Merge sonrası (kullanıcı):
- `git fetch origin && git tag -a v0.7.0 -m "delixcrew 0.7.0" <merge commit> && git push origin v0.7.0`
- Plugin update (README Installation): `claude plugin marketplace update delixcrew`, then `claude plugin update delixcrew@delixcrew`, and `claude plugin update delix-board@delixcrew` if the pane is installed (0.1.6 since #77); then restart Claude.
- No Stop gate approval step: the approval files and commands are unchanged since `v0.6.3` (D7).

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔` lines (`version 0.7.0 (2 marks)` on each page), no `✘`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0 on Python 3.9.6: 16 files, no `✘`, 15 `ALL PASSED` (`site_tests.sh` prints no summary line); the card writer's prototype run printed 1375 `✔` lines
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done` → exit 0, the same 16 files, no `✘` (`board_tests.sh` names `Python 3.13.13` in its T034 line)
- `claude plugin validate .` → `✔ Validation passed with warnings`, exit 0; the same output as on the base (1 warning, 2 plugin directory warnings)
- `shasum -a 256 .claude-plugin/plugin.json CHANGELOG.md README.md README.tr.md site/index.html site/tr/index.html site/usage.html site/tr/usage.html` → the eight "after" sha256s in Edit anchors
- `grep -c '"version": "0.7.0"' .claude-plugin/plugin.json` → `1`
- `grep -cF 'data-version="0.7.0"' site/index.html site/tr/index.html site/usage.html site/tr/usage.html` → `2` each; the same grep for `0.6.3` → `0` each
- `grep -cF 'coming in the next release' site/index.html site/usage.html` and `grep -cF 'sonraki sürümle gelecek' site/tr/index.html site/tr/usage.html` → `0` each
- `grep -cF 'as of 2026-11-17' site/index.html site/usage.html` and `grep -cF 'durum 2026-11-17' site/tr/index.html site/tr/usage.html` → `1` each
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## 0.7.0 — 2026-11-17` then `56:## 0.6.3 — 2026-11-04`
- `for f in README.md README.tr.md site/index.html site/tr/index.html; do grep -oF '(T049)' "$f" | wc -l; done` → `2` four times (H1 and H2)
- `grep -cF 'pushInsteadOf' README.md README.tr.md site/usage.html site/tr/usage.html` → `1` each (H3); `grep -cF 'get-url origin' README.md README.tr.md site/usage.html site/tr/usage.html` → `1` each (the false-positive clause)
- `git diff --numstat origin/main` → exactly 8 lines, added/removed per path: `.claude-plugin/plugin.json` 1/1 · `CHANGELOG.md` 31/2 · `README.md` 11/5 · `README.tr.md` 12/5 · `site/index.html` 3/3 · `site/tr/index.html` 3/3 · `site/usage.html` 6/6 · `site/tr/usage.html` 6/6
- `git diff --stat origin/main | tail -1` → ` 8 files changed, 73 insertions(+), 31 deletions(-)`
- `git diff -U0 origin/main -- CHANGELOG.md README.md README.tr.md | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"` → no output
- `git diff -U0 origin/main | python3 -c "import sys, unicodedata as u; [print(ascii(l)) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and any(u.category(c) in ('Cf', 'Mn', 'Cc') or (u.category(c) == 'Zs' and c != ' ') for c in l)]"` → no output

## Review Focus
- Exactly 16 labels removed. No sentence is cut, and no `.` or `)` is lost or doubled.
- The six new CHANGELOG items are the card's words (D1 is the one change to the lead's text). The five existing items change only in `(0.1.6)`. No item claims full assurance for the push rule (K305).
- H1, H2, H3 and the false-positive clause carry the handover's words (D2, D9) in README, README.tr and the site; TR/EN parity holds; the HTML is escaped.
- `plugin.json` changes only the version value. The footer dates equal the CHANGELOG date.

## Don'ts
- Do not create or push a tag. Do not run `gh release`, `gh api` writes or a push to main.
- Do not touch any path outside Files, including `plugins/delix-board/**` and the `Source:` / `Kaynak:` lines.
- Do not reword a sentence the anchors do not change. If an anchor looks wrong, stop with `NEEDS_CONTEXT`.
- No raw invisible character; write one, if ever needed, as `\uXXXX`.

## Report contract
`.delix/report.md`: one of `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`, the verification outputs (also in `.delix/evidence/verification.txt`), `python3 --version`, the screenshot paths, the PR number and branch, and any assumptions.

Read only this card and, in the spec, K309, K313, K315, K316, K319 and K320.

## Review findings (filled by the lead)
- Round 1 (PR #81, head `328f837d12e1771e66dd60402bef564aaf70cefb`, 2026-11-17): qa `ACCEPT` (0 P0, 0 P1), security
  `🔐 HUMAN_APPROVAL` (no finding; Tier 3, `plugin.json` changes only its version). Lead gates on the clean
  `git archive` of the head: exactly the 8 Files, numstat 1/1, 31/2, 11/5, 12/5, 3/3, 3/3, 6/6, 6/6 (73 insertions,
  31 deletions); the 8 sha256s equal the card's "after" values (the lead's own application of the anchors gave the
  same); 16 suites exit 0 with no `✘` on Python 3.9.6 and 3.13.13 (`site_tests.sh` 23 `✔`); the Stop gate gives
  `[exit 0]` for both commands; CI `check` and `test` green; screenshots show `delixcrew 0.7.0` and 2026-11-17.
  - P2 (security unsure, reproduced by the lead, no fix): the Known limits false-positive clause "with another option
    before the read option" / its TR twin is broader than the code. On the head, `--local`, `--file=<file>`,
    `--show-origin` and `--includes` before `--get` pass; `-f <file>` before `--get` is denied; the write control
    denies. The text errs toward deny and its workaround works; a later wording can name the two-word option form.
  - Note (qa unsure, checked by the lead): the PR body's `## Merge sonrası` block equals the card's (tag, plugin
    update, no Stop gate step per D7).
  - Note (implementer): the impeccable hook flags pre-existing 11.5 px site text outside this card; unchanged.
  - Evidence: `rev81/` files in the lead's scratchpad (not in the repo).
