# Changelog

Earlier versions: git history and the [v0.2.0 release](https://github.com/tahircengiz/delixcrew/releases/tag/v0.2.0).

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
