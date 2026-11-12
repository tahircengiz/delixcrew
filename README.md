# delix — a team workflow for Claude Code

**Spec first. Agents build. You hold the gates.**

`delix` turns the single-session loop of "open, pick a folder, read the history, continue" into the division of labour
of a real software team: a **lead** session writes a tech spec through a grill interview, splits the work into
task cards, hands each card to an **implementer** session running in its own worktree, and has **read-only reviewers**
(qa, security) check the result. A human is involved at exactly two gates: **spec approval** and **PR merge**. The
constraints live in the harness, not in the prompt: reviewer roles have no write tool in their `tools` list, plugin hooks
block writes to protected paths and changes to test files, and the Stop hook does not close an implementer turn until the
tests pass.

Türkçe sürüm: [README.tr.md](README.tr.md). Design and evidence (Turkish): [tech spec](docs/spec/ekip-tech-spec.md) ·
[research report](docs/research/reports/Çoklu%20ajan%20yazılım%20ekibi%20orkestrasyonu.md) · decisions [STATUS.md](STATUS.md).
The skills reply in the user's language; labels, status values and verdict tokens stay in English.

## Requirements

- **Claude Code** with plugin marketplaces; tested with 2.1.309, older versions not tested.
- **`python3`** on `PATH` (tested with 3.9). The hooks are Python scripts and block on failure, so without it every
  Write, Edit and Bash call is blocked, in every session, with the line `delixcrew: python3 not found on PATH …`.
- **`git`**: implementer sessions work in worktrees on card branches.
- Optional: **`gh`** (GitHub CLI, signed in) to open and read PRs; without a remote the commits stay on the card branch
  and the report says `**PR:** none`. **`gitleaks`**: a secret scan before every implementer commit; without it a note
  goes to `.delix/warnings.log`.

No GitHub SSH key is needed: `marketplace add` tries SSH and falls back to HTTPS.

## Installation

From GitHub (Desktop and terminal, no `--plugin-dir` needed):

```bash
claude plugin marketplace add tahircengiz/delixcrew
```

```bash
claude plugin install delixcrew@delixcrew
```

From a local clone: `claude plugin marketplace add /path/to/delix`, then the same `install` command. The marketplace
definition is [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Both installs copy the plugin into
Claude's plugin cache, one folder per version, so an install updates only when the version in `plugin.json` changes:
run `claude plugin marketplace update delixcrew` (GitHub; a local folder is read directly), then
`claude plugin update delixcrew@delixcrew`, and restart Claude. A local change without a version bump does not reach the
installed copy, `git pull` alone is not enough; to try one, `claude --plugin-dir /path/to/delix` reads the folder in place.
Installed before 0.4.0 as plugin `delix` (or under the marketplace name `delix-local`): see the [CHANGELOG](CHANGELOG.md#040--2026-11-03).
Checks (also run by CI on every push and PR): `claude plugin validate .`; hook tests: `bash tests/hook_tests.sh`; board tests:
`bash tests/board_tests.sh`; behaviour evals: `claude plugin eval . --trust-plugin --no-publish` (calls the model, costs money).

### Companion: delix-board

[`delix-board`](plugins/delix-board/README.md) is a separate, read-only mod in the same marketplace: a live pane with the
board, long runs, card details and metrics, a band above the prompt and a toast when a run ends. It is not needed for
delix to work and draws nothing in headless sessions.

```bash
claude plugin install delix-board@delixcrew
```

![delix-board in the terminal](plugins/delix-board/assets/board-terminal-pano.png)

## Flow

| Step | Command | What happens |
|---|---|---|
| 1 | `/delixcrew:start <request>` | Context is read; **size** (S/M/L: process weight) and **tier** (1/2/3: gates) are proposed; `docs/delix/` is set up. For S, a single card. |
| 2 | `/delixcrew:spec` | Grill (one question at a time, with a pick) → `docs/delix/SPEC.md` (SHALL + WHEN/THEN); `architect` (+ `security` at Tier 3) reviews; EGM at size L. For UI work only, a design-system step: the spec links `DESIGN.md` (or the repo's token file), and produces `DESIGN.md` when neither exists. **Gate 1.** |
| 3 | `/delixcrew:dispatch` | `architect` writes the cards and the wave plan; conflict check; dispatch prompts; implementer sessions (at most 3 in parallel). Once per repository, before the first session, you approve the Stop gate commands in the main checkout from your own terminal: `python3 <plugin dir>/scripts/trust.py allow`, typing `TRUST <hash>` (see [What this plugin does on your machine](#what-this-plugin-does-on-your-machine)). |
| 4 | `/delixcrew:implement <card>` | In the implementer session: test-first, only the card's files, a PR, `.delix/report.md`. |
| 5 | `/delixcrew:review <card>` | Deterministic gates → `qa` (+ `security`) with zero context → ≤ 3 fix rounds → **Gate 2 (merge, human).** |
| 6 | `/delixcrew:close` | STATUS/CHANGELOG, metrics (cost, rounds), drift check, approved memory writes, worktree cleanup. |
| shortcut | `/delixcrew:verify <branch\|commit\|dir>` | **Only verifies** work done without a card (a single session or you) (K43): gitleaks, local tests, a remote **isolated** unit test (separate directory + separate image, never touches the live stack), `--full` on request; `qa` (+ `security`) in a **single pass**, no fix rounds → a `docs/delix/verifications/<date>-<name>.md` report (ACCEPT / FIX, 🔐) and `STATE.json.verifications`. For S/M + well-described + Tier ≤ 2 work, `/delixcrew:start` proposes this; the full flow is for Tier 3 / parallel cards / an unclear spec. |
| any time | `/delixcrew:status` | Read-only board: wave · card · role · tier · status · rounds · PR · cost · last report · pending gate (🔐, merge) table in the chat; on request (`--write`) to `docs/delix/BOARD.md` (not committed). |
| issues | `/delixcrew:triage [#n]` | In the delixcrew repo: reads incoming issues cleaned, the read-only `architect` checks each one and proposes a decision; after your `<decision> #<n>` in chat it records it and shows the exact comment; you publish it from your own terminal. See [Triage](#triage). |

## Roles

| Role | Unit | Permissions | Model |
|---|---|---|---|
| lead | main session | writes no code | top |
| `delixcrew:architect` | subagent | Read, Grep, Glob | opus |
| implementer (backend / frontend / ui-ux / devops / docs role note) | separate session, worktree | everything; a protected path or an existing test file only when listed in the card's Files (a protected path additionally needs a 🔐 Approved line); the card and `docs/delix/**` blocked by hook | sonnet |
| `delixcrew:qa` | subagent | Read, Grep, Glob | sonnet |
| `delixcrew:security` | subagent | Read, Grep, Glob + read-only scanner Bash | opus |
| `delixcrew:scout` | subagent | Read, Grep, Glob | haiku |

## Files on the project side

`docs/delix/delix.json` (test command, protected paths, test paths, max parallel, the `verify` remote isolated-run block),
`docs/delix/SPEC.md`, `docs/delix/tasks/T<nnn>-<slug>.md`, `docs/delix/STATE.json` (cards + `verifications` records),
`docs/delix/verifications/<date>-<name>.md|.patch` (`/delixcrew:verify` report and patch), `docs/delix/BOARD.md` (generated only
on request, in `.gitignore`). In the implementer worktree: `.delix/card` (activates the hooks), `.delix/report.md`,
`.delix/test-result.txt`, `.delix/evidence/`.

## What this plugin does on your machine

What runs locally, what it writes and when it uses the network. What a feedback draft contains and where it goes is in
[Data & privacy](#data--privacy); where the hooks stop is in [Known limits](#known-limits). Security reports:
[SECURITY.md](SECURITY.md).

**Hooks** ([`hooks/hooks.json`](hooks/hooks.json)) load in every session where the plugin is enabled:
- `PreToolUse` on `Write|Edit|MultiEdit|NotebookEdit` runs [`scripts/write_gate.py`](scripts/write_gate.py). In every
  session it denies writes into the feedback and triage directories below and to the Stop gate record
  `~/.claude/delixcrew/trust.json`; for the reviewer agents it denies every write. In an implementer worktree it also denies writes outside the worktree, to the card and `docs/delix/**`, to a
  protected path without an approved card, and to an existing test file.
- `PreToolUse` on `Bash` runs [`scripts/bash_gate.py`](scripts/bash_gate.py). In every session it denies the known send
  and apply paths (`feedback.py send`, `triage.py apply`, terminal wrappers such as `script`, and writing `gh issue`,
  `gh label` or `gh api` calls aimed at this repository). A `gh api` write to this repository's settings, rulesets or
  security gets its own message:
  `delixcrew: writes to the delixcrew GitHub repository (settings, rulesets, security) run only from the user's own terminal`.
  In every session it also denies `trust.py allow`, `trust.py` under a terminal wrapper (`script`, `expect`,
  `unbuffer`, `openpty`, `pty.spawn`, `pty.fork`, `tmux`, `screen`, `socat`, `zpty`) and any command naming
  `delixcrew/trust.json`, with
  `delixcrew: Stop gate commands are approved only by the user from their own terminal`.
  Exactly one `cat > <path> <<'EOF'` heredoc (`>>` too; a quoted delimiter, nothing after the closing line, a path
  outside `~/.claude/delixcrew/`) is checked on its first line only, like one `feedback.py add` or `triage.py record`
  heredoc; the rule for a command naming the record and the protected-path redirect check still see the full text.
  The security reviewer may run only commands that start with an
  allowlisted scanner or read command and match no known write pattern; this is a pattern check, not a sandbox. The
  other reviewers get no Bash. In an implementer worktree it denies shell writes into a protected path and runs
  `gitleaks protect --staged` before every `git commit`. There a push runs only as
  `git push [-u|--set-upstream] [--force-with-lease] origin <HEAD|branch>` from the card's own branch, which is not the
  default branch, with no `remote.origin.push`, and with no `cd` and no git command other than `add`, `commit`,
  `status`, `diff`, `log` or `show` in the same command; the branch name form also needs the branch's upstream unset
  or the branch itself. `gh pr merge` is denied there: gate 2 is the user's (T041, K279).
- `Stop` runs [`scripts/stop_gate.py`](scripts/stop_gate.py), only in an implementer worktree: it runs `test_command`
  and `extra_checks` from the project's `docs/delix/delix.json` through the shell, and the turn does not end until they
  pass. These are your project's commands, not the plugin's. It runs them only when you approved that exact list for
  this repository (its `git_common_dir` and a SHA-256 of the list) with `trust.py allow` from your own terminal.
  Worktrees of an approved checkout inherit the approval; a changed list needs a new one. Without approval it runs
  nothing, writes `[not run: commands not approved, hash <h12>]` to `.delix/test-result.txt`, prints the command for
  you (`The user runs, in their own terminal: cd <worktree> && python3 <plugin dir>/scripts/trust.py allow`) and stops
  the turn once (exit 2); the implementer then writes `BLOCKED`. The repository is identified on the file system (a
  real `.git` directory, or a `.git` file whose worktree entry points back), never through a symlink, and git runs
  without `GIT_*` variables. After an update from an earlier version, the first Stop gate in each repository stops
  this way until you run `trust.py allow` once in its main checkout.
- `trust.py allow` ([`scripts/trust.py`](scripts/trust.py)) shows the commands one per line, warns when
  `docs/delix/delix.json` differs from `HEAD`, and asks
  `Type TRUST <hash> to approve these commands for "<git_common_dir>" (the word TRUST, a space, then the hash): `.
  It exits 0 when approved or already approved, 6 when not confirmed (no terminal, wrong text) and 7 on a precondition
  (not at the root of a git checkout or worktree, `.git` a symlink, a command that is not a string, the record not
  writable). Nothing is approved on 6 or 7.
- An implementer worktree is one with a local, untracked `.delix/card` at the work-tree root
  ([`scripts/common.py`](scripts/common.py)). Without `python3` both `PreToolUse` hooks block (see
  [Requirements](#requirements)).

**Files it writes**
- In your project: `docs/delix/` (spec, cards, `STATE.json` with its `cost_usd` fields, verification reports), written
  by the lead skills and not git-ignored, so once you commit them they are as public as your repository;
  `docs/delix/BOARD.md` only with `board.py --write` (git-ignored). In the implementer worktree: `.delix/report.md`,
  `.delix/test-result.txt`, `.delix/evidence/`, and `.delix/warnings.log` when `gitleaks` is missing.
- In your home directory: the feedback queue `~/.claude/delixcrew/feedback/` (directory `0700`, files `0600`) and the
  triage records `~/.claude/delixcrew/triage/<n>.json`; the Stop gate approvals `~/.claude/delixcrew/trust.json`
  (directory `0700`, file `0600`; `{"version": 1, "entries": [...]}`, each entry a `git_common_dir`, a `sha256` and an
  `approved_at` time). It is written only by `trust.py allow` and ignored when it is a symlink, not yours or readable by
  others. To withdraw an approval, delete its object from `entries`, or the file; there is no revoke or list command.
- Temporary: the `/delixcrew:verify` workspace `${TMPDIR:-/tmp}/delix-verify-<name>/`, and the issue or comment body
  that `feedback.py send` and `triage.py apply` hand to `gh`, deleted after the call.

**When it uses the network.** The hook scripts open no connection of their own; they run `git` and `gitleaks` locally.
The Stop gate runs your project's own commands (above), whatever network they use. Beyond those, the network is used
by these commands, each with your own accounts:
- Claude runs them when a skill says so: `triage.py index|show|record|preview` read issues of this repository with
  `gh issue list|view` (`/delixcrew:triage`, `/delixcrew:start #<n>`); `gh repo view`, `gh pr create` (implementer) and
  `gh pr checks` (review) on your project's remote; `ssh` and `rsync` to the `verify.remote` host in `delix.json`, only
  when that block exists (`/delixcrew:verify`, `/delixcrew:review`); headless implementer sessions with `claude -p`
  (`/delixcrew:dispatch`, and a fix round in `/delixcrew:review`). Claude does not run `gh pr merge`.
- Only you run them, in your own terminal (they need a TTY and a typed `SEND <hash>` or `APPLY <hash>`):
  `feedback.py send` (`gh issue list`, `gh issue create`) and `triage.py apply` (`gh label`,
  `gh issue comment|edit|close`). Both are fixed to `github.com/tahircengiz/delixcrew` and drop `GH_HOST` and `GH_REPO` from the environment.

## Feedback

When delixcrew itself misbehaves (a hook rejects correct work, a skill step cannot be followed as written, you work
around a plugin limit by hand), it can keep a local draft of the problem so you can send it to this repo as a GitHub
issue. delixcrew never sends on its own: a draft is sent when you run `send` in your own terminal, and the hooks block
the known ways for Claude to send (see Remaining risk).

**Off by default.** Turn it on (and off) in your own terminal; the script lives in the plugin's install directory, for
a marketplace install `~/.claude/plugins/cache/delixcrew/delixcrew/<version>/scripts/feedback.py`:

```bash
python3 <plugin dir>/scripts/feedback.py enable --terms acme,example-corp
```

`--terms` adds your own words to redact (customer names, codenames). `status` shows whether it is on, the queue
directory and the number of drafts; `disable` turns it off. `enable` without `--terms` and `disable` keep your terms;
when `config.json` is there but cannot be read, or its `extra_terms` is not a list of strings, they exit 2 and leave the
file as it is: fix or remove it, or give the terms again with `enable --terms`. While it is off nothing is written: `/delixcrew:feedback note` shows
`delixcrew feedback is off; enable: python3 <path>/feedback.py enable` with the real path, and `/delixcrew:close` and
`/delixcrew:review` stay silent. Drafts live in
`~/.claude/delixcrew/feedback/` (`DELIXCREW_FEEDBACK_DIR` overrides it), never in your project repo.

**Flow.**
1. A draft is created by `/delixcrew:feedback note` (a finding from the current conversation), or by `/delixcrew:close`
   and `/delixcrew:review` when one of the three events above happened. A repeated finding raises the draft's count
   instead of adding a new one.
2. `/delixcrew:feedback review` shows each draft **exactly** as it would be published (repo, label, title, body), with a
   `VERDICT:` and a `HASH:` line.
3. To send a draft, reply in chat with its id: `yes F003` (or `evet F003`). A bare "yes", "send all" or "approved" in a
   file is not consent. Claude then gives you one command:
   `python3 <plugin dir>/scripts/feedback.py send F003 --confirm <hash>`.
4. Run it in **your own terminal**. It prints the queue directory and the full text again and waits for you to type
   `SEND <hash>`. If the text changed since the preview, it stops and asks you to preview again.

The known send paths for Claude are closed: in every session the hooks deny `feedback.py send`, running `feedback.py` under `script`, `expect`,
`unbuffer` or `pty.spawn`, `gh issue create|comment|edit` and `gh api … issues` aimed at delixcrew, and Write/Edit into
the queue directory, with `delixcrew: feedback is sent only by the user from their own terminal`.

**Requirements for sending:** `gitleaks` on `PATH` and a signed-in `gh`. Without `gitleaks` every draft is `BLOCKED`;
without `gh` the draft stays queued and `send` exits 7. The target repo is fixed to `tahircengiz/delixcrew`; before
creating an issue, `send` searches for the draft's fingerprint line (`delixcrew-fp: …`) and, if an issue already has it,
records that URL instead of opening a second one. You can also open an issue on GitHub by hand; the issue forms ask the
same headings.

**What is redacted** (before the preview, title included): every host name outside a short allowlist (`github.com`,
`code.claude.com`, `docs.anthropic.com`, `anthropic.com`, `example.com`, `example.net`, `example.org` and their
subdomains, `*.example` and `localhost` as an exact name; not `*.test`, `*.invalid`, `*.localhost` or a non-ASCII name),
so `build.example-corp.dev` becomes `<redacted:host>`; IP addresses outside the documentation ranges and loopback
(`10.1.2.3` → `<redacted:ip>`); MAC and e-mail addresses; the user part of home paths (`/Users/<you>/x` → `~/x`) and
every other absolute path, single-segment ones and `name:/path` included (`/srv/app`, `/srv`, `nas:/volume1/x` →
`<redacted:path>`; only `/delixcrew:<skill>` and Claude Code's built-in commands such as `/compact` stay); your user name and machine name; the names of the projects the drafts came
from (folder name, git remote owner and repo) and your `--terms`. A name whose last label is a file extension is not a
host, so `notes.md` and `ci.acme-corp.conf` stay. An IP address is redacted also with a leading zero (`010.001.002.003`)
or with a `_` next to it (`10.1.2.3_`).

URLs are checked first (`scheme://…`, `//…`, `host/…`, `name:port/…`, and a dotted `host/…` right after `:` or `\`). A
URL stays only if all of these hold: its scheme is empty, `http` or `https`; its host is on the allowlist above or is a
loopback or documentation IP (IPv4 only in its canonical dotted form, so `http://127.1/` is removed); it has no user
part (`user@`); its path and query hold only letters, digits and `._~-/` (`=&+` after `?` or `#`); no path segment is
`.` or `..`; in every dotted part of the path or query, each label after the first is a file extension or a number
(`a.tar.gz`, `v0.6.1`); the path holds no host name, IP or MAC address; no term appears anywhere in the URL, scheme and
host included; on `github.com` only `tahircengiz/delixcrew` and `anthropics/…` paths stay. Any other URL keeps its
scheme and the rest becomes `<redacted:url>` (`http://jenkins:8080/job/x` → `http://<redacted:url>`,
`key:ci.acme-corp.net/api/x` → `key:<redacted:url>`; without a scheme the whole URL, `//fileserver/share` →
`<redacted:url>`), so a link with `%` (`?q=is%3Aopen`) is removed too.

A path or port right after a redacted host, IP, e-mail or MAC address is redacted with it (`see 10.1.2.3/api/x` →
`see <redacted:ip><redacted:path>`, `git@github.com:acme/private` → `<redacted:email><redacted:path>`,
`de:ad:be:ef:00:11/x` → `<redacted:mac><redacted:path>`). Markdown emphasis, a backtick or a quote between the two stops
this for a port: `**ci.acme-corp.net**:8080/api/x` → `**<redacted:host>**:8080/api/x`, while
`**ci.acme-corp.net**/api/x` → `**<redacted:host>**<redacted:path>`. A `github.com/…` path in plain text, wherever it
appears, keeps the same owner rule: `vendor/github.com/acme/private-lib/x.go` → `vendor/github.com<redacted:path>`.

**What blocks a draft** (`VERDICT: BLOCKED: <reason>`, `send` exits 4; no secret value is printed): a `gitleaks` finding
in the raw or the redacted text, or `gitleaks` missing, failing or timing out; an invisible Unicode control character
(zero-width, bidi); any other character that is not a letter, number, punctuation mark, symbol, space, newline or tab
(`invisible character`: for example U+2028, U+2029, a variation selector, a Hangul filler or a lone surrogate; an emoji
selector such as U+FE0F may only follow a visible symbol such as U+2764), so text with combining marks that NFKC does
not merge into one character (Devanagari, for example) is blocked too; an opaque string of 32+ characters
(`[A-Za-z0-9+=_-]`, so a full git SHA is blocked too; use the short one); more than 15 code lines; a body over 8 KB;
anything still matching the redaction rules after redaction; a record changed on disk since it was queued
(`fingerprint mismatch`); an unreadable queue record; a feedback `config.json` (your `--terms`) that is there but not a
readable JSON object, or whose `extra_terms` is not a list of strings, so a draft is never redacted without your terms.

**Remaining risk.** The hooks close the *known* ways to send; they do not block everything. Claude runs with your `gh`
login, and a disguised command (one built from base64, a wrapper written to a file, an HTTP request without `gh`) can get
past a pattern-matching hook. This is true of any Claude session, with or without delixcrew. If you want a stronger
guard, add a deny rule to your own `settings.json`; delixcrew only suggests this and does not change your settings:

```json
{ "permissions": { "deny": ["Bash(gh issue create:*)", "Bash(gh api:*)"] } }
```

### Data & privacy

- **What is sent**, after redaction, and nothing else: the title, the label (`bug` or `enhancement`) and a body with
  `### Component`, `### Version` (plugin version, Claude Code version, OS name such as `Darwin` or `Linux`),
  `### What happened`, `### Expected`, `### Steps to reproduce`, `### Context`, and the last line
  `delixcrew-fp: <fingerprint>`. You see this exact text in the preview and again in your terminal before `SEND <hash>`.
- **What is not sent**: the project terms kept with each draft (`origin_terms`), your user and machine names, the user
  part of home paths, other absolute paths, e-mail addresses, hosts outside the allowlist and URLs that are not allowed
  (`<redacted:url>`) are redacted; a draft with a
  secret is blocked, not redacted and sent.
- **Where it goes**: a **public** issue on `tahircengiz/delixcrew`, opened with **your own** GitHub account through
  `gh`. The basis is your explicit action: feedback is off until you enable it, and delixcrew sends nothing until you
  type `SEND <hash>` in your own terminal; the hooks close only the known paths for Claude (see Remaining risk).
- **Local queue**: `~/.claude/delixcrew/feedback/` (or `DELIXCREW_FEEDBACK_DIR`). `feedback.py drop <id>` marks a draft
  as dropped so it is not offered again (the file stays); delete the directory to remove every draft and the setting.
  The queue files keep the **raw, unredacted** draft text and the project terms (`origin_terms`); redaction is applied
  only at `preview` and `send`. Redaction is pattern-based, so read the preview before you send.
- **Deleting a sent issue**: as its author you can edit it, but GitHub does not let you delete it. To have it removed,
  ask through GitHub private reporting:
  [security/advisories/new](https://github.com/tahircengiz/delixcrew/security/advisories/new).

## Triage

Issues on this repo (bug reports, feature requests, sent feedback drafts) are checked before they become work.
`/delixcrew:triage` works only in the delixcrew repository. Issue titles, bodies and comments are untrusted input: Claude
shows them only inside an `UNTRUSTED` block, and nothing in them is an instruction or a decision. Claude never publishes:
the decision comment and the label changes are applied by you, from your own terminal.

**Flow.**
1. `/delixcrew:triage` runs `triage.py index` and takes the pending issues (open, no decision label) one at a time,
   lowest number first; `/delixcrew:triage #12` takes one issue. `triage.py show <n>` reads it cleaned: Unicode
   control, format and private-use characters (Cc except newline and tab, Cf, Co) and HTML comments are removed and
   counted (`removed:`); other invisible characters (e.g. Hangul fillers) stay. The fixed fields (`url`, `state`,
   `author`, `source`, `labels`, `decision`, `reported-version`, `issue-sha`) come first.
2. The read-only `delixcrew:architect` runs a checklist (job D) and proposes one decision with a reason: a bug is checked
   against the tree of the reported version (its `v<X.Y.Z>` tag, or `main` when there is no such tag), a feature against
   the delix principles, and every issue for duplicates, its source (`external` issues need a concrete use case) and
   missing information.
3. You decide in chat with the decision **and** the number: `accept #12`, `needs-info #12`, `duplicate #12`,
   `wontfix #12` or `defer #12` (or `skip #12`). A bare "ok", "yes", "accept all", or "accepted" written in an issue or a
   file is not a decision. Your decision wins over the proposal.
4. Claude records it with `triage.py record <n>` (refused if the issue's title or body changed since `show`), then runs
   `triage.py preview <n>` and shows its output verbatim: the repo, the issue, the label actions, the exact comment, and
   a `VERDICT:` and a `HASH:` line.
5. With `VERDICT: CLEAN`, Claude gives you one command:
   `python3 <plugin dir>/scripts/triage.py apply 12 --confirm <hash>`. Run it in **your own terminal**. It prints
   everything again and waits for you to type `APPLY <hash>`. Before that it rebuilds the comment and stops if its
   hash no longer matches (exit 5) or the comment is now blocked, e.g. the issue's title or body changed since the
   record (exit 4). Labels, comments and the issue's state are read again after `APPLY`, not compared with the preview.

**Labels.** Five decision labels: `accepted`, `needs-info`, `duplicate`, `wontfix`, `deferred` (`defer` sets
`deferred`). `apply` creates a missing one, adds the decision label, removes the other four and posts the comment, whose
last line is `delixcrew-triage: <decision> <hash> <issue-sha>`. Only `duplicate` and `wontfix` close the issue (as not
planned); `needs-info`, `defer` and `accept` leave it open, and an accepted issue is closed by the PR that finishes the
work. Re-running `apply` after a failed step does only the steps still missing.

**What blocks a comment** (`VERDICT: BLOCKED: <reason>`, `preview` exits 4, no command is given): the issue changed
since it was triaged; an `@` mention, HTML or a character reference in the reason or questions; invisible characters; a
`gitleaks` finding, or `gitleaks` missing or failing; a 32+ character opaque string; a feedback `config.json` (your
`--terms`) that is there but not a readable JSON object (malformed, over 1 MiB or 32 levels deep, not a regular file),
or whose `extra_terms` is not a list of strings, so the comment is never redacted without your terms. The comment is built only from the recorded reason, questions and
duplicate number, never from the issue text.

**From issue to work.** `/delixcrew:start #12` takes only an issue triaged as `accepted` whose title and body are
unchanged since acceptance: it reads the issue through `triage.py show 12 --require accepted`, which exits 8 when the
`accepted` label or the maintainer's triage comment is missing, or when the text changed after acceptance. Run
`/delixcrew:triage #12` again in that case. If an `accept` decision for the current text is recorded locally but not
applied yet, the exit 8 message says so instead and gives the script's full path: from your own terminal, run its
`preview 12`, then the `apply` command with the `HASH` it prints. A local record never counts as acceptance. Issue
intake works only in the delixcrew repository and is still at least Tier 2.

**Records.** Decisions are stored in `~/.claude/delixcrew/triage/<n>.json` (`DELIXCREW_TRIAGE_DIR` overrides it), never
in your project repo; only `triage.py` is meant to write there: the hooks deny Write/Edit into it, but a shell write
(redirection, `cp`, `tee`) is not denied. `apply` marks a record as applied. `preview` and `apply` need `gitleaks` on `PATH`;
`apply` also needs a signed-in `gh` with write access to this repo.

The known publish paths for Claude are closed: in every session the hooks deny `triage.py apply`, running `triage.py`
under `script`, `expect`, `unbuffer` or `pty.spawn`, `gh issue close|reopen|lock|unlock|delete|transfer|pin|unpin|develop`,
`gh label` and writing `gh api` calls (`-f`/`-F`, `--field`, `--raw-field`, `--input`, `graphql`, a method other than
`GET`) aimed at delixcrew, and Write/Edit into the record directory, with
`delixcrew: triage decisions are applied only by the user from their own terminal`. `gh issue comment|edit` aimed at
delixcrew was already denied by the [Feedback](#feedback) rule.

**Remaining risk.** As with feedback, the hooks close the *known* paths only. A disguised command (`exec(open(...))`, a
`gh` alias, a REST call with `curl`) is not caught by a pattern. On the `triage.py` path the TTY and `APPLY <hash>`
still stop it; outside `triage.py` nothing stops it, but an `accepted` label alone does not let an issue into
`/delixcrew:start`: that also needs the maintainer's triage comment with the matching `issue-sha`. The `permissions.deny`
rule under [Feedback](#feedback) covers `gh api` here too.

## Known limits

Plugin agents ignore the `permissionMode`, `hooks` and `mcpServers` fields (the constraint is `tools` + `hooks/hooks.json`).
Hooks load in every session where the plugin is installed; the implementer gates run only when `cwd/.delix/card` exists,
the reviewer gates only when `agent_type` is `delixcrew:*`. Experimental Agent Teams are not used. There is no plugin monitor:
the former watcher never started in the pilot and 3 diagnostic runs and was removed on 2026-11-01 (retro A9, K35).
`/delixcrew:status` also works under `-p`. When `gitleaks` is installed, a secret scan runs before every commit; otherwise a
note is appended to `.delix/warnings.log`.

The write gate (`scripts/write_gate.py`) sees only the Write/Edit/MultiEdit/NotebookEdit tools; an implementer writing
files through Bash (`echo >`, `sed -i`, `tee`) is outside this hook (`bash_gate.py` intercepts only redirects, `cp`, `mv`
and `tee` into protected paths, reviewer Bash and, in every session, the known feedback send paths and triage write
paths; see [Feedback](#feedback) and [Triage](#triage)). A path escaping the worktree (cwd) is always rejected (A13, K42); path matching is relative to cwd. For
that reason a change to the card file, `docs/delix/**` or an unapproved protected path in the card counts as a finding in
the `delixcrew:qa` review of the diff. Tier 3 permission is opened by the `**🔐 Approved:** <YYYY-MM-DD> <who>` line after
the card's header table; only the lead writes it, after the user's explicit "yes" in chat, and commits it to main.

The Stop gate approval (`trust.py allow`) has these limits. It covers the command text, not the files it runs: on an
approved repository, a branch that changes `tests/` but keeps the list runs them, as if you ran the tests on that
branch. A new directory at the path of a deleted repository, or of a worktree not yet pruned (`git worktree prune`), can
inherit its approval. The project's own `.claude/settings.json` hooks and `PATH` can still run code once you accept the
folder trust dialog; the approval closes only the `delix.json` channel. The Bash hook's denylist is friction, not a
boundary: commands built from split quotes, variables or globs get past it, and so does a path to the trust record
written as a relative path after `cd`, with `//` or `/./`, or through a symlinked directory, because that rule is a
substring match (K220); the boundary is Claude Code's Bash permission prompt (K77). The implementer push rule (T041,
K279) is a pattern check on words too, defence in depth and not a GitHub boundary: words built from variables or
`eval`, git settings given through the environment (`GIT_DIR`, `GIT_CONFIG_*`) or `--config-env`, a script file or
another program's own git calls, `gh api` ref or merge writes in any repository other than delixcrew's own, deleting
`.delix/card`, a cwd below the worktree root and the repository owner's bypass on the `main-review` ruleset are out
of its reach; as a false positive it denies the words `git` and `push` on one line of a heredoc body, an `echo` or a
commit message, and a push in a command that also has `cd` or a git command other than `add`, `commit`, `status`,
`diff`, `log` or `show`. The one allowed `cat` heredoc
writes nothing the Write tool could not already write. With git older than 2.44, a missing object in a promisor
(partial clone) repository can still be fetched from its remote while the hooks read the index (K225).

## License

MIT, see [LICENSE](LICENSE). Source and issues: <https://github.com/tahircengiz/delixcrew>.
Not affiliated with or endorsed by Anthropic. Provided as is, without warranty (see [LICENSE](LICENSE)).
