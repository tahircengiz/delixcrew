# T028 — Docs and site: Stop gate approval, trust.py allow, cat heredoc, repo-write message, migration note

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T028 | M | 2 | docs | 2 | open |

> Tier 2: none of these paths is protected (`skills/`, `README*`, `site/`, `CHANGELOG.md` are free). It is Tier 2 because it touches 9 files and makes public claims about security behaviour. The site is published from main on every push.

**Goal (1 sentence):** README (EN/TR), the dispatch and implement skills, CHANGELOG Unreleased and the four site pages describe what T026 and T027 merged:
- the approval with `trust.py allow`, inherited by worktrees;
- the `[not run: …]` stop and the BLOCKED step;
- the record file and how to withdraw an approval by deleting its entry;
- the new hook rules and the §6 residuals.

The version is unchanged (K209). · **Spec:** `docs/delix/SPEC.md#REQ-7`; §5 (migration), §6 (residuals); K208, K209, K77

**Docs/site:** this card is the update (CLAUDE.md: a command and hook rules were added).

## Files
- Modify: `README.md` (Flow dispatch row line 69; Hooks bullets lines 103 to 115; home-dir bullet lines 125 to 126; Known limits after line 339)
- Modify: `README.tr.md` (the same four places; Akis dispatch row, lines 103 to 115, 125 to 126, after line 339)
- Modify: `skills/dispatch/SKILL.md` (section 4, after line 35)
- Modify: `skills/implement/SKILL.md` (section 3, after line 39)
- Modify: `CHANGELOG.md` (Unreleased, after line 22)
- Modify: `site/index.html` (lines 449, 464, 473, 481 to 485, 488)
- Modify: `site/tr/index.html` (the same elements)
- Modify: `site/usage.html` (lines 95, 104, 229 to 234, 237)
- Modify: `site/tr/usage.html` (the same elements)

## Edit anchors (base: main after T026 and T027 are merged; line numbers from 63e8440, match the content)
Quote every message, path and command from the merged `scripts/trust.py`, `scripts/stop_gate.py`, `scripts/bash_gate.py` and `scripts/write_gate.py`, byte for byte. Do not paraphrase a message inside backticks.
1. `README.md`:
   - Flow row `/delixcrew:dispatch` (line 69): append one sentence. Once per repository, before the first session, you approve the Stop gate commands in the main checkout from your own terminal: `python3 <plugin dir>/scripts/trust.py allow`, typing `TRUST <hash>`. Link `#what-this-plugin-does-on-your-machine`.
   - write_gate bullet (103–106): in every session it also denies writes to the Stop gate record `~/.claude/delixcrew/trust.json`.
   - bash_gate bullet (107–112), in every session:
     - it denies `trust.py allow`, `trust.py` under a terminal wrapper (`script`, `expect`, `unbuffer`, `pty`, `tmux`, `screen`, `socat`, `zpty`) and any command naming `delixcrew/trust.json`;
     - a `gh api` write to this repository's settings, rulesets or security gets its own message;
     - exactly one `cat > <path> <<'EOF'` heredoc (quoted delimiter, nothing after the closing line, a path outside `~/.claude/delixcrew/`) is checked on its first line only, like one `feedback.py add` or `triage.py record` heredoc;
     - a command naming the record and the protected-path redirect check still see the full text.
   - Stop bullet (113–115), rewritten:
     - it runs `test_command` and `extra_checks` only when you approved that exact list for this repository (its `git_common_dir` and a SHA-256 of the list) with `trust.py allow` from your own terminal;
     - worktrees of an approved checkout inherit the approval, and a changed list needs a new one;
     - without approval it runs nothing, writes `[not run: commands not approved, hash <h12>]` to `.delix/test-result.txt`, prints the command for you and stops the turn once; the implementer then writes `BLOCKED`;
     - the repository is identified on the file system (a real `.git` directory, or a `.git` file whose worktree entry points back), never through a symlink, and git runs without `GIT_*` variables;
     - after an update from an earlier version, the first Stop gate in each repository stops this way until you run `trust.py allow` once in its main checkout (§5).
   - Home-dir bullet (125–126): add the Stop gate approvals `~/.claude/delixcrew/trust.json` (directory `0700`, file `0600`). It is written only by `trust.py allow` and ignored when it is a symlink, not yours or readable by others. To withdraw an approval, delete its object from `entries`, or the file; there is no revoke or list command (K208).
   - Known limits: new paragraph after line 339 with the §6 residuals (including K220: the trust record rule is a substring match, so a relative path after `cd`, `//`, `/./` or a symlinked directory passes it; and K225: with git older than 2.44 a missing object in a promisor repo can still be fetched while the hooks read the index), in this order:
     1. the approval covers the command text, not the files it runs: on an approved repository, a branch that changes `tests/` but keeps the list runs them, as if you ran the tests on that branch;
     2. a new directory at the path of a deleted repository, or of a worktree not yet pruned (`git worktree prune`), can inherit its approval;
     3. the project's own `.claude/settings.json` hooks and `PATH` can still run code once you accept the folder trust dialog; the approval closes only the `delix.json` channel;
     4. the Bash hook's denylist is friction, not a boundary: commands built from split quotes, variables or globs get past it; the boundary is Claude Code's Bash permission prompt (K77);
     5. the one allowed `cat` heredoc writes nothing the Write tool could not already write.
2. `README.tr.md`: the same content in Turkish at the same places (Akış `/delixcrew:dispatch` row; Hook bullets 103–115; "Ev dizininizde" bullet 125–126; new paragraph after line 339 in "Bilinen sınırlar"). Technical terms and quoted messages stay English.
3. `skills/dispatch/SKILL.md`: insert after line 35 (`One line per card for the user: card, role, tier, how to open it.`) a bullet:
   - **Stop gate approval (once per repository):** before the first session, the user runs `python3 <plugin root>/scripts/trust.py allow` in the main checkout, in their own terminal, and types `TRUST <hash>`.
   - Give the command with the plugin root written out; never run it yourself, because the Bash hook denies it.
   - Worktrees inherit the approval. A card whose branch changes `test_command` or `extra_checks` needs a new approval from its worktree.
4. `skills/implement/SKILL.md`: insert after line 39 (`  tricks.`) a bullet. If the Stop hook says the commands are not approved (`[not run: commands not approved, hash …]` in `.delix/test-result.txt`), do not try to approve or bypass it: write `BLOCKED` in `.delix/report.md` naming the `trust.py allow` command from the hook message, then stop.
5. `CHANGELOG.md` Unreleased: append after line 22, in the style of the existing bullets:
   - **Stop gate commands need your approval** (#17): what it checks; `trust.py allow`; worktree inheritance; `[not run: …]` and BLOCKED; the record and removal by deleting an entry. Migration: after updating, run `python3 <plugin dir>/scripts/trust.py allow` once in each repository's main checkout.
   - **One `cat` heredoc is checked on its first line only**, and one capture call now also skips the gh rules for its body (K202, K204).
   - **Repository settings writes get their own message** (REQ-6).
6. `site/index.html`:
   - Known limits bullet line 449 (the `issue #17` open case): replace it with one bullet. The Stop gate runs `delix.json` commands only after you approve them from your own terminal (`trust.py allow`); the approval covers the command text, not the test files, and not the project's own `.claude/settings.json` hooks.
   - write_gate "Every session" `dd` (464): add the record.
   - bash_gate "Every session" `dd` (473): add the trust rules and the single `cat` heredoc.
   - stop_gate `dl` (481–485): add `<div><dt>Approval</dt><dd>…</dd></div>` before "Way out": approval, `[not run: …]`, exit 2 once, BLOCKED.
   - Each new or changed sentence ends with "(coming in the next release)", because the installed 0.6.2 does not have it (CLAUDE.md "coming in" labels; K209 keeps the version).
   - Source line 488: add `scripts/trust.py · CHANGELOG (Unreleased)`.
7. `site/usage.html`:
   - dispatch step (line 95): append the one-time approval sentence with `<code>python3 &lt;plugin dir&gt;/scripts/trust.py allow</code>` and `TRUST &lt;hash&gt;`, plus "(coming in the next release)".
   - Troubleshooting `ul` (229–234): add a `li`. The implementer reports `BLOCKED` with "commands not approved": run the same command in that checkout from your own terminal (coming in the next release).
   - Source lines 104 and 237: add `scripts/trust.py`; at 237 also add `README.md (What this plugin does on your machine)`.
8. `site/tr/index.html`, `site/tr/usage.html`: the same elements in Turkish, with the label "(sonraki sürümle gelecek)" and the source line "Kaynak:".

## Interfaces
- Consumed (from merged T026/T027, quote exactly):
  - the `trust.py allow` prompt and its exit codes 0/6/7;
  - the record path and format;
  - the `[not run: commands not approved, hash <h12>]` line;
  - the three Stop gate stderr lines;
  - `TRUST_DENY`, `REPO_DENY`;
  - the `CAT_HEREDOC` shape.
- Produced: no code interface.

## Global Constraints (verbatim from the spec)
- REQ-7:
  - "README.md / README.tr.md güncellenir: 'What this plugin does on your machine'; 'Known limits': §6 kalıntıları ve 'bash denylist yalnız sürtünmedir; sınır izin istemidir (K77)'; 'Files': kayıt dosyası ve satır silerek geri alma."
  - "`skills/dispatch/SKILL.md`: ilk dispatch'ten önce ana checkout'ta `trust.py allow`."
  - "`skills/implement/SKILL.md`: Stop gate 'not approved' dediğinde BLOCKED."
  - "`site/` dört sayfası: CLAUDE.md tetikleyicisi (yeni komut ve hook kuralı); sürüm etiketi değişmez (K209). `bash tests/site_tests.sh` yeşil kalır."
- §5: "Geçiş adımı `trust.py allow`'u ana checkout'ta bir kez çalıştırmaktır; README ve CHANGELOG bunu söyler."
- CLAUDE.md (site):
  - "Every claim on the site comes from a repo file; each section names its sources in its `Source:` / `Kaynak:` line."
  - The English and Turkish pages carry the same content.
  - No script, form, event handler or third-party asset, other than the existing Umami tag.
- No raw invisible characters; HTML-escape `<`, `>` and `&` inside `<code>`.

## Steps
1. Read the merged scripts and capture the exact texts you will quote (prompt, `[not run: …]`, the stderr lines, both deny messages).
2. Edit the 9 files per the anchors. Keep every other line unchanged.
3. Run `bash tests/site_tests.sh`, the full loop and `claude plugin validate .`.
4. Open each of the four pages in a browser from `site/` (file URL). Check the new `dt`/`li` render and the TR/EN pairs match, and save a screenshot per page to `.delix/evidence/`.
5. Commit `T028: docs and site for the Stop gate approval (trust.py allow)`. Open a PR whose `## How I tested` lists the commands, their output and the screenshot paths.

## Verification command → expected output
- `bash tests/site_tests.sh` → exit 0, no `✘`; `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0; `claude plugin validate .` → passes
- `grep -cF 'trust.py allow' README.md README.tr.md skills/dispatch/SKILL.md skills/implement/SKILL.md CHANGELOG.md site/index.html site/tr/index.html site/usage.html site/tr/usage.html` → every count ≥ 1
- `grep -cF 'delixcrew/trust.json' README.md README.tr.md` → each ≥ 1; `grep -cF 'K77' README.md README.tr.md` → each count one more than on origin/main
- `grep -cF 'issue #17' site/index.html site/tr/index.html` → `0` for both
- `grep -cF 'coming in the next release' site/index.html site/usage.html` and `grep -cF 'sonraki sürümle gelecek' site/tr/index.html site/tr/usage.html` → equal counts per EN/TR pair, each ≥ 1
- `git diff origin/main -- .claude-plugin/plugin.json` → no output; `git diff origin/main -- site | grep -c 'data-version'` → `0`
- `git diff --stat origin/main` → only the 9 files in Files

## Review Focus
- Every quoted message and command matches the merged code byte for byte (compare with `grep -F` in `scripts/`).
- The README residuals are the four §6 items plus the `.claude/settings.json` scope sentence, nothing more. The tone stays plain: the K77 sentence does not claim the denylist is a boundary.
- TR/EN parity on all four pages and both READMEs; `Source:`/`Kaynak:` lines name `scripts/trust.py`.
- The site marks the new behaviour "coming in the next release". README describes main without a label.
- Removal is described as deleting an entry from `entries` (K208). No revoke or list command is invented.

## Don'ts
- Do not touch `scripts/**`, `tests/**`, `hooks/hooks.json`, `docs/delix/**`, `.claude-plugin/**` or `SECURITY.md`.
- Do not change the version, any `data-version` mark or the `delixcrew <version>` text (K209).
- Claim nothing the merged code does not do. If the code and the spec disagree, write `NEEDS_CONTEXT`.
- Add no script, form, event handler or external asset to the site.

## Report contract
`.delix/report.md` (≤ 1K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output (site_tests, the grep counts);
- the screenshot paths;
- the PR number;
- assumptions.

Read only this card, SPEC REQ-7, §5 and §6, and the merged scripts named above.

## Review findings (filled by the lead)
- Round 0 (e9e788e, PR #58): deterministic gates green, run by the lead from `git archive e9e788e`. Site tests had 0 failures, all 10 suites passed, and `claude plugin validate .` passed. CI `test` and `check` passed. Every grep count in the Verification list matched. The diff touches exactly the 9 Files. The internal-host and invisible-character scans found 0. qa: ACCEPT (0 P0, 0 P1). security: CLEAN (no Critical, High or Medium; gitleaks found no leaks). Notes, no fix round; the wording goes into the K225 follow-up card (K229):
  - [Low, security] `README.md:375-376` (TR twin): "The one allowed `cat` heredoc writes nothing the Write tool could not already write" is not literal in an implementer worktree. write_gate denies writes outside the worktree, to `docs/delix/**` and to existing tests. `cat > ../x <<'EOF'` passes bash_gate, because only the protected-path redirect check sees the full text. The lead confirmed this by reading `bash_gate.py:40-47,116`. The exemption itself adds nothing; the gap is the existing "Bash writes bypass write_gate" limit. Better wording: the exemption only skips the send, apply and `trust.py allow` patterns for the body.
  - [Low, security] `README.md:376-377` (TR twin): the K225 sentence leaves out the impact. A lazy fetch can run a program named in that repository's git config.
  - [Low, security] `site/index.html:473` (TR twin): "any command naming `delixcrew/trust.json`" carries no K220 substring caveat on the site. The card asked for one bullet only, so this conforms to the card.
  - [P2, qa] `README.md:70-75` (TR twin): the printed command is shown with placeholders; the real line has `shlex.quote`d absolute paths.
  - [unsure, security] `skills/dispatch/SKILL.md`: an approval made from a worktree is keyed by `git_common_dir`, so a list changed on a branch becomes approved for every worktree of the repo. `trust.py` shows the commands, but the skill does not ask the user to check that the change is intended. This goes to the follow-up card.
- Gate 2: the user merged PR #58 as 429e79b (2026-11-04).
