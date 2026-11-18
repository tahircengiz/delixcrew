# T053 🔐 — Release 0.7.1: version, CHANGELOG, T052's Known limits text, delix-board 0.1.7, site version marks

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T053 | S | 3 | docs | 24 | open |

**🔐 Approved:** 2026-11-18 tahircengiz

> 🔐 Tier 3: `.claude-plugin/plugin.json` is protected (`.claude-plugin/**` in `docs/delix/delix.json`). The lead adds the Approved line after the user's item-specific "yes" in chat and commits it to main before dispatch.
> - The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-18 ("Evet, T053 onaylı", said in the lead session; K335).
> - It ships what `CHANGELOG.md` `## Unreleased` holds (#80), T051 (#82) and T052 (#83) as 0.7.1, with the README and site text that T052 left to the release (T052 D4, K298, K334) and the pane version that T051 left to it (K329).
> - The user chose this card on 2026-11-18 ("Evet, sürüm kartı").
> - Claims (K305): the release claims no full assurance for the push rule. The CHANGELOG item names what a push command may hold; the README's Known limits keep what the hook cannot see.
> - Publication (K313): README, README.tr, the site and the CHANGELOG name no form that passed main before T052. The new false-positive clause names only forms the hook denies on main (D1).

**Goal (1 sentence):** Ship #80, T051 (#82) and T052 (#83) as **0.7.1**, so that the plugin version, the delix-board version (0.1.7) in its manifest and spec, the CHANGELOG heading with the #80 item's PR and two new items, T052's text in the README Hooks section and Known limits (README, README.tr and both usage pages), and the version marks and footer dates of the four site pages all name 0.7.1. · **Spec:** `docs/delix/specs/C-board-visibility.md` K298, K305, K313, K329, K331, K334, K335; the CLAUDE.md "Site (GitHub Pages)" rule covers a version change.

**Docs/site:** this card is the site update the CLAUDE.md version rule asks for, and the README / README.tr / site update that T052 left to the release (T052 D4).

## Files (base origin/main bdeec99; `plugin.json` unchanged since 0e6cb89 (#81), the delix-board manifest and spec since e2864f6 (#77), the README and site files since 0e6cb89, `CHANGELOG.md` since 2f5dceb (#80))
- Modify: `.claude-plugin/plugin.json` (A1: line 4)
- Modify: `plugins/delix-board/.claude-plugin/plugin.json` (A2: line 4)
- Modify: `docs/spec/delix-board.md` (A3 and A4: lines 3, 195)
- Modify: `CHANGELOG.md` (A5 to A7: lines 5, 7–8, 10)
- Modify: `README.md` (A8 to A11: lines 124–125, 247, 400–401, 411–412)
- Modify: `README.tr.md` (A12 to A15: lines 124–125, 248, 401–402, 413–414)
- Modify: `site/index.html` (A16 and A17: lines 29, 695)
- Modify: `site/tr/index.html` (A18 and A19: lines 29, 695)
- Modify: `site/usage.html` (A20 to A23: lines 29, 225, 244)
- Modify: `site/tr/usage.html` (A24 to A27: lines 29, 225, 244)
- Test: none new. `tests/site_tests.sh` already fails when a page's version differs from `plugin.json`.

## Interfaces
- Consumed: `tests/site_tests.sh` version check (every `data-version` mark equals `plugin.json` `version`).
- Produced: version string `0.7.1`, which the user's tag `v0.7.1` names after the merge; delix-board `0.1.7`.

## Lead decisions
- **D1, the false-positive clause (README, README.tr, both usage pages):** it names the forms R-L1 denies with its own message (`LINE_DENY`). The lead ran a probe of 35 commands through `scripts/bash_gate.py` on main `bdeec99` in an implementer worktree: every form the clause names was denied with that message, and the forms the Hooks sentence allows (D4) were allowed. The forms that earlier rules deny (`cd`, a git option before the subcommand, an assignment, a comment) keep their place in the clause's first half.
- **D2, the same-line clause goes:** R-L1 denies another command and a redirection to a file in a command that pushes (T052 D4), so "written into a git config file by another command on the same line" leaves the bypass list. The clause for `origin`'s URL keeps "in the same or an earlier call": a program git runs (hooks, filters) can still write it on that line, and that is the "script file or another program" limit (T052 O2).
- **D3, the environment stays:** git settings given through the environment the session inherits are still out of reach (T052 O3).
- **D4, the Hooks sentence (README line 124, README.tr line 124):** it adds what the command may hold besides the push and its git peers, in the terms of the code: `gh pr create`, a pipe into `tail` or `head`, `LINE_REDIRS` (a redirection to `/dev/null` or a descriptor, `2>&1`), a heredoc with a quoted delimiter, and words no shell expands.
- **D5, the sanitizer example (README line 247, README.tr line 248):** `claude plugin validate .` takes `http://127.1/` from this sentence as the listing's `documentationUrl` and warns (`LISTING_URL_SCHEME`; T052's round 2 note, K334). Written without a scheme, the example keeps its meaning and the warning goes; on a clean copy of the prototype the plugin directory warnings drop from 2 to 1 (`ICON_MISSING` stays). A `homepage` key in `plugin.json` did not clear it (measured), so `plugin.json` changes only its version. README.tr changes the same way for parity, though the validator reads only README.md.
- **D6, CHANGELOG:** the #80 item gains its PR number like every other item; its words stay. T051's item covers K293, K297, K310 and T043's P2 (#82); T052's item names what a push command may hold. Add no new `## Unreleased` heading (the 0.6.2, 0.6.3 and 0.7.0 pattern).
- **D7, delix-board 0.1.7:** T051 changed the pane's `hooks/parse.ts` (#82), and a GitHub install updates only when the version changes (`.claude-plugin/marketplace.json`). The pane spec carries its version in lines 3 and 195 (T046's pattern); its rule text already points to Spec C REQ-3 and K297, so no other line changes. `plugins/delix-board/README.md` names no version.
- **D8, footer date:** the release date, the same as the CHANGELOG heading (T042 D5).
- **D9, no Stop gate step and no Source line:** `scripts/trust.py`, `scripts/stop_gate.py`, `scripts/common.py`, `hooks/hooks.json`, `docs/delix/delix.json` and `templates/delix.json` are unchanged since `v0.7.0`. No `Source:` / `Kaynak:` line changes: the new sentences rest on README.md and `scripts/bash_gate.py`, which those lines already cite.
- **D10, the index pages' Implementer cell (line 475) stays:** it names the push form and the own-branch rule but not the same-command list, and it stays true.

## Edit anchors (base main bdeec99, full SHA bdeec9964b52b5192b84ee9ad9eb48f784fc3245)
Line numbers are from that commit. The dispatch commit adds docs only; on it the ten files are byte-equal to `bdeec99`. Each file lists its line count and sha256 on the base and after the card. Match the quoted content before you edit; if it differs, stop with `NEEDS_CONTEXT`. Apply every anchor with the Edit tool; `plugin.json` must use it, because the hook denies shell writes to protected paths.
- **replace in the line:** the "Find" text occurs exactly once in its file. It is the Edit tool's `old_string`, and "Replace with" is its `new_string`.
- **replace:** the "Current" lines occur once in the file. They are `old_string`, and the new lines are `new_string`.
- The code blocks are not indented: copy each line as it is. README and CHANGELOG lines keep their two leading spaces where they have them, and nothing else has leading or trailing blanks.
- Applied to the base in any order, the anchors give the lead's prototype byte for byte. A script read this card, applied the blocks two ways (the Edit tool's string order and line numbers bottom-up) and got every "after" sha256 below.

### `.claude-plugin/plugin.json`
Base: 19 lines, sha256 `ef1ff407c0c8d21a088d2e4d3b9fd16e9f3bd58c64e2400806a941486a74bc42`. After the card: 19 lines, sha256 `b1d7fae1b61418898bb1367ae26e7728b52f985d96a09f8ebeed58f907a39b2c`.

**A1 · line 4 · replace in the line · the plugin version.** Find (once in the file):
```text
"version": "0.7.0"
```
Replace with:
```text
"version": "0.7.1"
```

### `plugins/delix-board/.claude-plugin/plugin.json`
Base: 21 lines, sha256 `d67c0b9a7e7777e9043d04136fda5a284811ace37e46748adcadd9f81e9c7c71`. After the card: 21 lines, sha256 `5d02cf3410940bb7119bc9b4acb8324f4b61814931518e1a153d2ff03b2b5277`.

**A2 · line 4 · replace in the line · the pane version.** Find (once in the file):
```text
"version": "0.1.6"
```
Replace with:
```text
"version": "0.1.7"
```

### `docs/spec/delix-board.md`
Base: 224 lines, sha256 `8e5662e6414da6fb09600656cee0d57d5229a6826be6e788650ebc5e60e31597`. After the card: 224 lines, sha256 `8bc7a3f873260361c225a1f6fe6b67867d84eb66117c9ef178cc7263b3f2e68e`.

**A3 · line 3 · replace in the line · the pane spec's version.** Find (once in the file):
```text
Sürüm: delix-board 0.1.6
```
Replace with:
```text
Sürüm: delix-board 0.1.7
```

**A4 · line 195 · replace in the line · the manifest line.** Find (once in the file):
```text
name delix-board, version 0.1.6,
```
Replace with:
```text
name delix-board, version 0.1.7,
```

### `CHANGELOG.md`
Base: 250 lines, sha256 `998634919d7551016d6774bee19285606054585201fc392f4762c3615982dce9`. After the card: 260 lines, sha256 `b98544f8c1724af811f557e4a165d8998af64bd2654dfe84fb9b9a6c125b5a16`.

**A5 · line 5 · replace in the line · the release heading.** Find (once in the file):
```text
## Unreleased
```
Replace with:
```text
## 0.7.1 — 2026-11-18
```

**A6 · lines 7 to 8 · replace · the PR of the existing item.** Current (2 lines, once in the file):
```text
- **The lead's Desktop title says Lead**: when `/delixcrew:dispatch` opens card sessions in Claude Desktop, the lead
  renames itself `<project> | Lead • <topic>` and titles each card session `<project> | T<nnn> <topic>`, so the
```
Replace with these 2 lines:
```text
- **The lead's Desktop title says Lead** (#80): when `/delixcrew:dispatch` opens card sessions in Claude Desktop, the
  lead renames itself `<project> | Lead • <topic>` and titles each card session `<project> | T<nnn> <topic>`, so the
```

**A7 · line 10 · replace · the two new items after the existing one.** Current (1 line, once in the file):
```text
  title.
```
Replace with these 11 lines:
```text
  title.
- **A push shares its command only with its git peers** (🔐 K331–K334; #83): in an implementer worktree a command that
  pushes may hold, besides the push, only `git add`, `commit`, `status`, `diff`, `log` or `show` (with no `--output`),
  `gh pr create`, a pipe into `tail` or `head`, a redirection to `/dev/null` or a descriptor (`2>&1`) and a heredoc
  with a quoted delimiter, and no word a shell expands. Anything else denies with a message that says to run the other
  command in a separate call. The README's Known limits list the forms it denies.
- **The board keeps an escalated card's worktree and reads the dated Approved line** (K293, K297, K310; #82): a card
  whose status is `escalated` gets no `git worktree remove` after a week idle, so it stays under Waiting on you. An open
  tier 3 card shows `tier 3 approval` until its header holds the `**🔐 Approved:** <YYYY-MM-DD> <who>` line, the form
  write_gate reads. `/delixcrew:status` tells whether a worktree has a `.delix/card` by the pane's rule, and the
  delix-board pane (0.1.7) draws control, line and paragraph separator characters in its data text as spaces.
```

### `README.md`
Base: 438 lines, sha256 `724e28410f13acc9713992fe1ce689e0d450319321cbb235a2e935123e813019`. After the card: 444 lines, sha256 `eeb9eaf4855b1e7274e51f4743efee582ddca8bd896ae3bbab96c5b7b6f4cd5a`.

**A8 · lines 124 to 125 · replace · the push rule in Hooks.** Current (2 lines, once in the file):
```text
  default branch, with no `remote.origin.push`, and with no `cd` and no git command other than `add`, `commit`,
  `status`, `diff`, `log` or `show` in the same command; the branch name form also needs the branch's upstream unset
```
Replace with these 4 lines:
```text
  default branch, with no `remote.origin.push`, and with no `cd` and no git command other than `add`, `commit`,
  `status`, `diff`, `log` or `show` in the same command; that command holds nothing else but `gh pr create`, a pipe
  into `tail` or `head`, a redirection to `/dev/null` or a descriptor (`2>&1`) and a heredoc with a quoted
  delimiter, with no word a shell expands (T052). The branch name form also needs the branch's upstream unset
```

**A9 · line 247 · replace in the line · the sanitizer example (D5).** Find (once in the file):
```text
so `http://127.1/` is removed
```
Replace with:
```text
so a URL to `127.1` is removed
```

**A10 · lines 400 to 401 · replace · the same-line git settings clause.** Current (2 lines, once in the file):
```text
(`GIT_DIR`, `GIT_CONFIG_*`) or written into a git config file by another command on the same line (such as a `>>`
redirection), a script file or another program's own git calls (such as `gh pr checkout`), a `gh` alias for `pr merge`,
```
Replace with these 2 lines:
```text
(`GIT_DIR`, `GIT_CONFIG_*`), a script file or another program's own git calls (such as `gh pr checkout`), a `gh` alias
for `pr merge`,
```

**A11 · lines 411 to 412 · replace · the push false positives.** Current (2 lines, once in the file):
```text
the text in a file), a command nested too deep for the hook to read, and a push in a command that also has `cd` or a git
command other than `add`, `commit`, `status`, `diff`, `log` or `show`. The one
```
Replace with these 6 lines:
```text
the text in a file), a command nested too deep for the hook to read, a push in a command that also has `cd` or a git
command other than `add`, `commit`, `status`, `diff`, `log` or `show`, and a push in a command that also has any other
command except `gh pr create` and a pipe into `tail` or `head`, a `--output` option, a redirection other than `>`,
`1>`, `2>` or `&>` to `/dev/null`, `2>&1`, `1>&2` or `>&2`, a heredoc with an unquoted delimiter, `<<-` or `<<<`, a
`$`, backtick or backslash outside single quotes, a glob, `~`, `!`, a lone `&` or `(` outside quotes, or a `{` or `}`
word after a command's name (T052; run the other command in a separate call). The one
```

### `README.tr.md`
Base: 441 lines, sha256 `c473b422199fdfb94b4c9af446210e10832da8d44c4bbe46f1f56ad8b2eb19ce`. After the card: 449 lines, sha256 `77e8f8fb7577a34a6a8f157d31f5d3af7268f9fd8cd8bf15635ea0de58167cbe`.

**A12 · lines 124 to 125 · replace · the push rule in Hooks.** Current (2 lines, once in the file):
```text
  dalından, `remote.origin.push` yokken, aynı komutta `cd` ve `add`, `commit`, `status`, `diff`, `log`, `show`
  dışında bir git komutu yokken çalışır; dal adı biçimi ayrıca dalın upstream'inin olmamasını ya da dalın kendisi
```
Replace with these 5 lines:
```text
  dalından, `remote.origin.push` yokken, aynı komutta `cd` ve `add`, `commit`, `status`, `diff`, `log`, `show`
  dışında bir git komutu yokken çalışır; o komutta bunlardan başka yalnız `gh pr create`, `tail` ya da `head`'e bir
  pipe, `/dev/null`'a ya da bir tanımlayıcıya (`2>&1`) bir yönlendirme ve sınırlayıcısı tırnaklı bir heredoc
  bulunur, kabuğun genişlettiği bir kelime bulunmaz (T052). Dal adı biçimi ayrıca dalın upstream'inin olmamasını ya
  da dalın kendisi
```

**A13 · line 248 · replace in the line · the sanitizer example.** Find (once in the file):
```text
`http://127.1/` silinir
```
Replace with:
```text
`127.1`'li URL silinir
```

**A14 · lines 401 to 402 · replace · the same-line git settings clause.** Current (2 lines, once in the file):
```text
kelimeler, ortamdan (`GIT_DIR`, `GIT_CONFIG_*`) verilen ya da aynı satırda başka bir komutun (`>>` yönlendirmesi gibi)
bir git ayar dosyasına yazdığı git ayarları, bir betik dosyası ya da başka bir programın kendi git çağrıları
```
Replace with these 2 lines:
```text
kelimeler, ortamdan (`GIT_DIR`, `GIT_CONFIG_*`) verilen git ayarları, bir betik dosyası ya da başka bir programın
kendi git çağrıları
```

**A15 · lines 413 to 414 · replace · the push false positives.** Current (2 lines, once in the file):
```text
tırnağı (tırnağı kapat ya da metni bir dosyaya yaz), hook'un okuyamayacağı kadar derin iç içe bir komutu ve `cd` ya da
`add`, `commit`, `status`, `diff`, `log`, `show` dışında bir git komutu da içeren bir komuttaki push'u reddeder.
```
Replace with these 7 lines:
```text
tırnağı (tırnağı kapat ya da metni bir dosyaya yaz), hook'un okuyamayacağı kadar derin iç içe bir komutu, `cd` ya da
`add`, `commit`, `status`, `diff`, `log`, `show` dışında bir git komutu da içeren bir komuttaki push'u ve
`gh pr create` ile `tail` ya da `head`'e bir pipe dışında başka bir komut, bir `--output` seçeneği, `/dev/null`'a
`>`, `1>`, `2>` ya da `&>` ve `2>&1`, `1>&2`, `>&2` dışında bir yönlendirme, sınırlayıcısı tırnaksız bir heredoc,
`<<-` ya da `<<<`, tek tırnak dışında bir `$`, ters tırnak ya da ters eğik çizgi, tırnak dışında bir glob, `~`, `!`,
tek başına bir `&` ya da `(` ya da bir komutun adından sonra bir `{` ya da `}` kelimesi de içeren bir komuttaki
push'u reddeder (T052; öteki komutu ayrı bir çağrıda çalıştır).
```

### `site/index.html`
Base: 702 lines, sha256 `cfc21f2dc50f737b3ae7a13ee4318920bdb4a6d8270850973b9b3c60f20716ed`. After the card: 702 lines, sha256 `f02786cf2ce9197cd75850e46a5cc290bd1b2dfc802a2e4276f575e2821c8480`.

**A16 · line 29 · replace in the line · the kicker version.** Find (once in the file):
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.1">delixcrew 0.7.1</span>
```

**A17 · line 695 · replace in the line · the footer version and date.** Find (once in the file):
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · as of 2026-11-17.
```
Replace with:
```text
<span data-version="0.7.1">delixcrew 0.7.1</span> · as of 2026-11-18.
```

### `site/tr/index.html`
Base: 702 lines, sha256 `4c9e994f84c0d04b71810a0ecb1be4c49e32cd5c4eb456ce96271431775f1841`. After the card: 702 lines, sha256 `da117b9f1817d364d2581c9f857f47492830682d9eb174ed90dd136e9f32ff3e`.

**A18 · line 29 · replace in the line · the kicker version.** Find (once in the file):
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.1">delixcrew 0.7.1</span>
```

**A19 · line 695 · replace in the line · the footer version and date.** Find (once in the file):
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · durum 2026-11-17.
```
Replace with:
```text
<span data-version="0.7.1">delixcrew 0.7.1</span> · durum 2026-11-18.
```

### `site/usage.html`
Base: 251 lines, sha256 `119fb4cafcc043e186881d20494d0e2dc1d6b2476351bd11cf27f106c09eb8d2`. After the card: 251 lines, sha256 `266e67e3fc85cca8f4d8be358340b5a3b91d21ef4adb5b28ec51a961c8c61957`.

**A20 · line 29 · replace in the line · the kicker version.** Find (once in the file):
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.1">delixcrew 0.7.1</span>
```

**A21 · line 225 · replace in the line · Known limits: the same-line git settings.** Find (once in the file):
```text
git settings from the environment or written by another command on the same line, a script file
```
Replace with:
```text
git settings from the environment, a script file
```

**A22 · line 225 · replace in the line · Known limits: the push false positives.** Find (once in the file):
```text
a command nested too deep for the hook to read, and a push in a command that also has <code>cd</code> or a git command other than <code>add</code>, <code>commit</code>, <code>status</code>, <code>diff</code>, <code>log</code> or <code>show</code>.</li>
```
Replace with:
```text
a command nested too deep for the hook to read, a push in a command that also has <code>cd</code> or a git command other than <code>add</code>, <code>commit</code>, <code>status</code>, <code>diff</code>, <code>log</code> or <code>show</code>, and a push in a command that also has any other command except <code>gh pr create</code> and a pipe into <code>tail</code> or <code>head</code>, a <code>--output</code> option, a redirection other than <code>&gt;</code>, <code>1&gt;</code>, <code>2&gt;</code> or <code>&amp;&gt;</code> to <code>/dev/null</code>, <code>2&gt;&amp;1</code>, <code>1&gt;&amp;2</code> or <code>&gt;&amp;2</code>, a heredoc with an unquoted delimiter, <code>&lt;&lt;-</code> or <code>&lt;&lt;&lt;</code>, a <code>$</code>, backtick or backslash outside single quotes, a glob, <code>~</code>, <code>!</code>, a lone <code>&amp;</code> or <code>(</code> outside quotes, or a <code>{</code> or <code>}</code> word after a command's name (T052; run the other command in a separate call).</li>
```

**A23 · line 244 · replace in the line · the footer version and date.** Find (once in the file):
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · as of 2026-11-17.
```
Replace with:
```text
<span data-version="0.7.1">delixcrew 0.7.1</span> · as of 2026-11-18.
```

### `site/tr/usage.html`
Base: 251 lines, sha256 `c0c2fe2857ba5ab44615a31b34ad892a73b9c8dbe7b1d18dbf940f665de33b46`. After the card: 251 lines, sha256 `92d325d05287a7e4c71a5918a89c3452bc4fa6e3d83ad01e145c7e59a19999c2`.

**A24 · line 29 · replace in the line · the kicker version.** Find (once in the file):
```text
<span class="ver" data-version="0.7.0">delixcrew 0.7.0</span>
```
Replace with:
```text
<span class="ver" data-version="0.7.1">delixcrew 0.7.1</span>
```

**A25 · line 225 · replace in the line · Known limits: the same-line git settings.** Find (once in the file):
```text
ortamdan gelen ya da aynı satırda başka bir komutun yazdığı git ayarları,
```
Replace with:
```text
ortamdan gelen git ayarları,
```

**A26 · line 225 · replace in the line · Known limits: the push false positives.** Find (once in the file):
```text
hook'un okuyamayacağı kadar derin iç içe bir komutu ve <code>cd</code> ya da <code>add</code>, <code>commit</code>, <code>status</code>, <code>diff</code>, <code>log</code>, <code>show</code> dışında bir git komutu da içeren bir komuttaki push'u da reddeder.</li>
```
Replace with:
```text
hook'un okuyamayacağı kadar derin iç içe bir komutu, <code>cd</code> ya da <code>add</code>, <code>commit</code>, <code>status</code>, <code>diff</code>, <code>log</code>, <code>show</code> dışında bir git komutu da içeren bir komuttaki push'u ve <code>gh pr create</code> ile <code>tail</code> ya da <code>head</code>'e bir pipe dışında başka bir komut, bir <code>--output</code> seçeneği, <code>/dev/null</code>'a <code>&gt;</code>, <code>1&gt;</code>, <code>2&gt;</code> ya da <code>&amp;&gt;</code> ve <code>2&gt;&amp;1</code>, <code>1&gt;&amp;2</code>, <code>&gt;&amp;2</code> dışında bir yönlendirme, sınırlayıcısı tırnaksız bir heredoc, <code>&lt;&lt;-</code> ya da <code>&lt;&lt;&lt;</code>, tek tırnak dışında bir <code>$</code>, ters tırnak ya da ters eğik çizgi, tırnak dışında bir glob, <code>~</code>, <code>!</code>, tek başına bir <code>&amp;</code> ya da <code>(</code> ya da bir komutun adından sonra bir <code>{</code> ya da <code>}</code> kelimesi de içeren bir komuttaki push'u da reddeder (T052; öteki komutu ayrı bir çağrıda çalıştır).</li>
```

**A27 · line 244 · replace in the line · the footer version and date.** Find (once in the file):
```text
<span data-version="0.7.0">delixcrew 0.7.0</span> · durum 2026-11-17.
```
Replace with:
```text
<span data-version="0.7.1">delixcrew 0.7.1</span> · durum 2026-11-18.
```

## Global Constraints
- `plugin.json` (both): only the version value. No other key and no reformatting.
- `CHANGELOG.md`: line 5 `## Unreleased` → `## 0.7.1 — 2026-11-18`. The existing item stays byte for byte except `(#80)` and the rewrap of its first two lines (A6). The two new items follow it, word for word as in A7.
- Date: if the lead changes the release date at dispatch, it changes A5 and the four footer anchors (A17, A19, A23, A27) together and replaces the five affected "after" sha256s.
- Site, on all four pages: both `data-version="0.7.0"` marks and their `delixcrew 0.7.0` text → 0.7.1 (8 marks); the footer date → the release date. On the usage pages the Known limits item changes only in A21/A22 and A25/A26. On the site a backticked word is a `<code>` element, and `<`, `>` and `&` are escaped. The TR and EN twins carry the same content.
- Change nothing else: the `Source:` / `Kaynak:` lines (D9), the Umami tag and every other sentence stay. No `SECURITY.md`, `scripts/**`, `hooks/**`, `tests/**`, `docs/delix/**` or `STATUS.md` change, and in `plugins/delix-board/**` only the manifest's version. The lead records the release in STATUS and STATE after the merge.
- Every new README and CHANGELOG line is at most 120 characters. No raw invisible character.

## Steps
1. Baseline on the base: `grep -cF 'data-version="0.7.0"'` → `2` on each page; `grep -n '^## ' CHANGELOG.md | head -2` → `5:## Unreleased` then `12:## 0.7.0 — 2026-11-17`; `claude plugin validate . 2>&1 | grep -c LISTING_URL_SCHEME` → `1`.
2. Apply A1 to A27 with the Edit tool. Change nothing else.
3. Run the Verification commands and see the expected output. Write the output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
4. Open each of the four pages from `site/` in a browser. Check that the kicker and the footer show `delixcrew 0.7.1`, the footer shows the release date, and on the usage pages the Known limits item reads cleanly with the new clause. Save one screenshot per page to `.delix/evidence/`.
5. Run `git add` with the 10 paths by name. Commit `Sürüm 0.7.1: pano düzeltmeleri, push komutu izin listesi belgeleri, delix-board 0.1.7 (#80, #82, #83)`. Run `git push -u origin HEAD` as its own command from the worktree root, with no `cd` and nothing else in the command. No other command of yours holds `git` followed by `push`, `update-ref` or `remote` as words on one line. Write the PR body with the Write tool and open the PR with `--body-file`.
   - The body has `## How I tested` (commands and output, screenshot paths).
   - It also has `## Merge sonrası (kullanıcı, kendi terminali)` with the block below exactly.

Merge sonrası (kullanıcı):
- `git fetch origin && git tag -a v0.7.1 -m "delixcrew 0.7.1" <merge commit> && git push origin v0.7.1`
- Plugin update (README Installation): `claude plugin marketplace update delixcrew`, then `claude plugin update delixcrew@delixcrew`, and `claude plugin update delix-board@delixcrew` if the pane is installed (0.1.7 since this release); then restart Claude.
- No Stop gate approval step: the approval files and commands are unchanged since `v0.7.0` (D9).

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, 23 `✔` lines (`version 0.7.1 (2 marks)` on each page), no `✘`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0 on Python 3.9.6: 17 files, no `✘`, 16 `ALL PASSED` (`site_tests.sh` prints no summary line); the lead's prototype run printed 1431 `✔` lines
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done` → exit 0, the same 17 files, no `✘`
- `claude plugin validate .` → `✔ Validation passed with warnings`, exit 0; `claude plugin validate . 2>&1 | grep -c LISTING_URL_SCHEME` → `0`
- `shasum -a 256 .claude-plugin/plugin.json plugins/delix-board/.claude-plugin/plugin.json docs/spec/delix-board.md CHANGELOG.md README.md README.tr.md site/index.html site/tr/index.html site/usage.html site/tr/usage.html` → the ten "after" sha256s in Edit anchors
- `grep -c '"version": "0.7.1"' .claude-plugin/plugin.json` → `1`; `grep -c '"version": "0.1.7"' plugins/delix-board/.claude-plugin/plugin.json` → `1`; `grep -c 'delix-board 0.1.7' docs/spec/delix-board.md` → `1`; `grep -c 'version 0.1.7,' docs/spec/delix-board.md` → `1`
- `grep -cF 'data-version="0.7.1"' site/index.html site/tr/index.html site/usage.html site/tr/usage.html` → `2` each; the same grep for `0.7.0` → `0` each
- `grep -cF 'as of 2026-11-18' site/index.html site/usage.html` and `grep -cF 'durum 2026-11-18' site/tr/index.html site/tr/usage.html` → `1` each
- `grep -n '^## ' CHANGELOG.md | head -2` → `5:## 0.7.1 — 2026-11-18` then `22:## 0.7.0 — 2026-11-17`
- `for f in README.md README.tr.md site/usage.html site/tr/usage.html; do grep -oF '(T052' "$f" | wc -l; done` → `2`, `2`, `1`, `1`
- `grep -cF 'another command on the same line' README.md site/usage.html` and `grep -cF 'aynı satırda başka bir komutun' README.tr.md site/tr/usage.html` → `0` each
- `grep -cF '127.1' README.md README.tr.md` → `1` each; `grep -cF 'http://127.1/' README.md README.tr.md` → `0` each
- `git diff --numstat origin/main` → exactly 10 lines, added/removed per path: `.claude-plugin/plugin.json` 1/1 · `plugins/delix-board/.claude-plugin/plugin.json` 1/1 · `docs/spec/delix-board.md` 2/2 · `CHANGELOG.md` 13/3 · `README.md` 12/6 · `README.tr.md` 14/6 · `site/index.html` 2/2 · `site/tr/index.html` 2/2 · `site/usage.html` 3/3 · `site/tr/usage.html` 3/3
- `git diff --stat origin/main | tail -1` → ` 10 files changed, 53 insertions(+), 29 deletions(-)`
- `git diff -U0 origin/main -- CHANGELOG.md README.md README.tr.md | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"` → no output
- `git diff -U0 origin/main | python3 -c "import sys, unicodedata as u; [print(ascii(l)) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and any(u.category(c) in ('Cf', 'Mn', 'Cc') or (u.category(c) == 'Zs' and c != ' ') for c in l)]"` → no output

## Review Focus
- The false-positive clause names only forms R-L1 denies on main (D1); no form that passes main appears anywhere (K313).
- The two new CHANGELOG items are the card's words; the existing item changes only in `(#80)` and its rewrap. No item claims full assurance for the push rule (K305).
- README, README.tr and the two usage pages carry the same clauses (TR/EN parity); the HTML is escaped.
- Both `plugin.json` files change only the version value. The footer dates equal the CHANGELOG date.

## Don'ts
- Do not create or push a tag. Do not run `gh release`, `gh api` writes or a push to main.
- Do not touch any path outside Files, including the rest of `plugins/delix-board/**` and the `Source:` / `Kaynak:` lines.
- Do not reword a sentence the anchors do not change. If an anchor looks wrong, stop with `NEEDS_CONTEXT`.
- No raw invisible character; write one, if ever needed, as `\uXXXX`.

## Report contract
`.delix/report.md`: one of `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`, the verification outputs (also in `.delix/evidence/verification.txt`), `python3 --version`, the screenshot paths, the PR number and branch, and any assumptions.

Read only this card and, in the spec, K298, K305, K313, K329, K331, K334 and K335.

## Review findings (filled by the lead)
- Round 1 (PR #84, head `f38f441cbdd536863685926c0cdf66f212f021ff`, 2026-11-18): qa `ACCEPT` (0 P0, 0 P1), security
  `🔐 HUMAN_APPROVAL` (Tier 3; `plugin.json` changes only its version). Lead gates on the clean `git archive` of the
  head: exactly the 10 Files, the card's numstat (53 insertions, 29 deletions); the 10 files equal the lead's prototype
  byte for byte (the card's "after" sha256s); the Stop gate gives `[exit 0]` for both commands; CI `check` and `test`
  green; `claude plugin validate .` on the archive: 1 warning and 1 plugin directory warning, no `LISTING_URL_SCHEME`;
  17 suites on Python 3.9.6 and 3.13.13 on the archive, 1431 ✔ each, 0 ✘; the screenshots show `delixcrew 0.7.1` and 2026-11-18.
  - Low (security, reproduced by the lead on the head): the redirection list in the false-positive clause and the
    Hooks sentence is looser than `LINE_REDIRS`. `1> /dev/null` and `&> /dev/null` with a space deny (the glued forms,
    `> /dev/null` and `2> /dev/null` pass), and so do descriptor forms other than `2>&1`, `1>&2` and `>&2` (`3>&1`,
    `2>&-`). The text errs toward allow; the deny message names the rule. Gate 2 decides: a docs fix round or a
    follow-up.
  - Note (security unsure, checked by the lead): a `{ … }` group around the push and its peers passes; the CHANGELOG's
    "Anything else denies" does not name it. A group runs in the same shell, and a `}` word inside a command denies.
  - Note (security, pre-existing, not in this PR): `plugins/delix-board/.claude-plugin/plugin.json` and
    `plugins/delix-board/hooks/hooks.json` match no `protected_paths` entry (the lead ran `common.matches`), so a card
    that changes them is not Tier 3 by path. A `protected_paths` change is itself protected (🔐); the user decides.
  - Note (qa unsure): the screenshots are not in the archive; the lead looked at them.
- Gate 2 (the user, 2026-11-18): merge as it is; the Low goes to a follow-up card (T054) that adds the spaced
  forms to `LINE_REDIRS`. Merged (K337): the user merged head `f38f441cbdd536863685926c0cdf66f212f021ff` as it is (merge
  commit `7ea54f7eb16234fae733bd4b5ef2d62a810b375c`, 2026-11-18T09:37:38Z). The merge commit changes only the 10 Files, and they equal
  the reviewed head byte for byte. Status `accepted`.
