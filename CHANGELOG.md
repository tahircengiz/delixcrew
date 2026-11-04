# Changelog

Earlier versions: git history and the [v0.2.0 release](https://github.com/tahircengiz/delixcrew/releases/tag/v0.2.0).

## Unreleased

- **Security fix in the Bash hook** (`scripts/bash_gate.py`, #36): a capture call whose path started with `-`
  (`python3 -ic<dir>/feedback.py add <<'EOF'`, and the same `triage.py record` shape) passed the capture exemption, and
  Python ran the heredoc body as code under `-i -c`; such a body could start `send` or `apply` on a pseudo-terminal
  without the user typing the confirmation. The four capture path patterns now reject a path that starts with `-`, and
  the unquoted ones also reject `^` (with zsh `extendedglob`, `^x/…` can expand to `-ic/…`). Update the plugin.
- **One capture call exempts both rule sets** (#36): the body of exactly one `feedback.py add` heredoc is no longer
  checked against the triage rules, and the body of exactly one `triage.py record` heredoc no longer against the
  feedback rules. Every other shape (a `cd …&&` or `; echo` wrapper, a `${…}` path, an early delimiter) is still checked
  as full text.
- **The confirmation prompt says what to type** (#34): `triage.py apply` asks
  `Type APPLY <h> to apply it (the word APPLY, a space, then the hash): ` and `feedback.py send` the same with `SEND`;
  a mismatch repeats the full expected text. The exact comparison, the TTY check and exit 6 are unchanged.
- **Exit 8 names a recorded but unapplied accept** (#35): when `triage.py show <n> --require accepted` refuses and a
  valid local `accept` record for the live issue text exists, stderr says the issue is recorded locally but not
  applied and gives the `preview` command to run from your own terminal. A local record never counts as acceptance;
  `/delixcrew:start` shows the line as it is.
- **Stop gate commands need your approval** (#17): the Stop gate runs `test_command` and `extra_checks` from
  `docs/delix/delix.json` only when you approved that exact list for the repository (its `git_common_dir`, identified
  on the file system and never through a symlink, and a SHA-256 of the list) with `trust.py allow` from your own
  terminal, typing `TRUST <hash>`. Worktrees of an approved checkout inherit the approval; a changed list needs a new
  one. Without approval it runs nothing, writes `[not run: commands not approved, hash <h12>]` to
  `.delix/test-result.txt`, prints the command and stops the turn once; the implementer writes `BLOCKED`. Approvals
  live in `~/.claude/delixcrew/trust.json` (directory `0700`, file `0600`); to withdraw one, delete its object from
  `entries`. Migration: after updating, run `python3 <plugin dir>/scripts/trust.py allow` once in each repository's
  main checkout.
- **One `cat` heredoc is checked on its first line only** (K202, K204): exactly one `cat > <path> <<'EOF'` call (`>>`
  too, a quoted delimiter, nothing after the closing line, a path outside `~/.claude/delixcrew/`) gets the same
  first-line check as one `feedback.py add` or `triage.py record` heredoc, and one capture call now also skips the
  `gh` rules for its body. The trust record rule and the protected-path redirect check still see the full text.
- **Repository settings writes get their own message** (REQ-6): a `gh api` write aimed at this repository that names
  none of `issues`, `labels` or `graphql` is denied with
  `delixcrew: writes to the delixcrew GitHub repository (settings, rulesets, security) run only from the user's own terminal`.

## 0.6.2 — 2026-11-04

- **Feedback redaction is stricter** (`SANITIZER_VERSION` 3; take a new `preview` before `send`): a URL keeps only an
  allowlisted host with a plain path, otherwise the part after its scheme becomes `<redacted:url>` (on `github.com` only
  `tahircengiz/delixcrew` and `anthropics/…`; a user part never stays); `*.test`, `*.invalid` and `*.localhost` are no
  longer allowed; absolute paths after `>`, `|`, `-` or `\/` and Windows UNC paths are redacted, as are Unicode host
  names; triage comments use the same redaction. `feedback.py list` and `add` print control characters from the queue as
  visible escapes, and the hook that guards the feedback and triage directories ignores letter case and Unicode
  normalization. A dotted `host/…` right after `:` or `\` is checked as a URL; a path or port right after a redacted
  host, IP, e-mail or MAC address is redacted with it (`see 10.1.2.3/api/x` → `see <redacted:ip><redacted:path>`); a
  `github.com/…` path in plain text keeps the owner rule (`vendor/github.com/acme/x` →
  `vendor/github.com<redacted:path>`); an IP with a leading zero or a `_` next to it is redacted. A draft with a
  character that is not a letter, number, punctuation mark, symbol, space, newline or tab (U+2028, a variation selector,
  a Hangul filler, a lone surrogate) is `BLOCKED` with `invisible character`; `add` refuses a lone surrogate, and a
  queue record whose `id` is not `F` and digits is never updated as a duplicate.

## 0.6.1 — 2026-11-03

- **The main session's role is now called the lead** (Turkish: *ekip lideri*); it was the *orchestrator*. Only the
  name changes: skills, agent descriptions, templates, hook deny messages (`write_gate.py`), README, the site and the
  delix-board comments use the new name. Nothing in behaviour, commands or file formats changes. New `env_owner` locks
  say `"who": "lead"`; an existing `"orchestrator"` value still shows as is.

## 0.6.0 — 2026-11-03

Issue triage: incoming delixcrew issues are checked before they become work, and the decision comment is published
only by you, from your own terminal.

- **Triage script** (`scripts/triage.py`, stdlib only): `show <n>` reads an issue cleaned (Cc except newline and tab,
  Cf, Co and HTML comments removed and counted; other invisible characters stay) with fixed fields and an `issue-sha`
  of the title and body; `index` lists up to 300 issues with their state, decision label and source (`maintainer` or
  `external`); `record <n>` stores a decision (JSON on stdin) only if the issue is unchanged since `show`;
  `preview <n>` builds the exact comment and label
  actions with a `VERDICT:` and a `HASH:` line; `apply <n> --confirm <hash>` runs only on a TTY, prints everything again
  and waits for `APPLY <hash>`. Records live in `~/.claude/delixcrew/triage/` (`DELIXCREW_TRIAGE_DIR`). A comment is
  `BLOCKED` on a mention, HTML, a character reference, invisible characters, a `gitleaks` finding or a 32+ character
  opaque string. See README → Triage.
- **Five labels**: `accepted`, `needs-info`, `duplicate`, `wontfix`, `deferred`; a missing one is created on the first
  `apply`. Only `duplicate` and `wontfix` close the issue (as not planned); `accepted` stays open until the PR that
  finishes the work closes it.
- **`/delixcrew:triage [#n]`**: without an argument it walks the pending issues one at a time; the read-only architect
  runs a checklist (job D: bug against the reported version's tree, feature against the delix principles, duplicates,
  source) and proposes a decision. A decision is recorded only after you name it with the issue number in chat
  (`accept #12`); Claude then shows the preview verbatim and gives you the one-line `apply` command.
- **Hook rules** (every session): `bash_gate.py` denies `triage.py apply`, `triage.py` under `script` / `expect` /
  `unbuffer` / `pty.spawn`, and `gh issue close|reopen|…`, `gh label` and writing `gh api` calls aimed at delixcrew;
  `write_gate.py` denies Write/Edit into the triage record directory. Known paths only, as in 0.5.0.
- **`/delixcrew:start #<n>`** takes only an issue triaged as `accepted` whose title and body are unchanged since
  acceptance (`triage.py show <n> --require accepted`, exit 8 when the acceptance check fails, 7 when `gh` fails).
  This also fixes the 0.5.0 issue intake (§1a), which asked `gh issue view` for a field it does not return and failed.
- **CI** runs `tests/triage_tests.sh`.

## 0.5.0 — 2026-11-03

Self-feeding feedback: problems with delixcrew itself become sanitized GitHub issues, sent from your own terminal after you review them.

- **Feedback queue** (`scripts/feedback.py`, stdlib only): off by default (`feedback.py enable [--terms a,b]`,
  `disable`, `status`); drafts in `~/.claude/delixcrew/feedback/` (`DELIXCREW_FEEDBACK_DIR`), never in the project repo;
  repeats are folded by fingerprint. `preview` redacts hosts outside an allowlist, IP addresses (except loopback and documentation ranges), MAC and e-mail addresses,
  paths, user and machine names, project names and your extra terms, and blocks (fail-closed) on a `gitleaks` finding or
  missing `gitleaks`, invisible Unicode controls, 32+ character opaque strings, more than 15 code lines or a body over
  8 KB. `send` runs only on a TTY, prints the full text and waits for `SEND <hash>`; the target repo is fixed and an
  existing issue with the same fingerprint is reused. Sending needs `gitleaks` and a signed-in `gh`. See README →
  Feedback.
- **`/delixcrew:feedback [note | review]`**: `note` turns a finding from the conversation into a draft; `review` shows
  each draft exactly as it would be published and, only after `yes F<nnn>` in chat, gives the one-line `send` command for
  your own terminal. `/delixcrew:close` and `/delixcrew:review` add a draft only after a false-positive hook rejection, an
  unworkable skill step or a manual workaround of a plugin limit.
- **Hook rules** (every session): `bash_gate.py` denies `feedback.py send`, `feedback.py` under `script` / `expect` /
  `unbuffer` / `pty.spawn`, and `gh issue create|comment|edit` / `gh api … issues` aimed at delixcrew; `write_gate.py`
  denies Write/Edit into the queue directory. These close the known paths only, not every path; README suggests a
  `permissions.deny` rule for `gh issue create` and `gh api`, and the plugin does not change your settings.
- **Issue forms** (`.github/ISSUE_TEMPLATE/`): a hand-opened bug or feature issue asks the same headings as a sent draft.
- **`/delixcrew:start #<n>`** (in the delixcrew repo): takes a GitHub issue as the request; the issue text is treated as
  untrusted (HTML comments and invisible characters removed and reported, quoted only), and nothing is written before
  you approve the rewritten request.
- **Design-system step in `/delixcrew:spec`** (UI work only): the spec links `DESIGN.md` (or the repo's token file) and
  produces `DESIGN.md` when neither exists; the `spec-M` / `spec-L` templates say the same.
- **Security fix (T007, #16, issue #8):** the hooks trust only a local, git-untracked `.delix/card` at the root of a git
  work tree, not reached through a symlink. Before, a card that came with a cloned repo or an archive could turn on the Stop gate and run
  that repo's test command. The remaining case, an archive that brings its own `.git`, is tracked in issue #17.
- README → Feedback → Data & privacy: what is sent, what is not, where it goes (a public issue under your own GitHub
  account), the local queue and how to delete it, and how to ask for a sent issue to be removed.
- **Feedback hardening (T008, sanitizer v2):** `add` rejects a non-string `kind` without a traceback; single-segment
  paths (`/srv`) and `name:/path` (`nas:/volume1/x`) are redacted, except `/delixcrew:<skill>` and Claude Code's
  built-in commands; `send` runs only for a draft (`sent`, `duplicate`, `dropped` exit 2, nothing sent). Hashes from an
  earlier preview are no longer valid; run `preview` again.

## 0.4.0 — 2026-11-03

- **Plugin renamed `delix` → `delixcrew`**, the same name as the repo and the marketplace. Commands are now
  `/delixcrew:start`, `/delixcrew:spec`, … `/delixcrew:verify`; agents `delixcrew:architect`, `delixcrew:qa`,
  `delixcrew:security`, `delixcrew:scout`; hook messages start with `delixcrew:`. Project files keep their names
  (`docs/delix/`, `delix.json`, `.delix/` in worktrees), so existing projects need no migration. `delix-board` keeps its
  name (0.1.2: follows the new agent prefix).
- Moving an existing install (the old plugin name no longer exists in the marketplace, so `plugin update` cannot reach
  it): `claude plugin uninstall delix@delixcrew` (or `delix@delix-local`), `claude plugin marketplace update delixcrew`,
  `claude plugin install delixcrew@delixcrew`, `claude plugin update delix-board@delixcrew` if installed, then restart
  Claude. Dispatch prompts written before 0.4.0 still say `/delix:implement`; type `/delixcrew:implement` instead.

## 0.3.0 — 2026-11-03

For users outside the author's machine: requirements, clearer failure, CI.

- **Marketplace renamed `delix-local` → `delixcrew`.** New installs: `claude plugin install delix@delixcrew`
  (and `delix-board@delixcrew`). An existing `delix-local` install keeps working and keeps updating under its old name
  (`claude plugin marketplace update delix-local`, then `claude plugin update delix@delix-local`); to move to the new
  name, so the README commands match:
  `claude plugin uninstall delix@delix-local` (and `delix-board@delix-local` if installed),
  `claude plugin marketplace remove delix-local`, `claude plugin marketplace add tahircengiz/delixcrew`,
  `claude plugin install delix@delixcrew`, then restart Claude.
- README: a Requirements section (Claude Code, `python3`, `git`; optional `gh`, `gitleaks`).
- Hooks: without `python3` on `PATH` the Write/Edit and Bash hooks still block, now with one line,
  `delix: python3 not found on PATH; …`, instead of `/bin/sh: python3: command not found`.
- CI (`.github/workflows/tests.yml`): hook tests, board tests and `claude plugin validate .` on every push to main and
  every PR; actions pinned to commit SHAs, read-only token, no secrets. Evals stay local (they cost money).
- Evals: `task-card-format` checks that each required section is present, in any order; `reviewer-cannot-write` no
  longer fails a correct finding for a missing P0/P1 label.

## 0.2.4 — 2026-11-03

- `board.py`: an `accepted` card is merged (review §4), so it no longer shows a `merge` gate; the gate now shows on an
  `in_review` card with a PR.
- Verification records take an optional `resolution` (`merged <sha>`, `abandoned: <why>`): shown next to the verdict,
  left out of "Pending fixes".

## 0.2.3 — 2026-11-03

- `roles/ui-ux.md`: no taglines, helper text or secondary labels; a screen that needs them gets a better layout.
  Accessible names, form labels and error messages stay.
- `spec`: simple purpose, architecture and implementation; a decision that improves one of UX, DX or AX (agent
  experience) at the cost of another is recorded as a K decision with the trade.
- `architect` spec review: new question (6), a simpler design that meets the same requirements, or an unrecorded
  UX/DX/AX trade.

## 0.2.2 — 2026-11-02

Fixes from the first acceptance run on a real project (one devops card, Tier 3, start → dispatch → implement →
review → merge → close).

- `implement` / `roles/devops.md`: one rule for operational evidence. The implementer gathers it in an isolated,
  throwaway run of its own (own compose project name and directory, torn down afterwards); the shared test environment
  stays with the orchestrator, and what needs it goes into the report as commands.
- `implement`: projects without PRs (no git remote, or the card / dispatch says "no PR") leave the commits on the card
  branch, write `**PR:** none (<branch> @ <sha>)` and keep `pr` `null`; no push.
- `dispatch`: step 1 is skipped for size S with an approved card. Desktop sessions: `initiation: user_asked` only when
  the user asked in the chat, otherwise an `own_initiative` card; the worktree branch name comes from the report.
- `board.py`: reads object-shaped `waves` (`[{"wave": 2, "cards": [...], "note": "..."}]`) as well as the template's
  list of lists.
- `bash_gate.py`: the security reviewer may run `git -C <dir> diff|log|show|status|ls-files|grep`; writing git
  subcommands stay blocked with `-C` too.
- README: an install from a local path is a cached copy per version, like a GitHub install; it updates only after a
  version bump (`claude plugin update`). `claude --plugin-dir` reads a folder in place.
