# Changelog

Earlier versions: git history and the [v0.2.0 release](https://github.com/tahircengiz/delixcrew/releases/tag/v0.2.0).

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
