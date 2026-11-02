# delix — a team workflow for Claude Code

**Spec first. Agents build. You hold the gates.**

`delix` turns the single-session loop of "open, pick a folder, read the history, continue" into the division of labour
of a real software team: an **orchestrator** session writes a tech spec through a grill interview, splits the work into
task cards, hands each card to an **implementer** session running in its own worktree, and has **read-only reviewers**
(qa, security) check the result. A human is involved at exactly two gates: **spec approval** and **PR merge**. The
constraints live in the harness, not in the prompt: reviewer roles have no write tool in their `tools` list, plugin hooks
block writes to protected paths and changes to test files, and the Stop hook does not close an implementer turn until the
tests pass.

Türkçe sürüm: [README.tr.md](README.tr.md). Design and evidence (Turkish): [tech spec](docs/spec/ekip-tech-spec.md) ·
[research report](docs/research/reports/Çoklu%20ajan%20yazılım%20ekibi%20orkestrasyonu.md) · decisions [STATUS.md](STATUS.md).
The skills reply in the user's language; labels, status values and verdict tokens stay in English.

## Installation

From GitHub (Desktop and terminal, no `--plugin-dir` needed):

```bash
claude plugin marketplace add tahircengiz/delixcrew
```

```bash
claude plugin install delix@delix-local
```

From a local clone the repo is read in place, no copy: `claude plugin marketplace add /path/to/delix`, then the same
`install` command. The marketplace definition is [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json);
after `claude plugin marketplace update delix-local` (or `git pull` in a local clone), run
`claude plugin update delix@delix-local`. For a one-off trial, `claude --plugin-dir /path/to/delix` also works. Checks: `claude plugin validate .`; hook tests: `bash tests/hook_tests.sh`; board tests:
`bash tests/board_tests.sh`; behaviour evals: `claude plugin eval . --trust-plugin --no-publish` (calls the model, costs money).

## Flow

| Step | Command | What happens |
|---|---|---|
| 1 | `/delix:start <request>` | Context is read; **size** (S/M/L: process weight) and **tier** (1/2/3: gates) are proposed; `docs/delix/` is set up. For S, a single card. |
| 2 | `/delix:spec` | Grill (one question at a time, with a pick) → `docs/delix/SPEC.md` (SHALL + WHEN/THEN); `architect` (+ `security` at Tier 3) reviews; EGM at size L. **Gate 1.** |
| 3 | `/delix:dispatch` | `architect` writes the cards and the wave plan; conflict check; dispatch prompts; implementer sessions (at most 3 in parallel). |
| 4 | `/delix:implement <card>` | In the implementer session: test-first, only the card's files, a PR, `.delix/report.md`. |
| 5 | `/delix:review <card>` | Deterministic gates → `qa` (+ `security`) with zero context → ≤ 3 fix rounds → **Gate 2 (merge, human).** |
| 6 | `/delix:close` | STATUS/CHANGELOG, metrics (cost, rounds), drift check, approved memory writes, worktree cleanup. |
| shortcut | `/delix:verify <branch\|commit\|dir>` | **Only verifies** work done without a card (a single session or you) (K43): gitleaks, local tests, a remote **isolated** unit test (separate directory + separate image, never touches the live stack), `--full` on request; `qa` (+ `security`) in a **single pass**, no fix rounds → a `docs/delix/verifications/<date>-<name>.md` report (ACCEPT / FIX, 🔐) and `STATE.json.verifications`. For S/M + well-described + Tier ≤ 2 work, `/delix:start` proposes this; the full flow is for Tier 3 / parallel cards / an unclear spec. |
| any time | `/delix:status` | Read-only board: wave · card · role · tier · status · rounds · PR · cost · last report · pending gate (🔐, merge) table in the chat; on request (`--write`) to `docs/delix/BOARD.md` (not committed). |

## Roles

| Role | Unit | Permissions | Model |
|---|---|---|---|
| orchestrator | main session | writes no code | top |
| `delix:architect` | subagent | Read, Grep, Glob | opus |
| implementer (backend / frontend / ui-ux / devops / docs role note) | separate session, worktree | everything; a protected path or an existing test file only when listed in the card's Files (a protected path additionally needs a 🔐 Approved line); the card and `docs/delix/**` blocked by hook | sonnet |
| `delix:qa` | subagent | Read, Grep, Glob | sonnet |
| `delix:security` | subagent | Read, Grep, Glob + read-only scanner Bash | opus |
| `delix:scout` | subagent | Read, Grep, Glob | haiku |

## Files on the project side

`docs/delix/delix.json` (test command, protected paths, test paths, max parallel, the `verify` remote isolated-run block),
`docs/delix/SPEC.md`, `docs/delix/tasks/T<nnn>-<slug>.md`, `docs/delix/STATE.json` (cards + `verifications` records),
`docs/delix/verifications/<date>-<name>.md|.patch` (`/delix:verify` report and patch), `docs/delix/BOARD.md` (generated only
on request, in `.gitignore`). In the implementer worktree: `.delix/card` (activates the hooks), `.delix/report.md`,
`.delix/test-result.txt`, `.delix/evidence/`.

## Known limits

Plugin agents ignore the `permissionMode`, `hooks` and `mcpServers` fields (the constraint is `tools` + `hooks/hooks.json`).
Hooks load in every session where the plugin is installed; the implementer gates run only when `cwd/.delix/card` exists,
the reviewer gates only when `agent_type` is `delix:*`. Experimental Agent Teams are not used. There is no plugin monitor:
the former watcher never started in the pilot and 3 diagnostic runs and was removed on 2026-11-01 (retro A9, K35).
`/delix:status` also works under `-p`. When `gitleaks` is installed, a secret scan runs before every commit; otherwise a
note is appended to `.delix/warnings.log`.

The write gate (`scripts/write_gate.py`) sees only the Write/Edit/MultiEdit/NotebookEdit tools; an implementer writing
files through Bash (`echo >`, `sed -i`, `tee`) is outside this hook (`bash_gate.py` intercepts only `.env` redirects and
reviewer Bash). A path escaping the worktree (cwd) is always rejected (A13, K42); path matching is relative to cwd. For
that reason a change to the card file, `docs/delix/**` or an unapproved protected path in the card counts as a finding in
the `delix:qa` review of the diff. Tier 3 permission is opened by the `**🔐 Approved:** <YYYY-MM-DD> <who>` line after
the card's header table; only the orchestrator writes it, after the user's explicit "yes" in chat, and commits it to main.

## License

MIT, see [LICENSE](LICENSE). Source and issues: <https://github.com/tahircengiz/delixcrew>.
