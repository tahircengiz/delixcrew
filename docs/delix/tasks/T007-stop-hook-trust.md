# T007 — 🔐 Hooks trust only a local .delix/card (issue #8)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T007 | S | 3 | backend | 3 | open |

> 🔐 Tier 3 (protected hook script `scripts/common.py`). The orchestrator adds the Approved line after the human's "yes".

**Goal (1 sentence):** A repo that ships its own `.delix/card` cannot switch the hooks on, so the Stop gate never runs
that repo's `delix.json` commands. · **Spec:** none (S card from GitHub issue #8, ek madde E2 in
`docs/legal/kontrol-listesi-degerlendirme.md`)

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/common.py` (`card_path`, imports)
- Modify: `tests/hook_tests.sh` (line 5 only: `git -C "$T" init -q` after `mktemp -d`; the fixture must be a git work tree)
- Test: `tests/trust_tests.sh` (new)

## Interfaces
- Consumed: `git ls-files --error-unmatch -- .delix/card` exit codes: 0 tracked, 1 untracked, 128 not a work tree.
- Produced: `card_path(cwd)` returns `None` (hooks inactive) unless `cwd/.delix/card` is a regular file, not reached
  through a symlink, and untracked in a git work tree; in that case one stderr line starting `delixcrew: `.

## Global Constraints
- `stop_gate.py`, `write_gate.py`, `bash_gate.py` are unchanged: all three already go through `card_path`.
- Normal dispatch is unchanged: `skills/implement` writes `.delix/card` locally and excludes `.delix/` via
  `.git/info/exclude`, so the card is untracked.
- No network; git runs with `-c core.fsmonitor=false`, stdin closed, timeout 5 s.

## Steps
1. `tests/trust_tests.sh`: tracked card, committed symlink `.delix`, non-git dir (archive) must not run the repo
   command; a local untracked card must still run it and keep the write gate active. Run, see **red**.
2. Implement in `card_path` only.
3. Green: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done`.
4. Commit `T007: hooks trust only a local .delix/card (#8)`. PR body has "## How I tested" and `Fixes #8`.

## Verification command → expected output
`for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → each file ends `ALL PASSED`

## Review Focus
- Bypasses: symlinked `.delix` or `card`, cwd in a subdirectory, `git` missing, a repo shipped with its own `.git`
  (archive with `.git/`: out of scope, a malicious `.git/config` already runs code on any git command).
- Running `git` in an untrusted directory: only `ls-files`, fsmonitor off.
- PR #4 (T002) also touches `tests/hook_tests.sh` (appends at line ~82); line 5 does not conflict textually; verified
  green with PR #4's diff applied.

## Don'ts
- Untouchable: `hooks/hooks.json`, `scripts/stop_gate.py`, `scripts/write_gate.py`, `scripts/bash_gate.py`,
  `docs/delix/**`, `.github/**`.
- If a test looks wrong: NEEDS_CONTEXT.

## Report contract
`.delix/report.md` (≤ 2K tokens): status · command + output · PR number · assumptions · remaining work.

## Review findings (filled by the orchestrator)
