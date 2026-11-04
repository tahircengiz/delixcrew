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
| 3 | `/delixcrew:dispatch` | `architect` writes the cards and the wave plan; conflict check; dispatch prompts; implementer sessions (at most 3 in parallel). |
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
directory and the number of drafts; `disable` turns it off. While it is off nothing is written: `/delixcrew:feedback note` shows
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
from (folder name, git remote owner and repo) and your `--terms`. URLs are checked first (`scheme://…`, `//…`, `host/…`,
`name:port/…`): a URL stays only if its host is on the allowlist above or is a loopback or documentation IP, it has no
user part (`user@`), and its path and query hold only letters, digits and `._~-/` (`=&+` after `?` or `#`) with no `..`
segment, host name, IP or term; on `github.com` only `tahircengiz/delixcrew` and `anthropics/…` paths stay. Any other
URL keeps its scheme and the rest becomes `<redacted:url>` (`http://jenkins:8080/job/x` → `http://<redacted:url>`;
without a scheme the whole URL, `//fileserver/share` → `<redacted:url>`), so a link with `%` (`?q=is%3Aopen`) is removed
too.

**What blocks a draft** (`VERDICT: BLOCKED: <reason>`, `send` exits 4; no secret value is printed): a `gitleaks` finding in
the raw or the redacted text, or `gitleaks` missing, failing or timing out; an invisible Unicode control character
(zero-width, bidi); an opaque string of 32+ characters (`[A-Za-z0-9+=_-]`, so a full git SHA is blocked too; use the
short one); more than 15 code lines; a body over 8 KB; anything still matching the redaction rules after redaction; a
record changed on disk since it was queued (`fingerprint mismatch`); an unreadable queue record.

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
`gitleaks` finding, or `gitleaks` missing or failing; a 32+ character opaque string. The comment is built only from the recorded reason, questions and
duplicate number, never from the issue text.

**From issue to work.** `/delixcrew:start #12` takes only an issue triaged as `accepted` whose title and body are
unchanged since acceptance: it reads the issue through `triage.py show 12 --require accepted`, which exits 8 when the
`accepted` label or the maintainer's triage comment is missing, or when the text changed after acceptance. Run
`/delixcrew:triage #12` again in that case. Issue intake works only in the delixcrew repository and is still at least
Tier 2.

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

## License

MIT, see [LICENSE](LICENSE). Source and issues: <https://github.com/tahircengiz/delixcrew>.
